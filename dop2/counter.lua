---@class counter 计数表：item -> quality -> count
local counter = {}

---共享元表：计数器会被大量创建（每个计数项、每次归属地重算），
---不为每个实例再造一张元表。
local counter_mt = { __index = counter }

---comment
---@return counter
function counter:new()
    return setmetatable({}, counter_mt)
end

---取某个物品的计数行（无则新建）
---@param item LuaItemPrototype
---@return table<LuaQualityPrototype,int>
function counter:row(item)
    local qualities = self[item]
    if not qualities then
        qualities = {}
        self[item] = qualities
    end
    return qualities
end

---增量修改计数（正负均可）
---@param item LuaItemPrototype
---@param quality LuaQualityPrototype
---@param count integer
function counter:add(item, quality, count)
    local qualities = self:row(item)
    qualities[quality] = (qualities[quality] or 0) + count
end

---设置计数（覆盖）
---@param item LuaItemPrototype
---@param quality LuaQualityPrototype
---@param count integer
function counter:set(item, quality, count)
    self:row(item)[quality] = count
end

---comment
---@param item LuaItemPrototype
---@param quality LuaQualityPrototype
---@return integer
function counter:read(item, quality)
    local qualities = self[item]
    if not qualities then return 0 end
    return qualities[quality] or 0
end

local M = {}
---@return counter
function M.create()
    return counter:new()
end

--方法也一并导出：除了在 counter 对象上以 `obj:add(...)` 调用，还需要以
--"函数 + 显式 self"的形式对普通表操作（例如 count_item 的分类表、合并用的临时表）：
--`counter.add(tbl, item, quality, count)`。只导出 create 的话这些调用会是 nil。
M.row = counter.row
M.add = counter.add
M.set = counter.set
M.read = counter.read

return M
