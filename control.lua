-- ghost-reader / control.lua
--
-- Ghost Reader (虚影读取器) — a constant-combinator style entity with a custom
-- GUI panel. It counts ghosts (entity + tile + upgrade) and outputs the per-item
-- counts as vanilla item signals via its control-behavior slots.
--
-- Two operating modes:
--   * Surface mode  : scans ALL ghosts on the whole surface.
--   * Network mode  : scans ghosts inside the reader's logistics-network
--                     construction area — the union (not the bounding box) of
--                     every square construction area of the roboports in the
--                     network the reader belongs to.
--
-- The custom GUI shows a mode selector, a live status (current surface in the
-- form 【新地星】, or current network in the form 【网络#7】), a signal grid with
-- item icons, a refresh button and a close button.
--
-- Unlock: crafting a roboport auto-researches the ghost-reader technology.

local READER = "ghost-reader"
local MAX_SLOTS = 18       -- constant-combinator slots per section

local MODE_SURFACE = "surface"
local MODE_NETWORK = "network"
local DEFAULT_MODE = MODE_NETWORK

local FILTER_ALL       = "all"
local FILTER_BUILDINGS = "buildings"
local FILTER_TILES     = "tiles"
local FILTER_UPGRADES  = "upgrades"
local DEFAULT_FILTER   = FILTER_ALL

local GUI_FRAME  = "ghost_reader_gui"
local GUI_TABLE  = "ghost_reader_table"
local GUI_STATUS = "ghost_reader_status"
local GUI_MODE   = "ghost_reader_mode"
local GUI_FILTER = "ghost_reader_filter"

-- ---------------------------------------------------------------------------
-- Item-name resolution (entity/tile prototype -> placing item)
-- ---------------------------------------------------------------------------
local function item_for_entity(name)
  local p = prototypes.entity[name]
  if p and p.items_to_place_this and #p.items_to_place_this > 0 then
    return p.items_to_place_this[1].name
  end
end

local function item_for_tile(name)
  local p = prototypes.tile[name]
  if p and p.items_to_place_this and #p.items_to_place_this > 0 then
    return p.items_to_place_this[1].name
  end
end

-- ---------------------------------------------------------------------------
-- Reader mode (persisted in storage)
-- ---------------------------------------------------------------------------
local function get_mode(unit)
  storage.readers = storage.readers or {}
  local d = storage.readers[unit]
  return (d and d.mode) or DEFAULT_MODE
end

local function set_mode(unit, mode)
  storage.readers = storage.readers or {}
  storage.readers[unit] = storage.readers[unit] or {}
  storage.readers[unit].mode = mode
end

local function get_filter(unit)
  storage.readers = storage.readers or {}
  local d = storage.readers[unit]
  return (d and d.filter) or DEFAULT_FILTER
end

local function set_filter(unit, filter)
  storage.readers = storage.readers or {}
  storage.readers[unit] = storage.readers[unit] or {}
  storage.readers[unit].filter = filter
end

-- ---------------------------------------------------------------------------
-- The logistics network the reader belongs to (or nil), and its id.
-- ---------------------------------------------------------------------------
local function reader_network(reader)
  local pos = reader.position
  if not pos then return nil end
  for _, port in ipairs(reader.surface.find_entities_filtered{name = "roboport"}) do
    if port.valid then
      local srad = port.prototype and port.prototype.logistic_radius
      local ppos = port.position
      if srad and ppos then
        local dx, dy = math.abs(ppos.x - pos.x), math.abs(ppos.y - pos.y)
        if dx <= srad and dy <= srad then -- square supply area
          local net = port.logistic_network
          if net then return net end
        end
      end
    end
  end
  return nil
end

local function reader_network_id(reader)
  local net = reader_network(reader)
  return net and net.network_id
end

-- ---------------------------------------------------------------------------
-- A ghost is only counted if its CENTER POINT falls inside the construction
-- area (that is what the game uses to decide it can be built). area == nil
-- means the whole surface, so every ghost qualifies.
-- ---------------------------------------------------------------------------
local function center_in_area(pos, area)
  if not area then return true end
  local x1, y1 = area[1][1], area[1][2]
  local x2, y2 = area[2][1], area[2][2]
  return pos and pos.x >= x1 and pos.x <= x2 and pos.y >= y1 and pos.y <= y2
end

-- ---------------------------------------------------------------------------
-- Count ghosts (entity + tile + upgrade) inside an area. `visited` dedups ghosts
-- that fall in several overlapping areas. Only ghosts whose centre is inside the
-- area are counted.
-- ---------------------------------------------------------------------------
local function scan_area(surface, area, counts, visited, filter)
  local include_buildings = (filter == FILTER_ALL or filter == FILTER_BUILDINGS)
  local include_tiles     = (filter == FILTER_ALL or filter == FILTER_TILES)
  local include_upgrades  = (filter == FILTER_ALL or filter == FILTER_UPGRADES)

  if include_buildings then
    local ghosts = surface.find_entities_filtered{area = area, type = "entity-ghost"}
    for _, g in ipairs(ghosts) do
      if g.valid and center_in_area(g.position, area) then
        local u = g.unit_number
        if u then
          if visited[u] then goto skip_ghost end
          visited[u] = true
        end
        local item = item_for_entity(g.ghost_name)
        if item then counts[item] = (counts[item] or 0) + 1 end
        ::skip_ghost::
      end
    end
  end

  if include_tiles then
    local tiles = surface.find_entities_filtered{area = area, type = "tile-ghost"}
    for _, g in ipairs(tiles) do
      if g.valid and center_in_area(g.position, area) then
        local u = g.unit_number
        if u then
          if visited[u] then goto skip_tile end
          visited[u] = true
        end
        local item = item_for_tile(g.ghost_name)
        if item then counts[item] = (counts[item] or 0) + 1 end
        ::skip_tile::
      end
    end
  end

  if include_upgrades then
    local marked = surface.find_entities_filtered{area = area, to_be_upgraded = true}
    for _, en in ipairs(marked) do
      if en.valid and center_in_area(en.position, area) then
        local u = en.unit_number
        if u then
          if visited[u] then goto skip_upg end
          visited[u] = true
        end
        local target = en.get_upgrade_target()
        if target then
          local item = item_for_entity(target.name)
          if item then counts[item] = (counts[item] or 0) + 1 end
        end
        ::skip_upg::
      end
    end
  end

  return counts
end

-- Network mode: scan the union of the network roboports' square construction
-- areas (dedup across the squares, NOT a single bounding box).
local function get_counts_network(reader, filter)
  local net_id = reader_network_id(reader)
  if not net_id then return {} end
  local counts, visited = {}, {}
  for _, port in ipairs(reader.surface.find_entities_filtered{name = "roboport"}) do
    if port.valid then
      local pnet = port.logistic_network
      if pnet and pnet.network_id == net_id then
        local range = port.prototype and port.prototype.construction_radius
        local ppos = port.position
        if range and ppos then
          local area = {{ppos.x - range, ppos.y - range}, {ppos.x + range, ppos.y + range}}
          scan_area(reader.surface, area, counts, visited, filter)
        end
      end
    end
  end
  return counts
end

local function get_counts(reader)
  local filter = get_filter(reader.unit_number)
  if get_mode(reader.unit_number) == MODE_SURFACE then
    return scan_area(reader.surface, nil, {}, {}, filter)
  end
  return get_counts_network(reader, filter)
end

-- ---------------------------------------------------------------------------
-- Write counts into the reader's control-behavior slots (vanilla item signals).
-- ---------------------------------------------------------------------------
local function write_outputs(reader, counts)
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

-- ---------------------------------------------------------------------------
-- Update pass: share scan results between readers on the same surface / network.
-- ---------------------------------------------------------------------------
local function update()
  local cache = {}
  for _, surface in pairs(game.surfaces) do
    for _, reader in ipairs(surface.find_entities_filtered{name = READER}) do
      local mode = get_mode(reader.unit_number)
      local filter = get_filter(reader.unit_number)
      local key
      if mode == MODE_SURFACE then
        key = "S:" .. surface.index .. ":" .. filter
      else
        key = "N:" .. surface.index .. ":" .. tostring(reader_network_id(reader)) .. ":" .. filter
      end
      local counts = cache[key]
      if not counts then
        counts = get_counts(reader)
        cache[key] = counts
      end
      write_outputs(reader, counts)
    end
  end
end

-- Event-driven: mark that a ghost changed so we rescan on the same tick.
local function mark_dirty()
  storage.dirty = true
end

-- Any entity built that affects a reader's output (a ghost, a roboport that
-- changes the network area, or the reader itself placed by copy/blueprint)
-- triggers a rescan on the same tick.
local function on_entity_built(event)
  local e = event.entity
  if not (e and e.valid) then return end
  if e.type == "entity-ghost" or e.type == "tile-ghost" then
    pcall(function() script.register_on_object_destroyed(e) end)
  elseif e.name ~= READER and e.name ~= "roboport" then
    return
  end
  mark_dirty()
