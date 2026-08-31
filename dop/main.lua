-- dop/main.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 主管线（on_tick 主循环 + 顶层事件回调）。
--
-- 组装各功能模块，实现 on_tick 统一流程（DOP 核心）：
--   1. 遍历表面/平台增删 → 更新归属地元信息，记录归属地增删/网络扩缩。
--   2. 依据归属地增删/网络扩缩 → 标记脏读取器。
--   3. 遍历新增读取器 → 标记脏。
--   4. 遍历脏读取器 → 结合范围模式重新归属（加入/移出归属地）。
--   5. 消费实体/虚影/拆除/升级/IRP 变更列表 → 增量更新归属地计数。
--   6. 清空变更列表、脏列表。
--   7. 幽灵读取器输出信号（写电路 + GUI）。
-- 每帧归属地元信息更新 + 读取器输出合并为一次，杜绝一帧多次全量更新。
--
-- 本模块也定义顶层事件回调（on_built_entity / on_mined_entity / on_decon /
-- on_cancel_decon / on_upgrade / on_irp_created / on_destroyed），它们只登记
-- 变更并置位 pending，不直接重扫。

local constants = require("__ghost-reader__/dop/constants")
local items = require("__ghost-reader__/dop/items")
local changes = require("__ghost-reader__/dop/changes")
local regions = require("__ghost-reader__/dop/regions")
local bvh = require("__ghost-reader__/dop/bvh")
local point_tree = require("__ghost-reader__/dop/point_tree")
local events_mod = require("__ghost-reader__/dop/events")
local regions_incr = require("__ghost-reader__/dop/regions_incr")
local irp_mod = require("__ghost-reader__/dop/irp")
local gui = require("__ghost-reader__/dop/gui")
local bplib_mod = require("__ghost-reader__/dop/bplib")
local paste_mod = require("__ghost-reader__/dop/paste")
local M = {}

local REGION_SURFACE = constants.REGION_SURFACE
local REGION_NETWORK = constants.REGION_NETWORK
local QTY_NET, QTY_SUPPLY, QTY_RECYCLE = constants.QTY_NET, constants.QTY_SUPPLY, constants.QTY_RECYCLE
local REGIONS = constants.REGIONS
local READER_REGION = constants.READER_REGION
local DIRTY_READERS = constants.DIRTY_READERS
local DIRTY_FLAG = constants.DIRTY_FLAG
local IRP_SNAPS = constants.IRP_SNAPS
local DECON_MOVERS = constants.DECON_MOVERS
local CHG_ITEM_RECYCLE = constants.CHG_ITEM_RECYCLE
local CHG_ENTITY_RECYCLE = constants.CHG_ENTITY_RECYCLE
local CHG_ENTITY_SUPPLY = constants.CHG_ENTITY_SUPPLY
local CHG_TILE_SUPPLY = constants.CHG_TILE_SUPPLY
local MARK_META = constants.MARK_META
local READER = constants.READER
local tile_pos = constants.tile_pos

local item_for_entity = items.item_for_entity
local item_for_tile = items.item_for_tile
local recycle_entity_contents = items.recycle_entity_contents

local current_changes = changes.current_changes
local reset_changes = changes.reset_changes
local add_count_change = changes.add_count_change
local mark_reader_dirty = changes.mark_reader_dirty

local ensure_region = regions.ensure_region
local remove_region = regions.remove_region
local update_region_bbox = regions.update_region_bbox
local hit_regions_by_point = regions.hit_regions_by_point
local region_key = regions.region_key

local reader_region_of = regions_incr.reader_region_of
local reader_region_set = regions_incr.reader_region_set

local irp_fingerprint = irp_mod.irp_fingerprint
local irp_requests = irp_mod.irp_requests
local irp_removals = irp_mod.irp_removals
local irp_anchor_position = irp_mod.irp_anchor_position
local apply_irp_changes = irp_mod.apply_irp_changes
local apply_irp_removals = irp_mod.apply_irp_removals
local poll_irp_updates = irp_mod.poll_irp_updates
local register_irp_changes = irp_mod.register_irp_changes

local refresh_all_open_gui = gui.refresh_all_open_gui
local render_reader = gui.render_reader

-- 注入 GUI 的 combine_counts 依赖
local function combine_counts(dual, qty)
  local out = {}
  if qty == QTY_SUPPLY then
    for item, n in pairs(dual.supply) do out[item] = n end
  elseif qty == QTY_RECYCLE then
    for item, n in pairs(dual.recycle) do out[item] = n end
  else
    for item, n in pairs(dual.supply) do out[item] = (out[item] or 0) + n end
    for item, n in pairs(dual.recycle) do out[item] = (out[item] or 0) - n end
    for item, n in pairs(out) do if n == 0 then out[item] = nil end end
  end
  return out
end
gui.set_combine_fn(combine_counts)

-- 按 filter 合并归属地计数为扁平 supply/recycle 表。
-- filter 为 "all" 时合并全部类别；否则只取对应类别。
local function merge_counts_for_filter(r, filter)
  local empty = { supply = {}, recycle = {} }
  if not r then return empty end
  local cats
  if filter == constants.FILTER_ENTITY then cats = { constants.FILTER_ENTITY }
  elseif filter == constants.FILTER_TILES then cats = { constants.FILTER_TILES }
  elseif filter == constants.FILTER_UPGRADES then cats = { constants.FILTER_UPGRADES }
  elseif filter == constants.FILTER_ITEMS then cats = { constants.FILTER_ITEMS }
  else cats = { constants.FILTER_ENTITY, constants.FILTER_TILES, constants.FILTER_UPGRADES, constants.FILTER_ITEMS } end
  local out = { supply = {}, recycle = {} }
  for _, cat in ipairs(cats) do
    for item, n in pairs((r.counts.supply and r.counts.supply[cat]) or {}) do
      out.supply[item] = (out.supply[item] or 0) + n
    end
    for item, n in pairs((r.counts.recycle and r.counts.recycle[cat]) or {}) do
      out.recycle[item] = (out.recycle[item] or 0) + n
    end
  end
  return out
