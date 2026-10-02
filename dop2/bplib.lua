-- dop2/bplib.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 蓝图 tags 配置持久化（bplib）。
--
-- 读取器配置存在 mod 存档里（storage.readers[unit]），不会随复制/蓝图继承。
-- 借助 bplib 提供的三个自定义事件，把配置写进蓝图实体的 per-entity tags 随蓝图传播：
--   bplib-extract    实体被拷入蓝图 → 把该实体当前的配置写进对应蓝图实体的 tags；
--   bplib-positions  蓝图即将放置   → 按世界位置记下待应用配置（放置出的虚影会用到）；
--   bplib-overlaps   蓝图盖到已有读取器上 → 直接把配置应用到那个已存在的读取器。
-- 另有一条不依赖 bplib 的兜底：on_player_setup_blueprint 在生成蓝图时直接写 tags。
--
-- tags 只支持基本类型，而枚举值（range_mode/filter_mode/count_mode）本身就是稳定
-- 字符串（surface/network、all/entity/...、net/supply/recycle），故直接写入 tags；读回
-- 时用合法取值集合校验，丢弃外来或过期的值。该取值与 dop 旧版写进 tags 的完全一致，
-- 所以旧蓝图（甚至旧版写的蓝图）也能被正确读回。
--
-- 配置的传递链（虚影与真实读取器的 unit_number 不同，必须靠位置接力）：
--   1. 虚影建成时读自身 tags（蓝图放置的虚影带 tags）→ 应用到该虚影的配置；
--   2. 同时按位置留下 ghost_cfg；
--   3. 同位置的真实读取器建成时，entity.tags 为 nil（tags 只存在于 entity-ghost 上），
--      依次回退 pending_tags → ghost_cfg，从而继承虚影阶段定下的配置。
--
-- 只处理读取器（真实实体及其虚影），恒压器永不被标记，故不会跨类型串配置。

local config = require("__ghost-reader__/dop2/config")
local meta = require("__ghost-reader__/dop2/meta")
local changes = require("__ghost-reader__/dop2/changes")

---模块对外暴露部分
local M = {}
--================================================================================================

---蓝图 tags 键名
local TAG_MODE = "gr_mode"
local TAG_FILTER = "gr_filter"
local TAG_COUNT = "gr_count"
local TAG_QUALITY = "gr_quality"

---枚举的合法取值集合缓存（读取 tags 时用来剔除外来/过期的值）
---@type table<string,table<any,true>>|nil
local valid_values_cache

---枚举的合法取值：mode/filter/count。
---枚举值本身就是稳定字符串（见 enum.lua），与 dop 旧版写进 tags 的取值一致，
---所以写 tags 时直接写枚举值即可，无需再做一层转换；这里只用于读回时校验。
---在调用时构造，不假定模块加载顺序（枚举是全局表）。
---@return table<string,table<any,true>>
local function valid_values()
    if not valid_values_cache then
        valid_values_cache = {
            mode = {
                [range_mode.SURFACE] = true,
                [range_mode.NETWORK] = true,
            },
            filter = {
                [filter_mode.ALL] = true,
                [filter_mode.ENTITY] = true,
                [filter_mode.TILES] = true,
                [filter_mode.UPGRADES] = true,
                [filter_mode.ITEMS] = true,
            },
            count = {
                [count_mode.NET] = true,
                [count_mode.SUPPLY] = true,
                [count_mode.RECYCLE] = true,
            },
        }
    end
    return valid_values_cache
end

---配置 → tags（四个值都是可直接序列化的字符串）
---@param cfg table 配置（config.reader_config 的返回值）
---@return Tags
local function encode(cfg)
    local tags = {}
    if cfg.mode then tags[TAG_MODE] = cfg.mode end
    if cfg.filter then tags[TAG_FILTER] = cfg.filter end
    if cfg.count then tags[TAG_COUNT] = cfg.count end
    if cfg.quality then tags[TAG_QUALITY] = cfg.quality end
    return tags
end

