-- dop2/gui.lua
--
-- 虚影读取器（Ghost Reader）DOP 重构 —— GUI（构建/刷新/事件）。
--
-- 面板只做展示与配置写入，不参与计数管线：计数由归属地（region）维护，
-- 面板仅把 meta.output_of(读取器) 的结果画出来；配置改动照常只置脏标记，
-- 由 on_tick 统一重算。
--
-- **刷新是按需的，不是每帧的**：只有「面板已打开」且「面板对应的读取器发生变动」
-- （计数/归属地/配置）时才重画。events 消费读取器脏标记时把读取器位置登记到
-- dirty_panels（见 M.mark_dirty），on_tick 末调用 M.refresh_dirty() 处理一次；
-- 没有面板打开时 on_tick 完全不碰 GUI，也不再遍历玩家/重算信号指纹。
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
        { { "gr-gui.mode-surface" }, range_mode.SURFACE, { "gr-gui.mode-surface-tooltip" } },
        { { "gr-gui.mode-network" }, range_mode.NETWORK, { "gr-gui.mode-network-tooltip" } },
    }
end

---筛选模式的下拉选项
---@return table[]
local function filter_options()
    return {
        { { "gr-gui.filter-all" },      filter_mode.ALL,      { "gr-gui.filter-all-tooltip" } },
        { { "gr-gui.filter-entity" },   filter_mode.ENTITY,   { "gr-gui.filter-entity-tooltip" } },
        { { "gr-gui.filter-tiles" },    filter_mode.TILES,    { "gr-gui.filter-tiles-tooltip" } },
        { { "gr-gui.filter-upgrades" }, filter_mode.UPGRADES, { "gr-gui.filter-upgrades-tooltip" } },
        { { "gr-gui.filter-items" },    filter_mode.ITEMS,    { "gr-gui.filter-items-tooltip" } },
    }
end

