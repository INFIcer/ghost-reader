-- dop/regions.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 归属地元信息 + 碰撞检测。
--
-- 归属地 = 一个表面（surface），或一个物流网络（logistics network）。
-- 每个归属地对应一份元信息，集中存放统计结果，供所有读取该归属地的幽灵
-- 读取器复用，避免每个读取器各自全量扫描一遍。
--
-- 元信息字段：
--   type     : REGION_SURFACE | REGION_NETWORK
--   id       : 表面用 surface.index；物流网络用 network_id（可为 nil，表示不在网）
--   readers  : { [unit] = true }  归属该归属地的幽灵读取器
--   counts   : { supply = { [item]=n }, recycle = { [item]=n } }
--   以下仅网络模式有效：
--   bbox     : { x1, y1, x2, y2 }  所有平台建设区域并集的包围盒
--   ports    : { [port_unit] = { x, y, crad } }  归属该网络的无人机平台列表
--   bvh      : 静态 BVH（把各平台建设区域建成索引，点碰撞 O(log n)）
--
-- 网络归属地的点碰撞用静态 BVH：每次网络变动（平台增删）重建一次，之后对大量
-- 点做碰撞查询，正好匹配 BVH "多次重建 + 超高频率点查询" 的适用场景。

local constants = require("__ghost-reader__/dop/constants")
local bvh = require("__ghost-reader__/dop/bvh")
local M = {}

local REGION_SURFACE = constants.REGION_SURFACE
local REGION_NETWORK = constants.REGION_NETWORK
local REGIONS = constants.REGIONS

-- 归属地 key 生成
local function region_key(rtype, id)
  if rtype == REGION_SURFACE then
    return "s:" .. tostring(id)
  end
  return "n:" .. tostring(id or "nil")
end

-- 取归属地元信息（不存在则创建一份空元信息）
local function ensure_region(rtype, id)
  storage[REGIONS] = storage[REGIONS] or {}
  local key = region_key(rtype, id)
  local r = storage[REGIONS][key]
  if not r then
    r = {
      type = rtype,
      id = id,
      readers = {},
      -- 按类别细分的计数：supply[category] / recycle[category]，category ∈
      -- {entity, tiles, upgrades, items}。支持读取器按 filter 选择类别输出。
      counts = {
        supply  = { entity = {}, tiles = {}, upgrades = {}, items = {} },
        recycle = { entity = {}, tiles = {}, upgrades = {}, items = {} },
      },
      bbox = nil,
      ports = {},
      bvh = nil,   -- 静态 BVH（仅网络归属地用；每次网络变动重建）
    }
    storage[REGIONS][key] = r
  end
  return r
end

-- 删除归属地元信息
local function remove_region(rtype, id)
  storage[REGIONS] = storage[REGIONS] or {}
  storage[REGIONS][region_key(rtype, id)] = nil
end

-- 为网络归属地重建静态 BVH：把每个平台的建设区域（正方形 AABB）作为图元。
-- 每次网络变动（平台增删/扩缩）后调用。
local function rebuild_region_tree(r)
  r.bvh = nil
  if r.type ~= REGION_NETWORK then return end
  local prims = {}
  for _, port in pairs(r.ports) do
    local crad = port.crad
    if crad then
      prims[#prims + 1] = {
        x1 = port.x - crad, y1 = port.y - crad,
        x2 = port.x + crad, y2 = port.y + crad,
      }
    end
  end
  r.bvh = bvh.build(prims)
end

-- 判断一个点是否落在某归属地的建设范围内。
--   surface 归属地：整表面都在范围内。
--   network 归属地：用静态 BVH 做点碰撞查询（O(log n)）。
local function region_contains(r, pos)
  if r.type == REGION_SURFACE then
    return true
  end
  return bvh.query(r.bvh, pos.x, pos.y)
end

-- 判断一个点是否落在某个网络建设范围 BVH 内（用于网络范围变化时判断新旧归属）。
-- tree 为 r.bvh（可为 nil，此时返回 false）。
local function bvh_contains(tree, x, y)
  if not tree then return false end
  return bvh.query(tree, x, y)
end

-- 取网络归属地的当前建设范围 BVH（用于保存变化前快照，供增量重扫 diff 用）。
local function region_get_bvh(r)
  return r.bvh
end

-- 记录一个网络归属地的包围盒：所有平台建设区域的并集（外接矩形）。
-- 同时重建该网络归属地的静态 BVH（网络变动时）。
local function update_region_bbox(r)
  local x1, y1, x2, y2 = nil, nil, nil, nil
  for _, port in pairs(r.ports) do
    local px, py, crad = port.x, port.y, port.crad
    if crad then
      local a, b, c, d = px - crad, py - crad, px + crad, py + crad
      if not x1 or a < x1 then x1 = a end
      if not y1 or b < y1 then y1 = b end
      if not x2 or c > x2 then x2 = c end
      if not y2 or d > y2 then y2 = d end
    end
  end
  if x1 then r.bbox = { x1, y1, x2, y2 } else r.bbox = nil end
  rebuild_region_tree(r)
end

-- 命中：一个位置点，落入的归属地集合（写回 out[key] = true）。
-- 先按表面归属地（表面模式下点总在范围内），再遍历网络归属地用 BVH 做点碰撞。
local function hit_regions_by_point(point, out)
  local surface_index = point.surface_index
  out[region_key(REGION_SURFACE, surface_index)] = true
  storage[REGIONS] = storage[REGIONS] or {}
  for key, r in pairs(storage[REGIONS]) do
    if r.type == REGION_NETWORK then
      if region_contains(r, point) then
        out[key] = true
      end
    end
  end
  return out
end

M.region_key = region_key
M.ensure_region = ensure_region
M.remove_region = remove_region
M.rebuild_region_tree = rebuild_region_tree
M.update_region_bbox = update_region_bbox
M.region_contains = region_contains
M.bvh_contains = bvh_contains
M.region_get_bvh = region_get_bvh
M.hit_regions_by_point = hit_regions_by_point

return M

