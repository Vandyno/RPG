# Humanoid Character Plan

Status: proposal, not canon.

Purpose: define the shared humanoid actor model for playable peoples and NPCs:
identity, appearance, inventory, equipment, spells, death bodies, looting, and
pickpocket access.

Important structural rule: this is not just for the player. All humanoids should
eventually share the same character profile shape, because NPCs can have their
own inventories, equipment, spells, stats, race/people bonuses, and visual
identity. Current placeholder NPCs should migrate onto this system when it is
ready instead of remaining one-off world markers.

Universal NPC rule: everyone with person-like movement, interaction, inventory,
or combat is an NPC/actor. Hostility is state. Combat is behavior. A humanoid
"enemy" is an NPC currently hostile because of faction, crime response, scripted
state, or test setup; it must not use a separate humanoid model or permanent
`kind: "enemy"` content type.

Humanoid NPCs should be full characters even when a test slice only uses part of
that behavior. They should have a path to movement, attacking, interaction,
inventory/equipment ownership, profile-backed appearance, and future AI. Do not
add new humanoid markers that would need to be replaced once brains or combat
arrive.

Death, looting, and pickpocketing should also use this same model. A dead
humanoid leaves a body on the ground with its remaining inventory and equipment
available to inspect or loot. A living humanoid can expose a similar inventory
view through pickpocketing when gameplay allows it. This Skyrim-like continuity
is core to the game feel.

Beasts and monsters may share actor systems such as health, inventory/loot,
factions, AI, detection, death state, and persistence where useful. They should
not be forced into humanoid-only systems. A bear can have a body and lootable
contents, but it should not need weapon slots, armour layers, spellbooks, or
paper-doll appearance parts unless a specific creature type calls for them.

## Core Direction

Use a shared humanoid character profile with a layered paper-doll avatar.

The player and humanoid NPCs are built from the same small visual parts:

- head silhouette
- shoulders/torso silhouette
- waist/hips silhouette
- hands
- feet
- skin or surface palette
- hair, crest, leaves, tusks, beak, or other people-specific feature layer
- eyes or face marks
- equipped clothing/armour layers
- held weapon/offhand layers later

This should make characters distinct at small tile scale while keeping the
gameplay model simple.

Appearance is one part of the humanoid profile. It should not become the whole
system.
Individual humanoids should be able to vary their visual proportions through
appearance data. Shoulder width, torso width, waist width, head size, hand
size, and foot size are visual identity knobs, not movement or combat rules.

Finished humanoid avatars should aim for a readable top-down/RimWorld-like body
stack:

- head
- shoulders/torso
- waist/hips
- hands
- feet

Start with feet instead of full legs. Feet are more readable at small scale,
easier to animate, and avoid clipping problems with robes, armour, cloaks, and
turning. The layer contract can leave room for `legs` later, but visible full
legs should be optional polish, not required for the first implementation.

## Use Peoples, Not Generic Fantasy Races

Internal IDs should use `people_id`, not `race`.

Current lore-supported people IDs:

- `people_human`
- `people_tanglekin`
- `people_tuskfolk`
- `people_mirefolk`
- `people_ravenfolk`
- `people_rootborn`

The visible system can still call this "People" or "Ancestry" in UI later.
Do not add elves, dwarves, or generic fantasy placeholders unless canon changes.

Early people silhouette rules:

- Tanglekin should read as monkey-like agile humanoids. Use shorter, lean bodies,
  long arms, strong grasping hands/feet, a visible tail, muzzle/brow/ear
  features, and nimble posture. Do not represent them as cord/wrap people; wraps
  and clothing must come from equipment.
- Tuskfolk should usually read shorter and stockier than humans. Use a
  short-heavy body plan, broad shoulders/torso/waist, slightly larger hands and
  feet, and visible tusk feature layers. This is a visual rule, not a movement
  penalty by itself.
- Mirefolk should read shorter and slenderer than their first placeholder pass,
  while keeping wide amphibian heads, high eyes, webbed hands/feet, and wetland
  palettes.
- Ravenfolk should read as slender feathered humanoids. Use narrow shoulders,
  narrow torso/waist, visible body feathers, head crests, beaks, quill marks,
  and small tail-feather attachments. Do not bake robes/clothing into the people;
  worn gear still comes from equipment. Avoid functional wings for the first
  playable avatar pass.