end
gui.set_merge_fn(merge_counts_for_filter)
-- mark_pending：把 DIRTY_FLAG 置位，由 on_tick 统一处理。必须在下方闭包
-- 引用前声明为 local，否则闭包会解析到全局 nil。
local function mark_pending()
  storage[DIRTY_FLAG] = true
end
-- 注入 GUI 的配置变更回调
gui.set_config_changed_hook(function(unit)
  if unit then mark_reader_dirty(unit); mark_pending() end
end)

-- 读档后需要重建的标志（模块级局部变量，不存 storage：on_load 禁止改 storage）
local needs_rebuild_after_load = false

-- 网络端口增删后，对变化端口建设区域内现存实体的归属做增量修正。
-- 关键：重叠区域不能重复计/漏计。判断基准是"网络建设范围 BVH 并集"：
--   * in_new = 点落在新网络 BVH（变化后）内
--   * in_old = 点落在旧网络 BVH（变化前）内
--   新增端口时：in_new 且 not in_old → 补记（新进入范围；重叠部分在旧BVH内，不补）。
--   移除端口时：in_old 且 not in_new → 扣减（离开范围；重叠部分在新BVH内，不扣）。
-- 只扫变化端口建设区域（局部，非整网络重建）。
-- 前向声明：apply_entity_change_to_region 在本文件后方定义为 local，
-- scan_port_delta 的词法位置在其之前，若不前置声明会解析为全局 nil。
local apply_entity_change_to_region
-- skip 为 { [si] = { ["x,y"] = true } }：本次 count_changes 已登记的位置。
-- 这些位置的虚影/拆除由 count_changes 用"当前 bvh"权威归属，scan 若再补记会双计。
local function scan_port_delta(r, surface, port, old_bvh, skip)
  if not (r and surface and port and port.crad) then return end
  local x, y, crad = port.x, port.y, port.crad
  local area = { { x - crad, y - crad }, { x + crad, y + crad } }
  local si = surface.index
  local function skipped(ex, ey)
    if not skip then return false end
    local grp = skip[si]
    return grp and grp[ex .. "," .. ey] or false
  end
  local function delta(kind, ex, ey, item, count)
    if skipped(ex, ey) then return end
    local in_new = regions.bvh_contains(r.bvh, ex, ey)
    local in_old = old_bvh and regions.bvh_contains(old_bvh, ex, ey) or false
    if in_new and not in_old then
      apply_entity_change_to_region(r, { kind = kind, item = item, count = count })
    elseif in_old and not in_new then
      apply_entity_change_to_region(r, { kind = kind, item = item, count = -count })
    end
  end
  -- 实体虚影（供给：实体类别）
  for _, g in ipairs(surface.find_entities_filtered{ area = area, type = "entity-ghost" }) do
    if g.valid and g.position then
      local item = item_for_entity(g.ghost_name)
      if item then delta(CHG_ENTITY_SUPPLY, g.position.x, g.position.y, item, 1) end
    end
  end
  -- 地格虚影（供给：地格类别）
  for _, g in ipairs(surface.find_entities_filtered{ area = area, type = "tile-ghost" }) do
    if g.valid and g.position then
      local item = item_for_tile(g.ghost_name)
      if item then delta(CHG_TILE_SUPPLY, g.position.x, g.position.y, item, 1) end
    end
  end
  -- 拆除标记（回收：实体类别 + 内部物品为物品类别）
  for _, en in ipairs(surface.find_entities_filtered{ area = area, to_be_deconstructed = true }) do
    if en.valid and en.position then
      local ent_item = item_for_entity(en.name)
      if ent_item then delta(CHG_ENTITY_RECYCLE, en.position.x, en.position.y, ent_item, 1) end
      local item_tbl = {}
      recycle_entity_contents(en, false, true, item_tbl)
      for item, n in pairs(item_tbl) do
        delta(CHG_ITEM_RECYCLE, en.position.x, en.position.y, item, n)
      end
    end
  end
end

-- 网络合并/分裂：Factorio 无 on_logistic_network_merged/split 事件，且合并时
-- 既有端口的 network_id 会重排而不触发 port_added/port_removed（只新增的桥接
-- 端口触发 port_added）。故在端口增删后，额外核对所有端口的当前 network_id，
-- 把因 id 重排而"归属错位"的端口迁移到正确的网络 region（复用 scan_port_delta
-- 的 BVH diff 做补记/扣减），并标脏受影响的网络读取器。
local function reconcile_ports(surface, skip)
  if not surface then return nil end
  -- 收集该表面所有端口当前归属
  local port_net = {}
  for _, e in ipairs(surface.find_entities_filtered{name = "roboport"}) do
    if e.valid and e.unit_number then
      local net = e.logistic_network
      port_net[e.unit_number] = net and net.network_id or nil
    end
  end
  local regions_tbl = storage[REGIONS] or {}
  -- 第一遍：收集需要迁移的端口（unit, from_net, to_net）与已消失端口
  local moves, removed = {}, {}
  for key, r in pairs(regions_tbl) do
    if r.type == REGION_NETWORK then
      for unit, port in pairs(r.ports) do
        local new_net = port_net[unit]
        if new_net == nil then
          removed[#removed + 1] = { r = r, unit = unit, port = port }
        elseif new_net ~= r.id then
          moves[#moves + 1] = { r = r, unit = unit, port = port, to = new_net }
        end
      end
    end
  end
  local changed = false
  local changed_nets = {}
  -- 迁移端口：从旧 region 移除（扣减），加入新 region（补记）
  for _, m in ipairs(moves) do
    local from = m.r
    local unit, port, to = m.unit, m.port, m.to
    if to == nil then
      -- 端口不再属于任何网络：仅从 from 移除（扣减）
      local old_bvh = regions.region_get_bvh(from)
      from.ports[unit] = nil
      update_region_bbox(from)
      scan_port_delta(from, surface, port, old_bvh, skip)
      changed_nets[from.id] = true
      changed = true
    else
      local to_r = ensure_region(REGION_NETWORK, to)
      to_r.surface_index = surface.index
      -- 1) 从 from 移除：BVH 缩小，扣减离开范围
      local old_bvh = regions.region_get_bvh(from)
      from.ports[unit] = nil
      update_region_bbox(from)
      scan_port_delta(from, surface, port, old_bvh, skip)
      changed_nets[from.id] = true
      -- 2) 加入 to：BVH 扩大，补记新进入范围
      local to_old_bvh = regions.region_get_bvh(to_r)
      to_r.ports[unit] = port
      update_region_bbox(to_r)
      scan_port_delta(to_r, surface, port, to_old_bvh, skip)
      changed_nets[to] = true
      changed = true
    end
  end
  -- 已消失端口：按移除处理
  for _, d in ipairs(removed) do
    local old_bvh = regions.region_get_bvh(d.r)
    d.r.ports[d.unit] = nil
    update_region_bbox(d.r)
    scan_port_delta(d.r, surface, d.port, old_bvh, skip)
    changed_nets[d.r.id] = true
    changed = true
  end
  if changed then
    return changed_nets
  end
  return nil
