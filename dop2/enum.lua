-- dop2/enum.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— 枚举。
--
-- 枚举值一律用字符串常量，理由有两条：
--   1. 必须是互不相同的值。原来写成 `#{}`（对空表取长度 = 数字 0），
--      结果同一枚举的所有成员都等于 0，类别/筛选/数量/范围全部无法区分；
--   2. 必须可序列化。这些值会存进 storage（storage.readers[unit] 的
--      mode/filter/count）并写进蓝图 tags，而 `{}` 这种唯一表在存档往返后
--      会变成另一张表、失去身份。字符串既稳定又与 dop 旧版的取值一致
--      （surface/all/net/...），旧存档与旧蓝图都能直接沿用。
--
-- change_type 的值只作为计数表的分类键（不落存档），命名沿用 dop 旧版常量。

---@enum change_type
change_type = {
    ENTITY_SUPPLY = "entity_supply",
    TILE_SUPPLY = "tile_supply",
    UPGRADE_SUPPLY = "upgrade_supply",
    ITEM_SUPPLY = "item_supply",
    ENTITY_RECYCLE = "entity_recycle",
    TILE_RECYCLE = "tile_recycle",
    UPGRADE_RECYCLE = "upgrade_recycle",
    ITEM_RECYCLE = "item_recycle",
}

---@enum range_mode
range_mode = {
    SURFACE = "surface",
    NETWORK = "network",
}
---@enum filter_mode
filter_mode = {
    ALL = "all",
    ENTITY = "entity",
    TILES = "tiles",
    UPGRADES = "upgrades",
    ITEMS = "items",
}
---@enum count_mode
count_mode = {
    NET = "net",
    SUPPLY = "supply",
    RECYCLE = "recycle",
}
