# gdlint:disable=max-file-lines,max-public-methods
extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const HumanoidProfile = preload("res://scripts/characters/humanoid_profile.gd")
const QuestManager = preload("res://scripts/managers/quest_manager.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")
const ChunkManager = preload("res://scripts/managers/chunk_manager.gd")
const EntityManager = preload("res://scripts/managers/entity_manager.gd")

const PEOPLE_TEST_ENEMIES := [
	{
		"entity_id": "enemy_people_test_human",
		"profile_id": "char_people_test_human",
		"people_id": "people_human",
		"tile": Vector2i(-16, 0)
	},
	{
		"entity_id": "enemy_people_test_tanglekin",
		"profile_id": "char_people_test_tanglekin",
		"people_id": "people_tanglekin",
		"tile": Vector2i(-18, -2)
	},
	{
		"entity_id": "enemy_people_test_tuskfolk",
		"profile_id": "char_people_test_tuskfolk",
		"people_id": "people_tuskfolk",
		"tile": Vector2i(-18, 2)
	},
	{
		"entity_id": "enemy_people_test_mirefolk",
		"profile_id": "char_people_test_mirefolk",
		"people_id": "people_mirefolk",
		"tile": Vector2i(-20, 0)
	},
	{
		"entity_id": "enemy_people_test_ravenfolk",
		"profile_id": "char_people_test_ravenfolk",
		"people_id": "people_ravenfolk",
		"tile": Vector2i(-23, -2)
	},
	{
		"entity_id": "enemy_people_test_rootborn",
		"profile_id": "char_people_test_rootborn",
		"people_id": "people_rootborn",
		"tile": Vector2i(-22, 2)
	}
]

var content


func before_each() -> void:
	content = ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()


func test_content_database_loads_seed_content() -> void:
	assert_false(content.items.is_empty())
	assert_false(content.quests.is_empty())
	assert_false(content.npcs.is_empty())
	assert_false(content.character_profiles.is_empty())
	assert_false(content.people.is_empty())
	assert_false(content.people_visual_models.is_empty())
	assert_false(content.dialogues.is_empty())
	assert_false(content.locations.is_empty())
	assert_false(content.factions.is_empty())
	assert_false(content.shops.is_empty())
	assert_false(content.status_effects.is_empty())
	assert_false(content.spells.is_empty())
	assert_false(content.world_objects.is_empty())
	assert_false(content.world_terrain.is_empty())
	assert_eq(content.get_item("item_old_toolbox").get("name"), "Old Toolbox")
	assert_eq(content.get_item("item_river_mint").get("type"), "ingredient")
	assert_eq(
		content.get_location("location_briarwatch_crossroads").get("name"), "Briarwatch Crossroads"
	)
	assert_eq(content.get_dialogue("dialogue_harrow_venn").get("id"), "dialogue_harrow_venn")
	assert_eq(content.get_character_profile("char_player").get("character_id"), "char_player")
	assert_eq(content.get_character_profile("char_maera_pike").get("character_id"), "char_maera_pike")
	assert_eq(content.get_people("people_human").get("display_name"), "Human")
	assert_eq(
		content.get_people_visual_model("people_tuskfolk").get("people_id"), "people_tuskfolk"
	)
	assert_eq(content.get_faction("faction_marches_of_velcor").get("name"), "Marches of Velcor")
	assert_eq(content.get_spell("spell_fire_blast").get("name"), "Fire Blast")
	assert_eq(content.get_status_effect("status_road_focus").get("name"), "Road Focus")
	assert_eq(content.validate_all(), [])


func test_all_authored_npcs_and_enemies_are_profile_backed_characters() -> void:
	for npc_id in content.npcs:
		var npc: Dictionary = content.npcs[npc_id]
		var profile_id := String(npc.get("character_profile_id", ""))
		assert_false(profile_id.is_empty(), "%s should have character_profile_id." % npc_id)
		var profile: Dictionary = content.get_character_profile(profile_id)
		assert_eq(profile["character_id"], profile_id)
		assert_eq(profile["inventory_owner_id"], profile_id)
		assert_eq(profile["equipment_owner_id"], profile_id)

	for entry in content.world_objects:
		var kind := String(entry.get("kind", ""))
		if not ["npc", "enemy"].has(kind):
			continue
		var profile_id := String(entry.get("character_profile_id", ""))
		if kind == "npc" and profile_id.is_empty():
			var npc: Dictionary = content.get_npc(String(entry.get("npc_id", "")))
			profile_id = String(npc.get("character_profile_id", ""))
		assert_false(profile_id.is_empty(), "%s should resolve a profile." % entry.get("id", ""))
		assert_eq(String(entry.get("inventory_owner_id", "")), profile_id)
		assert_eq(String(entry.get("equipment_owner_id", "")), profile_id)


func test_people_default_proportions_apply_without_overwriting_authored_values() -> void:
	var tuskfolk: Dictionary = content.get_people("people_tuskfolk")
	assert_eq(tuskfolk.get("body_plans"), ["body_humanoid_short_heavy"])
	assert_eq(content.get_people_default_proportions("people_tuskfolk")["body_height"], 0.76)
	var mirefolk: Dictionary = content.get_people("people_mirefolk")
	assert_eq(mirefolk.get("body_plans"), ["body_humanoid_low_amphibian"])
	assert_eq(content.get_people_default_proportions("people_mirefolk")["body_height"], 0.88)
	for people_id in content.people:
		var definition: Dictionary = content.people[people_id]
		assert_false(
			Dictionary(definition.get("default_proportions", {})).is_empty(),
			"%s should define default proportions." % people_id
		)
		assert_false(
			Array(definition.get("visual_notes", [])).is_empty(),
			"%s should define reusable visual notes." % people_id
		)

	content.character_profiles["char_tuskfolk_test"] = {
		"character_id": "char_tuskfolk_test",
		"people_id": "people_tuskfolk",
		"state": "alive",
		"appearance": {
			"people_id": "people_tuskfolk",
			"body_plan_id": "body_humanoid_short_heavy",
			"head_id": "head_tuskfolk_broad",
			"palette_id": "palette_tuskfolk_umber",
			"proportions": {"head_size": 1.08}
		},
		"inventory_owner_id": "char_tuskfolk_test",
		"equipment_owner_id": "char_tuskfolk_test",
		"spellbook_owner_id": "char_tuskfolk_test"
	}

	var profile: Dictionary = content.get_character_profile("char_tuskfolk_test")
	var proportions: Dictionary = profile["appearance"]["proportions"]

	assert_eq(proportions["body_height"], 0.76)
	assert_eq(proportions["shoulder_width"], 1.34)
	assert_eq(proportions["head_size"], 1.08)


