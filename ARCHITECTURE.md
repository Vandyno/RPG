# ARCHITECTURE.md

# Tile-Based 2D Open-World RPG Architecture

## Purpose

This file records the technical architecture for the game.

It should be updated when major implementation decisions are made.

The project is a story-driven 2D open-world RPG built on a seamless tile-based world with chunk streaming, authored content, persistent world state, and reusable RPG systems.

---

# Core Technical Principles

## One Continuous World

The player experiences the world as one continuous tile-based space.

The world uses global tile coordinates.

Chunks are used for performance, editing, loading, unloading, and saving. Chunks are not separate levels from the player's perspective.

## Grid-Aware Gameplay

Gameplay logic should be based on explicit world coordinates and tile data.

Characters are not locked to tile-by-tile movement. Player and NPC movement can
be continuous in world space while still sampling tile data for collision,
terrain, interaction range, combat range, line of sight, triggers, chunk
streaming, and save/load.

Automatic tap-to-move and tap-to-interact should plan through walkable grid
tiles while following smooth world-space waypoints. The planner must respect
the player collision footprint by validating waypoint centers with the same
standability checks used by continuous movement.

Grid-aware systems include:

- movement
- collision
- interaction
- pathfinding
- combat range
- line of sight
- triggers
- object placement
- NPC/enemy placement
- save/load
- chunk streaming

Visuals and character movement may be smooth, but the gameplay model should
remain tile-aware.

## Data-Driven Authored Content

Important content should be defined in data files, Godot resources, or authoring tools where practical.

Content includes:

- NPCs
- dialogue
- quests
- items
- shops
- readables
- enemies
- factions
- loot tables
- locations
- chunk placements
- world-state flags

Scripts should load and interpret content rather than hardcoding major content directly into scene logic.

## Explicit Persistent State

Persistent state should be owned by systems and serialized intentionally.

Do not rely on live scene nodes as the only source of truth.

Systems that own persistent state should provide save/load methods or clear serialization contracts.

---

# Coordinate Model

## Global Tile Coordinates

Every important world thing should be addressable through global tile coordinates.

Examples:

```text
Vector2i(0, 0)
Vector2i(500, 200)
Vector2i(-120, 830)
```

Global tile coordinates are used for:

- player location derived from world position
- chunk lookup
- object placement
- NPC/enemy spawn placement
- trigger placement
- location discovery
- save/load
- authored content references

## Chunk Coordinates

Chunks are rectangular groups of tiles.

Initial chunk size can be decided during implementation, but common candidates are:

- 32x32 tiles
- 64x64 tiles

Chunk coordinates should be derived from global tile coordinates.

Example:

```text
global_tile = Vector2i(130, -12)
chunk_size = 32
chunk_coord = Vector2i(4, -1)
```

The exact math should be centralized in a world/grid utility rather than duplicated across systems.

## World Layers

The first implementation can use a single world layer.

Future layers may include:

- surface
- underground
- interior
- dungeon

If layers are introduced, they should still use explicit coordinates and chunk-aware loading.

Possible layered coordinate shape:

```text
world_layer = "surface"
global_tile = Vector2i(500, 200)
chunk_coord = Vector2i(15, 6)
```

---

# World Streaming

## WorldStreamingManager

Owns the active world window around the player.

Responsibilities:

- track player global tile position
- calculate current chunk
- decide which chunks should be loaded
- request chunk data
- instantiate terrain visuals
- instantiate active entities
- unload distant chunks
- preserve modified chunk state
- notify systems when chunks load/unload

The streamer coordinates loading. It should not own quest, dialogue, inventory, readable, or combat rules.

## ChunkManager

Owns chunk data access.

Responsibilities:

- load chunk definitions
- load authored terrain regions from `data/world_terrain.json`
- cache active chunk data
- expose tile data
- expose object/entity placements
- track modified chunk state
- serialize modified chunk state
- provide debug information about loaded chunks

## EntityManager

Owns live scene instances for entities.

