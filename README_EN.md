# Ghost Reader

**Version 1.2.0** · Requires Factorio 2.1 (including Space Age)

In vanilla Factorio, the tasks of construction robots cannot be read as circuit signals, yet this is crucial for automating construction. This mod focuses on solving that. It adds a new entity that reads the ghost requests within the whole surface or its logistics network and outputs them as circuit signals, fully configurable via a GUI. It supports adjusting the filter mode (entities | tiles | upgrades | items), the quantity mode (supply requests | recycling requests), and quality filtering.

---

# For Players

## What this mod does

In vanilla Factorio, the tasks of construction robots cannot be read as circuit signals, yet this is crucial for automating construction. This mod focuses on solving that. Ghost Reader aggregates all those requests into a clear item list and outputs it as circuit signals, letting you automate material-deficit calculations, drive display panels, or feed logistics requests.

It reads four kinds of requests and tracks them in two directions — **supply** and **recycling**:

| Type | Supply | Recycling (to be deconstructed/recovered) |
| ---- | ---- | ---- |
| Entities | Ghost of an entity to be built | Entity marked for deconstruction |
| Tiles | Ghost of a tile to be placed | Tile marked for deconstruction |
| Upgrades | The upgraded target entity | The original entity replaced by the upgrade |
| Items | Requested items to deliver | Items already inside a deconstructed entity (including modules), storage-slot recycling requests (remove items), recycling products of environment entities (trees/fish/rocks...), on-ground items |

> **About "Items"**: here, "items" refers to item requests produced when you perform a **ghost operation on an entity's storage slots** (set directly in remote view), which are served by **construction robots**. It does **not** refer to the item-logistics requests served by logistics robots.

- **Supply** = items construction robots are **missing** while working.
- **Recycling** = items construction robots will **deconstruct or recover**.

## Unlocking

- Research the "Ghost Reader" technology (prerequisite: **construction robotics**).

## How to use

1. Place a "Ghost Reader".
2. Connect it to a circuit network with red/green wires.
3. Click the reader to open its GUI panel and set the scan range, filter, quantity, and quality modes.
4. The circuit network will then carry each item's signal, computed according to the current quantity mode.

## GUI panel

A standard vanilla-styled, draggable window with a close button in the top-right corner.

- **Scan range mode**
  - `Surface`: scan every request on the whole planet surface.
  - `Logistics network`: scan only the requests inside the reader's logistics network (construction area).
- **Current range**: shows the active range in real time.
  - Surface mode: shows the location.
  - Logistics network mode: shows `network#id`.
- **Filter mode**
  - `All`: entities + tiles + upgrades + items.
  - `Entities` / `Tiles` / `Upgrades` / `Items`: only the selected category.
- **Quantity mode**
  - `Supply - Recycling`: outputs supply minus recycling (may be negative, for net deficit).
  - `Supply only`: outputs supply quantities only.
  - `Recycling only`: outputs recycling quantities only.
- **Quality filter**
  - `All`: no quality filtering.
  - A specific quality: only items of that quality.

## Calculation details (important)

- In **logistics network mode**, entities, tiles, upgrades, and items are all computed as the **union** of each roboport's **construction area** (the green area). Because only requests (or ghosts) whose center point falls inside the construction area can be served by construction robots, the inclusion check matches that rule.
- In **logistics network mode**, the reader itself must be inside some roboport's **supply area** (the orange area) to be considered "in a logistics network".
- Targets belonging to **neutral/enemy forces** (trees, rocks, on-ground items, biter nests...) have no logistics network of their own; they are attributed by position to the player-force networks covering them. Entities of a player force only use their own force's construction areas.
- Item requests on moving entities (e.g. tanks, spidertrons) are counted as well.
- If a container entity (e.g. a chest) is marked for deconstruction, the items/modules **already inside it** are classified under the "items" category as recycling, and its temporary item requests are voided (not double-counted).

---

# For Mod Developers

This section is for developers who want to quickly understand the mod's structure in order to modify or reuse it.

## Structure overview

