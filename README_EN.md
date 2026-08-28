# Ghost Reader

**Version 1.1.0** · Requires Factorio 2.1 (including Space Age)

In vanilla Factorio, the tasks of construction robots cannot be read as circuit signals, yet this is crucial for automating construction. This mod focuses on solving that. It adds a new entity that reads the ghost requests within the whole surface or its logistics network and outputs them as circuit signals, fully configurable via a GUI. It supports adjusting the filter mode (buildings | tiles | upgrades | temporary item requests) and the quantity mode (supply requests | recycling requests).

---

# For Players

## What this mod does

In vanilla Factorio, the tasks of construction robots cannot be read as circuit signals, yet this is crucial for automating construction. This mod focuses on solving that. Ghost Reader aggregates all those requests into a clear item list and outputs it as circuit signals, letting you automate material-deficit calculations, drive display panels, or feed logistics requests.

It reads four kinds of requests and tracks them in two directions — **supply** and **recycling**:

| Type | Supply | Recycling (to be deconstructed/recovered) |
| ---- | ---- | ---- |
| Buildings | Ghost of a building to be built | Building marked for deconstruction |
| Tiles | Ghost of a tile to be placed | Tile marked for deconstruction |
| Upgrades | The upgraded target building | The original building replaced by the upgrade |
| Temporary item requests | Requested items to deliver | Storage-slot recycling requests (remove items) |

- **Supply** = items construction robots are **missing** while working.
- **Recycling** = items construction robots will **deconstruct or recover**.

## Unlocking

- Research the "Ghost Reader" technology (prerequisite: **construction robotics**).

## How to use

1. Place a "Ghost Reader".
2. Connect it to a circuit network with red/green wires.
3. Click the reader to open its GUI panel and set the scan range, filter, and quantity modes.
4. The circuit network will then carry each item's signal, computed according to the current quantity mode.

## GUI panel

A standard vanilla-styled, draggable window with a close button in the top-right corner.

- **Scan range mode**
  - `Surface`: scan every request on the whole planet surface.
  - `Logistics network`: scan only the requests inside the reader's logistics network (construction area).
- **Current range**: shows the active range in real time.
  - Surface mode: shows the location, e.g. `【Nauvis】`.
  - Logistics network mode: shows `【Network #id】`.
- **Filter mode**
  - `All`: buildings + tiles + upgrades + temporary item requests.
  - `Buildings` / `Tiles` / `Upgrades` / `Temp item requests`: only the selected category.
- **Quantity mode**
  - `Supply - Recycling`: outputs supply minus recycling (may be negative, for net deficit).
  - `Supply only`: outputs supply quantities only.
  - `Recycling only`: outputs recycling quantities only.
- **Current output signals**: lists the signals to be output in real time, using the vanilla signal-icon style (icon with the count in the bottom-right corner).

## Calculation details (important)

- In **logistics network mode**, buildings, tiles, upgrades, and temporary item requests are all computed as the **union** of each roboport's **construction area** (the green area). Because only requests (or ghosts) whose center point falls inside the construction area can be served by construction robots, the inclusion check matches that rule.
- In **logistics network mode**, the reader itself must be inside some roboport's **supply area** (the orange area) to be considered "in a logistics network".
- Temporary item requests on moving entities (e.g. tanks, spidertrons) are counted as well.
- If a container building (e.g. a chest) is marked for deconstruction, the items **already inside it** are also counted as recycling, and its temporary item requests are voided (not double-counted).

---

# For Mod Developers

This section is for developers who want to quickly understand the mod's structure in order to modify or reuse it. It describes the design logic only, without diving into specific code.

## Structure overview

The mod is split into three files with clear responsibilities:

- **data.lua** — declares the new entity. It copies the vanilla constant-combinator prototype into a same-named custom entity and redirects its internal sprite references to graphics shipped inside this mod (no dependency on `__base__`), then registers the corresponding item, recipe, and technology.
- **data-updates.lua** — prepares reading of "temporary item requests". It attaches a creation effect to the vanilla item-request-proxy prototype so that every such entity sends a script event when created (see "Temporary item requests" below).
- **control.lua** — all runtime logic: range determination, request scanning, signal output, GUI, and event-driven updates.

## Core data flow

1. **Define the range**: each reader decides its scan range from "surface" or "the construction area of its logistics network".
2. **Two-way scan**: within each construction area, count **supply** (deliver) and **recycling** (remove/recover) separately.
3. **Combine quantities**: merge the two counts into a final per-item signal table according to the selected quantity mode (net / supply only / recycling only).
4. **Output signals**: write each item signal into the entity's constant-combinator control behavior slots.
5. **GUI display**: present the current range, mode selections, and live output signals in a standard vanilla-styled window.

## Range determination

- **Surface mode**: scan the whole surface.
- **Logistics network mode**: first confirm the reader sits inside some roboport's **supply area** to determine its network, then scan the **union** of the **construction areas** of all roboports in that network. Requests overlapping multiple ports are deduplicated.
- Only requests (or ghosts) whose **center point** falls inside the construction area are counted, matching the game's rule for whether a construction robot can respond.

## Two-way scan (supply / recycling)

The scan maintains two count tables at once:

- **Supply** comes from: building ghosts, tile ghosts, upgrade target buildings, and temporary item request delivery requests.
- **Recycling** comes from: deconstruction-marked buildings, deconstruction-marked tiles, original buildings replaced by upgrades, temporary item request removal requests, and items already inside deconstructed containers.

## Temporary item requests (item-request-proxy)

This is a special kind of request: vanilla does not expose its creation, so the mod fills that gap with events:

- Via the creation effect in data-updates.lua, the script is notified every time a temporary request entity appears.
- The script tracks it event-driven and cleans up when it is removed/destroyed, avoiding whole-map polling.
- For a temporary request, "supply" reads the items it requests to deliver; "recycling" reads its removal plan, using the actual stock in its target container as the recycling quantity.

## Event-driven updates

The mod prefers event-driven updates over per-frame polling:

- Changes such as ghost create/destroy, upgrade marking, roboport add/remove, and temporary request create/remove all set a "needs rescan" flag.
- On the next game tick, a single rescan and signal refresh runs, avoiding wasted work.
- Open GUI panels refresh their live values on a fixed interval (every 30 ticks).
- Multiple readers on the same surface/network/mode share one scan result, avoiding duplicate computation.

## File structure

```
ghost-reader/
├── info.json            # Mod metadata (name=ghost-reader, version=1.1.0)
├── data.lua             # Entity/item/recipe/technology + sprite redirect
├── data-updates.lua     # Creation effect for reading temporary item requests
├── control.lua          # Scanning, two-way counting, signal output, GUI, events
├── graphics/            # Copied vanilla sprites & icons (no __base__ refs)
├── locale/en|zh-CN/     # Localization
└── thumbnail.png
```
