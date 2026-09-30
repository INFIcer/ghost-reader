local meta = require("meta")
local item = require("item")
local M = {}


local changes = {
    reader_added = {}
}




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

---@type string
READER = "ghost-reader"

---@param event EventData.on_built_entity
local function on_built_entity(event)
    local e = event.entity
    if e.type == "entity-ghost" then
        on_entity_ghost_built(e)
    elseif e.type == "tile-ghost" then
        on_tile_ghost_built(e)
    elseif e.name == READER then
        changes.reader_added.add(e)
    end
end


---@param event EventData.on_marked_for_deconstruction
local function on_deconstruction(event)
    local m = meta.ensure_entity_meta(event.entity)
    local recycle = {}
    item.recycle_entity_contents(event.entity, true, false, recycle)
    for name, count in pairs(recycle) do
        m:set_count_item('deconstruction', change_type.ENTITY_RECYCLE, item.item_for_entity(name), count)
    end
    recycle = {}
    item.recycle_entity_contents(event.entity, false, true, recycle)
    for name, count in pairs(recycle) do
        m:set_count_item('deconstruction', change_type.ITEM_RECYCLE, prototypes.item[name], count)
    end
end
---@param event EventData.on_cancelled_deconstruction
local function on_cancel_deconstruction(event)
    local m = meta.ensure_entity_meta(event.entity)
    m:remove_count_item('deconstruction')
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


            local function on_irp_destroyed()
                m:remove_count_item('irp')
            end

            irp_meta.on_destroyed = on_irp_destroyed
            for name, t in pairs(irp_requests(e)) do
                for quality, count in pairs(t) do
                    m:set_count_item('irp',
                        change_type.ITEM_SUPPLY,
                        prototypes.item[name],
                        prototypes.quality[quality],
                        count)
                end
            end
            for name, t in pairs(irp_removals(e)) do
                for quality, count in pairs(t) do
                    m:set_count_item('irp',
                        change_type.ITEM_RECYCLE,
                        prototypes.item[name],
                        prototypes.quality[quality],
                        count)
                end
            end
        end
    end
end

---comment
---@param event EventData.on_object_destroyed
local function on_destroyed(event)
    ---需要处理
    local m = meta.get_meta(event.registration_number)
    if m.on_destroyed then
        m.on_destroyed()
    end


    m:clear_count_item()
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
    script.on_event(defines.events.on_pre_ghost_upgraded, on_upgrade)
    script.on_event(defines.events.on_script_trigger_effect, on_irp_created)
end

M.changes = changes
return M
