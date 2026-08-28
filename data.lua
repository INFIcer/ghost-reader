-- ghost-reader / data.lua
--
-- Adds a custom constant-combinator style entity "ghost-reader" (虚影读取器).
-- It reads every ghost inside the construction range of the logistics network it
-- is part of (entity ghosts + tile ghosts + upgrade requests + temporary item
-- requests) and outputs, as per-item signals, the count of each, using the
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
local function redirect_sprites(t)
  for k, v in pairs(t) do
    if (k == "filename" or k == "icon") and type(v) == "string" then
      if v:find("graphics/entity/combinator/constant%-combinator") then
        t[k] = v:gsub("__base__/graphics/entity/combinator/", "__ghost-reader__/graphics/entities/")
      elseif v:find("graphics/icons/constant%-combinator") then
        t[k] = v:gsub("__base__/graphics/icons/", "__ghost-reader__/graphics/icons/")
      end
    elseif type(v) == "table" then
      redirect_sprites(v)
    end
  end
end

local base_cc = data.raw["constant-combinator"]["constant-combinator"]

-- A constant-combinator variant (same 1x1 size, read-only output, no power).
local ghost_reader = deepcopy(base_cc)
ghost_reader.name = "ghost-reader"
ghost_reader.minable = {mining_time = 0.1, result = "ghost-reader"}
ghost_reader.fast_replaceable_group = nil
ghost_reader.flags = {"placeable-player", "player-creation"}

-- Use our own copies of the sprites / activity LEDs.
redirect_sprites(ghost_reader)

data:extend{ghost_reader}

local icon = "__ghost-reader__/graphics/icons/constant-combinator.png"
local icon_size = base_cc.icon_size or 64

data:extend{
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
      {type = "item", name = "construction-robot", amount = 1},
      {type = "item", name = "steel-chest", amount = 1}
    },
    results = {
      {type = "item", name = "ghost-reader", amount = 1}
    }
  },
  {
    type = "technology",
    name = "ghost-reader",
    icon = icon,
    icon_size = icon_size,
    prerequisites = {"construction-robotics"},
    unit = {
      count = 50,
      ingredients = {
        {"automation-science-pack", 1},  -- 红瓶
        {"logistic-science-pack", 1},    -- 绿瓶
        {"chemical-science-pack", 1}     -- 蓝瓶
      },
      time = 30
    },
    effects = {
      {type = "unlock-recipe", recipe = "ghost-reader"}
    }
  }
}
