-- dop/events.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 事件处理层（登记变更）。
--
-- 每个事件回调只"登记变更"，不做重扫。on_tick 统一消费这些变更并增量更新
-- 归属地元信息。本模块把 Factorio 实体事件翻译成变更列表条目。
--
-- 注意：surface 增删事件在源 control_dop.lua 中定义了但从未注册；本模块保留
-- 相关登记函数，但由 main/register 决定是否接线（当前未接线，surface 归属地
-- 默认随表面存在）。

local constants = require("__ghost-reader__/dop/constants")
local items = require("__ghost-reader__/dop/items")
local changes = require("__ghost-reader__/dop/changes")
local M = {}

local MARK_META = constants.MARK_META
local DECON_MOVERS = constants.DECON_MOVERS

local CHG_ENTITY_SUPPLY   = constants.CHG_ENTITY_SUPPLY
local CHG_TILE_SUPPLY     = constants.CHG_TILE_SUPPLY
local CHG_ENTITY_RECYCLE  = constants.CHG_ENTITY_RECYCLE
local CHG_TILE_RECYCLE    = constants.CHG_TILE_RECYCLE
local CHG_ITEM_RECYCLE    = constants.CHG_ITEM_RECYCLE
local CHG_UPGRADE_SUPPLY  = constants.CHG_UPGRADE_SUPPLY
local CHG_UPGRADE_RECYCLE = constants.CHG_UPGRADE_RECYCLE

local item_for_entity = items.item_for_entity
local item_for_tile = items.item_for_tile
local recycle_entity_contents = items.recycle_entity_contents

-- 前置声明：record/clear_decon_mover 在后面定义，但 on_decon_marked 需要调用。
local record_decon_mover
local clear_decon_mover
-- 前置声明：meta 相关函数在后面定义，但 on_entity_ghost_built/on_tile_ghost_built
-- （定义在前）需要调用它们。
local mark_meta_key
local meta_ensure
local meta_add_change
local add_count_change = changes.add_count_change

-- 幽灵读取器被拆/死亡（登记到 reader_removed）
local function on_reader_removed(unit)
  changes.current_changes().reader_removed[unit] = true
end

-- 无人机平台增删（影响网络归属地的包围盒与建设范围）
local function on_port_added(port, net_id)
  pcall(function() script.register_on_object_destroyed(port) end)
  changes.current_changes().port_added[port.unit_number] = {
    surface_index = port.surface.index,
    x = port.position and port.position.x,
    y = port.position and port.position.y,
    crad = port.prototype and port.prototype.construction_radius,
    net_id = net_id,
  }
end

local function on_port_removed(port)
  changes.current_changes().port_removed[port.unit_number] = true
end

-- 实体虚影建成（供给：实体类别）。
-- 注册销毁事件并记录 meta：无人机建成实体时虚影被移除，据此反向扣减供给。
local function on_entity_ghost_built(g)
  if g and g.valid and g.position then
    local item = item_for_entity(g.ghost_name)
    if item then
      pcall(function() script.register_on_object_destroyed(g) end)
      local si = g.surface.index
      local x, y = g.position.x, g.position.y
      local key = mark_meta_key(g)
      meta_ensure(key, si, x, y)
      add_count_change(CHG_ENTITY_SUPPLY, si, x, y, item, 1)
      meta_add_change(key, CHG_ENTITY_SUPPLY, item, 1)
    end
  end
end

-- 地格虚影建成（供给：地格类别）。同样注册销毁 + 记录 meta。
local function on_tile_ghost_built(g)
  if g and g.valid and g.position then
    local item = item_for_tile(g.ghost_name)
    if item then
      pcall(function() script.register_on_object_destroyed(g) end)
      local si = g.surface.index
      local x, y = g.position.x, g.position.y
      local key = mark_meta_key(g)
      meta_ensure(key, si, x, y)
      add_count_change(CHG_TILE_SUPPLY, si, x, y, item, 1)
      meta_add_change(key, CHG_TILE_SUPPLY, item, 1)
    end
  end
end

-- 元信息存储：{ [key] = { surface_index, x, y, changes = { {kind, item, count}, ... } } }
-- key 用实体 unit_number；环境实体/落地物品无 unit_number 时用位置 key（surface:x,y）。
mark_meta_key = function(entity)
  if entity.unit_number then return "u:" .. tostring(entity.unit_number) end
  local p = entity.position
  if p then return "p:" .. tostring(entity.surface.index) .. ":" .. tostring(p.x) .. "," .. tostring(p.y) end
  return nil
end

