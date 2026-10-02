---@class counter
local counter = {}

---comment
---@return counter
function counter:new()
    local obj = {}
    setmetatable(obj, { __index = self })
    return obj
end

---@param item LuaItemPrototype
---@param quality LuaQualityPrototype
---@param count integer
function counter:add(item, quality, count)
    if not self[item] then item = {} end
    if not self[item][quality] then self[item][quality] = {} end
    self[item][quality] = (self[item][quality] or 0) + count
end

---@param item LuaItemPrototype
---@param quality LuaQualityPrototype
---@param count integer
function counter:set(item, quality, count)
    if not self[item] then item = {} end
    if not self[item][quality] then self[item][quality] = {} end
    self[item][quality] = count
end

---comment
---@param item LuaItemPrototype
---@param quality LuaQualityPrototype
---@return integer
function counter:read(item, quality)
    if not self[item] then return 0 end
    if not self[item][quality] then return 0 end
    return (self[item][quality] or 0)
end

local M = {}
---@return counter
function M.create()
    return counter:new()
end

return M
