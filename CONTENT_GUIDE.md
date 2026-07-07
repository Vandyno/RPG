# CONTENT_GUIDE.md

# Content Guide for the Tile-Based 2D Open-World RPG

## Purpose

This file defines how authored content should be written and structured.

It covers:

- quests
- dialogue
- NPCs
- shops
- books
- notes
- signs
- inscriptions
- item descriptions
- environmental storytelling
- world-state consequences
- naming conventions
- factions
- locations

The goal is to make content easy to add, test, reference, and maintain.

---

# Content Principles

Good content should:

- support exploration
- make locations feel real
- give the player useful choices
- reveal worldbuilding naturally
- connect NPCs to places
- connect quests to world state
- reward curiosity
- avoid filler where possible
- be easy to implement through data

Content should usually be written with the assumption that the player may discover things out of order.

---

# IDs

Use stable string IDs for all important content.

IDs should be lowercase, descriptive, and safe for save files.

Use underscores.

Examples:

```text
npc_brindlemark_blacksmith
quest_missing_tools
item_old_toolbox
readable_miner_journal_01
shop_crossroads_peddler
faction_sainted_church
location_brindlemark
area_old_road_camp
flag_mine_door_unlocked
actor_forest_wolf
```

Do not use `kind: "enemy"` as a content type. Hostility is state, and combat is
behavior; a hostile bandit, guard, cultist, undead, animal, or monster is still
an actor. Humanoid people should be authored as NPC actors with inventory,
equipment, faction/state, and a character profile.

Avoid vague IDs like:

```text
npc_01
quest_test
note2
thing_old
```

Temporary prototype IDs are acceptable only when clearly temporary.

---

# Locations

Locations should have:

- unique ID
- display name
- region
- global coordinate or coordinate range
- short description
- purpose
- connected quests
- connected NPCs
- connected readables
- relevant factions
- relevant hostile actors or threats
- world-state flags where needed

Implemented location definitions live in `data/locations.json`.

Example:

```json
{
  "location_brindlemark": {
    "id": "location_brindlemark",
    "name": "Brindlemark",
    "type": "village",
    "region": "Western Road",
    "description": "An early settlement and first quest hub."
  }
}
```

A good location should answer:

- Why is this place here?
- Who uses it?
- What happened here?
- What can the player discover here?
- How does it connect to nearby places?
- What changes here after relevant quests?

Discovered locations are shown in the Journal tab with their authored region and
description, so keep descriptions concise and useful as player-facing journal
text rather than private author notes.

---

## Location Discovery Objects

Implemented locations can be discovered through world objects with
`kind: "location"`. These markers are not normal interact targets; they are
discovered automatically when the player comes within their discovery radius.
The `location_id` must reference an entry in `data/locations.json`.

Example:

```json
{
  "id": "location_briarwatch_crossroads_marker",
  "name": "Briarwatch Crossroads",
  "kind": "location",
  "global_tile": [1, 1],
  "location_id": "location_briarwatch_crossroads",
  "discovery_radius": 42
}
```

Use this when a place should become known through exploration without forcing
the player to click on a sign, NPC, or object.

---

# Authored Terrain

Implemented authored terrain lives in `data/world_terrain.json`.

Use it for town geometry, roads, rivers, bridges, walls, floors, and other
terrain that should be deliberately placed instead of procedurally generated.
`ChunkManager` applies the areas in this file before using procedural fallback
terrain outside authored spaces.

The current shape is intentionally small:

- `areas`: top-level array of authored regions.
- `bounds`: inclusive tile rectangle using `min` and `max`.
- `default_kind`: tile kind used inside the bounds before regions are applied.
- `regions`: ordered paint operations. Later regions override earlier ones.
- `rect`: rectangle paint with `position` and `size`.
- `border_only`: optional boolean for walls or building outlines.
- `tiles`: explicit tile list for gates, doors, small fixes, or landmarks.

Supported early tile kinds:

- `grass`
- `road`
- `water`
- `bridge`
- `stone_wall`
- `wood_wall`
- `wood_floor`
- `forest`
- `hill`

Example:

```json
{
  "id": "area_briarwatch_spawn_town",
  "bounds": {
    "min": [-12, -10],
    "max": [14, 10]
  },
  "default_kind": "grass",
  "regions": [
    {
      "id": "town_wall",
      "kind": "stone_wall",
      "rect": {
        "position": [-12, -10],
        "size": [27, 21]
      },
      "border_only": true
    },
    {
      "id": "west_gate",
      "kind": "road",
      "tiles": [[-12, 0], [-12, 1]]
    }
  ]
}
```

Terrain data is content, so it should stay stable, readable, and validated.
Prefer moving terrain in `world_terrain.json` over adding one-off tile checks in
code.

---

# NPCs

NPCs should have:

- unique ID
- display name
- role
- location
- faction
- dialogue ID
- optional shop ID
- quest connections
- basic personality
- what they want
- what they know
- what changes after relevant quests

Example:

```text
ID: npc_brindlemark_blacksmith
Name: Harrow Venn
Role: Village blacksmith
Location: location_brindlemark
Faction: faction_brindlemark
Dialogue: dialogue_harrow_venn
Shop: shop_harrow_forge optional
Connected quests:
- quest_missing_tools
Personality:
- tired
- practical
- suspicious of outsiders
Wants:
- his stolen tools returned
Knows:
- bandits have been seen near the old road
State changes:
- becomes friendlier after tools are returned
- offers better prices after quest completion
```

NPCs should feel like people with motives, not quest vending machines.

Hostile humanoids are still NPCs. Do not author a separate humanoid "enemy"
shape that cannot later talk, move, attack, be pickpocketed, carry equipment,
die into a lootable body, or change hostility through faction/story state.

---

# Shops

Implemented shop definitions live in `data/shops.json`. NPCs become traders by
referencing a shop ID with `shop_id` in `data/npcs.json`.

Shop definitions should have:

- unique ID
- display name
- stock entries with item IDs
- positive prices when overriding item value
- optional `open_hour` and `close_hour` values using 24-hour time

Example:

```json
{
  "shop_crossroads_peddler": {
    "id": "shop_crossroads_peddler",
    "name": "Crossroads Peddler",
    "open_hour": 8,
    "close_hour": 18,
    "stock": [
      {
        "item_id": "item_roadside_draught",
        "price": 8
      },
      {
        "item_id": "item_traveler_buckler",
        "price": 18
      }
    ]
  }
}
```

Trade interactions use `item_gold_coin` as currency. Quest-tagged or unsellable
items should not be sellable, and equipped items remain protected from selling.
If a shop has hours, the Trade tab should show the hours and hide buy/sell
actions while the shop is closed.

Good shop stock should support nearby gameplay tests: healing, equipment,
currency flow, and basic buy/sell behavior should all be reachable near the
current spawn while the systems are still being hardened. At least one early
shop should also be testable after resting into a closed time window.

---

# Dialogue

Dialogue should be clear, characterful, and functional.

Dialogue should support:

- greetings
- player choices
- branching responses
- quest starts
- quest progress checks
- quest resolution
- conditional options
- reputation changes
- item checks
- world-state checks
- readable/lore knowledge checks later
- skill or stat checks later

Dialogue should usually be concise.

Avoid writing giant monologues unless the moment deserves it.

## Dialogue Node Structure

A dialogue line should usually include:

- line ID
- speaker
- text
- conditions
- effects

Implemented dialogue definitions live in `data/dialogues.json`. The current
engine selects the first line whose conditions pass, applies that line's
effects, and displays its speaker/text. This supports quest starts, quest
progress, and quest resolution now; branching player choices can build on the
same condition/effect format later.

Example:

```json
{
  "dialogue_harrow_venn": {
    "id": "dialogue_harrow_venn",
    "lines": [
      {
        "id": "start_missing_tools",
        "speaker": "Harrow Venn",
        "text": "If you want work, find my old toolbox.",
        "conditions": [
          {
            "type": "quest_state",
            "quest_id": "quest_missing_tools",
            "state": "inactive"
          }
        ],
        "effects": [
          {
            "type": "start_quest",
            "quest_id": "quest_missing_tools"
          }
        ]
      }
    ]
  }
}
```