end

-- A roboport was mined -> the network construction areas may have changed.
local function on_roboport_removed(event)
  local e = event.entity
  if e and e.valid and e.name == "roboport" then mark_dirty() end
end

local needs_rescan = false -- set by on_load; not stored in storage
local refresh_all_open_gui -- forward declaration, defined below
local find_reader -- forward declaration, defined below

local function on_tick()
  -- Event-driven: rescan only when something actually changed.
  if needs_rescan or storage.dirty then
    needs_rescan = false
    storage.dirty = nil
    update()
    refresh_all_open_gui() -- reflect the just-updated counts immediately
  elseif game.tick % 30 == 0 then
    refresh_all_open_gui() -- periodic real-time refresh of open panels
  end
end

-- ---------------------------------------------------------------------------
-- Status text for the GUI: 【新地星】 / 【网络#7】
-- ---------------------------------------------------------------------------
local function status_localised(reader)
  local mode = get_mode(reader.unit_number)
  if mode == MODE_SURFACE then
    local surface = reader.surface
    local ok, name = pcall(function()
      if surface.planet then return surface.planet.prototype.localised_name end
      return surface.name
    end)
    return {"", {"gr-gui.current-range"}, "【", (ok and name) or surface.name, "】"}
  end
  local net_id = reader_network_id(reader)
  if net_id then
    return {"", {"gr-gui.current-range"}, "【", {"gr-gui.network-prefix"}, tostring(net_id), "】"}
  end
  return {"", {"gr-gui.current-range"}, {"gr-gui.status-no-network"}}