Current iteration screenshots and reusable model notes live in
`docs/PEOPLE_VISUAL_MODEL_ITERATIONS.md`. Treat those as proposal direction, not
final canon art approval.

## Profile Shape

A humanoid character profile should hold identity and references to owned
systems. Movement and combat controllers can act on the profile, but should not
own the data.

```json
{
  "character_id": "npc_harrow_venn",
  "people_id": "people_human",
  "faction_id": "faction_briarwatch",
  "state": "alive",
  "handedness": "right",
  "level": 1,
  "stats": {},
  "derived_bonuses": {},
  "appearance": {},
  "inventory_owner_id": "char_harrow_venn",
  "equipment_owner_id": "char_harrow_venn",
  "spellbook_owner_id": "char_harrow_venn",
  "loadout_id": "loadout_harrow_venn",
  "corpse_entity_id": ""
}
```

The `appearance` object should stay visual. Inventory, equipment, spells,
faction, crime state, race/people bonuses, and stats should live outside it.
`handedness` is optional profile data and defaults to right-handed. It controls
which body side uses one-handed weapons, polearm rear grips, bow draw hands, and
future tool poses; it should not swap visually just because the actor turns.

```json
{
  "people_id": "people_human",
  "body_plan_id": "body_humanoid_average",
  "head_id": "head_human_round",
  "palette_id": "palette_human_warm_brown",
  "hair_id": "hair_short_waves",
  "hair_color_id": "hair_black",
  "eye_id": "eyes_dark",
  "marking_id": "",
  "base_clothing_id": "clothing_traveler_plain"
}
```

`base_clothing_id` is optional and can be empty. The current target is that
characters do not visually wear clothing unless armour or clothing is actually
equipped. Equipped armour and clothing should come from `EquipmentManager` and
render as layers over the body. Avoid `outfit_id` unless it is later defined as
a non-equipped costume or NPC uniform concept.

People definitions should constrain what parts are valid:

```json
{
  "id": "people_tuskfolk",
  "display_name": "Tuskfolk",
  "body_plans": ["body_humanoid_heavy"],
  "heads": ["head_tuskfolk_broad"],
  "palettes": ["palette_tuskfolk_umber", "palette_tuskfolk_ash"],
  "features": ["feature_tusks_small", "feature_tusks_broad"],
  "bonuses": {
    "future_bonus_id": 1
  }
}
```

Stats and bonuses should be actor data, even if they mean very little in the
current build. Long term, this should feel Skyrim-like: every character has
stats, the player's stats matter more to the UI, and NPC stats still drive
combat, resistance, spells, detection, and special cases where needed.

## Actor Categories

Use shared actor plumbing where it helps, then specialize by actor category.

- `humanoid`: full character profile, people ID, inventory, equipment,
  spellbook/loadout, stats, people bonuses, layered appearance, body looting,
  pickpocket access
- `creature`: health, AI, faction/hostility, detection, death body, simple
  static or semi-static appearance, optional inventory/loot owner
- `monster`: same broad path as creature, with special attacks or supernatural
  rules as needed
- `object`: not an actor unless it needs health, AI, ownership, or combat state

Do not make every creature pretend to be humanoid just to reuse code.
Do not make hostile humanoids pretend to be a separate enemy category just to
start combat. They remain NPCs with hostile state and combat behavior.

## Ownership

Do not put this directly in `PlayerController`.

Recommended ownership:

- `PlayerController`: movement, facing, animation hooks.
- `HumanoidAvatar2D`: visual renderer attached under player and NPC nodes.
- `AppearanceDefinitionDatabase`: loads valid people, palettes, and part IDs.
- future `CharacterProfileManager`: owns humanoid profiles, including player
  appearance, NPC appearance, inventory references, equipped items, spell lists,
  stats, people bonuses, alive/dead state, corpse/body references, and
  save/load.
- `InventoryManager`: should eventually support inventories by owner ID.
- `EquipmentManager`: should eventually support equipment by owner ID.
- future spell/ability manager: should eventually support spellbooks/loadouts by
  owner ID.
- future theft/pickpocket system: should open living humanoid inventories
  through rules, risk, detection, and faction/crime consequences.
- NPC data: should be able to include an `appearance` object using the same
  shape as the player.