---tags → 配置（没有本 mod 的键、或取值不认识时返回 nil，表示"无配置"）
---@param tags Tags|nil
---@return table|nil
local function decode(tags)
    if not tags then return nil end
    local valid = valid_values()
    local cfg = {}
    --外来/过期的取值直接丢弃（例如别的 mod 同名的键、或旧版本换过取值）
    if valid.mode[tags[TAG_MODE]] then cfg.mode = tags[TAG_MODE] end
    if valid.filter[tags[TAG_FILTER]] then cfg.filter = tags[TAG_FILTER] end
    if valid.count[tags[TAG_COUNT]] then cfg.count = tags[TAG_COUNT] end
    --品质存的是品质名（"all" 表示不筛选），与 storage.readers 里的表示一致
    local quality_name = tags[TAG_QUALITY]
    if type(quality_name) == "string" then
        if quality_name == QUALITY_ALL or prototypes.quality[quality_name] then
            cfg.quality = quality_name
        end
    end
    if cfg.mode or cfg.filter or cfg.count or cfg.quality then return cfg end
    return nil
end

--================================================================================================
-- 位置与实体
--================================================================================================

---位置 key：表面号 + 格点坐标。
---用格点而非浮点：虚影与建成后的真实读取器位置可能有极小的浮点差异，同格内应视为同一位置。
---@param surface_index int
---@param position MapPosition
---@return string
local function pos_key(surface_index, position)
    return surface_index .. ":" .. math.floor(position.x) .. "," .. math.floor(position.y)
end

---实体是否是读取器（真实实体或其虚影）
---@param entity LuaEntity|nil
---@return boolean
local function is_reader(entity)
    if not (entity and entity.valid) then return false end
    if entity.name == READER then return true end
    return entity.type == "entity-ghost" and entity.ghost_name == READER
end

---蓝图实体是否是读取器。
---蓝图里虚影既可能以其目标原型名（ghost-reader）出现，也可能以 entity-ghost + ghost_name 出现，两者都认。
---@param bp_entity table|nil 蓝图实体（get_blueprint_entities 的元素）
---@return boolean
local function is_reader_blueprint_entity(bp_entity)
    if not bp_entity then return false end
    if bp_entity.name == READER then return true end
    return bp_entity.name == "entity-ghost" and bp_entity.ghost_name == READER
end

---取实体应写进蓝图的配置：虚影自带的 tags 优先（照抄原蓝图配置，二次成蓝图不丢配置），
---否则取该实体在存档里的配置。
---@param entity LuaEntity
---@return table|nil
local function entity_config(entity)
    if entity.type == "entity-ghost" then
        local cfg = decode(entity.tags)
        if cfg then return cfg end
    end
    local unit = entity.unit_number
    if type(unit) == "number" then return config.reader_config(unit) end
end

---把一组配置应用到读取器实体
---@param entity LuaEntity 真实读取器或其虚影
---@param cfg table
local function apply_to_reader(entity, cfg)
    if not (entity and entity.valid) then return end
    local unit = entity.unit_number
    if type(unit) == "number" then config.apply_config(unit, cfg) end
    --虚影没有归属地与电路输出，只需记下配置；真实读取器要重算输出
    if entity.name == READER then
        local m = meta.ensure_reader_meta(entity)
        changes.dirty_reader_output(m)
    end
end

--================================================================================================
-- 蓝图读写
--================================================================================================

---把 tags 合并写入蓝图实体。
---先读回该条目已有的 tags 再合并，避免覆盖其它 mod 写在同一蓝图实体上的 tags。
---@param blueprint LuaItemStack|LuaRecord
---@param index uint32 蓝图实体序号
---@param tags Tags
local function write_tags(blueprint, index, tags)
    local merged = {}
    local ok, existing = pcall(function() return blueprint.get_blueprint_entity_tags(index) end)
    if ok and existing then
        for key, value in pairs(existing) do merged[key] = value end
    end
    for key, value in pairs(tags) do merged[key] = value end
    pcall(function() blueprint.set_blueprint_entity_tags(index, merged) end)
end

---读取蓝图实体上记录的配置
---@param blueprint LuaItemStack|LuaRecord
---@param index uint32 蓝图实体序号
---@return table|nil
local function read_tags(blueprint, index)
    local ok, tags = pcall(function() return blueprint.get_blueprint_entity_tags(index) end)
    if not (ok and tags) then return nil end
    return decode(tags)
end

