-- ghost-reader / control_dop.lua
--
-- 虚影读取器（Ghost Reader）—— 面向数据编程（DOP）**旧版（dop/）入口备份**。
--
-- 当前生效的入口是 control.lua（指向 dop2/）。本文件保留 dop/ 版本的入口内容：
-- 需要回退到旧实现时，把本文件的内容复制回 control.lua 即可（dop/ 目录未改动，
-- data.lua / data-updates.lua 为两版共用，无需更换）。
--
-- 原 dop/ 实现拆分如下：
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
