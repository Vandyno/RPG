# Sprite Template Usage

Use these templates as guide files only. They are not final game assets.

Template folder:

- `res://art_templates/humanoid_actor_16dir_64x64.svg`
- `res://art_templates/humanoid_body_parts_16dir_64x64.svg`
- `res://art_templates/humanoid_equipment_layers_16dir_64x64.svg`
- `res://art_templates/interactables_objects_pickups.svg`
- `res://art_templates/item_icons_and_ground_sprites.svg`
- `res://art_templates/terrain_tiles_optional_16x16.svg`

## Rules That Matter

- Keep transparent background.
- Keep frame size exact.
- Paint art on a separate layer from the guide.
- Remove or hide guide lines before importing final sprites.
- Do not move the pivot/feet marker.
- Do not change direction order.
- Do not center humanoids by image center. Center them by feet/y-sort origin.

## Direction Order

For actor and equipment sheets, directions are left to right:

`east`, `east_southeast`, `southeast`, `south_southeast`, `south`, `south_southwest`, `southwest`, `west_southwest`, `west`, `west_northwest`, `northwest`, `north_northwest`, `north`, `north_northeast`, `northeast`, `east_northeast`

This is the current in-game `FacingBuckets` order.

## Humanoid Actor Template

File: `res://art_templates/humanoid_actor_16dir_64x64.svg`

Use for:

- previewing complete full actor silhouettes
- checking direction readability
- checking animation poses
- checking a final composite after body parts and equipment exist

Do not use this as the main NPC generation target. Current NPCs are rendered in parts, not as baked full sprites.

Frame:

- `64x64`
- feet/y-sort pivot at `(32, 40)`
- collision guide radius `10 px`
- safe drawing area is the green dashed rectangle

Rows:

- `idle`
- `walk`
- `sneak`
- `attack_swing`
- `attack_thrust`
- `attack_projectile`
- `cast`
- `body_dead`

AI prompt hint:

> Create a transparent pixel-art top-down RPG humanoid sprite sheet using this exact 64x64 grid. Preserve the 16 direction columns and animation row labels. Keep the feet planted on the yellow pivot marker in every frame. Do not draw outside the safe area except for intentional weapons, hair, horns, cloaks, or species features.

## Humanoid Body-Part Template

File: `res://art_templates/humanoid_body_parts_16dir_64x64.svg`

Use for:

- player and NPC body-part generation
- base body silhouettes
- head, torso, waist/hips, feet, and hands
- species feature layers
- body/death pose layer planning

This is the closest template to how NPCs are rendered now. `HumanoidAvatar2D` draws a stack of parts and overlays, roughly:

- shadow
- back species features
- feet
- boots
- waist/hips
- legs
- back hand layer
- torso
- back/cloak layer
- chest equipment
- body species features
- front hand layer
- head
- front species features
- hair
- head equipment
- markings/face

Rows in this template are guide rows for separate part layers:

- `shadow`
- `feet`
- `waist_hips`
- `hands_back`
- `torso`
- `chest_equipment`
- `species_body`
- `hands_front`
- `head`
- `hair_face_feature`

AI prompt hint:

> Generate one transparent humanoid body-part layer only, not a full character. Use this 64x64 16-direction grid. Preserve the feet/y-sort pivot at the yellow marker and align the requested part to the pink anchors. Leave all unrelated body parts transparent.

## Equipment Layer Template

File: `res://art_templates/humanoid_equipment_layers_16dir_64x64.svg`

Use for:

- smith apron
- future armor/clothing
- hair
- species feature overlays
- back items
- held weapons
- shields

Rows:

- `body_base`
- `head`
- `hair_features`
- `chest`
- `legs_boots`
- `right_hand`
- `left_hand`
- `back`

Pink dots are rough anchor guides. They are not exact runtime math, but they keep generated art close to the current avatar shape.

For held items, the grip point matters more than the sprite center. Swords, hatchets, bows, polearms, and shields should align to hand anchors.

AI prompt hint:

> Generate only the requested equipment layer on a transparent background. Do not include the body unless asked for alignment preview. Keep every frame in the same 64x64 cell and preserve the 16 direction order. Align the item or clothing to the pink anchor dots and yellow feet pivot guide.

## Interactables, Objects, Pickups

File: `res://art_templates/interactables_objects_pickups.svg`

Use for:

- readable notice
- containers and strongboxes
- campfire/rest object
- job board
- forge service prop
- forge hearth
- doors
- gates
- generic pickup ground props
- debug/location marker if kept visible

Frame sizes:

- small objects and pickups: `32x32`
- POI/service props: `48x48`
- doors: `32x48`
- gates: `64x48`

