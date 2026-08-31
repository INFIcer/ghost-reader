-- dop/items.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 物品名解析与回收内容。
--
-- 与性能无关的纯辅助逻辑：实体/地格原型 -> 可放置物品名，环境实体的期望
-- 挖掘产物，传送带/机械臂非库存槽携带物品，以及把一个被标记拆除的实体按
-- 类别累加进 recycle 表。这些函数被事件处理层与归属地重建共用。

local M = {}

-- 实体原型 -> 可放置物品名（若无则 nil）
local function item_for_entity(name)
  local p = prototypes.entity[name]
  if p and p.items_to_place_this and #p.items_to_place_this > 0 then
    return p.items_to_place_this[1].name
  end
end

-- 地格原型 -> 可放置物品名（若无则 nil）
local function item_for_tile(name)
  local p = prototypes.tile[name]
  if p and p.items_to_place_this and #p.items_to_place_this > 0 then
    return p.items_to_place_this[1].name
  end
end

-- 环境实体（树/鱼/岩石等）的期望挖掘产物：{ [item] = 数量 }。
-- 没有 items_to_place_this，改从 mineable_properties.products 取，
-- 数量 = amount × probability，四舍五入取整（至少 1）。
local function mineable_products(name)
  local p = prototypes.entity[name]
  if not p then return nil end
  local ok, mp = pcall(function() return p.mineable_properties end)
  if not (ok and mp and mp.products) then return nil end
  local out = {}
  for _, pr in ipairs(mp.products) do
    if pr and pr.name then
      local prob = pr.probability
      if prob == nil then prob = 1 end   -- nil 表示必掉（100%）
      if prob ~= 0 then
        local amount = pr.amount
        if not amount and pr.amount_min and pr.amount_max then
          amount = (pr.amount_min + pr.amount_max) / 2
        end
        amount = amount or 1
        local expected = amount * prob
        local qty = math.floor(expected + 0.5)
        if qty < 1 then qty = 1 end
        out[pr.name] = (out[pr.name] or 0) + qty
      end
    end
  end
  return out
end

-- 读取实体"非库存槽"携带的物品：传送带运输线上的物品、机械臂手持物品。
-- 返回 { [item] = count }。
local function extra_carry_items(en)
  local et = en.type
  local out = {}
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
          if st and st.name then
            out[st.name] = (out[st.name] or 0) + (st.count or 1)
          end
        end
      end
    end
  elseif et == "inserter" then
    local okh, hs = pcall(function() return en.held_stack end)
    if okh and hs then
      local okn, name = pcall(function() return hs.name end)
      local okc, count = pcall(function() return hs.count end)
      if okn and name then
        out[name] = (out[name] or 0) + ((okc and count) or 1)
      end
    end
  end
  return out
end