end

-- 供 mark_dirty_by_topology 只标脏可能受影响的读取器，而非全部。
local function process_region_topology_changes()
  local C = current_changes()
  storage[REGIONS] = storage[REGIONS] or {}
  local regions_tbl = storage[REGIONS]
  local expanded, shrunk = {}, {}
  -- 端口增删涉及的表面（网络合并/分裂 id 重排时需 reconcile 核对迁移）
  local recon_surfaces = {}

  -- 本次脏 tick 已登记到 count_changes 的位置：这些虚影/拆除会用"当前 bvh"由
  -- process_count_changes 权威归属，scan_port_delta 必须跳过，否则同 tick 内
  -- 端口增删 + 虚影增删并存时会双计/双扣。
  local skip = {}
  for _, chg in ipairs(C.count_changes) do
    local grp = skip[chg.surface_index]
    if not grp then grp = {}; skip[chg.surface_index] = grp end
    grp[chg.x .. "," .. chg.y] = true
  end

  for si, _ in pairs(C.surface_added) do
    ensure_region(REGION_SURFACE, si)
  end
  for si, _ in pairs(C.surface_removed) do
    remove_region(REGION_SURFACE, si)
  end

  for port_unit, data in pairs(C.port_added) do
    local net_id = data.net_id
    local r = ensure_region(REGION_NETWORK, net_id)
    local surface = game.get_surface(data.surface_index)
    local old_bvh = regions.region_get_bvh(r)   -- 端口加入前（不含新端口）的网络建设范围
    r.surface_index = data.surface_index
    r.ports[port_unit] = { x = data.x, y = data.y, crad = data.crad }
    update_region_bbox(r)                        -- 重建 BVH（含新端口）
    -- 增量修正：新进入网络建设范围的现存虚影/拆除补记（重叠部分在旧BVH内，不补）
    if surface then
      scan_port_delta(r, surface, r.ports[port_unit], old_bvh, skip)
    end
    expanded[net_id] = true
    if data.surface_index then recon_surfaces[data.surface_index] = true end
  end
  for port_unit, _ in pairs(C.port_removed) do
    for key, r in pairs(regions_tbl) do
      if r.type == REGION_NETWORK then
        if r.ports[port_unit] then
          local port = r.ports[port_unit]
          local surface = game.get_surface(r.surface_index)
          local old_bvh = regions.region_get_bvh(r)   -- 端口移除前（含被移除端口）的建设范围
          r.ports[port_unit] = nil
          update_region_bbox(r)                        -- 重建 BVH（不含被移除端口）
          -- 增量修正：离开网络建设范围的现存虚影/拆除扣减（重叠部分在新BVH内，不扣）
          if surface then
            scan_port_delta(r, surface, port, old_bvh, skip)
          end
          shrunk[r.id] = true
          if r.surface_index then recon_surfaces[r.surface_index] = true end
        end
      end
    end
  end

  -- 网络合并/分裂的 id 重排迁移：端口增删可能伴随既有端口 network_id 变化
  -- （不触发事件）。对涉及的表面做核对迁移，并把受影响网络并入标脏集合。
  for si, _ in pairs(recon_surfaces) do
    local surface = game.get_surface(si)
    if surface then
      local changed_nets = reconcile_ports(surface, skip)
      if changed_nets then
        for nid, _ in pairs(changed_nets) do
          expanded[nid] = true
          shrunk[nid] = true
        end
      end
    end
  end

  return { expanded = expanded, shrunk = shrunk }
end

-- 依据网络扩缩精确标记脏读取器。
-- 关键洞察（大幅降低标脏数量）：
--   * 表面模式的读取器完全不受网络变化影响 → 永不标脏。
--   * 网络拓扑变化（含合并/分裂导致的 network_id 重排）可能改变任何网络模式
--     读取器的归属 → 网络有任何增删时，标脏所有网络模式读取器，使其重新归属。
--     注意：Factorio 在物流网络合并/分裂时可能重排 network_id（实测新建平台并入
--     现有网络后整网 id 可能变化），故不能用"仅扩建标 nil、仅缩小标该网"的旧逻辑，
--     那会漏掉 id 重排导致读取器归属缓存指向已失效的旧 region。
local function mark_dirty_by_topology(net_change)
  local change = net_change or { expanded = {}, shrunk = {} }
  local has_expand = next(change.expanded or {}) ~= nil
  local has_shrink = next(change.shrunk or {}) ~= nil
  if not (has_expand or has_shrink) then return end
  for unit, reg in pairs(storage[READER_REGION] or {}) do
    -- reg = { rtype, id }
    if reg[1] == REGION_NETWORK then
      mark_reader_dirty(unit)
    end
    -- surface 模式读取器：忽略
  end
