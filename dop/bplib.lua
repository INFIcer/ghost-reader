-- dop/bplib.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 蓝图 tags 配置持久化（bplib）。
--
-- 读取器的 mode/filter/qty 存于 mod storage（storage.readers），不污染电路。
-- 为了让配置随复制/蓝图继承，借助 bplib：
--   * 蓝图提取时（bplib-extract）把配置写入蓝图实体的 per-entity tags；
--   * 蓝图放置前（bplib-positions）按世界位置记录待应用配置；
--   * 蓝图重叠放置（bplib-overlaps）直接应用到已存在的读取器；
--   * 玩家生成蓝图（on_player_setup_blueprint）作为直连 fallback 也写 tags。
-- 放置时（on_built_entity 的 reader/ghost 分支）读取 e.tags 或 pending_tags 应用。
--
-- 关键：只处理名为 READER 的实体（含其虚影），恒压器永不被标记/误认（不跨类型）。

local constants = require("__ghost-reader__/dop/constants")
local config = require("__ghost-reader__/dop/config")
local changes = require("__ghost-reader__/dop/changes")
local M = {}

local READER = constants.READER
local TAG_MODE = "gr_mode"
local TAG_FILTER = "gr_filter"
local TAG_QTY = "gr_qty"

-- 位置 key（用于 pending_tags 按世界位置记录）
local function pos_key(surface_index, pos)
  if not (pos and pos.x and pos.y) then return nil end
  return surface_index .. ":" .. math.floor(pos.x) .. "," .. math.floor(pos.y)
end

-- 读取器（真实或虚影）判断
local function is_reader_entity(en)
  return en and en.valid
    and (en.name == READER or (en.type == "entity-ghost" and en.ghost_name == READER))
end

-- 把读取器配置写入蓝图实体 tags
local function write_reader_tags(blueprint, index, reader)
  local cfg = config.reader_config(reader.unit_number)
  pcall(function()
    blueprint.set_blueprint_entity_tags(index, {
      [TAG_MODE] = cfg.mode,
      [TAG_FILTER] = cfg.filter,
      [TAG_QTY] = cfg.qty,
    })
  end)
end

-- 从蓝图实体 tags 读配置（无则 nil）
local function read_reader_tags(blueprint, index)
  local ok, tags = pcall(function() return blueprint.get_blueprint_entity_tags(index) end)
  if not (ok and tags) then return nil end
  local cfg = {}
  if tags[TAG_MODE] then cfg.mode = tags[TAG_MODE] end
  if tags[TAG_FILTER] then cfg.filter = tags[TAG_FILTER] end
  if tags[TAG_QTY] then cfg.qty = tags[TAG_QTY] end
  if cfg.mode or cfg.filter or cfg.qty then return cfg end
  return nil
end

-- 从实体自带 tags 读配置（蓝图放置的虚影/实体，tags 随 build 复制）
local function read_entity_tags_cfg(entity)
  local t = entity.tags
  if not t then return nil end
  local cfg = {}
  if t[TAG_MODE] then cfg.mode = t[TAG_MODE] end
  if t[TAG_FILTER] then cfg.filter = t[TAG_FILTER] end
  if t[TAG_QTY] then cfg.qty = t[TAG_QTY] end
  if cfg.mode or cfg.filter or cfg.qty then return cfg end
  return nil
end

-- bplib-extract：reader 被拷入用户蓝图 → 写配置到 tags
local function on_bplib_extract(event)
  if not (event and event.blueprint and event.entities) then return end
  for index, entity in pairs(event.entities) do
    if is_reader_entity(entity) then
      write_reader_tags(event.blueprint, index, entity)
    end
  end
end

-- bplib-positions：蓝图即将放置 → 按世界位置记录待应用配置
local function on_bplib_positions(event)
  if not (event and event.blueprint and event.positions) then return end
  local entities = event.blueprint.get_blueprint_entities()
  for index, pos in pairs(event.positions) do
    local e = entities and entities[index]
    if e and e.name == READER then
      local cfg = read_reader_tags(event.blueprint, index)
      if cfg then
        local key = pos_key(event.surface_index or 1, pos)
        if key then
          storage.pending_tags = storage.pending_tags or {}
          storage.pending_tags[key] = cfg
        end
      end
    end
  end
