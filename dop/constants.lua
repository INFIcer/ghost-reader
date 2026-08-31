-- dop/constants.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 常量与存储键。
--
-- 集中存放所有常量（实体名、模式、筛选、数量、归属地类型、GUI 元素名、
-- 变更 kind、storage 键名），供其余模块 require 复用，避免各模块重复定义
-- 导致不一致。所有常量以一张表导出。

local M = {}

-- 实体与输出
M.READER = "ghost-reader"
M.MAX_SLOTS = 18            -- 恒压器每个 section 的插槽数

-- 检索范围模式
M.MODE_SURFACE = "surface"
M.MODE_NETWORK = "network"
M.DEFAULT_MODE = "network"

-- 筛选类别
M.FILTER_ALL      = "all"
M.FILTER_ENTITY   = "entity"
M.FILTER_TILES    = "tiles"
M.FILTER_UPGRADES = "upgrades"
M.FILTER_ITEMS    = "items"
M.DEFAULT_FILTER  = "all"

-- 数量模式：供给与回收如何合并
M.QTY_NET     = "net"       -- 供给 - 回收（净值，可为负）
M.QTY_SUPPLY  = "supply"    -- 只输出供给
M.QTY_RECYCLE = "recycle"   -- 只输出回收
M.DEFAULT_QTY = "net"

-- 归属地类型
M.REGION_SURFACE = "surface"
M.REGION_NETWORK = "network"

-- GUI 元素名
M.GUI_FRAME  = "ghost_reader_gui"
M.GUI_TABLE  = "ghost_reader_table"
M.GUI_STATUS = "ghost_reader_status"
M.GUI_MODE   = "ghost_reader_mode"
M.GUI_FILTER = "ghost_reader_filter"
M.GUI_QTY    = "ghost_reader_qty"

-- 实体变化 kind（供给/回收 × 类别）
M.CHG_ENTITY_SUPPLY  = "entity_supply"    -- 虚影：实体类别供给 +count
M.CHG_TILE_SUPPLY    = "tile_supply"      -- 地格虚影：地格类别供给
M.CHG_ITEM_SUPPLY    = "item_supply"      -- IRP：物品类别供给
M.CHG_ENTITY_RECYCLE = "entity_recycle"   -- 拆除：实体类别回收
M.CHG_TILE_RECYCLE   = "tile_recycle"     -- 拆除地格：地格类别回收
M.CHG_ITEM_RECYCLE   = "item_recycle"     -- 拆除容器内部/IRP移除：物品类别回收
M.CHG_UPGRADE_SUPPLY = "upgrade_supply"   -- 升级目标：升级类别供给
M.CHG_UPGRADE_RECYCLE= "upgrade_recycle"  -- 升级替换下的原实体：升级类别回收

-- storage 键名（面向数据：所有共享状态都显式存于 storage，便于读档持久化）
M.REGIONS        = "gr_dop_regions"        -- 归属地元信息表
M.CHANGES        = "gr_dop_changes"        -- 变更列表
M.DIRTY_READERS  = "gr_dop_dirty_readers"  -- 归属地脏的读取器列表
M.DIRTY_FLAG     = "gr_dop_dirty"          -- 一帧统一处理开关
M.READER_REGION  = "gr_dop_reader_region"  -- 读取器当前归属表
M.IRP_SNAPS      = "gr_dop_irp_snaps"      -- IRP 指纹快照
M.IRP_POLL_PER_TICK = 8                    -- IRP 每 tick 轮询上限
M.DECON_POLL_PER_TICK = 1                  -- 拆除移动实体每 tick 内容物轮询上限（借鉴 IRP 分批）
M.MARK_META      = "gr_dop_mark_meta"      -- 拆除/升级标记的变更元信息（供取消回滚）
M.DECON_MOVERS   = "gr_dop_decon_movers"   -- 拆除标记的移动实体位置快照（供进出建设区域检测）
M.DECON_POLL_INDEX = "gr_dop_decon_poll_index" -- 拆除实体轮询游标（round-robin）

-- 把一个 position 换算成格点坐标 { x, y }（均为整数）。
-- 进出建设区域只取决于实体所在格点，用格点精度可避免浮点抖动导致的位置变化
-- 误触发（同一格内微移不重算），且判断仍准确。Factorio 中格 N 的中心在
-- position = N + 0.5，故 math.floor(x) 即格点索引（负坐标也正确）。
local function tile_pos(pos)
  if not pos then return nil end
  return { x = math.floor(pos.x), y = math.floor(pos.y) }
end

M.tile_pos = tile_pos

return M
