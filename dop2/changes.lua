local M = {}

---@class changes
---@field dirty_readers_region table<meta,any>
---@field dirty_readers_output table<meta,any>
---@field dirty_readers_panel table<meta,any>
---@field dirty_regions_count table<region,any>
---@field dirty_count_entities_region  table<meta,any>
local changes = {}

---本帧待处理的变更集合。
---计数本身不再进这里：计数项一改就当场把增量写给归属地（region:add_count），
---不再靠"标脏归属地 + 帧末整份重算"，所以这里只剩"待解析/待重写"的工作
---（外加只刷新面板的配置变化，见 dirty_reader_panel）。
---@return changes
function changes:new()
    local obj = {
        dirty_readers_region = {},
        dirty_readers_output = {},
        dirty_readers_panel = {},
        --归属地计数变化：只用于按需刷新"已打开面板"（见 gui.refresh_dirty）。
        --读取器虚影不是归属地读者（不进 region.readers），没法靠 dirty_reader_output
        --通知到它的面板，故额外记下"哪些归属地的计数变了"。
        dirty_regions_count = {},
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

---标记读取器面板脏（只需要刷新面板，不需要重写电路输出的配置变化）。
---用于读取器虚影改配置：虚影没有电路输出，但可能开着面板（虚影有单位号，可开面板）。
---真实读取器的配置变化照旧走 dirty_reader_output（顺带刷新面板）。
---@param reader meta
function M.dirty_reader_panel(reader)
    current_changes.dirty_readers_panel[reader] = true
end

---标记计数实体归属地脏（由实体移动引发：需要重新解析所在归属地）
---@param count_entity meta
function M.dirty_count_entitiy_region(count_entity)
    current_changes.dirty_count_entities_region[count_entity] = true
end

---标记归属地计数脏（只用于面板按需刷新：面板展示的计数来自归属地）。
---真实读取器的面板另有 dirty_reader_output 登记；读取器虚影不在 region.readers 里，
---只能靠这个集合让 on_tick 判断"已打开的虚影面板所在归属地是否变了"。
---@param target_region region
function M.dirty_region_count(target_region)
    current_changes.dirty_regions_count[target_region] = true
end

---清除所有脏标记
function M.clear()
    current_changes = changes:new()
    --M.current 是对外暴露的读取入口，清空后必须同步指向新表，
    --否则读方（on_tick）会一直遍历已经废弃的旧表。
    M.current = current_changes
end

return M