end

-- 增量更新归属地计数：把一条实体变更应用到它命中的所有归属地。
-- chg.kind 决定 (供给/回收方向, 类别)，chg.item 决定物品名，chg.count 决定增减。
local CATEGORY_ENTITY, CATEGORY_TILES, CATEGORY_UPGRADES, CATEGORY_ITEMS =
  constants.FILTER_ENTITY, constants.FILTER_TILES, constants.FILTER_UPGRADES, constants.FILTER_ITEMS

-- 赋值给前置声明的局部变量（见 scan_port_delta 上方），勿改为 local function。
apply_entity_change_to_region = function(r, chg)
  local counts = r.counts
  -- 方向 + 类别
  local direction, category
  if chg.kind == constants.CHG_ENTITY_SUPPLY then direction, category = counts.supply, CATEGORY_ENTITY
  elseif chg.kind == constants.CHG_TILE_SUPPLY then direction, category = counts.supply, CATEGORY_TILES
  elseif chg.kind == constants.CHG_ITEM_SUPPLY then direction, category = counts.supply, CATEGORY_ITEMS
  elseif chg.kind == constants.CHG_UPGRADE_SUPPLY then direction, category = counts.supply, CATEGORY_UPGRADES
  elseif chg.kind == constants.CHG_ENTITY_RECYCLE then direction, category = counts.recycle, CATEGORY_ENTITY
  elseif chg.kind == constants.CHG_TILE_RECYCLE then direction, category = counts.recycle, CATEGORY_TILES
  elseif chg.kind == constants.CHG_ITEM_RECYCLE then direction, category = counts.recycle, CATEGORY_ITEMS
  elseif chg.kind == constants.CHG_UPGRADE_RECYCLE then direction, category = counts.recycle, CATEGORY_UPGRADES
  end
  if direction and category then
    local item = chg.item
    if item then
      local tbl = direction[category]
      tbl[item] = (tbl[item] or 0) + chg.count
      if tbl[item] == 0 then tbl[item] = nil end
    end
  end
end

