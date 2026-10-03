-- dop2/snapshot.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 指纹快照轮询。
--
-- 有些变化没有原生事件：实体被拖走、内部储存物被机器人逐步搬走、IRP 的请求被部分
-- 供应。这里用「快照 + 指纹」在 on_tick 里分批轮询（每 tick 只查 max_check 个，
-- round-robin），指纹变化时才做事：
--   * 内容物快照  物品计数用 counter，指纹变化即整体替换 'deconstruction-inventory'；
--   * 位置快照    实体所在格点，指纹变化即标该实体的归属地脏（可能进出建设区域）；
--   * IRP 快照    请求/回收明细各一个 counter，指纹变化即整体替换目标容器上的 'irpN'。
--
-- 快照创建时立刻跑一次 update（previous = nil），所以「创建即完成首次计数」：
-- 事件处理层只负责建快照，不需要自己写这些计数项。
--
-- 计数项更新与标脏由各 update 函数自己完成——只有它知道变化影响的是哪个 meta
-- （例如 IRP 的计数项记在目标容器上，要标脏的是目标容器）。

local changes = require("__ghost-reader__/dop2/changes")
local item = require("__ghost-reader__/dop2/item")
local meta = require("__ghost-reader__/dop2/meta")

---每 tick 最多检查的快照数（两个世代共用这一份预算）
local max_check = 8
---连续多少次无变化后转入不活跃世代（查得更稀）
local inactive_times = 30

---世代索引：活跃世代优先用预算，不活跃世代只在预算有剩时才轮到
local ACTIVE = 1
local INACTIVE = 2

---@class snapshot
---@field entity LuaEntity
---@field update_mod fun(entity: LuaEntity, previous: string|nil): string 更新函数：返回指纹，变化时自行更新计数项/标脏
---@field snaps string 上一次的指纹
---@field checks int 连续无变化的次数
---@field dead boolean? 已移除（惰性删除：标死后由队列游标跳过，不再检查）
local snapshot = {}

---@class snapshot_queue 一个世代的三表轮转队列
---@field todo table<snapshot> 本轮未查（待查队列）
---@field curr table<snapshot> 本轮已查
---@field prev table<snapshot> 上轮已查（本轮未查清空后由它接上）
---@field head int 待查队列的游标：下一个要查的下标（1 起）
---@type snapshot_queue[]
local queues = {
    --ACTIVE：查得密
    { todo = {}, curr = {}, prev = {}, head = 1 },
    --INACTIVE：查得稀
    { todo = {}, curr = {}, prev = {}, head = 1 },
}

--================================================================================================
-- 指纹
--================================================================================================