Responsibilities:

- spawn entities from chunk placement data
- despawn entities when chunks unload
- maintain stable IDs for persistent entities
- route save/load data for persistent entities
- expose entity lookup by ID and position where needed

---

# Data Ownership

## WorldStateManager

Owns global flags and story/world decisions.

Examples:

```text
flag_blacksmith_tools_returned
flag_miner_journal_read
flag_old_mine_gate_opened
flag_bandit_leader_spared
```

## QuestManager

Owns quest states, stages, objectives, rewards, and quest log state.
Objectives may include optional `target_id` metadata. The HUD uses that metadata
to show quest-target directions through live world entities, while quest state
remains owned by `QuestManager`.

## DialogueManager

Owns dialogue loading, condition evaluation, choice display, and dialogue effects.

## InventoryManager

Owns player inventory, item counts, item lookup, and container integration where appropriate.

## ShopManager

Owns shop transaction rules, buy prices, sell prices, currency checks, inventory
capacity checks, equipped-item sell protection, and trade action generation.
Shop stock is authored in `data/shops.json`; NPC definitions may reference a
shop with `shop_id`.

## EquipmentManager

Owns equipped item slots, validates equipment against inventory and item
definitions, exposes combat modifiers, and serializes equipped state.

## ReadableManager

Owns readable content, read/discovered tracking, readable UI opening, and read effects.

## CombatManager

Owns combat coordination, damage rules, enemy/player combat state integration, and combat events.

## FactionManager

Owns faction definitions, reputation, faction relationships, faction-based
conditions, and reputation save/load.

## ProgressionManager

Owns player level, experience, unspent skill points, progression save/load, and
small progression-derived combat modifiers.

Implemented training stats:

- `might`: increases player attack damage.
- `grit`: improves guarded counter-damage reduction.

## StatusEffectManager

Owns temporary player status effects, active attack charges, status-derived
combat modifiers, status save/load, and HUD refresh events. Status definitions
come from `data/status_effects.json`; authored effects apply them through
`apply_status`.

## TimeManager

Owns in-game day, minute-of-day, phase labels, time advancement, time save/load,
and future schedule hooks. Campfire rest and HUD Journal-tab wait actions advance
time through this manager, and authored effects can advance time with
`advance_time`.

## SaveManager

Coordinates serialization across systems.

SaveManager should ask each persistent system for its save data rather than reaching into live nodes randomly.

---

# System Boundaries

## Player

The player controller should own:

- movement input
- movement execution
- camera target behavior if appropriate
- interaction request input
- player-facing animation hooks

The player controller should not own:

- quest rules
- dialogue trees
- inventory data
- readable content
- faction reputation
- global world-state flags
- save file structure

## NPCs

NPC scenes should own presentation and local behavior.

NPCs should reference:

- NPC ID
- dialogue ID
- faction ID
- schedule ID later
- inventory ID later

NPCs should not hardcode full quest logic.

## Objects

World objects should use reusable components.

Examples:

- a readable object references a readable ID
- a pickup references an item ID
- a chest references a loot table or container ID
- a door references condition/lock data
- a shrine references interaction/effect data

Implemented early container objects use `kind: "container"` and
`effects_on_open`. Opened state is persisted by `ChunkManager` in
`modified_objects` so the object can remain visible while its loot is only
granted once.

Containers can include `open_conditions` and `locked_text` when the object
should remain visible but refuse opening until authored state is satisfied. This
is separate from world-object `conditions`, which control whether the object
spawns at all.

Door-like access objects use `kind: "door"` and the same opened-state,
`open_conditions`, `locked_text`, and `effects_on_open` machinery. This supports
route gates and locked doors now, while leaving collision/path blocking as a
later layer on top of the same authored data.

