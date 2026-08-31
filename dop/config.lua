-- dop/config.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 读取器配置。
--
-- 读取器的 mode/filter/qty 存于 mod storage（storage.readers），不污染电路。
-- 其余模块通过本模块导出的 get_*/set_* 读写。apply_config/reader_config 仅
-- 在蓝图 tags 持久化需要时使用（当前未接线 bplib，保留以备扩展）。

local constants = require("__ghost-reader__/dop/constants")
local M = {}

local DEFAULT_MODE = constants.DEFAULT_MODE
local DEFAULT_FILTER = constants.DEFAULT_FILTER
local DEFAULT_QTY = constants.DEFAULT_QTY

local function reader_storage(unit)
  storage.readers = storage.readers or {}
  storage.readers[unit] = storage.readers[unit] or {}
  return storage.readers[unit]
end

local function get_mode(unit)  local d = storage.readers and storage.readers[unit] or nil; return (d and d.mode) or DEFAULT_MODE end
local function get_filter(unit) local d = storage.readers and storage.readers[unit] or nil; return (d and d.filter) or DEFAULT_FILTER end
local function get_qty(unit)   local d = storage.readers and storage.readers[unit] or nil; return (d and d.qty) or DEFAULT_QTY end

local function set_mode(unit, mode)  reader_storage(unit).mode = mode end
local function set_filter(unit, filter) reader_storage(unit).filter = filter end
local function set_qty(unit, qty)    reader_storage(unit).qty = qty end

-- 读取器配置快照（供蓝图 tags 用）
local function reader_config(unit)
  local d = storage.readers and storage.readers[unit]
  return {
    mode = (d and d.mode) or DEFAULT_MODE,
    filter = (d and d.filter) or DEFAULT_FILTER,
    qty = (d and d.qty) or DEFAULT_QTY,
  }
end

-- 应用一组配置到读取器
local function apply_config(unit, cfg)
  if not (type(unit) == "number") then return end
  local s = reader_storage(unit)
  if cfg.mode then s.mode = cfg.mode end
  if cfg.filter then s.filter = cfg.filter end
  if cfg.qty then s.qty = cfg.qty end
end

M.get_mode = get_mode
M.get_filter = get_filter
M.get_qty = get_qty
M.set_mode = set_mode
M.set_filter = set_filter
M.set_qty = set_qty
M.reader_config = reader_config
M.apply_config = apply_config

return M