Future branching choices may use a shape like:

```json
{
  "choices": [
    {
      "text": "I'm looking for work.",
      "next": "offer_work"
    },
    {
      "text": "What happened here?",
      "next": "local_problem"
    },
    {
      "text": "Goodbye.",
      "next": "end"
    }
  ]
}
```

## Dialogue Conditions

Choices or lines may depend on conditions.

Examples:

```json
{
  "text": "I found your tools.",
  "condition": {
    "type": "has_item",
    "item_id": "item_old_toolbox",
    "count": 1
  },
  "next": "return_tools"
}
```

```json
{
  "text": "I read the miner's journal.",
  "condition": {
    "type": "read_readable",
    "readable_id": "readable_miner_journal_01"
  },
  "next": "journal_reaction"
}
```

Implemented condition types currently include `has_flag`, `not_flag`,
`has_item`, `quest_state`, `quest_stage`, `read_readable`,
`location_discovered`, `faction_reputation_at_least`,
`player_level_at_least`, `time_phase`, and `time_hour_between`.

Progression conditions can gate dialogue, quest choices, spawned objects, or
object access:

```json
{
  "type": "player_level_at_least",
  "level": 2
}
```

Time conditions can gate dialogue, quest choices, or object interactions:

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

Hour windows can cross midnight. The example above is true from 18:00 until
just before 08:00.

## Dialogue Effects

Dialogue choices may trigger effects.

Examples:

```json
{
  "text": "I'll find your tools.",
  "effects": [
    {
      "type": "start_quest",
      "quest_id": "quest_missing_tools"
    }
  ],
  "next": "accepted_quest"
}
```

```json
{
  "text": "Here are your tools.",
  "effects": [
    {
      "type": "remove_item",
      "item_id": "item_old_toolbox",
      "count": 1
    },
    {
      "type": "complete_quest",
      "quest_id": "quest_missing_tools"
    },
    {
      "type": "set_flag",
      "flag_id": "flag_blacksmith_tools_returned",
      "value": true
    }
  ],
  "next": "quest_complete"
}
```

Quest rewards should usually live in the quest's `rewards` array, not in the
dialogue line. `complete_quest` applies those rewards once when the quest first
transitions to completed.

Rewards can include items, reputation, XP, locations, flags, or other shared
effects. Use XP for character growth:

```json
{
  "type": "add_experience",
  "amount": 20
}
```

Level-ups grant skill points. Skill points are intentionally banked for now;
there are no implemented trainable stats until the stat model is designed.

Status effects are defined in `data/status_effects.json` and can be applied by
any authored effect list:

```json
{
  "type": "apply_status",
  "status_id": "status_road_focus",
  "charges": 2
}
```

If `charges` is omitted, the status uses its authored `attack_charges`.

Time can be advanced by authored effects:

```json
{
  "type": "advance_time",
  "hours": 2
}
```

Use this for rest, travel, rituals, waiting, crafting, or any interaction that
should visibly move the world clock. Prefer `hours` for broad actions and
`minutes` for short interactions.

The HUD Journal tab also provides simple wait actions for engine testing. Keep
early time-gated content close enough to spawn that waiting, resting, shop hours,
and dialogue conditions can be verified without a long walk.

## Rest Objects

Rest world objects use `kind: "rest"` in `data/world_objects.json`.

Example:

```json
{
  "id": "object_roadside_campfire",
  "name": "Roadside Campfire",
  "kind": "rest",
  "global_tile": [0, 5],
  "heal_amount": 100,
  "rest_hours": 8
}
```

The player-facing prompt shows both healing and time cost. Keep early rest
objects near spawn while core systems are being tested.

---

# Quest Design

A quest should have:

- unique ID
- title
- short summary
- starting condition
- stages
- objectives
- involved NPCs
- involved locations
- involved items
- relevant readables
- outcomes
- rewards
- world-state changes

## Quest Template

```text
ID:
Title:
Type:
Starting NPC or Trigger:
Starting Location:
Summary:

Stages:
1.
2.
3.

Objectives:
-

Important NPCs:
-

Important Locations:
-

Important Items:
-

Important Readables:
-

Possible Outcomes:
-

Rewards:
-

World-State Changes:
-
```

