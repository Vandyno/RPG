# Sprite Replacement Contracts

Status: audit of current Godot project visuals. No gameplay code assumptions changed.

## Global Findings

- There are no gameplay sprite sheets in `assets/` or `scenes/`.
- Current world visuals are procedural `CanvasItem` drawing, mostly from `Node2D._draw()`.
- Current texture path is therefore `none` for all gameplay actors, world objects, terrain, item visuals, and UI placeholder icons.
- `icon.svg`, `scorecard.png`, docs reference images, and addon images are not gameplay sprite contracts.
- World tile size is `16x16 px` from `scripts/core/grid_math.gd`.
- Entity world position is centered on a tile: `tile_to_world(tile) + Vector2(8, 8)`.
- Moving actor collision samples use a radius of `10 px` from `scripts/world/world_entity_movement.gd`.
- Blocked terrain kinds are `water`, `stone_wall`, and `wood_wall`.

## Shared Direction Contract

Current directional actor logic uses 16 snapped facing buckets:

`east`, `east_southeast`, `southeast`, `south_southeast`, `south`, `south_southwest`, `southwest`, `west_southwest`, `west`, `west_northwest`, `northwest`, `north_northwest`, `north`, `north_northeast`, `northeast`, `east_northeast`

Recommended final order for directional sprite sheets: same order, left to right.

If an 8-direction interim sheet is needed, use:

`east`, `southeast`, `south`, `southwest`, `west`, `northwest`, `north`, `northeast`

## Shared Frame Defaults

| Asset class | Current frame size | Current full image size | Recommended final frame |
|---|---:|---:|---:|
| Terrain tile | `16x16`, procedural | N/A | `16x16`, atlas-safe, no padding unless atlas importer needs it |
| Small pickup/icon-in-world | procedural bounds vary | N/A | `32x32`, origin at ground/contact center |
| Static interactable marker/object | about `24x24` to `32x32`, procedural | N/A | `32x32` or `48x48`, origin at footprint center |
| Door/gate/object with larger touch target | visual about `16x24`, pick radius may be larger | N/A | `32x48`, origin at threshold/footprint center |
| Humanoid avatar | procedural body-part stack approx `40x48`, gear can extend wider | N/A | layered body parts in shared `64x64` actor frame space |
| Large structure facade | procedural rect from tile footprint | N/A | multi-tile prop or tilemap composition, aligned to `16x16` grid |
| UI item icon | text/procedural placeholder | N/A | `32x32` inventory icon, optional `64x64` source |

## Actor Contract

Scene/resource path:

- Player node: `scripts/player/player_controller.gd`
- World NPC node: `scripts/world/world_entity.gd`
- Avatar renderer: `scripts/characters/humanoid_avatar_2d.gd`
- Equipment renderers: `scripts/characters/humanoid_equipment_drawer.gd`, `scripts/characters/humanoid_held_item_drawer.gd`, `scripts/items/item_visual_2d.gd`
- Data paths: `data/character_profiles.json`, `data/world_objects.json`, `data/npcs.json`, `data/people_visual_models.json`

Current texture path: `none`.

Node type using the texture: no texture node; `PlayerController`, `WorldEntity`, and child `HumanoidAvatar2D` are `Node2D` drawing with CanvasItem primitives.

hframes/vframes or SpriteFrames names: N/A.

Current animation names:

- `idle`
- `walk`
- `sneak`
- attack pose data from weapon/spell actions, not SpriteFrames

Expected final animation names:

- `idle`
- `walk`
- `sneak`
- `attack_swing`
- `attack_thrust`
- `attack_projectile`
- `cast`
- `hurt`
- `dead` or `body`

Pivot/origin assumptions:

- Origin is actor feet/body center at world position.
- Actor is centered on a tile by default.
- Current body draws mostly above origin, with feet near positive Y and head at negative Y.
- Runtime body/corpse rotates avatar `90 deg`, moves it by `(2, 4)`, and scales to `0.88`.

