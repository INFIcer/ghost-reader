---@type string
READER = "ghost-reader"

--- 比较两个数组，返回双方独有的元素
-- @param arr1 数组1
-- @param arr2 数组2
-- @return only_in_arr1 仅在 arr1 中出现的元素列表
-- @return only_in_arr2 仅在 arr2 中出现的元素列表
function get_unique_elements(arr1, arr2)
    -- 用表作为集合，快速查找
    local set1, set2 = {}, {}
    for _, v in ipairs(arr1) do
        set1[v] = true
    end
    for _, v in ipairs(arr2) do
        set2[v] = true
    end

    local only_in_arr1, only_in_arr2 = {}, {}

    -- 找出 arr1 中 arr2 没有的元素
    for _, v in ipairs(arr1) do
        if not set2[v] then
            table.insert(only_in_arr1, v)
        end
    end

    -- 找出 arr2 中 arr1 没有的元素
    for _, v in ipairs(arr2) do
        if not set1[v] then
            table.insert(only_in_arr2, v)
        end
    end

    return only_in_arr1, only_in_arr2
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
            (kind == change_type.ENTITY_SUPPLY or kind == change_type.TILE_SUPPLY or change_type.UPGRADE_SUPPLY or change_type.ITEM_SUPPLY) then
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