In JSON quest definitions, stage objectives can be plain strings or dictionaries
with `text` and `target_id`. Use `target_id` when the HUD should show a
direction to a live world object:

```json
{
  "objectives": {
    "clear_thug": {
      "text": "Defeat the road thug threatening Briarwatch's west road.",
      "target_id": "enemy_road_thug"
    }
  }
}
```

## Example Quest

```text
ID: quest_missing_tools
Title: The Missing Tools
Type: Local side quest
Starting NPC: npc_brindlemark_blacksmith
Starting Location: location_brindlemark
Summary:
The village blacksmith's tools were stolen from a cart outside the village. He suspects bandits on the old road.

Stages:
1. Speak with Harrow Venn.
2. Search the old road.
3. Find the stolen toolbox.
4. Return to Harrow.

Objectives:
- Talk to Harrow Venn.
- Find the old toolbox.
- Return the toolbox.

Important NPCs:
- npc_brindlemark_blacksmith

Important Locations:
- location_brindlemark
- location_old_road_camp

Important Items:
- item_old_toolbox

Important Readables:
- readable_old_road_warning_note

Possible Outcomes:
- Return the toolbox.
- Keep the toolbox.
- Lie about finding it later if dialogue supports that.

Rewards:
- gold
- local reputation
- possible discount at blacksmith

World-State Changes:
- flag_blacksmith_tools_returned
- quest_missing_tools completed
```

---

# Quest Stages

Quest stages should be clear and specific.

Good:

```text
Find the stolen toolbox near the old road camp.
```

Weak:

```text
Find the thing.
```

Good:

```text
Return to Harrow Venn in Brindlemark.
```

Weak:

```text
Go back.
```

The quest log should give enough information for the player to continue without needing exact GPS-style markers for every step.

---

# Books and Readables

Readables are a major content type.

They should make the world feel deeper and more explorable.

Readable types:

- books
- letters
- journals
- notes
- signs
- wanted posters
- shrine inscriptions
- wall carvings
- plaques
- sermons
- laws
- recipes
- maps
- research notes
- cult writings
- faction documents
- military orders
- personal diaries
- contracts
- tax ledgers
- warnings

## Readable Data

A readable should have:

- unique readable ID
- title
- author/source, when relevant
- readable type
- body text
- optional pages
- location or item association
- quest relevance
- effects when read
- discovered/read tracking

## Readable Template

```text
ID:
Title:
Type:
Author/Source:
Associated Location:
Associated Quest:
Associated Item/Object:
Summary:
Body:
Effects When Read:
```

## Example Readable

```text
ID: readable_miner_journal_01
Title: Last Entry of Dallan Reeve
Type: Journal
Author/Source: Dallan Reeve
Associated Location: location_old_mine
Associated Quest: quest_old_mine
Associated Item/Object: object_dead_miner_journal
Summary:
A dead miner's final journal entry hinting that something below the mine was intentionally sealed away.

Body:
The lamps will not hold. We hear it under the lower stones now, dragging itself through places no tunnel should reach.

Berric says the old door was built to keep us out.

I think it was built to keep something in.

If anyone finds this, do not open the red-marked gate.

Effects When Read:
- mark readable_miner_journal_01 as read
- set flag_miner_journal_read to true
- allow dialogue option with npc_brindlemark_elder
- update quest_old_mine if active
```

## Readable Writing Rules

Readables should usually be short enough to read comfortably.

Use longer books when the content genuinely matters.

A good readable should do at least one of:

- reveal lore
- provide a quest clue
- deepen a character
- explain a location
- foreshadow danger
- add flavour
- unlock a dialogue option
- mark a secret
- make the world feel lived-in

Avoid filling the world with long text that does not matter.

---

# Signs and Inscriptions

Signs should be short and useful.

Examples:

```text
BRINDLEMARK
Western road closed after sundown.
```

```text
OLD MINE
By order of the reeve, lower tunnels sealed.
```

```text
Pilgrims may leave offerings at the root.
Take nothing that has been given.
```