func test_people_visual_models_define_reusable_variant_archetypes() -> void:
	for people_id in content.people:
		var model: Dictionary = content.get_people_visual_model(String(people_id))
		var definition: Dictionary = content.get_people(String(people_id))
		var variants: Array = model.get("variants", [])
		assert_gte(
			variants.size(), 16, "%s should have at least sixteen visual variants." % people_id
		)
		for variant_value in variants:
			var variant: Dictionary = variant_value
			assert_false(String(variant.get("display_name", "")).is_empty())
			assert_true(
				Array(definition.get("palettes", [])).has(String(variant.get("palette_id", "")))
			)
			assert_true(Array(definition.get("heads", [])).has(String(variant.get("head_id", ""))))
			for feature_id in Array(variant.get("feature_ids", [])):
				assert_true(Array(definition.get("features", [])).has(String(feature_id)))
			var deltas: Dictionary = variant.get("proportion_deltas", {})
			for delta_id in deltas:
				assert_true(HumanoidProfile.DEFAULT_PROPORTIONS.has(String(delta_id)))
				assert_true(deltas[delta_id] is int or deltas[delta_id] is float)

	var tuskfolk_model: Dictionary = content.get_people_visual_model("people_tuskfolk")
	for variant_value in tuskfolk_model.get("variants", []):
		var variant: Dictionary = variant_value
		var profile: Dictionary = content.get_people_visual_variant_profile(
			"people_tuskfolk", String(variant.get("id", "")), "preview_%s" % variant.get("id", "")
		)
		var proportions: Dictionary = profile["appearance"]["proportions"]
		var feature_ids: Array = variant.get("feature_ids", [])
		assert_lte(float(proportions["body_height"]), 0.78)
		assert_gte(float(proportions["shoulder_width"]), 1.32)
		assert_gte(float(proportions["waist_width"]), 1.26)
		assert_gte(float(proportions["foot_size"]), 1.20)
		assert_true(
			feature_ids.has("feature_tusks_small") or feature_ids.has("feature_tusks_broad"),
			"%s should keep visible Tuskfolk tusks." % variant.get("id", "")
		)

	var human_model: Dictionary = content.get_people_visual_model("people_human")
	var human_hair_ids := {}
	for variant_value in human_model.get("variants", []):
		var variant: Dictionary = variant_value
		var hair_id := String(variant.get("hair_id", ""))
		assert_false(hair_id.is_empty(), "%s should declare a hair shape." % variant.get("id", ""))
		human_hair_ids[hair_id] = true
	assert_gte(human_hair_ids.size(), 5, "Humans should keep broad hair-shape variety.")

	var ravenfolk_model: Dictionary = content.get_people_visual_model("people_ravenfolk")
	for variant_value in ravenfolk_model.get("variants", []):
		var variant: Dictionary = variant_value
		var feature_ids: Array = variant.get("feature_ids", [])
		var profile: Dictionary = content.get_people_visual_variant_profile(
			"people_ravenfolk", String(variant.get("id", "")), "preview_%s" % variant.get("id", "")
		)
		var proportions: Dictionary = profile["appearance"]["proportions"]
		assert_true(
			feature_ids.has("feature_ravenfolk_body_feathers"),
			"%s should keep visible Ravenfolk body feathers." % variant.get("id", "")
		)
		assert_true(
			feature_ids.has("feature_ravenfolk_beak"),
			"%s should keep the Ravenfolk beak read." % variant.get("id", "")
		)
		assert_lte(float(proportions["shoulder_width"]), 0.86)
		assert_lte(float(proportions["torso_width"]), 0.84)
		assert_lte(float(proportions["waist_width"]), 0.74)

	var tanglekin_model: Dictionary = content.get_people_visual_model("people_tanglekin")
	for variant_value in tanglekin_model.get("variants", []):
		var variant: Dictionary = variant_value
		var feature_ids: Array = variant.get("feature_ids", [])
		var profile: Dictionary = content.get_people_visual_variant_profile(
			"people_tanglekin", String(variant.get("id", "")), "preview_%s" % variant.get("id", "")
		)
		var proportions: Dictionary = profile["appearance"]["proportions"]
		assert_true(
			feature_ids.has("feature_tanglekin_tail"),
			"%s should keep the Tanglekin tail read." % variant.get("id", "")
		)
		assert_true(
			feature_ids.has("feature_tanglekin_muzzle")
			or feature_ids.has("feature_tanglekin_brow_tuft"),
			"%s should keep the Tanglekin simian face read." % variant.get("id", "")
		)
		assert_false(feature_ids.has("feature_tanglekin_motion_cord"))
		assert_false(feature_ids.has("feature_tanglekin_wrap_bands"))
		assert_lte(float(proportions["body_height"]), 1.00)
		assert_lte(float(proportions["shoulder_width"]), 0.92)
		assert_lte(float(proportions["waist_width"]), 0.78)
		assert_gte(float(proportions["hand_size"]), 1.18)
		assert_gte(float(proportions["foot_size"]), 1.12)

	var rootborn_model: Dictionary = content.get_people_visual_model("people_rootborn")
	for variant_value in rootborn_model.get("variants", []):
		var variant: Dictionary = variant_value
		var feature_ids: Array = variant.get("feature_ids", [])
		var profile: Dictionary = content.get_people_visual_variant_profile(
			"people_rootborn", String(variant.get("id", "")), "preview_%s" % variant.get("id", "")
		)
		var proportions: Dictionary = profile["appearance"]["proportions"]
		assert_gte(float(proportions["body_height"]), 1.07)
		assert_gte(float(proportions["foot_size"]), 1.10)
		assert_true(
			feature_ids.has("feature_rootborn_leaf_crown")
			or feature_ids.has("feature_rootborn_bark_marks"),
			"%s should keep Rootborn leaf or bark identity." % variant.get("id", "")
		)
		if feature_ids.has("feature_rootborn_branch_crown"):
			assert_true(
				feature_ids.has("feature_rootborn_leaf_crown")
				or feature_ids.has("feature_rootborn_bark_marks"),
				"%s should keep branch crown tied to bark or leaf identity."
				% variant.get("id", "")
			)

	var mirefolk_model: Dictionary = content.get_people_visual_model("people_mirefolk")
	for variant_value in mirefolk_model.get("variants", []):
		var variant: Dictionary = variant_value
		var feature_ids: Array = variant.get("feature_ids", [])
		var profile: Dictionary = content.get_people_visual_variant_profile(
			"people_mirefolk", String(variant.get("id", "")), "preview_%s" % variant.get("id", "")
		)
		var proportions: Dictionary = profile["appearance"]["proportions"]
		assert_true(
			feature_ids.has("feature_mirefolk_high_eyes")
			or feature_ids.has("feature_mirefolk_webbed_hands"),
			"%s should keep the Mirefolk amphibian read." % variant.get("id", "")
		)
		assert_lte(float(proportions["body_height"]), 0.93)
		assert_lte(float(proportions["shoulder_width"]), 1.02)
		assert_lte(float(proportions["torso_width"]), 0.94)
		assert_lte(float(proportions["waist_width"]), 1.00)
		assert_gte(float(proportions["head_size"]), 1.14)
		assert_gte(float(proportions["foot_size"]), 1.10)


