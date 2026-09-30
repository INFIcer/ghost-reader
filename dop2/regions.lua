---@class regions
---@field surface LuaSurface
---@field logistic_network LuaLogisticNetwork
---@field readers table<LuaEntity>
---@field count_entities table<LuaEntity>
local regions = {}


---创建表面归属地
---@param surface LuaSurface
function regions:new_surface(surface)
    local obj = { surface = surface }
    setmetatable(obj, { __index = self })
    return obj
end

---创建物流网络归属地
---@param logistic_network LuaLogisticNetwork
function regions:new_logistic_network(logistic_network)
    local obj = { logistic_network = logistic_network }
    setmetatable(obj, { __index = self })
    return obj
end

---获取名称
---@return LocalisedString
function regions:name()
    if self.surface then
        if self.surface.planet then return self.surface.planet.prototype.localised_name end
        if self.surface.platform then return { "", self.surface.platform.name } end
        return { "", self.surface.name }
    else
        if self.logistic_network.custom_name then return { "", self.logistic_network.custom_name } end
        return { "", { "gr-gui.network-prefix" }, tostring(self.logistic_network.network_id) }
    end
end

---添加读取器
---@param reader LuaEntity
function regions:add_reader(reader)
    table.insert(self.readers, reader)
end

---添加计数实体
---@param entity LuaEntity
function regions:add_count_entity(entity)
    table.insert(self.count_entities, entity) 
end
