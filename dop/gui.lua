-- dop/gui.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— GUI（构建/渲染/事件）。
--
-- 仅作展示，与 DOP 性能无关。构建读取器面板（范围模式/筛选/数量三个下拉 +
-- 状态 + 信号表），并处理 GUI 开/关/点击/下拉事件。配置变更通过注入的
-- on_config_changed 回调通知主管线（标记归属地脏）。

local constants = require("__ghost-reader__/dop/constants")
local config = require("__ghost-reader__/dop/config")
local regions_incr = require("__ghost-reader__/dop/regions_incr")
local regions = require("__ghost-reader__/dop/regions")
local output = require("__ghost-reader__/dop/output")
local M = {}

local READER = constants.READER
local MODE_SURFACE = constants.MODE_SURFACE
local MODE_NETWORK = constants.MODE_NETWORK
local FILTER_ALL, FILTER_ENTITY, FILTER_TILES, FILTER_UPGRADES, FILTER_ITEMS =
  constants.FILTER_ALL, constants.FILTER_ENTITY, constants.FILTER_TILES, constants.FILTER_UPGRADES, constants.FILTER_ITEMS
local QTY_NET, QTY_SUPPLY, QTY_RECYCLE = constants.QTY_NET, constants.QTY_SUPPLY, constants.QTY_RECYCLE
local GUI_FRAME, GUI_TABLE, GUI_STATUS, GUI_MODE, GUI_FILTER, GUI_QTY =
  constants.GUI_FRAME, constants.GUI_TABLE, constants.GUI_STATUS, constants.GUI_MODE, constants.GUI_FILTER, constants.GUI_QTY
local REGIONS = constants.REGIONS

local get_mode = config.get_mode
local get_filter = config.get_filter
local get_qty = config.get_qty
local set_mode = config.set_mode
local set_filter = config.set_filter
local set_qty = config.set_qty
local reader_region_cached = regions_incr.reader_region_cached
local status_localised = output.status_localised

-- 输出缓存：{ [region_key.."|"..filter.."|"..qty] = 最终信号表 }
-- 同一网络/表面 + 同一筛选/数量配置的读取器共享同一份合并结果，避免每读取器重复 merge。
-- 计数在每脏 tick 会变，故每脏 tick 渲染前由 main 调用 reset_output_cache 清空。
local out_cache = {}
local function reset_output_cache()
  out_cache = {}
end

-- 配置变更回调（由 main 注入：标记归属地脏 + 置位 pending）
local on_config_changed = nil
local function set_config_changed_hook(fn)
  on_config_changed = fn
end

-- combine_counts 由 main 注入（避免循环依赖：main require gui，gui 用 combine）
local combine = nil
local function set_combine_fn(fn)
  combine = fn
end

-- 类别合并函数（由 main 注入）：给定归属地与 filter，返回 {supply, recycle}
-- 两个扁平 item->count 表（把 filter 对应的类别合并）。
local merge_counts_for_filter = nil
local function set_merge_fn(fn)
  merge_counts_for_filter = fn
end

local function rebuild_gui_table(frame, counts)
  local t = frame[GUI_TABLE]
  if not (t and t.valid) then return end
  t.clear()
  for item, count in pairs(counts or {}) do
    pcall(function()
      local icon = t.add{type = "sprite-button", style = "transparent_slot",
        sprite = "item/" .. item,
        tooltip = {"", "[item=" .. item .. "]", "  x", tostring(count)}}
      icon.number = count
      icon.style.width = 40
      icon.style.height = 40
      icon.style.padding = 4
    end)
  end
end

local function find_reader(unit)
  for _, surface in pairs(game.surfaces) do
    for _, e in ipairs(surface.find_entities_filtered{name = READER}) do
      if e.unit_number == unit then return e end
    end
    for _, e in ipairs(surface.find_entities_filtered{type = "entity-ghost"}) do
      if e.unit_number == unit and e.ghost_name == READER then return e end
    end
  end
  return nil
end