func test_people_visual_variant_composes_preview_profile() -> void:
	var profile: Dictionary = content.get_people_visual_variant_profile(
		"people_tuskfolk", "tuskfolk_smith", "preview_tuskfolk_smith"
	)
	var appearance: Dictionary = profile["appearance"]
	var proportions: Dictionary = appearance["proportions"]

	assert_eq(profile["character_id"], "preview_tuskfolk_smith")
	assert_eq(profile["people_id"], "people_tuskfolk")
	assert_eq(appearance["visual_model_id"], "tuskfolk_smith")
	assert_eq(appearance["palette_id"], "palette_tuskfolk_umber")
	assert_eq(appearance["head_id"], "head_tuskfolk_broad")
	assert_eq(appearance["marking_id"], "marking_hand_wraps")
	assert_eq(appearance["feature_ids"], ["feature_tusks_broad", "feature_tuskfolk_clan_marks"])
	assert_almost_eq(float(proportions["body_height"]), 0.74, 0.001)
	assert_almost_eq(float(proportions["shoulder_width"]), 1.42, 0.001)
	assert_almost_eq(float(proportions["hand_size"]), 1.28, 0.001)

	var human_profile: Dictionary = content.get_people_visual_variant_profile(
		"people_human", "human_orchard_healer", "preview_human_orchard_healer"
	)
	var human_appearance: Dictionary = human_profile["appearance"]
	assert_eq(human_appearance["hair_id"], "hair_wide_curls")
	assert_eq(human_appearance["hair_color_id"], "hair_grey")
	assert_eq(human_appearance["marking_id"], "marking_cheek_dots")


func test_generated_people_appearance_is_deterministic_and_profile_ready() -> void:
	var first: Dictionary = content.get_generated_people_appearance("people_tanglekin", "road_seed")
	var second: Dictionary = content.get_generated_people_appearance("people_tanglekin", "road_seed")
	assert_eq(first, second)
	assert_false(String(first.get("visual_model_id", "")).is_empty())

	var seen_variants := {}
	for seed_index in 32:
		var appearance: Dictionary = content.get_generated_people_appearance(
			"people_tanglekin", "seed_%s" % seed_index
		)
		seen_variants[String(appearance.get("visual_model_id", ""))] = true
	assert_gt(seen_variants.size(), 1)

	for people_id in content.people:
		var profile_id := "char_generated_%s" % String(people_id).replace("people_", "")
		var generated: Dictionary = content.get_generated_people_profile(
			String(people_id), profile_id, "profile_seed", {"proportion_jitter": true}
		)
		var appearance: Dictionary = generated["appearance"]
		assert_eq(generated["character_id"], profile_id)
		assert_eq(generated["people_id"], String(people_id))
		assert_eq(generated["inventory_owner_id"], profile_id)
		assert_eq(generated["equipment_owner_id"], profile_id)
		assert_eq(generated["spellbook_owner_id"], profile_id)
		assert_eq(appearance["people_id"], String(people_id))
		assert_false(String(appearance.get("visual_model_id", "")).is_empty())
		assert_true(appearance.get("feature_ids", []) is Array)
		for proportion_id in HumanoidProfile.DEFAULT_PROPORTIONS:
			var amount := float(Dictionary(appearance["proportions"])[proportion_id])
			assert_gte(amount, HumanoidProfile.MIN_PROPORTION)
			assert_lte(amount, HumanoidProfile.MAX_PROPORTION)


func test_generated_people_appearance_supports_exact_variant_overrides_and_jitter() -> void:
	var exact: Dictionary = content.get_generated_people_appearance(
		"people_tuskfolk", "any_seed", {"variant_id": "tuskfolk_smith"}
	)
	assert_eq(exact["visual_model_id"], "tuskfolk_smith")
	assert_almost_eq(float(Dictionary(exact["proportions"])["body_height"]), 0.74, 0.001)

	var jittered: Dictionary = content.get_generated_people_appearance(
		"people_tuskfolk",
		"jitter_seed",
		{"variant_id": "tuskfolk_smith", "proportion_jitter": true, "jitter_strength": 0.03}
	)
	assert_eq(jittered["visual_model_id"], "tuskfolk_smith")
	var changed := false
	for proportion_id in HumanoidProfile.DEFAULT_PROPORTIONS:
		if not is_equal_approx(
			float(Dictionary(exact["proportions"])[proportion_id]),
			float(Dictionary(jittered["proportions"])[proportion_id])
		):
			changed = true
	assert_true(changed)

	var overridden: Dictionary = content.get_generated_people_appearance(
		"people_tuskfolk",
		"override_seed",
		{
			"variant_id": "tuskfolk_smith",
			"appearance_overrides":
			{
				"palette_id": "palette_tuskfolk_ash",
				"feature_ids": ["feature_tusks_small"],
				"proportions": {"head_size": 1.12}
			}
		}
	)
	assert_eq(overridden["visual_model_id"], "tuskfolk_smith")
	assert_eq(overridden["palette_id"], "palette_tuskfolk_ash")
	assert_eq(overridden["feature_ids"], ["feature_tusks_small"])
	assert_almost_eq(float(Dictionary(overridden["proportions"])["head_size"]), 1.12, 0.001)


func test_character_profile_appearance_generation_resolves_with_authored_overrides() -> void:
	content.character_profiles["char_generated_tuskfolk"] = {
		"character_id": "char_generated_tuskfolk",
		"people_id": "people_tuskfolk",
		"state": "alive",
		"appearance_generation":
		{
			"seed": "blacksmith_enemy_seed",
			"variant_id": "tuskfolk_smith",
			"appearance_overrides": {"marking_id": "marking_chest_band"}
		},
		"appearance":
		{
			"palette_id": "palette_tuskfolk_ash",
			"proportions": {"head_size": 1.11}
		},
		"inventory_owner_id": "char_generated_tuskfolk",
		"equipment_owner_id": "char_generated_tuskfolk",
		"spellbook_owner_id": "char_generated_tuskfolk"
	}

	var profile: Dictionary = content.get_character_profile("char_generated_tuskfolk")
	var appearance: Dictionary = profile["appearance"]
	assert_eq(profile["people_id"], "people_tuskfolk")
	assert_eq(profile["derived_bonuses"], {})
	assert_eq(appearance["people_id"], "people_tuskfolk")
	assert_eq(appearance["visual_model_id"], "tuskfolk_smith")
	assert_eq(appearance["head_id"], "head_tuskfolk_broad")
	assert_eq(appearance["marking_id"], "marking_chest_band")
	assert_eq(appearance["palette_id"], "palette_tuskfolk_ash")
	assert_almost_eq(float(Dictionary(appearance["proportions"])["head_size"]), 1.11, 0.001)