--================================================================================================
-- bplib 事件
--================================================================================================

---bplib-extract：读取器被拷入蓝图 → 把配置写进对应蓝图实体的 tags
---@param event bplib.ExtractEvent
local function on_extract(event)
    local blueprint = event and event.blueprint
    if not (blueprint and event.entities) then return end
    for index, entity in pairs(event.entities) do
        if is_reader(entity) then
            local cfg = entity_config(entity)
            if cfg then write_tags(blueprint, index, encode(cfg)) end
        end
    end
end

---bplib-positions：蓝图即将放置 → 按世界位置记下待应用配置
---@param event bplib.PositionsEvent
local function on_positions(event)
    local blueprint = event and event.blueprint
    if not (blueprint and event.positions) then return end
    local entities = blueprint.get_blueprint_entities()
    if not entities then return end
    local surface_index = event.surface_index or 1
    for index, position in pairs(event.positions) do
        if is_reader_blueprint_entity(entities[index]) then
            local cfg = read_tags(blueprint, index)
            if cfg and position then
                storage.pending_tags = storage.pending_tags or {}
                storage.pending_tags[pos_key(surface_index, position)] = cfg
            end
        end
    end
end

---bplib-overlaps：蓝图盖到已存在的读取器上 → 直接把配置应用到那个读取器
---@param event bplib.OverlapsEvent
local function on_overlaps(event)
    local blueprint = event and event.blueprint
    if not (blueprint and event.overlaps) then return end
    local entities = blueprint.get_blueprint_entities()
    if not entities then return end
    for index, overlapped in pairs(event.overlaps) do
        if is_reader(overlapped) and is_reader_blueprint_entity(entities[index]) then
            local cfg = read_tags(blueprint, index)
            if cfg then apply_to_reader(overlapped, cfg) end
        end
    end
end

---on_player_setup_blueprint 兜底：生成蓝图时直接写 tags（不经过 bplib 的事件）
---@param event EventData.on_player_setup_blueprint
local function on_player_setup_blueprint(event)
    local stack = event.stack
    if not (stack and stack.valid_for_read and event.mapping) then return end
    local mapping = event.mapping.get()
    if not mapping then return end
    for index, entity in pairs(mapping) do
        if is_reader(entity) then
            local cfg = entity_config(entity)
            if cfg then write_tags(stack, index, encode(cfg)) end
        end
    end
end

--================================================================================================
-- 供主管线调用
--================================================================================================

---蓝图放置时应用配置（on_built_entity 的读取器/虚影分支调用）。
---@param entity LuaEntity 真实读取器或其虚影
function M.apply_reader_config_from_tags(entity)
    if not (entity and entity.valid) then return end
    local key = entity.surface and pos_key(entity.surface.index, entity.position) or nil
    --entity.tags 只存在于实体虚影上（LuaEntity.tags 的语义），真实读取器上没有
    local cfg
    if entity.type == "entity-ghost" then cfg = decode(entity.tags) end
    if not cfg and key and storage.pending_tags then
        cfg = storage.pending_tags[key]
        storage.pending_tags[key] = nil
    end
    if not cfg and key and storage.ghost_cfg then
        cfg = storage.ghost_cfg[key]
        storage.ghost_cfg[key] = nil
    end
    if not cfg then return end

    apply_to_reader(entity, cfg)
    --按位置留下配置，供同位置的虚影建成真实读取器时继承
    if key then
        storage.ghost_cfg = storage.ghost_cfg or {}
        storage.ghost_cfg[key] = cfg
    end
end

---把配置按位置记为待继承（GUI 改读取器虚影的配置时调用）。
---虚影与真实读取器的 unit_number 不同，只能靠位置把配置接力给建成后的真实读取器。
---@param entity LuaEntity 读取器虚影
---@param cfg table
function M.remember_config(entity, cfg)
    if not (entity and entity.valid and entity.surface) then return end
    storage.ghost_cfg = storage.ghost_cfg or {}
    storage.ghost_cfg[pos_key(entity.surface.index, entity.position)] = cfg
end

M.on_extract = on_extract
M.on_positions = on_positions
M.on_overlaps = on_overlaps
M.on_player_setup_blueprint = on_player_setup_blueprint

return M