-- 从归属地元信息取一个读取器的最终信号表
-- 归属地用缓存（READER_REGION，归属阶段已解析），避免每帧每读取器 network_id_at
-- 全表面扫描；最终输出按 (归属地,filter,qty) 缓存共享给同网络同配置的读取器。
local function reader_counts(reader)
  local unit = reader.unit_number
  local rtype, id = reader_region_cached(unit, reader)
  if not rtype then return {} end
  local region_key = regions.region_key
  local filter = get_filter(unit)
  local qty = get_qty(unit)
  local ckey = region_key(rtype, id) .. "|" .. filter .. "|" .. qty
  local cached = out_cache[ckey]
  if cached then return cached end
  local r = storage[REGIONS] and storage[REGIONS][region_key(rtype, id)] or nil
  -- 按读取器的 filter 合并对应类别的计数
  local dual = merge_counts_for_filter(r, filter)
  local counts = combine(dual, qty)
  out_cache[ckey] = counts
  return counts
end

-- 刷新所有打开面板的状态与计数（帧末输出时调用）
local function refresh_all_open_gui()
  for _, player in pairs(game.players) do
    if player and player.valid then
      local frame = player.gui.screen[GUI_FRAME]
      if frame and frame.valid then
        local unit = frame.tags and frame.tags.unit
        local reader = (type(unit) == "number") and find_reader(unit) or nil
        if reader and reader.valid then
          local counts = reader_counts(reader)
          local content = frame.gr_gui_content
          local status = content and content.gr_gui_status_flow and content.gr_gui_status_flow[GUI_STATUS]
          if status and status.valid then status.caption = status_localised(reader) end
          rebuild_gui_table(content or frame, counts)
        end
      end
    end
  end
end

-- 渲染单个读取器：从归属地元信息取计数，写电路 + tooltip（GUI 由帧末统一刷新）
local function render_reader(reader)
  if not (reader and reader.valid and reader.name == READER) then return end
  local counts = reader_counts(reader)
  output.write_outputs(reader, counts)
  output.update_reader_tooltip(reader)
end

-- 构建 GUI 面板（精简版：模式/筛选/数量三个下拉 + 状态 + 信号表）
local function build_gui(player, reader)
  local old = player.gui.screen[GUI_FRAME]
  if old and old.valid then old.destroy() end
  player.opened = nil
  local frame = player.gui.screen.add{
    type = "frame", name = GUI_FRAME, direction = "vertical",
    tags = { unit = reader.unit_number }
  }
  frame.auto_center = true
  frame.style.minimal_width = 260
  -- 标准标题栏：标题 + 可拖拽空白区 + 关闭按钮。标题与空白区都带 drag_target，
  -- 使整个标题栏可拖动窗口。
  local titlebar = frame.add{ type = "flow" }
  local title = titlebar.add{ type = "label", style = "frame_title", caption = {"gr-gui.title"} }
  title.drag_target = frame
  local drag_space = titlebar.add{ type = "empty-widget", style = "draggable_space_header" }
  drag_space.drag_target = frame
  drag_space.style.horizontally_stretchable = true
  drag_space.style.height = 24
  titlebar.add{ type = "sprite-button", name = "gr_gui_close", style = "frame_action_button",
    sprite = "utility/close", tooltip = {"gr-gui.close"} }
  local content = frame.add{ type = "frame", name = "gr_gui_content",
    style = "inside_shallow_frame_with_padding", direction = "vertical" }
  local mode = get_mode(reader.unit_number)
  local filter = get_filter(reader.unit_number)
  local qty = get_qty(reader.unit_number)
  local rf = content.add{ type = "flow", direction = "horizontal" }
  rf.add{ type = "label", caption = {"gr-gui.range-mode"} }
  rf.add{ type = "empty-widget" }.style.horizontally_stretchable = true
  local rd = rf.add{ type = "drop-down", name = GUI_MODE,
    items = {{"gr-gui.mode-surface"}, {"gr-gui.mode-network"}},
    selected_index = (mode == MODE_SURFACE) and 1 or 2 }
  rd.style.width = 170
  local sf = content.add{ type = "flow", name = "gr_gui_status_flow", direction = "horizontal" }
  sf.add{ type = "label", caption = {"gr-gui.current-range"} }
  sf.add{ type = "empty-widget" }.style.horizontally_stretchable = true
  sf.add{ type = "label", name = GUI_STATUS, caption = status_localised(reader) }
  local ff = content.add{ type = "flow", direction = "horizontal" }
  ff.add{ type = "label", caption = {"gr-gui.filter"} }
  ff.add{ type = "empty-widget" }.style.horizontally_stretchable = true
  local fd = ff.add{ type = "drop-down", name = GUI_FILTER,
    items = {{"gr-gui.filter-all"}, {"gr-gui.filter-entity"}, {"gr-gui.filter-tiles"}, {"gr-gui.filter-upgrades"}, {"gr-gui.filter-items"}},
    selected_index = (filter == FILTER_ALL) and 1 or (filter == FILTER_ENTITY) and 2
      or (filter == FILTER_TILES) and 3 or (filter == FILTER_UPGRADES) and 4 or 5 }
  fd.style.width = 170
  local qf = content.add{ type = "flow", direction = "horizontal" }
  qf.add{ type = "label", caption = {"gr-gui.qty"} }
  qf.add{ type = "empty-widget" }.style.horizontally_stretchable = true
  local qd = qf.add{ type = "drop-down", name = GUI_QTY,
    items = {{"gr-gui.qty-net"}, {"gr-gui.qty-supply"}, {"gr-gui.qty-recycle"}},
    selected_index = (qty == QTY_NET) and 1 or (qty == QTY_SUPPLY) and 2 or 3 }
  qd.style.width = 170
  content.add{ type = "label", caption = {"gr-gui.output"}, style = "frame_subheading_label" }
  content.add{ type = "table", name = GUI_TABLE, column_count = 6 }
  rebuild_gui_table(content, reader_counts(reader))
  player.opened = frame