func test_people_test_enemies_use_generated_profiles() -> void:
	var seen_tiles := {}
	for data in PEOPLE_TEST_ENEMIES:
		var entity_id := String(data["entity_id"])
		var profile_id := String(data["profile_id"])
		var people_id := String(data["people_id"])
		var expected_tile: Vector2i = data["tile"]
		var world_entry := _world_object(entity_id)
		var profile: Dictionary = content.get_character_profile(profile_id)
		var appearance: Dictionary = profile["appearance"]
		var tile_array: Array = world_entry.get("global_tile", [])
		var tile := Vector2i(int(tile_array[0]), int(tile_array[1]))

		assert_eq(world_entry.get("kind"), "enemy")
		assert_eq(world_entry.get("character_profile_id"), profile_id)
		assert_eq(world_entry.get("inventory_owner_id"), profile_id)
		assert_eq(world_entry.get("equipment_owner_id"), profile_id)
		assert_eq(tile, expected_tile)
		assert_false(seen_tiles.has(GridMath.tile_key(tile)))
		seen_tiles[GridMath.tile_key(tile)] = true
		assert_eq(profile["people_id"], people_id)
		assert_eq(profile["inventory_owner_id"], profile_id)
		assert_eq(profile["equipment_owner_id"], profile_id)
		assert_eq(profile["spellbook_owner_id"], profile_id)
		assert_eq(appearance["people_id"], people_id)
		assert_false(String(appearance.get("visual_model_id", "")).is_empty())
		assert_true(world_entry.get("equipped_items", {}).has("right_hand"))
		assert_eq(int(world_entry.get("max_health")), 6)
		assert_eq(int(world_entry.get("damage_taken_per_hit")), 6)


func test_content_validation_reports_appearance_generation_errors() -> void:
	var broken := ContentDatabase.new()
	add_child_autofree(broken)
	broken.people = content.people.duplicate(true)
	broken.people_visual_models = content.people_visual_models.duplicate(true)
	broken.character_profiles = {
		"char_bad_generation":
		{
			"character_id": "char_bad_generation",
			"people_id": "people_tuskfolk",
			"state": "alive",
			"appearance_generation": "bad",
			"inventory_owner_id": "char_bad_generation",
			"equipment_owner_id": "char_bad_generation",
			"spellbook_owner_id": "char_bad_generation"
		},
		"char_missing_variant":
		{
			"character_id": "char_missing_variant",
			"people_id": "people_tuskfolk",
			"state": "alive",
			"appearance_generation": {"variant_id": "missing_tuskfolk_variant"},
			"inventory_owner_id": "char_missing_variant",
			"equipment_owner_id": "char_missing_variant",
			"spellbook_owner_id": "char_missing_variant"
		},
		"char_malformed_generation":
		{
			"character_id": "char_malformed_generation",
			"people_id": "people_tuskfolk",
			"state": "alive",
			"appearance_generation":
			{
				"seed": 7,
				"proportion_jitter": "yes",
				"jitter_strength": "much",
				"appearance_overrides": "bad"
			},
			"inventory_owner_id": "char_malformed_generation",
			"equipment_owner_id": "char_malformed_generation",
			"spellbook_owner_id": "char_malformed_generation"
		}
	}

	var joined := "\n".join(broken.validate_all())

	assert_true(joined.contains("appearance_generation must be a dictionary"))
	assert_true(joined.contains("references missing variant missing_tuskfolk_variant"))
	assert_true(joined.contains("seed must be a string"))
	assert_true(joined.contains("proportion_jitter must be a boolean"))
	assert_true(joined.contains("jitter_strength must be numeric"))
	assert_true(joined.contains("appearance_overrides must be a dictionary"))


func test_people_bonuses_apply_to_player_and_npc_profiles() -> void:
	var player_profile: Dictionary = content.get_character_profile("char_player")
	var harrow_profile: Dictionary = content.get_character_profile("char_harrow_venn")

	assert_eq(player_profile["stats"], {})
	assert_eq(harrow_profile["stats"], {})
	assert_eq(player_profile["derived_bonuses"], {"resolve": 1.0})
	assert_eq(harrow_profile["derived_bonuses"], {"resolve": 1.0})


func test_seed_equipment_items_declare_avatar_visuals_or_placeholders() -> void:
	for item_id in content.items:
		var item: Dictionary = content.items[item_id]
		if not item.has("equipment_slot"):
			continue
		var visual: Dictionary = item.get("avatar_visual", {})
		assert_false(visual.is_empty(), "%s should declare avatar_visual." % item_id)
		assert_false(
			String(visual.get("avatar_slot", "")).is_empty(),
			"%s should declare avatar_slot." % item_id
		)
		assert_false(
			String(visual.get("visual_layer_id", "")).is_empty(),
			"%s should declare visual_layer_id." % item_id
		)
		assert_true(
			bool(visual.get("accepted_placeholder", false))
			or not String(visual.get("paperdoll_sprite_id", "")).is_empty(),
			"%s should declare a drawable layer or accepted placeholder." % item_id
		)


func test_content_validation_reports_missing_references() -> void:
	var broken := ContentDatabase.new()
	add_child_autofree(broken)
	broken.items = {}
	broken.readables = {}
	broken.quests = {
		"quest_bad":
		{
			"id": "quest_bad",
			"start_stage": "missing",
			"stages": {},
			"rewards":
			[
				{"type": "add_item", "item_id": "missing_item", "count": 1},
				{"type": "apply_status", "status_id": "missing_status"},
				{"type": "change_reputation", "faction_id": "missing_faction", "amount": 1},
				{"type": "advance_time"}
			]
		}
	}
	broken.npcs = {
		"npc_bad":
		{
			"id": "npc_bad",
			"quest_id": "missing_quest",
			"dialogue_id": "missing_dialogue",
			"faction": "missing_faction",
			"shop_id": "missing_shop",
			"completion_conditions":
			[
				{"type": "has_item", "item_id": "missing_item", "count": 1},
				{"type": "quest_state", "quest_id": "missing_quest", "state": "active"},
				{"type": "quest_state", "quest_id": "missing_quest", "state": "failed"},
				{"type": "read_readable", "readable_id": "missing_readable"},
				{"type": "location_discovered", "location_id": "missing_location"},
				{
					"type": "faction_reputation_at_least",
					"faction_id": "missing_faction",
					"reputation": 1
				},
				{"type": "time_phase", "phase": "Dawn"},
				{"type": "time_hour_between", "start_hour": "late", "end_hour": 24}
			]
		}
	}
	broken.world_objects = [
		{"id": "object_bad", "kind": "readable", "global_tile": [0, 0], "readable_id": "missing"},
		{
			"id": "object_bad",
			"kind": "enemy",
			"global_tile": [1, 0],
			"max_health": 0,
			"damage_taken_per_hit": 0,
			"attack_damage": -1
		},
		{
			"id": "location_bad",
			"kind": "location",
			"global_tile": [0, 1],
			"location_id": "missing_location"
		}
	]
	broken.shops = {
		"shop_bad":
		{"id": "shop_bad", "name": "", "stock": [{"item_id": "missing_item", "price": 0}, "bad"]}
	}

	var errors := broken.validate_all()

	assert_gt(errors.size(), 0)
	assert_true(", ".join(errors).contains("missing"))
	assert_true(", ".join(errors).contains("Duplicate world object id"))
	assert_true(", ".join(errors).contains("positive damage_taken_per_hit"))
	assert_true(", ".join(errors).contains("Shop shop_bad is missing name"))
	assert_true(", ".join(errors).contains("Shop shop_bad references missing item"))
	assert_true(", ".join(errors).contains("malformed stock entry"))