- **data.lua** — declares the new entity. It copies the vanilla constant-combinator prototype into a same-named custom entity and redirects its internal sprite references to graphics shipped inside this mod (no dependency on `__base__`), then registers the corresponding item, recipe, and technology.
- **data-updates.lua** — prepares reading of "item requests". It attaches a creation effect to the vanilla item-request-proxy prototype so that every such entity sends a script event when created.
- **control.lua** — the **entry file**: it requires the modules under `dop2/` in dependency order, injects the cross-module dependency, and finally calls `events.register()`.
- **dop2/** — all runtime logic, split into 14 modules by responsibility (see "File structure").

> The `dop/` directory holds the pre-refactor implementation (one large control.lua) as a backup; it is not loaded. To go back, copy `control_dop.lua` over `control.lua`.

## Modules (dop2/)

| Module | Responsibility |
| ---- | ---- |
| `lib.lua` / `enum.lua` | Global constants (`READER`, count-item names, `QUALITY_ALL`), helpers, and enums (`change_type` / `range_mode` / `filter_mode` / `count_mode`). They write globals at load time, so they must be required first |
| `config.lua` | Reader configuration (range/filter/quantity/quality), stored per entity unit number in `storage.readers` |
| `counter.lua` | Two-level count table: item name → quality name → count |
| `count_item.lua` | Count item: `change_type` → `counter` |
| `item.lua` | Item/tile resolution, entity-carried item accounting, IRP detail extraction |
| `region.lua` | Regions (surface / logistics network), their members, and merged counts |
| `meta.lua` | Entity meta and count items (registration number → meta); assembles reader output |
| `snapshot.lua` | Fingerprint snapshot polling (contents / position / IRP) |
| `gui.lua` | Reader panel and tooltip |
| `bplib.lua` | Blueprint tag persistence (requires bplib) |
| `paste.lua` | Copy-paste: isolation from vanilla constant combinators + config inheritance between readers |
| `events.lua` | Event layer + `on_tick` pipeline + initialization / full rebuild |

## Core data flow

1. **Configuration**: each reader reads either "the surface" or "its logistics network" region, plus three filters (category / quantity / quality).
2. **Count entities**: every tracked entity (ghosts, deconstruction-marked entities, upgrade-marked entities, IRP target containers, the reader itself, roboports) has a meta holding one or more **count items**.
3. **Region merging**: a count entity belongs to both "its surface" and "the logistics network(s) covering it"; a region merges all its members' count items into one table.
4. **Dirty-marking pipeline**: events only set dirty flags (they never compute); `on_tick` resolves them in a fixed order: re-resolve regions → propagate counts → merge regions → reader region → reader output.
5. **Signal output**: the reader reads its own region's merged table, filters it (recycling kinds are negated in net mode), and writes it into the constant-combinator slots; when slots run out it creates further sections (1000 slots per section, the engine's hard cap).

## Count items and categories

A count item is a "count table classified by `change_type`"; readers filter by category. One entity may carry several at once:

| Count item | Contents | Category |
| ---- | ---- | ---- |
| `ghost` | Entity ghost / tile ghost | Entity supply / tile supply |
| `upgrade` | Upgrade marking: target (supply) and original (recycling) | Upgrade supply / upgrade recycling |
| `deconstruction-entity` | The deconstruction-marked entity itself (also the "is marked" test) | Entity recycling |
| `deconstruction-tile` | Deconstruction-marked tile (represented by the deconstructible-tile-proxy) | Tile recycling |
| `deconstruction-inventory` | Items inside entities **with internal storage**: robots carry them away one by one, polled by a content snapshot | Item recycling |
| `deconstruction-instant` | Recycling products of **instantly removed** things (environment entities, on-ground items): counted once at marking | Item recycling |
| `irp<reg_num>` | Requested (supply) and removal plan (recycling) of an IRP, stored on the target container | Item supply / item recycling |

"Contents" therefore splits into two kinds, backed by two pairs of functions in `item.lua`:

- `has_inventory_contents` / `inventory_contents`: has storage slots, or a belt/inserter keeping goods on a transport line or held stack → a **content snapshot** tracks it as robots carry things away.
- `is_instant_recycle` / `instant_recycle_items`: environment entities (mineable products) and on-ground items (stack) → **counted once at marking**, no snapshot (so deconstructing a whole forest creates none).

Other sources: belt transport lines, inserter held stacks, container inventories, and IRP request/removal details.

## Region model

- Regions are derived from engine objects and keyed by the registration number from `register_on_object_destroyed`: **logistics-network regions** and **surface regions**.
- A count entity's regions = every logistics network covering its position + its surface; a reader picks one of the two according to its range mode.
- Force rule: an entity of a **player force** only queries its own force's construction areas; an entity of a force **without players** (neutral: trees/rocks/ground items; enemy: nests...) scans every player force's construction areas — its own force has no logistics network, so querying only that would find nothing.
- On a network **merge**, the engine fires `on_object_destroyed` for the vanished network (`type=logistic_network`, `useful_id` = network_id), which is how the region is reclaimed and its members re-resolved.
- On a network **split**, the engine destroys no network at all (the surviving half keeps the old id, the split-off half gets a new one), so it is derived from the **destroyed roboport**: every member of that port's former network region is marked dirty and re-resolved.

## Snapshot subsystem

Some changes have no native event (robots gradually emptying a chest, an entity being dragged away, an IRP being partially supplied), so they use "snapshot + fingerprint" polling:

- Three kinds: contents (`inventory_contents`), position (tile-position fingerprint), and IRP (one counter each for requests and removals).
- A snapshot runs once at creation (`previous = nil`), so **the event layer only creates snapshots**: "creation completes the first count", it does not write those count items itself.
- Scheduling: a fixed per-tick budget (default 8). Two generations (active / inactive) each rotate three lists ("checked last round / checked this round / not yet checked this round"); a snapshot with 30 consecutive unchanged checks moves to the inactive generation and is polled more sparsely.
- The pending queue advances with a **cursor** (never `table.remove` at the head) and removal is **lazy** (a `dead` flag), so batch destruction cannot cause periodic stutter tied to queue length.

## Event-driven updates

The mod prefers event-driven updates over per-frame polling:

- Ghost create/destroy, deconstruction/upgrade marking, roboport add/remove, IRP creation, and config changes only set dirty flags; `on_tick` resolves them once.
- When a region itself is destroyed (network merge) or a port removal shrinks a network, its members are marked dirty and re-resolved.
- An open panel refreshes every tick, but the **signal table is fingerprint-gated**: GUI elements are not rebuilt while the content is unchanged.

## Blueprints and copy-paste

- **Blueprints**: via bplib's custom events, the reader config is written into the blueprint entity's tags (`gr_mode` / `gr_filter` / `gr_count` / `gr_quality`); on placement the config is remembered per position (`pending_tags`), consumed by the ghost, which leaves `ghost_cfg` behind for the real reader built at the same spot to inherit.
- **Copy-paste**: readers are isolated from vanilla constant combinators (same entity type) — copying a reader does not carry its output signals over as a combinator configuration; between readers (including ghosts) the config is inherited.

## Initialization and full rebuild

- Module-level registries (meta / regions / snapshots) are not stored in `storage` and are empty after a load, so `on_load` only sets `needs_rebuild`; the first tick performs one full rebuild: clear registries → surface regions → roboports → readers → ghosts (entity/tile) → upgrade marks → deconstruction marks → tile proxies → IRPs.
- `on_configuration_changed` rebuilds directly. The rebuild reuses exactly the same functions as the event path, so both paths register identical state.

## Performance notes

- Everything is dirty-marked and resolved once per tick; there is practically no whole-surface scanning. A roboport's construction area is scanned with type filters (only ghosts, tile ghosts, tile proxies, IRPs and deconstruction/upgrade-marked entities are registered), so trees and rocks in the area are not turned into count entities.
- Region merging only recomputes when a region is marked dirty; membership changes are plain hash lookups and in-place add/remove.
- Snapshots have a per-tick budget and active/inactive generations, so steady-state cost is independent of the total number of snapshots.
- Panel refresh is fingerprint-gated, so no GUI elements are created or destroyed while signals are unchanged.

## Pitfalls worth remembering

- **Never use prototype objects as table keys**: `prototypes.item["iron-plate"]` returns a **different userdata** on every call (`a == b` is true only via the engine's `__eq`, while Lua table keys use raw identity), so the same item would never merge (several piles of one item would collapse into one pile's count). Count tables/count items therefore key on **name strings**; `counter.lua` errors on a non-string key and `ensure_quality` only accepts quality names.
- **In 2.x, object methods obtained from an object are already bound closures**: hence this project writes `parent.add{...}` and `bp.set_stack{...}` (dot, no self). Passing self again via `pcall(obj.method, obj, {...})` fails with `Expected 1 argument but 2 were given`.
- **`require` may only be called while control.lua is being parsed**; calling it at runtime raises `Require can't be used outside of control.lua parsing`. Since `meta` and `snapshot` depend on each other, the entry injects it with `meta.inject_snapshot(snapshot)` after both are loaded instead of requiring lazily inside a function.
- **`LuaLogisticSection.filters_count` is "how many filters this section currently has", not its slot capacity** (it is 0 after clearing); a constant-combinator section caps at 1000 slots and `set_slot` beyond that raises an error.
- **Coordinates in bplib events use its internal array form `{x, y}`** (its type annotation says `MapPosition`, which is easy to trip over); accept both forms.

## File structure

```
ghost-reader/
├── info.json            # Mod metadata (name=ghost-reader, version=1.2.0)
├── data.lua             # Entity/item/recipe/technology + sprite redirect
├── data-updates.lua     # Creation effect for reading item requests
├── control.lua          # Entry: requires dop2/ modules + dependency injection + event registration
├── control_dop.lua      # Backup entry for the old (dop/) version
├── dop2/                # Runtime implementation (see "Modules")
├── dop/                 # Pre-refactor implementation, backup only
├── graphics/            # Copied vanilla sprites & icons (no __base__ refs)
├── locale/en|zh-CN/     # Localization
└── thumbnail.png
```