Town POIs use `kind: "poi"` for interactable places such as squares, stalls,
forges, shrines, and job boards. POIs surface authored descriptions in the HUD,
can discover linked locations, and can run one-time `effects_on_discover`.
POI `actions` reuse dialogue-style conditions, effects, and responses for
simple job-board interactions such as starting or reporting quests.
Service POIs can also open a named Systems tab directly; shop POIs expose a
`shop_id` so the Trade tab can operate from a place, not only an NPC.

`open_conditions` and spawn `conditions` can use progression checks such as
`stat_at_least`, allowing trained stats to unlock authored doors, containers,
dialogue, or spawned objects without special-case code.

Interactable world objects can include `interaction_radius` to expand their
targeting range without changing global defaults. This lets dense spawn-yard
test fixtures spread out while still exercising systems from the starting area.

World objects can also include `conditions`, using the same condition format as
dialogue and quests. `EntityManager` filters those objects during spawn and
refreshes the live entity set after world, quest, readable, inventory, faction,
progression, time, or load state changes.

## UI

UI should display state and route player choices to systems.

UI should not become the source of truth for game state.

The Systems HUD includes a Character tab for level, XP, training stats, and
spendable skill-point actions. Those buttons route back to gameplay systems in
the same way item actions do.

The Trade tab shows the currently selected trader's shop stock and sellable
inventory. Buy and sell buttons route through `ShopManager`; the HUD only
renders the actions it receives.

The Map and Quest tabs may show navigation summaries generated by
`EntityManager`. UI should treat those compass/distance strings as display
state, not as authority for interaction range, collision, or quest rules.
Target picker rows can also include the same direction text to support touch
selection without requiring the player to inspect the world grid.
Rows should include target kind labels, and the picker may show compact kind
counts so dense nearby systems remain scannable on horizontal phones.
Nearby interactable world entities also draw compact action hints over their
markers. These hints are tappable through the same world hit-test path as the
marker itself, so touch players can act on visible world affordances without
opening the target picker for routine interactions.
Visible action hints have priority over nearby marker hitboxes when taps
overlap. The selected target should always keep a visible hint even in dense
nearby clusters, and movement input should clear stale manual target locks so
the default action follows the player's current facing and movement intent.
World tap targeting uses a forgiving marker pick radius for mobile play, but it
must not use authored `interaction_radius` as a tap hitbox; broad interaction
ranges are for reachability, not for deciding what the player tapped.
When a selected POI has available authored actions, those actions should appear
in the context action strip and execute directly. The content card remains the
place for readable description and inspection, but routine place actions such
as taking a posted job or using a forge service should not require opening the
card and hunting for a choice button.
Selected NPCs may also expose context actions for effectful dialogue choices
and trader access. Flavor choices and refusals can stay inside the dialogue
card, but state-changing choices such as accepting an offered quest should be
available directly once the player has already targeted the NPC.
Effectful dialogue lines can also appear as explicit context actions when they
represent an immediate state change, such as turning in a quest. Dialogue
preview APIs may inspect valid lines and their effects, but previews must never
apply those effects.
Primary interaction should remain inspect/talk/use for normal NPC and POI
targets when context actions are present, so authored descriptions and dialogue
remain reachable. It may promote an unambiguous dialogue-line turn-in to the
primary action because that represents the currently selected quest handoff.
Selected world action hints should mirror that promoted primary action. For
example, an NPC ready for quest handoff should show `Turn In` in the world, and
that visible hint should be tappable through the normal world hit-test path.
The context action strip must support multiple actions on landscape mobile. It
should wrap into thumb-sized rows instead of shrinking text or forcing new
POI/NPC/combat actions into modal menus.
Live world entities referenced by active quest objectives draw compact quest
markers. The marker follows quest stage changes and clears when the objective
is no longer active, keeping short quest loops understandable from the world
view before the player opens the Quest tab.
The Map tab should also render discovered-location details from authored
location content, not only location names, so exploration state remains useful
without opening a debug-only panel.

UI should be built with landscape mobile as a first-class target. Future UI
systems should account for touch input, safe areas, scalable text, large touch
targets, and layouts that leave the world view playable on horizontal phone and
tablet screens. Debug or desktop-only UI may exist during development, but
player-facing UI should be verified at mobile landscape aspect ratios before it
is considered complete.

