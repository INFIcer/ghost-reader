---确保品质不为空
---@param quality? LuaQualityPrototype
---@return LuaQualityPrototype
function ensure_quality(quality)
    if not quality then
        quality = prototypes.quality["normal"]
    end
    return quality
end

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
---@field entity LuaEntity
---@field last_position TilePosition
---@field count_items table<string,count_item>
---@field on_destroyed function
local meta = {}
---@param reg_num uint64 注册号
---@param entity LuaEntity 注册实体
function meta:new(reg_num, entity)
    local obj = { reg_num = reg_num, entity = entity }
    setmetatable(obj, { __index = self })
    return obj
end

---增添一个计数项
---@param name string 计数项的id
---@return count_item 计数项
function meta:get_count_item(name)
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
    local pos = self.entity.position
    local tile_x = math.floor(pos.x)
    local tile_y = math.floor(pos.y)
    self.last_position = { tile_x, tile_y }
    self.movable = self.movable + 1
end

---取消注册可移动
function meta:unregister_movable()
    self.movable = self.movable - 1
end

---检查移动
---@return boolean
function meta:check_move()
    local pos = self.entity.position
    local tile_x = math.floor(pos.x)
    local tile_y = math.floor(pos.y)
    local new_position = { tile_x, tile_y }
    if new_position[1] ~= self.last_position[1] or new_position[2] ~= self.last_position[2] then
        return true
    end
    return false
end

---标记脏数据
function meta:mark_dirty()
    self.dirty = true
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
    objects_meta[reg_num] = nil
end

return M
