local region = require("__ghost-reader__/dop2/region")
local meta = require("__ghost-reader__/dop2/meta")
local item = require("__ghost-reader__/dop2/item")
local config = require("__ghost-reader__/dop2/config")
local changes = require("__ghost-reader__/dop2/changes")
local snapshot = require("__ghost-reader__/dop2/snapshot")
local gui = require("__ghost-reader__/dop2/gui")
local bplib = require("__ghost-reader__/dop2/bplib")
local paste = require("__ghost-reader__/dop2/paste")

local M = {}

---读取器当前应归属的归属地：按配置的检索范围模式取所在表面或所在物流网络。
---不在任何物流网络内（或没有物流网络）时返回 nil，此时读取器无信号可读。
---@param entity LuaEntity
---@return region|nil
local function reader_region_of(entity)
    if config.get_mode(entity.unit_number) == range_mode.SURFACE then
        return region.ensure_region_surface(entity.surface)
    end
    local logistic_network = entity.surface.find_logistic_network_by_position(entity.position, entity.force)
    if not logistic_network then return nil end
    return region.ensure_region_logistic_network(logistic_network)
end

---@param e LuaEntity
local function on_entity_ghost_built(e)
    local m = meta.ensure_entity_meta(e)
    m:set_count_item('ghost', change_type.ENTITY_SUPPLY, item.item_for_entity(e.ghost_name), e.quality.name, 1)
end

---@param e LuaEntity
local function on_tile_ghost_built(e)
    local m = meta.ensure_entity_meta(e)
    m:set_count_item('ghost', change_type.TILE_SUPPLY, item.item_for_tile(e.ghost_name), e.quality.name, 1)
end

---@param event EventData.on_built_entity
local function on_built_entity(event)
    local e = event.entity
    if e.type == "entity-ghost" then
        on_entity_ghost_built(e)
        --读取器虚影：应用蓝图 tags 里的配置。虚影自身没有输出，但配置要按位置留下，
        --供同位置建成真实读取器时继承。
        if e.ghost_name == READER then
            bplib.apply_reader_config_from_tags(e)
        end
    elseif e.type == "tile-ghost" then
        on_tile_ghost_built(e)
    elseif e.name == READER then
        meta.ensure_reader_meta(e)
        --真实读取器建成：依次从 tags / pending_tags / ghost_cfg 继承配置
        bplib.apply_reader_config_from_tags(e)
    elseif e.name == "roboport" then
        meta.ensure_roboport_meta(e)
    end
end

---@param event EventData.on_surface_created
local function on_surface_created(event)
    region.ensure_region_surface(game.surfaces[event.surface_index])
end

---登记一个被标记拆除的目标。按类别分开存计数项：
---  * 地格代理（deconstructible-tile-proxy）：它代表"某格地格被标记拆除"，
---    只有地格类别的回收（地格 → 可放置该地格的物品），单独一个计数项；
---  * 普通实体本身：实体类别回收（这个计数项同时充当"已标记拆除"的判据）；
---  * 实体携带的物品，又按"是否需要机器人一件件搬"分两类：
---      - 环境实体/落地物品：标记拆除的瞬间就被移除，回收物当场算准，
---        直接计一次到 'deconstruction-instant'，不建快照；
---      - 有内部存储的实体：机器人一件件搬，数量会变，
---        交给内容物快照写入 'deconstruction-inventory' 并由轮询跟踪。
---事件处理与全量重建共用本函数，保证两条路径登记出的状态完全一致。
---@param entity LuaEntity
local function apply_deconstruction(entity)
    if not (entity and entity.valid) then return end
    local m = meta.ensure_entity_meta(entity)

    --地格代理：自身没有实体物品、也没有内容物，只有地格回收
    if entity.type == "deconstructible-tile-proxy" then
        local position = entity.position
        local tile = entity.surface.get_tile(math.floor(position.x), math.floor(position.y))
        m:set_count_item(COUNT_DECON_TILE,
            change_type.TILE_RECYCLE,
            tile and item.item_for_tile(tile.name),
            nil,
            1)
        return
    end

    --被拆实体本身记为实体类别回收（这个计数项同时充当"已标记拆除"的判据）
    m:set_count_item(COUNT_DECON_ENTITY,
        change_type.ENTITY_RECYCLE,
        item.item_for_entity(entity.name),
        entity.quality.name,
        1)
    --可移动实体（含落地物品）另建位置快照：位置会变，而"移动"没有任何事件可听，
    --只能靠快照按格点比对指纹，发现它进出建设区域后重解析归属地。
    --注意这与上面"瞬间计一次"是两件事：计数只在标记时定，位置则持续跟踪。
    if item.is_movable(entity) then
        m:register_movable()
    end

    --环境实体/落地物品：瞬间拆除，回收物现在就定了，计一次即可（空表就没必要占计数项）
    if item.is_instant_recycle(entity) then
        local recycled = item.instant_recycle_items(entity)
        if next(recycled) then
            m:replace_count_item(COUNT_DECON_INSTANT, change_type.ITEM_RECYCLE, recycled)
        end
    end
    --有内部存储：交给内容物快照（创建时立刻算一次写进 'deconstruction-inventory'，
    --之后内容变化——机器人搬走——由轮询增量更新）
    if item.has_inventory_contents(entity) then
        m.inventory_snapshot = snapshot.add_inventory_snapshot(entity)
    end