---

# Event Flow

Use signals or an EventBus for cross-system communication.

Effect application may emit concise player-facing feedback through the EventBus
when the runner is configured with one. Feedback should summarize meaningful
state changes such as quest starts, quest updates, quest completion rewards,
direct item gains/spends, reputation changes, and XP gains. Batch interactions
such as enemy defeat should summarize rewards rather than flooding the log and
hiding the primary result.

## Example: Readable Event Flow

1. Player interacts with a journal object.
2. `InteractionManager` calls the readable interaction.
3. `ReadableManager` opens readable UI.
4. When read, `ReadableManager` marks the readable as read.
5. `ReadableManager` emits `readable_read(readable_id)`.
6. `QuestManager` advances relevant objectives if applicable.
7. `WorldStateManager` sets relevant flags if configured.
8. `SaveManager` can persist read state and changed flags.

## Example: Quest Item Flow

1. Player picks up an item.
2. `InventoryManager` adds item.
3. EventBus emits `item_picked_up(item_id, count)`.
4. `QuestManager` checks whether active objectives care about that item.
5. Quest log UI updates if needed.

## Example: Enemy Defeated Flow

1. Enemy health reaches zero.
2. Enemy emits or reports `enemy_defeated(enemy_id, enemy_type, global_tile)`.
3. `CombatManager` resolves combat state.
4. `LootDropComponent` creates loot if configured.
5. `QuestManager` checks kill/clear objectives.
6. `WorldStateManager` records persistent defeated state if needed.
7. `SaveManager` persists the relevant entity/chunk state.

---

# Save Data Shape

Initial save data can be JSON.

Expected top-level sections:

```json
{
  "version": 1,
  "player": {},
  "world_state": {},
  "quests": {},
  "inventory": {},
  "equipment": {},
  "factions": {},
  "progression": {},
  "statuses": {},
  "time": {},
  "readables": {},
  "combat": {},
  "chunks": {}
}
```

Each system owns its own sub-object.

Avoid one massive save method that manually knows every field from every system.

## Player Save Data

Expected player data:

```json
{
  "global_tile": [0, 0],
  "world_position": [0.0, 0.0],
  "chunk_coord": [0, 0],
  "world_layer": "surface",
  "stats": {},
  "health": 100
}
```

`world_position` is the authoritative player movement position. `global_tile`
and `chunk_coord` are derived from it and stored for debugging, validation, and
safe loading.

## World State Save Data

Expected world state data:

```json
{
  "flags": {
    "flag_blacksmith_tools_returned": true
  },
  "discovered_locations": [
    "location_brindlemark"
  ]
}
```

## Quest Save Data

Expected quest data:

```json
{
  "quest_missing_tools": {
    "state": "active",
    "stage": "find_toolbox",
    "objectives": {
      "find_toolbox": "active"
    }
  }
}
```

## Inventory Save Data

Expected inventory data:

```json
{
  "items": [
    {
      "item_id": "item_gold_coin",
      "count": 25
    },
    {
      "item_id": "item_old_toolbox",
      "count": 1
    }
  ]
}
```

## Readables Save Data

Expected readable data:

```json
{
  "read": [
    "readable_miner_journal_01"
  ],
  "discovered": [
    "readable_miner_journal_01"
  ]
}
```

## Faction Save Data

Expected faction data:

```json
{
  "reputation": {
    "faction_marches_of_velcor": 5,
    "faction_road_bandits": -5
  }
}
```

## Status Effect Save Data

Expected status effect data:

```json
{
  "active": [
    {
      "status_id": "status_road_focus",
      "charges": 2
    }
  ]
}
```

Unknown statuses and non-positive charges are ignored on load.

## Time Save Data

Expected time data:

```json
{
  "day": 1,
  "minute_of_day": 480
}
```

`minute_of_day` is clamped to one 24-hour day. The default start is Day 1,
08:00.