Y-sort origin assumptions:

- No explicit y-sort origin is authored.
- Treat world position/origin as the y-sort point.
- Final sprite feet/contact point should sit on origin.

Collision footprint:

- Moving actor collision radius: `10 px`.
- Offset: centered on actor origin.
- Entity body picker uses visible radius/default pick radius, not physics bodies.

Drop-in replacement:

- Not drop-in as a single full sprite without renderer work.
- Paper-doll layers can be drop-in only after a layer naming/template contract exists.

Should migrate:

- Yes. Keep the shared humanoid/profile system. Migrate final art to paper-doll layers, not baked full-body sprites.

Recommended final sprite contract:

- Use `64x64` actor frame space.
- Runtime PNG inputs are horizontal `1024x64` strips: one logical piece across
  all 16 directions. Use separate left/right hand and foot strips; the combined
  rows in the large body template are composition guides only.
- Origin/feet at `(32, 40)` or equivalent imported offset so world origin remains feet center.
- Direction rows or columns must use the 16-bucket order above.
- Primary art should be body-part layers, not baked full-character sprites.
- Required body-part/layer rows: shadow, feet, waist/hips, hands_back, torso, chest_equipment, species_body, hands_front, head, hair_face_feature.
- Required equipment slots: head, chest, legs, boots, gloves, back, right_hand, left_hand.
- Equipment art must align to `get_body_part_anchors()` semantics: head, chest, waist, hands, feet.
- Keep profile-driven proportions as data, but generate/render against one stable frame box.
- Full actor sheets are useful for composite previews/readability checks, not as the source format for current NPC rendering.

### Current Actors

| Actor | Scene/resource path | Current visual path | Current texture | Drop-in? | Final contract |
|---|---|---|---|---|---|
| `char_player` / player | `scripts/player/player_controller.gd` | `HumanoidAvatar2D` | none | No | Body-part layers in `64x64`, 16 directions, composited for idle/walk/sneak/attack/cast/hurt/body |
| `npc_harrow_venn_world` | `data/world_objects.json`, `scripts/world/world_entity.gd` | `HumanoidAvatar2D`; chest `placeholder_smith_apron` | none | No | Same body-part stack; smith apron as chest layer |
| `npc_maera_pike_world` | same | `HumanoidAvatar2D` | none | No | Same body-part stack |
| `npc_road_thug` | same | `HumanoidAvatar2D`; sword equipped | none | No | Same body-part stack; right-hand weapon layer |
| `npc_test_raider` | same | `HumanoidAvatar2D`; sword/spell loadout | none | No | Same body-part stack; add cast/attack pose compatibility |
| `npc_people_test_human` | same | generated humanoid profile | none | No | Same body-part stack |
| `npc_people_test_tanglekin` | same | generated humanoid profile with species features | none | No | Body-part stack plus species feature layers |
| `npc_people_test_tuskfolk` | same | generated humanoid profile with species features | none | No | Body-part stack plus species feature layers |
| `npc_people_test_mirefolk` | same | generated humanoid profile with species features | none | No | Body-part stack plus species feature layers |
| `npc_people_test_ravenfolk` | same | generated humanoid profile with species features | none | No | Body-part stack plus species feature layers |
| `npc_people_test_rootborn` | same | generated humanoid profile with species features | none | No | Body-part stack plus species feature layers |
| Runtime `body` entity | created by defeat flow in `scripts/main/actions/main_systems_actions.gd` | rotated/scaled `HumanoidAvatar2D` or fallback body ellipse | none | No | `body` pose/layer from same humanoid avatar; no separate baked corpse unless needed |

## World Entity Placeholder Contract

Scene/resource path:

- `scripts/world/world_entity.gd`
- `scripts/world/world_entity_fallback_renderer.gd`
- `scripts/world/world_entity_marker_renderer.gd`
- Data: `data/world_objects.json`