end

---@param event EventData.on_marked_for_deconstruction
local function on_deconstruction(event)
    apply_deconstruction(event.entity)
end

---@param event EventData.on_cancelled_deconstruction
local function on_cancel_deconstruction(event)
    local m = meta.ensure_entity_meta(event.entity)
    m:remove_count_item(COUNT_DECON_ENTITY)
    m:remove_count_item(COUNT_DECON_INVENTORY)
    m:remove_count_item(COUNT_DECON_INSTANT)
    m:remove_count_item(COUNT_DECON_TILE)
    if m.movable > 0 then
        m:unregister_movable()
    end
    --内容物快照与本事件成对出现（只有拆除标记会建它），直接撤掉即可
    if m.inventory_snapshot then
        snapshot.remove_snapshot(m.inventory_snapshot)
        m.inventory_snapshot = nil
    end
end

---登记一个被标记升级的实体：升级目标记为"升级类别供给"，实体自身记为"升级类别回收"。
---目标从实体自身取（entity.get_upgrade_target()，返回新实体原型 + 新品质），
---而不是用事件字段：事件里的 previous_target 是可选的，且全量重建时根本没有事件。
---事件处理与全量重建共用本函数。
---@param entity LuaEntity
local function apply_upgrade(entity)
    if not (entity and entity.valid) then return end
    local m = meta.ensure_entity_meta(entity)
    --get_upgrade_target 返回新实体原型 + 新品质（品质是原型，取名字当键）
    local target, target_quality = entity.get_upgrade_target()
    m:set_count_item('upgrade', change_type.UPGRADE_SUPPLY,
        target and item.item_for_entity(target.name),
        target_quality and target_quality.name, 1)
    m:set_count_item('upgrade', change_type.UPGRADE_RECYCLE,
        item.item_for_entity(entity.name),
        entity.quality.name, 1)
end

---@param event EventData.on_marked_for_upgrade
local function on_upgrade(event)
    apply_upgrade(event.entity)
end

---@param event EventData.on_cancelled_upgrade
local function on_cancel_upgrade(event)
    local m = meta.ensure_entity_meta(event.entity)
    m:remove_count_item('upgrade')
end


---登记一个 IRP（物品请求代理）：把它的请求/回收记成目标容器上的计数项，
---并建立 IRP 快照跟踪后续变化（请求被部分供应）。事件处理与全量重建共用本函数。
---@param irp LuaEntity
local function apply_irp(irp)
    if not (irp and irp.valid and irp.type == "item-request-proxy") then return end
    local irp_meta = meta.ensure_entity_meta(irp)

    local target = irp.proxy_target --请求容器实体

    if target and target.valid then
        local m = meta.ensure_entity_meta(target)
        irp_meta.proxy_target = m
        --IRP 快照：创建时立刻算一次并写入目标容器上的 'irpN' 计数项，
        --之后请求被部分供应（item_requests 收缩）由轮询增量更新
        irp_meta.irp_snapshot = snapshot.add_irp_snapshot(irp)
        if item.is_movable(m.entity) then
            m:register_movable()
        end
    end