end

-- bplib-overlaps：蓝图放置覆盖到已有读取器 → 直接应用配置
local function on_bplib_overlaps(event)
  if not (event and event.blueprint and event.overlaps) then return end
  local entities = event.blueprint.get_blueprint_entities()
  for index, overlapped in pairs(event.overlaps) do
    if overlapped and overlapped.valid and overlapped.unit_number then
      if is_reader_entity(overlapped) then
        local e = entities and entities[index]
        if e and e.name == READER then
          local cfg = read_reader_tags(event.blueprint, index)
          if cfg then
            config.apply_config(overlapped.unit_number, cfg)
            -- 配置变化 → 标记该读取器脏并触发重算
            changes.mark_reader_dirty(overlapped)
            storage[constants.DIRTY_FLAG] = true
          end
        end
      end
    end
  end
end

-- on_player_setup_blueprint fallback：创建蓝图时直接写 tags（更稳健，不依赖 bplib 解析）
local function on_player_setup_blueprint(event)
  local stack = event.stack
  if not (stack and stack.valid_for_read and event.mapping) then return end
  local mapping = event.mapping.get()
  if not mapping then return end
  for index, entity in pairs(mapping) do
    if is_reader_entity(entity) then
      local cfg = config.reader_config(entity.unit_number)
      pcall(function()
        stack.set_blueprint_entity_tags(index, {
          [TAG_MODE] = cfg.mode,
          [TAG_FILTER] = cfg.filter,
          [TAG_QTY] = cfg.qty,
        })
      end)
    end
  end
end

-- 蓝图放置时应用配置（供 on_built_entity 的 reader/ghost 分支调用）。
-- 配置来源优先级：
--   1. 实体自带 tags（e.tags）——虚影/实体从蓝图继承的 per-entity tags；
--   2. pending_tags —— bplib-positions 按世界位置记录的待应用配置；
--   3. ghost_cfg —— 虚影阶段按位置保存的配置（供真实读取器构建时继承，
--      因为虚影与真实读取器的 unit_number 不同）。
-- 应用后把配置按位置存到 storage.ghost_cfg，供后续"虚影建成真实读取器"继承。
local function apply_reader_config_from_tags(entity)
  if not (entity and entity.valid and entity.unit_number) then return end
  local unit = entity.unit_number
  local cfg = read_entity_tags_cfg(entity)
  local key = entity.position and pos_key(entity.surface.index, entity.position)
  if not cfg and key then
    cfg = storage.pending_tags and storage.pending_tags[key]
    if cfg and storage.pending_tags then storage.pending_tags[key] = nil end
  end
  if not cfg and key then
    cfg = storage.ghost_cfg and storage.ghost_cfg[key]
    if cfg and storage.ghost_cfg then storage.ghost_cfg[key] = nil end
  end
  if cfg then
    config.apply_config(unit, cfg)
    -- 按位置记录，供真实读取器构建（新 unit）继承
    if key then
      storage.ghost_cfg = storage.ghost_cfg or {}
      storage.ghost_cfg[key] = cfg
    end
    changes.mark_reader_dirty(entity)
    storage[constants.DIRTY_FLAG] = true
    log("[ghost-reader][INHERIT] applied cfg to unit="..tostring(unit)
      .." key="..tostring(key).." mode="..tostring(cfg.mode).." filter="..tostring(cfg.filter)
      .." qty="..tostring(cfg.qty).." name="..tostring(entity.name).." type="..tostring(entity.type))
  end
end

M.is_reader_entity = is_reader_entity
M.apply_reader_config_from_tags = apply_reader_config_from_tags
M.on_bplib_extract = on_bplib_extract
M.on_bplib_positions = on_bplib_positions
M.on_bplib_overlaps = on_bplib_overlaps
M.on_player_setup_blueprint = on_player_setup_blueprint

return M