end

-- ---------------------------------------------------------------------------
-- Custom GUI panel
-- ---------------------------------------------------------------------------
local function rebuild_gui_table(frame, reader)
  local t = frame[GUI_TABLE]
  if not (t and t.valid) then return end
  local ok, counts = pcall(function() return get_counts(reader) end)
  if not ok or type(counts) ~= "table" then counts = {} end
  t.clear()
  for item, count in pairs(counts) do
    pcall(function()
      t.add{type = "label", caption = {"", "[item=" .. item .. "]", "  ", tostring(count)},
        tooltip = {"", "[item=" .. item .. "]", "  x", tostring(count)}}
    end)
  end
end

local function build_gui(player, reader)
  local old = player.gui.screen[GUI_FRAME]
  if old and old.valid then old.destroy() end
  player.opened = nil

  local mode = get_mode(reader.unit_number)
  local filter = get_filter(reader.unit_number)
  local frame = player.gui.screen.add{
    type = "frame", name = GUI_FRAME, direction = "vertical",
    tags = {unit = reader.unit_number}
  }

  -- title bar (single): title + close
  local titlebar = frame.add{type = "flow", direction = "horizontal"}
  titlebar.add{type = "label", caption = {"gr-gui.title"}, style = "frame_title"}
  titlebar.add{type = "empty-widget"}
  titlebar.add{type = "sprite-button", name = "gr_gui_close", style = "frame_action_button",
    sprite = "utility/close", hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black", tooltip = {"gr-gui.close"}}

  -- 1. 检索范围模式 (scan range mode)
  local range_flow = frame.add{type = "flow", direction = "horizontal"}
  range_flow.add{type = "label", caption = {"gr-gui.range-mode"}}
  range_flow.add{type = "drop-down", name = GUI_MODE,
    items = {{"gr-gui.mode-surface"}, {"gr-gui.mode-network"}},
    selected_index = (mode == MODE_SURFACE) and 1 or 2}

  -- 2. 当前范围 (current range)
  frame.add{type = "label", name = GUI_STATUS, caption = status_localised(reader)}

  -- 3. 筛选模式 (filter mode)
  local filter_flow = frame.add{type = "flow", direction = "horizontal"}
  filter_flow.add{type = "label", caption = {"gr-gui.filter"}}
  filter_flow.add{type = "drop-down", name = GUI_FILTER,
    items = {{"gr-gui.filter-all"}, {"gr-gui.filter-buildings"}, {"gr-gui.filter-tiles"}, {"gr-gui.filter-upgrades"}},
    selected_index = (filter == FILTER_ALL) and 1
      or (filter == FILTER_BUILDINGS) and 2
      or (filter == FILTER_TILES) and 3
      or 4}

  -- 4. 当前输出信号 (current output signals)
  frame.add{type = "label", caption = {"gr-gui.output"}, style = "frame_subheading_label"}
  frame.add{type = "table", name = GUI_TABLE, column_count = 1}
  rebuild_gui_table(frame, reader)

  frame.force_auto_center()
  player.opened = frame
end

local function refresh_status_and_table(player, reader)
  local frame = player.gui.screen[GUI_FRAME]
  if not (frame and frame.valid) then return end
  pcall(function()
    local status = frame[GUI_STATUS]
    if status and status.valid then status.caption = status_localised(reader) end
    rebuild_gui_table(frame, reader)
  end)
end

-- Real-time refresh: update the status and counts of every open reader panel.
refresh_all_open_gui = function()
  for _, player in pairs(game.players) do
    if player and player.valid then
      local frame = player.gui.screen[GUI_FRAME]
      if frame and frame.valid then
        local unit = frame.tags and frame.tags.unit
        local reader = (type(unit) == "number") and find_reader(unit) or nil
        if reader and reader.valid then refresh_status_and_table(player, reader) end
      end
    end
  end
end

find_reader = function(unit)
  for _, surface in pairs(game.surfaces) do
    local r = surface.find_entities_filtered{name = READER}
    for _, e in ipairs(r) do if e.unit_number == unit then return e end end
  end
  return nil
end

local function on_gui_opened(event)
  if event.gui_type ~= defines.gui_type.entity then return end
  local entity = event.entity
  if not (entity and entity.valid and entity.name == READER) then return end
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
  local player = game.get_player(event.player_index)
  if not player then return end
  if e.name == "gr_gui_close" then
    local frame = player.gui.screen[GUI_FRAME]
    if frame and frame.valid then frame.destroy() end
    player.opened = nil
  end
end

local function on_gui_selection_state_changed(event)
  local e = event.element
  if not (e and e.valid) then return end
  local player = game.get_player(event.player_index)
  if not player then return end
  local frame = player.gui.screen[GUI_FRAME]
  local unit = frame and frame.tags and frame.tags.unit
  local reader = (type(unit) == "number") and find_reader(unit) or nil
  if not (reader and reader.valid) then return end

  if e.name == GUI_MODE then
    set_mode(unit, (e.selected_index == 1) and MODE_SURFACE or MODE_NETWORK)
  elseif e.name == GUI_FILTER then
    local filters = {FILTER_ALL, FILTER_BUILDINGS, FILTER_TILES, FILTER_UPGRADES}
    set_filter(unit, filters[e.selected_index] or FILTER_ALL)
  else
    return
  end
  update() -- immediately refresh the circuit output for the new selection
  refresh_status_and_table(player, reader)
end

-- ---------------------------------------------------------------------------
-- Event wiring
-- ---------------------------------------------------------------------------
script.on_event(defines.events.on_tick, on_tick)
script.on_event(defines.events.on_gui_opened, on_gui_opened)
script.on_event(defines.events.on_gui_closed, on_gui_closed)
script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)

