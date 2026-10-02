local changes = require("__ghost-reader__/dop2/changes")
local config = require('__ghost-reader__/dop2/config')
local region = require("__ghost-reader__/dop2/region")
local counter = require("__ghost-reader__/dop2/counter")
local count_item = require("__ghost-reader__/dop2/count_item")

---snapshot 模块，由入口注入（见 M.inject_snapshot）。
---meta 与 snapshot 天然互相依赖：本模块要建/撤快照，而快照轮询要读/建元信息。
---snapshot 在加载期 require 本模块，所以本模块不能在加载期 require 它；
---而 Factorio 的 require 只在解析 control.lua 期间可用，运行期调用会直接报
---"Require can't be used outside of control.lua parsing"——写成函数里延迟 require 是行不通的。
---@type table|nil
local snapshot_mod

---@return table
local function get_snapshot()
    if not snapshot_mod then
        error("meta: snapshot 模块尚未注入（入口需在 require 后调用 meta.inject_snapshot）")
    end
    return snapshot_mod
end


---模块对外暴露部分
local M = {}
--================================================================================================

---注入 snapshot 模块（打破 meta <-> snapshot 的循环依赖）
---@param mod table snapshot 模块
function M.inject_snapshot(mod)
    snapshot_mod = mod
end

---@type table<uint64,meta>
local objects_meta = {}

---无人机平台建设区域附近要关注的实体类型。
---只登记这些：区域的计数表会被反复遍历重算，把树/石头/装饰这些永远不会产生
---计数的实体也登记进来纯属浪费（一个平台的建设区域里就有上千个）。
local COUNT_ENTITY_TYPES = { "entity-ghost", "tile-ghost", "deconstructible-tile-proxy", "item-request-proxy" }