## Chunk Save Data

Expected chunk data:

```json
{
  "surface:12:-4": {
    "removed_entities": [
      "entity_bandit_road_01"
    ],
    "modified_objects": {
      "object_old_chest_01": {
        "opened": true
      }
    },
    "dropped_items": []
  }
}
```

`modified_objects.*.opened` is currently used for persistent container state.

---

# Content Data Shapes

These shapes are early targets and may evolve.

## Item Definition

```json
{
  "id": "item_old_toolbox",
  "name": "Old Toolbox",
  "description": "A heavy wooden toolbox stamped with Harrow Venn's maker's mark.",
  "type": "quest_item",
  "stackable": false,
  "max_stack": 1,
  "value": 0,
  "tags": ["quest"]
}
```

## Readable Definition

```json
{
  "id": "readable_miner_journal_01",
  "title": "Last Entry of Dallan Reeve",
  "type": "journal",
  "author": "Dallan Reeve",
  "body": "The lamps will not hold...",
  "effects_on_read": [
    {
      "type": "set_flag",
      "flag_id": "flag_miner_journal_read",
      "value": true
    }
  ]
}
```

## Dialogue Definition

```json
{
  "id": "dialogue_harrow_venn",
  "start_node": "start",
  "nodes": {
    "start": {
      "speaker": "Harrow Venn",
      "text": "You looking for work, or just standing close to the forge for warmth?",
      "choices": [
        {
          "text": "I'm looking for work.",
          "next": "offer_work"
        }
      ]
    }
  }
}
```

## Quest Definition

```json
{
  "id": "quest_missing_tools",
  "title": "The Missing Tools",
  "description": "Harrow Venn's tools were stolen near the old road.",
  "initial_state": "inactive",
  "stages": {
    "started": {
      "objective": "Search the old road for Harrow's tools."
    },
    "found_toolbox": {
      "objective": "Return the toolbox to Harrow Venn."
    }
  },
  "rewards": [
    {
      "type": "add_item",
      "item_id": "item_gold_coin",
      "count": 25
    }
  ]
}
```

## Faction Definition

```json
{
  "id": "faction_marches_of_velcor",
  "name": "Marches of Velcor",
  "description": "The roadward towns, farmholds, and trade families of Velcor's human heartland.",
  "starting_reputation": 0
}
```

## Shop Definition

```json
{
  "id": "shop_crossroads_peddler",
  "name": "Crossroads Peddler",
  "open_hour": 8,
  "close_hour": 18,
  "stock": [
    {
      "item_id": "item_roadside_draught",
      "price": 8
    }
  ]
}
```

Shop stock item IDs must reference `data/items.json`. Prices must be positive
numbers. If a stock entry omits `price`, the engine can fall back to the item's
authored value. `open_hour` and `close_hour` are optional 24-hour clock values;
when present, buy and sell actions are hidden while the shop is closed.

## Container World Object

```json
{
  "id": "object_road_cache",
  "name": "Roadside Cache",
  "kind": "container",
  "global_tile": [3, -5],
  "effects_on_open": [
    {
      "type": "add_item",
      "item_id": "item_gold_coin",
      "count": 2
    }
  ]
}
```

## Chunk Definition

```json
{
  "id": "surface:0:0",
  "layer": "surface",
  "chunk_coord": [0, 0],
  "chunk_size": 32,
  "tiles": [],
  "objects": [],
  "entities": [],
  "triggers": []
}
```

---

# Conditions and Effects

Dialogue, quests, readables, objects, and triggers may use shared condition/effect formats.

## Conditions

Possible condition types:

- `has_flag`
- `not_flag`
- `has_item`
- `quest_state`
- `quest_stage`
- `read_readable`
- `faction_reputation_at_least`
- `location_discovered`
- `player_level_at_least`
- `stat_at_least`
- `time_phase`
- `time_hour_between`

Example:

```json
{
  "type": "has_item",
  "item_id": "item_old_toolbox",
  "count": 1
}
```