This keeps appearance reusable for all humanoids and keeps movement controllers
clean.

## Lifecycle States

Humanoid profiles should have explicit state.

Initial states:

- `alive`: normal active actor
- `unconscious`: downed actor, not dead, inventory access depends on rules
- `dead_body`: body remains in world and can be looted
- `despawned`: actor/body no longer active in the current world state

These states matter for quests, looting, stealth, save/load, and combat
resolution. Do not treat death as simply deleting the NPC.

## Stats And People Bonuses

Every humanoid character should eventually have stats, even when most NPC stats
are invisible to the player.

Early shape:

```json
{
  "stats": {},
  "derived_bonuses": {}
}
```

People/race bonuses should apply to characters, not only to the player. A
Tuskfolk guard, a Tanglekin thief, and a Rootborn warden should all receive the
same kind of people-based modifiers that the player would receive.

Do not build the full stat system now. For the first slice, preserve the data
shape and keep current player progression working.

## Renderer

First renderer can draw simple Godot shapes before final art exists.

Layer order:

1. shadow
2. back attachments, tails, cords, rear-facing cloaks/back gear, and far-side
   held items
3. feet
4. equipped boots
5. waist/hips
6. equipped legs/clothing
7. far hands, gloves, and far-side held items
8. shoulders/torso
9. rear-visible cloaks/back gear
10. equipped chest clothing/armour, including wrapping apron shapes
11. body people features
12. near hands, gloves, and near-side held items
13. head
14. front people features, tusks, beaks, eyes, hair, head gear, and markings
15. face/eyes
16. selection/quest/combat overlays

The first shape renderer quantizes facing into 16 visual buckets. It still
uses procedural shapes, but attached parts and held items should sort through
the back/body/front contract instead of drawing every people feature on top of
the body. This keeps things like Tanglekin tails behind the torso from
front-facing angles and lets side-facing held weapons follow the near/far hand.
Movement position may remain analog, but stored facing, avatar body math,
and attack VFX use snapped bucket direction. Attack hit shapes use continuous
aim direction so combat is not functionally limited to 16 angles.

Current 16-direction QA uses large per-people detail captures from
`scripts/tools/capture_people_crowd_sheet.gd`. The useful proof format is:

```text
reports/people_iterations_v51/round_09_<people>_16_detail_<range>.png
```

The current renderer has first-pass direction-aware people features for
Tanglekin tails/ears, Tuskfolk tusks, Mirefolk eyes/webbing, Ravenfolk
beaks/crests/tail feathers, and Rootborn crowns/body marks. This is still
procedural placeholder art, not final sprite production.

Later, the same layer contract can swap shape drawing for spritesheets or
texture atlases.

## Bodies, Looting, And Pickpocketing

Humanoid bodies should preserve character identity after death.

Target behavior:

- a killed humanoid becomes a body/corpse entity at its death position
- the body keeps the humanoid's appearance or a collapsed variant of it
- the body keeps remaining inventory and equipped items unless combat effects
  explicitly remove, break, or drop them
- interacting with the body opens a loot view backed by that humanoid's
  inventory owner ID
- taking equipped items updates both equipment and inventory state
- body state persists while the body remains loaded
- for now, a body can stay until the player moves far enough away for its area
  to unload
- living humanoids can expose a similar inventory view through pickpocketing
- pickpocket access requires sneaking and not being seen
- hostile actors and NPCs should have a 180 degree view cone in their facing direction
- future pickpocket rules can add light, sound, skill, hostility,
  faction/crime response, and item difficulty

Early implementation can fake ragdoll as a rotated/collapsed layered avatar.
Actual physics is not required for the first slice.

Body persistence can become more detailed later. Important or quest-linked
bodies may need longer persistence, but the first rule is distance/unload based.

Body entity data should be explicit enough to reconnect identity and inventory:

```json
{
  "corpse_entity_id": "corpse_harrow_venn",
  "character_id": "npc_harrow_venn",
  "inventory_owner_id": "char_harrow_venn",
  "equipment_owner_id": "char_harrow_venn",
  "death_position": [120.0, 88.0],
  "death_time": 540,
  "collapsed_pose_id": "pose_fallen_side"
}
```

Body loot and pickpocket should use the same inventory screen pattern. The
difference is access rules: dead/unconscious bodies are direct access, while
pickpocketing requires sneaking and being outside the target's view cone.

