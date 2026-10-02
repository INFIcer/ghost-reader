local changes = require("__ghost-reader__/dop2/changes")
local config = require('__ghost-reader__/dop2/config')
local snapshot = require("__ghost-reader__/dop2/snapshot")

--================================================================================================

---@type table<uint64,meta>
local objects_meta = {}

---@class count_item
local count_item = {}
function count_item:new()
    local obj = {}
    setmetatable(obj, { __index = self })
    return obj
end

---设置计数
---@param kind change_type
---@param item LuaItemPrototype
---@param quality? LuaQualityPrototype
---@param count int
function count_item:set(kind, item, quality, count)
    if not self[kind] then self[kind] = {} end
    if not self[kind][item] then self[kind][item] = {} end
    self[kind][item][ensure_quality(quality)] = count
end

---读取计数
---@param kind change_type
---@param item LuaItemPrototype
---@param quality? LuaQualityPrototype
---@return int count
function count_item:read(kind, item, quality)
    return self[kind][item][ensure_quality(quality)]
end

--================================================================================================

---@class meta
---@field reg_num uint64 注册号
---@field entity LuaEntity 注册实体
---@field movable int 可移动注册次数，仅在可移动的计数实体上使用
---@field tilepos_snapshot snapshot|nil 位置快照，仅在可移动的计数实体上使用
---@field inventory int 库存注册次数，仅在有内部库存的计数实体上使用
---@field inventory_snapshot snapshot|nil 库存快照，仅在有内部库存的计数实体上使用
---@field count_items table<string,count_item> 计数项，仅在计数实体上可访问
---@field proxy_target meta 请求容器实体的元数据，仅在IRP上可访问
---@field reader_region region 读取器所在归属地，仅在读取器上可访问
---@field count_entity_regions table<region> 计数实体所在归属地，仅在计数实体上可访问
local meta = {}

---@param reg_num uint64 注册号
---@param entity LuaEntity 注册实体
function meta:new(reg_num, entity)
    local obj = {
        reg_num = reg_num,
        entity = entity,
        movable = 0,
        inventory = 0,
    }
    setmetatable(obj, { __index = self })
    return obj
end

---增添一个计数项
---@param name string 计数项的id
---@return count_item 计数项
function meta:get_count_item(name)
    if not self.count_items then self.count_items = {} end
    local obj = self.count_items[name]
    if not obj then
        obj = count_item:new()
        self.count_items[name] = obj
    end
    return obj
end

---设置一个计数项
---@param count_item_name string
---@param kind change_type
---@param item? LuaItemPrototype
---@param quality? LuaQualityPrototype
---@param count int
function meta:set_count_item(count_item_name, kind, item, quality, count)
    local count_item = self:get_count_item(count_item_name)
    if item then
        count_item:set(kind, item, ensure_quality(quality), count)
        self:mark_dirty()
    end
end

---删除一个计数项
---@param name string 计数项的id
function meta:remove_count_item(name)
    self.count_items[name] = nil
    self:mark_dirty()
end

---删除所有计数项
function meta:clear_count_item()
    self.count_items = nil
    self:mark_dirty()
end

---注册可移动
function meta:register_movable()
    if self.movable == 0 then
        self.tilepos_snapshot = snapshot.add_tilepos_snapshot(self.entity)
    end
    self.movable = self.movable + 1
end

---取消注册可移动
function meta:unregister_movable()
    self.movable = self.movable - 1
    if self.movable == 0 then
        snapshot.remove_snapshot(self.tilepos_snapshot)
    end
end

---注册库存检测
function meta:register_inventory()
    if self.inventory == 0 then
        self.inventory_snapshot = snapshot.add_inventory_snapshot(self.entity)
    end
    self.inventory = self.inventory + 1
end

---取消注册库存检测
function meta:unregister_inventory()
    self.inventory = self.inventory - 1
    if self.inventory == 0 then
        snapshot.remove_snapshot(self.inventory_snapshot)
    end
end

---标记脏数据
function meta:mark_dirty()
    changes.dirty_count_entitiy_output(self)
end

