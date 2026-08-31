-- dop/regions_incr.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 归属地增量维护（读取器归属）。
--
-- 提供：查找某位置所属物流网络 id；计算一个读取器的归属地（表面/网络）；
-- 把读取器加入/移出某归属地元信息的 readers 列表并维护其归属表。

local constants = require("__ghost-reader__/dop/constants")
local config = require("__ghost-reader__/dop/config")
local regions = require("__ghost-reader__/dop/regions")
local M = {}

local REGION_SURFACE = constants.REGION_SURFACE
local REGION_NETWORK = constants.REGION_NETWORK
local MODE_SURFACE = constants.MODE_SURFACE
local MODE_NETWORK = constants.MODE_NETWORK
local REGIONS = constants.REGIONS
local READER_REGION = constants.READER_REGION

local get_mode = config.get_mode
local region_key = regions.region_key
local ensure_region = regions.ensure_region

-- 查找某表面上一个位置所属的物流网络 id（供读取器归属、平台归属判断）
-- 通过遍历该表面的 roboport 判断位置是否在 logistic_radius 内。
-- 实测：roboport 原型字段名为 logistic_radius（=25），直接可读。
local function network_id_at(surface, pos)
  if not (surface and pos) then return nil end
  for _, port in ipairs(surface.find_entities_filtered{name = "roboport"}) do
    if port.valid then
      local srad = port.prototype and port.prototype.logistic_radius
      local ppos = port.position
      if srad and ppos then
        local dx, dy = math.abs(ppos.x - pos.x), math.abs(ppos.y - pos.y)
        if dx <= srad and dy <= srad then
          local net = port.logistic_network
          if net then return net.network_id end
        end
      end
    end
  end
  return nil
end

-- 重新计算一个读取器的归属地（表面或网络）。
-- 依据其范围模式：surface 归属地 = 所在表面；network 归属地 = 位置所属网络。
-- 返回新的归属地（rtype, id）。
local function reader_region_of(reader)
  local mode = get_mode(reader.unit_number)
  local surface_index = reader.surface.index
  if mode == MODE_SURFACE then
    return REGION_SURFACE, surface_index
  end
  local net_id = network_id_at(reader.surface, reader.position)
  return REGION_NETWORK, net_id
end

-- 取读取器当前归属地（rtype, id）。
-- 优先用缓存 storage[READER_REGION][unit]（由 reader_region_set 在归属阶段写入），
-- 避免渲染/输出时每读取器每帧重复 network_id_at 全表面 roboport 扫描。
-- 无缓存（如尚未归属）时退回即时计算。
local function reader_region_cached(unit, reader)
  local reg = storage[READER_REGION] and storage[READER_REGION][unit]
  if reg then return reg[1], reg[2] end
  if reader and reader.valid then
    return reader_region_of(reader)
  end
  return nil, nil
end

-- 把读取器加入某归属地（更新元信息的 readers 列表 + 归属表）
local function reader_region_set(unit, rtype, id)
  storage[READER_REGION] = storage[READER_REGION] or {}
  -- 从旧归属地移除
  local old = storage[READER_REGION][unit]
  if old then
    local oldkey = region_key(old[1], old[2])
    local r = storage[REGIONS] and storage[REGIONS][oldkey]
    if r and r.readers then r.readers[unit] = nil end
  end
  -- 记入新归属地
  storage[READER_REGION][unit] = { rtype, id }
  local r = ensure_region(rtype, id)
  r.readers[unit] = true
end

M.network_id_at = network_id_at
M.reader_region_of = reader_region_of
M.reader_region_cached = reader_region_cached
M.reader_region_set = reader_region_set

return M