end

---@param event EventData.on_script_trigger_effect
local function on_irp_created(event)
    if event.effect_id ~= "gr-item-request-proxy" then return end
    apply_irp(event.source_entity)
end


---读档后是否需要全量重建。
---on_load 里 game 不可用、也不允许改 storage，所以只能置这个模块级标志，
---由读档后的第一个 on_tick 执行（与 dop1 的 needs_rebuild_after_load 同一思路）。
local needs_rebuild = false

--================================================================================================
-- 初始化与全量重建
--================================================================================================

---全量重建：先清空各模块的注册表，再按当前世界状态重新登记一遍。
---触发时机：
---  1. 读档（见 needs_rebuild）——objects_meta / regions / 快照队列 / changes 都是模块局部
---     变量，读档时随 control.lua 重跑而清空，必须重建，否则读档后什么都不统计；
---  2. 配置变化（on_configuration_changed，含本 mod 版本变化）。
---登记顺序沿用 dop1：平台 → 读取器 → 虚影（实体/地格）→ 升级标记 → 拆除标记 → IRP。
---登记动作一律复用事件处理层的函数，保证"重建出来的状态"与"事件驱动出来的状态"一致。
---引擎侧的 register_on_object_destroyed 是幂等的（同一对象返回同一注册号），
---所以重建只是重新建立我们这边的元信息，不影响销毁事件的投递。
function M.rebuild()
    --1) 清空模块级注册表
    meta.reset()
    region.reset()
    snapshot.reset()
    changes.clear()

    --2) 表面归属地（顺带完成销毁注册，供 on_object_destroyed 回收）
    for _, surface in pairs(game.surfaces) do
        region.ensure_region_surface(surface)
    end

    --3) 无人机平台：登记平台元信息，并标脏其范围内的读取器/计数实体
    for _, surface in pairs(game.surfaces) do
        for _, port in ipairs(surface.find_entities_filtered({ name = "roboport" })) do
            if port.valid then
                meta.ensure_roboport_meta(port)
            end
        end
    end

    --4) 幽灵读取器
    for _, surface in pairs(game.surfaces) do
        for _, reader in ipairs(surface.find_entities_filtered({ name = READER })) do
            if reader.valid then
                meta.ensure_reader_meta(reader)
            end
        end
    end

    --5) 虚影：实体虚影（含读取器虚影，它与事件路径一致地记为实体类别供给）与地格虚影
    for _, surface in pairs(game.surfaces) do
        for _, ghost in ipairs(surface.find_entities_filtered({ type = "entity-ghost" })) do
            if ghost.valid then
                on_entity_ghost_built(ghost)
            end
        end
        for _, ghost in ipairs(surface.find_entities_filtered({ type = "tile-ghost" })) do
            if ghost.valid then
                on_tile_ghost_built(ghost)
            end
        end
    end

    --6) 升级标记
    for _, surface in pairs(game.surfaces) do
        for _, entity in ipairs(surface.find_entities_filtered({ to_be_upgraded = true })) do
            apply_upgrade(entity)
        end
    end

    --7) 拆除标记
    for _, surface in pairs(game.surfaces) do
        for _, entity in ipairs(surface.find_entities_filtered({ to_be_deconstructed = true })) do
            apply_deconstruction(entity)
        end
    end

    --7.5) 地格拆除：被标记拆除的地格由 deconstructible-tile-proxy 代表，是否会被上面那句
    --      to_be_deconstructed 查询命中并不确定，故再显式枚举一次代理实体。
    --      apply_deconstruction 对代理是幂等的（只是覆盖同一个计数项），重复处理无害。
    for _, surface in pairs(game.surfaces) do
        for _, proxy in ipairs(surface.find_entities_filtered({ type = "deconstructible-tile-proxy" })) do
            apply_deconstruction(proxy)
        end
    end

    --8) IRP：重建目标容器上的计数项与快照
    for _, surface in pairs(game.surfaces) do
        for _, irp in ipairs(surface.find_entities_filtered({ type = "item-request-proxy" })) do
            if irp.valid and irp.unit_number then
                apply_irp(irp)
            end
        end
    end
