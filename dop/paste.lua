-- dop/paste.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 复制粘贴配置处理。
--
-- 两个目的：
--   1. 阻止"虚影读取器 <-> 常量运算器"之间的配置复制粘贴。两者都是
--      constant-combinator 类型，原版会允许 Shift+复制互传（污染电路信号），
--      必须彻底隔离。
--   2. 允许"虚影读取器 -> 虚影读取器"（含虚影）复制粘贴配置（mode/filter/qty）。
--
-- 机制：
--   * on_pre_entity_settings_pasted（原生粘贴前）：若是跨类型粘贴，快照目标的
--     控制行为，并尝试清空 entity_copy_source 取消原生粘贴。
--   * on_entity_settings_pasted（原生粘贴后）：若是跨类型粘贴，从快照恢复目标；
--     若是 reader->reader，读取源配置应用到目标并触发重算。

local constants = require("__ghost-reader__/dop/constants")
local config = require("__ghost-reader__/dop/config")
local changes = require("__ghost-reader__/dop/changes")
local M = {}

local READER = constants.READER
local MAX_SLOTS = constants.MAX_SLOTS
local VANILLA_COMBINATOR = "constant-combinator"

-- 是否为读取器（真实或虚影）
local function is_reader_kind(en)
  return en.name == READER or (en.type == "entity-ghost" and en.ghost_name == READER)
end

-- 是否为原版恒压器（真实或虚影）
local function is_vanilla_kind(en)
  return en.name == VANILLA_COMBINATOR or (en.type == "entity-ghost" and en.ghost_name == VANILLA_COMBINATOR)
end

-- 是否为 reader<->vanilla 跨类型粘贴（双向）
local function is_cross_type_paste(source, destination)
  local src_reader = is_reader_kind(source)
  local dst_reader = is_reader_kind(destination)
  local src_vanilla = is_vanilla_kind(source)
  local dst_vanilla = is_vanilla_kind(destination)
  return (src_reader and dst_vanilla) or (src_vanilla and dst_reader)
end

-- 快照一个恒压器的完整控制行为（所有 section 的所有插槽），用于被污染后恢复。
local function snapshot_control_behavior(entity)
  local ok_cb, cb = pcall(function() return entity.get_or_create_control_behavior() end)
  if not (ok_cb and cb) then return nil end
  local sections = {}
  local count = cb.sections_count
  for s = 1, count do
    local ok_sec, section = pcall(function() return cb.get_section(s) end)
    if ok_sec and section then
      local slots = {}
      for i = 1, MAX_SLOTS do
        local ok_slot, slot = pcall(function() return section.get_slot(i) end)
        if ok_slot and slot and slot.value then
          slots[i] = { value = slot.value, min = slot.min, max = slot.max }
        end
      end
      sections[s] = { slots = slots }
    end
  end
  if #sections == 0 then return nil end
  return sections
end

-- 从快照恢复一个恒压器的控制行为。
local function restore_control_behavior(entity, sections)
  if not (entity and entity.valid and sections) then return end
  local ok_cb, cb = pcall(function() return entity.get_or_create_control_behavior() end)
  if not (ok_cb and cb) then return end
  for s, data in ipairs(sections) do
    local ok_sec, section = pcall(function() return cb.get_section(s) end)
    if not (ok_sec and section) then
      ok_sec, section = pcall(function() return cb.add_section("") end)
    end
    if ok_sec and section then
      section.filters = {}
      for i, slot in pairs(data.slots or {}) do
        pcall(function()
          section.set_slot(i, { value = slot.value, min = slot.min, max = slot.max })
        end)
      end
    end
  end
end

-- 原生粘贴前：若跨类型，快照目标 + 尝试取消原生粘贴。
local function on_pre_settings_pasted(event)
  local source = event.source
  local destination = event.destination
  if not (source and source.valid and destination and destination.valid) then return end
  if is_cross_type_paste(source, destination) then
    local snapshot = snapshot_control_behavior(destination)
    if snapshot and destination.unit_number then
      storage.paste_undo = storage.paste_undo or {}
      storage.paste_undo[destination.unit_number] = snapshot
    end
    -- 尽力取消原生粘贴
    local player = event.player_index and game.get_player(event.player_index)
    if player then player.entity_copy_source = nil end
  end
end

-- 原生粘贴后：跨类型 → 恢复目标；reader->reader → 继承配置。
local function on_settings_pasted(event)
  local source = event.source
  local target = event.destination
  if not (source and source.valid and target and target.valid) then return end
  -- 跨类型：撤销（恢复目标原控制行为）
  if is_cross_type_paste(source, target) then
    if target.unit_number and storage.paste_undo and storage.paste_undo[target.unit_number] then
      restore_control_behavior(target, storage.paste_undo[target.unit_number])
      storage.paste_undo[target.unit_number] = nil
    end
    return
  end
  -- reader->reader（含虚影）继承配置
  if not is_reader_kind(source) or not is_reader_kind(target) then return end
  local cfg = config.reader_config(source.unit_number)
  local tgt_unit = target.unit_number
  if cfg and tgt_unit then
    config.apply_config(tgt_unit, cfg)
    -- 配置变化 → 标记该读取器脏并触发重算
    changes.mark_reader_dirty(tgt_unit)
    storage[constants.DIRTY_FLAG] = true
  end
end

M.is_reader_kind = is_reader_kind
M.on_pre_settings_pasted = on_pre_settings_pasted
M.on_settings_pasted = on_settings_pasted

return M
