---@enum change_type
change_type = {
    ENTITY_SUPPLY = #{} --[[@as change_type.ENTITY_SUPPLY]],
    TILE_SUPPLY = #{} --[[@as change_type.TILE_SUPPLY]],
    UPGRADE_SUPPLY = #{} --[[@as change_type.UPGRADE_SUPPLY]],
    ITEM_SUPPLY = #{} --[[@as change_type.ITEM_SUPPLY]],
    ENTITY_RECYCLE = #{} --[[@as change_type.ENTITY_RECYCLE]],
    TILE_RECYCLE = #{} --[[@as change_type.TILE_RECYCLE]],
    UPGRADE_RECYCLE = #{} --[[@as change_type.UPGRADE_RECYCLE]],
    ITEM_RECYCLE = #{} --[[@as change_type.ITEM_RECYCLE]],
}

---@enum range_mode
range_mode = {
    SURFACE = #{} --[[@as range_mode.SURFACE]],
    NETWORK = #{} --[[@as range_mode.NETWORK]],
}
---@enum filter_mode
filter_mode = {
    ALL = #{} --[[@as filter_mode.ALL]],
    ENTITY = #{} --[[@as filter_mode.ENTITY]],
    TILES = #{} --[[@as filter_mode.TILES]],
    UPGRADES = #{} --[[@as filter_mode.UPGRADES]],
    ITEMS = #{} --[[@as filter_mode.ITEMS]],
}
---@enum count_mode
count_mode = {
    NET = #{} --[[@as count_mode.NET]],
    SUPPLY = #{} --[[@as count_mode.SUPPLY]],
    RECYCLE = #{} --[[@as count_mode.RECYCLE]],
}