## Equipment Visual Sync

Equipment must be visually reflected on humanoid avatars.

Rules:

- equipped armour/clothing renders from equipment state, not appearance state
- equipped weapons and offhand items render from equipment state
- held equipment uses body-side roles: dominant hand for one-handed weapon use
  and polearm rear grip, off-hand for shields and bow grip
- taking an equipped item from a body updates both the loot view and visual body
- pickpocketing equipped items should use the same equipment state
- no visual clothing should come from `appearance`, `visual_model_id`, or
  `base_clothing_id`; if it is visible, it should be an equipped item

Equipment items should eventually include visual metadata:

```json
{
  "visual_layer_id": "layer_leather_vest",
  "avatar_slot": "body_armour",
  "held_pose": "one_hand_low",
  "paperdoll_sprite_id": "sprite_leather_vest_a",
  "icon_id": "icon_leather_vest"
}
```

The exact field names can change, but the content needs to tell the renderer
which avatar layer, held pose, paper-doll sprite, and inventory icon to use.

Add a validation tool when equipment visuals exist. It should iterate over the
current item definitions, equip every weapon/armour/offhand item on a test
humanoid, and verify that each valid equipment item produces a drawable layer or
an explicit accepted placeholder. The test should adapt to new item IDs instead
of hardcoding a fixed list.

Future validation checklist:

- every equipment item can render or has an accepted placeholder
- every equipment item declares the expected visual metadata
- killing a humanoid creates a body entity
- body interaction opens that humanoid's inventory
- removing equipped items updates avatar/body visuals
- pickpocket is blocked while the target sees the player
- pickpocket is allowed while sneaking and unseen
- creature deaths can use simpler body/loot rules without humanoid equipment
  slots

## Art Reference Workflow

Use player-approved reference images before generating durable equipment or
humanoid assets.

Recommended reference folder:

```text
assets/reference/humanoid_style/
```

Useful references:

- top-down or three-quarter character examples
- armour and clothing examples
- weapon examples
- body proportion examples
- palette/material examples
- UI portrait examples if the portrait style should match the world avatar

Once references exist, generated test assets should target that style instead
of inventing a new one. Leather armour and early weapons are good first assets
because they are useful for gameplay testing and likely to survive later art
passes if the style is correct.

## First Slice Implementation

Build only this much first:

1. Add `HumanoidAvatar2D` that can replace the red debug player circle with a
   small layered humanoid.
2. Support a human baseline plus two or three palette/hair variants.
3. Add a minimal character profile data shape with owner IDs.
4. Use the same renderer for at least one NPC after the player works.
5. Add one leather armour and one or two grounded weapon visuals for testing
   equipment sync.
6. Plan current placeholder NPC migration onto humanoid profiles once the shared
   avatar path is stable.
7. Add save/load only when character profiles exist, not as loose fields on the
   player controller.

Do not build the full Skyrim actor simulation yet. The warning is serious:
prove the shared avatar/profile path first, then add bodies, pickpocketing,
full NPC inventories, and spellbooks in small playable steps.

## Goal Checkpoints

Use these checkpoints when running a broad `/goal`. Complete and verify each
checkpoint before expanding the next one.

### Checkpoint 1: Profile Shape

Done means:

- minimal humanoid profile data shape exists
- profile includes `character_id`, `people_id`, `state`, owner IDs, stats
  fields, and appearance fields
- player can have a profile without moving player movement data into the
  profile
- at least one existing placeholder NPC can reference a profile
- tests cover profile defaults and malformed/missing optional fields

Stop line:

- do not add corpses, pickpocket, spellbooks, race bonuses, or full NPC
  inventories here

### Checkpoint 2: Shared Humanoid Avatar

Done means:

- `HumanoidAvatar2D` exists
- player uses `HumanoidAvatar2D` instead of the red debug circle
- at least one existing NPC uses the same avatar path
- avatar body stack supports head, shoulders/torso, waist/hips, hands, and feet
- legs are not required, but the layer contract does not block adding them later
- tests or smoke checks verify player and NPC avatar creation

Stop line:

- do not generate final art or build full animation here

### Checkpoint 3: Equipment Visual Sync Foundation

Done means:

- equipment item definitions can declare visual metadata or accepted
  placeholders
