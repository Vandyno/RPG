extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const ContentWorldValidator = preload("res://scripts/data/content_world_validator.gd")

var content: ContentDatabase


func before_each() -> void:
	content = ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()


func test_rejects_broken_objects_and_terrain() -> void:
	var errors: Array[String] = []
	content.locations["location_validator_bad"] = {
		"id": "wrong_location_id",
		"name": "",
		"region": "",
		"description": ""
	}
	content.world_objects = [
		{"id": "", "kind": "pickup"},
		{
			"id": "enemy_legacy",
			"name": "",
			"kind": "enemy",
			"global_tile": ["x", 2],
			"interaction_radius": 0
		},
		{
			"id": "npc_bad",
			"name": "Bad NPC",
			"kind": "npc",
			"global_tile": [1, 1],
			"npc_id": "missing_npc",
			"character_profile_id": "char_missing",
			"inventory_owner_id": "wrong",
			"equipment_owner_id": "wrong",
			"hostile_to_player": true,
			"max_health": "full",
			"damage_taken_per_hit": 0,
			"attack_damage": -1,
			"attack_interval_seconds": 1.0
		},
		{
			"id": "poi_bad",
			"name": "Bad POI",
			"kind": "poi",
			"global_tile": [2, 2],
			"system_tab": "trade",
			"actions": [{"id": "", "text": ""}]
		},
		{
			"id": "door_bad_portal",
			"name": "Bad Portal",
			"kind": "door",
			"global_tile": [4, 4],
			"portal": {"target_layer": "", "target_tile": ["x", 1], "target_facing": [0]}
		},
		{"id": "poi_bad", "name": "Duplicate", "kind": "unknown", "global_tile": [3, 3]}
	]
	content.structure_archetypes = {
		"archetype_bad": {
			"id": "wrong_archetype",
			"name": "",
			"visual_style": "",
			"size": [2, 2],
			"terrain_rows": ["wxy"],
			"tile_kinds": {"w": "lava"},
			"anchors": {"": [0, 0], "bad": [0]}
		}
	}
	content.world_structures = [
		{
			"id": "",
			"name": "Missing ID",
			"archetype_id": "missing",
			"world_layer": "",
			"origin_tile": [0]
		},
		{
			"id": "structure_bad",
			"name": "",
			"archetype_id": "missing",
			"world_layer": "",
			"origin_tile": ["x", 0]
		}
	]
	content.world_terrain = {
		"areas":
		[
			{
				"id": "bad_area",
				"bounds": {"min": [0], "max": ["x", 4]},
				"default_kind": "lava",
				"regions":
				[
					{"id": "", "kind": "void"},
					{"id": "bad_region", "kind": "grass", "rect": {"position": [0], "size": [0, 1]}},
					{"id": "tiles_bad", "kind": "road", "tiles": []}
				]
			}
		]
	}

	ContentWorldValidator.validate(content, errors)
	var joined := "\n".join(errors)

	assert_true(joined.contains("Location location_validator_bad has mismatched id"))
	assert_true(joined.contains("Location location_validator_bad is missing name"))
	assert_true(joined.contains("World object is missing id"))
	assert_true(joined.contains("uses legacy enemy_ id"))
	assert_true(joined.contains("global_tile values must be numeric"))
	assert_true(joined.contains("uses legacy kind enemy"))
	assert_true(joined.contains("references missing NPC missing_npc"))
	assert_true(joined.contains("references missing character profile char_missing"))
	assert_true(joined.contains("inventory_owner_id must match character_profile_id char_missing"))
	assert_true(joined.contains("equipment_owner_id must match character_profile_id char_missing"))
	assert_true(joined.contains("max_health must be numeric"))
	assert_true(joined.contains("must have positive damage_taken_per_hit"))
	assert_true(joined.contains("must have non-negative attack_damage"))
	assert_true(joined.contains("POI poi_bad is missing description"))
	assert_true(joined.contains("trade system_tab without shop_id"))
	assert_true(joined.contains("Duplicate world object id poi_bad"))
	assert_true(joined.contains("World object poi_bad has unsupported kind unknown"))
	assert_true(joined.contains("World object door_bad_portal portal is missing target_layer"))
	assert_true(joined.contains("target_tile values must be numeric"))
	assert_true(joined.contains("target_facing must be [x, y]"))
	assert_true(joined.contains("Structure archetype archetype_bad has mismatched id"))
	assert_true(joined.contains("Structure archetype archetype_bad is missing name"))
	assert_true(joined.contains("Structure archetype archetype_bad is missing visual_style"))
	assert_true(joined.contains("terrain_rows height must match size"))
	assert_true(joined.contains("terrain row 0 width must match size"))
	assert_true(joined.contains("terrain code w has unsupported kind lava"))
	assert_true(joined.contains("terrain code x has no tile kind"))
	assert_true(joined.contains("anchors has blank anchor id"))
	assert_true(joined.contains("anchor bad must be [x, y]"))
	assert_true(joined.contains("World structure is missing id"))
	assert_true(joined.contains("World structure structure_bad is missing name"))
	assert_true(joined.contains("references missing archetype missing"))
	assert_true(joined.contains("World structure structure_bad is missing world_layer"))
	assert_true(joined.contains("origin_tile values must be numeric"))
	assert_true(joined.contains("bounds min must be [x, y]"))
	assert_true(joined.contains("bounds max values must be numeric"))
	assert_true(joined.contains("unsupported terrain kind lava"))
	assert_true(joined.contains("has region with missing id"))
	assert_true(joined.contains("unsupported terrain kind void"))
	assert_true(joined.contains("rect position must be [x, y]"))
	assert_true(joined.contains("rect size values must be positive"))
	assert_true(joined.contains("tiles must be a non-empty array"))
