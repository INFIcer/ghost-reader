---@class counter 计数表：item(物品名) -> quality(品质名) -> count
---键强制为名字（字符串），不接受原型对象：Factorio 的原型 userdata 不驻留，
---prototypes.item["iron-plate"] 两次调用返回不同对象（a == b 为真靠的是引擎的 __eq），
---而 Lua 表键只认原始身份、不走 __eq —— 用原型当键会让同一个物品永远合不到一起
---（多堆同类物品只剩一堆的数量）。名字既是稳定键，也正好是 SignalID 想要的形式。
---调用方传名字：物品名来自 item_for_entity/item_for_tile 等，品质名来自 ensure_quality。
local counter = {}

---共享元表：计数器会被大量创建（每个计数项、每次归属地重算），
---不为每个实例再造一张元表。
local counter_mt = { __index = counter }

---键必须是名字。传原型只会静默写坏计数（合并失效），所以这里直接报错，
---把"该传名字"这件事在开发期就暴露出来。
---@param name string
local function check_key(name)
    if type(name) ~= "string" then
        error("counter: 键必须是名字（字符串）")
    end
end

---comment
---@return counter
function counter:new()
    return setmetatable({}, counter_mt)
end

---取某个物品的计数行（无则新建）
---@param item string 物品名
---@return table<string,int> 品质名 -> 数量
function counter:row(item)
    check_key(item)
    local qualities = self[item]
    if not qualities then
        qualities = {}
        self[item] = qualities
    end
    return qualities
end

---增量修改计数（正负均可）
---@param item string 物品名
---@param quality string 品质名
---@param count integer
function counter:add(item, quality, count)
    check_key(quality)
    local qualities = self:row(item)
    qualities[quality] = (qualities[quality] or 0) + count
end

---设置计数（覆盖）
---@param item string 物品名
---@param quality string 品质名
---@param count integer
function counter:set(item, quality, count)
    check_key(quality)
    self:row(item)[quality] = count
end

---comment
---@param item string 物品名
---@param quality string 品质名
---@return integer
function counter:read(item, quality)
    check_key(item)
    check_key(quality)
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