Current texture path: `none`.

Node type using the texture: `WorldEntity` is `Node2D`; fallback renderer draws primitives.

Frame size/full image size: N/A now. Recommended final frame depends on kind, below.

hframes/vframes or SpriteFrames: N/A.

Expected animation names:

- Static objects: `default`
- Doors/gates: `closed`, `open`, optional `locked`
- Containers: `closed`, `open`, optional `locked`
- Rest/campfire: `idle`, optional `lit`
- Pickup: `ground`
- POI/location marker: `default`, optional `active`

Direction order: generally N/A, except doors/gates may need `north`, `east`, `south`, `west` facings later.

Pivot/origin:

- Origin is tile center.
- Static sprite should place its footprint center at origin.
- Tall props may extend above origin.

Y-sort:

- Sort at origin/footprint center.
- Tall props should keep bottom/contact point near origin.

Collision/pick footprint:

- Default marker pick radius: at least `40 px`.
- Large marker kinds `container`, `door`, `poi`, `rest`: at least `46 px`.
- Door interaction radius is at least `48 px`.
- Authored `pick_radius` can cap body pick radius; forge doors use `12 px`.

### Current Interactables and Objects

| ID | Kind | Current visual | Collision/pick footprint | Drop-in? | Migrate? | Recommended final contract |
|---|---|---|---|---|---|---|
| `object_road_notice` | readable | beige `12x16` rect | default pick `40 px`; interaction from data `128` capped by caller | Yes after sprite node exists | Yes | `32x32` notice/sign icon, `default` |
| `poi_briarwatch_square` | poi | freestanding job-board sign | large pick `46 px` | Yes | Yes | Dedicated sign-only job board prop, `32x48`, `default/active`; stands beside the town-hall door |
| `object_harrow_forge_door` | door | brown `8x18` rect | authored pick `12 px`; door interaction min `48 px` | Yes after sprite node exists | Yes | `32x48`, origin at threshold, `closed/open/locked` |
| `object_harrow_forge_exit` | door | brown `8x18` rect | authored pick `12 px`; door interaction min `48 px` | Yes after sprite node exists | Yes | `32x48`, origin at threshold, `closed/open/locked` |
| `object_road_cache` | container | chest rect `14x10` plus band | large pick `46 px` | Yes after sprite node exists | Yes | `32x32`, `closed/open` |
| `object_sealed_strongbox` | container | chest rect `14x10` plus band | large pick `46 px` | Yes after sprite node exists | Yes | Warden's Strongbox, `32x32`, `closed/open/locked` |
| `object_roadside_campfire` | rest | circle ember plus ground line approx `12x13` | large pick `46 px` | Yes after sprite node exists | Yes | `32x32`, `idle/lit`, origin at fire base |
| `location_briarwatch_crossroads_marker` | location | blue diamond `16x16` | non-interactive by manager; discovery radius `96` | Yes after sprite node exists | Maybe | Map/debug marker or invisible trigger; avoid final visible marker unless design wants it |

### Current Pickups

| ID | Item | Current visual | Frame/bounds | Collision/pick footprint | Drop-in? | Recommended final contract |
|---|---|---|---|---|---|---|
| `pickup_old_toolbox` | `item_old_toolbox` | generic gold `10x10` rect | procedural | default pick `40 px` | Yes after sprite node exists | `32x32` ground item or toolbox prop |
| `pickup_road_hatchet` | `item_road_hatchet` | procedural `placeholder_hatchet` | about `22x13`, rotated by seeded direction | default pick `40 px` | No | Use weapon ground sprite in `32x32`; same item also needs hand layer |
| `pickup_training_sword` | `item_training_sword` | procedural `placeholder_sword` | about `30x12`, rotated by seeded direction | default pick `40 px` | No | Use weapon ground sprite in `32x32`; same item also needs hand layer |
| `pickup_test_polearm` | `item_test_polearm` | procedural `placeholder_polearm` | about `66x8`, rotated by seeded direction | default pick `40 px`; visual can exceed pick | No | Use larger `64x32` or `64x64` ground sprite, origin at grip/center |
| `pickup_hunting_bow` | `item_hunting_bow` | procedural `placeholder_bow` | about `26x14`, rotated by seeded direction | default pick `40 px` | No | `32x32` ground sprite plus hand layer |
| `pickup_traveler_buckler` | `item_traveler_buckler` | procedural `placeholder_buckler` | `10x10` circle | default pick `40 px` | No | `32x32` ground sprite plus offhand layer |