func test_content_validation_reports_authoring_contract_errors() -> void:
	var broken := ContentDatabase.new()
	add_child_autofree(broken)
	broken.items = {
		"item_bad":
		{
			"id": "item_other",
			"name": "",
			"max_stack": 0,
			"value": -1,
			"effects_on_use":
			[
				{"type": "heal_player", "amount": 0},
				{"type": "heal_player", "amount": "many"},
				{"type": "advance_time"},
				"bad"
			]
		},
		"item_bad_numeric":
		{
			"id": "item_bad_numeric",
			"name": "Bad",
			"type": "weapon",
			"max_stack": "many",
			"value": "free",
			"equipment_slot": "hands",
			"damage_bonus": "heavy",
			"guard_counter_multiplier": 0,
			"weapon_attack": {"attack_interval_seconds": 0}
		}
	}
	broken.readables = {
		"readable_bad":
		{
			"id": "readable_other",
			"title": "",
			"body": "",
			"effects_on_read":
			[
				{"type": "add_item", "item_id": "item_bad", "count": 0},
				{"type": "add_item", "item_id": "item_bad", "count": "two"},
				"bad"
			]
		}
	}
	broken.quests = {
		"quest_bad":
		{
			"id": "",
			"title": "",
			"start_stage": "started",
			"stages":
			{
				"started": {},
				"bad_stage": "bad",
				"empty_objective":
				{
					"objectives":
					{
						"": "",
						"blank_text": "",
						"missing_target": {"text": "Go nowhere.", "target_id": "missing_object"}
					}
				}
			},
			"rewards": ["bad", {"type": "add_experience", "amount": 0}]
		}
	}
	broken.factions = {
		"faction_bad":
		{"id": "faction_other", "name": "", "description": "", "starting_reputation": "loved"},
		"faction_bad_range":
		{
			"id": "faction_bad_range",
			"name": "Range",
			"description": "Too high.",
			"starting_reputation": 200
		}
	}
	broken.npcs = {
		"npc_bad":
		{
			"id": "npc_other",
			"name": "",
			"quest_id": "quest_bad",
			"dialogue_id": "dialogue_bad",
			"completion_conditions":
			[
				{"type": "has_flag", "flag_id": ""},
				{"type": "has_item", "item_id": "item_bad", "count": 0},
				{"type": "has_item", "item_id": "item_bad", "count": "many"},
				{"type": "quest_state", "quest_id": "quest_bad", "state": "wrong"},
				{
					"type": "faction_reputation_at_least",
					"faction_id": "faction_bad",
					"reputation": "high"
				},
				{"type": "player_level_at_least", "level": "high"},
				{"type": "time_phase", "phase": "Dawn"},
				{"type": "time_hour_between", "start_hour": "late", "end_hour": 24},
				{"type": "unknown_condition"},
				"bad"
			],
			"completion_effects":
			[
				{"type": "change_reputation", "faction_id": "faction_bad", "amount": "much"},
				{"type": "add_experience", "amount": "much"},
				{"type": "apply_status", "status_id": "status_bad", "charges": "many"},
				"bad"
			]
		}
	}
	broken.dialogues = {
		"dialogue_bad":
		{
			"id": "dialogue_other",
			"lines":
			[
				{
					"id": "",
					"speaker": "",
					"text": "",
					"conditions": ["bad"],
					"effects": ["bad"],
					"choices":
					[
						{"id": "", "text": "", "conditions": ["bad"], "effects": ["bad"]},
						{"id": "", "text": "Duplicate blank."},
						"bad"
					]
				},
				{"id": "", "speaker": "Again", "text": "Duplicate blank."}
			]
		}
	}
	broken.locations = {
		"location_bad": {"id": "location_other", "name": "", "region": "", "description": ""}
	}
	broken.shops = {
		"shop_bad": {"id": "shop_other", "name": "", "stock": []},
		"shop_bad_numeric":
		{
			"id": "shop_bad_numeric",
			"name": "Bad Shop",
			"open_hour": "dawn",
			"close_hour": 24,
			"stock": [{"item_id": "item_bad", "price": "free"}]
		}
	}
	broken.status_effects = {
		"status_bad":
		{
			"id": "status_other",
			"name": "",
			"description": "",
			"attack_charges": "many",
			"damage_bonus": -1,
			"guard_counter_multiplier": 0
		}
	}
	broken.world_objects = [
		{
			"id": "object_bad",
			"name": "",
			"kind": "pickup",
			"global_tile": [0],
			"item_id": "item_bad",
			"effects_on_pickup": ["bad"],
			"effects_on_defeat": ["bad"]
		},
		{
			"id": "object_bad_tile",
			"name": "Bad Tile",
			"kind": "pickup",
			"global_tile": ["x", 0],
			"item_id": "item_bad",
			"count": 0
		},
		{
			"id": "enemy_bad_numeric",
			"name": "Bad Enemy",
			"kind": "enemy",
			"global_tile": [1, 0],
			"max_health": "twelve",
			"damage_taken_per_hit": "six",
			"attack_damage": "four"
		},
		{
			"id": "location_bad_numeric",
			"name": "Bad Location",
			"kind": "location",
			"global_tile": [0, 1],
			"location_id": "location_bad",
			"discovery_radius": "near"
		},
		{
			"id": "container_bad",
			"name": "Bad Container",
			"kind": "container",
			"global_tile": [1, 1],
			"effects_on_open": []
		},
		{
			"id": "container_bad_effect",
			"name": "Bad Container Effect",
			"kind": "container",
			"global_tile": [2, 2],
			"effects_on_open": ["bad"]
		},
		{
			"id": "container_bad_open_condition",
			"name": "Bad Open Condition Container",
			"kind": "container",
			"global_tile": [2, 3],
			"interaction_radius": "far",
			"open_conditions": ["bad"],
			"effects_on_open": [{"type": "add_item", "item_id": "item_gold_coin", "count": 1}]
		},
		{
			"id": "door_bad_effect",
			"name": "Bad Door",
			"kind": "door",
			"global_tile": [3, 2],
			"effects_on_open": ["bad"]
		},
		{
			"id": "rest_bad_numeric",
			"name": "Bad Rest",
			"kind": "rest",
			"global_tile": [3, 3],
			"heal_amount": 5,
			"conditions": ["bad"],
			"rest_hours": "late"
		},
		{
			"id": "poi_bad",
			"name": "Bad POI",
			"kind": "poi",
			"global_tile": [4, 3],
			"location_id": "location_missing",
			"shop_id": "shop_missing",
			"system_tab": "crafting",
			"actions":
			[
				{"id": "", "text": "", "conditions": ["bad"], "effects": ["bad"]},
				{"id": "", "text": "Duplicate blank."},
				"bad"
			],
			"effects_on_discover": ["bad"]
		},
		{
			"id": "poi_trade_without_shop",
			"name": "Bad Trade POI",
			"kind": "poi",
			"global_tile": [5, 3],
			"description": "Trade tab is missing its shop.",
			"system_tab": "trade"
		}
	]

	var joined := "\n".join(broken.validate_all())

	assert_true(joined.contains("mismatched id"))
	assert_true(joined.contains("missing name"))
	assert_true(joined.contains("missing title"))
	assert_true(joined.contains("missing body"))
	assert_true(joined.contains("missing speaker"))
	assert_true(joined.contains("missing text"))
	assert_true(joined.contains("must have at least one objective"))
	assert_true(joined.contains("must be a dictionary"))
	assert_true(joined.contains("objective with missing id"))
	assert_true(joined.contains("objective blank_text is missing text"))
	assert_true(
		joined.contains("objective missing_target references missing target missing_object")
	)
	assert_true(joined.contains("malformed condition"))
	assert_true(joined.contains("malformed effect"))
	assert_true(joined.contains("missing region"))
	assert_true(joined.contains("missing description"))
	assert_true(joined.contains("Shop shop_bad has mismatched id"))
	assert_true(joined.contains("Shop shop_bad is missing name"))
	assert_true(joined.contains("Shop shop_bad must have stock"))
	assert_true(joined.contains("Shop shop_bad_numeric open_hour must be numeric"))
	assert_true(joined.contains("Shop shop_bad_numeric close_hour must be between"))
	assert_true(joined.contains("Shop shop_bad_numeric stock item_bad price must be numeric"))
	assert_true(joined.contains("Status effect status_bad has mismatched id"))
	assert_true(joined.contains("Status effect status_bad is missing name"))
	assert_true(joined.contains("Status effect status_bad is missing description"))
	assert_true(joined.contains("Status effect status_bad attack_charges must be numeric"))
	assert_true(joined.contains("Status effect status_bad must have non-negative damage_bonus"))
	assert_true(
		joined.contains("Status effect status_bad has non-positive guard_counter_multiplier")
	)
	assert_true(joined.contains("Faction faction_bad has mismatched id"))
	assert_true(joined.contains("Faction faction_bad is missing name"))
	assert_true(joined.contains("Faction faction_bad starting_reputation must be numeric"))
	assert_true(joined.contains("Faction faction_bad_range starting_reputation must be between"))
	assert_true(joined.contains("positive max_stack"))
	assert_true(joined.contains("non-negative value"))
	assert_true(joined.contains("non-positive count"))
	assert_true(joined.contains("missing flag_id"))
	assert_true(joined.contains("invalid state"))
	assert_true(joined.contains("reputation must be numeric"))
	assert_true(joined.contains("level must be numeric"))
	assert_true(joined.contains("invalid phase Dawn"))
	assert_true(joined.contains("start_hour must be numeric"))
	assert_true(joined.contains("end_hour must be between"))
	assert_true(joined.contains("change_reputation amount must be numeric"))
	assert_true(joined.contains("add_experience amount must be numeric"))
	assert_true(joined.contains("apply_status charges must be numeric"))
	assert_true(joined.contains("advance_time requires minutes or hours"))
	assert_true(joined.contains("unsupported condition type"))
	assert_true(joined.contains("must have effects or response"))
	assert_true(joined.contains("trade system_tab without shop_id"))
	assert_true(joined.contains("global_tile"))
	assert_true(joined.contains("global_tile values must be numeric"))
	assert_true(joined.contains("positive count"))
	assert_true(joined.contains("readable readable_bad effects_on_read has malformed effect"))
	assert_true(joined.contains("Item item_bad_numeric max_stack must be numeric"))
	assert_true(joined.contains("Item item_bad_numeric value must be numeric"))
	assert_true(joined.contains("unsupported equipment_slot"))
	assert_true(joined.contains("Item item_bad_numeric damage_bonus must be numeric"))
	assert_true(joined.contains("non-positive guard_counter_multiplier"))
	assert_true(joined.contains("weapon_attack must have positive attack_interval_seconds"))
	assert_true(joined.contains("item item_bad effects_on_use has malformed effect"))
	assert_true(joined.contains("item item_bad effects_on_use heal_player amount must be numeric"))
	assert_true(joined.contains("count must be numeric"))
	assert_true(joined.contains("Enemy enemy_bad_numeric max_health must be numeric"))
	assert_true(joined.contains("Enemy enemy_bad_numeric damage_taken_per_hit must be numeric"))
	assert_true(joined.contains("Enemy enemy_bad_numeric attack_damage must be numeric"))
	assert_true(joined.contains("World object enemy_bad_numeric is missing character_profile_id"))
	assert_true(joined.contains("World object enemy_bad_numeric is missing inventory_owner_id"))
	assert_true(joined.contains("World object enemy_bad_numeric is missing equipment_owner_id"))
	assert_true(
		joined.contains("Location object location_bad_numeric discovery_radius must be numeric")
	)
	assert_true(joined.contains("quest quest_bad rewards has malformed effect"))
	assert_true(joined.contains("quest quest_bad rewards add_experience must have positive amount"))
	assert_true(joined.contains("NPC npc_bad completion_conditions has malformed condition"))
	assert_true(joined.contains("NPC npc_bad completion_effects has malformed effect"))
	assert_true(joined.contains("NPC npc_bad is missing character_profile_id"))
	assert_true(joined.contains("choices has malformed choice"))
	assert_true(joined.contains("choice  is missing text"))
	assert_true(joined.contains("world object object_bad effects_on_pickup has malformed effect"))
	assert_true(joined.contains("world object object_bad effects_on_defeat has malformed effect"))
	assert_true(joined.contains("world object rest_bad_numeric conditions has malformed condition"))
	assert_true(joined.contains("Container container_bad must have effects_on_open"))
	assert_true(
		joined.contains("world object container_bad_effect effects_on_open has malformed effect")
	)
	assert_true(
		joined.contains(
			"world object container_bad_open_condition open_conditions has malformed condition"
		)
	)
	assert_true(
		joined.contains(
			"World object container_bad_open_condition interaction_radius must be numeric"
		)
	)
	assert_true(
		joined.contains("world object door_bad_effect effects_on_open has malformed effect")
	)
	assert_true(joined.contains("Rest object rest_bad_numeric rest_hours must be numeric"))
	assert_true(joined.contains("POI poi_bad is missing description"))
	assert_true(joined.contains("POI poi_bad references missing location location_missing"))
	assert_true(joined.contains("POI poi_bad references missing shop shop_missing"))
	assert_true(joined.contains("POI poi_bad has unsupported system_tab crafting"))
	assert_true(joined.contains("POI poi_bad actions has action with missing id"))
	assert_true(joined.contains("POI poi_bad actions action  is missing text"))
	assert_true(joined.contains("POI poi_bad actions action  conditions has malformed condition"))
	assert_true(joined.contains("POI poi_bad actions action  effects has malformed effect"))
	assert_true(joined.contains("POI poi_bad actions has malformed action"))
	assert_true(joined.contains("world object poi_bad effects_on_discover has malformed effect"))