---数量模式的下拉选项
---@return table[]
local function count_options()
    return {
        { { "gr-gui.qty-net" },     count_mode.NET,     { "gr-gui.qty-net-tooltip" } },
        { { "gr-gui.qty-supply" },  count_mode.SUPPLY,  { "gr-gui.qty-supply-tooltip" } },
        { { "gr-gui.qty-recycle" }, count_mode.RECYCLE, { "gr-gui.qty-recycle-tooltip" } },
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
            options[#options + 1] = { { "", "[img=quality." .. quality.name .. "] ", quality.localised_name }, quality
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
---@return LocalisedString
local function status_text(entity)
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
                -- else
                --     --贴图/样式不可用时退化成文本，保证信号内容始终看得见（否则整栏空白且无从判断）
                --     pcall(table_element.add, {
                --         type = "label",
                --         caption = signal_tooltip(item, quality, count),
                --     })
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
    if #(options[selected_index]) > 2 then
        dropdown.tooltip = options[selected_index][3]
    end
end

--================================================================================================
-- 按需刷新：只有「面板已打开 + 对应读取器发生变化」时才重画
--================================================================================================
--
-- events 消费读取器脏标记时把读取器位置登记到 dirty_panels（M.mark_dirty）；
-- on_tick 末调用 M.refresh_dirty() 统一处理一次，且只处理 game.players 里确实开着
-- 面板、位置又被登记过的面板。没有面板打开时登记与刷新都是空操作（open_panels 为 0），
-- 未打开面板的读取器变动不会产生任何 GUI 开销。

---面板位置键（tags 只支持基本类型，位置拼成字符串当表键）。
---读取器与读取器虚影共用同一套键：虚影建成真实读取器后位置不变、单位号会变。
---@param surface_index int
---@param x number
---@param y number
---@return string
local function pos_key(surface_index, x, y)
    return tostring(surface_index) .. ":" .. tostring(x) .. ":" .. tostring(y)
end

---面板位置键（tags 上记着面板对应的读取器位置）
---@param frame LuaGuiElement
---@return string
local function panel_key(frame)
    local tags = frame.tags
    return pos_key(tags.surface, tags.x, tags.y)
end

---当前打开着的面板数量。
---用于让「没有面板打开」成为真正的零开销：读取器变动时连位置键都不拼。
---读档/配置变化后模块级计数会归零，但面板本身还在存档里，故由 M.resync_open_panels()
---在重建时按实际面板数重算（见 events.rebuild）。
---@type int
local open_panels = 0

---本帧需要重画的面板位置（读取器变动时由 events 登记，M.refresh_dirty 消费后清空）
---@type table<string,true>
local dirty_panels = {}

---面板状态：按「玩家 + 面板位置」分开存。
---* unit：上次显示的读取器单位号（虚影建成真实读取器后会变，用于决定是否换预览实体）
---* counts：上次显示的信号表引用（深比较用：内容没变就不重建 GUI 元素）。
---  meta.read_region_output 返回的是归属地按"过滤器组合"缓存的表，创建后不会再被改动
---  （任何计数变化都会整份作废缓存、之后重新建表），所以保存引用就能当作上次内容的快照。
---用玩家做外层键：多个玩家可以同时打开同一个读取器，各自的面板必须各自刷新
---（旧实现的全局指纹会让后遍历到的玩家面板停在旧内容上）。
---@type table<uint32, table<string, {unit:uint64|nil, counts:counter|nil}>>
local panel_states = {}

---取（或创建）某个玩家某个面板的状态
---@param player LuaPlayer
---@param key string
---@return table
local function get_panel_state(player, key)
    local states = panel_states[player.index]
    if not states then
        states = {}
        panel_states[player.index] = states
    end
    local state = states[key]
    if not state then
        state = {}
        states[key] = state
    end
    return state
end

---面板销毁时清掉它的状态（避免按玩家/按面板累积状态表）
---@param player LuaPlayer
---@param frame LuaGuiElement
local function clear_panel_state(player, frame)
    local states = panel_states[player.index]
    if not states then return end
    states[panel_key(frame)] = nil
    if next(states) == nil then panel_states[player.index] = nil end
end

---销毁面板：清状态 + 清 player.opened + 减打开计数
---@param player LuaPlayer
---@param frame LuaGuiElement
local function destroy_panel(player, frame)
    if not (frame and frame.valid) then return end
    clear_panel_state(player, frame)
    if player.opened == frame then player.opened = nil end
    frame.destroy()
    if open_panels > 0 then open_panels = open_panels - 1 end
    --最后一个面板关掉后，本帧排队的刷新登记已经没有意义，直接丢弃
    if open_panels == 0 then dirty_panels = {} end
end

---两份信号计数表内容是否相同（item -> quality -> count 两层深比较）。
---用作重建信号表的门：归属地计数变了但当前筛选/品质下看不到变化时，不重建 GUI 元素。
---不拼指纹串、不排序：脏帧本来就可能每帧都来，这里只做 O(信号数) 的比较。
---@param a counter|nil
---@param b counter
---@return boolean
local function same_counts(a, b)
    if a == b then return true end
    if not (a and b) then return false end
    for item, qualities in pairs(a) do
        local other = b[item]
        if not other then return false end
        for quality, count in pairs(qualities) do
            if other[quality] ~= count then return false end
        end
        for quality in pairs(other) do
            if qualities[quality] == nil then return false end
        end
    end
    for item in pairs(b) do
        if a[item] == nil then return false end
    end
    return true
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

---@param parent LuaGuiElement
---@param entity LuaEntity 读取器（真实实体或其虚影）
local function add_link_row(parent, entity)
    local row = parent.add { type = "frame", style = "gr_gui_panel_row", direction = "horizontal" }
    row.name = GR_GUI_LINK_ROW
    local st = status_text(entity)

    row.add { type = "label", style = "subheader_label", caption = { "gr-gui.status-range" } }
    row.add { type = "label", name = GR_GUI_LINK_VALUE, caption = st, }
end

local function update_link_row(content, entity)
    local row = content[GR_GUI_LINK_ROW]
    if row and row.valid then
        local value = row[GR_GUI_LINK_VALUE]
        if value and value.valid then value.caption = status_text(entity) end
    end
end

---添加棋盘格实体预览区（原版那块预览同样是深色内嵌框 + 引擎实时绘制的内容）
---@param parent LuaGuiElement
---@param entity LuaEntity|nil 要预览的实体，之后可用 preview.entity 换
---@return LuaGuiElement preview
local function add_entity_preview(parent, entity)
    --引擎元素：万一某个 2.1.x 版本没有 entity-preview，也只是没有预览区，不该让整个面板打不开
    local frame = parent.add { type = "frame", style = "deep_frame_in_shallow_frame", name = GR_GUI_PREVIEW_BOX }
    local preview = frame.add { type = "entity-preview", style = "wide_entity_button", name = GR_GUI_PREVIEW }
    preview.entity = entity
    return preview
end


---刷新一个已打开的面板（预览/连接信息/信号表）。
---读取器已不存在时关掉面板：虚影建成真实读取器时同位置会立刻出现新读取器，面板跟着换过去；
---被挖掉/虚影取消时同位置没有读取器，面板随之关闭。
---@param player LuaPlayer
---@param frame LuaGuiElement
local function refresh_panel(player, frame)
    --先确认读取器还在：面板对应的读取器没了就关闭面板（这一步不依赖面板内容是否完整）
    local entity = frame_reader(frame)
    if not entity then
        destroy_panel(player, frame)
        return
    end

    local content = frame[GR_GUI_CONTENT]
    if not (content and content.valid) then return end

    local state = get_panel_state(player, panel_key(frame))
    --顶栏：读取器换了（虚影建成真实读取器）就换预览实体；预览内容由引擎实时绘制，不需要重画
    local unit = entity.unit_number
    if state.unit ~= unit then
        state.unit = unit
        local preview_box = content[GR_GUI_PREVIEW_BOX]
        if preview_box and preview_box.valid then
            local preview = preview_box[GR_GUI_PREVIEW]
            if preview and preview.valid then preview.entity = entity end
        end
    end

    --「连接至」状态行（读到哪个归属地/是否不在物流网络内）
    update_link_row(content, entity)

    --信号表：内容没变就不重建（重建要 clear + 逐个新建按钮，是面板刷新的主要开销）。
    --虚影没有归属地与电路输出，但面板同样显示按位置预览的信号（与 dop1 一致）
    local counts = meta.output_of(entity)
    if not same_counts(state.counts, counts) then
        state.counts = counts
        local table_frame = content[GR_GUI_TABLE_FRAME]
        if table_frame and table_frame.valid then
            rebuild_table(table_frame[GR_GUI_TABLE], counts)
        end
    end
end

---登记一个位置的面板待刷新（读取器变动时由 events 调用）。
---没有面板打开时直接返回：不拼位置键、不做任何事。
---@param surface_index int|nil
---@param position MapPosition|nil
local function mark_dirty(surface_index, position)
    if open_panels == 0 then return end
    if type(surface_index) ~= "number" or not position then return end
    dirty_panels[pos_key(surface_index, position.x, position.y)] = true
end

---刷新本帧被登记过的已打开面板。
---没有登记时立即返回（不遍历玩家、不重算信号）；有登记时先取走登记表，
---再只遍历一次 player，处理位置命中且确实开着的面板。
---
---dirty_regions：本帧计数发生变化的归属地集合（可选）。读取器虚影不是归属地读者
---（它没有 reader_region），拿不到 dirty_reader_output，所以虚影面板还要靠
---"面板当前所在归属地是否在集合里"来判断；真实读取器面板一般已被登记位置，不会重复刷新。
---@param dirty_regions table<region,true>|nil
local function refresh_dirty(dirty_regions)
    local keys = dirty_panels
    local regions = (dirty_regions and next(dirty_regions)) and dirty_regions or nil
    if next(keys) == nil and not regions then return end
    dirty_panels = {}
    for _, player in pairs(game.players) do
        if player and player.valid then
            local frame = player.gui.screen[GR_GUI_FRAME]
            if frame and frame.valid then
                if keys[panel_key(frame)] then
                    refresh_panel(player, frame)
                elseif regions then
                    local entity = frame_reader(frame)
                    local panel_region = entity and meta.region_of(entity)
                    if panel_region and regions[panel_region] then
                        refresh_panel(player, frame)
                    end
                end
            end
        end
    end
end

---构建读取器面板
---@param player LuaPlayer
---@param entity LuaEntity 读取器（真实实体或其虚影）
local function build(player, entity)
    local old = player.gui.screen[GR_GUI_FRAME]
    if old and old.valid then destroy_panel(player, old) end
    player.opened = nil

    local unit = entity.unit_number
    local frame = player.gui.screen.add {
        type = "frame", name = GR_GUI_FRAME, direction = "vertical", tags = pos_tag(entity),
    }
    open_panels = open_panels + 1
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
    add_dropdown_row(content, { "gr-gui.range-mode" }, GR_GUI_MODE, range_options(), config.get_mode(unit))
    add_dropdown_row(content, { "gr-gui.filter" }, GR_GUI_FILTER, filter_options(), config.get_filter(unit))
    add_dropdown_row(content, { "gr-gui.qty" }, GR_GUI_COUNT, count_options(), config.get_count(unit))
    add_dropdown_row(content, { "gr-gui.quality" }, GR_GUI_QUALITY, quality_options(), config.get_quality(unit))
    content.add { type = "line" }
    local table_flow = content.add { type = "scroll-pane", name = GR_GUI_TABLE_FRAME, style = "deep_slots_scroll_pane" }
    local subheader_frame = table_flow.add { type = "frame", style = "logistic_section_subheader_frame" }
    subheader_frame.style.width = GR_GUI_PREVIEW_WIDTH
    subheader_frame.add { type = "label", caption = { "gr-gui.output" }, style = "subheader_label" }
    table_flow.add { type = "table", name = GR_GUI_TABLE, style = "gr_table", column_count = 10 }
    --记下面板当前显示的状态：之后的按需刷新用它们判断"读取器换了没有""信号变了没有"
    local counts = meta.output_of(entity)
    local state = get_panel_state(player, panel_key(frame))
    state.unit = unit
    state.counts = counts
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
    if frame and frame.valid then destroy_panel(player, frame) end
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
    destroy_panel(player, frame)
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

    if #option > 2 then
        element.tooltip = option[3]
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
    if player then
        --配置变更立即生效：登记所有打开该读取器的面板并当场刷新一次
        --（不等到下一帧；也用不到遍历全体玩家之外的东西）
        mark_dirty(reader.surface.index, reader.position)
        refresh_dirty()
    end
end

--================================================================================================
-- 由主管线驱动
--================================================================================================

---当前是否有面板打开。events 用它把"没有面板打开"的情况做成真正的零开销：
---连位置键都不拼、也不调用 refresh_dirty。
---@return boolean
function M.has_open_panels()
    return open_panels > 0
end

---重建后按实际面板数重算打开计数。
---面板是存档的一部分、会随读档保留，而模块级计数会随 control.lua 重跑归零，
---所以读档/配置变化后的全量重建末尾必须调一次（见 events.rebuild）。
function M.resync_open_panels()
    local count = 0
    for _, player in pairs(game.players) do
        if player and player.valid then
            local frame = player.gui.screen[GR_GUI_FRAME]
            if frame and frame.valid then count = count + 1 end
        end
    end
    open_panels = count
    if open_panels == 0 then dirty_panels = {} end
end

---登记一个位置的面板待刷新（读取器变动时由 events 调用）。
---@param surface_index int|nil
---@param position MapPosition|nil
function M.mark_dirty(surface_index, position)
    mark_dirty(surface_index, position)
end

---刷新本帧被登记过的已打开面板（on_tick 末由 events 调用）。
---@param dirty_regions table<region,true>|nil 本帧计数变化的归属地（供虚影面板判断）
function M.refresh_dirty(dirty_regions)
    refresh_dirty(dirty_regions)
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
            { { "gr-tooltip.current-range" }, status_text(reader) },
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
