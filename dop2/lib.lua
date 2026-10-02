---@type string
READER = "ghost-reader"

--- 共享的空集合。比较过程只读传入的集合，故复用安全。
local EMPTY_SET = {}

--- 比较两个集合，返回双方独有的键。
--- 集合是「键 -> 任意值」的表（本项目一律用 true）。这里用集合而不是数组：
--- 增删判断只需哈希查表，调用方（计数实体的归属地增删）本来也用集合保存。
---@param set1 table 集合1，nil 视为空集合
---@param set2 table 集合2，nil 视为空集合
---@return table only_in_set1 仅在 set1 中出现的键集合
---@return table only_in_set2 仅在 set2 中出现的键集合
function get_unique_elements(set1, set2)
    set1 = set1 or EMPTY_SET
    set2 = set2 or EMPTY_SET

    local only_in_set1, only_in_set2 = {}, {}

    -- 找出 set1 中 set2 没有的键
    for v in pairs(set1) do
        if not set2[v] then
            only_in_set1[v] = true
        end
    end

    -- 找出 set2 中 set1 没有的键
    for v in pairs(set2) do
        if not set1[v] then
            only_in_set2[v] = true
        end
    end

    return only_in_set1, only_in_set2
end

---@return boolean
function contain(table, e)
    for _, value in ipairs(table) do
        if value == e then
            return true
        end
    end
    return false
end

---查找元素在列表中的序号
---@param table table 数组
---@param e any 要查找的元素
---@return int index 元素序号，未找到返回 0
function index_of(table, e)
    for index, value in ipairs(table) do
        if value == e then
            return index
        end
    end
    return 0
end

function remove(table, e)
    for index, value in ipairs(table) do
        if value == e then
            table.remove(table, index)
            break
        end
    end
end

---确保品质不为空
---@param quality? LuaQualityPrototype
---@return LuaQualityPrototype
function ensure_quality(quality)
    if not quality then
        quality = prototypes.quality["normal"]
    end
    return quality
end

---comment
---@param str string
---@param prefix string
---@return boolean
function has_prefix(str, prefix)
    return str:find(prefix, 1, true) == 1
end

---comment
---@param kind change_type
---@param filter filter_mode
function match_filter(kind, filter)
    if filter == filter_mode.ALL then
        return true
    else
        if filter == filter_mode.ENTITY and
            (kind == change_type.ENTITY_SUPPLY or kind == change_type.ENTITY_RECYCLE) then
            return true
        elseif filter == filter_mode.TILES and
            (kind == change_type.TILE_SUPPLY or kind == change_type.TILE_RECYCLE) then
            return true
        elseif filter == filter_mode.UPGRADES and
            (kind == change_type.UPGRADE_SUPPLY or kind == change_type.UPGRADE_RECYCLE) then
            return true
        elseif filter == filter_mode.ITEMS and
            (kind == change_type.ITEM_SUPPLY or kind == change_type.ITEM_RECYCLE) then
            return true
        end
    end
    return false
end

---comment
---@param kind change_type
---@param count count_mode
function match_count(kind, count)
    if count == count_mode.NET then
        return true
    else
        if count == count_mode.SUPPLY and
            --每个比较都要写全 `kind ==`：漏写会让整条 or 链恒真（等于不筛选）
            (kind == change_type.ENTITY_SUPPLY or kind == change_type.TILE_SUPPLY or kind == change_type.UPGRADE_SUPPLY or kind == change_type.ITEM_SUPPLY) then
            return true
        elseif count == count_mode.RECYCLE and
            (kind == change_type.ENTITY_RECYCLE or kind == change_type.TILE_RECYCLE or kind == change_type.UPGRADE_RECYCLE or kind == change_type.ITEM_RECYCLE) then
            return true
        end
    end
    return false
end

---comment
---@param quality string
---@param filiter? string
function match_quality(quality, filiter)
    if not filiter then
        return true
    else
        return quality == filiter
    end
end

---@param kind change_type
---@param filter filter_mode
---@param count count_mode
function match(kind, filter, count)
    return match_filter(kind, filter) and match_count(kind, count)
end

---comment
---@param center MapPosition
---@param radius number
function box(center,radius)
    return {
        { center.x - radius, center.y - radius },
        { center.x + radius, center.y + radius }
    }
end