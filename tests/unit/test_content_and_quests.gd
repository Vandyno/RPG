extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const QuestManager = preload("res://scripts/managers/quest_manager.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")
const ChunkManager = preload("res://scripts/managers/chunk_manager.gd")
const EntityManager = preload("res://scripts/managers/entity_manager.gd")

var content


func before_each() -> void:
	content = ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()


func test_content_database_loads_seed_content() -> void:
	assert_false(content.items.is_empty())
	assert_false(content.quests.is_empty())
	assert_false(content.npcs.is_empty())
	assert_false(content.dialogues.is_empty())
	assert_false(content.locations.is_empty())
	assert_false(content.factions.is_empty())
	assert_false(content.shops.is_empty())
	assert_false(content.status_effects.is_empty())
	assert_false(content.world_objects.is_empty())
	assert_eq(content.get_item("item_old_toolbox").get("name"), "Old Toolbox")
	assert_eq(
		content.get_location("location_briarwatch_crossroads").get("name"), "Briarwatch Crossroads"
	)
	assert_eq(content.get_dialogue("dialogue_harrow_venn").get("id"), "dialogue_harrow_venn")
	assert_eq(content.get_faction("faction_marches_of_velcor").get("name"), "Marches of Velcor")
	assert_eq(content.get_status_effect("status_road_focus").get("name"), "Road Focus")
	assert_eq(content.validate_all(), [])


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
			"max_stack": "many",
			"value": "free",
			"equipment_slot": "hands",
			"damage_bonus": "heavy",
			"guard_counter_multiplier": 0
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
				{"type": "stat_at_least", "stat_id": "", "rank": "strong"},
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
	assert_true(joined.contains("missing stat_id"))
	assert_true(joined.contains("rank must be numeric"))
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
	assert_true(joined.contains("item item_bad effects_on_use has malformed effect"))
	assert_true(joined.contains("item item_bad effects_on_use heal_player amount must be numeric"))
	assert_true(joined.contains("count must be numeric"))
	assert_true(joined.contains("Enemy enemy_bad_numeric max_health must be numeric"))
	assert_true(joined.contains("Enemy enemy_bad_numeric damage_taken_per_hit must be numeric"))
	assert_true(joined.contains("Enemy enemy_bad_numeric attack_damage must be numeric"))
	assert_true(
		joined.contains("Location object location_bad_numeric discovery_radius must be numeric")
	)
	assert_true(joined.contains("quest quest_bad rewards has malformed effect"))
	assert_true(joined.contains("quest quest_bad rewards add_experience must have positive amount"))
	assert_true(joined.contains("NPC npc_bad completion_conditions has malformed condition"))
	assert_true(joined.contains("NPC npc_bad completion_effects has malformed effect"))
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
		"pickup_traveler_buckler",
		"object_road_cache",
		"object_warden_cache",
		"object_sealed_strongbox",
		"enemy_road_thug",
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
				distance_from_spawn,
				float(
					entry.get("interaction_radius", EntityManager.DEFAULT_INTERACTION_RADIUS_PIXELS)
				)
			)
		found_ids.append(entity_id)

	found_ids.sort()
	expected_ids.sort()
	assert_eq(found_ids, expected_ids)


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