-- 判断实体是否需要"动态拆除跟踪"（即记录到 DECON_MOVERS 供 poll_decon_movers 每帧
-- 检测位置/内容物变化）。仅在下列情况才需要：
--   * 可能移动（列车车厢/汽车/蜘蛛机甲等被拖走 → 改变回收计数归属）；或
--   * 可能携带内容物（库存/模块/传送带货物/机械臂手持物 → 拆除过程中内容逐步搬走）。
-- 对既不能移动又无内容的静态建筑（管道/灯/墙等），跳过跟踪可避免为海量实体做无效轮询。
-- 移动判定用实体 type（无原型可读的 movable 字段）：rolling-stock / car / spider-vehicle /
-- character 等。内容判定沿用 recycle_entity_contents 依赖的类型。
local MOVABLE_TYPES = {
  ["rolling-stock"] = true, ["car"] = true, ["spider-vehicle"] = true,
  ["character"] = true, ["locomotive"] = true, ["cargo-wagon"] = true,
  ["fluid-wagon"] = true, ["artillery-wagon"] = true, ["land-mine"] = true,
}
local CONTENT_TYPES = {
  ["container"] = true, ["logistic-container"] = true, ["assembling-machine"] = true,
  ["furnace"] = true, ["mining-drill"] = true, ["boiler"] = true, ["reactor"] = true,
  ["generator"] = true, ["offshore-pump"] = true, ["pump"] = true, ["lab"] = true,
  ["rocket-silo"] = true, ["transport-belt"] = true, ["underground-belt"] = true,
  ["splitter"] = true, ["inserter"] = true, ["train-stop"] = true, ["cargo-wagon"] = true,
  ["roboport"] = true, ["radar"] = true, ["storage-tank"] = true, ["gun-turret"] = true,
  ["ammo-turret"] = true, ["electric-turret"] = true, ["artillery-turret"] = true,
  ["agricultural-tower"] = true, ["biochamber"] = true, ["electromagnetic-plant"] = true,
  ["crusher"] = true, ["cryogenic-plant"] = true, ["heating-tower"] = true,
  ["capture-robot-rocket"] = true, ["rocket-silo-rocket"] = true,
}
local function needs_decon_tracking(en)
  if not (en and en.valid) then return false end
  local et = en.type
  if MOVABLE_TYPES[et] then return true end
  if CONTENT_TYPES[et] then return true end
  -- 兜底：有 inventory 的实体（如 MOD 新增类型）也跟踪
  local ok = pcall(function() return en.get_inventory(1) ~= nil end)
  if ok then return true end
  return false
end

-- 是否可移动（位置会变，需检测进出建设区域）。不可移动但有内容物的实体只需内容检测。
local function is_movable(en)
  if not (en and en.valid) then return false end
  return MOVABLE_TYPES[en.type] ~= nil
end

-- 把一个被标记拆除的实体，按类别累加进 recycle 表。
-- include_entities / include_items 控制是否计入实体本身 / 物品。
local function recycle_entity_contents(en, include_entities, include_items, recycle)
  local et = en.type
  -- 落地物品：按 stack 物品名 × 数量计为【物品】。
  if et == "item-entity" then
    if include_items and en.stack then
      local n = en.stack.name
      local c = en.stack.count or 1
      if n then recycle[n] = (recycle[n] or 0) + c end
    end
    return
  end
  -- 环境实体（无 items_to_place_this）：其挖掘产物归类为【物品】。
  if include_items and not item_for_entity(en.name) then
    local prods = mineable_products(en.name)
    if prods then
      for prod, n in pairs(prods) do
        recycle[prod] = (recycle[prod] or 0) + n
      end
      return
    end
  end
  -- 普通建筑：本身作为【实体】。
  if include_entities then
    local item = item_for_entity(en.name)
    if item then recycle[item] = (recycle[item] or 0) + 1 end
  end
  -- 内部物品/模块作为【物品】（跳过模块库存重复）。
  if include_items then
    local minv = en.get_module_inventory()
    for inv_index = 1, 40 do
      local tinv = en.get_inventory(inv_index)
      if not tinv then goto skip_recycle_inv end
      if minv and tinv == minv then goto skip_recycle_inv end
      for _, st in pairs(tinv.get_contents()) do
        if st and st.name then
          recycle[st.name] = (recycle[st.name] or 0) + (st.count or 1)
        end
      end
      ::skip_recycle_inv::
    end
    if minv then
      for _, st in pairs(minv.get_contents()) do
        if st and st.name then
          recycle[st.name] = (recycle[st.name] or 0) + (st.count or 1)
        end
      end
    end
    -- 传送带运输线物品 + 机械臂手持物品。
    for name, n in pairs(extra_carry_items(en)) do
      recycle[name] = (recycle[name] or 0) + n
    end
  end
end

M.item_for_entity = item_for_entity
M.item_for_tile = item_for_tile
M.mineable_products = mineable_products
M.needs_decon_tracking = needs_decon_tracking
M.is_movable = is_movable
M.recycle_entity_contents = recycle_entity_contents

return M