## Terrain Tile Contract

Scene/resource path:

- `scripts/world/chunk_renderer.gd`
- `scripts/managers/world/chunk_manager.gd`
- `scripts/managers/world/structure_manager.gd`
- Data: `data/world_terrain.json`, `data/world_structures.json`, `data/structure_archetypes.json`

Current texture path: `none`.

Node type using the texture: `ChunkRenderer` is `Node2D`; tiles are drawn with `draw_rect`, `draw_line`, `draw_circle`.

Current frame size: `16x16`.

Current full image size: N/A.

hframes/vframes or SpriteFrames: N/A.

Expected animation names: `default`; optional `variant_0..variant_n`; optional `animated` for water later.

Direction order: N/A for square tiles.

Pivot/origin:

- Tile rect position is chunk-local top-left.
- Tile image origin should be top-left when used in a tilemap.

Y-sort:

- Terrain itself does not y-sort.
- Tall overlays/props should be separate y-sorted objects.

Collision footprint:

- Tile-sized `16x16`.
- Blocked: `water`, `stone_wall`, `wood_wall`.
- Walkable: `grass`, `bridge`, `wood_floor`, `forest`, `hill`, `road`.

| Tile kind | Current visual | Drop-in? | Migrate? | Recommended final contract |
|---|---|---|---|---|
| `grass` | green rect, occasional blade line | Yes after tileset exists | Yes | `16x16`, 3-6 variants |
| `water` | blue rect with wave lines | Yes after tileset exists | Yes | `16x16`, animated or 4 variants, blocked unless bridge |
| `bridge` | brown rect with planks | Yes after tileset exists | Yes | `16x16`, bridge deck variants |
| `stone_wall` | grey rect with block lines | Yes after tileset exists | Yes | `16x16`, blocked wall tile, may need edge/corner variants |
| `wood_wall` | dark wood rect with vertical planks | Yes after tileset exists | Yes | `16x16`, blocked wall tile, edge/corner variants |
| `wood_floor` | wood rect/plank lines | Yes after tileset exists | Yes | `16x16`, 3-6 variants |
| `forest` | dark green rect plus canopy circle | No | Yes | Split ground tile from tree/brush prop; do not make blocked unless design changes |
| `hill` | brown-green rect with ridge lines | Yes after tileset exists | Yes | `16x16`, slope/ridge variants |
| `road` | tan rect with occasional scuff | Yes after tileset exists | Yes | `16x16`, path edge/crossing variants |
| interior void | dark rect | Yes after tileset exists | Maybe | Keep as debug/background fill or replace with black transparent void |

## Structure Visual Contract

Scene/resource path:

- `scripts/world/chunk_renderer.gd`
- `data/world_structures.json`
- `data/structure_archetypes.json`

Current texture path: `none`.

Node type using texture: `ChunkRenderer` `Node2D`, procedural.

Current frame size/full image size:

- Forge exterior: `6x3` tiles = `96x48`, but drawing extends upward/outside rect with roof/chimney.
- Forge interior: `12x9` tiles = `192x144`.
- Shop front: `5x5` tiles = `80x80`.
- Town hall exterior: `6x4` tiles = `96x64`; its usable interior is a separate `12x9` tile room.

hframes/vframes or SpriteFrames: N/A.

