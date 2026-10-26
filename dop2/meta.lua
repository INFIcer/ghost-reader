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
---@field tile_ghost_key string|nil 地格拆除去重索引键，仅在"覆盖了可回收地格"的地格虚影上可访问
---@field tile_proxy_key string|nil 地格拆除去重索引键，仅在地格拆除代理（deconstructible-tile-proxy）上可访问
---@field decon_tilepos TilePosition|nil 地格拆除代理登记时的格点坐标（代理销毁时判断原地格是否还在）
---@field decon_tile_name string|nil 地格拆除代理登记时的地格原型名（同上）
---@field decon_tile_item string|nil 地格拆除代理登记时的地格回收物品名（取消拆除时还给虚影用）
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
---注意：返回的对象**不要直接改**。归属地计数靠计数项变化时的增量通知维护
---（见下面的 propagate 小节），绕过本文件的方法直接改计数表会让归属地总和永久偏差。
---只有"整体重算/替换"这类一次算清的场景才用 replace_count_item。
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

--================================================================================================
-- 计数增量传播
--================================================================================================
--归属地计数是增量维护的：不再"标脏归属地、帧末整份重算"，而是任何计数项一变就当场把
--净变化量加到该计数实体所在的所有归属地上（region:add_count）。
--正确性完全取决于这里：重复通知会让总和偏大、遗漏通知会让总和永久偏小。
--所以所有计数项修改都必须走下面的方法（get_count_item 拿到的对象不能直接改）。
--
--两个容易出错的点，这里集中处理：
--  1. 同一计数实体可能同时属于多个归属地（所在表面 + 所在物流网络），变化要逐个通知；
--  2. IRP 计数项记在目标容器上，容器一旦被标记拆除（出现 deconstruction-inventory
--     计数项），这些请求就不再算数（拆除后请求已作废，留着会与实体回收重复计）。
--     该可见性是由"另一个计数项存不存在"决定的，所以增删 deconstruction-inventory
--     时必须把它遮住/放出全部 IRP 计数。

---计数项当前是否被 IRP 隐藏规则挡在归属地计数之外
---@param self meta
---@param name string 计数项名
---@return boolean
local function irp_hidden(self, name)
    local items = self.count_items
    return items ~= nil and items[COUNT_DECON_INVENTORY] ~= nil and has_prefix(name, COUNT_IRP_PREFIX)
end

---该实体是否已有某个计数项
---@param name string 计数项名
---@return boolean
function meta:has_count_item(name)
    return self.count_items ~= nil and self.count_items[name] ~= nil
end

---把一个计数增量通知给实体当前所在的所有归属地
---@param kind change_type
---@param item string 物品名
---@param quality string 品质名
---@param delta int 增量（正负均可）
function meta:notify_region_delta(kind, item, quality, delta)
    if delta == 0 then return end
    --set_count_item 的品质参数可以是 nil（缺省 normal），而归属地计数的键必须是字符串，
    --否则用 nil 当表键会直接报 "table index is nil"。这里统一兜底成名字。
    quality = ensure_quality(quality)
    local regions = self.count_entity_regions
    if not regions then return end
    for target_region in pairs(regions) do
        target_region:add_count(kind, item, quality, delta)
    end
end

---IRP 计数项的可见性翻转：hide=true 表示归属地计数里要扣掉现存 IRP 计数，
---hide=false 表示重新加回（deconstruction-inventory 被删掉时）。
---@param hide boolean
function meta:notify_irp_visibility(hide)
    local items = self.count_items
    if not items then return end
    for name, count_item_of in pairs(items) do
        if has_prefix(name, COUNT_IRP_PREFIX) then
            for kind, item_counts in pairs(count_item_of) do
                for item, quality_counts in pairs(item_counts) do
                    for quality, n in pairs(quality_counts) do
                        self:notify_region_delta(kind, item, quality, hide and -n or n)
                    end
                end
            end
        end
    end