Faction reputation condition example:

```json
{
  "type": "faction_reputation_at_least",
  "faction_id": "faction_marches_of_velcor",
  "reputation": 5
}
```

Time condition examples:

```json
{
  "type": "time_phase",
  "phase": "Night"
}
```

```json
{
  "type": "time_hour_between",
  "start_hour": 18,
  "end_hour": 8
}
```

## Effects

Possible effect types:

- `set_flag`
- `start_quest`
- `set_quest_stage`
- `complete_quest`
- `fail_quest`
- `add_item`
- `remove_item`
- `change_reputation`
- `add_experience`
- `advance_time`
- `discover_location`
- `heal_player`
- `apply_status`

Example:

```json
{
  "type": "set_flag",
  "flag_id": "flag_miner_journal_read",
  "value": true
}
```

Reputation effect example:

```json
{
  "type": "change_reputation",
  "faction_id": "faction_marches_of_velcor",
  "amount": 5
}
```

Progression reward example:

```json
{
  "type": "add_experience",
  "amount": 20
}
```

Time effect example:

```json
{
  "type": "advance_time",
  "hours": 2
}
```

Centralize condition and effect evaluation where practical.

Avoid each system inventing incompatible condition/effect formats.

---

# Debugging and Validation

Systems should expose enough debug information to test quickly.

Useful debug features:

- current global tile position
- current chunk coordinate
- loaded chunk list
- current flags
- current quest states
- current inventory
- read readables
- faction reputation
- active interactable
- current target entity

Data-driven content should eventually have validation checks for:

- missing IDs
- duplicate IDs
- invalid references
- missing dialogue nodes
- invalid quest stages
- missing item definitions
- missing readable definitions
- invalid chunk references

---

# Architecture Decision Records

When a major architecture decision is made, add a short entry here.

Use this format:

```md
## ADR-0001: Decision Title

Date:

Decision:

Context:

Consequences:

Follow-up:
```

Keep ADRs short.

---

# ADR-0001: Seamless Global Tile World

Date: Initial architecture draft

Decision:

The game uses one global tile coordinate system and presents the world as one continuous tile-based space.

Context:

The project aims to capture open-world RPG exploration in a 2D tile-based format. A single global coordinate model makes exploration, object placement, quest references, chunk streaming, and save/load easier to reason about.

Consequences:

- World content must be authored with global coordinates or coordinates derived from chunk placement.
- Chunk streaming is required for performance.
- Systems should avoid assumptions that each area is a separate isolated map.
- Interiors/dungeons may require a layer model later.

Follow-up:

- Implement central grid/chunk coordinate utilities early.
- Decide initial chunk size during the chunk streaming prototype.

---

# ADR-0002: First Engine Spine

Date: Initial engine implementation

Decision:

The first playable engine spine is implemented as code-generated Godot 4
systems rather than editor-authored TileMap resources.

Context:

The project needs a reliable foundation before final art, tilesets, or content
tools exist. Code-generated chunks, simple drawn entities, JSON seed content,
and manager-owned state make the core loop testable immediately.

Consequences:

- The world can run and be tested without external art assets.
- Grid, chunk, interaction, quest, inventory, readable, world-state, and save
  systems now have concrete code paths.
- Visual presentation is placeholder-only and should later be replaced with
  authored TileMap/tile assets once the systems are stable.

Follow-up:

- Replace procedural placeholder terrain rendering with authored tile data.
- Add automated scene tests for player interaction and save/load flows.
- Add validation for content JSON references and duplicate IDs.

---

# ADR-0003: Continuous Character Movement In A Tile-Aware World

Date: Initial movement correction

Decision:

Characters are not bound to grid-step movement. The world remains tile-authored
and chunk-streamed, but the player moves continuously in world space.

Context:

The game should feel like an open-world RPG presented through a tile-aware
world, not like a tactics board or discrete roguelike. Tiles define terrain,
collision, placement, chunk lookup, triggers, and authored references; they do
not force the character to hop one tile at a time.

