-- ghost-reader / control_dop.lua
--
-- 虚影读取器（Ghost Reader）—— 面向数据编程（DOP）重构版【入口文件】。
--
-- 本文件是入口：按依赖顺序 require dop/ 子目录下的各功能模块，并调用
-- main.register() 完成事件注册。真正的实现拆分在 dop/*.lua：
--
--   dop/constants.lua     常量与 storage 键名
--   dop/items.lua         物品名解析与回收内容（纯辅助）
--   dop/config.lua        读取器配置
--   dop/regions.lua       归属地元信息 + 粗/细碰撞检测
--   dop/changes.lua       变更列表（事件缓冲）+ 脏读取器列表
--   dop/events.lua        事件处理层（登记变更）
--   dop/regions_incr.lua  归属地增量维护（读取器归属）
--   dop/irp.lua           IRP 指纹轮询
--   dop/output.lua        幽灵读取器输出（写电路 + tooltip）
--   dop/gui.lua           GUI（构建/渲染/事件）
--   dop/main.lua          主管线（on_tick 主循环 + 顶层事件回调 + 生命周期）
--
-- 本文件不覆盖 control.lua。尚未切换入口（由用户确认后再替换 control.lua 或
-- 改 mod 配置指向本文件）。

-- 预加载各模块（require 会按需初始化，顺序即依赖方向）
local constants = require("__ghost-reader__/dop/constants")
local items = require("__ghost-reader__/dop/items")
local config = require("__ghost-reader__/dop/config")
local regions = require("__ghost-reader__/dop/regions")
local changes = require("__ghost-reader__/dop/changes")
local events = require("__ghost-reader__/dop/events")
local regions_incr = require("__ghost-reader__/dop/regions_incr")
local irp = require("__ghost-reader__/dop/irp")
local output = require("__ghost-reader__/dop/output")
local gui = require("__ghost-reader__/dop/gui")
local main = require("__ghost-reader__/dop/main")

-- 完成事件注册（on_tick / 各实体与 GUI 事件 / 生命周期）
main.register()

return {
  constants = constants,
  items = items,
  config = config,
  regions = regions,
  changes = changes,
  events = events,
  regions_incr = regions_incr,
  irp = irp,
  output = output,
  gui = gui,
  main = main,
}
