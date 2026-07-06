# Spawn Town People Enemy Test Area

Status: implemented test fixture.

Purpose: non-canon debug range near Briarwatch/spawn town with one enemy for
each current people. Use it to inspect generated silhouettes, combat, death
bodies, loot, equipment visuals, and future pickpocket behavior.

This is not canon encounter design.

## Current Fixtures

| People | Enemy ID | Profile ID | Tile |
| --- | --- | --- | --- |
| Human | `enemy_people_test_human` | `char_people_test_human` | `[-16, 0]` |
| Tanglekin | `enemy_people_test_tanglekin` | `char_people_test_tanglekin` | `[-18, -2]` |
| Tuskfolk | `enemy_people_test_tuskfolk` | `char_people_test_tuskfolk` | `[-18, 2]` |
| Mirefolk | `enemy_people_test_mirefolk` | `char_people_test_mirefolk` | `[-20, 0]` |
| Ravenfolk | `enemy_people_test_ravenfolk` | `char_people_test_ravenfolk` | `[-23, -2]` |
| Rootborn | `enemy_people_test_rootborn` | `char_people_test_rootborn` | `[-22, 2]` |

The range is outside Briarwatch's authored town bounds. This keeps future enemy
AI from immediately rampaging through town while the fixtures still remain
reachable from spawn through the west gate.

The range deliberately avoids overloading:

- `enemy_road_thug` at `[-6, 1]`, which is a Road Patrol quest fixture
- `enemy_test_raider` at `[-10, 1]`, which is the dedicated combat/loot fixture

## Appearance Generation

Each profile uses `appearance_generation` in `data/character_profiles.json`.

The fixed `people_id` is authoritative. `ContentDatabase.get_character_profile`
routes the generation through `HumanoidAppearanceGenerator`, which chooses a
deterministic variant from `data/people_visual_models.json` using the profile's
seed and applies small deterministic proportion jitter.

Do not hand-author static appearances for these enemies unless the test needs
one exact look. They should stay generator-backed so future spawn work proves
the same content path.

## Gameplay Contract

Each test enemy:

- is `kind: "enemy"`
- has `character_profile_id`, `inventory_owner_id`, and `equipment_owner_id`
- equips `item_training_sword` in `right_hand`
- carries one `item_gold_coin`
- has low health for fast death-body testing
- leaves a temporary lootable body through the existing death-body loop
- does not set quest flags or complete quests
- does not represent a canon encounter

## Verification

Coverage lives in:

- `tests/unit/data/test_content_and_quests.gd`
  - all six fixtures load
  - generated profiles resolve with expected `people_id`
  - generated appearances include `visual_model_id`
  - owner IDs, equipment, health, reachable placement, and unique tiles are checked
- `tests/unit/main/test_main_flow.gd`
  - all six spawn with humanoid avatars
  - killing the Tuskfolk fixture creates a lootable generated humanoid body
  - sword and coin transfer through the shared inventory UI

Last verified with:

```text
.\tools\verify_all.cmd
```

## Do Not Build Here

- no full stealth/crime implementation
- no faction encounter generator
- no long-term corpse persistence expansion
- no final art pass
- no AI patrol system
- no canon lore explanation for why all six are standing there

## Future Extension

If this range grows, keep new fixtures generator-backed and keep them away from
quest-critical targets and town NPC routines. A player-facing screenshot can still be added under
`reports/people_enemy_test_area/` when visual review becomes useful.
