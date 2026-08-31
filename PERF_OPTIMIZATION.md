# 虚影读取器（Ghost Reader）性能优化计划

## 一、现状与总体判断

实测 Mod 开销约为游戏本体的 10 倍以上，符合下述复杂度异常。核心问题集中在四个环节：

1. **`request_update()` 直接同步调用 `update()`** —— 每个离散事件（拆建、死亡、升级标记等）都在事件回调里当场跑一遍**全量重扫**。若一帧内多次事件，一帧内就执行多次全量 `update()`。
2. **`update()` 的重扫是"整表面 / 整网络"全量**，且缓存（`cache`）是**单次调用内的局部表**，不跨 tick 持久化。
3. **每 tick 的轮询**（`poll_irp_updates` / `poll_decon_snapshots`）对每个快照实体做**全表面 `find_entities_filtered`** 再算库存指纹，复杂度随快照数 × 实体数线性爆炸。
4. **`reader_network()` / `get_counts_network()`** 对每个 reader / 每个网络都**遍历整表面所有 roboport**。

---

## 二、逐场景复杂度分析

### 1. 大量无人机平台（roboport）
- **会出问题（线性×网络内扫描）**。
- `get_counts_network`：对每个 reader 遍历整表面所有 roboport（`find_entities_filtered{name="roboport"}`），逐个比对网络 ID。
- 平台越多，`update()` 每次全量扫就越慢；且**平台的建设区域（construction area）很大**，`scan_area` 在区域内再 `find_entities_filtered`（虚影/升级/拆除/IRP），成本与平台数 × 区域实体数成正比。
- **去重遍历**：`visited` 表已经避免重复计数，但扫描本身仍重复执行（同一实体落在多个重叠平台区域会被多次 `find` 命中，只是计数去重）。

### 2. 大量实体
- **会出问题**。`find_entities_filtered{area=...}` 本身按区域过滤是引擎加速的，但每次 `update()` 都重新扫一遍全部相关区域。实体越多，单次重扫越慢；当 `request_update` 高频触发时，放大明显。

### 3. 大量幽灵读取器（ghost-reader）
- **严重问题（二次方）**。
- `update()` 对每个 reader 调 `reader_network(reader)`，而它遍历整表面 roboport。→ 每个 reader 都做一遍 O(roboport数) 的扫描 → **O(reader数 × roboport数)**。
- `update()` 的 `cache` 虽按 `网络ID:filter:qty` 共享，但**共享仅限同一次 `update()` 调用内**，且 `reader_network_id` 的查找仍逐 reader 执行。

### 4. 大量移动实体（坦克/蜘蛛机甲等）
- **严重问题（每 tick 轮询）**。
- `poll_irp_updates`：对每个 IRP 快照，每 tick 做**整表面 `find_entities_filtered{type="item-request-proxy"}`** 再逐个比对 unit_number；还调用 `target_stock_fingerprint`（遍历最多 40 个库存）。
- 移动实体越多 → 快照越多 → 每 tick 成本线性增长，且移动触发 `mark_dirty` → 频繁全量 `update()`。

### 5. 同时产生大量虚影 / 标记大量拆除
- **严重问题（一帧内多次全量）**。
- 每个虚影建成（`on_entity_built`）、每次拆除标记（`on_decon_marked`）都调用 `request_update()` → **当场同步跑一次全量 `update()`**。
- 一次性摆 100 个蓝图 = 一帧内 100 次全量重扫，灾难性。

### 6. 建设无人机任务频繁完成
- **严重问题（每完成一个就全量重扫一次）**。
- `on_object_destroyed`、`on_robot_mined_entity`、`on_entity_died` 等每触发一次就 `request_update()` → 全量 `update()`。无人机集群完成一批任务时，一帧内重复几十上百次全量扫。

---

## 三、优化方向逐一核查

### 方向 1：是否存在大量重复计算（判断建设区域内）
**是，且很严重。**
- `reader_network` 对每个 reader 遍历全部 roboport。
- `get_counts_network` 对每个网络重复遍历 roboport + 在每个建设区域重复 `find_entities_filtered`。
- `update()` 每次调用都重建整表面统计，跨 tick 无缓存。
- **修复**：网络级扫描结果缓存到 `storage`，带指纹（fingerprint）判断，未变化不重扫。