Consequences:

- Player save/load treats `world_position` as authoritative.
- `global_tile` is derived from world position and used for chunk streaming,
  terrain checks, interaction lookup, and debugging.
- Collision can still be tile-based initially by sampling the tile under the
  candidate world position.
- Future NPCs and enemies should follow the same principle: continuous motion
  over a grid-aware world model.

Follow-up:

- Add smoother collision sampling around character radius instead of checking
  only the center point.
- Move interaction checks toward world-distance plus optional tile filters.

---

# ADR-0004: Equipment Is A First-Class Persistent System

Date: Initial vertical-slice equipment pass

Decision:

Equipment is owned by `EquipmentManager` rather than being stored inside combat,
inventory, or UI state.

Context:

The first vertical slice needs equipment to affect combat while remaining
data-driven and saveable. Inventory owns item counts, combat owns damage
resolution, and equipment bridges those systems by exposing modifiers from
currently equipped items.

Consequences:

- Save data now includes an `equipment` section.
- Combat asks equipment for player damage and guard modifiers.
- Inventory UI can route `equip`, `unequip`, and `use` actions without becoming
  the source of truth.

Follow-up:

- Add armour, stat requirements, and equipment comparison UI when progression
  expands.

---

# ADR-0005: Faction Reputation Uses Shared Conditions And Effects

Date: Initial faction reputation pass

Decision:

Faction reputation is owned by `FactionManager`, saved in the `factions`
section, and modified/read through shared effect and condition definitions.

Context:

Reputation needs to influence dialogue, quests, faction hostility, rewards, and
future access rules. Keeping reputation in the shared condition/effect language
lets dialogue, quests, readables, and world objects use one implementation.

Consequences:

- Content can use `change_reputation` effects and
  `faction_reputation_at_least` conditions.
- NPC faction references are validated against `data/factions.json`.
- The HUD Journal tab can show current reputation while testing the spawn yard.

Follow-up:

- Add faction hostility, prices, access checks, and reputation thresholds once
  shops, doors, and settlements exist.

---

# ADR-0006: Time Is A First-Class Persistent System

Date: Initial time-system pass

Decision:

In-game time is owned by `TimeManager`, saved in the `time` section, exposed in
the HUD Journal tab, advanced by rest and wait actions, and available to authored
content through the shared `advance_time` effect.

Context:

Rest, schedules, shop hours, world reactions, and quest timing all need one
authoritative clock. Treating time as a manager-owned system keeps it out of UI,
dialogue, and save-file glue code.

Consequences:

- Save data now includes a `time` section.
- Campfire rest advances the clock by authored `rest_hours`.
- The HUD Journal tab exposes small wait actions so time behavior is testable near spawn.
- Content validation checks `advance_time` effects and `rest_hours`.
- The HUD shows day, clock time, and phase while testing the spawn yard.

Follow-up:

- Add time-based conditions, NPC schedules, and lighting once those systems need
  them.

---

# ADR-0007: Authored Terrain Regions For Spawn Town

Date: Early vertical-slice town pass

Decision:

The spawn-town terrain is described in `data/world_terrain.json` as ordered
authored regions. `ChunkManager` still generates chunk tile arrays at runtime,
but it now checks authored terrain before falling back to procedural wilderness
roads, water, forests, hills, and grass.

Context:

Briarwatch needs to become an authored RPG town rather than a hardcoded test
yard. Terrain should be adjustable as content data so roads, walls, rivers,
bridges, buildings, and later districts can be moved without rewriting chunk
logic.

Consequences:

- Town geometry can be iterated through content data.
- Tests can verify authored terrain, walkability, and reachability separately
  from procedural wilderness fallback.
- Future tooling can replace or generate the same data shape without changing
  runtime chunk APIs.

Follow-up:

- Expand terrain authoring when interiors, dungeons, or larger authored
  landmarks need more tile layers or object palettes.
