-- ghost-reader / data.lua
--
-- Adds a custom constant-combinator style entity "ghost-reader" (虚影读取器).
-- It reads every ghost inside the construction range of the logistics network it
-- is part of (entity ghosts + tile ghosts + upgrade requests + item requests)
-- and outputs, as per-item signals, the count of each, using the
-- constant-combinator control behavior's section slots. Wiring it into a circuit
-- network makes those counts readable.

local function deepcopy(orig)
  if type(orig) ~= "table" then return orig end
  local copy = {}
  for k, v in pairs(orig) do
    copy[deepcopy(k)] = deepcopy(v)
  end
  return copy
end

-- Rewrite every constant-combinator sprite/icon filename so the entity uses
-- copies stored inside this mod instead of the vanilla files.
--
-- Two conditions must hold for a path to be rewritten:
--   * it lives under the vanilla combinator sprite folder, and
--   * it is one of OUR sprites, i.e. its file name contains "constant-combinator".
-- The second test matters: the same folder also holds sprites shared by the
-- other combinators (e.g. combinator/combinators-reflection.png), which this mod
-- deliberately does not copy and therefore must keep pointing at __base__.
-- Note that "constant-combinator" also covers the remnant sheet, whose path is
-- combinator/remnants/constant/constant-combinator-remnants.png.
local function redirect_sprites(t)
  for k, v in pairs(t) do
    if type(v) == "string" then
      if v:find("__base__/graphics/entity/combinator/", 1, true)
          and v:find("constant-combinator", 1, true) then
        t[k] = v:gsub("__base__/graphics/entity/combinator/", "__ghost-reader__/graphics/entities/")
      elseif v:find("__base__/graphics/icons/constant-combinator", 1, true) then
        t[k] = v:gsub("__base__/graphics/icons/", "__ghost-reader__/graphics/icons/")
      elseif v == "entity-name.constant-combinator" then
        t[k] = "entity-name.ghost-reader"
      end
    elseif type(v) == "table" then
      redirect_sprites(v)
    end
  end
end

local base_cc = data.raw["constant-combinator"]["constant-combinator"]
local base_ccr = data.raw["corpse"]["constant-combinator-remnants"]
-- A constant-combinator variant (same 1x1 size, read-only output, no power).
---@type ConstantCombinatorPrototype
local ghost_reader = deepcopy(base_cc)
ghost_reader.name = "ghost-reader"
ghost_reader.minable = { mining_time = 0.1, result = "ghost-reader" }
ghost_reader.fast_replaceable_group = nil
ghost_reader.flags = { "placeable-player", "player-creation" }
-- The prototype field is `corpse` (EntityWithHealthPrototype) and it takes one
-- EntityID or an array of them. `corpses` is a *runtime* read-only property on
-- LuaEntity, not a prototype key: setting it in the data stage does not bind
-- anything, so the copy kept the inherited vanilla corpse
-- "constant-combinator-remnants" (and with it the vanilla remnant texture).
ghost_reader.corpse = "ghost-reader-remnants"

local ghost_reader_remnants = deepcopy(base_ccr)
ghost_reader_remnants.name = "ghost-reader-remnants"
-- Use our own copies of the sprites / activity LEDs.
redirect_sprites(ghost_reader)
redirect_sprites(ghost_reader_remnants)
data:extend { ghost_reader, ghost_reader_remnants }

-- 面板（读取器 GUI）用的样式：数据阶段定义、全部继承原版样式，只写差异部分。
-- 这样原版主题（贴图/配色/内边距/圆角）一改，我们的控件自动跟着变；运行期因此完全不需要
-- 去写颜色和贴图路径——那才是版本脆弱性的主要来源。
-- 样式名是全局命名空间，加前缀隔离；继承链见 data/core/prototypes/style.lua。
local gui_styles = data.raw["gui-style"].default

-- 面板顶栏「连接至：<单位号> ⓘ」那一行：原版实体面板顶栏是深色内嵌行
gui_styles["gr_gui_panel_row"] = {
  type = "frame_style",
  parent = "subheader_frame",
  top_margin = -8,
  left_margin = -12,
  right_margin = -12,
  horizontally_stretchable = "on",
  horizontally_squashable = "on",
}

gui_styles["gr_subheader_frame"] = {
  type = "frame_style",
  parent = "inside_shallow_frame",
  vertically_stretchable = "on",
}

gui_styles["gr_table"] = {
  type = "table_style",
  horizontal_spacing = 0,
  vertical_spacing = 0,
  horizontally_stretchable = "on",
  vertically_stretchable = "on",
}

-- 棋盘格实体预览区的外框（棋盘格与实体本身由 entity-preview 元素绘制）
gui_styles["gr_gui_panel_preview"] = {
  type = "frame_style",
  horizontally_stretchable = "on",
  height = 152,
  natural_height = 152,
  ignored_by_search = true,
}

-- 标题栏：原版把这些定义成 frame 里的匿名子样式（title_style / header_filler_style），
-- 运行期取不到名字，所以照抄成具名样式。数值逐项来自 data/core/prototypes/style.lua=
--   frame.title_style        = parent frame_title + top_margin -3 + bottom_padding 3
--   frame.header_filler_style = parent draggable_space_header + 双向可伸展 + height 24
gui_styles["gr_gui_window_title"] = {
  type = "label_style",
  parent = "frame_title",
  top_margin = -3,
  bottom_padding = 3
}

gui_styles["gr_gui_header_filler"] = {
  type = "empty_widget_style",
  parent = "draggable_space_header",
  horizontally_stretchable = "on",
  vertically_stretchable = "on",
  height = 24
}

local icon = "__ghost-reader__/graphics/icons/constant-combinator.png"
local icon_size = base_cc.icon_size or 64

data:extend {
  {
    type = "item",
    name = "ghost-reader",
    icon = icon,
    icon_size = icon_size,
    subgroup = "circuit-network",
    order = "c[combinators]-h[ghost-reader]",
    place_result = "ghost-reader",
    stack_size = 50
  },
  {
    type = "recipe",
    name = "ghost-reader",
    enabled = false,
    energy_required = 0.5,
    ingredients = {
      { type = "item", name = "construction-robot", amount = 1 },
      { type = "item", name = "copper-cable",       amount = 5 }
    },
    results = {
      { type = "item", name = "ghost-reader", amount = 1 }
    }
  },
  {
    type = "technology",
    name = "ghost-reader",
    icon = icon,
    icon_size = icon_size,
    prerequisites = { "construction-robotics" },
    unit = {
      count = 50,
      ingredients = {
        { "automation-science-pack", 1 }, -- 红瓶
        { "logistic-science-pack", 1 },   -- 绿瓶
        { "chemical-science-pack", 1 }    -- 蓝瓶
      },
      time = 30
    },
    effects = {
      { type = "unlock-recipe", recipe = "ghost-reader" }
    }
  }
}