- avatar renderer can read equipped weapon/offhand/body visual state
- equipped item changes can request avatar refresh
- validation covers every current equipment item dynamically from item data
- missing visuals fail loudly unless explicitly marked as placeholder

Stop line:

- do not require final armour/weapon art before the style reference folder is
  populated

### Checkpoint 4: Placeholder NPC Migration

Done means:

- current humanoid placeholder NPCs have a path to profiles
- one real existing NPC is profile-backed end to end
- NPC still supports existing dialogue/faction/shop/quest behavior
- tests verify the migrated NPC still appears and remains interactable

Stop line:

- do not migrate every NPC if it risks breaking first-slice interaction

### Checkpoint 4.5: Shared Inventory Transfer UI

Done means:

- opening a lootable container shows player inventory and target inventory
  together
- items can transfer both directions when allowed
- containers and bodies use inventory owner IDs, not one-off loot bag logic
- the UI remains clean and usable in the current RPG HUD
- tests cover opening a container, seeing both inventories, taking an item, and
  putting an item back

Stop line:

- do not build shop pricing, crime, stealth, pickpocket rules, or a full trade
  economy here

### Checkpoint 5: Death Body And Loot Loop

Done means:

- a fully functional hostile humanoid NPC test fixture exists outside spawn town
- the test actor uses a humanoid profile, is combat-capable, has a sword
  equipped, and carries a bow in inventory for loot verification
- killing a humanoid can create a body entity at the death position
- body references character, inventory owner, equipment owner, and collapsed pose
- interacting with body opens the same inventory screen pattern used for loot
- body remains until the area unloads or distance cleanup removes it
- tests verify body creation and body inventory access

Stop line:

- do not build long-term corpse persistence tiers yet

### Checkpoint 6: Pickpocket Groundwork

Done means:

- living humanoid inventory can be opened through a pickpocket action only when
  rules allow it
- rule requires sneaking and not being seen
- NPC/hostile actor sight uses a 180 degree cone in facing direction
- tests verify blocked while seen and allowed while sneaking unseen

Stop line:

- do not build full stealth, crime, bounty, schedules, lighting, sound, or item
  difficulty yet

### Checkpoint 7: Stats And People Bonuses

Done means:

- humanoid profiles can hold stats
- people definitions can declare simple bonuses
- bonuses apply to player and NPC humanoids through the same lookup path
- existing player progression keeps working
- tests verify one NPC and the player receive expected simple bonuses

Stop line:

- do not build full RPG progression for NPCs here

### Checkpoint 8: Spellbook/Loadout Groundwork

Done means:

- humanoid profiles can reference spellbook/loadout owner IDs
- no player-only spellbook assumption is introduced
- one test fixture can attach a spell/loadout reference to an NPC without
  breaking existing combat

Stop line:

- do not build the full spellcasting system here

## Broad Goal Done State

A broad `/goal` for this plan is done when checkpoint progress is real,
verified, and documented. It does not need every future Skyrim-like feature
finished in one run.

Minimum useful done state:

- Checkpoints 1 through 4 complete
- checkpoint results covered by tests or smoke verification
- remaining checkpoints documented as next steps
- no unrelated dirty files reverted
- no broad systems added before they are needed

## Implementation Progress

Updated 2026-07-06.

- Checkpoint 1, Profile Shape: complete for first slice. Minimal profile data
  exists in `data/character_profiles.json`, loads through `ContentDatabase`,
  validates required owner IDs/stats/appearance fields, and covers malformed
  optional fields in tests.
- Checkpoint 2, Shared Humanoid Avatar: complete for first slice.
  `HumanoidAvatar2D` renders the player and Harrow Venn through the same
  layered body stack with explicit back/body/front sorting for attachments,
  hands, head, features, face, and equipment hints.
- Checkpoint 3, Equipment Visual Sync Foundation: complete for first slice.
  Current equipment items declare avatar visual metadata with accepted
  placeholders, avatar refresh is wired to equipment changes, and validation
  covers equipment items dynamically from item data. Appearance no longer draws
  clothing or role accents by itself; visible worn layers must come from
  equipped items.
- Checkpoint 4, Placeholder NPC Migration: complete for first slice. Harrow
  Venn is profile-backed end to end and keeps existing dialogue/quest/faction
  behavior.
