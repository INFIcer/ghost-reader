local region = require("region")
local meta = require("meta")
local item = require("item")
local changes = require("__ghost-reader__/dop2/changes")
local snapshot = require("__ghost-reader__/dop2/snapshot")

local M = {}

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
    elseif e.type == "tile-ghost" then
        on_tile_ghost_built(e)
    elseif e.name == READER then
        meta.ensure_reader_meta(e)
    elseif e.name == "robotport" then
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
    item.recycle_entity_contents(m.entity)
    for name, count in pairs(recycle) do
        m:set_count_item('deconstruction', change_type.ITEM_RECYCLE, prototypes.item[name], count)
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
    m:set_count_item('upgrade', change_type.UPGRADE_SUPPLY, event.target, 1)
    m:set_count_item('upgrade', change_type.UPGRADE_RECYCLE, event.previous_target, 1)
end

---@param event EventData.on_cancelled_upgrade
local function on_cancel_upgrade(event)
    local m = meta.on_cancel_upgrade(event.entity)
    m:remove_count_item('upgrade')
end


-- 提取 IRP 的请求明细（供给）：{ [i] = {name, count}, ... }（数组）
---comment
---@param irp LuaEntity
---@return table<string,table<string,int>>
local function irp_requests(irp)
    local reqs = irp and irp.item_requests
    if not reqs then error("Can only be used if this is ItemRequestProxy") end
    ---@type table<string,table<string,int>>
    local out = {}
    for _, r in pairs(reqs) do
        if r and r.name then
            if not out[r.name] then out[r.name] = {} end
            out[r.name][r.quality] = r.count
        end
    end
    return out
end
-- 提取 IRP 的回收明细：{ [i] = {name, count}, ... }（数组）。
-- 回收来自 removal_plan：每个 plan 命名一个物品，数量 = 代理目标容器内该物品当前库存。
-- 与原版一致：库存为 0 时按 1 计（该物品确实在回收计划中）。
---comment
---@param irp LuaEntity
---@return table<string,table<string,int>>
local function irp_removals(irp)
    local removal = irp and irp.removal_plan
    if not removal then error("Can only be used if this is ItemRequestProxy") end
    ---@type table<string,table<string,int>>
    local out = {}
    for _, r in pairs(removal) do
        if not out[r.id.name] then out[r.id.name] = {} end
        for _, pos in ipairs(r.items.in_inventory) do
            out[r.id.name][r.id.quality] = pos.count or 1
        end
    end
    return out
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
            for name, t in pairs(irp_requests(e)) do
                for quality, count in pairs(t) do
                    m:set_count_item('irp' .. tostring(irp_meta.reg_num),
                        change_type.ITEM_SUPPLY,
                        prototypes.item[name],
                        prototypes.quality[quality],
                        count)
                end
            end
            for name, t in pairs(irp_removals(e)) do
                for quality, count in pairs(t) do
                    m:set_count_item('irp' .. tostring(irp_meta.reg_num),
                        change_type.ITEM_RECYCLE,
                        prototypes.item[name],
                        prototypes.quality[quality],
                        count)
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
            local new_regions = {}
            local logistic_networks = e.entity.surface.find_logistic_networks_by_construction_area(e.entity.position,
                e.entity.force)
            for _, logistic_network in ipairs(logistic_networks) do
                table.insert(new_regions, region.ensure_region_logistic_network(logistic_network))
            end
            local surface = e.entity.surface.find_logistic_networks_by_construction_area(e.entity.position,
                e.entity.force)
            table.insert(new_regions, region.ensure_region_surface(surface))

            local add, remove = get_unique_elements(new_regions, e.count_entity_regions)

            for _, ar in ipairs(add) do
                e:add_to_region(ar)
            end
            for _, rr in ipairs(remove) do
                e:remove_from_region(rr)
            end
        end
    end

    --计数从计时实体污染到归属地(计数脏由各类事件、库存变化引发)
    for ce, _ in pairs(changes.current.dirty_count_entities_output) do
        for _, r in ipairs(ce.count_entity_regions) do
            changes.dirty_region_output(r)
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
            local logistic_network = r.entity.surface.find_logistic_network_by_position(r.entity.position, r.entity
                .force)
            r:reader_set_region(region.ensure_region_logistic_network(logistic_network))
            changes.dirty_reader_output(r)
        end
    end


    --清理读取器计数
    for reader, _ in pairs(changes.dirty_readers_output) do
        ---@type meta
        local r = reader
        r:write_outputs()
    end


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
end

return M
