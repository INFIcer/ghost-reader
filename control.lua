-- ghost-reader / control.lua
--
-- 虚影读取器（Ghost Reader）—— 面向数据编程（DOP）重构版 **dop2**【入口文件】。
--
-- 本文件是入口：按依赖顺序 require dop2/ 下的各模块，最后调用 events.register()
-- 完成事件注册与生命周期钩子（on_tick / on_load / on_configuration_changed）。
--
--   dop2/lib.lua         全局常量与工具（READER / COUNT_* / QUALITY_ALL / match_* / box ...）
--   dop2/enum.lua        全局枚举（change_type / range_mode / filter_mode / count_mode）
--   dop2/config.lua      读取器配置（mode/filter/count/quality）
--   dop2/counter.lua     两级计数器：item -> quality -> count
--   dop2/count_item.lua  计数项：change_type -> counter
--   dop2/item.lua        物品解析与实体携带物品统计（含 IRP 明细提取）
--   dop2/region.lua      归属地（表面 / 物流网络）
--   dop2/meta.lua        实体元信息与计数项
--   dop2/snapshot.lua    指纹快照轮询（内容物 / 位置 / IRP）
--   dop2/gui.lua         读取器面板与悬浮提示
--   dop2/bplib.lua       蓝图 tags 配置持久化
--   dop2/paste.lua       复制粘贴配置（隔离原版恒压器 + 读取器之间继承）
--   dop2/events.lua      事件层 + on_tick 管线 + 初始化/全量重建
--
-- 依赖顺序：lib 与 enum 是"纯全局表"（加载期就往全局写 READER / change_type 等），
-- 必须最先加载；config 在模块加载期就会引用 range_mode 与 QUALITY_ALL，所以要排在它们之后。
-- 其余模块由各自的 require 解析依赖，顺序无关。require 一律用带 mod 前缀的绝对路径
-- （裸路径会从 mod 根目录找，找不到 dop2/ 下的文件）。
--
-- 想切回 dop/ 版本：把 control_dop.lua 的内容复制回本文件即可（dop/ 目录未改动，
-- data.lua / data-updates.lua 为两版共用，无需更换）。

--纯全局模块：只为写全局表，没有返回值
require("__ghost-reader__/dop2/lib")
require("__ghost-reader__/dop2/enum")

--其余模块（require 会按依赖图自行初始化）
local config = require("__ghost-reader__/dop2/config")
local changes = require("__ghost-reader__/dop2/changes")
local counter = require("__ghost-reader__/dop2/counter")
local count_item = require("__ghost-reader__/dop2/count_item")
local item = require("__ghost-reader__/dop2/item")
local region = require("__ghost-reader__/dop2/region")
local meta = require("__ghost-reader__/dop2/meta")
local snapshot = require("__ghost-reader__/dop2/snapshot")
local gui = require("__ghost-reader__/dop2/gui")
local bplib = require("__ghost-reader__/dop2/bplib")
local paste = require("__ghost-reader__/dop2/paste")
local events = require("__ghost-reader__/dop2/events")

--打破 meta <-> snapshot 的循环依赖：snapshot 在加载期 require meta，
--所以 meta 不能反过来在加载期 require snapshot；require 又只能在解析 control.lua 时调用，
--因此在两者都加载完之后，由入口把 snapshot 注入 meta。
meta.inject_snapshot(snapshot)

--事件注册（含读档全量重建与配置变化重建）
events.register()

return {
  config = config,
  changes = changes,
  counter = counter,
  count_item = count_item,
  item = item,
  region = region,
  meta = meta,
  snapshot = snapshot,
  gui = gui,
  bplib = bplib,
  paste = paste,
  events = events,
}