### 方向 2：有没有单一物流网络 / 表面数据共享
**已部分实现，但仅限单次 update 调用内。**
- `update()` 的 `cache` 已按 `网络ID:filter:qty` 共享（同一网络的多个 reader 不重复扫）。✔
- **缺口**：缓存不跨 tick 持久化；`reader_network_id` 的查找仍逐 reader 执行。
- **修复**：把网络统计缓存到 `storage`（如 `storage.net_cache[网络ID] = {fp, counts}`），并**一次缓存网络→reader 归属**，避免重复 roboport 遍历。

### 方向 3：一帧内多次更新
**是，且是最大性能杀手。**
- `request_update()` 直接调 `update()`；`on_tick` 里又对 `storage.dirty` 再跑一次 `update()`。
- **修复**：事件回调**只置 `storage.dirty = true`，不再当场 update()**；由 `on_tick` 统一在每帧**至多执行一次** `update()` 消费 dirty 标记。这样一帧无论多少事件，全量重扫最多一次。

### 方向 4：是否实时跟踪了完全无关的实体
**是。**
- `poll_irp_updates` / `poll_decon_snapshots` 每 tick 对**所有快照**（无论是否在任一 reader 范围内）做全表面 `find_entities_filtered` + 库存指纹。
- **修复**：只跟踪"至少被一个 reader 的网络/表面覆盖"的实体；缩小轮询到相关区域；用 `game.get_surface().find_entities_filtered` 加位置/区域过滤，或改用 `script.register_on_object_destroyed` + 更轻的指纹。

---

## 四、分阶段优化计划

### 阶段 A：消除"一帧内多次全量更新"（最高收益，改动小）
1. `request_update()` 改为 **只置 `storage.dirty = true`**，去掉同步 `update()`。
2. `on_tick` 消费 dirty：`if storage.dirty then update(); storage.dirty=false end`（已有，保留）。
3. 所有离散事件回调统一走"标记 dirty"，由 on_tick 合并。
   - 注意：`on_tick` 在真实游戏中每 tick 都执行（headless 亦验证过），可安全依赖。
   - 影响：GUI 刷新也从 on_tick 统一触发，避免事件期多次刷新。

### 阶段 B：网络/表面统计持久化缓存 + 跨 reader 复用（次高收益）
1. 新增 `storage.net_cache`：`{ [网络ID] = { fp = fingerprint, counts = {supply, recycle} } }`。
2. `get_counts_network` 先查缓存指纹，未变化直接复用；`fp` 用轻量（数量合计 + 项名哈希）判断。
3. 表面模式同理用 `storage.surface_cache[surface_index:filter:qty]`。
4. 缓存失效策略：由 `mark_dirty`（事件驱动）清空相关网络缓存，而不是全量。

### 阶段 C：优化 reader_network / 网络归属查找（消除二次方）
1. 缓存"reader → 所属网络 ID"到 `storage.reader_net[unit]`，仅在 roboport 增删 / reader 移动时更新。
2. 或一次遍历 roboport 建立"网络 → roboport 列表"映射，避免每个 reader 各扫一遍。

### 阶段 D：精简每 tick 轮询（消除无关实体跟踪）
1. `poll_irp_updates` / `poll_decon_snapshots` 加**区域/位置过滤**：只轮询位于任一 reader 建设/表面范围内、或 reader 追踪的实体。
2. 用 `surface.find_entities_filtered{area=..., type="item-request-proxy"}` 直接按区域取，而非"整表面取后再逐个比对"。
3. 降低指纹成本：`target_stock_fingerprint` 只遍历存在的库存（跳过空库存），或对非容器实体跳过。
4. IRP 每 tick 只处理上限（已有 `IRP_POLL_PER_TICK=8`，保持/调优）。

### 阶段 E：扫描范围与 find 次数优化
1. `scan_area` 减少 `find_entities_filtered` 次数：一次 `find_entities_filtered{area, to_be_deconstructed=true}` 已包含部分，可合并条件。
2. 对重叠平台：考虑先合并同一网络的建设区域成"并集 bounding boxes"，减少重复 find。

---

## 五、建议优先级
1. **阶段 A（事件合并，一帧最多一次 update）** —— 收益最大、风险最低，优先做。
2. **阶段 B（持久化缓存）** —— 显著降低高频重扫成本。
3. **阶段 D（轮询精简）** —— 解决"大量实体/移动实体"场景。
4. **阶段 C（网络归属查找）** —— 解决"大量 reader"场景。
5. **阶段 E（find 次数）** —— 锦上添花。

每阶段完成后用 headless 基准（固定存档 + 统计 tick 耗时）对比验证，避免引入正确性回归。