func test_seed_system_fixtures_are_testable_near_spawn() -> void:
	var spawn_world := (
		GridMath.tile_to_world(Vector2i.ZERO) + Vector2.ONE * GridMath.TILE_SIZE * 0.5
	)
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	chunks.load_authored_terrain(ChunkManager.AUTHORED_TERRAIN_PATH)
	var expected_ids := [
		"object_road_notice",
		"npc_harrow_venn_world",
		"npc_maera_pike_world",
		"poi_briarwatch_square",
		"poi_harrow_forge",
		"poi_maera_stall",
		"pickup_old_toolbox",
		"pickup_roadside_draught",
		"pickup_road_hatchet",
		"pickup_training_sword",
		"pickup_test_polearm",
		"pickup_hunting_bow",
		"pickup_traveler_buckler",
		"object_road_cache",
		"object_warden_cache",
		"object_sealed_strongbox",
		"enemy_road_thug",
		"enemy_test_raider",
		"object_north_gate",
		"object_training_gate",
		"object_roadside_campfire",
		"location_briarwatch_crossroads_marker"
	]
	var found_ids := []
	var occupied_tiles := {}

	for entry in content.world_objects:
		var entity_id := String(entry.get("id", ""))
		if not expected_ids.has(entity_id):
			continue
		var tile_array: Array = entry.get("global_tile", [0, 0])
		var tile := Vector2i(int(tile_array[0]), int(tile_array[1]))
		var tile_key := GridMath.tile_key(tile)
		var world_position := GridMath.tile_to_world(tile) + Vector2.ONE * GridMath.TILE_SIZE * 0.5
		var distance_from_spawn := spawn_world.distance_to(world_position)
		if String(entry.get("kind", "")) != "location":
			assert_false(
				occupied_tiles.has(tile_key), "%s should not share a spawn test tile." % entity_id
			)
			occupied_tiles[tile_key] = true
		assert_true(
			_has_walkable_path(chunks, Vector2i.ZERO, tile, 12),
			"%s should be walkably reachable from spawn." % entity_id
		)
		if String(entry.get("kind", "")) == "location":
			assert_lte(distance_from_spawn, float(entry.get("discovery_radius", 42.0)))
		else:
			assert_true(chunks.is_walkable(tile), "%s should not sit on blocked terrain." % entity_id)
			assert_lte(
				distance_from_spawn / GridMath.TILE_SIZE,
				11.0,
				"%s should stay near spawn, but not be interactable from spawn." % entity_id
			)
		found_ids.append(entity_id)

	found_ids.sort()
	expected_ids.sort()
	assert_eq(found_ids, expected_ids)