Inscriptions can be more poetic, religious, historical, or strange.

Example:

```text
Here Saint Oravan planted his staff and found no shadow beneath him.
```

---

# Item Descriptions

Items should have short, useful descriptions.

Item descriptions can communicate:

- practical use
- origin
- faction connection
- quest relevance
- lore
- mood

Example:

```text
Item: Old Toolbox
Description:
A heavy wooden toolbox stamped with Harrow Venn's maker's mark. The lock has been broken, but most of the tools are still inside.
```

Example:

```text
Item: Tarnished Saint Medallion
Description:
A copper medallion showing a faceless saint with raised hands. The back is scratched with the words: Mercy is obedience.
```

## Equipment Items

Equipment items use normal item definitions plus an `equipment_slot`.

Supported early slots:

- `weapon`
- `offhand`
- `body`

Early combat modifiers:

- `damage_bonus`: added to the player's hit damage
- `guard_counter_multiplier`: lowers counterattack damage while guarding; lower
  values are stronger

Example:

```json
{
  "id": "item_road_hatchet",
  "name": "Road Hatchet",
  "type": "weapon",
  "stackable": false,
  "max_stack": 1,
  "equipment_slot": "weapon",
  "damage_bonus": 4
}
```

## Status Effects

Status effects live in `data/status_effects.json`. Current status definitions
use attack charges, which are consumed when the player attacks.

```json
{
  "id": "status_road_focus",
  "name": "Road Focus",
  "description": "A steadying rush that makes the next few strikes hit harder.",
  "attack_charges": 2,
  "damage_bonus": 3
}
```

Consumables, readables, containers, doors, quest rewards, or dialogue choices can
apply statuses through `apply_status`. Active statuses are shown in the HUD and
Character tab, modify combat through `CombatManager`, and persist in saves.

## Town POIs

POIs are interactable places such as town squares, forges, stalls, shrines,
gatehouses, and job boards. Use `kind: "poi"` when the player should be able to
tap a place, read what it is, discover its location, and eventually route into a
specific town system.

```json
{
  "id": "poi_briarwatch_square",
  "name": "Briarwatch Square",
  "kind": "poi",
  "poi_type": "Town Center",
  "summary": "notice post and roads",
  "global_tile": [-6, 2],
  "interaction_radius": 128,
  "location_id": "location_briarwatch_square",
  "description": "The square gives Briarwatch a readable center."
}
```

Optional `effects_on_discover` run only when the linked location is first
discovered. Use those for one-time flags, tutorials, or introductory quest
hooks. Keep repeatable actions in NPC, shop, rest, container, or future crafting
systems instead.

POIs can also offer action choices. Actions use the same condition/effect shape
as dialogue choices, so job boards can start or complete quests without custom
code. Service actions can use `has_item` conditions and `remove_item` effects
for simple costs:

```json
{
  "id": "poi_briarwatch_square",
  "kind": "poi",
  "actions": [
    {
      "id": "take_road_patrol",
      "text": "Take Road Patrol Job",
      "conditions": [
        {
          "type": "quest_state",
          "quest_id": "quest_briarwatch_road_patrol",
          "state": "inactive"
        }
      ],
      "effects": [
        {
          "type": "start_quest",
          "quest_id": "quest_briarwatch_road_patrol"
        }
      ],
      "response": "Clear the road, then report back here."
    }
  ]
}
```

For example, Harrow's Forge uses an action that requires `item_road_hatchet` and
2 gold, removes the gold, and applies a short sharpening status.

Service POIs can open a supported Systems tab directly. A market stall can link
to a shop:

```json
{
  "id": "poi_maera_stall",
  "name": "Maera's Stall",
  "kind": "poi",
  "poi_type": "Market Stall",
  "summary": "trade and rumor hook",
  "global_tile": [6, -2],
  "interaction_radius": 128,
  "location_id": "location_maera_stall",
  "shop_id": "shop_crossroads_peddler",
  "system_tab": "trade",
  "description": "Maera's awning marks the trading side of town."
}
```

Supported POI `system_tab` values are `inventory`, `character`, `trade`,
`quests`, `journal`, and `log`. The player-facing Systems HUD also has a
top-level `spells` tab for assigning ability slots, but POIs do not currently
open directly to that tab.

