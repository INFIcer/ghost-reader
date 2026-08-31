-- dop/bvh.lua
--
-- 静态 BVH（Bounding Volume Hierarchy）—— 通用 2D 空间索引（纯 Lua，无 Factorio 依赖）。
--
-- 适用场景：多次重建 + 超高频率点查询（正是本 mod 网络归属地的使用模式：
-- 每次网络变动重建一次，之后对每个点做大量碰撞查询）。
--
-- 相比四叉树：
--   * 无需指定根范围（自图元包围盒自底向上构建，零配置、更精确）。
--   * 构建更简单高效：按最长轴对图元中心排序 + 二分分割，一次性完成；
--     对任意分布都均衡（按中心排序），不像四叉树固定象限在分布不均时深度失衡。
--   * 点查询同样 O(log n)，且命中即剪枝、缓存友好。
--
-- 约定：
--   * AABB 用 { x1, y1, x2, y2 }（闭区间，允许负坐标，精确浮点）。
--   * 接口仅两项：build(primitives) -> root；query(root, x, y) -> bool。
--     build 传入 AABB 列表（可共享引用，构建时复用不复制）；query 返回点是否落在
--     任一图元内（命中立即返回 true）。不需要 data / 数组 / 矩形查询。
--
-- 设计：封装良好、纯逻辑，不读写 storage / game，便于独立单测与复用。

local bvh = {}

-- 每个叶子节点最大图元数
local LEAF_SIZE = 4

-- =============================================================================
-- 内部工具
-- =============================================================================

-- 计算一组 AABB 的包围盒
local function compute_bbox(prims)
  local minx, miny = math.huge, math.huge
  local maxx, maxy = -math.huge, -math.huge
  for _, b in ipairs(prims) do
    if b.x1 < minx then minx = b.x1 end
    if b.y1 < miny then miny = b.y1 end
    if b.x2 > maxx then maxx = b.x2 end
    if b.y2 > maxy then maxy = b.y2 end
  end
  return { x1 = minx, y1 = miny, x2 = maxx, y2 = maxy }
end

-- 点是否在 AABB 内（闭区间，含边界）
local function point_in_box(box, x, y)
  return x >= box.x1 and x <= box.x2 and y >= box.y1 and y <= box.y2
end

-- 递归构建 BVH 节点
local function build_node(prims)
  local node = { bbox = compute_bbox(prims), leaf = false, left = nil, right = nil, primitives = nil }
  if #prims <= LEAF_SIZE then
    node.leaf = true
    node.primitives = prims   -- 叶子存储图元引用
    return node
  end
  -- 内部节点：按最长轴分割
  local dx = node.bbox.x2 - node.bbox.x1
  local dy = node.bbox.y2 - node.bbox.y1
  local axis = (dx >= dy) and "x" or "y"
  -- 按中心坐标排序（稳定的简单排序即可；构建期一次成本，可接受）
  table.sort(prims, function(a, b)
    local ca = (axis == "x") and (a.x1 + a.x2) * 0.5 or (a.y1 + a.y2) * 0.5
    local cb = (axis == "x") and (b.x1 + b.x2) * 0.5 or (b.y1 + b.y2) * 0.5
    return ca < cb
  end)
  -- 切分为两半
  local mid = math.floor(#prims / 2)
  local left, right = {}, {}
  for i = 1, mid do left[#left + 1] = prims[i] end
  for i = mid + 1, #prims do right[#right + 1] = prims[i] end
  node.left = build_node(left)
  node.right = build_node(right)
  return node
end

-- 递归点查询（命中即剪枝 + 返回 true）
local function query_node(node, x, y)
  if not node then return false end
  if not point_in_box(node.bbox, x, y) then return false end
  if node.leaf then
    for _, b in ipairs(node.primitives) do
      if point_in_box(b, x, y) then return true end
    end
    return false
  end
  if query_node(node.left, x, y) then return true end
  return query_node(node.right, x, y)
end

-- =============================================================================
-- 公开 API
-- =============================================================================

-- 构建 BVH。primitives: { {x1,y1,x2,y2}, ... }。空列表返回 nil。
function bvh.build(primitives)
  if not primitives or #primitives == 0 then return nil end
  return build_node(primitives)
end

-- 点碰撞查询：返回该点是否落在任一图元 AABB 内（bool）。
function bvh.query(root, x, y)
  if not root then return false end
  return query_node(root, x, y)
end

return bvh
