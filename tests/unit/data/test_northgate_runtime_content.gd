extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const ChunkManager = preload("res://scripts/managers/world/chunk_manager.gd")
const StructureManager = preload("res://scripts/managers/world/structure_manager.gd")

var content: ContentDatabase


func before_all() -> void:
	content = ContentDatabase.new()
	content.load_all()


func after_all() -> void:
	content.free()


func test_northgate_runtime_geometry_is_fully_activated() -> void:
	assert_eq(content.load_errors, [])
	assert_eq(content.validate_all(), [])
	var northgate_structures: Array = content.world_structure_entries().filter(
		func(entry): return String(entry.get("id", "")).begins_with("structure_northgate_")
	)
	assert_eq(northgate_structures.size(), 26)
	assert_eq(northgate_structures.filter(func(entry): return entry["world_layer"] == "surface").size(), 13)
	assert_eq(northgate_structures.filter(func(entry): return entry["world_layer"] != "surface").size(), 13)
	var northgate_doors: Array = content.world_object_entries().filter(
		func(entry): return String(entry.get("id", "")).begins_with("portal_structure_northgate_")
	)
	assert_eq(northgate_doors.size(), 26)
	assert_true(northgate_doors.all(func(entry): return entry["kind"] == "door" and entry.has("portal")))


func test_northgate_palisade_blocks_and_all_gates_are_open() -> void:
	var chunks := ChunkManager.new()
	chunks.load_world_terrain(content.get_world_terrain())
	var proposal: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/proposals/settlement_northgate_seed_2701.json")
	)
	var defense: Dictionary = proposal["defenses"]
	for gate in defense["gates"]:
		var tile := Vector2i(int(gate["global_tile"][0]), int(gate["global_tile"][1]))
		assert_true(chunks.is_walkable(tile), String(gate["id"]))
	var blocked_boundary_found := false
	var gate_radius := int(defense.get("gate_width", 5)) / 2
	for pair in defense["boundary_polygon"]:
		var boundary_tile := Vector2i(int(pair[0]), int(pair[1]))
		var near_gate := false
		for gate in defense["gates"]:
			var gate_tile := Vector2i(int(gate["global_tile"][0]), int(gate["global_tile"][1]))
			if boundary_tile.distance_to(gate_tile) <= float(gate_radius + 1):
				near_gate = true
				break
		if near_gate:
			continue
		assert_eq(chunks.get_tile_kind(boundary_tile), "palisade")
		assert_false(chunks.is_walkable(boundary_tile))
		blocked_boundary_found = true
		break
	assert_true(blocked_boundary_found)
	chunks.free()


func test_northgate_residents_services_homes_and_quest_are_present() -> void:
	var structures := StructureManager.new()
	structures.setup(content)
	var residents: Array = content.world_object_entries().filter(
		func(entry): return String(entry.get("id", "")).begins_with("npc_northgate_") and String(entry.get("id", "")).ends_with("_world")
	)
	assert_gte(residents.size(), 15)
	for resident in residents:
		assert_true(structures.has_structure(String(resident.get("assigned_home_structure_id", ""))))
		assert_eq(String(resident.get("canon_status", "")), "proposal")
	for object_id in [
		"object_northgate_inn_bed", "object_northgate_player_storage",
		"poi_northgate_repair_bench", "poi_northgate_notice_board",
		"object_northgate_road_notice", "object_briarwatch_northgate_coach",
		"object_northgate_briarwatch_coach"
	]:
		assert_true(_has_world_object(object_id), object_id)
	assert_true(content.has_shop("shop_northgate_general"))
	assert_true(content.has_shop("shop_northgate_smith"))
	assert_true(content.has_quest("quest_northgate_missing_manifest"))
	assert_eq(content.get_quest("quest_northgate_missing_manifest")["canon_status"], "proposal")
	structures.free()


func test_all_authored_interior_fixtures_are_live_and_homes_are_personalized() -> void:
	var fixtures: Array = content.world_object_entries().filter(
		func(entry): return entry.get("kind", "") == "fixture"
	)
	# Building-specific authorship may add fixtures. Protect the established
	# baseline without freezing later visual passes to an obsolete town total.
	assert_gte(fixtures.size(), 102)
	var inn_fixtures: Array = fixtures.filter(
		func(entry): return entry.get("structure_id", "") == "structure_northgate_inn_plot"
	)
	assert_eq(inn_fixtures.size(), 18)
	var home_ids := [
		"structure_northgate_west_home_plot", "structure_northgate_south_home_plot",
		"structure_northgate_east_home_plot", "structure_northgate_southeast_home_plot",
		"structure_northgate_far_east_home_plot"
	]
	var personal_sets := {}
	for home_id in home_ids:
		var home_fixtures: Array = fixtures.filter(
			func(entry): return entry.get("structure_id", "") == home_id
		)
		assert_eq(home_fixtures.size(), 7, home_id)
		personal_sets[home_id] = home_fixtures.map(
			func(entry): return String(entry.get("visual_style", ""))
		)
	for left_index in home_ids.size():
		for right_index in range(left_index + 1, home_ids.size()):
			assert_ne(personal_sets[home_ids[left_index]], personal_sets[home_ids[right_index]])


func _has_world_object(object_id: String) -> bool:
	return content.world_object_entries().any(
		func(entry): return String(entry.get("id", "")) == object_id
	)