end

---@param _ EventData.on_configuration_changed
local function on_configuration_changed(_)
    M.rebuild()
end

---@param _ EventData.on_load
local function on_load(_)
    --此处不能访问 game、也不能改 storage，只置标志
    needs_rebuild = true
end

---阵营是不是"有玩家的阵营"。
---只有有玩家的阵营才会有人架设读取器、才会有该被读取的物流网络；
---neutral（树/岩石/落地物品）与 enemy（虫巢）没有玩家，它们只需要落到别人的网络里。
---另外，空载的专用服务器（还没人进来过）里任何阵营都没有玩家，那种情况下
---退化成"非中立/敌方即视为玩家阵营"，否则归属地解析会在服务器上集体失效。
---@param force LuaForce
---@return boolean
local function is_player_force(force)
    if #force.players > 0 then return true end
    if #game.players == 0 then
        return force ~= game.forces.neutral and force ~= game.forces.enemy
    end
    return false
end

---实体所在位置覆盖它的物流网络。
---分两种情况：
---  * 实体属于有玩家的阵营：只可能在自家建设范围里被读取，直接查自己阵营（一次查询）；
---  * 实体属于没有玩家的阵营（树、岩石、落地物品属 neutral，虫巢属 enemy）：
---    它们自身阵营根本没有物流网络，只按自身阵营查会一个都取不到，于是网络模式下
---    永远看不到它们（表面模式按位置归属，不受影响），故改为遍历所有玩家阵营，
---    按位置找覆盖它们的建设范围。
---注意 force 参数是单个 ForceID（LuaForce / 阵营序号 / 阵营名），**不是 ForceSet**，
---传表会直接报 "Invalid ForceID: expected LuaForce, force index or string."，
---所以"一次查询覆盖所有阵营"做不到，只能按阵营逐个查（次数有界：阵营数）。
---@param entity LuaEntity
---@return LuaLogisticNetwork[]
local function logistic_networks_at(entity)
    local surface = entity.surface
    local position = entity.position
    local force = entity.force

    if is_player_force(force) then
        return surface.find_logistic_networks_by_construction_area(position, force)
    end

    local found = {}
    for _, other in pairs(game.forces) do
        if is_player_force(other) then
            for _, logistic_network in ipairs(surface.find_logistic_networks_by_construction_area(position, other)) do
                found[#found + 1] = logistic_network
            end
        end
    end
    return found
end

local function on_tick()
    --0) 读档后的首帧：注册表已随 control.lua 重跑清空，先做一次全量重建
    if needs_rebuild then
        needs_rebuild = false
        M.rebuild()
    end

    --快照触发计时实体归属地脏、计时实体计数脏（库存变化引发）
    snapshot.on_tick()

    --清理计时实体归属地(由实体移动引发)
    for ce, _ in pairs(changes.current.dirty_count_entities_region) do
        ---@type meta
        local e = ce
        if e:vaild() then
            --每个计数实体同时归属所在表面与所在物流网络（读取器按范围模式二选一）。
            --新旧归属地都是集合，逐个查表比对即可，不必再各自攒一张差集表
            --（原先用 get_unique_elements 会多建两张表，这里直接就地增删）。
            local old_regions = e.count_entity_regions
            local new_regions = {}
            for _, logistic_network in ipairs(logistic_networks_at(e.entity)) do
                new_regions[region.ensure_region_logistic_network(logistic_network)] = true
            end
            new_regions[region.ensure_region_surface(e.entity.surface)] = true

            -- 新增：新集合里有、旧集合里没有
            for r in pairs(new_regions) do
                if not (old_regions and old_regions[r]) then
                    e:add_to_region(r)
                end
            end
            -- 移除：旧集合里有、新集合里没有。
            -- remove_from_region 会把键从 count_entity_regions 里删掉（就是 old_regions 本身），
            -- Lua 允许在遍历中把已有键置 nil，故这里可以直接就地遍历。
            if old_regions then
                for r in pairs(old_regions) do
                    if not new_regions[r] then
                        e:remove_from_region(r)
                    end
                end
            end
        end
    end

    --计数从计时实体污染到归属地(计数脏由各类事件、库存变化引发)
    for ce, _ in pairs(changes.current.dirty_count_entities_output) do
        --尚未落到任何归属地的计数实体没有可污染的归属地
        if ce.count_entity_regions then
            for r, _ in pairs(ce.count_entity_regions) do
                changes.dirty_region_output(r)
            end
        end
    end

    --清理归属地计数
    for region, _ in pairs(changes.current.dirty_regions_output) do
        if region:vaild() then
            region:update_count()
            for reader, _ in pairs(region.readers) do
                changes.dirty_reader_output(reader)
            end
        end
    end

    --清理读取器归属地
    for reader, _ in pairs(changes.current.dirty_readers_region) do
        ---@type meta
        local r = reader
        if r:vaild() then
            r:reader_set_region(reader_region_of(r.entity))
            changes.dirty_reader_output(r)
        end
    end


    --清理读取器计数
    for reader, _ in pairs(changes.current.dirty_readers_output) do
        ---@type meta
        local r = reader
        r:write_outputs()
        gui.update_tooltip(r.entity)
    end

    --刷新已打开的面板（状态行与信号表随配置/归属地变化）
    gui.refresh_open()

    changes.clear()