end

---把实体的全部有效计数整份计入/移出某个归属地（成员变更时用）。
---有效 = 所有计数项，但 IRP 计数项在 deconstruction-inventory 存在时不算。
---@param target_region region
---@param sign int 1 = 计入，-1 = 移出
function meta:contribute_counts(target_region, sign)
    local items = self.count_items
    if not items then return end
    local hidden_irp = items[COUNT_DECON_INVENTORY] ~= nil
    for name, count_item_of in pairs(items) do
        if not (hidden_irp and has_prefix(name, COUNT_IRP_PREFIX)) then
            for kind, item_counts in pairs(count_item_of) do
                for item, quality_counts in pairs(item_counts) do
                    for quality, n in pairs(quality_counts) do
                        target_region:apply_count(kind, item, quality, sign * n)
                    end
                end
            end
        end
    end
end

---设置一个计数项（覆盖）。变化量 = 新值 - 旧值，按变化量增量通知归属地。
---@param name string 计数项的id
---@param kind change_type
---@param item? string 物品名（计数表的键是名字）
---@param quality? string 品质名（缺省为 normal）
---@param count int
function meta:set_count_item(name, kind, item, quality, count)
    if not item then return end
    --创建 deconstruction-inventory 会把已有的 IRP 计数项从归属地里遮掉
    local hides_irp = name == COUNT_DECON_INVENTORY and not self:has_count_item(name)
    --品质兜底在 count_item 内部完成
    local count_item_of = self:get_count_item(name)
    local old = count_item_of:read(kind, item, quality)
    local delta = count - old
    count_item_of:set(kind, item, quality, count)
    --IRP 计数项被遮住时它的变化不属于归属地总和，不通知
    if not irp_hidden(self, name) then
        self:notify_region_delta(kind, item, quality, delta)
    end
    if hides_irp then self:notify_irp_visibility(true) end
end

---用整张计数器覆盖某个计数项的某个类别（替换而非累加）。
---用于"一次算清一整份计数"的场景：快照重算内容物、瞬间拆除类的回收物。
---先扣掉旧内容的计数，再加回新内容，归属地总和始终等于真实值。
---@param name string 计数项的id
---@param kind change_type
---@param c counter|nil 为 nil 表示清空该类别
function meta:replace_count_item(name, kind, c)
    --创建 deconstruction-inventory 会把已有的 IRP 计数项从归属地里遮掉
    local hides_irp = name == COUNT_DECON_INVENTORY and not self:has_count_item(name)
    local count_item_of = self:get_count_item(name)
    if not irp_hidden(self, name) then
        local old = count_item_of[kind]
        if old then
            for item, quality_counts in pairs(old) do
                for quality, n in pairs(quality_counts) do
                    self:notify_region_delta(kind, item, quality, -n)
                end
            end
        end
        if c then
            for item, quality_counts in pairs(c) do
                for quality, n in pairs(quality_counts) do
                    self:notify_region_delta(kind, item, quality, n)
                end
            end
        end
    end
    count_item_of:replace(kind, c)
    if hides_irp then self:notify_irp_visibility(true) end
end

---删除一个计数项：把它当前的全部计数从归属地扣掉。
---删除 deconstruction-inventory 时，原先被它遮住的 IRP 计数项要重新加回归属地。
---@param name string 计数项的id
function meta:remove_count_item(name)
    local items = self.count_items
    if not (items and items[name]) then return end
    local removes_decon_mark = (name == COUNT_DECON_INVENTORY)
    if not irp_hidden(self, name) then
        for kind, item_counts in pairs(items[name]) do
            for item, quality_counts in pairs(item_counts) do
                for quality, n in pairs(quality_counts) do
                    self:notify_region_delta(kind, item, quality, -n)
                end
            end
        end
    end
    items[name] = nil
    if removes_decon_mark then self:notify_irp_visibility(false) end