-- 消费实体变更列表：每条变更命中到的归属地，更新其计数。
local function process_count_changes()
  local C = current_changes()
  local changes = C.count_changes
  -- 按表面分组：点对象携带 chg 引用（点树构建会原地重排，chg 跟随点）
  local by_surface = {}   -- [si] = { {x=,y=,chg=}, ... }
  for _, chg in ipairs(changes) do
    local si = chg.surface_index
    local grp = by_surface[si]
    if not grp then grp = {}; by_surface[si] = grp end
    grp[#grp + 1] = { x = chg.x, y = chg.y, chg = chg }
  end
  for si, pts in pairs(by_surface) do
    -- 表面归属地：整表面内所有点都命中（surface 模式读取器总能读到该表面的计数）
    local surf = storage[REGIONS] and storage[REGIONS][regions.region_key(REGION_SURFACE, si)]
    if surf then
      for i = 1, #pts do
        apply_entity_change_to_region(surf, pts[i].chg)
      end
    end
    -- 网络归属地：构建点集合多层级包围盒树（一次构建），对每个网络用网络 bbox 逐层筛选，
    -- 命中点再做精确区域判定。避免"每批/每点遍历所有网络"。
    local root = point_tree.build(pts)
    if root then
      for key, r in pairs(storage[REGIONS]) do
        if r.type == REGION_NETWORK then
          local bb = r.bbox
          if bb then
            point_tree.query(root, { x1 = bb[1], y1 = bb[2], x2 = bb[3], y2 = bb[4] }, pts,
              function(i)
                local p = pts[i]
                if regions.region_contains(r, p) then
                  apply_entity_change_to_region(r, p.chg)
                end
              end)
          end
        end
      end
    end
  end
end

-- 全量重建一个归属地的计数（取消拆除/升级的兜底）。
-- 新建空类别计数表（按 filter 类别细分）
local function new_category_counts()
  return {
    supply  = { entity = {}, tiles = {}, upgrades = {}, items = {} },
    recycle = { entity = {}, tiles = {}, upgrades = {}, items = {} },
  }
end

-- 全量重建一个归属地的计数（取消拆除/升级的兜底）。按类别细分填充。
local function rebuild_region_counts(r)
  local counts = new_category_counts()
  local function add_supply(cat, item, n)
    if item then counts.supply[cat][item] = (counts.supply[cat][item] or 0) + (n or 1) end
  end
  local function add_recycle(cat, item, n)
    if item then counts.recycle[cat][item] = (counts.recycle[cat][item] or 0) + (n or 1) end
  end
  if r.type == REGION_SURFACE then
    local surface = game.get_surface(r.id)
    if not surface then return end
    for _, g in ipairs(surface.find_entities_filtered{type = "entity-ghost"}) do
      if g.valid then add_supply(CATEGORY_ENTITY, item_for_entity(g.ghost_name), 1) end
    end
    for _, g in ipairs(surface.find_entities_filtered{type = "tile-ghost"}) do
      if g.valid then add_supply(CATEGORY_TILES, item_for_tile(g.ghost_name), 1) end
    end
    for _, en in ipairs(surface.find_entities_filtered{to_be_deconstructed = true}) do
      if en.valid and en.type ~= "deconstructible-tile-proxy" then
        add_recycle(CATEGORY_ENTITY, item_for_entity(en.name), 1)
        local item_tbl = {}
        recycle_entity_contents(en, false, true, item_tbl)
        for item, n in pairs(item_tbl) do add_recycle(CATEGORY_ITEMS, item, n) end
      elseif en.valid then
        local tile = surface.get_tile(math.floor(en.position.x), math.floor(en.position.y))
        add_recycle(CATEGORY_TILES, tile and item_for_tile(tile.name), 1)
      end
    end
    r.counts = counts
  else
    for _, port in pairs(r.ports) do
      local surface = game.get_surface(r.surface_index)
      if surface and port.crad then
        local area = {{port.x - port.crad, port.y - port.crad}, {port.x + port.crad, port.y + port.crad}}
        for _, g in ipairs(surface.find_entities_filtered{area = area, type = "entity-ghost"}) do
          if g.valid then add_supply(CATEGORY_ENTITY, item_for_entity(g.ghost_name), 1) end
        end
        for _, en in ipairs(surface.find_entities_filtered{area = area, to_be_deconstructed = true}) do
          if en.valid and en.type ~= "deconstructible-tile-proxy" then
            add_recycle(CATEGORY_ENTITY, item_for_entity(en.name), 1)
            local item_tbl = {}
            recycle_entity_contents(en, false, true, item_tbl)
            for item, n in pairs(item_tbl) do add_recycle(CATEGORY_ITEMS, item, n) end
          end
        end
      end
    end
    r.counts = counts
  end
end

-- =============================================================================
-- 顶层事件回调（只登记变更 + 置位 pending）
-- =============================================================================

local function on_built_entity(event)
  local e = event.entity
  if not (e and e.valid) then return end
  if e.type == "entity-ghost" then
    if e.ghost_name == READER then
      -- 读取器虚影：只继承配置到 ghost_cfg（供建成真实读取器时继承），
      -- 不登记为读取器、不进入脏读取器/渲染管线（虚影无电路输出，step7 只渲染
      -- name==READER 的真实读取器）。若登记 reader_added 会把虚影塞进 DIRTY_READERS，
      -- on_tick step4 会对每个虚影调 find_reader 做全表面扫描 → 放置大量虚影时 O(N×全表面) 卡顿。
      bplib_mod.apply_reader_config_from_tags(e)
      -- 不 mark_pending：虚影本身不产生任何计数/归属地变化。
    else
      events_mod.on_entity_ghost_built(e)
      mark_pending()
    end
  elseif e.type == "tile-ghost" then
    events_mod.on_tile_ghost_built(e)
    mark_pending()
  elseif e.name == READER then
    current_changes().reader_added[e.unit_number] = e.surface.index
    -- 真实读取器构建：从蓝图 tags / pending_tags 继承配置
    bplib_mod.apply_reader_config_from_tags(e)
    mark_pending()
  elseif e.name == "roboport" then
    events_mod.on_port_added(e, e.logistic_network and e.logistic_network.network_id)
    mark_pending()
  end
end

local function on_mined_entity(event)
  local e = event.entity
  if not (e and e.valid) then return end
  if e.name == READER then
    events_mod.on_reader_removed(e.unit_number)
    mark_pending()
  elseif e.name == "roboport" then
    events_mod.on_port_removed(e)
    mark_pending()
  end
end

local function on_destroyed(event)
  if not (event and event.type == defines.target_type.entity) then return end
  -- 无 unit_number 的实体（环境实体/落地物品/地格代理）销毁：useful_id=0。
  -- 改按 registration_number 反查元信息，回滚其回收计数。
  if (not event.useful_id) or event.useful_id == 0 then
    local ok = events_mod.rollback_entity_by_registration(event.registration_number)
    if ok then
      -- rollback_entity_by_registration 已同时清理 "r:reg" 与位置 key 别名，无需再 clear
      mark_pending()
    end
    return
  end
  local uid = event.useful_id
  events_mod.on_reader_removed(uid)
  events_mod.on_port_removed({ unit_number = uid })
  -- IRP 被销毁（请求完成/取消）：按快照反扣其供给与回收，避免信号残留。
  local snaps = storage[IRP_SNAPS]
  if snaps and snaps[uid] then
    local d = snaps[uid]
    if d and d.surface_index then
      apply_irp_changes(d.reqs or {}, d.surface_index, d.x, d.y, -1)
      apply_irp_removals(d.removals or {}, d.surface_index, d.x, d.y, -1)
    end
    snaps[uid] = nil
  end
  -- 拆除完成：实体被移除，其回收计数应反向扣减（依据元信息），否则残留。
  -- 注意 on_object_destroyed 时实体已无效，需按 unit_number 反向扣减。
  events_mod.rollback_entity_by_unit(uid)
  -- 清理该实体的标记元信息与移动快照
  events_mod.clear_mark_meta({ unit_number = uid })
  events_mod.clear_decon_mover({ unit_number = uid })
  mark_pending()
end

local function on_decon(event)
  local e = event.entity
  if e and e.valid then events_mod.on_decon_marked(e); mark_pending() end
end

local function on_cancel_decon(event)
  local e = event.entity
  if not (e and e.valid) then return end
  -- 依据元信息精确回滚（反向变更，count 取负），消除全量重建。
  local ok = events_mod.rollback_entity(e)
  if ok then
    events_mod.clear_decon_mover(e)
    mark_pending()
  else
    -- 兜底：旧存档或异常情况没有元信息时，退化为按位置标脏全量重建。
    if e.position then
      storage.rollback_at = storage.rollback_at or {}
      local si = e.surface.index
      local x, y = e.position.x, e.position.y
      storage.rollback_at[#storage.rollback_at + 1] = { si, x, y }
      mark_pending()
    end
  end
end

local function on_upgrade(event)
  local e = event.entity
  if e and e.valid then events_mod.on_upgrade_marked(e); mark_pending() end
end

local function on_irp_created(event)
  if event.effect_id ~= "gr-item-request-proxy" then return end
  local e = event.source_entity
  if e and e.valid and e.type == "item-request-proxy" then
    pcall(function() script.register_on_object_destroyed(e) end)
    storage[IRP_SNAPS] = storage[IRP_SNAPS] or {}
    -- 归属位置用 proxy_target（被请求容器）的位置，与 poll 一致；容器被拖走时正确反映归属。
    local anchor = irp_anchor_position(e) or {}
    storage[IRP_SNAPS][e.unit_number] = {
      surface_index = anchor.surface or e.surface.index,
      fingerprint = irp_fingerprint(e),
      x = anchor.x,
      y = anchor.y,
      reqs = irp_requests(e),
      removals = irp_removals(e),
    }
    register_irp_changes(e)
    mark_pending()
    log("ghost-reader[IRP] created unit="..tostring(e.unit_number).." reqs="..tostring(#irp_requests(e)).." removals="..tostring(#irp_removals(e)).." fp="..tostring(irp_fingerprint(e)))
  end
end

-- =============================================================================
-- on_tick 主循环（DOP 核心）
-- =============================================================================

-- 拆除标记的移动实体位置/内容物轮询：
--   * 位置变化（列车车厢等被拖走）→ 进出建设区域，改变回收计数归属；
--   * 内容物变化（机器人拆除机械臂/传送带/容器时逐步搬走其手持物/货物/内部
--     物品与插件）→ 回收的物品计数随之减少。
-- 无原生事件，每帧对比位置与内容物指纹，变化时做增量撤销/重加。
--
-- 性能关键：早期实现"对每个快照各做一次全表面 find_entities_filtered{to_be_deconstructed}"
-- 扫描，N 个标记拆除实体 = 每帧 N 次全表面扫描 → 大量标记拆除实体时严重卡顿。
-- 现改为**每个表面每帧只扫一次**，建 unit→entity 索引，再遍历全部快照复用该索引。
-- 拆除标记的移动实体位置/内容物轮询：
--   * 位置变化（列车车厢等被拖走）→ 进出建设区域，改变回收计数归属；
--   * 内容物变化（机器人拆除机械臂/传送带/容器时逐步搬走其手持物/货物/内部
--     物品与插件）→ 回收的物品计数随之减少。
-- 无原生事件，每帧对比位置与内容物指纹，变化时做增量撤销/重加。
--
-- 性能关键（彻底与标记拆除实体总数 N 解耦）：
--   旧实现每帧 (a) 对每个表面全表面 find_entities_filtered{to_be_deconstructed} 建索引
--   (O(N)) 且 (b) pairs(snaps) 遍历全部快照 (O(N))，导致持续帧开销随 N 增长。
--   现改为 IRP 式 round-robin：每帧只处理 DECON_POLL_PER_TICK 个快照（游标轮转），
--   且按快照记录的位置做小区域 find 获取实体（O(区域)），不整表面扫描；
--   可移动实体在小区域找不到时再做一次该表面的有界兜底扫描。每帧成本 O(budget)。
local function poll_decon_movers(mark_pending)
  local snaps = storage[DECON_MOVERS]
  if not snaps or not next(snaps) then return end

  local budget = constants.DECON_POLL_PER_TICK
  local index_key = constants.DECON_POLL_INDEX

  -- round-robin：从游标开始，用 next() 顺序取 budget 个 key（到尾绕回开头）。
  -- 收集用局部数组，避免遍历中删除快照导致 next() 的 prev 失效。
  local units = {}
  local start = storage[index_key]
  -- 游标可能指向已删除的快照（取消/移除/重建），无效则从头开始
  if start ~= nil and snaps[start] == nil then start = nil; storage[index_key] = nil end
  local prev = start
  local guard = 0
  while #units < budget do
    guard = guard + 1
    if guard > budget * 2 + 2 then break end   -- 防死循环（表很小或已被改）
    local k = next(snaps, prev)
    if k == nil then
      if prev == nil then break end            -- 整个表已遍历完（无绕回对象）
      prev = nil                                -- 绕回表头
    else
      units[#units + 1] = k
      prev = k
      storage[index_key] = k
      if k == start then break end              -- 已绕回一圈
    end
  end
  if #units == 0 then storage[index_key] = nil end

  for _, unit in ipairs(units) do
    local data = snaps[unit]
    if data then
      -- 直接按 unit_number 取实体（O(1)，无需 find_entities_filtered），对可移动实体也可靠
      local ent = game.get_entity_by_unit_number(unit)
      if ent and ent.valid and not ent.to_be_deconstructed then ent = nil end
      if ent and ent.valid and ent.position then
        local t = tile_pos(ent.position)
        local ot = tile_pos(data)
        local moved = data.movable and ((t.x ~= ot.x) or (t.y ~= ot.y))
        local old_items = data.stock or {}
        local new_items = events_mod.content_items(ent)
        local function fp(tbl)
          local p = {}
          for k, v in pairs(tbl) do p[#p + 1] = tostring(k) .. ":" .. tostring(v) end
          table.sort(p)
          return table.concat(p, ";")
        end
        local stock_changed = (fp(old_items) ~= fp(new_items))
        if moved or stock_changed then
          local si = ent.surface.index
          for item, n in pairs(old_items) do
            add_count_change(CHG_ITEM_RECYCLE, data.surface_index, data.x, data.y, item, -n)
          end
          for item, n in pairs(new_items) do
            add_count_change(CHG_ITEM_RECYCLE, si, ent.position.x, ent.position.y, item, n)
          end
          local ent_item = item_for_entity(ent.name)
          if ent_item then
            add_count_change(CHG_ENTITY_RECYCLE, data.surface_index, data.x, data.y, ent_item, -1)
            add_count_change(CHG_ENTITY_RECYCLE, si, ent.position.x, ent.position.y, ent_item, 1)
          end
          data.surface_index = si
          data.x = ent.position.x
          data.y = ent.position.y
          data.stock = new_items
          if unit then events_mod.meta_set_items("u:" .. tostring(unit), new_items) end
          if moved and unit then
            events_mod.meta_set_position("u:" .. tostring(unit), si, ent.position.x, ent.position.y)
          end
          if mark_pending then mark_pending() end
        end
      else
        snaps[unit] = nil -- 已取消/已移除
      end
    end
  end
  if #units == 0 then storage[index_key] = nil end
end

-- 前置声明：rebuild_all 在文件后方定义，但 on_tick 需要调用它（Lua 中 local
-- function 只在声明之后可见，故此处先声明，后面再赋值）。
local rebuild_all

local function on_tick()
  -- 0) 读档后首帧重建（on_load 中 game 不可用且不能改 storage，故延迟到第一帧）
  if needs_rebuild_after_load then
    needs_rebuild_after_load = false
    rebuild_all()
  end

  -- 无事件时，仍每帧做少量轮询（IRP 指纹/位置 + 拆除标记移动实体的位置）
  poll_irp_updates(mark_pending)
  poll_decon_movers(mark_pending)

  if not storage[DIRTY_FLAG] then
    return
  end
  storage[DIRTY_FLAG] = nil

  -- 1) 归属地拓扑：表面/平台增删 → 更新元信息
  local net_change = process_region_topology_changes()

  -- 2) 网络扩缩 → 精确标记脏读取器（表面模式不受影响；扩建只标未归属、缩小只标该网络）
  mark_dirty_by_topology(net_change)

  -- 3) 新增读取器 → 标记脏
  for unit, _ in pairs(current_changes().reader_added) do
    mark_reader_dirty(unit)
  end
  -- 删除读取器：清理其归属与输出指纹
  for unit, _ in pairs(current_changes().reader_removed) do
    storage[READER_REGION] = storage[READER_REGION] or {}
    storage[READER_REGION][unit] = nil
    if storage.out_fp then storage.out_fp[unit] = nil end
  end

  -- 4) 遍历脏读取器 → 结合范围模式重新归属
  -- 性能：一次性建 unit→reader 索引（跨表面），避免对每个脏读取器各自调 find_reader
  -- 做全表面扫描（那会 O(N × 全表面)）。
  local reader_by_unit = {}
  local function build_reader_index()
    for _, surface in pairs(game.surfaces) do
      for _, e in ipairs(surface.find_entities_filtered{name = READER}) do
        if e.valid and e.unit_number then reader_by_unit[e.unit_number] = e end
      end
    end
  end
  build_reader_index()
  for unit, _ in pairs(storage[DIRTY_READERS] or {}) do
    local reader = reader_by_unit[unit]
    if reader and reader.valid then
      local rtype, id = reader_region_of(reader)
      reader_region_set(unit, rtype, id)
    else
      storage[READER_REGION] = storage[READER_REGION] or {}
      storage[READER_REGION][unit] = nil
    end
  end

  -- 5) 消费实体/虚影/拆除/升级/IRP 变更列表 → 增量更新归属地计数
  process_count_changes()
  -- 兜底：rollback_at 中的点命中归属地整体标为需重建（仅当元信息缺失时触发）
  for _, pt in ipairs(storage.rollback_at or {}) do
    local point = { surface_index = pt[1], x = pt[2], y = pt[3] }
    local hits = {}
    hit_regions_by_point(point, hits)
    for key, _ in pairs(hits) do
      storage.region_rebuild = storage.region_rebuild or {}
      storage.region_rebuild[key] = true
    end
  end
  storage.rollback_at = {}
  -- IRP 重算（指纹变化）：在该 IRP 位置重登记供给
  for unit, _ in pairs(storage.irp_rescan_at or {}) do
    local data = storage[IRP_SNAPS] and storage[IRP_SNAPS][unit]
    if data then
      local surface = data.surface_index and game.get_surface(data.surface_index)
      if surface then
        for _, e in ipairs(surface.find_entities_filtered{type = "item-request-proxy"}) do
          if e.unit_number == unit then register_irp_changes(e); break end
        end
      end
    end
  end
  storage.irp_rescan_at = {}

  -- 5.5) 重建被标记的归属地计数（仅兜底路径：元信息缺失的取消操作）。
  -- 正常情况下取消拆除/升级走增量 rollback_entity，不应触发此路径；一旦触发
  -- 说明元信息缺失（如旧存档/异常），属于异常：写日志 + 游戏内弹窗提示。
  for key, _ in pairs(storage.region_rebuild or {}) do
    log("[ghost-reader][WARN] region rebuild fallback triggered for region '" .. tostring(key)
      .. "' — mark_meta was missing so a full rescan was used instead of incremental rollback. "
      .. "This is NOT expected in normal operation; please report if you see it repeatedly.")
    -- 游戏内提示（对所有玩家弹出，便于即时发现异常）
    pcall(function()
      game.print{"", {"gr-gui.warn-prefix"}, {"gr-gui.warn-region-rebuild"}, " '" .. tostring(key) .. "'"}
    end)
    local r = storage[REGIONS] and storage[REGIONS][key]
    if r then rebuild_region_counts(r) end
  end
  storage.region_rebuild = {}

  -- 6) 清空变更列表、脏列表
  reset_changes()
  storage[DIRTY_READERS] = {}

  -- 7) 幽灵读取器输出信号（每脏 tick 清一次输出缓存，同网络同配置读取器共享）
  gui.reset_output_cache()
  for _, surface in pairs(game.surfaces) do
    for _, reader in ipairs(surface.find_entities_filtered{name = READER}) do
      render_reader(reader)
    end
  end
  refresh_all_open_gui()