- Avatar polish after checkpoint 4: current shape avatar supports directional
  walking, sneak crouch/step animation, body turning, visible feet, simplified
  face turns, and proportion knobs for shoulder width, torso width, waist
  width, head size, hand size, and foot size. Keep future armour generation
  aligned to these same body anchors instead of creating separate armour-only
  motion. Face feature positions are now turn-aware so side-view mouth/eye
  marks move with the head instead of sliding across it. Facing now resolves to
  16 visual buckets for avatar body math, player facing, and attack VFX, while
  attack hit shapes use continuous aim. Tanglekin tails draw as back
  attachments instead of front overlays, Mirefolk profiles always keep high-eye
  face features, and held equipment follows near/far hand sorting.
- Equipment/attachment layering after checkpoint 8: complete for first slice.
  Worn gear now has slot bands for back, boots, legs, gloves, chest, and head;
  back gear swaps rear/front sorting by facing; and Smith Apron uses a wrapping
  chest visual instead of a breastplate-shaped placeholder.
- 16-direction body projection pass: complete for first slice. Torso, waist,
  shoulders, hand anchors, chest armour, apron wrap, leg gear, and back gear now
  share one projected body-space helper so diagonal facing does not mix rotated
  feet/weapons with screen-flat torso equipment.
- 16-direction people feature consistency pass: complete for first slice.
  People-specific attachments and marks now vary across front, side, diagonal,
  and back buckets instead of drawing one flat overlay at every angle. The
  current proof capture is
  `reports/people_iterations_v47/round_05b_16_direction_turnaround.png`.
- Smith Apron display rule: first pass complete. It now renders as a front
  cloth panel when front-facing, a narrow side edge when side-facing, and back
  straps/ties when rear-facing instead of behaving like centered torso armour at
  every angle.
- Debug appearance creator: first pass complete. Press `P` in-game to open a
  dev-only character creator panel that cycles people, generated/variant
  appearances, facing buckets, and simple gear previews, then applies the
  selected appearance to the player for fast visual testing.
- Armour/body-part generation path: `HumanoidAvatar2D.get_body_part_anchors()`
  exposes head, chest, waist, hand, and foot anchors from the same facing,
  proportion, stride, and hand-sway math used by the visible body. Generated
  armour should target these anchors and equipment slots first, then replace
  placeholder drawing later without adding a separate animation rig.
- Checkpoint 4.5, Shared Inventory Transfer UI: complete for first slice.
  Containers open a two-sided inventory transfer view keyed by owner IDs. Items
  can move from target to player and back, and tests cover a locked strongbox
  flow with take/put transfer.
- Checkpoint 5, Death Body And Loot Loop: complete for first slice. The Road
  Thug outside spawn town is profile-backed, combat-capable, visually humanoid,
  equipped with a sword, and carries a bow. Killing him creates a temporary
  body at the death position with character, inventory owner, equipment owner,
  collapsed pose, and shared transfer UI loot access. Tests cover body creation
  and taking the sword/bow through the transfer view.
- Dedicated combat/loot hostile actor: `npc_test_raider` now exists outside
  spawn town with its own profile, sword visual, bow inventory, and lootable
  temporary body after death. This keeps future equipment, armour, and loot
  testing separate from the Road Thug quest fixture.
- Appearance Generator Groundwork: complete for first slice.
  `HumanoidAppearanceGenerator` composes deterministic appearances from
  people visual models by exact `variant_id` or stable seed, supports optional
  small proportion jitter, applies modular appearance overrides, and lets
  character profiles opt into `appearance_generation` while authored named NPC
  appearances remain static unless explicitly changed.
- People hostile actor test area: complete for first slice.
  Six non-canon hostile NPC actors near spawn town now cover Human, Tanglekin,
  Tuskfolk, Mirefolk, Ravenfolk, and Rootborn profiles generated through
  `appearance_generation`. Each has owner IDs, simple equipment/inventory,
  reachable placement, and death-body loot coverage. Fixture details live in
  `docs/SPAWN_TOWN_PEOPLE_HOSTILE_ACTOR_TEST_AREA_HANDOFF.md`.
- Hostile actor naming cleanup: complete for first slice.
  Authored humanoid hostile actors now use `npc_*` world IDs instead of
  `enemy_*`, the Road Patrol quest targets `npc_road_thug`, and content
  validation rejects new world object IDs that start with `enemy_`.