func test_people_enemy_range_stays_outside_town_but_reachable() -> void:
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	chunks.load_authored_terrain(ChunkManager.AUTHORED_TERRAIN_PATH)
	var town_bounds := Rect2i(Vector2i(-12, -10), Vector2i(27, 21))
	var seen_tiles := {}

	for data in PEOPLE_TEST_ENEMIES:
		var entity_id := String(data["entity_id"])
		var entry := _world_object(entity_id)
		var tile_array: Array = entry.get("global_tile", [0, 0])
		var tile := Vector2i(int(tile_array[0]), int(tile_array[1]))
		var tile_key := GridMath.tile_key(tile)

		assert_eq(tile, data["tile"])
		assert_false(town_bounds.has_point(tile), "%s should stay outside Briarwatch." % entity_id)
		assert_false(seen_tiles.has(tile_key), "%s should not share a test tile." % entity_id)
		seen_tiles[tile_key] = true
		assert_true(chunks.is_walkable(tile), "%s should not sit on blocked terrain." % entity_id)
		assert_true(
			_has_walkable_path(chunks, Vector2i.ZERO, tile, 32),
			"%s should remain reachable from spawn through the west gate." % entity_id
		)


func test_quest_lifecycle() -> void:
	var quests := QuestManager.new()
	add_child_autofree(quests)
	quests.setup(null, content)
	assert_true(quests.start_quest("quest_missing_tools"))
	assert_eq(quests.get_quest_state("quest_missing_tools"), "active")
	assert_eq(quests.quests["quest_missing_tools"]["stage"], "started")
	assert_false(quests.start_quest("quest_missing_tools"))
	assert_true(quests.set_stage("quest_missing_tools", "found_toolbox"))
	assert_eq(quests.quests["quest_missing_tools"]["stage"], "found_toolbox")
	assert_false(quests.set_stage("quest_missing_tools", "missing_stage"))
	assert_eq(quests.quests["quest_missing_tools"]["stage"], "found_toolbox")
	assert_true(quests.complete_quest("quest_missing_tools"))
	assert_eq(quests.get_quest_state("quest_missing_tools"), "completed")
	assert_false(quests.complete_quest("quest_missing_tools"))
	assert_false(quests.fail_quest("quest_missing_tools"))
	assert_false(quests.set_stage("quest_missing_tools", "started"))

	var failed := QuestManager.new()
	add_child_autofree(failed)
	failed.setup(null, content)
	assert_true(failed.fail_quest("quest_missing_tools"))
	assert_eq(failed.get_quest_state("quest_missing_tools"), "failed")
	assert_eq(failed.quests["quest_missing_tools"]["stage"], "failed")
	assert_eq(failed.quests["quest_missing_tools"]["objectives"], {})
	assert_false(failed.fail_quest("quest_missing_tools"))
	assert_false(failed.complete_quest("quest_missing_tools"))
	assert_false(failed.set_stage("quest_missing_tools", "started"))
	assert_true(failed.get_active_summary()[0].contains("failed"))