---枚举区域内需要关注的实体（虚影/地格虚影/地格代理/IRP + 已标记拆除/升级的实体）。
---@param surface LuaSurface
---@param area BoundingBox
---@return LuaEntity[]
local function find_count_entities(surface, area)
    local found = {}
    local function collect(filter)
        for _, e in ipairs(surface.find_entities_filtered(filter)) do
            found[#found + 1] = e
        end
    end
    collect({ area = area, type = COUNT_ENTITY_TYPES })
    collect({ area = area, to_be_deconstructed = true })
    collect({ area = area, to_be_upgraded = true })
    return found
end

--================================================================================================

---@class meta
---@field reg_num uint64 注册号
---@field entity LuaEntity 注册实体
---@field unit uint64 实体单位号，仅在带单位号的实体上可访问
---@field surface LuaSurface 实体所在表面（实体摧毁后 entity 不可用，故单独保留）
---@field movable int 可移动注册次数，仅在可移动的计数实体上使用
---@field tilepos_snapshot snapshot|nil 位置快照，仅在可移动的计数实体上使用
---@field inventory_snapshot snapshot|nil 内容物快照，仅在被标记拆除且有内容物的实体上使用
---@field count_items table<string,count_item> 计数项，仅在计数实体上可访问
---@field proxy_target meta 请求容器实体的元数据，仅在IRP上可访问
---@field reader_region region 读取器所在归属地，仅在读取器上可访问
---@field roboport_region region 平台所在归属地，用于在平台被删除时更新归属地。仅在无人机平台上可访问
---@field cbox BoundingBox 平台的建设范围，仅在无人机平台上可访问
---@field lbox BoundingBox 平台的物流范围，仅在无人机平台上可访问
---@field count_entity_regions table<region,any> 计数实体所在归属地，仅在计数实体上可访问
---@field irp_snapshot snapshot|nil IRP 快照，仅在IRP上可访问
local meta = {}

---@param reg_num uint64 注册号
---@param entity LuaEntity 注册实体
---@return meta
function meta:new(reg_num, entity)
    local obj = {
        reg_num = reg_num,
        entity = entity,
        unit = entity.unit_number,
        surface = entity.surface,
        movable = 0,
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
        obj = count_item.create()
        self.count_items[name] = obj
    end
    return obj
end

---设置一个计数项
---@param name string 计数项的id
---@param kind change_type
---@param item? LuaItemPrototype
---@param quality? LuaQualityPrototype
---@param count int
function meta:set_count_item(name, kind, item, quality, count)
    if not item then return end
    --品质兜底在 count_item 内部完成
    self:get_count_item(name):set(kind, item, quality, count)
    self:mark_dirty()
end

---删除一个计数项
---@param name string 计数项的id
function meta:remove_count_item(name)
    if self.count_items then self.count_items[name] = nil end
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
        self.tilepos_snapshot = get_snapshot().add_tilepos_snapshot(self.entity)
    end
    self.movable = self.movable + 1
end

---取消注册可移动
function meta:unregister_movable()
    self.movable = self.movable - 1
    if self.movable == 0 then
        get_snapshot().remove_snapshot(self.tilepos_snapshot)
    end
end

---标记脏数据
function meta:mark_dirty()
    changes.dirty_count_entitiy_output(self)
end

---读取器当前输出信号
---按配置的筛选模式/数量模式过滤合并归属地计数，NET 模式下回收计为负数。
---GUI 信号表与电路输出共用本函数，避免两处各写一遍合并逻辑。
---@return counter 合并结果：item -> quality -> count
function meta:read_output()
    local out = counter.create()
    local reader_region = self.reader_region
    --读取器不在任何归属地内（如未接入物流网络）时没有可读的计数
    if not (reader_region and reader_region.count) then return out end

    local uint = self.entity.unit_number
    local filter = config.get_filter(uint)
    local mode = config.get_count(uint)
    local quality_filter = config.get_quality(uint)
    for kind, item_counts in pairs(reader_region.count) do
        if match(kind, filter, mode) then
            local negtive = mode == count_mode.NET and match_count(kind, count_mode.RECYCLE)
            for item, quality_counts in pairs(item_counts) do
                for quality, count in pairs(quality_counts) do
                    if match_quality(quality.name, quality_filter) then
                        if negtive then
                            counter.add(out, item, quality, -count)
                        else
                            counter.add(out, item, quality, count)
                        end
                    end
                end
            end
        end
    end
    return out
end

---常量箱 section 的插槽上限（引擎硬上限：slot 索引超出会直接报错，不是静默失败）
---注意 LuaLogisticSection::filters_count 是"当前已有多少个过滤器"，不是插槽容量，
---不能用它判断是否写满（清空后它恒为 0）。
local SLOTS_PER_SECTION = 1000

---读取器重写信号输出
---一个 section 的插槽填满（1000 个）时新建 section 继续填充；
---本次用不到的旧 section 会被清空，避免残留上一次的信号。
function meta:write_outputs()
    ---@type LuaConstantCombinatorControlBehavior
    local cb = self.entity.get_or_create_control_behavior()
    --不支持控制行为的实体（如读取器虚影）没有信号输出
    if not cb then return end

    --先清空所有 section：本次可能用更少的 section，不清就会留下上次的旧信号
    for index = 1, cb.sections_count do
        local used = cb.get_section(index)
        if used then used.filters = {} end
    end

    local section_index = 0
    local slot = 0
    ---@type LuaLogisticSection|nil
    local section = nil
    for item, quality_counts in pairs(self:read_output()) do
        for quality, count in pairs(quality_counts) do
            --当前 section 插槽已满：取下一个（没有就新建）继续填
            if (not section) or slot >= SLOTS_PER_SECTION then
                section_index = section_index + 1
                section = cb.get_section(section_index)
                if not section then section = cb.add_section("") end
                --section 数量也到上限（add_section 返回 nil）：剩余信号无处安放，
                --只能丢弃（至少已写入的信号是完整的）
                if not section then return end
                slot = 0
            end
            slot = slot + 1
            section.set_slot(slot, { value = { type = 'item', name = item.name, quality = quality.name }, min = count })
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
    self.count_entity_regions[region] = true
    region:add_count_entity(self)
end

---为计数实体移除归属地
---@param region region
function meta:remove_from_region(region)
    self.count_entity_regions[region] = nil
    region:remove_count_entity(self)
end

---为计数实体移除所有归属地
function meta:clear_regions()
    --count_entity_regions 是集合（归属地 -> true），须用 pairs 遍历
    if self.count_entity_regions then
        for region, _ in pairs(self.count_entity_regions) do
            region:remove_count_entity(self)
        end
    end
    self.count_entity_regions = nil
end

function meta:on_destroyed()
    --IRP清理：它在目标容器上留下的计数项与轮询快照都要撤掉
    if self.proxy_target then
        self.proxy_target:remove_count_item(COUNT_IRP_PREFIX .. tostring(self.reg_num))
        changes.dirty_count_entitiy_output(self.proxy_target)
        if self.proxy_target.movable > 0 then
            self.proxy_target:unregister_movable()
        end
    end
    if self.irp_snapshot then
        get_snapshot().remove_snapshot(self.irp_snapshot)
    end

    --计数实体清理
    self:clear_count_item()
    self:clear_regions()
    if self.tilepos_snapshot then
        get_snapshot().remove_snapshot(self.tilepos_snapshot)
    end
    if self.inventory_snapshot then
        get_snapshot().remove_snapshot(self.inventory_snapshot)
    end

    --读取器清理
    self:reader_set_region(nil)
    --无人机平台清理(由于无人机平台删除导致归属地尺寸收缩)
    --平台被拆会让它所在的物流网络重新分裂：引擎不会为分裂销毁任何网络对象
    --（存活的那半沿用原 network_id，裂出去的那半是新 network_id），
    --所以事件里查不到"网络归属地销毁"，只能由平台这一侧反推：
    --把原网络归属地的全部成员标脏重解析。这些成员可能遍布整个原网络
    --（如裂出去那半覆盖的实体），不是只看平台自己的建设区域。
    if self.roboport_region then
        for reader, _ in pairs(self.roboport_region.readers) do
            changes.dirty_reader_region(reader)
        end
        for ce, _ in pairs(self.roboport_region.count_entities) do
            changes.dirty_count_entitiy_region(ce)
        end
    end
    --此处实体已被摧毁（on_object_destroyed 在销毁后触发），只能用创建时保留的 surface
    if self.roboport_region and self.surface then
        for _, e in ipairs(self.surface.find_entities_filtered({ area = self.lbox, name = READER })) do
            local m = M.ensure_reader_meta(e)
            changes.dirty_reader_region(m)
        end
        for _, e in ipairs(find_count_entities(self.surface, self.cbox)) do
            local m = M.ensure_entity_meta(e)
            changes.dirty_count_entitiy_region(m)
        end
    end
end

--================================================================================================

---注册对象的元信息，元数据中保留了实体摧毁后要访问的数据。
---因为on_object_destroyed响应时不带实体数据（已完成销毁），所以才不得不这样实现。
---@return meta register_meta 注册的元信息
---@param entity LuaEntity 要进行注册的实体（关注实体的摧毁事件）
function M.ensure_entity_meta(entity)
    local reg_num = script.register_on_object_destroyed(entity)
    local m = objects_meta[reg_num]
    if m == nil then
        m = meta:new(reg_num, entity)
        objects_meta[reg_num] = m
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
        objects_meta[reg_num] = m
        changes.dirty_reader_region(m)
    end
    return m
end

---@return meta register_meta 注册的元信息
---@param port LuaEntity 要进行注册的机器人平台
function M.ensure_roboport_meta(port)
    local reg_num = script.register_on_object_destroyed(port)
    local m = objects_meta[reg_num]
    if m == nil then
        m = meta:new(reg_num, port)
        objects_meta[reg_num] = m
        local r = region.ensure_region_logistic_network(port.logistic_network)
        m.roboport_region = r
        local logistic_cell = port.logistic_cell
        local lbox = box(port.position, logistic_cell.logistic_radius)
        local cbox = box(port.position, logistic_cell.construction_radius)
        m.cbox = cbox
        m.lbox = lbox

        for _, e in ipairs(port.surface.find_entities_filtered({ area = lbox, name = READER })) do
            local m = M.ensure_reader_meta(e)
            m:reader_set_region(r)
        end
        for _, e in ipairs(find_count_entities(port.surface, cbox)) do
            local m = M.ensure_entity_meta(e)
            m:add_to_region(r)
        end
    end
    return m
end

---@param reg_num uint64 注册号
---@return meta register_meta
function M.get_meta(reg_num)
    return objects_meta[reg_num]
end

---取已注册实体的元信息（不新建）。
---register_on_object_destroyed 对同一对象重复注册返回同一个注册号，故可安全用作查找键。
---@param entity LuaEntity
---@return meta|nil
function M.get_meta_of(entity)
    if not (entity and entity.valid) then return nil end
    return objects_meta[script.register_on_object_destroyed(entity)]
end

---@param reg_num uint64 注册号
function M.remove_meta(reg_num)
    local m = objects_meta[reg_num]
    if not m then return end
    --先摘除登记再清理：清理过程会调用 ensure_* 重新登记其他实体
    objects_meta[reg_num] = nil
    m:on_destroyed()
end

---清空元信息注册表（全量重建时用）。
---元信息依附实体，会随世界状态重新登记；引擎侧的销毁注册是幂等的，不受影响。
function M.reset()
    objects_meta = {}
end

return M
