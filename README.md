# Ghost Reader（虚影读取器）

**版本 1.1.0** · 适用于 Factorio 2.1（含太空时代）

一个原版恒压器（constant-combinator）风格的自定义实体，带自定义 GUI 面板。它读取所在表面或所在物流网络范围内的**建筑|地格|升级|临时物品请求**，并按物品把所需数量输出为原版电路信号。

---

# 面向普通玩家

## 这个 Mod 是做什么的

建造大型蓝图时，虚影（ghost）会告诉你「还缺哪些材料」。Ghost Reader 把这些虚影汇总成一个清晰的物品清单，并作为电路信号输出，方便你自动化计算缺料、驱动显示面板或物流请求。

它读取四类请求并合并计数：

| 类型 | 说明 |
| ---- | ---- |
| 建筑 | 蓝图/远程放置的待建建筑（entity ghost） |
| 地格 | 待铺的地形（tile ghost） |
| 升级 | 标记要升级成别的实体的建筑（upgrade） |
| 临时物品请求 | 远程视图下在储物格上放置的幽灵物品（item-request-proxy） |

## 如何解锁

- 研究科技「虚影读取器」（前置科技：**建设机器人**）。

## 如何使用

1. 放置一个「虚影读取器」。
2. 把它用红/绿线接入电路网络。
3. 在读取器上点击打开 GUI 面板，设置扫描范围和筛选模式。
4. 电路网络里就会出现各物品的信号，信号值 = 该物品当前所需数量。

## GUI 面板说明

- **检索范围模式**
  - `表面`：扫描整个星球表面上的全部虚影。
  - `物流网络`：只扫描读取器所在的物流网络（建设区域）内的虚影。
- **当前范围**：实时显示当前生效的范围。
  - 表面模式：显示所在地，如 `【新地星】`。
  - 物流网络模式：显示 `【网络#id】`。
- **筛选模式**
  - `全部`：建筑 + 地格 + 升级 + 临时物品请求。
  - `建筑`：只计建筑虚影。
  - `地格`：只计地格虚影。
  - `升级`：只计升级虚影。
  - `临时物品请求`：只计临时物品请求。
- **当前输出信号**：实时列出当前将要输出的各物品信号与数量。

## 范围细节（重要）

- **物流网络模式**下，虚影和临时物品请求都按各无人机平台（roboport）的**建设区域**（绿色区域）的**并集**计算。因为只有实体的中心点落入建设区域内才能被建设机器人响应，所以判断落入建设区域的条件也与之保持一致。
- **物流网络模式**下，读取器自身必须位于某个无人机平台的**供应区域**（橙色区域）内，才能被判定为「属于某个物流网络」。
- 移动实体（坦克、蜘蛛机甲）上的临时物品请求同样会被计入。

---

# 面向 Mod 开发者

## 概述

本 Mod 的核心是一个复制原版 `constant-combinator` 而来的自定义实体 `ghost-reader`。它在 `data.lua` 中通过深拷贝原版恒压器原型、重定向贴图到本 mod 目录，并注册对应的物品 / 配方 / 科技。

运行时（`control.lua`）扫描建筑|地格|升级|临时物品请求，按物品聚合数量，再通过实体的**恒压器控制行为**（`LuaConstantCombinatorControlBehavior`）把每个物品信号写入插槽。

## 2.1 的关键 API 约束（本 Mod 的处理方式）

1. **恒压器输出**：Factorio 2.1 中 `LuaCircuitNetwork` 是只读的（无 `write_signal`/`set_signal`），所以输出必须走恒压器控制行为：
   - `cb = entity.get_or_create_control_behavior()`
   - `section = cb.get_section(1) or cb.add_section("")`
   - `section.set_slot(i, { value = { type = "item", name = item, quality = "normal" }, min = count })`
   - 清除用 `section.filters = {}`。
2. **范围 / 半径**：`LuaEntity.get_construction_area()` 与 `get_logistic_network()` 在 2.1 已移除。改用：
   - `port.prototype.construction_radius`（建设半径，默认 55，方形）。
   - `port.prototype.logistic_radius`（补给半径，默认 25，方形）。
   - `port.logistic_network` 属性读取物流网络。
   - 方形判断：`math.abs(dx) <= r and math.abs(dy) <= r`。
3. **无人机平台查找**：`game.get_entity_by_unit_number` 对 roboport 返回 nil，因此用 `surface.find_entities_filtered{ name = "roboport" }` 枚举所有端口。

## 临时物品请求（item-request-proxy）的实现

### 发现（data-updates.lua）

原版 `item-request-proxy` 实体默认不可由脚本遍历得知其创建。`data-updates.lua` 内联了社区手法（参考 `item-request-proxy-events`，**无外部依赖**）：

```lua
data.raw["item-request-proxy"]["item-request-proxy"].created_effect = {
  type = "direct",
  action_delivery = {{
    type = "instant",
    source_effects = {{
      type = "script",
      effect_id = "gr-item-request-proxy"
    }}
  }}
}
```

这样每次 IRP 创建都会触发 `on_script_trigger_effect`（`effect_id == "gr-item-request-proxy"`）。`control.lua` 监听该事件以事件驱动地发现新临时请求，并对该实体调用 `script.register_on_object_destroyed` 以便销毁时也能触发重扫，无需 on_tick 全图轮询。

### 读取（control.lua 的 `scan_irp`）

临时请求的物品通过 `entity.item_requests` 读取，它是一个 `{ name, quality, count }` 数组。遍历求和即可得到各物品的所需数量：

```lua
local reqs = irp.item_requests
for _, r in ipairs(reqs) do
  counts[r.name] = (counts[r.name] or 0) + (r.count or 1)
end
```

## 扫描与网络归属（control.lua）

- `reader_network(reader)`：枚举所有 roboport，判断读取器是否落在某端口的**供应方形**内，是则返回 `port.logistic_network`。
- `get_counts_network(reader, filter)`：先取读取器网络 id，再枚举同网络的每个端口，对每个端口的**建设方形**：
  - `scan_area(...)`：建筑 / 地格 / 升级虚影。
  - `scan_irp(...)`：临时物品请求（同样按建设方形）。
  - 用 `visited`（按 `unit_number`）去重跨端口重叠的虚影。
- `center_in_area(pos, area)`：只有当虚影**中心点**落入方形内才计入（与游戏判定可建造的方式一致）。

## 更新策略

- **事件驱动为主**：虚影 / IRP 创建、销毁、升级标记、无人机平台增删都会调用 `mark_dirty()`，在下一个 on_tick 统一 `update()` 重扫并刷新信号，避免逐帧轮询。
- **实时 GUI**：`refresh_all_open_gui()` 在每个 `game.tick % 30 == 0` 时刷新所有打开的 GUI 面板。
- `update()` 对相同表面+网络+筛选组合做缓存，避免多个读取器重复扫描同一范围。

## 文件结构

```
ghost-reader/
├── info.json            # Mod 元数据（name=ghost-reader, version=1.1.0）
├── data.lua             # 实体/物品/配方/科技 + 贴图重定向（深拷贝原版恒压器）
├── data-updates.lua     # 给 item-request-proxy 加 created_effect
├── control.lua          # 扫描、IRP 读取、信号输出、GUI、事件处理
├── graphics/            # 复制的原版贴图与图标（不引用 __base__）
├── locale/en|zh-CN/     # 本地化
└── thumbnail.png
```

## 解谜顺序

- 科技解锁由 `data.lua` 的原生 `research_trigger = { type="craft-item", item="roboport", count=1 }` 完成，`control.lua` 无需任何代码。