func test_quest_set_stage_starts_valid_inactive_quest_only() -> void:
	var quests := QuestManager.new()
	add_child_autofree(quests)
	quests.setup(null, content)

	assert_true(quests.set_stage("quest_missing_tools", "found_toolbox"))
	assert_eq(quests.get_quest_state("quest_missing_tools"), "active")
	assert_eq(quests.quests["quest_missing_tools"]["stage"], "found_toolbox")

	var invalid := QuestManager.new()
	add_child_autofree(invalid)
	invalid.setup(null, content)
	assert_false(invalid.set_stage("quest_missing_tools", "missing_stage"))
	assert_eq(invalid.get_quest_state("quest_missing_tools"), "inactive")


func test_quest_stage_objectives_ignore_malformed_definition_data() -> void:
	content.quests["quest_malformed_objectives"] = {
		"id": "quest_malformed_objectives",
		"title": "Malformed Objectives",
		"start_stage": "started",
		"stages":
		{
			"started":
			{"objectives": {"valid": "Keep the valid objective.", "blank": "", "": "No id."}},
			"bad_stage": "bad"
		}
	}
	var quests := QuestManager.new()
	add_child_autofree(quests)
	quests.setup(null, content)

	assert_true(quests.start_quest("quest_malformed_objectives"))
	assert_eq(
		quests.quests["quest_malformed_objectives"]["objectives"],
		{"valid": "Keep the valid objective."}
	)
	assert_true(quests.set_stage("quest_malformed_objectives", "bad_stage"))
	assert_eq(quests.quests["quest_malformed_objectives"]["objectives"], {})


func test_quest_load_sanitizes_unknown_states_and_regenerates_objectives() -> void:
	var quests := QuestManager.new()
	add_child_autofree(quests)
	quests.setup(null, content)

	quests.load_save_data(
		{
			"quest_missing_tools":
			{
				"state": "active",
				"stage": "missing_stage",
				"objectives": {"fake": "This should be replaced."}
			},
			"quest_unknown": {"state": "active", "stage": "started"},
			"quest_bad_state": {"state": "nonsense", "stage": "started"},
			"": {"state": "active", "stage": "started"}
		}
	)

	assert_eq(quests.quests.keys(), ["quest_missing_tools"])
	assert_eq(quests.quests["quest_missing_tools"]["state"], "active")
	assert_eq(quests.quests["quest_missing_tools"]["stage"], "started")
	assert_eq(
		quests.quests["quest_missing_tools"]["objectives"],
		{
			"find_toolbox":
			{"text": "Find Harrow's old toolbox by the west road.", "target_id": "pickup_old_toolbox"}
		}
	)


func test_quest_load_preserves_completed_known_quest_as_complete() -> void:
	var quests := QuestManager.new()
	add_child_autofree(quests)
	quests.setup(null, content)

	quests.load_save_data({"quest_missing_tools": {"state": "completed", "stage": "bad"}})

	assert_eq(quests.get_quest_state("quest_missing_tools"), "completed")
	assert_eq(quests.quests["quest_missing_tools"]["stage"], "completed")
	assert_eq(quests.quests["quest_missing_tools"]["objectives"], {})


func test_quest_load_preserves_failed_known_quest_as_failed() -> void:
	var quests := QuestManager.new()
	add_child_autofree(quests)
	quests.setup(null, content)

	quests.load_save_data({"quest_missing_tools": {"state": "failed", "stage": "started"}})

	assert_eq(quests.get_quest_state("quest_missing_tools"), "failed")
	assert_eq(quests.quests["quest_missing_tools"]["stage"], "failed")
	assert_eq(quests.quests["quest_missing_tools"]["objectives"], {})


func test_quest_live_state_sanitizes_malformed_entries_for_summary_and_save() -> void:
	var quests := QuestManager.new()
	add_child_autofree(quests)
	quests.setup(null, content)
	quests.quests = {
		"quest_missing_tools": "bad",
		"quest_unknown": {"state": "completed"},
		"": {"state": "active", "stage": "started"},
		"quest_bad_state": {"state": "nonsense", "stage": "started"}
	}

	assert_eq(quests.get_quest_state("quest_missing_tools"), "inactive")
	assert_eq(quests.get_active_summary(), [])
	assert_eq(quests.get_save_data(), {})
	assert_true(quests.set_stage("quest_missing_tools", "found_toolbox"))
	assert_eq(quests.quests["quest_missing_tools"]["state"], "active")
	assert_eq(quests.quests["quest_missing_tools"]["stage"], "found_toolbox")
	assert_eq(quests.get_active_objectives_data()[0]["target_id"], "npc_harrow_venn_world")


func test_quest_summary_and_save_regenerate_malformed_live_active_state() -> void:
	var quests := QuestManager.new()
	add_child_autofree(quests)
	quests.setup(null, content)
	quests.quests = {
		"quest_missing_tools": {"state": "active", "stage": "missing_stage", "objectives": "bad"}
	}

	assert_eq(
		quests.get_active_summary(), ["The Missing Tools: Find Harrow's old toolbox by the west road."]
	)
	assert_eq(
		quests.get_save_data(),
		{
			"quest_missing_tools":
			{
				"state": "active",
				"stage": "started",
				"objectives":
				{
					"find_toolbox":
					{
						"text": "Find Harrow's old toolbox by the west road.",
						"target_id": "pickup_old_toolbox"
					}
				}
			}
		}
	)

	quests.quests["quest_missing_tools"] = {
		"state": "completed", "stage": "bad", "objectives": "bad"
	}

	assert_eq(quests.get_active_summary(), ["The Missing Tools: complete"])
	assert_eq(
		quests.get_save_data(),
		{"quest_missing_tools": {"state": "completed", "stage": "completed", "objectives": {}}}
	)


func _has_walkable_path(chunks, start: Vector2i, target: Vector2i, max_steps: int) -> bool:
	if start == target:
		return true
	var frontier: Array[Dictionary] = [{"tile": start, "steps": 0}]
	var visited := {GridMath.tile_key(start): true}
	var directions := [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	while not frontier.is_empty():
		var current: Dictionary = frontier.pop_front()
		var steps := int(current["steps"])
		if steps >= max_steps:
			continue
		for direction in directions:
			var next_tile: Vector2i = current["tile"] + direction
			var next_key := GridMath.tile_key(next_tile)
			if visited.has(next_key) or not chunks.is_walkable(next_tile):
				continue
			if next_tile == target:
				return true
			visited[next_key] = true
			frontier.append({"tile": next_tile, "steps": steps + 1})
	return false


func _world_object(entity_id: String) -> Dictionary:
	for entry in content.world_objects:
		if String(entry.get("id", "")) == entity_id:
			return entry
	return {}