-- Ghost / roboport / reader placement -> rescan on the same tick.
script.on_event(defines.events.on_built_entity, on_entity_built)
script.on_event(defines.events.on_robot_built_entity, on_entity_built)
script.on_event(defines.events.script_raised_built, on_entity_built)
script.on_event(defines.events.script_raised_revive, on_entity_built)
script.on_event(defines.events.on_object_destroyed, mark_dirty)
script.on_event(defines.events.on_marked_for_upgrade, mark_dirty)
script.on_event(defines.events.on_cancelled_upgrade, mark_dirty)
script.on_event(defines.events.on_pre_ghost_upgraded, mark_dirty)

-- A roboport was mined/removed -> network construction areas may have changed.
local roboport_filter = {{filter = "name", name = "roboport"}}
script.on_event(defines.events.on_player_mined_entity, on_roboport_removed, roboport_filter)
script.on_event(defines.events.on_robot_mined_entity, on_roboport_removed, roboport_filter)
script.on_event(defines.events.on_entity_died, on_roboport_removed, roboport_filter)
script.on_event(defines.events.script_raised_destroy, on_roboport_removed, roboport_filter)

-- Register existing ghosts on load so their removal also triggers a rescan.
script.on_configuration_changed(function()
  storage.dirty = true
  for _, surface in pairs(game.surfaces) do
    for _, g in ipairs(surface.find_entities_filtered{type = {"entity-ghost", "tile-ghost"}}) do
      if g.valid then pcall(function() script.register_on_object_destroyed(g) end) end
    end
  end
end)

script.on_load(function()
  needs_rescan = true -- do NOT touch storage here (not save/load stable)
end)