## Containers

Containers are world objects that can grant authored effects once and then stay
open through chunk persistence.

Use `kind: "container"` with `effects_on_open`.

Example:

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

Containers should be used for chests, caches, packs, desks, shelves, corpses,
and similar authored loot sources. They should have stable IDs because opened
state is saved per object.

Interactable world objects can include `interaction_radius` in pixels when they
need a larger touch/targeting range than the default spawn-yard radius. Use this
sparingly for important objects that should be testable from nearby but not
visually crowded around the player.

Use `open_conditions` when a container should be visible but locked until the
player satisfies authored state. Add `locked_text` for the message shown while
the conditions are not met:

```json
{
  "id": "object_sealed_strongbox",
  "name": "Sealed Strongbox",
  "kind": "container",
  "global_tile": [7, 0],
  "interaction_radius": 128,
  "open_conditions": [
    {
      "type": "read_readable",
      "readable_id": "readable_briarwatch_notice"
    }
  ],
  "locked_text": "The strongbox seal matches the warden's notice.",
  "effects_on_open": [
    {
      "type": "add_item",
      "item_id": "item_gold_coin",
      "count": 4
    }
  ]
}
```

World objects may include `conditions` to appear only after authored state is
true. This uses the same condition format as dialogue. Use it for hidden caches,
quest-state NPCs, time-gated objects, aftermath props, and other world changes
that should be data-driven:

```json
{
  "id": "object_warden_cache",
  "name": "Warden's Cache",
  "kind": "container",
  "global_tile": [5, 3],
  "conditions": [
    {
      "type": "read_readable",
      "readable_id": "readable_briarwatch_notice"
    }
  ],
  "effects_on_open": [
    {
      "type": "add_item",
      "item_id": "item_gold_coin",
      "count": 1
    }
  ]
}
```

Use `kind: "door"` for route gates, locked doors, hatches, barricades, or other
access objects that should persist as opened once used. Doors share
`open_conditions`, `locked_text`, `interaction_radius`, and `effects_on_open`
with containers:

```json
{
  "id": "object_north_gate",
  "name": "North Gate",
  "kind": "door",
  "global_tile": [0, -7],
  "interaction_radius": 128,
  "open_conditions": [
    {
      "type": "read_readable",
      "readable_id": "readable_briarwatch_notice"
    }
  ],
  "locked_text": "The north gate chain is marked with the warden's notice seal.",
  "effects_on_open": [
    {
      "type": "set_flag",
      "flag_id": "flag_north_gate_opened",
      "value": true
    },
    {
      "type": "advance_time",
      "minutes": 15
    }
  ]
}
```

`open_conditions` can use progression checks, which makes training unlock
authored access without custom code:

```json
{
  "id": "object_training_gate",
  "name": "Training Gate",
  "kind": "door",
  "global_tile": [-7, 1],
  "interaction_radius": 128,
  "open_conditions": [
    {
      "type": "has_item",
      "item_id": "item_training_sword",
      "count": 1
    }
  ],
  "locked_text": "The training gate's lever is notched for a training sword.",
  "effects_on_open": [
    {
      "type": "set_flag",
      "flag_id": "flag_training_gate_opened",
      "value": true
    }
  ]
}
```

---

# Environmental Storytelling

Environmental storytelling should support the world without requiring exposition.

Use:

- object placement
- corpses
- damaged buildings
- abandoned camps
- notes
- loot
- enemy placement
- locked doors
- shrines
- signs
- strange terrain
- repeated symbols

Examples:

- A dead courier carries a sealed letter near a broken bridge.
- A shrine has fresh candles despite being deep in abandoned woods.
- A bandit camp contains stolen tools, children's toys, and tax ledgers.
- A cave has claw marks outside but human footprints within.
- A noble house has saintly icons upstairs and cult documents below.

Environmental storytelling should often raise questions before answering them.

---

# World-State Flags

Use flags for persistent story and world changes.

Flag names should be stable and descriptive.

Examples:

