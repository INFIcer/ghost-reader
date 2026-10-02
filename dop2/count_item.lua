-- dop2/count_item.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 计数项。
--
-- 计数项是「按 change_type 分类的计数表」：kind -> item -> quality -> count。
-- 分类以下的那一层（item -> quality -> count 的增删）完全复用 counter：
-- 计数项只负责分类、品质兜底与对象身份，不再各处手写嵌套表的建立与累加。
--
-- 用法：
--   meta.count_items[name] 是某个计数项（虚影/拆除/升级/IRP 各一项）；
--   region.count 是该归属地内所有计数实体合并后的计数，两者同类型，可相加。
-- 读取时可直接 pairs 遍历（数据都在表本体上，方法在元表里）：
--   for kind, item_counts in pairs(ci) do for item, quality_counts in pairs(item_counts) ...

local counter = require("__ghost-reader__/dop2/counter")

---@class count_item 按 change_type 分类的计数表
local count_item = {}

---共享元表：计数项会被大量创建（每个实体的每个计数项、每次归属地重算），
---不为每个实例再造一张元表。
local count_item_mt = { __index = count_item }

---comment
---@return count_item
function count_item:new()
    return setmetatable({}, count_item_mt)
end

---取某个类别的计数器（无则新建）。
---计数器共享同一张元表，新建一个对象的代价就是一张空表。
---@param kind change_type
---@return counter
function count_item:counter_of(kind)
    local item_counts = self[kind]
    if not item_counts then
        item_counts = counter.create()
        self[kind] = item_counts
    end
    return item_counts
end

---设置计数（覆盖）
---@param kind change_type
---@param item LuaItemPrototype
---@param quality? LuaQualityPrototype
---@param count int
function count_item:set(kind, item, quality, count)
    counter.set(self:counter_of(kind), item, ensure_quality(quality), count)
end

---增量修改计数（正负均可）
---@param kind change_type
---@param item LuaItemPrototype
---@param quality? LuaQualityPrototype
---@param count int
function count_item:add(kind, item, quality, count)
    counter.add(self:counter_of(kind), item, ensure_quality(quality), count)
end

---读取计数
---@param kind change_type
---@param item LuaItemPrototype
---@param quality? LuaQualityPrototype
---@return int count
function count_item:read(kind, item, quality)
    local item_counts = self[kind]
    if not item_counts then return 0 end
    return counter.read(item_counts, item, ensure_quality(quality))
end

---模块对外暴露部分
local M = {}

---@return count_item
function M.create()
    return count_item:new()
end

return M
