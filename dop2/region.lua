local changes = require("__ghost-reader__/dop2/changes")
local count_item = require("__ghost-reader__/dop2/count_item")
---@type table<uint64,region>
local regions = {}


---@class region
---@field reg_num uint64
---@field surface LuaSurface
---@field logistic_network LuaLogisticNetwork
---@field readers table<meta,any>
---@field count_entities table<meta,any>
---@field count count_item 归属地内所有计数实体合并后的计数
---@field outputs table<string,counter>|nil 按过滤器组合缓存的读取结果（见 meta.read_region_output）
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
        outputs = nil,
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
        outputs = nil,
    }
    setmetatable(obj, { __index = self })
    return obj
end

---获取表面的显示名称（行星用原型名，太空平台/普通表面用其名字）
---@param surface LuaSurface
---@return LocalisedString
local function surface_name(surface)
    if surface.planet then
        return { "", "[img=space-location." .. surface.planet.name .. "] ", surface.planet.prototype
            .localised_name }
    end
    if surface.platform then
        return { "",
            "[img=surface.space-platform] " ..
            surface.platform.name }
    end
    return { "", surface.name }
end

---获取名称
---@return LocalisedString
function region:name()
    if self.surface then
        return surface_name(self.surface)
    else
        local icon = "[img=item.roboport] "
        if self.logistic_network.custom_name then return { "", icon, self.logistic_network.custom_name } end
        return { "", icon, { "gr-gui.network-prefix" }, tostring(self.logistic_network.network_id) }
    end
end

---更新计数：把所有计数实体的计数项合并成一个计数项
function region:update_count()
    ---@type count_item
    local count = count_item.create()
    for meta, _ in pairs(self.count_entities) do
        local count_items = meta.count_items
        if count_items then
            --实体本身已被标记拆除时，它在目标容器上留下的 IRP 计数项要跳过
            --（拆除后请求已作废，留着会与实体回收重复计）
            local deconstruction_mark = count_items[COUNT_DECON_INVENTORY]
            for name, item_count in pairs(count_items) do
                if deconstruction_mark and has_prefix(name, COUNT_IRP_PREFIX) then
                    --有销毁标志时跳过irp统计
                else
                    for kind, item_counts in pairs(item_count) do
                        for item, quality_counts in pairs(item_counts) do
                            for quality, n in pairs(quality_counts) do
                                count:add(kind, item, quality, n)
                            end
                        end
                    end
                end
            end
        end
    end
    self.count = count
    --计数变了，之前按过滤器组合缓存的读取结果全部作废
    self.outputs = nil
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
        --因为可能出现合并的情况，所以也可能立刻落入新的网络中。使用标脏属地
        changes.dirty_reader_region(reader)
    end
    for ce, _ in pairs(self.count_entities) do
        --因为可能出现合并的情况，所以也可能立刻落入新的网络中。使用标脏属地
        changes.dirty_count_entitiy_region(ce)
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
        regions[reg_num] = m
    end
    return m
end

function M.ensure_region_logistic_network(logistic_network)
    local reg_num = script.register_on_object_destroyed(logistic_network)
    local m = regions[reg_num]
    if m == nil then
        m = region:new_logistic_network(reg_num, logistic_network)
        regions[reg_num] = m
    end
    return m
end

---@param reg_num uint64 归属地的注册号
---@return boolean 是否确实回收了一个归属地
function M.remove_region(reg_num)
    local r = regions[reg_num]
    if not r then return false end
    r:on_destroyed()
    regions[reg_num] = nil
    return true
end

---清空归属地注册表（全量重建时用）。归属地由引擎对象派生，会随世界状态重新登记。
function M.reset()
    regions = {}
end

M.surface_name = surface_name

return M