---把计数器压成稳定的指纹字符串（键排序后拼接）。
---计数与指纹同源（都来自同一个 counter），故指纹变了就等于计数变了。
---@param c counter
---@return string
local function counter_fingerprint(c)
    local parts = {}
    for item_prototype, quality_counts in pairs(c) do
        for quality, count in pairs(quality_counts) do
            --键就是物品名与品质名
            parts[#parts + 1] = item_prototype .. ":" .. quality .. "=" .. tostring(count)
        end
    end
    table.sort(parts)
    return table.concat(parts, ";")
end

---位置指纹。用格点而非浮点：进出建设区域只取决于所在格点，
---同格内微移不应触发归属地重算。
---@param position MapPosition
---@return string
local function position_fingerprint(position)
    return tostring(math.floor(position.x)) .. "," .. tostring(math.floor(position.y))
end

--================================================================================================
-- 快照更新函数
--================================================================================================

---内容物快照：把实体内部存储里的物品（库存/传送带货物/机械臂手持物）
---算成一个 counter，指纹变化时整体替换 'deconstruction-inventory'。
---只跟踪"有内部存储"的实体：环境实体/落地物品是瞬间拆除的，标记时已一次算清，
---不需要（也不该）建快照。
---@param entity LuaEntity
---@param previous string|nil
---@return string
local function update_inventories(entity, previous)
    local contents = item.inventory_contents(entity)
    local fingerprint = counter_fingerprint(contents)
    if fingerprint ~= previous then
        meta.ensure_entity_meta(entity):replace_count_item(COUNT_DECON_INVENTORY, change_type.ITEM_RECYCLE, contents)
    end
    return fingerprint
end

---位置快照：指纹变化说明实体换格了（可能进出建设区域），标该实体归属地脏
---@param entity LuaEntity
---@param previous string|nil
---@return string
local function update_pos(entity, previous)
    local fingerprint = position_fingerprint(entity.position)
    if fingerprint ~= previous then
        changes.dirty_count_entitiy_region(meta.ensure_entity_meta(entity))
    end
    return fingerprint
end

---IRP 快照：把 IRP 当前的请求（供给）与回收明细各算成一个 counter，
---指纹变化时整体替换目标容器上的 'irpN' 计数项。
---计数项记在目标容器上：IRP 自身没有归属地，容器被拖走由容器自己的位置快照负责。
---@param irp LuaEntity
---@param previous string|nil
---@return string
local function update_irp(irp, previous)
    local requests = item.irp_requests(irp)
    local removals = item.irp_removals(irp)
    local fingerprint = counter_fingerprint(requests) .. "|" .. counter_fingerprint(removals)
    if fingerprint ~= previous then
        local irp_meta = meta.get_meta_of(irp)
        local target = irp.proxy_target --请求容器实体
        if irp_meta and target and target.valid then
            local m = meta.ensure_entity_meta(target)
            local ci = m:get_count_item(COUNT_IRP_PREFIX .. tostring(irp_meta.reg_num))
            ci:replace(change_type.ITEM_SUPPLY, requests)
            ci:replace(change_type.ITEM_RECYCLE, removals)
            changes.dirty_count_entitiy_output(m)
        end
    end
    return fingerprint
end

---检查一个快照并更新指纹
---@param ss snapshot
local function check(ss)
    if not (ss.entity and ss.entity.valid) then return end
    local new = ss.update_mod(ss.entity, ss.snaps)
    if ss.snaps ~= new then
        ss.snaps = new
        --有变化：checks 归零，随后会被放回活跃世代
        ss.checks = 0
    else
        ss.checks = ss.checks + 1
    end
end

---把刚查完的快照放回队列：有变化(checks=0)回活跃世代，久无变化(checks 达标)转不活跃
---世代，否则留在本世代——世代只决定它被轮到的密度。
---@param queue snapshot_queue 快照原来所在的队列
---@param ss snapshot
local function requeue(queue, ss)
    if ss.checks == 0 then
        table.insert(queues[ACTIVE].curr, ss)
    elseif ss.checks >= inactive_times then
        table.insert(queues[INACTIVE].curr, ss)
    else
        table.insert(queue.curr, ss)
    end
end

---跑一个世代的队列，返回剩余预算。每代内部是「上轮已查 / 本轮已查 / 本轮未查」三组轮转：
---  1. 从 todo 取一个查完移入 curr；
---  2. todo 走完 -> prev 提升为本轮待查（本帧已查完的那张表就此作废，另起一张空的承接本轮结果）；
---  3. 本帧检查结束 -> 把 curr 单向并入 prev（单向传递），让本轮查过的成为下一轮的"上轮"。
---之所以能保证「一个快照一帧最多检查一次」：进入 todo 的来源只有 prev，而 prev 只在
---第 3 步（本世代本帧的检查全部结束之后）才被本轮结果填充；查完的快照只进 curr，本帧
---不会再回到 todo。因此同一帧里不存在重复检查。
---
---待查队列用游标（queue.head）推进，不用 table.remove(todo, 1)：
---后者每查一个快照都要把整表后面的元素前移一格，而 todo 长度在轮转中周期性起伏，
---于是每帧都要做 O(队列长度) 的搬移，且随队列长度变化表现为周期性的卡顿。
---游标推进后每帧只剩「查几个快照」这点固定开销，与本代快照总数无关（走完一轮才轮转一次，
---代价是每轮一次空表分配，可以忽略）。
---@param queue snapshot_queue
---@param budget int
---@return int budget 剩余预算
local function run_queue(queue, budget)
    local todo = queue.todo
    local head = queue.head
    local total = #todo
    while budget > 0 do
        if head > total then
            --本轮待查的已走完：prev 提升为待查；本帧已查完的那张表作废，另起空表承接
            if #queue.prev == 0 then break end
            queue.todo = queue.prev
            queue.prev = {}
            todo = queue.todo
            head = 1
            total = #todo
        end
        local ss = todo[head]
        head = head + 1
        --已标记删除的快照直接跳过：不检查、不占预算、也不再入队（槽位随轮转整表丢弃时释放）
        if not ss.dead then
            check(ss)
            requeue(queue, ss)
            budget = budget - 1
        end
    end
    queue.head = head
    --本帧检查结束：本轮检查的单向并入上一轮检查的（单向传递，不是交换），
    --本轮顺势清空——同一张表原地复用，不必每帧新建
    local curr = queue.curr
    for i = 1, #curr do
        local ss = curr[i]
        curr[i] = nil
        if not ss.dead then
            queue.prev[#queue.prev + 1] = ss
        end
    end
    return budget
end

---运行一轮检查：两个世代共用一份预算，活跃世代优先
local function on_tick()
    local budget = max_check
    for _, queue in ipairs(queues) do
        budget = run_queue(queue, budget)
    end
end

--================================================================================================
-- 模块对外暴露部分
--================================================================================================

local M = {}

---@param entity LuaEntity
---@param update_mod fun(entity: LuaEntity, previous: string|nil): string
---@return snapshot
function snapshot:new(entity, update_mod)
    local obj = {}
    obj.entity = entity
    obj.update_mod = update_mod
    obj.checks = 0
    setmetatable(obj, { __index = self })
    --创建时先跑一次（previous 为 nil）：创建即完成首次计数
    obj.snaps = update_mod(entity, nil)
    return obj
end

---内容物快照（拆除/库存变化跟踪）
---@param entity LuaEntity
---@return snapshot
function M.add_inventory_snapshot(entity)
    local ss = snapshot:new(entity, update_inventories)
    table.insert(queues[ACTIVE].todo, ss)
    return ss
end

---位置快照（实体移动跟踪）
---@param entity LuaEntity
---@return snapshot
function M.add_tilepos_snapshot(entity)
    local ss = snapshot:new(entity, update_pos)
    table.insert(queues[ACTIVE].todo, ss)
    return ss
end

---IRP 快照（请求/回收明细变化跟踪）
---@param irp LuaEntity
---@return snapshot
function M.add_irp_snapshot(irp)
    local ss = snapshot:new(irp, update_irp)
    table.insert(queues[ACTIVE].todo, ss)
    return ss
end

---标记一个快照为已移除（惰性删除）。
---销毁/取消拆除常常成批到来（机器人建完或搬完一批实体、整片区域取消拆除），
---若每次都去队列里全表扫描找对象（还要顺带搬移数组元素），批量时就会周期性卡一下。
---这里只标死：队列游标扫到就跳过，槽位随轮转整表丢弃时自然释放，删除成本恒为 O(1)。
---@param ss snapshot
function M.remove_snapshot(ss)
    ss.dead = true
end

---清空所有快照（全量重建时用）。快照依附实体，会随世界状态重新建立。
function M.reset()
    for _, queue in ipairs(queues) do
        queue.todo = {}
        queue.curr = {}
        queue.prev = {}
        queue.head = 1
    end
end

M.on_tick = on_tick
return M
