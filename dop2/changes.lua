local M = {}

---@class changes
---@field dirty_readers_region table<meta,any>
---@field dirty_readers_output table<meta,any>
---@field dirty_count_entities_region  table<meta,any>
local changes = {}

---本帧待处理的变更集合。
---计数本身不再进这里：计数项一改就当场把增量写给归属地（region:add_count），
---不再靠"标脏归属地 + 帧末整份重算"，所以这里只剩三类"待解析/待重写"的工作。
---@return changes
function changes:new()
    local obj = {
        dirty_readers_region = {},
        dirty_readers_output = {},
        dirty_count_entities_region = {},
    }
    return obj
end

---@type changes
local current_changes = changes:new()
M.current = current_changes
---标记读取器归属地脏
---@param reader meta
function M.dirty_reader_region(reader)
    current_changes.dirty_readers_region[reader] = true
end

---标记读取器计数脏
---@param reader meta
function M.dirty_reader_output(reader)
    current_changes.dirty_readers_output[reader] = true
end

---标记计数实体归属地脏（由实体移动引发：需要重新解析所在归属地）
---@param count_entity meta
function M.dirty_count_entitiy_region(count_entity)
    current_changes.dirty_count_entities_region[count_entity] = true
end

---清除所有脏标记
function M.clear()
    current_changes = changes:new()
    --M.current 是对外暴露的读取入口，清空后必须同步指向新表，
    --否则读方（on_tick）会一直遍历已经废弃的旧表。
    M.current = current_changes
end

return M