Yellow marker is the origin/y-sort point. For tall props, art can rise above the marker, but the contact point should stay there.

Runtime pick radius can be larger than the sprite frame. Do not enlarge art just to fill the pick radius.

AI prompt hint:

> Create transparent RPG object sprites inside the given frame boundaries. Use the yellow marker as the ground contact and y-sort origin. Keep the object readable at small size. Do not add backgrounds, shadows outside the frame, labels, or guide marks.

## Item Icons and Ground Sprites

File: `res://art_templates/item_icons_and_ground_sprites.svg`

Use for:

- inventory icons
- spell icons
- simple pickup ground sprites
- weapon ground sprites
- held item alignment previews

Frame sizes:

- inventory icons: `32x32`, centered
- most ground items: `32x32`, pivot at contact center
- polearm ground item: `64x32`
- held item layer preview: `64x64`

Held item art should eventually use the full 16-direction equipment template. This file is for quick item shape, icon, and ground pickup generation.

AI prompt hint:

> Generate transparent item art only. For icons, center the item in the 32x32 frame. For ground sprites, place the contact point on the yellow marker. For held items, align grip points to the pink dots and avoid changing frame size.

## Optional Terrain Template

File: `res://art_templates/terrain_tiles_optional_16x16.svg`

Use later for:

- grass
- road
- wood floor
- bridge
- hill
- forest ground
- water
- stone wall
- wood wall

Frame:

- `16x16`
- top-left origin
- 4 variants per tile kind

First pass can skip terrain and structures. Terrain is included because it is cheap to template and prevents future atlas confusion.

Important:

- `water`, `stone_wall`, and `wood_wall` are blocked.
- `forest` is currently walkable, but should be redesigned before final art.
- Structure facades should not be generated from this terrain template. They need separate redesign before final art.

## Current Asset Map

Use `humanoid_body_parts_16dir_64x64.svg` as the primary template for:

- `char_player`
- `npc_harrow_venn_world`
- `npc_maera_pike_world`
- `npc_road_thug`
- `npc_test_raider`
- `npc_people_test_human`
- `npc_people_test_tanglekin`
- `npc_people_test_tuskfolk`
- `npc_people_test_mirefolk`
- `npc_people_test_ravenfolk`
- `npc_people_test_rootborn`
- runtime `body` entities

Use `humanoid_actor_16dir_64x64.svg` only for composite previews and readability checks for those same actors.

Use `humanoid_equipment_layers_16dir_64x64.svg` for:

- `placeholder_smith_apron`
- `placeholder_hatchet`
- `placeholder_sword`
- `placeholder_polearm`
- `placeholder_bow`
- `placeholder_buckler`
- future species feature layers
- future armor/clothing layers

Use `interactables_objects_pickups.svg` for:

- `object_road_notice`
- `poi_briarwatch_square`
- `poi_harrow_forge`
- `poi_harrow_forge_hearth`
- `object_harrow_forge_door`
- `object_harrow_forge_exit`
- `object_north_gate`
- `object_training_gate`
- `object_road_cache`
- `object_warden_cache`
- `object_sealed_strongbox`
- `object_roadside_campfire`
- `location_briarwatch_crossroads_marker` if it stays visible
- generic pickup ground frames

Use `item_icons_and_ground_sprites.svg` for:

- `item_gold_coin`
- `item_old_toolbox`
- `item_roadside_draught`
- `item_river_mint`
- `item_road_hatchet`
- `item_training_sword`
- `item_test_polearm`
- `item_hunting_bow`
- `item_traveler_buckler`
- `item_smith_apron`
- `spell_fire_blast`

Use `terrain_tiles_optional_16x16.svg` for:

- `grass`
- `water`
- `bridge`
- `stone_wall`
- `wood_wall`
- `wood_floor`
- `forest`
- `hill`
- `road`
- interior void, if kept as a tile asset

No structure facade template is included in this pass. Forge, shop, and town hall structures should be redesigned before generating final art.

## Manual Painting Workflow

1. Open the SVG in Aseprite, Krita, Photoshop, Inkscape, or another editor.
2. Put guide lines on a locked top layer if the editor supports layers.
3. Paint on transparent layers beneath or above the guide.
4. Keep art inside frame boundaries.
5. Export final art as PNG with guides hidden.
6. Verify frame size and direction order before import.

## AI Generation Workflow

1. Use the template image as the reference.
2. Ask for transparent background.
3. Ask the model to preserve grid, frame size, row labels, and direction order.
4. Generate one asset family at a time.
5. Reject outputs that move the feet pivot, merge frames, add backgrounds, or change directions.
6. Clean final art manually before import.
