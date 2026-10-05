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
local GR_GUI_TABLE_FRAME = "gr_gui_table_frame"
local GR_GUI_TABLE = "gr_gui_table"
local GR_GUI_STATUS = "gr_gui_status"
local GR_GUI_STATUS_ROW = "gr_gui_status_row"
local GR_GUI_MODE = "gr_gui_mode"
local GR_GUI_FILTER = "gr_gui_filter"
local GR_GUI_COUNT = "gr_gui_count"
local GR_GUI_QUALITY = "gr_gui_quality"
local GR_GUI_CLOSE = "gr_gui_close"
local GR_GUI_LINK_ROW = "gr_gui_link_row"
local GR_GUI_LINK_VALUE = "gr_gui_link_value"
local GR_GUI_LINK_INFO = "gr_gui_link_info"
local GR_GUI_PREVIEW_BOX = "gr_gui_preview_box"
local GR_GUI_PREVIEW = "gr_gui_preview"

---「连接至」行尾的信息图标：直接用原版贴图原型 info_no_border（core 自带，不必自己切图）
local GR_ICON_INFO = "info_no_border"

---「连接至」行首文案：原版引擎面板用的就是这条 core 键，各语言自动跟随，无需自维护翻译
local GR_LINK_CAPTION = { "gui-control-behavior.connected-to-network" }
local NOT_IN_LOGISTIC_NETWORK = { "not-in-logistic-network" }
---预览区尺寸。entity-preview 的画面由引擎实时绘制（棋盘格 + 实体 + 它的红/绿接线），
---尺寸只能通过样式给，集中在这里方便调。
local GR_GUI_PREVIEW_WIDTH = 400
local GR_GUI_PREVIEW_HEIGHT = 152

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
            options[#options + 1] = { { "", "[img=quality." .. quality.name .. "]", quality.localised_name }, quality
                .name }
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
    local flow = parent.add { type = "flow", style = "player_input_horizontal_flow" }
    flow.add { type = "label", caption = caption, style = "caption_label" }
    flow.add { type = "empty-widget" }.style.horizontally_stretchable = true
    flow.style.vertical_align = "center"
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
    dropdown.style.width = 200
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

--================================================================================================
-- 面板顶栏：连接信息 + 实体预览
--================================================================================================
--
-- 「连接至：<单位号>」是原版实体面板顶栏的写法，读取器面板同样先说明这块面板属于哪个实体；
-- 预览区用 entity-preview 元素：棋盘格背景、实体外观、实体身上的红/绿接线都由引擎实时绘制，
-- Lua 侧只负责告诉它看哪个实体。
-- （rendering.draw_* 只能画在世界里，ScriptRenderTarget 不接受 GUI 目标，所以「把渲染挂到
-- 面板上」的唯一正确形态就是这个元素，不是自己拼接贴图。）

---面板身份指纹：面板位置 -> 当前「连接至」显示的读取器单位号。
---用位置而不是单位号做键：读取器虚影建成真实读取器后单位号会变，位置不变。
---@type table<string,uint64>
local identity_fingerprints = {}

---面板位置键（tags 只支持基本类型，拼成字符串当表键）
---@param frame LuaGuiElement
---@return string
local function panel_key(frame)
    local tags = frame.tags
    return tostring(tags.surface) .. ":" .. tostring(tags.x) .. ":" .. tostring(tags.y)
end