end

---comment
---@param event EventData.on_object_destroyed
local function on_destroyed(event)
    local reg_num = event.registration_number
    region.remove_region(reg_num)
    meta.remove_meta(reg_num)
end
function M.register()
    script.on_event(defines.events.on_built_entity, on_built_entity)
    script.on_event(defines.events.on_robot_built_entity, on_built_entity)
    script.on_event(defines.events.script_raised_built, on_built_entity)
    script.on_event(defines.events.script_raised_revive, on_built_entity)


    script.on_event(defines.events.on_object_destroyed, on_destroyed)
    -- script.on_event(defines.events.on_player_mined_entity, on_mined_entity)
    -- script.on_event(defines.events.on_robot_mined_entity, on_mined_entity)
    script.on_event(defines.events.on_marked_for_deconstruction, on_deconstruction)
    script.on_event(defines.events.on_cancelled_deconstruction, on_cancel_deconstruction)
    script.on_event(defines.events.on_marked_for_upgrade, on_upgrade)
    script.on_event(defines.events.on_cancelled_upgrade, on_cancel_upgrade)
    -- script.on_event(defines.events.on_pre_ghost_upgraded, on_upgrade)
    script.on_event(defines.events.on_script_trigger_effect, on_irp_created)
    script.on_event(defines.events.on_tick, on_tick)

    script.on_event(defines.events.on_surface_created, on_surface_created)

    -- GUI：读取器配置面板
    script.on_event(defines.events.on_gui_opened, gui.on_gui_opened)
    script.on_event(defines.events.on_gui_closed, gui.on_gui_closed)
    script.on_event(defines.events.on_gui_click, gui.on_gui_click)
    script.on_event(defines.events.on_gui_selection_state_changed, gui.on_gui_selection_state_changed)

    -- bplib：蓝图 tags 配置持久化（bplib 是硬依赖，其自定义事件名必定已注册）
    script.on_event("bplib-extract", bplib.on_extract)
    script.on_event("bplib-positions", bplib.on_positions)
    script.on_event("bplib-overlaps", bplib.on_overlaps)
    if defines.events.on_player_setup_blueprint then
        script.on_event(defines.events.on_player_setup_blueprint, bplib.on_player_setup_blueprint)
    end

    -- 复制粘贴：隔离读取器与原版恒压器（同为 constant-combinator），
    -- 并支持读取器之间（含虚影）继承配置
    if defines.events.on_pre_entity_settings_pasted then
        script.on_event(defines.events.on_pre_entity_settings_pasted, paste.on_pre_settings_pasted)
    end
    if defines.events.on_entity_settings_pasted then
        script.on_event(defines.events.on_entity_settings_pasted, paste.on_settings_pasted)
    end

    -- 生命周期：读档（on_load 只置标志，首帧重建）与配置变化（直接重建）
    script.on_load(on_load)
    script.on_configuration_changed(on_configuration_changed)
end

return M
