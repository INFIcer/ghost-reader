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

-- bplib: ask bplib to raise "bplib-extract" whenever a ghost-reader is copied
-- into a user blueprint, so control.lua can persist its config into the
-- blueprint's tags. Runs here (after bplib's data.lua) so the mod-data exists.
-- Only the reader is registered -- a vanilla constant-combinator is never
-- tagged, so its config can never be copied onto a reader (and vice versa).
if data.raw["mod-data"] and data.raw["mod-data"]["bplib"] then
  -- Register the real reader AND its ghost form. bplib matches entities by
  -- `entity.name`, so a reader ghost (name "entity-ghost") needs its own entry;
  -- control.lua filters by ghost_name so a vanilla ghost is never tagged.
  data.raw["mod-data"]["bplib"].data.extract_entity_names["ghost-reader"] = true
  data.raw["mod-data"]["bplib"].data.extract_entity_names["entity-ghost"] = true
  data.raw["mod-data"]["bplib"].data.position_entity_names["ghost-reader"] = true
  data.raw["mod-data"]["bplib"].data.position_entity_names["entity-ghost"] = true
  data.raw["mod-data"]["bplib"].data.overlap_entity_names["ghost-reader"] = true
  data.raw["mod-data"]["bplib"].data.overlap_entity_names["entity-ghost"] = true
end
