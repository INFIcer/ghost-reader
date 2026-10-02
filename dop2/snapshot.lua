local meta = require("meta")
local changes = require("__ghost-reader__/dop2/changes")

local active_unchecked = {}
local active_checked = {}
local inactive_unchecked = {}
local inactive_checked = {}

---@class snapshot
---@field entity LuaEntity
---@field update_mod function
---@field snaps string
---@field checks int
local snapshot = {}


---@param inventory LuaInventory
---@return string
local function generate_inventory_snapshot(inventory)
    local parts = {}
    for _, c in ipairs(inventory.get_contents()) do
        table.insert(parts, tostring(c.name) .. "-" .. tostring(c.quality) .. "=" .. tostring(c.count))
    end
    table.sort(parts)
    return table.concat(parts, ";")
end

---@param position MapPosition
---@return string
local function generate_tilepos_snapshot(position)
    local tile_x = math.floor(position.x)
    local tile_y = math.floor(position.y)
    return tostring(tile_x) .. "," .. tostring(tile_y)
end

---@param entity LuaEntity
local function update_inventories(entity)
    local parts = {}
    for inv_index in 1, entity.get_max_inventory_index() do
        local tinv = entity.get_inventory(inv_index)
        if tinv then
            table.insert(parts, generate_inventory_snapshot(tinv))
        end
    end
    return table.concat(parts, "\n")
end

---@param entity LuaEntity
local function update_pos(entity)
    return generate_tilepos_snapshot(entity.position)
end

---comment
---@param snapshot snapshot
local function check(snapshot)
    if snapshot.entity and snapshot.entity.valid then
        local new = snapshot.update_mod(snapshot.entity)
        if snapshot.snaps ~= new then
            snapshot.snaps = new
            if snapshot.update_mod == update_inventories then
                --库存变化 引发计数脏
                changes.dirty_count_entitiy_output(meta.ensure_entity_meta(snapshot.entity))
            else
                --位移 引发归属地脏
                changes.dirty_count_entitiy_region(meta.ensure_entity_meta(snapshot.entity))
            end
        else
            snapshot.checks = snapshot.checks + 1
        end
    end
end

---@param entity LuaEntity
function snapshot:new(entity, update_mod)
    local obj = {}
    obj.entity = entity
    obj.update_mod = update_mod
    obj.snaps = update_mod(entity)
    obj.checks = 0
    setmetatable(obj, { __index = self })
    return obj
end

max_check = 8
inactive_times = 30
function on_tick()
    local i = 0
    local swap = false
    while i < max_check do
        if #active_unchecked == 0 then
            if #active_checked == 0 or swap then
                break
            elseif not swap then
                active_checked, active_unchecked = active_unchecked, active_checked
                swap = true
            end
        end
        ss = table.remove(active_unchecked, 1)
        check(ss)
        if ss.checks >= inactive_times then
            table.insert(inactive_checked, ss)
        else
            table.insert(active_checked, ss)
        end
        i = i + 1
    end
    swap = false
    while i < max_check do
        if #inactive_unchecked == 0 then
            if #inactive_checked == 0 or swap then
                break
            elseif not swap then
                inactive_checked, inactive_unchecked = inactive_unchecked, inactive_checked
                swap = true
            end
        end
        ss = table.remove(inactive_unchecked, 1)
        check(ss)
        if ss.checks == 0 then
            table.insert(active_checked, ss)
        else
            table.insert(inactive_checked, ss)
        end
        i = i + 1
    end
end

local M = {}

---comment
---@param entity LuaEntity
---@return snapshot
function M.add_inventory_snapshot(entity)
    local ss = snapshot:new(entity, update_inventories)
    table.insert(active_unchecked, ss)
    return ss
end

---@param entity LuaEntity
---@return snapshot
function M.add_tilepos_snapshot(entity)
    local ss = snapshot:new(entity, update_pos)
    table.insert(active_unchecked, ss)
    return ss
end

---comment
---@param list table<snapshot>
---@param entity LuaEntity
local function remove_snapshot_in_list(list, entity)
    for i = #list, 1, -1 do
        if list[i].entity == entity then
            table.remove(list, i)
        end
    end
end

---@param snapshot snapshot
function M.remove_snapshot(snapshot)
    remove(active_unchecked, snapshot)
    remove(active_checked, snapshot)
    remove(inactive_unchecked, snapshot)
    remove(inactive_checked, snapshot)
end

---@param entity LuaEntity
function M.remove_snapshots(entity)
    remove_snapshot_in_list(active_unchecked, entity)
    remove_snapshot_in_list(active_checked, entity)
    remove_snapshot_in_list(inactive_unchecked, entity)
    remove_snapshot_in_list(inactive_checked, entity)
end

M.on_tick = on_tick
return M
