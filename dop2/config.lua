local M = {}

local DEFAULT_RANGE = range_mode.NETWORK
local DEFAULT_FILTER = filter_mode.ALL
local DEFAULT_QUALITY = QUALITY_ALL
local DEFAULT_COUNT = count_mode.NET

local function reader_storage(unit)
    storage.readers = storage.readers or {}
    storage.readers[unit] = storage.readers[unit] or {}
    return storage.readers[unit]
end

local function get_mode(unit)
    local d = storage.readers and storage.readers[unit] or nil; return (d and d.mode) or DEFAULT_RANGE
end
local function get_filter(unit)
    local d = storage.readers and storage.readers[unit] or nil; return (d and d.filter) or DEFAULT_FILTER
end
local function get_count(unit)
    local d = storage.readers and storage.readers[unit] or nil; return (d and d.count) or DEFAULT_COUNT
end
local function get_quality(unit)
    local d = storage.readers and storage.readers[unit] or nil; return (d and d.quality) or DEFAULT_QUALITY
end

local function set_mode(unit, mode) reader_storage(unit).mode = mode end
local function set_filter(unit, filter) reader_storage(unit).filter = filter end
local function set_count(unit, count) reader_storage(unit).count = count end
local function set_quality(unit, quality) reader_storage(unit).quality = quality end

-- 读取器配置快照（供蓝图 tags 用）
local function reader_config(unit)
    local d = storage.readers and storage.readers[unit]
    return {
        mode = (d and d.mode) or DEFAULT_RANGE,
        filter = (d and d.filter) or DEFAULT_FILTER,
        count = (d and d.count) or DEFAULT_COUNT,
        quality = (d and d.quality) or DEFAULT_QUALITY,
    }
end

-- 应用一组配置到读取器
local function apply_config(unit, cfg)
    if not (type(unit) == "number") then return end
    local s = reader_storage(unit)
    if cfg.mode then s.mode = cfg.mode end
    if cfg.filter then s.filter = cfg.filter end
    if cfg.count then s.count = cfg.count end
    if cfg.quality then s.quality = cfg.quality end
end

-- 过滤器组合的缓存键：筛选模式 | 数量模式 | 品质筛选。
-- 三个值都是稳定的字符串（枚举值/品质名），拼起来即可作为归属地输出缓存的键：
-- 键相同 => 过滤结果必然相同，多个读取器可以直接复用同一份结果。
local function output_key(unit)
    return get_filter(unit) .. "|" .. get_count(unit) .. "|" .. get_quality(unit)
end

M.get_mode = get_mode
M.get_filter = get_filter
M.get_count = get_count
M.get_quality = get_quality
M.set_mode = set_mode
M.set_filter = set_filter
M.set_count = set_count
M.set_quality = set_quality
M.reader_config = reader_config
M.apply_config = apply_config
M.output_key = output_key

return M
