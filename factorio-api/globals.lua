-- globals.lua
-- 全局对象声明 + 常用概念类型别名。
-- 本文件仅类型注释，不会被 Factorio 加载执行。

---@class LuaGameScript
---@class LuaBootstrap

---@alias Position { x: number, y: number }
---@alias Area { [integer]: Position }
---@alias BoundingBox { left_top: Position, right_bottom: Position }
---@alias LocalisedString string | string[] | { [integer]: any }
---@alias SignalID { name: string, type: string, quality?: string }
---@alias SpritePath string

---@type LuaGameScript
game = {}

---@type LuaBootstrap
script = {}

---@type table<string, any>
storage = {}

---@type fun(message: string)
log = function(message) end

---@type fun(message: any)
print = function(message) end
