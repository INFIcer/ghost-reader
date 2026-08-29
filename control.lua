-- ghost-reader / control.lua
--
-- Ghost Reader (虚影读取器) — a constant-combinator style entity with a custom
-- GUI panel. It counts ghosts (entity + tile + upgrade) plus item requests
-- (item-request-proxy) and outputs the per-item counts as vanilla item
-- signals via its control-behavior slots.
--
-- Two scan-range modes:
--   * Surface mode  : scans ALL ghosts on the whole surface.
--   * Network mode  : scans ghosts inside the reader's logistics-network
--                     construction area — the union (not the bounding box) of
--                     every square construction area of the roboports in the
--                     network the reader belongs to. IRPs (item requests) are
--                     served by construction robots, so they use the same
--                     construction area.
--
-- The custom GUI shows a scan-range mode selector, a filter (all / entities /
-- tiles / upgrades / items), a live status (current surface
-- 【新地星】 or current network 【网络#7】), and the per-item signal counts. It
-- refreshes in real time and has a close button.
--
-- Unlock: the technology uses a native `research_trigger` in data.lua — crafting
-- one roboport unlocks the Ghost Reader (no control.lua code needed for that).

local READER = "ghost-reader"
local MAX_SLOTS = 18       -- constant-combinator slots per section

local MODE_SURFACE = "surface"
local MODE_NETWORK = "network"
local DEFAULT_MODE = MODE_NETWORK

local FILTER_ALL     = "all"
local FILTER_ENTITY  = "entity"
local FILTER_TILES   = "tiles"
local FILTER_UPGRADES = "upgrades"
local FILTER_ITEMS   = "items"
local DEFAULT_FILTER = FILTER_ALL

-- Quantity mode: how supply and recycle counts are combined.
local QTY_NET     = "net"      -- 供给 - 回收 (net shortage, may be negative)
local QTY_SUPPLY  = "supply"   -- 只输出供给
local QTY_RECYCLE = "recycle"  -- 只输出回收
local DEFAULT_QTY = QTY_NET

local GUI_FRAME  = "ghost_reader_gui"
local GUI_TABLE  = "ghost_reader_table"
local GUI_STATUS = "ghost_reader_status"
local GUI_MODE   = "ghost_reader_mode"
local GUI_FILTER = "ghost_reader_filter"
local GUI_QTY    = "ghost_reader_qty"

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

-- Expected mineable yields for environment entities (trees, fish, rocks, ...).
-- These have no `items_to_place_this`, but their mineable_properties.products
-- tell us what deconstructing them yields (e.g. tree -> wood, fish -> raw-fish).
-- We consider ALL products and return, per item, the EXPECTED quantity
-- (amount * probability), rounded to the nearest integer.
local function mineable_products(name)
  local p = prototypes.entity[name]
  if not p then return nil end
  local ok, mp = pcall(function() return p.mineable_properties end)
  if not (ok and mp and mp.products) then return nil end
  local out = {}
  for _, pr in ipairs(mp.products) do
    if pr and pr.name then
      local prob = pr.probability
      if prob == nil then prob = 1 end -- nil means guaranteed (100%)
      if prob ~= 0 then
        local amount = pr.amount
        if not amount and pr.amount_min and pr.amount_max then
          amount = (pr.amount_min + pr.amount_max) / 2
        end
        amount = amount or 1
        local expected = amount * prob
        -- Round half up to the nearest integer.
        local qty = math.floor(expected + 0.5)
        if qty < 1 then qty = 1 end -- always expect at least one of a possible product
        out[pr.name] = (out[pr.name] or 0) + qty
      end
    end
  end
  return out
end

-- Collect the items an entity carries that are NOT stored in a regular
-- inventory slot: items travelling on a transport belt's lines, and the item
-- held in an inserter's hand. Returns a table { [item_name] = count }.
local function extra_carry_items(en)
  local et = en.type
  local out = {}
  -- Transport belts store cargo in transport lines, not inventories. The number
  -- of lines varies by type: a normal belt has 2, an underground belt 4, and a
  -- splitter 8 (its 4 internal cache slots are extra lines 5-8). Iterate until
  -- get_transport_line returns nil, with a safe upper bound.
  if et == "transport-belt" or et == "underground-belt" or et == "splitter" then
    for line_index = 1, 12 do
      local ok, tl = pcall(function() return en.get_transport_line(line_index) end)
      if not (ok and tl) then break end
      local okc, contents = pcall(function() return tl.get_contents() end)
      if okc and contents then
        for _, st in pairs(contents) do
          if st and st.name then
            out[st.name] = (out[st.name] or 0) + (st.count or 1)
          end
        end
      end
    end
  elseif et == "inserter" then
    local okh, hs = pcall(function() return en.held_stack end)
    if okh and hs then
      local okn, name = pcall(function() return hs.name end)
      local okc, count = pcall(function() return hs.count end)
      if okn and name then
        out[name] = (out[name] or 0) + ((okc and count) or 1)
      end
    end
  end
  return out
end

-- Recycle a deconstruction-marked entity into the `recycle` table. Handles:
--   * item-entity (on-ground item): yields its stack item, count = stack.count
--   * environment entities (tree/fish/rock): their mineable products classified
--     as "items" (expected quantity per product, rounded)
--   * transport belts: items currently travelling on the belt (as "items")
--   * inserters: the item currently held in hand (as "items")
--   * normal buildings: yield the building item (as "entity") + stored contents /
--     modules (as "items")
local function recycle_entity_contents(en, include_entities, include_items, recycle)
  local et = en.type
  -- On-ground item: recycle its item stack as "items".
  if et == "item-entity" then
    if include_items and en.stack then
      local n = en.stack.name
      local c = en.stack.count or 1
      if n then recycle[n] = (recycle[n] or 0) + c end
    end
    return
  end
  -- Environment entities with no placeable item: their mineable products are
  -- classified as "items" (expected quantity per product, rounded).
  if include_items and not item_for_entity(en.name) then
    local prods = mineable_products(en.name)
    if prods then
      for prod, n in pairs(prods) do
        recycle[prod] = (recycle[prod] or 0) + n
      end
      return
    end
  end
  -- Normal building: recycle the building itself as "entity".
  if include_entities then
    local item = item_for_entity(en.name)
    if item then recycle[item] = (recycle[item] or 0) + 1 end
  end
  -- Stored items/modules as "items" (skip the module inventory duplicates).
  if include_items then
    local minv = en.get_module_inventory()
    for inv_index = 1, 40 do
      local tinv = en.get_inventory(inv_index)
      if not tinv then goto skip_recycle_inv end
      if minv and tinv == minv then goto skip_recycle_inv end
      for _, st in pairs(tinv.get_contents()) do
        if st and st.name then
          recycle[st.name] = (recycle[st.name] or 0) + (st.count or 1)
        end
      end
      ::skip_recycle_inv::
    end
    if minv then
      for _, st in pairs(minv.get_contents()) do
        if st and st.name then
          recycle[st.name] = (recycle[st.name] or 0) + (st.count or 1)
        end
      end
    end
    -- Items travelling on a deconstruction-marked transport belt, and the item
    -- held in a deconstruction-marked inserter's hand (as "items"). Neither is
    -- stored in a regular inventory, so they are read via extra_carry_items.
    for name, n in pairs(extra_carry_items(en)) do
      recycle[name] = (recycle[name] or 0) + n
    end
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

local function get_qty(unit)
  storage.readers = storage.readers or {}
  local d = storage.readers[unit]
  return (d and d.qty) or DEFAULT_QTY
end

local function set_qty(unit, qty)
  storage.readers = storage.readers or {}
  storage.readers[unit] = storage.readers[unit] or {}
  storage.readers[unit].qty = qty
end

-- ---------------------------------------------------------------------------
-- Ghost config inheritance: config changed on a READER GHOST must carry over to
-- the real reader once it is built. A ghost and the built entity sit at the same
-- position but have different unit_numbers, so we key by position.
-- ---------------------------------------------------------------------------
local function pos_key(surface_index, pos)
  if not (pos and pos.x and pos.y) then return nil end
  return surface_index .. ":" .. math.floor(pos.x) .. "," .. math.floor(pos.y)
end

-- Persist the config of the entity (real or ghost) at its position, so that when
-- the ghost is later built, the real reader inherits it.
local function save_config_at_pos(entity)
  if not (entity and entity.valid and entity.position) then return end
  local unit = entity.unit_number
  if not unit then return end
  local key = pos_key(entity.surface.index, entity.position)
  storage.ghost_cfg = storage.ghost_cfg or {}
  storage.ghost_cfg[key] = {
    mode = get_mode(unit),
    filter = get_filter(unit),
    qty = get_qty(unit)
  }
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
-- Count supply AND recycling requests inside an area.
--
-- `supply`   = items the network must RECEIVE (build ghosts, upgrade targets).
-- `recycle`  = items the network will REMOVE / recover (deconstruction of
--              buildings and tiles, and the original entity of an upgrade).
-- `visited`  dedups entities that fall in several overlapping areas. Only
-- entities whose centre is inside the area are counted. Each direction writes
-- into its own table so the quantity mode can combine them later.
-- ---------------------------------------------------------------------------
local function scan_area(surface, area, supply, recycle, visited, filter)
  local include_entities  = (filter == FILTER_ALL or filter == FILTER_ENTITY)
  local include_tiles     = (filter == FILTER_ALL or filter == FILTER_TILES)
  local include_upgrades  = (filter == FILTER_ALL or filter == FILTER_UPGRADES)
  local include_items     = (filter == FILTER_ALL or filter == FILTER_ITEMS)

  -- --- Supply: entity ghosts (build requests) ---
  if include_entities then
    local ghosts = surface.find_entities_filtered{area = area, type = "entity-ghost"}
    for _, g in ipairs(ghosts) do
      if g.valid and center_in_area(g.position, area) then
        local u = g.unit_number
        if u then
          if visited[u] then goto skip_ghost end
          visited[u] = true
        end
        local item = item_for_entity(g.ghost_name)
        if item then supply[item] = (supply[item] or 0) + 1 end
        ::skip_ghost::
      end
    end
  end

  -- --- Supply: tile ghosts ---
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
        if item then supply[item] = (supply[item] or 0) + 1 end
        ::skip_tile::
      end
    end
  end

  -- --- Supply (upgrade target) + Recycle (original entity) ---
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
          local new_item = item_for_entity(target.name)
          if new_item then supply[new_item] = (supply[new_item] or 0) + 1 end
        end
        local old_item = item_for_entity(en.name)
        if old_item then recycle[old_item] = (recycle[old_item] or 0) + 1 end
        ::skip_upg::
      end
    end
  end

  -- --- Recycle: entities marked for deconstruction (red deconstruction planner).
  -- The entity itself is recycled as an "entity" (buildings); any items/modules
  -- stored inside it are recycled as "items" (the former "temporary item
  -- requests"). `to_be_deconstructed` also matches deconstructible-tile-proxy;
  -- those are handled separately below (tiles).
  if include_entities or include_items then
    local deco = surface.find_entities_filtered{area = area, to_be_deconstructed = true}
    for _, en in ipairs(deco) do
      if en.type ~= "deconstructible-tile-proxy" and en.valid and center_in_area(en.position, area) then
        local u = en.unit_number
        if u then
          if visited[u] then goto skip_deco end
          visited[u] = true
        end
        -- Recycle this deconstruction-marked entity (entity itself as "entity",
        -- stored contents/modules as "items"; also covers on-ground items and
        -- environment entities like trees/fish/rocks).
        recycle_entity_contents(en, include_entities, include_items, recycle)
        ::skip_deco::
      end
    end
  end

  -- --- Recycle: tiles marked for deconstruction (deconstructible-tile-proxy) ---
  if include_tiles then
    local tproxies = surface.find_entities_filtered{area = area, name = "deconstructible-tile-proxy"}
    for _, p in ipairs(tproxies) do
      if p.valid and center_in_area(p.position, area) then
        -- Tile-proxies have no unit_number (unit_number is nil), so dedup by the
        -- proxy's position (which is the tile centre) to avoid double-counting a
        -- tile that falls in several overlapping roboport construction areas.
        local pos = p.position
        local key = pos and (pos.x .. "," .. pos.y) or nil
        if key then
          if visited[key] then goto skip_tproxy end
          visited[key] = true
        end
        if pos then
          local tile = surface.get_tile(math.floor(pos.x), math.floor(pos.y))
          local item = tile and item_for_tile(tile.name)
          if item then recycle[item] = (recycle[item] or 0) + 1 end
        end
        ::skip_tproxy::
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Count item-request-proxies (temporary item requests). `supply` gets the
-- requested items (item_requests); `recycle` gets items the proxy wants removed
-- (removal_plan, e.g. a storage slot set for recycling in remote view). The
-- removal quantity is the CURRENT amount of that item in the target entity's
-- inventories (removal_plan only names items/positions, not counts).
-- ---------------------------------------------------------------------------
local function scan_irp(surface, area, supply, recycle, visited)
  local irps = surface.find_entities_filtered{area = area, type = "item-request-proxy"}
  for _, g in ipairs(irps) do
    if g.valid and center_in_area(g.position, area) then
      local u = g.unit_number
      if u then
        if visited[u] then goto skip_irp end
        visited[u] = true
      end
      -- If the IRP's target is itself marked for deconstruction, its request is
      -- superseded by the building's recycling (which already counts the stored
      -- contents). Skip both supply and recycle for it.
      local tgt = g.proxy_target
      if tgt and tgt.valid and tgt.to_be_deconstructed and tgt.to_be_deconstructed() then
        goto skip_irp
      end
      -- Supply: requested items
      local reqs = g.item_requests
      if reqs then
        for _, r in ipairs(reqs) do
          local item = r and r.name
          if item then supply[item] = (supply[item] or 0) + (r.count or 1) end
        end
      end
      -- Recycle: removal plan. Each plan names an item (id.name); the quantity
      -- is the current stock of that item in the target entity's inventories
      -- (container inventories AND module slots — e.g. modules being recycled).
      local removal = g.removal_plan
      if removal and next(removal) then
        local target = g.proxy_target
        -- Precompute target item totals across container inventories AND modules.
        -- Skip the module inventory in the get_inventory loop (beacon-like entities
        -- expose their modules via both), then add it once separately. Inventory
        -- indices are not contiguous, so skip nil entries rather than break.
        local stock = {}
        if target and target.valid then
          local minv = target.get_module_inventory()
          for inv_index = 1, 40 do
            local tinv = target.get_inventory(inv_index)
            if not tinv then goto skip_irp_inv end
            if minv and tinv == minv then goto skip_irp_inv end
            for _, st in pairs(tinv.get_contents()) do
              if st and st.name then
                stock[st.name] = (stock[st.name] or 0) + (st.count or 1)
              end
            end
            ::skip_irp_inv::
          end
          if minv then
            for _, st in pairs(minv.get_contents()) do
              if st and st.name then
                stock[st.name] = (stock[st.name] or 0) + (st.count or 1)
              end
            end
          end
        end
        for _, plan in ipairs(removal) do
          local id = plan and plan.id
          local item = id and id.name or (plan and plan.name)
          if item then
            local n = stock[item] or 1
            recycle[item] = (recycle[item] or 0) + n
          end
        end
      end
      ::skip_irp::
    end
  end
end

-- Network mode: scan the union of the network roboports' square construction
-- areas (dedup across the squares, NOT a single bounding box). IRPs are served
-- by construction robots, so they are also counted against the construction area.
-- Returns {supply=..., recycle=...} two tables.
local function get_counts_network(reader, filter)
  local net_id = reader_network_id(reader)
  if not net_id then return {supply = {}, recycle = {}} end
  local supply, recycle, visited = {}, {}, {}
  for _, port in ipairs(reader.surface.find_entities_filtered{name = "roboport"}) do
    if port.valid then
      local pnet = port.logistic_network
      if pnet and pnet.network_id == net_id then
        local ppos = port.position
        local crad = ppos and port.prototype and port.prototype.construction_radius
        if crad then
          local c_area = {{ppos.x - crad, ppos.y - crad}, {ppos.x + crad, ppos.y + crad}}
          scan_area(reader.surface, c_area, supply, recycle, visited, filter)
          if filter == FILTER_ALL or filter == FILTER_ITEMS then
            scan_irp(reader.surface, c_area, supply, recycle, visited)
          end
        end
      end
    end
  end
  return {supply = supply, recycle = recycle}
end

-- Returns {supply=..., recycle=...} for the reader's current range.
local function get_dual_counts(reader)
  local filter = get_filter(reader.unit_number)
  if get_mode(reader.unit_number) == MODE_SURFACE then
    local supply, recycle, visited = {}, {}, {}
    scan_area(reader.surface, nil, supply, recycle, visited, filter)
    if filter == FILTER_ALL or filter == FILTER_ITEMS then
      scan_irp(reader.surface, nil, supply, recycle, visited)
    end
    return {supply = supply, recycle = recycle}
  end
  return get_counts_network(reader, filter)
end

-- Combine supply/recycle into a single item->value table according to qty mode.
-- qty modes:
--   NET     -> supply - recycle   (net shortage, may be negative)
--   SUPPLY  -> supply only
--   RECYCLE -> recycle only
local function combine_counts(dual, qty)
  local out = {}
  if qty == QTY_SUPPLY then
    for item, n in pairs(dual.supply) do out[item] = n end
  elseif qty == QTY_RECYCLE then
    for item, n in pairs(dual.recycle) do out[item] = n end
  else -- QTY_NET
    for item, n in pairs(dual.supply) do out[item] = (out[item] or 0) + n end
    for item, n in pairs(dual.recycle) do out[item] = (out[item] or 0) - n end
    for item, n in pairs(out) do if n == 0 then out[item] = nil end end
  end
  return out
end

local function get_counts(reader)
  local qty = get_qty(reader.unit_number)
  return combine_counts(get_dual_counts(reader), qty)
end

-- ---------------------------------------------------------------------------
-- Config persistence via blueprint tags (bplib).
--
-- The reader's mode/filter/qty live in mod storage (storage.readers[unit]).
-- To make them survive copy / blueprint WITHOUT polluting the circuit output,
-- we use bplib: when a reader is extracted into a user blueprint, bplib raises
-- "bplib-extract" and we write the config into the blueprint's per-entity tags.
-- When that blueprint is later placed (on_pre_build -> "bplib-positions" /
-- "bplib-overlaps"), we read the tags back and apply them to the built reader.
--
-- Crucially we only act on entities named READER ("ghost-reader"), so a vanilla
-- constant-combinator is never tagged/mistaken for a reader (no cross-copy).
--
-- Tag keys are prefixed with "gr" to avoid colliding with other mods' tags.
-- ---------------------------------------------------------------------------
local TAG_MODE   = "gr_mode"
local TAG_FILTER = "gr_filter"
local TAG_QTY    = "gr_qty"

-- Read a reader's config straight from storage. Never touches the circuit.
local function reader_config(unit)
  local d = storage.readers and storage.readers[unit]
  return {
    mode = (d and d.mode) or DEFAULT_MODE,
    filter = (d and d.filter) or DEFAULT_FILTER,
    qty = (d and d.qty) or DEFAULT_QTY,
  }
end

local function apply_config(unit, cfg)
  if not (type(unit) == "number") then return end
  storage.readers = storage.readers or {}
  storage.readers[unit] = storage.readers[unit] or {}
  if cfg.mode then storage.readers[unit].mode = cfg.mode end
  if cfg.filter then storage.readers[unit].filter = cfg.filter end
  if cfg.qty then storage.readers[unit].qty = cfg.qty end
end

-- Write a reader's config into a blueprint entity's tags.
local function write_reader_tags(blueprint, index, reader)
  local cfg = reader_config(reader.unit_number)
  pcall(function()
    blueprint.set_blueprint_entity_tags(index, {
      [TAG_MODE] = cfg.mode,
      [TAG_FILTER] = cfg.filter,
      [TAG_QTY] = cfg.qty,
    })
  end)
end

-- Read config from a blueprint entity's tags (nil if absent).
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

-- Forward declaration: request_update is defined later in the file. The bplib
-- handlers below call it, and in Lua a `local function` is only in scope from its
-- declaration onward, so without this forward declaration those calls would see
-- a nil `request_update` at runtime.
local request_update

-- bplib-extract: a reader (real or ghost) was copied into a user blueprint ->
-- save its config into the blueprint's per-entity tags. Only READER entities are
-- handled; a vanilla constant-combinator is never tagged.
local function is_reader_entity(en)
  return en and en.valid
    and (en.name == READER or (en.type == "entity-ghost" and en.ghost_name == READER))
end

local function on_bplib_extract(event)
  if not (event and event.blueprint and event.entities) then return end
  for index, entity in pairs(event.entities) do
    if is_reader_entity(entity) then
      write_reader_tags(event.blueprint, index, entity)
    end
  end
end

-- bplib-positions: a blueprint containing readers is about to be placed. The
-- event gives each blueprint entity's future world position. Record any config
-- carried in the tags, keyed by world position, so the built reader can inherit
-- it (bplib-overlaps handles pre-existing readers separately).
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

-- bplib-overlaps: placing a blueprint whose reader overlaps an existing reader
-- (real or ghost) in the world -> copy the blueprint's config onto it.
local function on_bplib_overlaps(event)
  if not (event and event.blueprint and event.overlaps) then return end
  local entities = event.blueprint.get_blueprint_entities()
  for index, overlapped in pairs(event.overlaps) do
    if overlapped and overlapped.valid then
      local is_reader = overlapped.name == READER
        or (overlapped.type == "entity-ghost" and overlapped.ghost_name == READER)
      if is_reader then
        local e = entities and entities[index]
        if e and e.name == READER then
          local cfg = read_reader_tags(event.blueprint, index)
          if cfg and overlapped.unit_number then
            apply_config(overlapped.unit_number, cfg)
            save_config_at_pos(overlapped)
            request_update()
          end
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- Write counts into the reader's control-behavior slots (vanilla item signals).
-- To avoid redundant circuit writes on periodic rescans, only rewrite the slots
-- when the signal set actually changed since the last write.
-- ---------------------------------------------------------------------------
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
    if storage.out_fp[unit] == fp then return end -- unchanged
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

-- ---------------------------------------------------------------------------
-- Update pass: share scan results between readers on the same surface / network.
-- ---------------------------------------------------------------------------
local update_reader_tooltip -- forward declaration, defined below

local function update()
  local cache = {}
  for _, surface in pairs(game.surfaces) do
    for _, reader in ipairs(surface.find_entities_filtered{name = READER}) do
      local mode = get_mode(reader.unit_number)
      local filter = get_filter(reader.unit_number)
      local qty = get_qty(reader.unit_number)
      local key
      if mode == MODE_SURFACE then
        key = "S:" .. surface.index .. ":" .. filter .. ":" .. qty
      else
        key = "N:" .. surface.index .. ":" .. tostring(reader_network_id(reader)) .. ":" .. filter .. ":" .. qty
      end
      local counts = cache[key]
      if not counts then
        counts = get_counts(reader)
        cache[key] = counts
      end
      write_outputs(reader, counts)
      -- Keep the hover tooltip in sync with the current settings.
      update_reader_tooltip(reader)
    end
  end
end

-- Event-driven: mark that a ghost changed so we rescan on the same tick.
local function mark_dirty()
  storage.dirty = true
end

-- Immediately rescan the circuit output, without waiting for on_tick. on_tick
-- only runs while the game is actively simulating, so after a discrete event
-- (e.g. a robot finishing a deconstruction) the dirty flag may never be consumed.
-- Calling update() right here guarantees the circuit output reflects the change.
-- We do NOT call refresh_all_open_gui() here: events can fire before the GUI
-- handlers are defined during startup, and GUI panels are already refreshed on a
-- fixed interval by on_tick. A dirty flag is still set as a fallback.
request_update = function()
  update()
  mark_dirty()
end

-- A building/tile was marked for deconstruction. Register it for object-destroyed
-- so that when a robot actually removes it, on_object_destroyed fires and the
-- recycling signal is cleared (on_robot_mined_entity is not reliable for this).
-- An item-request-proxy was created (created_effect fired by data-updates.lua).
-- Register it for destruction tracking and rescan on the same tick. Also record
-- its requested-item "fingerprint" so on_tick can detect when construction bots
-- partially supply it (item_requests shrink without the entity being destroyed,
-- which fires no event).
local function irp_fingerprint(irp)
  local reqs = irp and irp.item_requests
  if not reqs then return "" end
  local parts = {}
  for _, r in ipairs(reqs) do
    if r and r.name then
      parts[#parts+1] = tostring(r.name) .. "|" .. tostring(r.quality) .. ":" .. tostring(r.count or 1)
    end
  end
  table.sort(parts)
  return table.concat(parts, ";")
end

-- Fingerprint of everything stored in a target entity's container inventories
-- AND its module slots. When a robot removes items/modules from a container being
-- recycled, this changes even though the IRP's item_requests do not, so polling
-- it lets us detect and refresh the recycling signal.
local function target_stock_fingerprint(target)
  if not target or not target.valid then return "" end
  local parts = {}
  local minv = target.get_module_inventory()
  -- Inventory indices are not contiguous; skip nil entries rather than break.
  for inv_index = 1, 40 do
    local tinv = target.get_inventory(inv_index)
    if not tinv then goto skip_inv end
    if minv and tinv == minv then goto skip_inv end -- module inv counted once below
    for _, st in pairs(tinv.get_contents()) do
      if st and st.name then
        parts[#parts+1] = tostring(st.name) .. ":" .. tostring(st.count or 1)
      end
    end
    ::skip_inv::
  end
  if minv then
    for _, st in pairs(minv.get_contents()) do
      if st and st.name then
        parts[#parts+1] = tostring(st.name) .. ":" .. tostring(st.count or 1)
      end
    end
  end
  -- Belt cargo and inserter held items are not in inventories; include them so
  -- the poll detects when construction robots remove them during deconstruction.
  for name, n in pairs(extra_carry_items(target)) do
    parts[#parts+1] = tostring(name) .. ":" .. tostring(n)
  end
  table.sort(parts)
  return table.concat(parts, ";")
end

-- A building/tile was marked for deconstruction. Register it for object-destroyed
-- and record its stock fingerprint so we can detect when a robot removes items or
-- modules from the container (no reliable event fires for that, so we poll).
local function on_decon_marked(event)
  local e = event.entity
  if e and e.valid then
    pcall(function() script.register_on_object_destroyed(e) end)
    local unit = e.unit_number
    if unit then
      storage.decon_snapshots = storage.decon_snapshots or {}
      storage.decon_snapshots[unit] = {
        surface_index = e.surface.index,
        stock = target_stock_fingerprint(e),
        pos_x = e.position and e.position.x,
        pos_y = e.position and e.position.y,
      }
    end
  end
  request_update()
end

local function on_irp_created(event)
  if event.effect_id ~= "gr-item-request-proxy" then return end
  local e = event.source_entity
  if e and e.valid and e.type == "item-request-proxy" then
    pcall(function() script.register_on_object_destroyed(e) end)
    local unit = e.unit_number
    if unit then
      storage.irp_snapshots = storage.irp_snapshots or {}
      storage.irp_snapshots[unit] = {
        surface_index = e.surface.index,
        fingerprint = irp_fingerprint(e),
        stock = target_stock_fingerprint(e.proxy_target),
        pos_x = e.position and e.position.x,
        pos_y = e.position and e.position.y,
      }
    end
  end
  request_update()
end

-- Rebuild the IRP snapshot table from currently-existing item-request-proxies.
-- Called on load (on_configuration_changed does not fire on a plain load, and
-- created_effect does not refire for already-existing IRPs), so that the poll
-- keeps tracking partially-supplied IRPs across a save/load.
local function sync_irp_snapshots()
  storage.irp_snapshots = storage.irp_snapshots or {}
  for _, surface in pairs(game.surfaces) do
    for _, g in ipairs(surface.find_entities_filtered{type = "item-request-proxy"}) do
      if g.valid and g.unit_number then
        pcall(function() script.register_on_object_destroyed(g) end)
        storage.irp_snapshots[g.unit_number] = {
          surface_index = surface.index,
          fingerprint = irp_fingerprint(g),
          stock = target_stock_fingerprint(g.proxy_target),
          pos_x = g.position and g.position.x,
          pos_y = g.position and g.position.y,
        }
      end
    end
  end
end

-- Rebuild deconstruction-marked snapshots from currently-existing marked entities.
-- Like IRPs, the game does not refire the decon event for already-marked entities
-- on a plain load, so re-sync so the poll keeps tracking their stock/position.
local function sync_decon_snapshots()
  storage.decon_snapshots = storage.decon_snapshots or {}
  for _, surface in pairs(game.surfaces) do
    for _, e in ipairs(surface.find_entities_filtered{to_be_deconstructed = true}) do
      if e.valid and e.unit_number then
        pcall(function() script.register_on_object_destroyed(e) end)
        storage.decon_snapshots[e.unit_number] = {
          surface_index = surface.index,
          stock = target_stock_fingerprint(e),
          pos_x = e.position and e.position.x,
          pos_y = e.position and e.position.y,
        }
      end
    end
  end
end

-- Any entity built/placed that affects a reader's output triggers a rescan on
-- the same tick. This includes ghosts, tile-proxies (tile deconstruction), the
-- reader itself, and roboports. Ghosts are also registered for destruction so
-- their removal triggers a rescan.
local function on_entity_built(event)
  local e = event.entity
  if not (e and e.valid) then return end
  if e.type == "entity-ghost" or e.type == "tile-ghost" then
    pcall(function() script.register_on_object_destroyed(e) end)
    -- Remember a reader ghost's config so it can be inherited when built.
    if e.type == "entity-ghost" and e.ghost_name == READER then
      local unit = e.unit_number
      local key = pos_key(e.surface.index, e.position)
      -- The ghost carries config copied from the blueprint's per-entity tags
      -- (gr_mode/gr_filter/gr_qty). This is the primary source and works for any
      -- placement method (blueprint tool, Ctrl+C/V paste, robot build).
      local cfg = nil
      if e.tags then
        local t = e.tags
        if t[TAG_MODE] or t[TAG_FILTER] or t[TAG_QTY] then
          cfg = {}
          if t[TAG_MODE] then cfg.mode = t[TAG_MODE] end
          if t[TAG_FILTER] then cfg.filter = t[TAG_FILTER] end
          if t[TAG_QTY] then cfg.qty = t[TAG_QTY] end
        end
      end
      -- Fallback: bplib-positions recorded config keyed by world position.
      if not cfg then cfg = storage.pending_tags and storage.pending_tags[key] end
      log("ghost-reader: reader ghost built pos_key="..tostring(key).." cfg="..tostring(cfg and (cfg.mode.."/"..cfg.filter.."/"..cfg.qty)).." unit="..tostring(unit).." tags="..tostring(e.tags and e.tags[TAG_MODE]))
      if cfg and unit then
        apply_config(unit, cfg)
        if storage.pending_tags then storage.pending_tags[key] = nil end
      end
      save_config_at_pos(e)
    end
  elseif e.name == READER then
    -- A real reader was just built. Inherit config from either:
    --   * a reader ghost that sat at this position (storage.ghost_cfg), or
    --   * a blueprint placed directly here (storage.pending_tags, from bplib).
    local unit = e.unit_number
    local key = pos_key(e.surface.index, e.position)
    local cfg = storage.ghost_cfg and storage.ghost_cfg[key]
    if not cfg then cfg = storage.pending_tags and storage.pending_tags[key] end
    log("ghost-reader: reader built pos_key="..tostring(key).." ghost_cfg="..tostring(cfg and (cfg.mode.."/"..cfg.filter.."/"..cfg.qty)).." unit="..tostring(unit))
    if cfg then
      if unit then apply_config(unit, cfg) end
      if storage.ghost_cfg then storage.ghost_cfg[key] = nil end
      if storage.pending_tags then storage.pending_tags[key] = nil end
    end
  end
  request_update()
end

-- ---------------------------------------------------------------------------
-- Block settings copy-paste between the reader and a vanilla constant-combinator.
-- Both share the "constant-combinator" type, so the game would otherwise let a
-- player Shift+copy a reader onto a combinator (clearing the combinator's own
-- signals) or copy a combinator onto a reader. To keep the two fully separate we
-- do two things:
--   * on_pre_entity_settings_pasted (fires BEFORE the native paste): snapshot the
--     destination's full control behavior and try to clear entity_copy_source so
--     the native paste is cancelled.
--   * on_entity_settings_pasted (fires AFTER the native paste): if a cross-type
--     paste still went through, restore the destination's original control
--     behavior from the snapshot.
-- ---------------------------------------------------------------------------
local VANILLA_COMBINATOR = "constant-combinator"

-- Is this a reader<->vanilla-combinator settings paste (either direction)?
-- Handles both real entities and ghosts: a ghost's inner entity is its ghost_name.
local function is_reader_kind(en)
  return en.name == READER or (en.type == "entity-ghost" and en.ghost_name == READER)
end

local function is_vanilla_kind(en)
  return en.name == VANILLA_COMBINATOR or (en.type == "entity-ghost" and en.ghost_name == VANILLA_COMBINATOR)
end

local function is_cross_type_paste(source, destination)
  local src_reader = is_reader_kind(source)
  local dst_reader = is_reader_kind(destination)
  local src_vanilla = is_vanilla_kind(source)
  local dst_vanilla = is_vanilla_kind(destination)
  return (src_reader and dst_vanilla) or (src_vanilla and dst_reader)
end

-- Snapshot a combinator's full control behavior (all sections, all slots) so it
-- can be restored after an unwanted paste. Returns nil if not snapshot-able.
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
          slots[i] = {
            value = slot.value,
            min = slot.min,
            max = slot.max,
          }
        end
      end
      sections[s] = { slots = slots }
    end
  end
  if #sections == 0 then return nil end
  return sections
end

-- Restore a combinator's control behavior from a snapshot produced above.
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
          section.set_slot(i, {
            value = slot.value,
            min = slot.min,
            max = slot.max,
          })
        end)
      end
    end
  end
end

local function on_pre_settings_pasted(event)
  local source = event.source
  local destination = event.destination
  if not (source and source.valid and destination and destination.valid) then return end
  if is_cross_type_paste(source, destination) then
    log("ghost-reader: blocking settings paste reader<->vanilla combinator (src="..tostring(source.name).." dst="..tostring(destination.name)..")")
    -- Snapshot the destination so we can restore it if the native paste still happens.
    local snapshot = snapshot_control_behavior(destination)
    if snapshot and destination.unit_number then
      storage.paste_undo = storage.paste_undo or {}
      storage.paste_undo[destination.unit_number] = snapshot
    end
    -- Best effort: cancel the native paste.
    local player = event.player_index and game.get_player(event.player_index)
    if player then
      player.entity_copy_source = nil
    end
  end
end

-- Copy/paste of entity settings: when a player copies a configured reader and
-- pastes it onto a reader ghost/entity (or copies its settings via shift+click),
-- inherit the source reader's mode/filter/qty. The event carries the copied-from
-- entity as `source` and the pasted-to target as `destination`.
local function on_settings_pasted(event)
  local source = event.source
  local target = event.destination
  if not (source and source.valid and target and target.valid) then return end
  -- If this was a reader<->vanilla-combinator paste, undo it (restore the target).
  if is_cross_type_paste(source, target) then
    log("ghost-reader: undoing reader<->vanilla combinator settings paste")
    if target.unit_number and storage.paste_undo and storage.paste_undo[target.unit_number] then
      restore_control_behavior(target, storage.paste_undo[target.unit_number])
      storage.paste_undo[target.unit_number] = nil
    end
    return
  end
  -- Otherwise: reader->reader (or reader ghost) inherits config.
  if not is_reader_kind(source) or not is_reader_kind(target) then return end
  -- Read the source's config from storage (live readers store it there).
  local cfg = reader_config(source.unit_number)
  local tgt_unit = target.unit_number
  if cfg and tgt_unit then
    apply_config(tgt_unit, cfg)
    -- Keep the ghost config at the target's position in sync for build inheritance.
    save_config_at_pos(target)
    request_update()
  end
end

-- A roboport was mined -> the network construction areas may have changed.
local function on_roboport_removed(event)
  local e = event.entity
  if e and e.valid and e.name == "roboport" then request_update() end
end

-- Any entity was destroyed -> drop stale IRP snapshot (if any) and rescan.
local function on_object_destroyed(event)
  if event and event.type == defines.target_type.entity and event.useful_id then
    local snaps = storage.irp_snapshots
    if snaps then snaps[event.useful_id] = nil end
    local dsnaps = storage.decon_snapshots
    if dsnaps then dsnaps[event.useful_id] = nil end
  end
  request_update()
end

local needs_rescan = false -- set by on_load; not stored in storage
local needs_irp_sync = false -- set by on_load; not stored in storage
local refresh_all_open_gui -- forward declaration, defined below
local find_reader -- forward declaration, defined below

-- Item-request-proxies can be partially supplied by construction bots: their
-- item_requests shrink while the entity stays alive, which fires no event. To
-- keep the circuit output in sync we poll the tracked IRPs' fingerprints a few
-- per tick (like item-request-proxy-events does) and mark dirty when they change.
local IRP_POLL_PER_TICK = 8

local function poll_irp_updates()
  local snaps = storage.irp_snapshots
  if not snaps or not next(snaps) then return end
  local processed = 0
  local prev = storage.irp_prev or nil
  local first = prev
  while processed < IRP_POLL_PER_TICK do
    local unit = next(snaps, prev)
    storage.irp_prev = unit
    if not unit then break end
    local data = snaps[unit]
    if data then
      local surface = data.surface_index and game.get_surface(data.surface_index)
      local irp = nil
      if surface then
        for _, e in ipairs(surface.find_entities_filtered{type = "item-request-proxy"}) do
          if e.unit_number == unit then irp = e; break end
        end
      end
      if irp and irp.valid then
        local fp = irp_fingerprint(irp)
        local stock = target_stock_fingerprint(irp.proxy_target)
        -- A moving request target (e.g. a tank/spidertron) carries its IRP with it;
        -- its position changes as it moves in/out of the scan area even though the
        -- request items are unchanged. Detect that so the reader re-scans.
        local moved = irp.position
          and (irp.position.x ~= data.pos_x or irp.position.y ~= data.pos_y)
        if fp ~= data.fingerprint or stock ~= data.stock or moved then
          data.fingerprint = fp
          data.stock = stock
          data.pos_x = irp.position and irp.position.x
          data.pos_y = irp.position and irp.position.y
          mark_dirty()
        end
      else
        snaps[unit] = nil -- gone; clean up
      end
    end
    processed = processed + 1
    if unit == first then break end
  end
end

-- Poll deconstruction-marked containers' stock. When a robot removes items or
-- modules from one, its stock fingerprint changes even though no event fires.
-- Also track position: a marked-for-deconstruction MOVING entity (e.g. a train
-- wagon being pulled by its locomotive) can enter/leave the scan area, changing
-- how many deconstruction-marked entities are counted as recycling. No event
-- fires for that, so we compare positions each tick.
local function poll_decon_snapshots()
  local snaps = storage.decon_snapshots
  if not snaps or not next(snaps) then return end
  for unit, data in pairs(snaps) do
    local surface = data.surface_index and game.get_surface(data.surface_index)
    local ent = nil
    if surface then
      for _, e in ipairs(surface.find_entities_filtered{to_be_deconstructed = true}) do
        if e.unit_number == unit then ent = e; break end
      end
    end
    if ent and ent.valid then
      local stock = target_stock_fingerprint(ent)
      local moved = ent.position
        and (ent.position.x ~= data.pos_x or ent.position.y ~= data.pos_y)
      if stock ~= data.stock or moved then
        data.stock = stock
        data.pos_x = ent.position and ent.position.x
        data.pos_y = ent.position and ent.position.y
        mark_dirty()
      end
    else
      snaps[unit] = nil -- cancelled or gone (e.g. decon mark cleared when a train moved)
    end
  end
end

local function on_tick()
  -- Rebuild IRP + decon snapshots on the first tick after load (game is
  -- unavailable in on_load; created_effect / on_configuration_changed don't fire
  -- for already-existing IRPs or already-marked-for-deconstruction entities).
  if needs_irp_sync then
    needs_irp_sync = false
    pcall(sync_irp_snapshots)
    pcall(sync_decon_snapshots)
  end
  -- Keep partially-supplied IRPs in sync even though they fire no event.
  poll_irp_updates()
  -- Detect items/modules being removed from deconstruction-marked containers.
  poll_decon_snapshots()
  -- Event-driven: rescan only when something actually changed.
  if needs_rescan or storage.dirty then
    needs_rescan = false
    storage.dirty = nil
    update()
    refresh_all_open_gui() -- reflect the just-updated counts immediately
  end
end

-- ---------------------------------------------------------------------------
-- Status text for the GUI: 【新地星】 / 【网络#7】
-- ---------------------------------------------------------------------------
-- Status value for the GUI: 【新地星】 / 【网络#7】 / 不在物流网络内
-- (only the value; the "当前范围：" label is separate and left-aligned).
local function status_localised(reader)
  local mode = get_mode(reader.unit_number)
  if mode == MODE_SURFACE then
    local surface = reader.surface
    local ok, name = pcall(function()
      if surface.planet then return surface.planet.prototype.localised_name end
      return surface.name
    end)
    return {"", "【", (ok and name) or surface.name, "】"}
  end
  local net_id = reader_network_id(reader)
  if net_id then
    return {"", "【", {"gr-gui.network-prefix"}, tostring(net_id), "】"}
  end
  return {"gr-gui.status-no-network"}
end

-- ---------------------------------------------------------------------------
-- Hover tooltip: refresh the reader's runtime tooltip fields so the info panel
-- (right side when hovering the entity) shows the current settings without
-- opening the GUI. Four fields: scan range mode, current range, filter, qty.
-- set_tooltip_field APPENDS fields (same name does not replace), so we clear all
-- runtime fields first, then re-add. Only real readers (not ghosts) get this.
-- ---------------------------------------------------------------------------
update_reader_tooltip = function(reader)
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
    -- name/value must be LocalisedString arrays ({key}) so the game localizes them.
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

-- ---------------------------------------------------------------------------
-- Custom GUI panel
-- ---------------------------------------------------------------------------
local function rebuild_gui_table(frame, reader)
  local t = frame[GUI_TABLE]
  if not (t and t.valid) then return end
  local ok, counts = pcall(function() return get_counts(reader) end)
  if not ok or type(counts) ~= "table" then counts = {} end
  t.clear()
  -- Present each signal borderless (transparent slot): an item icon button with
  -- the quantity in its bottom-right corner (sprite-button `number`). The table
  -- has a fixed column count, so signals flow across and wrap to the next row.
  for item, count in pairs(counts) do
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

local function build_gui(player, reader)
  local old = player.gui.screen[GUI_FRAME]
  if old and old.valid then old.destroy() end
  player.opened = nil

  local mode = get_mode(reader.unit_number)
  local filter = get_filter(reader.unit_number)
  local qty = get_qty(reader.unit_number)

  -- Standard draggable window frame.
  local frame = player.gui.screen.add{
    type = "frame", name = GUI_FRAME, direction = "vertical",
    tags = {unit = reader.unit_number}
  }
  frame.auto_center = true
  frame.style.minimal_width = 260

  -- Standard titlebar: title + drag handle + close button. Both the title text
  -- and the stretchable drag handle carry drag_target, so the whole titlebar
  -- drags the window. They must NOT ignore interaction or dragging stops.
  local titlebar = frame.add{type = "flow"}
  local title_label = titlebar.add{type = "label", style = "frame_title",
    caption = {"gr-gui.title"}}
  title_label.drag_target = frame
  local drag_space = titlebar.add{type = "empty-widget", style = "draggable_space_header"}
  drag_space.drag_target = frame
  drag_space.style.horizontally_stretchable = true
  drag_space.style.height = 24
  titlebar.add{type = "sprite-button", name = "gr_gui_close", style = "frame_action_button",
    sprite = "utility/close", tooltip = {"gr-gui.close"}}

  -- Content pane with standard padding.
  local content = frame.add{type = "frame", name = "gr_gui_content",
    style = "inside_shallow_frame_with_padding", direction = "vertical"}

  -- 1. 检索范围模式 (scan range mode)
  local range_flow = content.add{type = "flow", direction = "horizontal"}
  range_flow.add{type = "label", caption = {"gr-gui.range-mode"}}
  local range_pad = range_flow.add{type = "empty-widget"}
  range_pad.style.horizontally_stretchable = true
  local range_dd = range_flow.add{type = "drop-down", name = GUI_MODE,
    items = {{"gr-gui.mode-surface"}, {"gr-gui.mode-network"}},
    selected_index = (mode == MODE_SURFACE) and 1 or 2}
  range_dd.style.width = 170

  -- 2. 当前范围 (current range) — label left, value right-aligned
  local status_flow = content.add{type = "flow", name = "gr_gui_status_flow",
    direction = "horizontal"}
  status_flow.add{type = "label", caption = {"gr-gui.current-range"}}
  local status_pad = status_flow.add{type = "empty-widget"}
  status_pad.style.horizontally_stretchable = true
  status_flow.add{type = "label", name = GUI_STATUS, caption = status_localised(reader)}

  -- 3. 筛选模式 (filter mode)
  local filter_flow = content.add{type = "flow", direction = "horizontal"}
  filter_flow.add{type = "label", caption = {"gr-gui.filter"}}
  local filter_pad = filter_flow.add{type = "empty-widget"}
  filter_pad.style.horizontally_stretchable = true
  local filter_dd = filter_flow.add{type = "drop-down", name = GUI_FILTER,
    items = {{"gr-gui.filter-all"}, {"gr-gui.filter-entity"}, {"gr-gui.filter-tiles"}, {"gr-gui.filter-upgrades"}, {"gr-gui.filter-items"}},
    selected_index = (filter == FILTER_ALL) and 1
      or (filter == FILTER_ENTITY) and 2
      or (filter == FILTER_TILES) and 3
      or (filter == FILTER_UPGRADES) and 4
      or 5}
  filter_dd.style.width = 170

  -- 4. 数量模式 (quantity mode)
  local qty_flow = content.add{type = "flow", direction = "horizontal"}
  qty_flow.add{type = "label", caption = {"gr-gui.qty"}}
  local qty_pad = qty_flow.add{type = "empty-widget"}
  qty_pad.style.horizontally_stretchable = true
  local qty_dd = qty_flow.add{type = "drop-down", name = GUI_QTY,
    items = {{"gr-gui.qty-net"}, {"gr-gui.qty-supply"}, {"gr-gui.qty-recycle"}},
    selected_index = (qty == QTY_NET) and 1
      or (qty == QTY_SUPPLY) and 2
      or 3}
  qty_dd.style.width = 170

  -- 5. 当前输出信号 (current output signals)
  content.add{type = "label", caption = {"gr-gui.output"}, style = "frame_subheading_label"}
  local signal_table = content.add{type = "table", name = GUI_TABLE, column_count = 6}
  signal_table.style.horizontal_spacing = 4
  signal_table.style.vertical_spacing = 4
  rebuild_gui_table(content, reader)

  player.opened = frame
end

local function refresh_status_and_table(player, reader)
  local frame = player.gui.screen[GUI_FRAME]
  if not (frame and frame.valid) then return end
  pcall(function()
    local content = frame.gr_gui_content
    local status = content and content.gr_gui_status_flow and content.gr_gui_status_flow[GUI_STATUS]
    if status and status.valid then status.caption = status_localised(reader) end
    rebuild_gui_table(content or frame, reader)
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
    -- Real readers
    for _, e in ipairs(surface.find_entities_filtered{name = READER}) do
      if e.unit_number == unit then return e end
    end
    -- Reader ghosts (ghost_name == READER)
    for _, e in ipairs(surface.find_entities_filtered{type = "entity-ghost"}) do
      if e.unit_number == unit and e.ghost_name == READER then return e end
    end
  end
  return nil
end

local function on_gui_opened(event)
  if event.gui_type ~= defines.gui_type.entity then return end
  local entity = event.entity
  if not (entity and entity.valid) then return end
  -- Match either a real reader or a reader ghost (a ghost of the reader placed by
  -- blueprint/remote view). A ghost's `name` is "entity-ghost"; its `ghost_name`
  -- holds the real entity name.
  local is_reader = (entity.name == READER)
  if not is_reader then
    is_reader = (entity.type == "entity-ghost" and entity.ghost_name == READER)
  end
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
    local filters = {FILTER_ALL, FILTER_ENTITY, FILTER_TILES, FILTER_UPGRADES, FILTER_ITEMS}
    set_filter(unit, filters[e.selected_index] or FILTER_ALL)
  elseif e.name == GUI_QTY then
    local qtys = {QTY_NET, QTY_SUPPLY, QTY_RECYCLE}
    set_qty(unit, qtys[e.selected_index] or QTY_NET)
  else
    return
  end
  -- Keep the ghost config at this position in sync so it is inherited when built.
  save_config_at_pos(reader)
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
script.on_event(defines.events.on_object_destroyed, on_object_destroyed)
-- Copy/paste settings onto a reader (or reader ghost) inherits its config.
if defines.events.on_entity_settings_pasted then
  script.on_event(defines.events.on_entity_settings_pasted, on_settings_pasted)
end
-- Block settings copy-paste between the reader and a vanilla constant-combinator.
if defines.events.on_pre_entity_settings_pasted then
  script.on_event(defines.events.on_pre_entity_settings_pasted, on_pre_settings_pasted)
end

-- Direct fallback for on_player_setup_blueprint: tag readers into the blueprint
-- being created, using event.stack + event.mapping directly. This is more robust
-- than relying solely on bplib-extract (which needs bplib to resolve the blueprint
-- object). We tag the SAME gr_* keys, so placement read-back is shared.
local function on_player_setup_blueprint(event)
  local stack = event.stack
  if not (stack and stack.valid_for_read and event.mapping) then return end
  local mapping = event.mapping.get()
  if not mapping then return end
  for index, entity in pairs(mapping) do
    if is_reader_entity(entity) then
      local cfg = reader_config(entity.unit_number)
      pcall(function()
        stack.set_blueprint_entity_tags(index, {
          [TAG_MODE] = cfg.mode,
          [TAG_FILTER] = cfg.filter,
          [TAG_QTY] = cfg.qty,
        })
      end)
      log("ghost-reader: direct setup_blueprint tagged idx="..tostring(index).." cfg="..tostring(cfg.mode).."/"..tostring(cfg.filter).."/"..tostring(cfg.qty))
    end
  end
end

-- bplib: persist a reader's config into blueprint tags on extraction, and apply
-- it back when the blueprint is placed (covers copy-paste AND blueprints).
script.on_event("bplib-extract", on_bplib_extract)
script.on_event("bplib-positions", on_bplib_positions)
script.on_event("bplib-overlaps", on_bplib_overlaps)
if defines.events.on_player_setup_blueprint then
  script.on_event(defines.events.on_player_setup_blueprint, on_player_setup_blueprint)
end
script.on_event(defines.events.on_marked_for_upgrade, request_update)
script.on_event(defines.events.on_cancelled_upgrade, request_update)
script.on_event(defines.events.on_pre_ghost_upgraded, request_update)

-- Deconstruction (recycling): a building/tile was marked for (or cancelled from)
-- deconstruction -> its recycling signal changed. Also rescan when an entity is
-- removed/replaced (e.g. an upgrade completing replaces the original entity).
-- These call request_update() directly because on_tick may not run after a
-- discrete event (the game may pause simulation), so the output must be refreshed
-- immediately rather than waiting for the next tick.
script.on_event(defines.events.on_marked_for_deconstruction, on_decon_marked)
script.on_event(defines.events.on_cancelled_deconstruction, request_update)
script.on_event(defines.events.on_entity_died, request_update)
script.on_event(defines.events.on_player_mined_entity, request_update)
script.on_event(defines.events.on_robot_mined_entity, request_update)

-- An item-request-proxy was created -> rescan (this is how temporary item
-- requests are discovered event-driven, without wide on_tick polling).
script.on_event(defines.events.on_script_trigger_effect, on_irp_created)

-- A roboport was mined/removed -> network construction areas may have changed.
local roboport_filter = {{filter = "name", name = "roboport"}}
script.on_event(defines.events.on_player_mined_entity, on_roboport_removed, roboport_filter)
script.on_event(defines.events.on_robot_mined_entity, on_roboport_removed, roboport_filter)
script.on_event(defines.events.on_entity_died, on_roboport_removed, roboport_filter)
script.on_event(defines.events.script_raised_destroy, on_roboport_removed, roboport_filter)

-- Register existing ghosts on load so their removal also triggers a rescan.
script.on_configuration_changed(function()
  storage.dirty = true
  sync_irp_snapshots()
  sync_decon_snapshots()
  for _, surface in pairs(game.surfaces) do
    for _, g in ipairs(surface.find_entities_filtered{type = {"entity-ghost", "tile-ghost"}}) do
      if g.valid then pcall(function() script.register_on_object_destroyed(g) end) end
    end
  end
end)

script.on_load(function()
  needs_rescan = true -- do NOT touch storage here (not save/load stable)
  needs_irp_sync = true -- rebuild IRP snapshots on first tick (game is nil here)
end)
