-- dop/changes.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 变更列表（事件缓冲）+ 脏读取器列表。
--
-- 所有的增删事件（建虚影、拆实体、加平台、建读取器……）都不直接重扫，而是
-- 登记到对应的变更列表。on_tick 帧末统一消费这些列表，增量更新归属地元信息，
-- 然后清空列表。这样：
--   * 一帧内无论发生多少事件，归属地元信息最多更新一遍。
--   * 增量更新，不再每帧全量重扫。
--
-- 只维护本 Mod 实际需要的变更列表：
--   surface_added   : { [surface_index] = true }                        新增表面
--   surface_removed : { [surface_index] = true }                        删除表面
--   port_added      : { [port_unit] = {surface_index,x,y,crad,net_id} } 新增平台
--   port_removed    : { [port_unit] = true }                            删除平台
--   reader_added    : { [reader_unit] = surface_index }                 新增读取器
--   reader_removed  : { [reader_unit] = true }                          删除读取器
--   count_changes   : { {kind,surface_index,x,y,item,count} }             计数增量变化
--
-- 注意：变更表存在 storage（持久化），但各模块通过本模块的 current() 拿到
-- 当前表引用；reset_changes() 会替换该表并同步重指模块内引用（修复了原
-- control_dop.lua 中"局部变量 C 捕获旧表、reset 后失效"的问题）。

local constants = require("__ghost-reader__/dop/constants")
local M = {}

local CHANGES = constants.CHANGES
local DIRTY_READERS = constants.DIRTY_READERS

-- 当前变更表（模块内可变引用；reset_changes 会重指）
local current

local function new_changes()
  return {
    surface_added = {},
    surface_removed = {},
    port_added = {},
    port_removed = {},
    reader_added = {},
    reader_removed = {},
    count_changes = {},
  }
end

-- 初始化（首次从 storage 读取或新建）
if not storage[CHANGES] then
  storage[CHANGES] = new_changes()
end
current = storage[CHANGES]

-- 清空所有变更列表（帧末调用），并同步模块内引用
local function reset_changes()
  current = new_changes()
  storage[CHANGES] = current
end

-- 返回当前变更表（供各模块读写字段）
local function current_changes()
  return current
end

-- 往变更列表登记一条计数变更（某物品在某位置的供给/回收增减）。
-- kind: CHG_* 常量（覆盖实体/地格/物品/升级各类别）；
-- surface_index/x/y: 变化点位置；item: 影响的物品名；count: 增减量（可为负，用于回滚）。
local function add_count_change(kind, surface_index, x, y, item, count)
  current.count_changes[#current.count_changes + 1] = {
    kind = kind,
    surface_index = surface_index,
    x = x,
    y = y,
    item = item,
    count = count or 1,
  }
end

-- 往 dirty 的读取器列表登记（归属地脏：该读取器需要重算归属地）
local function mark_reader_dirty(unit)
  storage[DIRTY_READERS] = storage[DIRTY_READERS] or {}
  storage[DIRTY_READERS][unit] = true
end

M.current_changes = current_changes
M.reset_changes = reset_changes
M.add_count_change = add_count_change
M.mark_reader_dirty = mark_reader_dirty

return M


