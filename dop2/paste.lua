-- dop2/paste.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 复制粘贴配置处理。
--
-- 两个目的：
--   1. 阻止"虚影读取器 <-> 原版恒压器"之间的配置复制粘贴。两者同为 constant-combinator
--      类型，原版允许 Shift+右键互传：粘贴会把读取器的输出信号灌进恒压器（或反之），
--      污染电路配置，必须彻底隔离。
--   2. 允许"虚影读取器 -> 虚影读取器"（含虚影）复制粘贴配置（范围/筛选/数量/品质）。
--
-- 机制：
--   * on_pre_entity_settings_pasted（原生粘贴前）：跨类型粘贴时先把目标的控制行为快照下来；
--   * on_entity_settings_pasted（原生粘贴后）：跨类型粘贴则按快照还原目标，读取器到读取器
--     则读取源配置应用到目标并置脏重算。
--
-- 真正的保证是"事后还原"而不是"取消粘贴"：即便取消不生效，粘贴造成的污染也会被还原掉。
-- 读取器的配置存在 storage 而非实体上，故复制粘贴只涉及配置的读写，与电路输出无关。

local changes = require("__ghost-reader__/dop2/changes")
local config = require("__ghost-reader__/dop2/config")
local meta = require("meta")
local bplib = require("__ghost-reader__/dop2/bplib")

---模块对外暴露部分
local M = {}
--================================================================================================

---原版恒压器原型名（与读取器同为 constant-combinator 类型，故必须隔离）
local VANILLA_COMBINATOR = "constant-combinator"

--================================================================================================
-- 类型判定
--================================================================================================

---是否读取器（真实实体或其虚影）
---@param entity LuaEntity|nil
---@return boolean
local function is_reader_kind(entity)
    if not (entity and entity.valid) then return false end
    if entity.name == READER then return true end
    return entity.type == "entity-ghost" and entity.ghost_name == READER
end

---是否原版恒压器（真实实体或其虚影）
---@param entity LuaEntity|nil
---@return boolean
local function is_vanilla_kind(entity)
    if not (entity and entity.valid) then return false end
    if entity.name == VANILLA_COMBINATOR then return true end
    return entity.type == "entity-ghost" and entity.ghost_name == VANILLA_COMBINATOR
end

---是否读取器 <-> 恒压器的跨类型粘贴（双向）
---@param source LuaEntity|nil
---@param destination LuaEntity|nil
---@return boolean
local function is_cross_type_paste(source, destination)
    return (is_reader_kind(source) and is_vanilla_kind(destination))
        or (is_vanilla_kind(source) and is_reader_kind(destination))
end

--================================================================================================
-- 控制行为快照 / 还原（跨类型粘贴时用来撤销污染）
--================================================================================================

---快照一个恒压器的控制行为：所有 section 的所有插槽。
---插槽数用 section.filters_count 取，不写死常量。
---@param entity LuaEntity
---@return table|nil 快照（{ {index=段号, slots={ {value,min,max}, ... }}, ... }），取不到则 nil
local function snapshot_control_behavior(entity)
    local ok, cb = pcall(function() return entity.get_or_create_control_behavior() end)
    if not (ok and cb) then return nil end

    local sections = {}
    for index = 1, cb.sections_count do
        local ok_section, section = pcall(function() return cb.get_section(index) end)
        if ok_section and section then
            local slots = {}
            for slot = 1, section.filters_count do
                local ok_filter, filter = pcall(function() return section.get_slot(slot) end)
                if ok_filter and filter and filter.value then
                    slots[slot] = { value = filter.value, min = filter.min, max = filter.max }
                end
            end
            sections[#sections + 1] = { index = index, slots = slots }
        end
    end
    if #sections == 0 then return nil end
    return sections
end

---按快照还原恒压器的控制行为
---@param entity LuaEntity
---@param sections table|nil 快照
local function restore_control_behavior(entity, sections)
    if not (entity and entity.valid and sections) then return end
    local ok, cb = pcall(function() return entity.get_or_create_control_behavior() end)
    if not (ok and cb) then return end

    for _, data in ipairs(sections) do
        local section = cb.get_section(data.index)
        if not section then section = cb.add_section("") end
        if section then
            --先清空：粘贴可能把信号塞进了这段的插槽
            section.filters = {}
            for slot, filter in pairs(data.slots) do
                pcall(function() section.set_slot(slot, filter) end)
            end
        end
    end
end

--================================================================================================
-- 事件
--================================================================================================

---原生粘贴前：跨类型粘贴时先快照目标
---@param event EventData.on_pre_entity_settings_pasted
function M.on_pre_settings_pasted(event)
    local source = event.source
    local destination = event.destination
    if not is_cross_type_paste(source, destination) then return end

    local snapshot = snapshot_control_behavior(destination)
    if snapshot and type(destination.unit_number) == "number" then
        storage.paste_undo = storage.paste_undo or {}
        storage.paste_undo[destination.unit_number] = snapshot
    end

    --尽力取消原生粘贴（该字段未必可写，故套 pcall）；真正的保证是粘贴后按快照还原
    local player = event.player_index and game.get_player(event.player_index)
    if player then
        pcall(function() player.entity_copy_source = nil end)
    end
end

---原生粘贴后：跨类型则还原目标；读取器 -> 读取器则继承配置
---@param event EventData.on_entity_settings_pasted
function M.on_settings_pasted(event)
    local source = event.source
    local target = event.destination
    if not (source and source.valid and target and target.valid) then return end

    --跨类型：撤销原生粘贴造成的污染
    if is_cross_type_paste(source, target) then
        local unit = target.unit_number
        local undo = type(unit) == "number" and storage.paste_undo and storage.paste_undo[unit]
        if undo then
            restore_control_behavior(target, undo)
            storage.paste_undo[unit] = nil
        end
        return
    end

    --读取器 -> 读取器（含虚影）：继承配置
    if not (is_reader_kind(source) and is_reader_kind(target)) then return end
    local unit = target.unit_number
    if type(unit) ~= "number" then return end
    local source_unit = source.unit_number
    if type(source_unit) ~= "number" then return end

    local cfg = config.reader_config(source_unit)
    config.apply_config(unit, cfg)

    local m = meta.get_meta_of(target)
    if m and target.name == READER then
        --真实读取器：配置变了要重算。范围模式会改变读取的归属地类型，索性两者都标脏
        changes.dirty_reader_region(m)
        changes.dirty_reader_output(m)
    else
        --读取器虚影：没有归属地与输出，把配置按位置记下，供建成真实读取器时继承
        bplib.remember_config(target, cfg)
    end
end

return M
