-- ghost-reader / data-updates.lua
--
-- Inline (no dependency) version of the "item-request-proxy-events" trick:
-- attach a `created_effect` to the vanilla item-request-proxy prototype so the
-- game fires on_script_trigger_effect (effect_id "gr-item-request-proxy") every
-- time an item-request-proxy is created. control.lua listens for that to detect
-- IRPs (item requests) without wide on_tick polling.
--
-- IRPs are the "item request" ghosts (e.g. set on a tile in remote view), and
-- are served by CONSTRUCTION robots, so they are read through
-- entity.item_requests.

if data.raw["item-request-proxy"] and data.raw["item-request-proxy"]["item-request-proxy"] then
  data.raw["item-request-proxy"]["item-request-proxy"].created_effect = {
    type = "direct",
    action_delivery = {{
      type = "instant",
      source_effects = {{
        type = "script",
        effect_id = "gr-item-request-proxy"
      }}
    }}
  }
end
