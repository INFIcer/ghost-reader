local counter = require("__ghost-reader__/dop2/counter")


-- dop2/item.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 物品解析与实体携带物品统计。
--
-- 与性能无关的纯辅助逻辑：
--   * 实体/地格原型 -> 可放置物品名；
--   * 环境实体的期望挖掘产物；
--   * 传送带/机械臂非库存槽携带物品；
--   * 把一个被标记拆除的实体按类别累加进 counter；
--   * 提取 IRP（item-request-proxy）的请求明细与回收明细。
-- 这些函数被事件处理层与归属地重建共用，统计结果一律是 counter
-- （item -> quality -> count），由调用方决定落到哪个计数项、哪个类别。

local M = {}

-- 实体原型 -> 可放置物品名（若无则 nil）
---comment
---@param name string
---@return LuaItemPrototype|nil
local function item_for_entity(name)
  local p = prototypes.entity[name]
  if p and p.items_to_place_this and #p.items_to_place_this > 0 then
    return prototypes.item[p.items_to_place_this[1].name]
  end
end

-- 地格原型 -> 可放置物品名（若无则 nil）
---@param name string
---@return LuaItemPrototype|nil
local function item_for_tile(name)
  local p = prototypes.tile[name]
  if p and p.items_to_place_this and #p.items_to_place_this > 0 then
    return prototypes.item[p.items_to_place_this[1].name]
  end
end


-- 环境实体（树/鱼/岩石等）的期望挖掘产物：{ [item] = 数量 }。
-- 没有 items_to_place_this，改从 mineable_properties.products 取，
-- 数量 = amount × probability，四舍五入取整（至少 1）。
---@param prototype LuaEntityPrototype
---@param recycle counter
local function mineable_products(prototype, recycle)
  local mp = prototype.mineable_properties
  if mp.minable and mp.products then
    for _, pr in ipairs(mp.products) do
      if pr and pr.name then
        local prob = pr.independent_probability
        if prob == nil then prob = 1 end -- nil 表示必掉（100%）
        if prob ~= 0 then
          local amount = pr.amount
          if not amount and pr.amount_min and pr.amount_max then
            amount = (pr.amount_min + pr.amount_max) / 2
          end
          amount = amount or 1
          local quality = pr.quality_min
          if type(quality) == "string" then
            quality = prototypes.quality[quality]
          end
          local expected = amount * prob
          local qty = math.floor(expected + 0.5)
          if qty < 1 then qty = 1 end
          --产物可能是流体等非物品，取不到物品原型时跳过（计数表只记物品）
          local item_prototype = prototypes.item[pr.name]
          if item_prototype then
            recycle:add(item_prototype, ensure_quality(quality), qty)
          end
        end
      end
    end
  end
end

-- 读取实体"非库存槽"携带的物品：传送带运输线上的物品、机械臂手持物品。
-- 直接累加进 recycle（counter），不再自建 name -> count 表。
---comment
---@param en LuaEntity
---@param recycle counter
local function extra_carry_items(en, recycle)
  local et = en.type
  -- 传送带/地下传送带/分流器把货物存在运输线而非库存里。运输线数量随类型不同：
  -- 普通传送带 2 条、地下传送带 4 条、分流器 8 条（内部缓存是额外 line 5-8）。
  -- 遍历到 get_transport_line 返回 nil 为止，带上限保护。
  if et == "transport-belt" or et == "underground-belt" or et == "splitter" then
    for line_index = 1, 12 do
      local ok, tl = pcall(function() return en.get_transport_line(line_index) end)
      if not (ok and tl) then break end
      local okc, contents = pcall(function() return tl.get_contents() end)
      if okc and contents then
        for _, st in pairs(contents) do
          --运输线内容物是 ItemStackDefinition，quality 是品质名（需查原型），count 可省略
          local item_prototype = st and st.name and prototypes.item[st.name] or nil
          if item_prototype then
            recycle:add(item_prototype, ensure_quality(prototypes.quality[st.quality]), st.count or 1)
          end
        end
      end
    end
  elseif et == "inserter" then
    local okh, hs = pcall(function() return en.held_stack end)
    if okh and hs then
      --空手持栈上读 name 会报错，故逐个 pcall 读取；LuaItemStack.quality 已是品质原型
      local okn, name = pcall(function() return hs.name end)
      local okq, quality = pcall(function() return hs.quality end)
      local item_prototype = (okn and name) and prototypes.item[name] or nil
      if item_prototype then
        local okc, count = pcall(function() return hs.count end)
        recycle:add(item_prototype, ensure_quality(okq and quality or nil), (okc and count) or 1)
      end
    end
  end
