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

---把一次计数增量写进归属地计数。
---不通知读取器、也不作废输出缓存：成员整份增减时由调用方批量处理一次即可。
---归属地计数是增量维护的，所以 count 里不允许留下 0 值项：否则过滤时会把
---数量为 0 的信号也写进电路（旧实现整份重算，天然不会留下 0）。
---@param kind change_type
---@param item string 物品名
---@param quality string 品质名
---@param count int 增量（正负均可）
function region:apply_count(kind, item, quality, count)
    if count == 0 then return end
    local total = self.count
    if not total then
        total = count_item.create()
        self.count = total
    end
    local item_counts = total:counter_of(kind)
    local quality_counts = item_counts:row(item)
    local value = (quality_counts[quality] or 0) + count
    if value == 0 then
        quality_counts[quality] = nil
        --整行都空了就连物品行一起摘掉，让计数表只保留真实存在的项
        if next(quality_counts) == nil then item_counts[item] = nil end
    else
        quality_counts[quality] = value
    end
end

---归属地计数变了：作废按过滤器组合缓存的读取结果，并让归属地内所有读取器重写输出
function region:invalidate_outputs()
    self.outputs = nil
    for reader, _ in pairs(self.readers) do
        --读取器可能已经失效（标脏与处理之间被拆掉）：这里照样登记，
        --由帧末的读取器计数清理统一摘除元信息（见 events.on_tick）。
        changes.dirty_reader_output(reader)
    end
end

---把一次计数变化增量写入归属地，并通知归属地内的读取器
---@param kind change_type
---@param item string 物品名
---@param quality string 品质名
---@param count int 增量（正负均可）
function region:add_count(kind, item, quality, count)
    if count == 0 then return end
    self:apply_count(kind, item, quality, count)
    self:invalidate_outputs()
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

---添加计数实体元数据：把这个实体的全部有效计数计入本归属地
---@param entity meta
function region:add_count_entity(entity)
    --幂等：同一实体重复登记不能重复计入
    if self.count_entities[entity] then return end
    self.count_entities[entity] = true
    entity:contribute_counts(self, 1)
    self:invalidate_outputs()
end

---移除计数实体元数据：把这个实体的全部有效计数移出本归属地
---@param entity meta
function region:remove_count_entity(entity)
    --幂等：不在表里的实体不能重复扣减
    if not self.count_entities[entity] then return end
    self.count_entities[entity] = nil
    entity:contribute_counts(self, -1)
    self:invalidate_outputs()
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
