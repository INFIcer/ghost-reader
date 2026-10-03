---@type string
READER = "ghost-reader"

--计数项名（meta.count_items 的键）。meta/region/snapshot/events 共用，集中在此避免各处拼错。
--名字里带连字符，不能用点号取值，必须用 [] 索引。
---@type string
COUNT_DECON_ENTITY = "deconstruction-entity"        --被拆实体本身（同时用作"已标记拆除"的判据）
---@type string
COUNT_DECON_INVENTORY = "deconstruction-inventory"  --被拆实体内部存储里的物品（机器人一件件搬，需快照轮询）
---@type string
COUNT_DECON_INSTANT = "deconstruction-instant"      --瞬间拆除的实体（环境实体/落地物品）的回收物，标记时一次算清
---@type string
COUNT_DECON_TILE = "deconstruction-tile"            --被拆地格（地格类别回收；由 deconstructible-tile-proxy 代表）
---@type string
COUNT_IRP_PREFIX = "irp"                            --IRP 计数项前缀（后接 IRP 的注册号）

---品质筛选的"全部"取值。品质筛选的其余取值是品质原型名（LuaQualityPrototype.name）。
---用字符串而不是品质原型：与其它枚举一致，可安全存 storage、写进蓝图 tags，
---旧存档里存的也是名字，不需要迁移。
---@type string
QUALITY_ALL = "all"

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

---取品质名（字符串）。
---计数表/计数项/配置里的品质一律以名字作键：名字是稳定键（原型 userdata 不驻留，
---两次查表拿到的是不同对象，拿来当表键会让同一品质合不到一起），
---也正是 SignalID 想要的形式。故这里只接受字符串——
---引擎给原型的地方（LuaEntity.quality、LuaItemStack.quality）由调用方自己取 .name，
---传原型会当场报错，避免静默写坏计数。
---@param quality? string 品质名，缺省为 normal
---@return string
function ensure_quality(quality)
    if quality == nil then return "normal" end
    if type(quality) ~= "string" then
        error("ensure_quality: 品质要以名字（字符串）传入，原型请先取 .name")
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
---@param quality string 物品的品质名（LuaQualityPrototype.name）
---@param filter? string 品质筛选：QUALITY_ALL 或品质名；nil 视为不筛选
function match_quality(quality, filter)
    if not filter or filter == QUALITY_ALL then
        return true
    end
    return quality == filter
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