---读取器重写信号输出
function meta:write_outputs()
    local uint = self.entity.unit_number
    ---@type LuaConstantCombinatorControlBehavior
    local cb = self.entity.get_or_create_control_behavior()
    local section = cb.get_section(1)
    if not section then section = cb.add_section("") end
    if not section then return end
    section.filters = {}

    ---@type table<LuaItemPrototype ,table<LuaQualityPrototype ,int>>
    local out = {}
    for kind, t1 in pairs(self.reader_region.count) do
        local filter = config.get_filter(uint)
        local count = config.get_count(uint)
        if match(kind, filter, count) then
            local negtive = count == count_mode.NET and match_count(kind, count_mode.RECYCLE)
            for item, t2 in pairs(t1) do
                for quality, count in pairs(t2) do
                    if match_quality(quality.name, config.get_quality(uint)) then
                        if not out[item] then out[item] = {} end
                        if negtive then
                            out[item][quality] = (out[item][quality] or 0) - count
                        else
                            out[item][quality] = (out[item][quality] or 0) + count
                        end
                    end
                end
            end
        end
    end

    local i = 0
    for item, t1 in pairs(out) do
        for quality, count in pairs(t1) do
            i = i + 1
            section.set_slot(i, { value = { type = 'item', name = item.name, quality = quality }, min = count })
        end
    end
end

---@return boolean
function meta:vaild()
    return self.entity and self.entity.valid
end

---为读取器设置归属地
---@param region? region
function meta:reader_set_region(region)
    if self.reader_region == region then
        return
    end
    if self.reader_region then
        self.reader_region:remove_reader(self)
        self.reader_region = nil
    end
    if region then
        self.reader_region = region
        region:add_reader(self)
    end
end

---为计数实体添加归属地
---@param region region
function meta:add_to_region(region)
    if not self.count_entity_regions then self.count_entity_regions = {} end
    table.insert(self.count_entity_regions, region)
    region:add_count_entity(self)
end

---为计数实体移除归属地
---@param region region
function meta:remove_from_region(region)
    remove(self.count_entity_regions, region)
    region:remove_count_entity(self)
end

---为计数实体移除所有归属地
function meta:clear_regions()
    for _, region in ipairs(self.count_entity_regions) do
        region:remove_count_entity(self)
    end
    self.count_entity_regions = nil
end

function meta:on_destroyed()
    --IRP清理
    if self.proxy_target then
        self.proxy_target:remove_count_item('irp' .. tostring(self.reg_num))
        changes.dirty_count_entitiy_output(self.proxy_target)
        if self.proxy_target.movable > 0 then
            self.proxy_target:unregister_movable()
        end
    end

    --计数实体清理
    self:clear_count_item()
    self:clear_regions()
    if self.tilepos_snapshot then
        snapshot.remove_snapshot(self.tilepos_snapshot)
    end
    if self.inventory_snapshot then
        snapshot.remove_snapshot(self.inventory_snapshot)
    end

    --读取器清理
    self:reader_set_region(nil)
end

--================================================================================================

---模块对外暴露部分
local M = {}


---注册对象的元信息，元数据中保留了实体摧毁后要访问的数据。
---因为on_object_destroyed响应时不带实体数据（已完成销毁），所以才不得不这样实现。
---@return meta register_meta 注册的元信息
---@param entity LuaEntity 要进行注册的实体（关注实体的摧毁事件）
function M.ensure_entity_meta(entity)
    local reg_num = script.register_on_object_destroyed(entity)
    local m = objects_meta[reg_num]
    if m == nil then
        m = meta:new(reg_num, entity)
        changes.dirty_count_entitiy_region(m)
    end
    return m
end

---@return meta register_meta 注册的元信息
---@param entity LuaEntity 要进行注册的实体（关注实体的摧毁事件）
function M.ensure_reader_meta(entity)
    local reg_num = script.register_on_object_destroyed(entity)
    local m = objects_meta[reg_num]
    if m == nil then
        m = meta:new(reg_num, entity)
        changes.dirty_reader_region(m)
    end
    return m
end

---@param reg_num uint64 注册号
---@return meta register_meta
function M.get_meta(reg_num)
    return objects_meta[reg_num]
end

---@param reg_num uint64 注册号
function M.remove_meta(reg_num)
    objects_meta[reg_num]:on_destroyed()
    objects_meta[reg_num] = nil
end

return M
