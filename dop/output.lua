-- dop/output.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 幽灵读取器输出。
--
-- 把某个读取器的最终信号表写入其 control-behavior 插槽（信号集变化才重写），
-- 并刷新其悬浮提示（4 个字段，name/value 必须是 LocalisedString 数组）。

local constants = require("__ghost-reader__/dop/constants")
local config = require("__ghost-reader__/dop/config")
local regions_incr = require("__ghost-reader__/dop/regions_incr")
local M = {}

local READER = constants.READER
local MAX_SLOTS = constants.MAX_SLOTS
local MODE_SURFACE = constants.MODE_SURFACE
local REGION_NETWORK = constants.REGION_NETWORK
local get_mode = config.get_mode
local get_filter = config.get_filter
local get_qty = config.get_qty
local reader_region_cached = regions_incr.reader_region_cached

local function counts_fingerprint(counts)
  local parts = {}
  for item, count in pairs(counts) do
    parts[#parts+1] = tostring(item) .. ":" .. tostring(count)
  end
  table.sort(parts)
  return table.concat(parts, ";")
end

local function write_outputs(reader, counts)
  local unit = reader.unit_number
  if unit then
    local fp = counts_fingerprint(counts)
    storage.out_fp = storage.out_fp or {}
    if storage.out_fp[unit] == fp then return end
    storage.out_fp[unit] = fp
  end
  local cb = reader.get_or_create_control_behavior()
  if not cb then return end
  local section = cb.get_section(1)
  if not section then section = cb.add_section("") end
  if not section then return end
  section.filters = {}
  local i = 0
  for item, count in pairs(counts) do
    i = i + 1
    if i > MAX_SLOTS then break end
    pcall(function()
      section.set_slot(i, {value = {type = "item", name = item, quality = "normal"}, min = count})
    end)
  end
end

-- 状态文本（GUI + tooltip 用）：【新地星】 / 【网络#7】 / 不在物流网络内
local function status_localised(reader)
  local unit = reader and reader.unit_number
  local rtype, id = reader_region_cached(unit, reader)
  if rtype == REGION_NETWORK and id then
    return {"", "【", {"gr-gui.network-prefix"}, tostring(id), "】"}
  end
  if rtype == REGION_NETWORK then
    return {"gr-gui.status-no-network"}
  end
  local surface = reader and reader.surface
  if surface then
    local ok, name = pcall(function()
      if surface.planet then return surface.planet.prototype.localised_name end
      return surface.name
    end)
    return {"", "【", (ok and name) or surface.name, "】"}
  end
  return {"gr-gui.status-no-network"}
end

-- 刷新悬浮提示（4 个字段）。name/value 必须为 LocalisedString 数组。
local function update_reader_tooltip(reader)
  if not (reader and reader.valid and reader.name == READER) then return end
  local unit = reader.unit_number
  if not unit then return end
  pcall(function()
    reader.clear_tooltip_fields()
    local mode = get_mode(unit)
    local filter = get_filter(unit)
    local qty = get_qty(unit)
    local mode_key = (mode == MODE_SURFACE) and "gr-gui.mode-surface" or "gr-gui.mode-network"
    local filter_key = "gr-gui.filter-" .. filter
    local qty_key = "gr-gui.qty-" .. qty
    local current = status_localised(reader)
    local fields = {
      {{"gr-tooltip.range-mode"}, {mode_key}},
      {{"gr-tooltip.current-range"}, current},
      {{"gr-tooltip.filter"}, {filter_key}},
      {{"gr-tooltip.qty"}, {qty_key}},
    }
    for i, f in ipairs(fields) do
      reader.set_tooltip_field{name = f[1], value = f[2], order = 50 + i}
    end
  end)
end

M.write_outputs = write_outputs
M.status_localised = status_localised
M.update_reader_tooltip = update_reader_tooltip

return M