end

local function on_gui_opened(event)
  if event.gui_type ~= defines.gui_type.entity then return end
  local entity = event.entity
  if not (entity and entity.valid) then return end
  local is_reader = (entity.name == READER)
      or (entity.type == "entity-ghost" and entity.ghost_name == READER)
  if not is_reader then return end
  local player = game.get_player(event.player_index)
  if player then build_gui(player, entity) end
end

local function on_gui_closed(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  local frame = player.gui.screen[GUI_FRAME]
  if frame and frame.valid then frame.destroy() end
end

local function on_gui_click(event)
  local e = event.element
  if not (e and e.valid) then return end
  if e.name == "gr_gui_close" then
    local player = game.get_player(event.player_index)
    if player then
      local frame = player.gui.screen[GUI_FRAME]
      if frame and frame.valid then frame.destroy() end
      if player.opened and player.opened == frame then player.opened = nil end
    end
  end
end

local function on_gui_selection_state_changed(event)
  local e = event.element
  if not (e and e.valid) then return end
  -- 读取器 unit 存于 GUI_FRAME 的 tags 上；下拉框在 frame>content>flow>dropdown，
  -- 故向上逐层查找含 unit 的 frame（避免硬编码层级深度）。
  local unit = nil
  local node = e
  while node and node.valid do
    local tags = node.tags
    if tags and type(tags.unit) == "number" then
      unit = tags.unit
      break
    end
    node = node.parent
  end
  if not (type(unit) == "number") then return end
  local reader = find_reader(unit)
  if not (reader and reader.valid) then return end
  if e.name == GUI_MODE then
    set_mode(unit, (e.selected_index == 1) and MODE_SURFACE or MODE_NETWORK)
  elseif e.name == GUI_FILTER then
    local filters = {FILTER_ALL, FILTER_ENTITY, FILTER_TILES, FILTER_UPGRADES, FILTER_ITEMS}
    set_filter(unit, filters[e.selected_index] or FILTER_ALL)
  elseif e.name == GUI_QTY then
    local qtys = {QTY_NET, QTY_SUPPLY, QTY_RECYCLE}
    set_qty(unit, qtys[e.selected_index] or QTY_NET)
  end
  if on_config_changed then on_config_changed(unit) end
end

M.find_reader = find_reader
M.reader_counts = reader_counts
M.refresh_all_open_gui = refresh_all_open_gui
M.render_reader = render_reader
M.on_gui_opened = on_gui_opened
M.on_gui_closed = on_gui_closed
M.on_gui_click = on_gui_click
M.on_gui_selection_state_changed = on_gui_selection_state_changed
M.set_config_changed_hook = set_config_changed_hook
M.set_combine_fn = set_combine_fn
M.set_merge_fn = set_merge_fn
M.reset_output_cache = reset_output_cache

return M