Expected animation names: `default`; optional `lit`, `open`, `active`.

Direction order: N/A for current facades.

Pivot/origin:

- Current rect origin is structure top-left tile.
- Final multi-tile prop should align top-left to `origin_tile`.

Y-sort:

- Current structures are chunk-drawn terrain overlays, not entity y-sorted.
- Final tall facades may need split: ground/floor in tile layer, tall wall/roof as y-sorted overlay.

Collision footprint:

- From archetype terrain rows. `wood_wall` tiles block; `wood_floor`/doors walkable.

| Structure | Current visual style | Drop-in? | Migrate? | Recommended final contract |
|---|---|---|---|---|
| `structure_briarwatch_harrow_forge` | `forge_exterior` | No | Yes | Redesign as tile composition plus facade overlay; keep `6x3` footprint |
| `structure_briarwatch_harrow_forge_interior` | `forge_interior` | No | Yes | Use floor/wall tiles plus props: hearth, anvil, bench, rack, storage |
| `structure_briarwatch_maera_shop` | `shop_front` | No | Yes | Maera's working exterior trade stall |
| `structure_briarwatch_town_hall` | `town_hall_exterior` | No | Yes | Surface facade only; door and sign are separate props, with notices and strongbox inside `structure_briarwatch_town_hall_interior` |
| `structure_briarwatch_town_hall_interior` | `town_hall_interior` | No | Yes | Use floor/wall tiles plus desk, record shelf, notice board, rug, and cabinet |

## Item Icon and Equipment Visual Contract

Scene/resource path:

- Item data: `data/items.json`
- World ground/held renderer: `scripts/items/item_visual_2d.gd`
- Equipment renderer: `scripts/characters/humanoid_equipment_drawer.gd`
- Held item renderer: `scripts/characters/humanoid_held_item_drawer.gd`
- UI icon drawers: `scripts/ui/controls/display/rpg_icon_drawer.gd`, `scripts/ui/controls/buttons/rpg_icon_button.gd`

Current texture path: `none`.

Node type using texture: none. Procedural CanvasItem drawing or text.

Current frame size/full image size: N/A.

hframes/vframes or SpriteFrames: N/A.

Expected animation names:

- Inventory icons: `default`.
- Held weapons: use actor animation and pose; no independent animation required now.
- Bow may need `draw_0`, `draw_1`, `draw_2` or parameterized draw state later.

Direction order:

- Held item art must follow actor direction/hand anchor.
- Ground item direction is currently arbitrary seeded rotation.

Pivot/origin:

- Inventory icon: centered.
- Ground sprite: origin at visual center or contact center.
- Held layer: origin at grip point, not sprite center.

Y-sort:

- Inventory icons: N/A.
- Ground pickups: y-sort at entity origin/tile center.
- Held items: drawn inside actor y-sort.

Collision footprint:

- UI icon: control rect.
- Ground pickup pick: default `40 px`.
- Held item: actor collision only.

| Item/visual | Current visual | Drop-in? | Migrate? | Recommended final contract |
|---|---|---|---|---|
| `item_gold_coin` | no world/icon art, text only | Yes after icon map exists | Yes | `32x32` icon, optional small ground sparkle/coin stack |
| `item_old_toolbox` | generic pickup rect | Yes after icon map exists | Yes | `32x32` icon and `32x32` ground sprite |
| `placeholder_hatchet` / `item_road_hatchet` | procedural hand/ground hatchet | No | Yes | hand layer with grip pivot; `32x32` icon; `32x32` ground sprite |
| `placeholder_sword` / `item_training_sword` | procedural hand/ground sword | No | Yes | hand layer with grip pivot; `32x32` icon; `32x32` ground sprite |
| `placeholder_polearm` / `item_test_polearm` | procedural long weapon | No | Yes | hand layer with front/rear grip pivots; `64x64` held frame; `64x32` ground |
| `placeholder_bow` / `item_hunting_bow` | procedural bow/string | No | Yes | hand layer with bow/draw grip pivots; draw-state variants |
| `placeholder_buckler` / `item_traveler_buckler` | procedural circle shield | No | Yes | offhand layer pivot at center; `32x32` icon |
| `placeholder_smith_apron` / `item_smith_apron` | procedural chest equipment | No | Yes | chest paper-doll layer for all 16 directions |

