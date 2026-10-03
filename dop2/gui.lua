-- dop2/gui.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— GUI（构建/刷新/事件）。
--
-- 面板只做展示与配置写入，不参与计数管线：计数由归属地（region）维护，
-- 面板仅把 meta.output_of(读取器) 的结果画出来；配置改动照常只置脏标记，
-- 由 on_tick 统一重算，故 GUI 与性能无关。
--
-- 面板对应的读取器以「表面号 + 位置」记在 frame.tags 上（tags 只支持基本类型，
-- 不能存实体引用），刷新时按位置反查，因此真实读取器与读取器虚影都能打开面板。
-- 读取器虚影没有归属地与电路输出，面板只显示其配置（改动经 bplib 按位置记下，
-- 供建成真实读取器时继承）。

local config = require("__ghost-reader__/dop2/config")
local meta = require("__ghost-reader__/dop2/meta")
local bplib = require("__ghost-reader__/dop2/bplib")
local region = require("__ghost-reader__/dop2/region")
local changes = require("__ghost-reader__/dop2/changes")

---模块对外暴露部分
local M = {}
--================================================================================================

---GUI 元素名
local GR_GUI_FRAME = "gr_gui_frame"
local GR_GUI_CONTENT = "gr_gui_content"
local GR_GUI_TABLE = "gr_gui_table"
local GR_GUI_STATUS = "gr_gui_status"
local GR_GUI_STATUS_ROW = "gr_gui_status_row"
local GR_GUI_MODE = "gr_gui_mode"
local GR_GUI_FILTER = "gr_gui_filter"
local GR_GUI_COUNT = "gr_gui_count"
local GR_GUI_QUALITY = "gr_gui_quality"
local GR_GUI_CLOSE = "gr_gui_close"

--================================================================================================
-- 枚举与下拉框选项
--================================================================================================

--选项表是 { {本地化名, 枚举值}, ... }，顺序即下拉框中的顺序。
--枚举值是 enum.lua 里的全局表，故选项在调用时构造，不假定模块加载顺序。

---检索范围模式的下拉选项
---@return table[]
local function range_options()
    return {
        { { "gr-gui.mode-surface" }, range_mode.SURFACE },
        { { "gr-gui.mode-network" }, range_mode.NETWORK },
    }
end

---筛选模式的下拉选项
---@return table[]
local function filter_options()
    return {
        { { "gr-gui.filter-all" },      filter_mode.ALL },
        { { "gr-gui.filter-entity" },   filter_mode.ENTITY },
        { { "gr-gui.filter-tiles" },    filter_mode.TILES },
        { { "gr-gui.filter-upgrades" }, filter_mode.UPGRADES },
        { { "gr-gui.filter-items" },    filter_mode.ITEMS },
    }
end

---数量模式的下拉选项
---@return table[]
local function count_options()
    return {
        { { "gr-gui.qty-net" },     count_mode.NET },
        { { "gr-gui.qty-supply" },  count_mode.SUPPLY },
        { { "gr-gui.qty-recycle" }, count_mode.RECYCLE },
    }
end

---品质筛选下拉选项缓存（品质原型在会话内固定，只构造一次）
---@type table[]|nil
local quality_options_cache

