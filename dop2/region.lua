local changes = require("__ghost-reader__/dop2/changes")
---@type table<uint64,region>
local regions = {}


---@class region
---@field reg_num uint64
---@field surface LuaSurface
---@field logistic_network LuaLogisticNetwork
---@field readers table<meta,any>
---@field count_entities table<meta,any>
---@field count table<change_type,table<LuaItemPrototype,table<LuaQualityPrototype,int>>>
local region = {}


---创建表面归属地
---@param surface LuaSurface
---@return region
function region:new_surface(reg_num, surface)
    local obj = {
        reg_num = reg_num,
        surface = surface,
        logistic_network = nil,
        readers = {},
        count_entities = {},
        count = nil,
    }
    setmetatable(obj, { __index = self })
    return obj
end

---创建物流网络归属地
---@param logistic_network LuaLogisticNetwork
---@return region
function region:new_logistic_network(reg_num, logistic_network)
    local obj = {
        reg_num = reg_num,
        surface = nil,
        logistic_network = logistic_network,
        readers = {},
        count_entities = {},
        count = nil,
    }
    setmetatable(obj, { __index = self })
    return obj
end

---获取名称
---@return LocalisedString
function region:name()
    if self.surface then
        if self.surface.planet then return self.surface.planet.prototype.localised_name end
        if self.surface.platform then return { "", self.surface.platform.name } end
        return { "", self.surface.name }
    else
        if self.logistic_network.custom_name then return { "", self.logistic_network.custom_name } end
        return { "", { "gr-gui.network-prefix" }, tostring(self.logistic_network.network_id) }
    end
end

---更新计数
function region:update_count()
    self.count = {}
    for meta, _ in pairs(self.count_entities) do
        local deconstruction_mark = meta.count_items.deconstruction
        for name, count_table in pairs(meta.count_items) do
            if deconstruction_mark and has_prefix(name, 'irp') then
                --有销毁标志时跳过irp统计
            else
                for kind, t1 in pairs(count_table) do
                    if not self.count[kind] then self.count[kind] = {} end
                    for item, t2 in pairs(t1) do
                        if not self.count[kind][item] then self.count[kind][item] = {} end
                        for quality, count in pairs(t2) do
                            self.count[kind][item][quality] = (self.count[kind][item][quality] or 0) + count
                        end
                    end
                end
            end
        end
    end
end

---添加读取器元数据
---@param reader meta
function region:add_reader(reader)
    self.readers[reader] = true
end

---移除读取器元数据
---@param reader meta
function region:remove_reader(reader)
    self.readers[reader] = nil
end

---添加计数实体元数据
---@param entity meta
function region:add_count_entity(entity)
    self.count_entities[entity] = true
    changes.dirty_region_output(self)
end

---移除计数实体元数据
---@param entity meta
function region:remove_count_entity(entity)
    self.count_entities[entity] = nil
    changes.dirty_region_output(self)
end

function region:vaild()
    if self.surface then
        return self.surface.valid
    end
    if self.logistic_network then
        return self.logistic_network.valid
    end
    error("归属地需要使用表面或物流网路进行初始化")
end

function region:on_destroyed()
    for reader, _ in pairs(self.readers) do
        reader:reader_set_region(nil)
    end
    for ce, _ in pairs(self.count_entities) do
        ce:remove_from_region(self)
    end
end

--===================================================================
---模块对外暴露部分
local M = {}

function M.ensure_region_surface(surface)
    local reg_num = script.register_on_object_destroyed(surface)
    local m = regions[reg_num]
    if m == nil then
        m = region:new_surface(reg_num, surface)
    end
    return m
end

function M.ensure_region_logistic_network(logistic_network)
    local reg_num = script.register_on_object_destroyed(logistic_network)
    local m = regions[reg_num]
    if m == nil then
        m = region:new_logistic_network(reg_num, logistic_network)
    end
    return m
end

function M.remove_region(reg_num)
    regions[reg_num]:on_destroyed()
    regions[reg_num] = nil
end

return M