end
-- 实体是否可能有"可计数的内容物"（决定被标拆除时是否需要建内容物快照）。
-- 与 recycle_entity_contents 的分支一一对应：
--   * 落地物品（item-entity）；
--   * 环境实体（树/岩石/鱼等，无 items_to_place_this，产物来自 mineable_properties）；
--   * 有储物格，或传送带/机械臂这类把货物放在运输线/手持栈上（而非库存里）的实体。
-- 静态建筑（墙/管道/灯等）三种都不满足，内容物恒为空，不必建快照。
---@param en LuaEntity
---@return boolean
local function has_countable_contents(en)
  if not (en and en.valid) then return false end
  local et = en.type
  if et == "item-entity" then return true end
  --环境实体没有可放置物品，其"内容物"是挖掘产物
  if not item_for_entity(en.name) then return true end
  --有储物格
  for i = 1, en.get_max_inventory_index() do
    local ok, inv = pcall(function() return en.get_inventory(i) end)
    if ok and inv then return true end
  end
  --传送带/地下传送带/分流器/机械臂：货物在运输线或手持栈上，不在库存里
  if et == "transport-belt" or et == "underground-belt" or et == "splitter" or et == "inserter" then
    return true
  end
  return false
end

-- 可能移动的实体类型：位置会变（被拖走/开走 → 进出建设区域，回收计数归属也跟着变）。
-- 用实体 type 判定，原型上没有可读的 movable 字段。
local MOVABLE_TYPES = {
  ["rolling-stock"] = true,
  ["car"] = true,
  ["spider-vehicle"] = true,
  ["character"] = true,
  ["locomotive"] = true,
  ["cargo-wagon"] = true,
  ["fluid-wagon"] = true,
  ["artillery-wagon"] = true,
  ["land-mine"] = true,
  ["item-entity"] = true,
}

-- 是否可移动（位置会变，需检测进出建设区域）。不可移动但有内容物的实体只需内容检测。
---comment
---@param en LuaEntity
---@return boolean
local function is_movable(en)
  if not (en and en.valid) then return false end
  return MOVABLE_TYPES[en.type] ~= nil
end

-- 把一个被标记拆除的实体，按类别累加进 recycle 表（counter）。
---@param en LuaEntity
---@return counter
local function recycle_entity_contents(en)
  local et = en.type
  local recycle = counter.create()
  -- 落地物品：按 stack 物品名 × 数量计为【物品】。
  if et == "item-entity" then
    if en.stack then
      local n = en.stack.name
      local item_prototype = n and prototypes.item[n] or nil
      if item_prototype then
        recycle:add(item_prototype, ensure_quality(en.stack.quality), en.stack.count or 1)
      end
    end
    return recycle
  end
  -- 环境实体（无 items_to_place_this）：其挖掘产物归类为【物品】。
  if not item_for_entity(en.name) then
    mineable_products(en.prototype, recycle)
    return recycle
  end
  -- 内部物品/模块作为【物品】（跳过模块库存重复）。
  for inv_index = 1, en.get_max_inventory_index() do
    local tinv = en.get_inventory(inv_index)
    if not tinv then goto skip_recycle_inv end
    for _, st in pairs(tinv.get_contents()) do
      --LuaInventory.get_contents 返回的 quality 是品质名，需要查原型
      local item_prototype = st and st.name and prototypes.item[st.name] or nil
      if item_prototype then
        recycle:add(item_prototype, ensure_quality(prototypes.quality[st.quality]), st.count or 1)
      end
    end
    ::skip_recycle_inv::
  end
  -- 传送带运输线物品 + 机械臂手持物品。
  extra_carry_items(en, recycle)
  return recycle
end

-- 提取 IRP 的请求明细（供给）：counter（item -> quality -> count）。
-- 同一物品+品质出现在多个请求里时累加（不能只保留最后一个）。
---comment
---@param irp LuaEntity
---@return counter
local function irp_requests(irp)
  local reqs = irp and irp.item_requests
  if not reqs then error("Can only be used if this is ItemRequestProxy") end
  local out = counter.create()
  for _, r in pairs(reqs) do
    if r and r.name then
      local item_prototype = prototypes.item[r.name]
      if item_prototype then
        counter.add(out, item_prototype, ensure_quality(prototypes.quality[r.quality]), r.count)
      end
    end
  end
  return out
end

-- 提取 IRP 的回收明细：counter（item -> quality -> count）。
-- 回收来自 removal_plan：每个 plan 命名一个物品，数量 = 代理目标容器内该物品当前库存。
-- 与原版一致：库存为 0 时按 1 计（该物品确实在回收计划中）。
---comment
---@param irp LuaEntity
---@return counter
local function irp_removals(irp)
  local removal = irp and irp.removal_plan
  if not removal then error("Can only be used if this is ItemRequestProxy") end
  local out = counter.create()
  for _, r in pairs(removal) do
    local item_prototype = prototypes.item[r.id.name]
    if item_prototype then
      local quality = ensure_quality(prototypes.quality[r.id.quality])
      for _, pos in ipairs(r.items.in_inventory) do
        counter.add(out, item_prototype, quality, pos.count or 1)
      end
    end
  end
  return out
end

M.item_for_entity = item_for_entity
M.item_for_tile = item_for_tile
M.mineable_products = mineable_products
M.has_countable_contents = has_countable_contents
M.is_movable = is_movable
M.recycle_entity_contents = recycle_entity_contents
M.irp_requests = irp_requests
M.irp_removals = irp_removals

return M