---品质筛选的下拉选项：全部 + 各品质（按品质等级升序）。
---第二项是品质名（字符串），QUALITY_ALL 表示不筛选。
---@return table[] { {本地化名, 品质名}, ... }
local function quality_options()
    if not quality_options_cache then
        local qualities = {}
        --prototypes.quality 是 LuaCustomTable，只能用 pairs 遍历
        for _, quality in pairs(prototypes.quality) do
            if not quality.hidden then
                qualities[#qualities + 1] = quality
            end
        end
        table.sort(qualities, function(a, b)
            if a.level ~= b.level then return a.level < b.level end
            return a.name < b.name
        end)

        local options = { { { "gr-gui.quality-all" }, QUALITY_ALL } }
        for _, quality in ipairs(qualities) do
            options[#options + 1] = { quality.localised_name or { "", quality.name }, quality.name }
        end
        quality_options_cache = options
    end
    return quality_options_cache
end

---取枚举值对应的本地化名（复用下拉框选项，避免再维护一份枚举->文本的映射）
---@param options table[]
---@param value any
---@return LocalisedString
local function locale_of(options, value)
    for _, option in ipairs(options) do
        if option[2] == value then return option[1] end
    end
    return { "" }
end

--================================================================================================
-- 面板内容
--================================================================================================

---是否读取器（真实实体或其虚影）
---@param entity LuaEntity|nil
---@return boolean
local function is_reader(entity)
    if not (entity and entity.valid) then return false end
    if entity.name == READER then return true end
    return entity.type == "entity-ghost" and entity.ghost_name == READER
end

---面板记录的读取器位置（tags 不能存实体引用，只能存基本类型）
---@param entity LuaEntity
---@return Tags
local function pos_tag(entity)
    return {
        surface = entity.surface.index,
        x = entity.position.x,
        y = entity.position.y,
    }
end

---按面板记录的位置反查读取器实体（真实读取器或读取器虚影）
---@param frame LuaGuiElement
---@return LuaEntity|nil
local function frame_reader(frame)
    local tags = frame.tags
    local surface_index = tags and tags.surface
    if type(surface_index) ~= "number" then return nil end
    local surface = game.get_surface(surface_index)
    if not surface then return nil end
    local found = surface.find_entities_filtered({ position = { x = tags.x, y = tags.y } })
    for _, entity in ipairs(found) do
        if is_reader(entity) then return entity end
    end
    return nil
end

---读取器当前范围的显示文本：归属地名 / 表面名 / 不在物流网络内
---@param entity LuaEntity
---@param m meta|nil 读取器元信息（虚影没有）
---@return LocalisedString
local function status_text(entity, m)
    --归属地可能已失效（如物流网络被合并/拆除而归属地尚未重新解析），此时不能读它的名字
    local reader_region = meta.region_of(entity)
    if reader_region and reader_region:vaild() then return reader_region:name() end
    if config.get_mode(entity.unit_number) == range_mode.NETWORK then
        return { "gr-gui.status-no-network" }
    end
    if entity.surface then return region.surface_name(entity.surface) end
    return { "gr-gui.status-no-network" }
end

---信号图标的悬浮提示：物品名（品质）× 数量
---计数表的键是物品名/品质名（字符串），显示用的本地化名要回原型里取。
---@param item_name string
---@param quality_name string
---@param count int
---@return LocalisedString
local function signal_tooltip(item_name, quality_name, count)
    local item = prototypes.item[item_name]
    local text = { "", (item and item.localised_name) or { "", item_name } }
    if quality_name ~= "normal" then
        local quality = prototypes.quality[quality_name]
        text[#text + 1] = { "", " (", (quality and quality.localised_name) or { "", quality_name }, ")" }
    end
    text[#text + 1] = " ×"
    text[#text + 1] = tostring(count)
    return text
end

---用读取器的输出信号重建信号表
---@param table_element LuaGuiElement|nil 信号表
---@param counts counter 信号计数表（item名 -> quality名 -> count）
local function rebuild_table(table_element, counts)
    if not (table_element and table_element.valid) then return end
    table_element.clear()
    for item, qualities in pairs(counts or {}) do
        for quality, count in pairs(qualities) do
            --注意：2.x 里从对象上取出的方法已经是绑定到该对象的闭包（所以全项目都写
            --`parent.add{...}` 而不是 `parent:add{...}`），pcall 时只能再传元素参数表，
            --多传一个 self 会报 "Expected 1 argument but 2 were given"。
            --物品原型未必有 "item/<名字>" 贴图，缺图时跳过这一个信号，不让整个面板刷新失败
            local ok, icon = pcall(table_element.add, {
                type = "sprite-button",
                style = "transparent_slot",
                sprite = "item/" .. item,
                --非普通品质加左下角品质角标（原版风格：normal 不显示角标）
                quality = quality ~= "normal" and quality or nil,
                tooltip = signal_tooltip(item, quality, count),
            })
            if ok and icon then
                icon.number = count
                icon.style.width = 40
                icon.style.height = 40
                icon.style.padding = 4
            else
                --贴图/样式不可用时退化成文本，保证信号内容始终看得见（否则整栏空白且无从判断）
                pcall(table_element.add, {
                    type = "label",
                    caption = signal_tooltip(item, quality, count),
                })
            end
        end
    end
end

---在内容区添加一行：左侧标签，右侧由调用方补控件
---@param parent LuaGuiElement
---@param caption LocalisedString
---@return LuaGuiElement flow
local function add_row(parent, caption)
    local flow = parent.add { type = "flow", direction = "horizontal" }
    flow.add { type = "label", caption = caption }
    flow.add { type = "empty-widget" }.style.horizontally_stretchable = true
    return flow
end

---添加一行下拉框
---@param parent LuaGuiElement
---@param caption LocalisedString
---@param name string 元素名（供事件按名分发）
---@param options table[] { {本地化名, 枚举值}, ... }
---@param selected any 当前枚举值
local function add_dropdown_row(parent, caption, name, options, selected)
    local flow = add_row(parent, caption)
    local items, values = {}, {}
    for index, option in ipairs(options) do
        items[index] = option[1]
        values[index] = option[2]
    end
    local selected_index = index_of(values, selected)
    if selected_index == 0 then selected_index = 1 end
    local dropdown = flow.add {
        type = "drop-down", name = name, items = items, selected_index = selected_index,
    }
    dropdown.style.width = 170
end

---添加一行状态文本
---@param parent LuaGuiElement
---@param caption LocalisedString
---@param caption_value LocalisedString
local function add_status_row(parent, caption, caption_value)
    local flow = add_row(parent, caption)
    --行 flow 也命名：状态标签在 flow 里面，刷新时要两层索引才取得到
    flow.name = GR_GUI_STATUS_ROW
    flow.add { type = "label", name = GR_GUI_STATUS, caption = caption_value }
end

---取状态标签（它在状态行的 flow 里，不是内容区的直接子元素）
---@param content LuaGuiElement
---@return LuaGuiElement|nil
local function status_label(content)
    local row = content[GR_GUI_STATUS_ROW]
    if not (row and row.valid) then return nil end
    local label = row[GR_GUI_STATUS]
    if label and label.valid then return label end
end

---面板信号表指纹：内容没变就不重建。
---重建要先把表清空再逐个新建按钮，是面板刷新的主要开销；信号没变时每帧重建纯属浪费。
---@type table<uint64,string>
local table_fingerprints = {}

---把信号计数表压成指纹（物品名:品质=数量，排序后拼接）
---@param counts counter
---@return string
local function counts_fingerprint(counts)
    local parts = {}
    for item, qualities in pairs(counts) do
        for quality, count in pairs(qualities) do
            parts[#parts + 1] = item .. ":" .. quality .. "=" .. tostring(count)
        end
    end
    table.sort(parts)
    return table.concat(parts, ";")
end

---刷新一个玩家的面板（状态行 + 信号表）
---@param player LuaPlayer
local function refresh_player(player)
    local frame = player.gui.screen[GR_GUI_FRAME]
    if not (frame and frame.valid) then return end
    local content = frame[GR_GUI_CONTENT]
    if not (content and content.valid) then return end
    --读取器已不存在（虚影已建成真实读取器/已被挖掉）：面板留着但不再刷新
    local entity = frame_reader(frame)
    if not entity then return end
    local status = status_label(content)
    if status then status.caption = status_text(entity) end
    --虚影没有归属地与电路输出，但面板同样显示按位置预览的信号（与 dop1 一致）
    local counts = meta.output_of(entity)
    local unit = entity.unit_number
    local fingerprint = counts_fingerprint(counts)
    if table_fingerprints[unit] ~= fingerprint then
        table_fingerprints[unit] = fingerprint
        rebuild_table(content[GR_GUI_TABLE], counts)
    end
end

---构建读取器面板
---@param player LuaPlayer
---@param entity LuaEntity 读取器（真实实体或其虚影）
local function build(player, entity)
    local old = player.gui.screen[GR_GUI_FRAME]
    if old and old.valid then old.destroy() end
    player.opened = nil

    local unit = entity.unit_number
    local frame = player.gui.screen.add {
        type = "frame", name = GR_GUI_FRAME, direction = "vertical", tags = pos_tag(entity),
    }
    frame.auto_center = true
    frame.style.minimal_width = 260

    --标题栏：标题与空白区都带 drag_target，使整条标题栏可拖动窗口
    local titlebar = frame.add { type = "flow" }
    local title = titlebar.add { type = "label", style = "frame_title", caption = { "gr-gui.title" } }
    title.drag_target = frame
    local drag_space = titlebar.add { type = "empty-widget", style = "draggable_space_header" }
    drag_space.drag_target = frame
    drag_space.style.horizontally_stretchable = true
    drag_space.style.height = 24
    titlebar.add {
        type = "sprite-button", name = GR_GUI_CLOSE, style = "frame_action_button",
        sprite = "utility/close", tooltip = { "gr-gui.close" },
    }

    local content = frame.add {
        type = "frame", name = GR_GUI_CONTENT,
        style = "inside_shallow_frame_with_padding", direction = "vertical",
    }
    add_dropdown_row(content, { "gr-gui.range-mode" }, GR_GUI_MODE, range_options(), config.get_mode(unit))
    add_status_row(content, { "gr-gui.current-range" }, status_text(entity))
    add_dropdown_row(content, { "gr-gui.filter" }, GR_GUI_FILTER, filter_options(), config.get_filter(unit))
    add_dropdown_row(content, { "gr-gui.qty" }, GR_GUI_COUNT, count_options(), config.get_count(unit))
    add_dropdown_row(content, { "gr-gui.quality" }, GR_GUI_QUALITY, quality_options(), config.get_quality(unit))
    content.add { type = "label", caption = { "gr-gui.output" }, style = "frame_subheading_label" }
    content.add { type = "table", name = GR_GUI_TABLE, column_count = 6 }
    local counts = meta.output_of(entity)
    table_fingerprints[unit] = counts_fingerprint(counts)
    rebuild_table(content[GR_GUI_TABLE], counts)

    player.opened = frame
end

--================================================================================================
-- 事件
--================================================================================================

---打开读取器面板
---@param event EventData.on_gui_opened
function M.on_gui_opened(event)
    if event.gui_type ~= defines.gui_type.entity then return end
    local entity = event.entity
    if not is_reader(entity) then return end
    --配置按单位号存放，没有单位号的实体无法配置
    if type(entity.unit_number) ~= "number" then return end
    local player = game.get_player(event.player_index)
    if not player then return end
    build(player, entity)
end

---关闭读取器面板
---@param event EventData.on_gui_closed
function M.on_gui_closed(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local frame = player.gui.screen[GR_GUI_FRAME]
    if frame and frame.valid then frame.destroy() end
end

---面板关闭按钮
---@param event EventData.on_gui_click
function M.on_gui_click(event)
    local element = event.element
    if not (element and element.valid) then return end
    if element.name ~= GR_GUI_CLOSE then return end
    local player = game.get_player(event.player_index)
    if not player then return end
    local frame = player.gui.screen[GR_GUI_FRAME]
    if not (frame and frame.valid) then return end
    if player.opened == frame then player.opened = nil end
    frame.destroy()
end

---下拉框配置变更：写入配置并按变更内容置脏（范围模式改归属地，其余只改输出）
---@param event EventData.on_gui_selection_state_changed
function M.on_gui_selection_state_changed(event)
    local element = event.element
    if not (element and element.valid) then return end
    local options
    if element.name == GR_GUI_MODE then
        options = range_options()
    elseif element.name == GR_GUI_FILTER then
        options = filter_options()
    elseif element.name == GR_GUI_COUNT then
        options = count_options()
    elseif element.name == GR_GUI_QUALITY then
        options = quality_options()
    else
        return
    end
    local option = options[element.selected_index]
    if not option then return end

    --下拉框在 frame>content>flow>drop-down，故向上逐层找带位置的面板，避免硬编码层级
    local node = element
    while node and node.valid do
        local tags = node.tags
        if tags and type(tags.surface) == "number" then break end
        node = node.parent
    end
    if not (node and node.valid) then return end
    local reader = frame_reader(node)
    if not reader then return end
    local unit = reader.unit_number

    if element.name == GR_GUI_MODE then
        config.set_mode(unit, option[2])
    elseif element.name == GR_GUI_FILTER then
        config.set_filter(unit, option[2])
    elseif element.name == GR_GUI_COUNT then
        config.set_count(unit, option[2])
    else
        config.set_quality(unit, option[2])
    end

    local m = meta.get_meta_of(reader)
    if m and reader.name == READER then
        --范围模式改变读取的归属地类型，需要重新解析归属地；其余只需重写输出
        if element.name == GR_GUI_MODE then changes.dirty_reader_region(m) end
        changes.dirty_reader_output(m)
    else
        --读取器虚影：没有归属地与电路输出，把配置按位置记下，供建成真实读取器时继承
        bplib.remember_config(reader, config.reader_config(unit))
    end

    local player = game.get_player(event.player_index)
    if player then refresh_player(player) end
end

--================================================================================================
-- 由主管线驱动
--================================================================================================

---刷新所有已打开的面板（帧末输出后调用）
function M.refresh_open()
    for _, player in pairs(game.players) do
        if player and player.valid then refresh_player(player) end
    end
end

---读取器悬浮提示内容指纹：内容没变就不重写。
---计数每次脏都会变，但提示只由配置与当前范围决定，故用指纹挡掉无谓的写入。
---@type table<uint64,string>
local tooltip_fingerprints = {}

---刷新读取器悬浮提示（5 个字段：范围模式/当前范围/筛选/数量/品质）
---@param reader LuaEntity
function M.update_tooltip(reader)
    if not (reader and reader.valid and reader.name == READER) then return end
    local unit = reader.unit_number
    if type(unit) ~= "number" then return end
    local m = meta.get_meta_of(reader)
    local mode = config.get_mode(unit)
    local filter = config.get_filter(unit)
    local count = config.get_count(unit)
    local quality = config.get_quality(unit)
    local region_id = m and m.reader_region and m.reader_region.reg_num or 0
    --单位号不会复用，故指纹可以安全地按单位号缓存
    local fingerprint = table.concat({
        tostring(mode), tostring(filter), tostring(count), tostring(quality), tostring(region_id),
    }, "|")
    if tooltip_fingerprints[unit] == fingerprint then return end

    --name/value 必须是 LocalisedString 数组，且实体原型未必支持自定义提示字段
    local done = pcall(function()
        reader.clear_tooltip_fields()
        local fields = {
            { { "gr-tooltip.range-mode" }, locale_of(range_options(), mode) },
            { { "gr-tooltip.current-range" }, status_text(reader, m) },
            { { "gr-tooltip.filter" }, locale_of(filter_options(), filter) },
            { { "gr-tooltip.qty" }, locale_of(count_options(), count) },
            { { "gr-tooltip.quality" }, locale_of(quality_options(), quality) },
        }
        for index, field in ipairs(fields) do
            reader.set_tooltip_field { name = field[1], value = field[2], order = 50 + index }
        end
    end)
    --写入失败则不记指纹，下次脏 tick 再试
    if done then tooltip_fingerprints[unit] = fingerprint end
end

return M