```text
flag_blacksmith_tools_returned
flag_miner_journal_read
flag_old_mine_gate_opened
flag_bandit_leader_dead
flag_bandit_leader_spared
flag_shrine_root_offering_given
flag_brindlemark_elder_exposed
```

Flags can affect:

- dialogue
- quest stages
- object availability
- enemy presence
- locked doors
- readables
- reputation
- location state
- endings

---

# Faction Content

Faction content should define:

- beliefs
- territory
- enemies
- allies
- leadership
- local representatives
- quests
- readable documents
- laws/rules
- symbols
- reputation effects

Faction writing should make each faction feel like it has reasons for existing.

A faction should have:

- what it wants
- what it fears
- what it offers
- what it hides
- what ordinary people think of it

Implemented faction definitions live in `data/factions.json`.

Example:

```json
{
  "faction_marches_of_velcor": {
    "id": "faction_marches_of_velcor",
    "name": "Marches of Velcor",
    "description": "The roadward towns, farmholds, and trade families of Velcor's human heartland.",
    "starting_reputation": 0
  }
}
```

Reputation can change through shared effects:

```json
{
  "type": "change_reputation",
  "faction_id": "faction_marches_of_velcor",
  "amount": 5
}
```

Dialogue or other authored content can check reputation:

```json
{
  "type": "faction_reputation_at_least",
  "faction_id": "faction_marches_of_velcor",
  "reputation": 5
}
```

Progression can also be checked by authored content:

```json
{
  "type": "player_level_at_least",
  "level": 2
}
```

---

# NPC Voice

NPC voice should vary by:

- region
- class
- occupation
- faction
- education
- religion
- personality
- fear
- loyalty
- relationship to player

Examples:

A blacksmith may be blunt and practical.

A priest may be formal, gentle, threatening, or fanatical depending on faction and personality.

A bandit may be desperate, cruel, funny, cowardly, or ideological.

A scholar may speak precisely and refer to books, old laws, or ruins.

Avoid giving every NPC the same generic fantasy voice.

---

# Choice and Consequence

Choices should be understandable.

The player does not need to know every long-term effect, but they should usually understand the immediate meaning of what they are choosing.

Choice types:

- help/refuse
- lie/tell truth
- spare/kill
- expose/hide
- steal/return
- side with faction A/faction B
- use force/use speech/use stealth/use magic
- read/investigate/ignore
- open/seal/destroy

Consequences may be small, medium, or large.

Small:

- different dialogue
- small reward change

Medium:

- different NPC state
- faction reputation change
- shop access change

Large:

- location state change
- character death
- faction hostility
- ending branch

---

# Rewards

Rewards can include:

- gold
- items
- weapons
- armour
- books
- spells
- perks
- reputation
- access
- information
- allies
- discounts
- safe passage
- location discovery
- world-state change

Not every reward needs to be loot.

Information is a valid reward in a story-driven RPG.

---

# Content Testing Checklist

When adding content, check:

- Does it have a stable ID?
- Is it connected to a location?
- Is it connected to the right NPCs/items/quests/readables?
- If it is a shop, can its stock be bought, sold against, and validated?
- Does it require world-state flags?
- Does it advance time, and is that time cost visible to the player?
- Does it need save/load support?
- Does it trigger events?
- Can the player discover it out of order?
- Does dialogue account for likely quest states?
- Does the quest log give enough direction?
- Does nearby test content appear clearly in the World/Quest direction summary?
- Does completing it change anything?
- Is the content reusable or hardcoded?
- Can it be tested quickly?

---

# First Content Pack Target

The first content pack should support the vertical slice.

It should include:

## Location

- one road
- one village or camp
- one cave, ruin, or interior
- one small hostile area

## NPCs

- one quest-giver
- one optional flavour NPC if time allows

## Quest

- one quest with clear start, middle, and resolution

## Readables

- one sign
- one note or journal
- one optional lore book

## Items

- one quest item
- one consumable
- one reward item
- gold

## Hostile Actor

- one simple hostile actor or threat

## World State

- one flag set by reading
- one flag set by quest completion
- one location or NPC response changed by quest completion

The first content pack should prove that authored RPG content can be created without custom code for every object.