end

---删除所有计数项。
---净效果是归属地贡献归零（IRP 计数项本来就被遮住时也不放出，因为它们同样被删掉了）。
function meta:clear_count_item()
    local items = self.count_items
    if not items then return end
    local hidden_irp = items[COUNT_DECON_INVENTORY] ~= nil
    for name, count_item_of in pairs(items) do
        if not (hidden_irp and has_prefix(name, COUNT_IRP_PREFIX)) then
            for kind, item_counts in pairs(count_item_of) do
                for item, quality_counts in pairs(item_counts) do
                    for quality, n in pairs(quality_counts) do
                        self:notify_region_delta(kind, item, quality, -n)
                    end
                end
            end
        end
    end
    self.count_items = nil
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

---把某个归属地的计数按配置过滤合并成输出计数表
---按配置的筛选模式/数量模式过滤合并归属地计数，NET 模式下回收计为负数。
---GUI 信号表与电路输出共用本函数，避免两处各写一遍合并逻辑。
---
---结果按「过滤器组合」缓存在归属地上：过滤只取决于（归属地计数, 筛选, 数量, 品质），
---配置相同的读取器结果必然一样，所以同一归属地下的同配置读取器共用一份结果——
---大量读取器时这是主要开销（每次计数变化都要为每个读取器重新过滤一遍归属地计数）。
---归属地计数一变（region:add_count 内部 invalidate_outputs）缓存即作废；读取器改配置只是换了个键。
---返回的计数表是**共享的只读结果**，调用方不得修改。
---@param reader_region region|nil
---@param unit uint64 读取器单位号（配置按单位号存放）
---@return counter 合并结果：item名 -> quality名 -> count
function M.read_region_output(reader_region, unit)
    --读取器不在任何归属地内（如未接入物流网络）时没有可读的计数
    if not (reader_region and reader_region.count) then return counter.create() end

    local key = config.output_key(unit)
    local outputs = reader_region.outputs
    if outputs then
        local cached = outputs[key]
        if cached then return cached end
    end

    local out = counter.create()
    local filter = config.get_filter(unit)
    local mode = config.get_count(unit)
    local quality_filter = config.get_quality(unit)
    for kind, item_counts in pairs(reader_region.count) do
        if match(kind, filter, mode) then
            local negtive = mode == count_mode.NET and match_count(kind, count_mode.RECYCLE)
            for item, quality_counts in pairs(item_counts) do
                for quality, count in pairs(quality_counts) do
                    --键已经是名字（字符串），与配置里的品质名同一形态，直接比
                    if match_quality(quality, quality_filter) then
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

    if not outputs then
        outputs = {}
        reader_region.outputs = outputs
    end
    outputs[key] = out
    return out
end

---读取器当前的归属地。
---真实读取器用元信息里已解析好的归属地；虚影没有归属地缓存，按配置与位置现算
---（面板要能预览虚影建成后会读到什么，这也是 dop1 的行为）。
---@param entity LuaEntity 读取器（真实实体或其虚影）
---@return region|nil
function M.region_of(entity)
    local m = M.get_meta_of(entity)
    if m and m.reader_region then return m.reader_region end

    local unit = entity.unit_number
    if type(unit) ~= "number" then return nil end
    if config.get_mode(unit) == range_mode.SURFACE then
        return region.ensure_region_surface(entity.surface)
    end
    local logistic_network = entity.surface.find_logistic_network_by_position(entity.position, entity.force)
    if not logistic_network then return nil end
    return region.ensure_region_logistic_network(logistic_network)
end

---读取器当前应显示/输出的信号（真实实体与虚影通用）
---@param entity LuaEntity 读取器（真实实体或其虚影）
---@return counter
function M.output_of(entity)
    local unit = entity.unit_number
    if type(unit) ~= "number" then return counter.create() end
    return M.read_region_output(M.region_of(entity), unit)
end

