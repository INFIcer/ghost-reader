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
local READER_BY_UNIT = constants.READER_BY_UNIT

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

-- 注册 unit→reader 实体映射（创建时调用，不涉及归属）。供需要实体时 O(1) 反查，
-- 替代 find_entities_filtered。虚影 reader（entity-ghost ghost_name==READER）也注册，
-- 以便 GUI 打开虚影时能反查到。
local function reader_register(reader)
  if not (reader and reader.valid and reader.unit_number) then return end
  storage[READER_BY_UNIT] = storage[READER_BY_UNIT] or {}
  storage[READER_BY_UNIT][reader.unit_number] = reader
end

-- 取读取器当前归属地（rtype, id）。
-- 业务数据用 unit 作 key（稳定、可序列化、销毁清理简单），由 reader_region_set 在归属阶段
-- 写入。无缓存时退回即时计算：优先用传入的 reader；否则查 READER_BY_UNIT 映射表拿实体。
local function reader_region_cached(unit, reader)
  local reg = storage[READER_REGION] and storage[READER_REGION][unit]
  if reg then return reg[1], reg[2] end
  if not reader and unit then
    reader = storage[READER_BY_UNIT] and storage[READER_BY_UNIT][unit]
  end
  if reader and reader.valid then
    return reader_region_of(reader)
  end
  return nil, nil
end

-- 把读取器加入某归属地（更新元信息的 readers 列表 + 归属表）。
-- 业务数据用 unit 作 key；同时维护 unit→reader 实体映射表 READER_BY_UNIT（创建/归属时
-- 两者都在，注册之），供需要实体时 O(1) 反查，避免 find。
local function reader_region_set(reader, rtype, id)
  if not reader then return end
  local unit = reader.unit_number
  storage[READER_REGION] = storage[READER_REGION] or {}
  storage[READER_BY_UNIT] = storage[READER_BY_UNIT] or {}
  storage[READER_BY_UNIT][unit] = reader
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

-- 移除读取器归属（销毁/被挖时调用）。事件提供 unit，直接删 unit 作 key 的业务数据，
-- 并清理 unit→reader 映射表。
local function reader_region_remove(unit)
  if not unit then return end
  storage[READER_BY_UNIT] = storage[READER_BY_UNIT] or {}
  storage[READER_BY_UNIT][unit] = nil
  storage[READER_REGION] = storage[READER_REGION] or {}
  local reg = storage[READER_REGION][unit]
  if reg then
    local oldkey = region_key(reg[1], reg[2])
    local r = storage[REGIONS] and storage[REGIONS][oldkey]
    if r and r.readers then r.readers[unit] = nil end
  end
  storage[READER_REGION][unit] = nil
end

M.network_id_at = network_id_at
M.reader_region_of = reader_region_of
M.reader_register = reader_register
M.reader_region_cached = reader_region_cached
M.reader_region_set = reader_region_set
M.reader_region_remove = reader_region_remove

return M
