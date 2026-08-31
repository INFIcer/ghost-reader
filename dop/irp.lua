-- dop/irp.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— IRP（临时物品请求）指纹轮询。
--
-- IRP 可能被建设机器人部分供应：item_requests 收缩而实体仍在，没有原生事件。
-- 在 on_tick 最前面用指纹检测变化，再登记为物品类别供给变更。只轮询需要
-- 跟踪的 IRP（上限每 tick 几个，避免每帧全量扫）。

local constants = require("__ghost-reader__/dop/constants")
local changes = require("__ghost-reader__/dop/changes")
local M = {}

local CHG_ITEM_SUPPLY = constants.CHG_ITEM_SUPPLY
local CHG_ITEM_RECYCLE = constants.CHG_ITEM_RECYCLE
local IRP_SNAPS = constants.IRP_SNAPS
local IRP_POLL_PER_TICK = constants.IRP_POLL_PER_TICK
local tile_pos = constants.tile_pos

local add_count_change = changes.add_count_change

-- 前置声明：apply_irp_changes / apply_irp_removals 在后面定义，但
-- poll_irp_updates（定义在前）需要调用。
local apply_irp_changes
local apply_irp_removals

-- 提取 IRP 的请求明细（供给）：{ [i] = {name, count}, ... }（数组）
local function irp_requests(irp)
  local reqs = irp and irp.item_requests
  if not reqs then return {} end
  local out = {}
  for _, r in pairs(reqs) do
    if r and r.name then
      out[#out + 1] = { name = r.name, count = r.count or 1 }
    end
  end
  return out
end

-- 统计代理目标（proxy_target）容器中某物品的当前库存。
-- 遍历所有库存 + 模块槽，跳过模块库存（在 get_inventory 循环里）再单独加一次。
local function target_stock_of(target, item_name)
  if not (target and target.valid) then return 0 end
  local total = 0
  local minv = target.get_module_inventory()
  for inv_index = 1, 40 do
    local tinv = target.get_inventory(inv_index)
    if not tinv then goto skip_stock_inv end
    if minv and tinv == minv then goto skip_stock_inv end
    for _, st in pairs(tinv.get_contents()) do
      if st and st.name == item_name then total = total + (st.count or 1) end
    end
    ::skip_stock_inv::
  end
  if minv then
    for _, st in pairs(minv.get_contents()) do
      if st and st.name == item_name then total = total + (st.count or 1) end
    end
  end
  return total
end

-- 提取 IRP 的回收明细：{ [i] = {name, count}, ... }（数组）。
-- 回收来自 removal_plan：每个 plan 命名一个物品，数量 = 代理目标容器内该物品当前库存。
-- 与原版一致：库存为 0 时按 1 计（该物品确实在回收计划中）。
local function irp_removals(irp)
  local removal = irp and irp.removal_plan
  if not removal then return {} end
  local out = {}
  local target = irp.proxy_target
  for _, plan in pairs(removal) do
    local id = plan and plan.id
    local item = id and id.name or (plan and plan.name)
    if item then
      local n = target_stock_of(target, item)
      if n == 0 then n = 1 end
      out[#out + 1] = { name = item, count = n }
    end
  end
  return out
end

-- IRP 请求指纹：item 名:count 排序后拼串
local function irp_fingerprint(irp)
  local parts = {}
  for _, r in ipairs(irp_requests(irp)) do
    parts[#parts+1] = tostring(r.name) .. ":" .. tostring(r.count)
  end
  table.sort(parts)
  return table.concat(parts, ";")
end

-- 取一个 IRP 的"归属位置"：优先用 proxy_target（被请求容器）的位置，
-- 因为可移动容器（列车车厢等）被拖走时才反映真实归属变化；IRP 实体自身
-- 位置可能不随容器移动。target 无效时退回 IRP 自身位置。
-- 返回 { surface, x, y } 或 nil。
local function irp_anchor_position(irp)
  if not (irp and irp.valid) then return nil end
  local target = irp.proxy_target
  if target and target.valid and target.position then
    return { surface = target.surface.index, x = target.position.x, y = target.position.y }
  end
  if irp.position then
    return { surface = irp.surface.index, x = irp.position.x, y = irp.position.y }
  end
  return nil
end

-- 按 unit_number + 快照位置取 IRP 实体（get_entity_by_unit_number 只对带
-- "get-by-unit-number" 能力的实体有效，普通实体不可靠，故用 find 兜底）。
-- 优先在快照锚点附近小区域找（IRP 通常在代理目标位置附近）；未命中再全表面
-- 按 unit 兜底，避免实体随代理容器移动时误判为"已移除"。返回 IRP 实体或 nil。
local function irp_by_unit(unit, data)
  if not (data and data.surface_index) then return nil end
  local surface = game.get_surface(data.surface_index)
  if not surface then return nil end
  local area = { { data.x - 2, data.y - 2 }, { data.x + 2, data.y + 2 } }
  for _, e in ipairs(surface.find_entities_filtered{area = area, type = "item-request-proxy"}) do
    if e.valid and e.unit_number == unit and e.type == "item-request-proxy" then return e end
  end
  -- 小区域未命中：全表面按 unit 兜底
  for _, e in ipairs(surface.find_entities_filtered{type = "item-request-proxy"}) do
    if e.valid and e.unit_number == unit and e.type == "item-request-proxy" then return e end
  end
  return nil
end

-- on_tick 最前：轮询少量 IRP，检测指纹变化 → 登记物品供给变更。
-- mark_pending 由调用方（main 的 on_tick）在登记后置位。
-- 采用"key 快照数组 + 起始索引"分批遍历：遍历中可安全删除 snaps 里的 key，
-- 不会因 next() 的 prev 失效而报错（invalid key to 'next'）。
local function poll_irp_updates(mark_pending)
  local snaps = storage[IRP_SNAPS]
  if not snaps or not next(snaps) then return end
  -- 收集 key 快照（仅当表不大；IRP 数量有限，可接受）
  local keys = {}
  for k in pairs(snaps) do keys[#keys + 1] = k end
  local total = #keys
  if total == 0 then return end

  -- 分批起始索引：记录上次处理到哪个 key（用其在快照中的位置近似，避免 key 失效）。
  local start = storage.irp_prev_index or 1
  if start > total then start = 1 end
  if start < 1 then start = 1 end
  local first = start

  local processed = 0
  while processed < IRP_POLL_PER_TICK do
    local unit = keys[start]
    if not unit then break end
    storage.irp_prev_index = start
    local data = snaps[unit]
    if data then
      -- 取 IRP 实体：unit_number + 快照位置（get_entity_by_unit_number 对普通实体不可靠，
      -- 封装在 irp_by_unit 内，优先小区域 find、未命中再全表面按 unit 兜底）。
      local irp = irp_by_unit(unit, data)
      if irp and irp.valid then
        local anchor = irp_anchor_position(irp)
        if anchor then
          local reqs = irp_requests(irp)         -- 当前请求明细（供给）
          local removals = irp_removals(irp)     -- 当前回收明细（回收）
          local fp = irp_fingerprint(irp)
          -- 格点精度检测：进出建设区域只取决于所在格点，避免浮点抖动误触发。
          -- 位置用 proxy_target（被请求容器）的格点，容器被拖走时正确反映归属变化。
          local t = tile_pos({ x = anchor.x, y = anchor.y })
          local ot = tile_pos(data)
          local moved = (t.x ~= ot.x) or (t.y ~= ot.y)
          local old_reqs = data.reqs or {}
          local old_removals = data.removals or {}
          -- 回收明细指纹（removal 数量随容器库存变化而变化，需纳入变化检测）
          local function rem_fp(tbl)
            local p = {}
            for _, r in ipairs(tbl) do p[#p + 1] = tostring(r.name) .. ":" .. tostring(r.count) end
            table.sort(p)
            return table.concat(p, ";")
          end
          local changed = moved or (fp ~= data.fingerprint) or (rem_fp(old_removals) ~= rem_fp(removals))
          if changed then
            -- 撤销旧明细（旧位置 + 旧内容），重加当前明细（新位置 + 新内容）。
            -- 先反扣再增加，避免"只加不减"导致部分供应/回收时重复累加。
            apply_irp_changes(old_reqs, data.surface_index, data.x, data.y, -1)
            apply_irp_changes(reqs, anchor.surface, anchor.x, anchor.y, 1)
            apply_irp_removals(old_removals, data.surface_index, data.x, data.y, -1)
            apply_irp_removals(removals, anchor.surface, anchor.x, anchor.y, 1)
            data.surface_index = anchor.surface
            data.x = anchor.x
            data.y = anchor.y
            data.reqs = reqs
            data.removals = removals
            data.fingerprint = fp
            if mark_pending then mark_pending() end
          end
        end
      else
        -- IRP 实体已不存在（取消请求/请求完成被移除）。若 on_object_destroyed
        -- 未触发（或先于此轮询被消费），快照仍残留：按快照反扣其供给与回收，
        -- 避免信号残留。注意若 on_object_destroyed 已处理并移除快照，这里不会
        -- 进入（snaps[unit] 已为 nil），因此不会重复反扣。
        if data and data.surface_index then
          apply_irp_changes(data.reqs or {}, data.surface_index, data.x, data.y, -1)
          apply_irp_removals(data.removals or {}, data.surface_index, data.x, data.y, -1)
          if mark_pending then mark_pending() end
          log("[ghost-reader][IRP][gone] unit="..tostring(unit).." rolled back "
            ..tostring(#(data.reqs or {})).." reqs + "..tostring(#(data.removals or {})).." removals")
        end
        snaps[unit] = nil
      end
    end
    processed = processed + 1
    start = start + 1
    if start > total then start = 1 end
    if start == first then break end
  end
end

-- 用给定请求明细登记物品供给变更（在给定位置，可指定增减方向）。
-- sign = 1 增加；sign = -1 撤销。
apply_irp_changes = function(reqs, si, x, y, sign)
  for _, r in ipairs(reqs) do
    if r and r.name then
      add_count_change(CHG_ITEM_SUPPLY, si, x, y, r.name, r.count * sign)
    end
  end
end

-- 用给定回收明细登记物品回收变更（在给定位置，可指定增减方向）。
apply_irp_removals = function(removals, si, x, y, sign)
  for _, r in ipairs(removals) do
    if r and r.name then
      add_count_change(CHG_ITEM_RECYCLE, si, x, y, r.name, r.count * sign)
    end
  end
end

-- 从 IRP 现读请求明细（供给）并登记（供创建/首次登记时用）。
local function register_irp_changes_at(irp, si, x, y, sign)
  if not (irp and irp.valid) then return end
  local s = sign or 1
  apply_irp_changes(irp_requests(irp), si, x, y, s)
  apply_irp_removals(irp_removals(irp), si, x, y, s)
end

-- 在 IRP 归属位置（proxy_target 容器位置，见 irp_anchor_position）登记其供给+回收
-- （供 IRP 创建时调用），与 poll 的撤销/重加锚点保持一致。
local function register_irp_changes(irp)
  if not (irp and irp.valid) then return end
  local anchor = irp_anchor_position(irp)
  if not anchor then return end
  register_irp_changes_at(irp, anchor.surface, anchor.x, anchor.y, 1)
end

M.irp_fingerprint = irp_fingerprint
M.irp_requests = irp_requests
M.irp_removals = irp_removals
M.irp_anchor_position = irp_anchor_position
M.apply_irp_changes = apply_irp_changes
M.apply_irp_removals = apply_irp_removals
M.poll_irp_updates = poll_irp_updates
M.register_irp_changes = register_irp_changes

return M