- NPC brain foundation: complete for first slice. Outside-town hostile test
  actors can opt into `brain_id: "hostile_basic"` to chase the player with the
  same continuous movement/collision style as the player. Player and NPC weapon
  attacks now route through shared `ActorWeaponAttackAction` nodes that draw
  no fake weapon art; they drive humanoid avatar attack pose while the existing
  hand/equipment renderer moves the equipped weapon from hand anchors and the
  action checks a weapon-specific swept hitbox. Empty hands use a punch action
  instead of pretending to swing an invisible weapon. Spell use is explicit per
  actor; the Ravenfolk people-test actor channels
  `spell_fire_blast`, while the other current brain actors remain weapon-only.
  Brain actors path around blocked tiles, leash back to their home/spawn area
  when pulled too far, and keep their live position across entity refreshes
  instead of snapping back to authored spawn.
- Checkpoint 6, Pickpocket Groundwork: complete for first slice. Profile-backed
  living humanoids can expose owner-ID inventory through the shared transfer UI
  only while the player is sneaking and outside the target's 180-degree facing
  cone. Harrow Venn carries a tiny owner-keyed test inventory and tests cover
  blocked-while-seen, blocked-while-standing, and allowed-unseen access.
- Checkpoint 7, Stats And People Bonuses: complete for first slice. Humanoid
  profiles now preserve `stats` and `derived_bonuses` fields, people
  definitions load from `data/people.json`, and `people_human` applies a simple
  shared `resolve` bonus through the same lookup path for the player and Harrow
  Venn. Existing player progression remains player-focused and unchanged.
- Checkpoint 8, Spellbook/Loadout Groundwork: complete for first slice.
  Spell slots now support owner IDs while keeping the existing player-facing
  API intact. The dedicated test raider carries NPC spellbook/loadout references
  to `spell_fire_blast` without enabling full NPC spellcasting or changing
  combat behavior.

## Recommended Next Goal

Next broad run should start after checkpoint 8.

```text
/goal Continue docs/HUMANOID_CHARACTER_PLAN.md after verified checkpoints 1-8.

Preserve the current profile/avatar, equipment sync, migrated NPC, body loot,
pickpocket, people bonus, and owner-aware spell/loadout groundwork.

Next useful work should improve the playable slice around these foundations:
- make owner-keyed NPC inventory/equipment less fixture-only where it improves
  a concrete NPC, body, shop, or quest flow
- keep pickpocket limited to the current sneak/unseen gate unless crime or
  detection becomes the explicit goal
- keep spell work to owner/loadout plumbing or one concrete gameplay slice

Do not build long-term corpse persistence, full crime/stealth, full NPC
progression, full spellcasting, final art, or broad actor simulation without a
new checkpoint plan.
```

## Game Structure Implication

The long-term model should treat the player as one humanoid actor, not as a
special case with unique-only systems.

Good direction:

- player and NPCs both reference character profiles
- inventories are keyed by character or container owner
- equipment is keyed by character owner
- spellbooks/loadouts are keyed by character owner
- stats and people bonuses apply to player and NPC humanoids
- appearance renders from the same profile data as equipment
- combat asks actor systems for equipment/spell/stat data by owner ID
- death converts humanoid actors into lootable body entities
- pickpocketing opens living humanoid inventories through a rule gate

Bad direction:

- `player_inventory` separate from all NPC inventories forever
- `player_equipment` separate from all NPC equipment forever
- appearance stored directly on `PlayerController`
- NPC visuals authored as unrelated one-off marker colors
- placeholder NPCs kept forever outside the shared character system
- hostile actors dropping abstract loot bags while their actual body inventory vanishes

## Later Mechanics

People gameplay differences should be small and explicit:

- one combat or survival bonus
- one exploration, social, or lore bonus
- one drawback or reputation complication if useful

These should belong to progression/condition/effect systems later, not the
visual renderer.

## UI Fit

Character creation and NPC inspection should eventually live in the
Systems/Character flow from `docs/ui/UI_TARGET.md`:

- large portrait/silhouette preview
- people selector
- part selectors with swatches
- no debug text dump
- mobile landscape controls

For now, only the shared world avatar contract matters.