---读取器当前输出信号
---@return counter 合并结果：item名 -> quality名 -> count
function meta:read_output()
    --用建元信息时记下的单位号取配置：实体可能已经失效，不去碰它
    return M.read_region_output(self.reader_region, self.unit)
end

---常量箱 section 的插槽上限（引擎硬上限：slot 索引超出会直接报错，不是静默失败）
---注意 LuaLogisticSection::filters_count 是"当前已有多少个过滤器"，不是插槽容量，
---不能用它判断是否写满（清空后它恒为 0）。
local SLOTS_PER_SECTION = 1000

---读取器重写信号输出
---一个 section 的插槽填满（1000 个）时新建 section 继续填充；
---本次用不到的旧 section 会被清空，避免残留上一次的信号。
function meta:write_outputs()
    --实体已销毁时不能再碰它（例如读取器与平台在同一帧被拆：标脏发生在销毁之前）
    if not self:vaild() then return end
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
            --计数表的键就是物品名与品质名（字符串），正是 SignalID 需要的形态
            section.set_slot(slot, { value = { type = 'item', name = item, quality = quality }, min = count })
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

---为计数实体添加归属地。
---加入时把实体当前的全部有效计数整份计入归属地，之后的计数变化再按增量通知。
---@param region region
function meta:add_to_region(region)
    if not self.count_entity_regions then self.count_entity_regions = {} end
    --幂等：重复加入不能重复计入
    if self.count_entity_regions[region] then return end
    self.count_entity_regions[region] = true
    region:add_count_entity(self)
end

---为计数实体移除归属地。
---移出时把实体当前的全部有效计数从归属地扣掉，保证归属地总和仍然准确。
---@param region region
function meta:remove_from_region(region)
    if not (self.count_entity_regions and self.count_entity_regions[region]) then return end
    self.count_entity_regions[region] = nil
    region:remove_count_entity(self)
end

---为计数实体移除所有归属地
function meta:clear_regions()
    --count_entity_regions 是集合（归属地 -> true），须用 pairs 遍历。
    --这里直接调 region:remove_count_entity（幂等且会扣掉该实体的计数），
    --不在遍历中改动集合本身，遍历结束后整表丢弃。
    if self.count_entity_regions then
        for target_region, _ in pairs(self.count_entity_regions) do
            target_region:remove_count_entity(self)
        end
    end
    self.count_entity_regions = nil
end

function meta:on_destroyed()
    --IRP清理：它在目标容器上留下的计数项与轮询快照都要撤掉
    --（remove_count_item 会把它从目标容器所在归属地的计数里同步扣掉）
    if self.proxy_target then
        self.proxy_target:remove_count_item(COUNT_IRP_PREFIX .. tostring(self.reg_num))
        if self.proxy_target.movable > 0 then
            self.proxy_target:unregister_movable()
        end
    end
    if self.irp_snapshot then
        get_snapshot().remove_snapshot(self.irp_snapshot)
    end

    --计数实体清理：先扣掉全部计数项、再摘除归属地，两步净效果是归属地贡献归零。
    --顺序不能反：clear_count_item 依赖 count_entity_regions 才能把计数扣到归属地上。
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
        --读取器既是"读取者"也是"计数实体"：
        --  * 读取者身份用 reader_region（按范围模式二选一）；
        --  * 计数实体身份要照常解析归属地，否则它自己身上的计数项
        --    （被标记拆除时的实体回收、升级等）传播不到任何归属地，读数里看不到。
        changes.dirty_reader_region(m)
        changes.dirty_count_entitiy_region(m)
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
        --平台自身同样是计数实体：它被标记拆除（以及平台内部存储的物品）要能被读到。
        --这里不直接 add_to_region：平台所在物流网络当时可能还没解析好，
        --交给通用的归属地解析（下一帧按位置算出它落在哪些网络/表面）更稳。
        changes.dirty_count_entitiy_region(m)
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