end

-- =============================================================================
-- 生命周期：初始化（读档/配置变化后重建归属地）
-- =============================================================================

-- 读档/配置变化后的全量重建。
-- 关键点：storage 是 mod 的存档持久化表，归属地元数据/读取器归属/变更列表
-- 其实都能随存档保存。但为了稳健（避免旧存档数据不一致、以及 mode 等配置
-- 变更），我们采用"读档即重建"：清空状态，扫描现存实体，把它们的当前状态
-- 登记为变更，交由 on_tick 的增量管线自然重建归属地元数据。这样不需要新增
-- 独立的全量重扫函数，也保证读取器能读到信号。
rebuild_all = function()
    storage[REGIONS] = nil
  storage[READER_REGION] = nil
  storage[DIRTY_READERS] = nil
  reset_changes()
  storage.irp_rescan_at = {}
  storage.rollback_at = {}
  storage.region_rebuild = {}
  storage[MARK_META] = nil
  storage[DECON_MOVERS] = nil
  storage[constants.DECON_POLL_INDEX] = nil
  storage[IRP_SNAPS] = nil   -- 懒初始化：无 IRP 时保持 nil，poll_irp_updates 首行即可早退

  -- 1) 平台：登记 port_added（构建网络归属地元信息）
  for _, surface in pairs(game.surfaces) do
    for _, port in ipairs(surface.find_entities_filtered{name = "roboport"}) do
      if port.valid then
        events_mod.on_port_added(port, port.logistic_network and port.logistic_network.network_id)
      end
    end
  end

  -- 2) 幽灵读取器：登记 reader_added（建立读取器归属）
  for _, surface in pairs(game.surfaces) do
    for _, reader in ipairs(surface.find_entities_filtered{name = READER}) do
      if reader.valid and reader.unit_number then
        current_changes().reader_added[reader.unit_number] = surface.index
      end
    end
  end

  -- 3) 虚影（实体/地格）：登记供给
  for _, surface in pairs(game.surfaces) do
    for _, g in ipairs(surface.find_entities_filtered{type = "entity-ghost"}) do
      if g.valid and g.ghost_name ~= READER then
        events_mod.on_entity_ghost_built(g)
      end
    end
    for _, g in ipairs(surface.find_entities_filtered{type = "tile-ghost"}) do
      if g.valid then events_mod.on_tile_ghost_built(g) end
    end
  end

  -- 4) 标记升级：登记供给+回收
  for _, surface in pairs(game.surfaces) do
    for _, en in ipairs(surface.find_entities_filtered{to_be_upgraded = true}) do
      if en.valid then events_mod.on_upgrade_marked(en) end
    end
  end

  -- 5) 标记拆除：登记回收 + 记录移动实体快照
  for _, surface in pairs(game.surfaces) do
    for _, en in ipairs(surface.find_entities_filtered{to_be_deconstructed = true}) do
      if en.valid and en.type ~= "deconstructible-tile-proxy" then
        events_mod.on_decon_marked(en)
      elseif en.valid then
        events_mod.on_decon_marked(en)
      end
    end
  end

  -- 6) IRP：重建快照 + 登记供给
  storage[IRP_SNAPS] = storage[IRP_SNAPS] or {}
  for _, surface in pairs(game.surfaces) do
    for _, g in ipairs(surface.find_entities_filtered{type = "item-request-proxy"}) do
      if g.valid and g.unit_number then
        pcall(function() script.register_on_object_destroyed(g) end)
        storage[IRP_SNAPS][g.unit_number] = {
          surface_index = surface.index,
          fingerprint = irp_fingerprint(g),
          x = g.position and g.position.x,
          y = g.position and g.position.y,
          reqs = irp_requests(g),
          removals = irp_removals(g),
        }
        register_irp_changes(g)
      end
    end
  end

  -- 由 on_tick 消费以上变更完成重建
  mark_pending()