## Other Visual Placeholders

| Placeholder | Scene/resource path | Current texture | Node type | Current size | Drop-in? | Recommended contract |
|---|---|---|---|---|---|---|
| Highlight ring | `scripts/world/world_entity.gd` | none | `WorldEntity` `Node2D` draw | radius `15 px` | Keep procedural | Keep procedural unless VFX atlas is added |
| Quest marker | `scripts/world/world_entity_marker_renderer.gd` | none | drawn on `WorldEntity` | rect `52x20`, center above entity | Keep procedural | Keep as UI/world marker, not sprite replacement priority |
| Action hint | same | none | drawn on `WorldEntity` | height `22`, width `48..148` | Keep procedural | UI skin later, no art generation needed now |
| Combat effects | `scripts/world/combat_action_effect.gd`, `scripts/world/actor_weapon_attack_action.gd` | none | `Node2D` draw | varies by attack range | No | Later VFX atlas: `swing`, `thrust`, `projectile`, `fire_stream` |
| `spell_fire_blast` quick-slot icon | `data/spells.json`, `scripts/ui/controls/buttons/rpg_action_cluster_builder.gd` | none; text icon `F` | UI label/control text | control-dependent | Yes after icon map exists | `32x32` spell icon plus optional VFX atlas entry |
| RPG UI icons | `scripts/ui/controls/display/rpg_icon_drawer.gd`, `scripts/ui/controls/buttons/rpg_icon_button.gd` | none | Control draw | control-dependent | Keep procedural now | Replace only after UI visual direction locks |
| Portrait silhouette | `scripts/ui/controls/display/rpg_portrait_silhouette.gd` | none | Control draw | control-dependent | No | Should use humanoid portrait render, not static icon |

## Prioritized Migration Plan

### 1. Assets safe to replace directly

- Terrain tiles: `grass`, `water`, `bridge`, `stone_wall`, `wood_wall`, `wood_floor`, `hill`, `road`, interior void.
- Simple static pickups with no held/avatar layer yet: `item_gold_coin`, `item_old_toolbox`.
- Small static object visuals once a sprite node/path exists: `object_road_notice`, caches/strongboxes, campfire.
- UI/system icons can stay procedural; replace only if a UI skin pass needs them.

### 2. Assets needing template generation first

- Humanoid body-part frame template: `64x64`, 16 directions, stable feet origin.
- Equipment layer templates for chest, head, legs, gloves, boots, back.
- Held item grip templates for right hand, left hand, bow hand, draw hand, front/rear polearm grips.
- Weapon ground sprite templates for sword, hatchet, bow, buckler, polearm.
- Door/gate templates with threshold origin and `closed/open/locked` states.

### 3. Assets that should be redesigned before generating art

- `forest` terrain: decide if this is ground, tree prop, blocker, or cover.
- Large structures: forge exterior/interior, Maera shop front, town hall front.
- POI visuals: job board, forge service marker, forge hearth.
- Gates: north gate and training gate need world scale/shape before final art.
- Location marker: decide whether final game should show it or make it invisible/discovery-only.
- Combat VFX: decide target readability before sprite effects.

### 4. Assets that should become paper-doll layers instead of full sprites

- Player.
- All humanoid NPCs.
- Runtime bodies/corpses.
- Species features for Human, Tanglekin, Tuskfolk, Mirefolk, Ravenfolk, Rootborn.
- Equipped gear: smith apron and future armor/clothing.
- Held/offhand items: hatchet, sword, polearm, bow, buckler.
