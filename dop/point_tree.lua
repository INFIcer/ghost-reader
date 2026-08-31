-- dop/point_tree.lua
--
-- 点集合多层级包围盒树（Point Tree）—— 纯 Lua，无 Factorio 依赖。
--
-- 适用场景：一帧内有一批点（如批量新增虚影/标记产生的 count_changes 点），需要判断
-- 每个点落在哪些网络建设区域内。若对每个点单独遍历所有网络，代价 O(N×网络数)。
--
-- 本模块把这些点构建成**多层级包围盒树**（二分思想）：
--   * 根节点包围盒 = 全部点的包围盒；
--   * 按最长轴把点集分成两半，各算子包围盒，递归细分，直到某层点足够少（叶子）。
-- 查询时给定一个网络 bbox，从根节点逐层筛选：
--   * 若网络 bbox 与节点包围盒不相交 → 整棵子树都不可能命中，直接剪枝；
--   * 相交则下探子节点，逐层递减筛选压力；
--   * 直到叶子仍未筛掉 → 对叶子内每个点做精确点碰撞。
-- 这样每个网络只需与树的一小部分路径相交，避免"每批点遍历所有网络"或"每点遍历所有网络"。
--
-- 约定：
--   * 点用 { x = , y = }（精确浮点）。
--   * 构建：build(points) -> root（points 为数组，元素 {x,y}）。
--   * 查询：query(root, box, hit_fn)，box={x1,y1,x2,y2}；对每个命中（点在 box 内）的
--     点索引调用 hit_fn(point_index)。命中即回调，不返回数组（省分配）。

local point_tree = {}

-- 叶子最大点数（不再细分）
local LEAF_SIZE = 8

-- =============================================================================
-- 内部工具
-- =============================================================================

-- 计算一批点的包围盒（就地写回 box）
local function compute_bbox(points, lo, hi, box)
  local minx, miny, maxx, maxy = math.huge, math.huge, -math.huge, -math.huge
  for i = lo, hi do
    local p = points[i]
    local x, y = p.x, p.y
    if x < minx then minx = x end
    if y < miny then miny = y end
    if x > maxx then maxx = x end
    if y > maxy then maxy = y end
  end
  box.x1, box.y1, box.x2, box.y2 = minx, miny, maxx, maxy
end

-- 递归构建：对 points[lo..hi] 建树（原地切分，lo/hi 为索引闭区间）
local function build_node(points, lo, hi, box)
  compute_bbox(points, lo, hi, box)
  local node = { bbox = { x1 = box.x1, y1 = box.y1, x2 = box.x2, y2 = box.y2 } }
  local count = hi - lo + 1
  if count <= LEAF_SIZE then
    node.leaf = true
    node.lo, node.hi = lo, hi   -- 指向 points 数组区间
    return node
  end
  -- 按最长轴中点切分（避免对点排序；用快排式划分）
  local dx = box.x2 - box.x1
  local dy = box.y2 - box.y1
  local axis = (dx >= dy) and "x" or "y"
  local mid = (axis == "x") and (box.x1 + box.x2) * 0.5 or (box.y1 + box.y2) * 0.5
  -- 划分：把 <=mid 的放左，>mid 的放右（用交换法，O(n) 单次）
  local l, r = lo, hi
  while l <= r do
    while l <= hi and ((axis == "x" and points[l].x <= mid) or (axis == "y" and points[l].y <= mid)) do l = l + 1 end
    while r >= lo and ((axis == "x" and points[r].x > mid) or (axis == "y" and points[r].y > mid)) do r = r - 1 end
    if l < r then
      points[l], points[r] = points[r], points[l]
      l = l + 1
      r = r - 1
    end
  end
  -- 若划分失败（所有点同侧，如全相等坐标），退化为简单对半切分
  local split = l
  if split <= lo or split > hi then split = lo + math.floor(count / 2) end
  node.left = build_node(points, lo, split - 1, {})
  node.right = build_node(points, split, hi, {})
  return node
end

-- 递归查询：节点 bbox 与 query box 相交时下探；叶子对每个点做精确碰撞
local function query_node(node, box, points, hit_fn)
  local nb = node.bbox
  -- 相交判定（闭区间）
  if box.x1 > nb.x2 or box.x2 < nb.x1 or box.y1 > nb.y2 or box.y2 < nb.y1 then
    return
  end
  if node.leaf then
    for i = node.lo, node.hi do
      local p = points[i]
      if p.x >= box.x1 and p.x <= box.x2 and p.y >= box.y1 and p.y <= box.y2 then
        hit_fn(i)
      end
    end
    return
  end
  query_node(node.left, box, points, hit_fn)
  query_node(node.right, box, points, hit_fn)
end

-- =============================================================================
-- 公开 API
-- =============================================================================

-- 构建点树。points: { {x=,y=}, ... }（构建会原地重排数组，若需保序请传入副本）。
function point_tree.build(points)
  if not points or #points == 0 then return nil end
  return build_node(points, 1, #points, {})
end

-- 查询：对每个落在 box 内的点调用 hit_fn(索引)。root 可为 nil（空集）。
function point_tree.query(root, box, points, hit_fn)
  if not root or not points or not hit_fn then return end
  query_node(root, box, points, hit_fn)
end

return point_tree