-- 确保元信息记录存在并记录位置（供取消/销毁时反向回滚定位）
meta_ensure = function(key, si, x, y)
  storage[MARK_META] = storage[MARK_META] or {}
  local rec = storage[MARK_META][key]
  if not rec then
    rec = { changes = {} }
    storage[MARK_META][key] = rec
  end
  rec.surface_index = si
  rec.x = x
  rec.y = y
  -- 记录本记录的"主 key"（位置 key），供按 registration 回滚时一并清理位置别名。
  rec.main_key = key
  return rec
end

-- 往元信息里追加一条变更记录（供取消时反向回滚）
meta_add_change = function(key, kind, item, count)
  if not key or not item then return end
  local rec = storage[MARK_META] and storage[MARK_META][key]
  if not rec then return end -- 需先 meta_ensure 创建
  rec.changes[#rec.changes + 1] = { kind = kind, item = item, count = count }
end

-- 把元信息里的【物品类别回收】记录替换为当前内容物 items。
-- 当机器人逐步搬走实体内物品/插件/传送带货物/机械臂手持物时，归属地计数已由
-- poll_decon_movers 增量调整，这里同步 meta，使最终销毁时 rollback_entity_by_unit
-- 按"当前内容物"反向扣减，避免与已调整的计数重复/错乱。
meta_set_items = function(key, items)
  local rec = storage[MARK_META] and storage[MARK_META][key]
  if not rec then return end
  local kept = {}
  for _, c in ipairs(rec.changes) do
    if c.kind ~= CHG_ITEM_RECYCLE then
      kept[#kept + 1] = c
    end
  end
  for item, n in pairs(items or {}) do
    kept[#kept + 1] = { kind = CHG_ITEM_RECYCLE, item = item, count = n }
  end
  rec.changes = kept
end

-- 更新元信息的归属位置（拆除标记的移动实体被拖走时用）。
-- 当 poll_decon_movers 检测到实体移动到新位置并做了"旧位置撤销+新位置重加"后，
-- 必须同步元信息的 surface_index/x/y，否则最终销毁时 rollback_entity_by_unit 会
-- 按旧的过期位置反向扣减，导致新位置计数残留、旧位置重复扣减。
meta_set_position = function(key, si, x, y)
  local rec = storage[MARK_META] and storage[MARK_META][key]
  if not rec then return end
  rec.surface_index = si
  rec.x = x
  rec.y = y
end

-- 实体被标记拆除（回收：实体类别 + 内部物品/模块为物品类别）。
-- 除登记正向变更外，把每条变更记入元信息，供取消拆除时反向回滚。
local function on_decon_marked(entity)
  if not (entity and entity.valid and entity.position) then return end
  local si = entity.surface.index
  local x, y = entity.position.x, entity.position.y
  local is_tile_proxy = (entity.type == "deconstructible-tile-proxy")

  -- 注册销毁事件 + 确定元信息 key。
  -- 有 unit_number 的实体：key = "u:unit"，取消/完成都用它定位。
  -- 无 unit_number 的实体（环境实体/落地物品/地格代理）：取消时实体仍有效，用位置
  -- key "p:si:x,y"；完成时实体已销毁、事件只带 registration_number，故把同一份
  -- 元信息同时登记到 "r:reg"，供完成回滚精确定位（on_destroyed 对 useful_id=0 的
  -- 实体按 registration_number 反查）。
  local reg = nil
  local key = mark_meta_key(entity)
  if not key then return end
  if entity.unit_number then
    pcall(function() script.register_on_object_destroyed(entity) end)
  else
    local okreg, r = pcall(function() return script.register_on_object_destroyed(entity) end)
    if okreg and r then reg = r end
  end
  meta_ensure(key, si, x, y)
  if reg then
    storage[MARK_META]["r:" .. tostring(reg)] = storage[MARK_META][key]
    storage[MARK_META][key].reg = reg
  end

  if is_tile_proxy then
    local tile = entity.surface.get_tile(math.floor(x), math.floor(y))
    local item = tile and item_for_tile(tile.name)
    if item then
      add_count_change(CHG_TILE_RECYCLE, si, x, y, item, 1)
      meta_add_change(key, CHG_TILE_RECYCLE, item, 1)
    end
    return
  end
  -- 记录移动实体快照（标记拆除的可移动实体可能在建设区域内移动）。
  -- record_decon_mover 会扫描内容物并存为快照；对 needs_decon_tracking 的实体返回
  -- 该 stock 表，下方直接复用，避免对同一实体重复扫描库存（大范围拆除时很贵）。
  local stock = record_decon_mover(entity)
  -- 普通实体（含落地物品、环境实体、容器、传送带、机械臂）
  local ent_item = item_for_entity(entity.name)
  if ent_item then
    add_count_change(CHG_ENTITY_RECYCLE, si, x, y, ent_item, 1)
    meta_add_change(key, CHG_ENTITY_RECYCLE, ent_item, 1)
  end
  -- 内部物品/模块 + 落地物品/环境实体/传送带/机械臂 —— 统一走物品类别回收。
  -- 若已由 record_decon_mover 扫描（stock 非 nil），直接复用其结果；
  -- 否则（静态无内容/环境/落地物品）单独扫描一次。
  local item_tbl = stock or {}
  if not stock then
    recycle_entity_contents(entity, false, true, item_tbl)
  end
  for item, n in pairs(item_tbl) do
    add_count_change(CHG_ITEM_RECYCLE, si, x, y, item, n)
    meta_add_change(key, CHG_ITEM_RECYCLE, item, n)
  end
end

-- 实体被标记升级：目标实体供给（升级类别）+ 原实体回收（升级类别）。
-- 同样记录元信息，供取消升级时反向回滚。
local function on_upgrade_marked(entity)
  if not (entity and entity.valid and entity.position) then return end
  local si = entity.surface.index
  local x, y = entity.position.x, entity.position.y
  local key = mark_meta_key(entity)
  meta_ensure(key, si, x, y)
  -- 关键：必须注册实体销毁事件。升级完成时旧实体被移除并替换为新实体，
  -- 需靠 on_object_destroyed 触发 rollback_entity_by_unit 反向扣减供给与回收，
  -- 否则升级完成后计数残留不更新。
  pcall(function() script.register_on_object_destroyed(entity) end)
  local target = entity.get_upgrade_target()
  local new_item = target and item_for_entity(target.name)
  if new_item then
    add_count_change(CHG_UPGRADE_SUPPLY, si, x, y, new_item, 1)
    meta_add_change(key, CHG_UPGRADE_SUPPLY, new_item, 1)
  end
  local old_item = item_for_entity(entity.name)
  if old_item then
    add_count_change(CHG_UPGRADE_RECYCLE, si, x, y, old_item, 1)
    meta_add_change(key, CHG_UPGRADE_RECYCLE, old_item, 1)
  end
end

-- 取消拆除/升级：依据元信息生成反向变更（count 取负），并清除元信息记录。
-- 返回是否有反向变更被登记（供调用方决定是否 mark_pending）。
-- 若无元信息记录（如加载后旧存档无 meta），返回 false，调用方可退化为全量重建。
local function rollback_entity(entity)
  if not (entity and entity.valid) then return false end
  local key = mark_meta_key(entity)
  if not key then return false end
  local rec = storage[MARK_META] and storage[MARK_META][key]
  if not rec or not rec.changes or not rec.surface_index then return false end
  local si = rec.surface_index or entity.surface.index
  local x, y = rec.x or entity.position.x, rec.y or entity.position.y
  for _, c in ipairs(rec.changes) do
    add_count_change(c.kind, si, x, y, c.item, -(c.count or 1))
  end
  storage[MARK_META][key] = nil
  -- 清理 registration 别名（若该无 unit 实体同时登记了 "r:reg"）
  if rec.reg and storage[MARK_META]["r:" .. tostring(rec.reg)] == rec then
    storage[MARK_META]["r:" .. tostring(rec.reg)] = nil
  end
  return true
end

-- 实体销毁时清理其元信息（防止残留）
local function clear_mark_meta(entity)
  local key = mark_meta_key(entity)
  if key and storage[MARK_META] then storage[MARK_META][key] = nil end
end

-- 落地物品（item-entity）取消拆除的精确回滚兜底。
-- 落地物品无 unit_number 且会漂移，位置 key 在标记与取消之间可能失效（has_rec=false），
-- 此时若走全量重建兜底会误触发 WARN 并全量重扫该区域。落地物品的回收内容 = 其 stack，
-- 取消时实体仍有效、stack 仍可读，故直接按当前 stack 反向生成 CHG_ITEM_RECYCLE 即可精确回滚。
-- 返回是否有反向变更被登记。
local function rollback_ground_item(entity)
  if not (entity and entity.valid and entity.type == "item-entity") then return false end
  local st = entity.stack
  if not st or not st.valid_for_read then return false end
  local item = st.name
  local n = st.count
  if not item or not n or n <= 0 then return false end
  if not entity.position then return false end
  local si = entity.surface.index
  add_count_change(CHG_ITEM_RECYCLE, si, entity.position.x, entity.position.y, item, -n)
  return true
end

-- 按 unit_number 反向扣减（实体已销毁、无法访问 entity 时用，如 on_object_destroyed）。
-- 从元信息读 surface_index/x/y 与变更记录，生成反向变更后清除记录。
-- 返回是否有反向变更被登记。
local function rollback_entity_by_unit(unit)
  if not unit then return false end
  local key = "u:" .. tostring(unit)
  local rec = storage[MARK_META] and storage[MARK_META][key]
  if not rec or not rec.changes or not rec.surface_index then return false end
  local si, x, y = rec.surface_index, rec.x, rec.y
  for _, c in ipairs(rec.changes) do
    add_count_change(c.kind, si, x, y, c.item, -(c.count or 1))
  end
  storage[MARK_META][key] = nil
  return true
end

-- 按 registration_number 反向扣减（无 unit_number 的实体：环境实体/落地物品/
-- 地格代理用。on_object_destroyed 的 useful_id=0，故用 register_on_object_destroyed
-- 返回的 registration_number 反查元信息，精确定位要回滚的位置）。
-- 返回是否有反向变更被登记。
local function rollback_entity_by_registration(reg)
  if not reg or reg == 0 then return false end
  local key = "r:" .. tostring(reg)
  local rec = storage[MARK_META] and storage[MARK_META][key]
  if not rec or not rec.changes or not rec.surface_index then return false end
  local si, x, y = rec.surface_index, rec.x, rec.y
  for _, c in ipairs(rec.changes) do
    add_count_change(c.kind, si, x, y, c.item, -(c.count or 1))
  end
  storage[MARK_META][key] = nil
  -- 清理位置 key 别名（同一份元信息同时登记在 "r:reg" 与 "p:si:x,y"）
  if rec.main_key and storage[MARK_META][rec.main_key] == rec then
    storage[MARK_META][rec.main_key] = nil
  end
  return true
end

-- 实体内容物表：被拆除实体的全部内容物（内部物品/插件 + 传送带货物 + 机械臂
-- 手持物），返回 { [item] = count }。用于 on_tick 检测机器人拆除过程中内容物
-- 被逐步搬走的变化，并据此做精确增量撤销/重加。
local function content_items(entity)
  local tbl = {}
  if entity and entity.valid then
    recycle_entity_contents(entity, false, true, tbl)
  end
  return tbl
end

-- 记录一个被标记拆除的移动实体快照（entity + 位置 + 内容物表），供 on_tick 检测
-- 进出建设区域与内容物（内部物品/插件/传送带货物/机械臂手持物）变化。
-- 仅对"移动或内容变化会影响计数归属"的实体记录：有 unit_number 且
-- needs_decon_tracking（可能移动或携带内容物）。落地物品/环境实体/静态无内容
-- 建筑（管道/灯/墙等）跳过，避免为海量实体做无效每帧轮询。
-- 返回本次扫描出的内容物表 stock（供调用方复用，避免对同一实体重复扫描库存）。
record_decon_mover = function(entity)
  if not (entity and entity.valid and entity.position and entity.unit_number) then return nil end
  if not items.needs_decon_tracking(entity) then return nil end
  local stock = content_items(entity)   -- 旧内容物表 { [item]=count }
  storage[DECON_MOVERS] = storage[DECON_MOVERS] or {}
  -- 存实体引用（借鉴 item-request-proxy-events）：轮询直接用引用读取内容物，
  -- 避免 find/get_entity_by_unit_number（后者对普通实体不可靠）。引用在 storage
  -- 跨 tick 有效，失效时 entity.valid==false 即清理快照。
  storage[DECON_MOVERS][entity.unit_number] = {
    entity = entity,
    surface_index = entity.surface.index,
    x = entity.position.x,
    y = entity.position.y,
    stock = stock,
    movable = items.is_movable(entity),   -- 是否可移动（需位置检测）；否则只做内容检测
  }
  return stock
end

-- 清除移动实体快照
clear_decon_mover = function(entity)
  if not entity then return end
  local u = entity.unit_number
  if u and storage[DECON_MOVERS] then storage[DECON_MOVERS][u] = nil end
end

M.on_reader_removed = on_reader_removed
M.on_port_added = on_port_added
M.on_port_removed = on_port_removed
M.on_entity_ghost_built = on_entity_ghost_built
M.on_tile_ghost_built = on_tile_ghost_built
M.on_decon_marked = on_decon_marked
M.on_upgrade_marked = on_upgrade_marked
M.rollback_entity = rollback_entity
M.rollback_ground_item = rollback_ground_item
M.rollback_entity_by_unit = rollback_entity_by_unit
M.rollback_entity_by_registration = rollback_entity_by_registration
M.clear_mark_meta = clear_mark_meta
M.content_items = content_items
M.meta_set_items = meta_set_items
M.meta_set_position = meta_set_position
M.record_decon_mover = record_decon_mover
M.clear_decon_mover = clear_decon_mover

return M