---「连接至」行的悬浮提示：内容全部来自原版数据（原型本地化名 + 表面名 + 坐标 + 原版状态名），
---不引入自定义文案键，所以不需要维护任何翻译。
---@param entity LuaEntity
---@return LocalisedString
local function link_tooltip(entity)
    local text = {
        "", { "entity-name." .. READER }, " #", tostring(entity.unit_number), "\n",
        region.surface_name(entity.surface), "  ",
        string.format("(%.0f, %.0f)", entity.position.x, entity.position.y),
    }
    if entity.type == "entity-ghost" then
        text[#text + 1] = "  "
        text[#text + 1] = { "entity-status.ghost" }
    end
    return text
end

---添加「连接至：<读取器单位号>」行：原版实体面板顶栏那一行是深色内嵌行。
---样式（继承 inside_deep_frame + 内边距/居中）定义在数据阶段的 data.lua 里，
---运行期只给样式名，不在这里改颜色或贴图。
---@param parent LuaGuiElement
---@param entity LuaEntity 读取器（真实实体或其虚影）
local function add_link_row(parent, entity)
    local row = parent.add { type = "frame", style = "gr_gui_panel_row", direction = "horizontal" }
    row.name = GR_GUI_LINK_ROW
    row.add { type = "label", style = "subheader_label", caption = GR_LINK_CAPTION }
    local t = row.add { type = "label", name = GR_GUI_LINK_VALUE,
        caption = tostring(entity.unit_number) .. " [img=info]",
        tooltip = link_tooltip(entity) }
end

---添加棋盘格实体预览区（原版那块预览同样是深色内嵌框 + 引擎实时绘制的内容）
---@param parent LuaGuiElement
---@param entity LuaEntity|nil 要预览的实体，之后可用 preview.entity 换
---@return LuaGuiElement preview
local function add_entity_preview(parent, entity)
    --引擎元素：万一某个 2.1.x 版本没有 entity-preview，也只是没有预览区，不该让整个面板打不开
    local frame = parent.add { type = "frame", style = "deep_frame_in_shallow_frame" }
    local preview = frame.add { type = "entity-preview", style = "wide_entity_button", name = GR_GUI_PREVIEW }
    preview.entity = entity
    return preview
end


---刷新顶栏（「连接至」+ 预览）：只在指向的读取器变化时才写 GUI。
---虚影建成真实读取器后单位号会变，所以要跟着换；预览本身由引擎实时绘制，不需要重画。
---@param frame LuaGuiElement
---@param content LuaGuiElement
---@param entity LuaEntity|nil 当前读取器；nil 表示读取器已不存在
local function refresh_identity(frame, content, entity)
    local key = panel_key(frame)
    local unit = entity and entity.unit_number

    if identity_fingerprints[key] == unit then return end
    identity_fingerprints[key] = unit
    local row = content[GR_GUI_LINK_ROW]
    if row and row.valid then
        local value = row[GR_GUI_LINK_VALUE]
        if value and value.valid then value.caption = tostring(unit) end
        --虚影建成真实读取器后提示也要改（少一行「尚未建成」）
        local info = row[GR_GUI_LINK_INFO]
        if info and info.valid then info.tooltip = link_tooltip(entity) end
    end
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
    if not entity then
        --预览区要清掉，否则会指着一个失效实体
        refresh_identity(frame, content, nil)
        return
    end
    --顶栏：读取器换了（虚影建成真实读取器）就换「连接至」与预览
    refresh_identity(frame, content, entity)
    local status = status_label(content)
    if status then status.caption = status_text(entity) end
    --虚影没有归属地与电路输出，但面板同样显示按位置预览的信号（与 dop1 一致）
    local counts = meta.output_of(entity)
    local unit = entity.unit_number
    local fingerprint = counts_fingerprint(counts)
    if table_fingerprints[unit] ~= fingerprint then
        table_fingerprints[unit] = fingerprint
        rebuild_table(content[GR_GUI_TABLE_FRAME][GR_GUI_TABLE], counts)
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
    frame.style.maximal_height = 1450

    --标题栏：结构与样式照原版 frame 的头栏（style.lua 的 frame_header_flow 与
    --frame.header_filler_style，后者照抄成了具名的 gr_gui_header_filler）。
    --标题与空白区都带 drag_target，使整条标题栏可拖动窗口。
    local titlebar = frame.add { type = "flow", style = "frame_header_flow" }
    local title = titlebar.add { type = "label", style = "gr_gui_window_title", caption = { "gr-gui.title" } }
    title.drag_target = frame
    local drag_space = titlebar.add { type = "empty-widget", style = "gr_gui_header_filler" }
    drag_space.drag_target = frame
    titlebar.add {
        type = "sprite-button", name = GR_GUI_CLOSE, style = "frame_action_button",
        sprite = "utility/close", tooltip = { "gr-gui.close" },
    }

    local content = frame.add {
        type = "frame", name = GR_GUI_CONTENT,
        style = "entity_frame", direction = "vertical",
    }
    --顶栏：连接信息 + 实体预览（对齐原版实体面板：先说明属于哪个读取器，再给实时预览）
    add_link_row(content, entity)
    add_entity_preview(content, entity)
    identity_fingerprints[panel_key(frame)] = unit
    add_dropdown_row(content, { "gr-gui.range-mode" }, GR_GUI_MODE, range_options(), config.get_mode(unit))
    add_status_row(content, { "gr-gui.current-range" }, status_text(entity))
    add_dropdown_row(content, { "gr-gui.filter" }, GR_GUI_FILTER, filter_options(), config.get_filter(unit))
    add_dropdown_row(content, { "gr-gui.qty" }, GR_GUI_COUNT, count_options(), config.get_count(unit))
    add_dropdown_row(content, { "gr-gui.quality" }, GR_GUI_QUALITY, quality_options(), config.get_quality(unit))
    content.add { type = "line" }
    local table_flow = content.add { type = "scroll-pane", name = GR_GUI_TABLE_FRAME, style = "deep_slots_scroll_pane" }
    local frame = table_flow.add { type = "frame", style = "logistic_section_subheader_frame" }
    frame.style.width = GR_GUI_PREVIEW_WIDTH
    frame.add { type = "label", caption = { "gr-gui.output" }, style = "subheader_label" }
    table_flow.add { type = "table", name = GR_GUI_TABLE, style = "gr_table", column_count = 10 }
    local counts = meta.output_of(entity)
    table_fingerprints[unit] = counts_fingerprint(counts)
    rebuild_table(table_flow[GR_GUI_TABLE], counts)

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
            { { "gr-tooltip.range-mode" },    locale_of(range_options(), mode) },
            { { "gr-tooltip.current-range" }, status_text(reader, m) },
            { { "gr-tooltip.filter" },        locale_of(filter_options(), filter) },
            { { "gr-tooltip.qty" },           locale_of(count_options(), count) },
            { { "gr-tooltip.quality" },       locale_of(quality_options(), quality) },
        }
        for index, field in ipairs(fields) do
            reader.set_tooltip_field { name = field[1], value = field[2], order = 50 + index }
        end
    end)
    --写入失败则不记指纹，下次脏 tick 再试
    if done then tooltip_fingerprints[unit] = fingerprint end
end

return M