end

local function on_configuration_changed()
  rebuild_all()
end

-- 事件注册
function M.register()
  script.on_event(defines.events.on_tick, on_tick)
  script.on_event(defines.events.on_built_entity, on_built_entity)
  script.on_event(defines.events.on_robot_built_entity, on_built_entity)
  script.on_event(defines.events.script_raised_built, on_built_entity)
  script.on_event(defines.events.script_raised_revive, on_built_entity)
  script.on_event(defines.events.on_object_destroyed, on_destroyed)
  script.on_event(defines.events.on_player_mined_entity, on_mined_entity)
  script.on_event(defines.events.on_robot_mined_entity, on_mined_entity)
  script.on_event(defines.events.on_marked_for_deconstruction, on_decon)
  script.on_event(defines.events.on_cancelled_deconstruction, on_cancel_decon)
  script.on_event(defines.events.on_marked_for_upgrade, on_upgrade)
  script.on_event(defines.events.on_cancelled_upgrade, on_cancel_decon)
  script.on_event(defines.events.on_pre_ghost_upgraded, on_upgrade)
  script.on_event(defines.events.on_script_trigger_effect, on_irp_created)
  script.on_event(defines.events.on_gui_opened, gui.on_gui_opened)
  script.on_event(defines.events.on_gui_closed, gui.on_gui_closed)
  script.on_event(defines.events.on_gui_click, gui.on_gui_click)
  script.on_event(defines.events.on_gui_selection_state_changed, gui.on_gui_selection_state_changed)
  script.on_event(defines.events.script_raised_destroy, on_mined_entity)
  -- bplib：蓝图 tags 配置持久化
  script.on_event("bplib-extract", bplib_mod.on_bplib_extract)
  script.on_event("bplib-positions", bplib_mod.on_bplib_positions)
  script.on_event("bplib-overlaps", bplib_mod.on_bplib_overlaps)
  if defines.events.on_player_setup_blueprint then
    script.on_event(defines.events.on_player_setup_blueprint, bplib_mod.on_player_setup_blueprint)
  end
  -- 复制粘贴配置：阻止 reader<->vanilla 恒压器互传，允许 reader->reader 继承
  if defines.events.on_entity_settings_pasted then
    script.on_event(defines.events.on_entity_settings_pasted, paste_mod.on_settings_pasted)
  end
  if defines.events.on_pre_entity_settings_pasted then
    script.on_event(defines.events.on_pre_entity_settings_pasted, paste_mod.on_pre_settings_pasted)
  end
  script.on_configuration_changed(on_configuration_changed)
  -- 读档时 game 不可用，仅标记 needs_rebuild_after_load，由 on_tick 首帧执行
  -- rebuild_all。注意 on_load 禁止修改 storage，故用模块级局部变量。
  script.on_load(function()
    needs_rebuild_after_load = true
  end)
end

return M










