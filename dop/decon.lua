-- dop/decon.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 拆除标记的移动实体轮询。
--
-- 类比 dop/irp.lua：拆除标记的移动/含内容物实体（列车车厢被拖走、机械臂/传送带/
-- 容器被机器人逐步搬走内容物）没有原生事件，需要 on_tick 每帧对比位置与内容物指纹，
-- 变化时做增量撤销/重加（回收计数随内容物减少而减少）。
--
-- 快照存实体引用（借鉴 item-request-proxy-events），轮询直接用引用访问，不 find、
-- 不 get_entity_by_unit_number（后者对普通实体不可靠）。每帧只轮询
-- DECON_POLL_PER_TICK 个快照（round-robin 游标），成本 O(budget)。

local constants = require("__ghost-reader__/dop/constants")
local changes = require("__ghost-reader__/dop/changes")
local items = require("__ghost-reader__/dop/items")
local events_mod = require("__ghost-reader__/dop/events")
local M = {}

local CHG_ITEM_RECYCLE = constants.CHG_ITEM_RECYCLE
local CHG_ENTITY_RECYCLE = constants.CHG_ENTITY_RECYCLE
local DECON_MOVERS = constants.DECON_MOVERS
local DECON_POLL_PER_TICK = constants.DECON_POLL_PER_TICK
local DECON_POLL_INDEX = constants.DECON_POLL_INDEX
local tile_pos = constants.tile_pos

local add_count_change = changes.add_count_change
local item_for_entity = items.item_for_entity
local content_items = events_mod.content_items
local meta_set_items = events_mod.meta_set_items
local meta_set_position = events_mod.meta_set_position

-- on_tick 最前：轮询少量被标记拆除的移动实体，检测位置/内容物指纹变化。
-- mark_pending 由调用方（main 的 on_tick）在登记后置位。
-- 采用"key 快照数组 + 起始索引"分批遍历（round-robin），遍历中可安全删除快照，
-- 不会因 next() 的 prev 失效而报错（invalid key to 'next'）。
local function poll_decon_movers(mark_pending)
  local snaps = storage[DECON_MOVERS]
  if not snaps or not next(snaps) then return end

  local budget = DECON_POLL_PER_TICK
  local index_key = DECON_POLL_INDEX

  -- round-robin：从游标开始，用 next() 顺序取 budget 个 key（到尾绕回开头）。
  -- 收集用局部数组，避免遍历中删除快照导致 next() 的 prev 失效。
  local units = {}
  local start = storage[index_key]
  -- 游标可能指向已删除的快照（取消/移除/重建），无效则从头开始
  if start ~= nil and snaps[start] == nil then start = nil; storage[index_key] = nil end
  local prev = start
  local guard = 0
  while #units < budget do
    guard = guard + 1
    if guard > budget * 2 + 2 then break end   -- 防死循环（表很小或已被改）
    local k = next(snaps, prev)
    if k == nil then
      if prev == nil then break end            -- 整个表已遍历完（无绕回对象）
      prev = nil                                -- 绕回表头
    else
      units[#units + 1] = k
      prev = k
      storage[index_key] = k
      if k == start then break end              -- 已绕回一圈
    end
  end
  if #units == 0 then storage[index_key] = nil end

  for _, unit in ipairs(units) do
    local data = snaps[unit]
    if data then
      -- 用快照里存的实体引用（借鉴 item-request-proxy-events），不 find。
      -- 引用失效（valid=false 或已取消拆除）即清理快照。
      local ent = data.entity
      if ent and ent.valid and ent.to_be_deconstructed and ent.position then
        local t = tile_pos(ent.position)
        local ot = tile_pos(data)
        local moved = data.movable and ((t.x ~= ot.x) or (t.y ~= ot.y))
        local old_items = data.stock or {}
        local new_items = content_items(ent)
        local function fp(tbl)
          local p = {}
          for k, v in pairs(tbl) do p[#p + 1] = tostring(k) .. ":" .. tostring(v) end
          table.sort(p)
          return table.concat(p, ";")
        end
        local stock_changed = (fp(old_items) ~= fp(new_items))
        if moved or stock_changed then
          local si = ent.surface.index
          for item, n in pairs(old_items) do
            add_count_change(CHG_ITEM_RECYCLE, data.surface_index, data.x, data.y, item, -n)
          end
          for item, n in pairs(new_items) do
            add_count_change(CHG_ITEM_RECYCLE, si, ent.position.x, ent.position.y, item, n)
          end
          local ent_item = item_for_entity(ent.name)
          if ent_item then
            add_count_change(CHG_ENTITY_RECYCLE, data.surface_index, data.x, data.y, ent_item, -1)
            add_count_change(CHG_ENTITY_RECYCLE, si, ent.position.x, ent.position.y, ent_item, 1)
          end
          data.surface_index = si
          data.x = ent.position.x
          data.y = ent.position.y
          data.stock = new_items
          if unit then meta_set_items("u:" .. tostring(unit), new_items) end
          if moved and unit then
            meta_set_position("u:" .. tostring(unit), si, ent.position.x, ent.position.y)
          end
          if mark_pending then mark_pending() end
        end
      else
        snaps[unit] = nil -- 已取消/已移除/引用失效
      end
    end
  end
  if #units == 0 then storage[index_key] = nil end
end

M.poll_decon_movers = poll_decon_movers

return M
