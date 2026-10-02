local region = require("region")
local meta = require("meta")
local item = require("item")
local config = require("__ghost-reader__/dop2/config")
local changes = require("__ghost-reader__/dop2/changes")
local snapshot = require("__ghost-reader__/dop2/snapshot")
local gui = require("__ghost-reader__/dop2/gui")
local bplib = require("__ghost-reader__/dop2/bplib")

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
    m:set_count_item('ghost', change_type.ENTITY_SUPPLY, item.item_for_entity(e.ghost_name), e.quality, 1)
end

---@param e LuaEntity
local function on_tile_ghost_built(e)
    local m = meta.ensure_entity_meta(e)
    m:set_count_item('ghost', change_type.TILE_SUPPLY, item.item_for_tile(e.ghost_name), e.quality, 1)
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
        meta.ensure_robotport_meta(e)
    end
end

---@param event EventData.on_surface_created
local function on_surface_created(event)
    local r = region.ensure_region_surface(game.surfaces[event.surface_index])
end

---@param event EventData.on_surface_deleted
local function on_surface_deleted(event)
    local r = region.ensure_region_surface(game.surfaces[event.surface_index])
    region.remove_region(r.reg_num)
end

---@param event EventData.on_marked_for_deconstruction
local function on_deconstruction(event)
    local m = meta.ensure_entity_meta(event.entity)
    m:set_count_item('deconstruction',
        change_type.ENTITY_RECYCLE,
        item.item_for_entity(m.entity.name),
        m.entity.quality,
        1)
    --实体携带的物品（库存/传送带货物/机械臂手持物/挖掘产物）逐个记为物品类别回收
    for recycle_item, quality_counts in pairs(item.recycle_entity_contents(m.entity)) do
        for quality, count in pairs(quality_counts) do
            m:set_count_item('deconstruction', change_type.ITEM_RECYCLE, recycle_item, quality, count)
        end
    end
    if item.is_movable(m.entity) then
        m:register_movable()
    end
    if item.has_inventory(m.entity) then
        m:register_inventory()
    end
end
---@param event EventData.on_cancelled_deconstruction
local function on_cancel_deconstruction(event)
    local m = meta.ensure_entity_meta(event.entity)
    m:remove_count_item('deconstruction')
    if m.movable > 0 then
        m:unregister_movable()
    end
    if m.inventory > 0 then
        m:unregister_inventory()
    end
    -- set_count_item(m, 'self', change_type.ENTITY_RECYCLE, item.item_for_entity(event.entity.name), 0)
end

---@param event EventData.on_marked_for_upgrade
local function on_upgrade(event)
    local m = meta.ensure_entity_meta(event.entity)
    m:set_count_item('upgrade', change_type.UPGRADE_SUPPLY, item.item_for_entity(event.target.name), event.entity
    .quality, 1)
    m:set_count_item('upgrade', change_type.UPGRADE_RECYCLE, item.item_for_entity(event.previous_target.name),
        event.entity.quality, 1)
end

---@param event EventData.on_cancelled_upgrade
local function on_cancel_upgrade(event)
    local m = meta.ensure_entity_meta(event.entity)
    m:remove_count_item('upgrade')
end


---@param event EventData.on_script_trigger_effect
local function on_irp_created(event)
    if event.effect_id ~= "gr-item-request-proxy" then return end
    local e = event.source_entity
    if e and e.valid and e.type == "item-request-proxy" then
        local irp_meta = meta.ensure_entity_meta(e)

        local target = e.proxy_target --请求容器实体

        if target and target.valid then
            local m = meta.ensure_entity_meta(target)
            irp_meta.proxy_target = m
            local count_item_name = 'irp' .. tostring(irp_meta.reg_num)
            for item_prototype, quality_counts in pairs(item.irp_requests(e)) do
                for quality, count in pairs(quality_counts) do
                    m:set_count_item(count_item_name, change_type.ITEM_SUPPLY, item_prototype, quality, count)
                end
            end
            for item_prototype, quality_counts in pairs(item.irp_removals(e)) do
                for quality, count in pairs(quality_counts) do
                    m:set_count_item(count_item_name, change_type.ITEM_RECYCLE, item_prototype, quality, count)
                end
            end
            if item.is_movable(m.entity) then
                m:register_movable()
            end
        end
    end
end


local function on_tick()
    --快照触发计时实体归属地脏、计时实体计数脏（库存变化引发）
    snapshot.on_tick()

    --清理计时实体归属地(由实体移动引发)
    for ce, _ in pairs(changes.current.dirty_count_entities_region) do
        ---@type meta
        local e = ce
        if e:vaild() then
            --每个计数实体同时归属所在表面与所在物流网络（读取器按范围模式二选一）。
            --新旧归属地都用集合，比对时只做哈希查表。
            local new_regions = {}
            local logistic_networks = e.entity.surface.find_logistic_networks_by_construction_area(e.entity.position,
                e.entity.force)
            for _, logistic_network in ipairs(logistic_networks) do
                new_regions[region.ensure_region_logistic_network(logistic_network)] = true
            end
            new_regions[region.ensure_region_surface(e.entity.surface)] = true

            --count_entity_regions 本身就是集合，比对结果也是集合；为 nil 时视为空集合
            local add, remove = get_unique_elements(new_regions, e.count_entity_regions)
            for ar in pairs(add) do
                e:add_to_region(ar)
            end
            for rr in pairs(remove) do
                e:remove_from_region(rr)
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
    ---需要处理
    -- local m = meta.get_meta(event.registration_number)
    meta.remove_meta(event.registration_number)
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
    script.on_event(defines.events.on_surface_deleted, on_surface_deleted)

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
end

return M
