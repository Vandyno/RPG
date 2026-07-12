extends GutTest

const ContentDatabaseScript = preload("res://scripts/data/content_database.gd")
const ChunkManagerScript = preload("res://scripts/managers/world/chunk_manager.gd")
const StructureManagerScript = preload("res://scripts/managers/world/structure_manager.gd")
const WorldQueryScript = preload("res://scripts/world/world_query.gd")

var content
var chunks
var structures
var query


func before_all() -> void:
	content = ContentDatabaseScript.new()
	add_child(content)
	assert_eq(content.load_all(), [])
	chunks = ChunkManagerScript.new()
	add_child(chunks)
	chunks.load_world_terrain(content.get_world_terrain())
	structures = StructureManagerScript.new()
	add_child(structures)
	structures.setup(content)
	query = WorldQueryScript.new()
	query.setup(chunks, structures)


func after_all() -> void:
	structures.free()
	chunks.free()
	content.free()


func test_approved_northgate_geometry_is_active_runtime_content() -> void:
	var northgate_structures: Array = content.world_structure_entries().filter(
		func(entry): return String(entry.get("id", "")).begins_with("structure_northgate_")
	)
	assert_eq(northgate_structures.size(), 26)
	assert_eq(
		northgate_structures.filter(func(entry): return entry["world_layer"] == "surface").size(),
		13
	)
	assert_eq(
		northgate_structures.filter(func(entry): return entry["world_layer"] != "surface").size(),
		13
	)
	assert_true(northgate_structures.all(func(entry): return structures.has_structure(entry["id"])))


func test_every_northgate_building_has_walkable_reciprocal_runtime_portals() -> void:
	var portals: Array = content.world_object_entries().filter(
		func(entry): return String(entry.get("id", "")).begins_with("portal_structure_northgate_")
	)
	assert_eq(portals.size(), 26)
	for portal in portals:
		var target: Dictionary = portal["portal"]
		var tile := Vector2i(int(target["target_tile"][0]), int(target["target_tile"][1]))
		assert_true(query.is_walkable(tile, String(target["target_layer"])), portal["id"])


func test_roads_gates_palisade_and_coach_routes_are_walkable_as_intended() -> void:
	var proposal: Dictionary = JSON.parse_string(
		FileAccess.get_file_as_string("res://data/proposals/settlement_northgate_seed_2701.json")
	)
	for gate in proposal["defenses"]["gates"]:
		var tile := Vector2i(int(gate["global_tile"][0]), int(gate["global_tile"][1]))
		assert_true(query.is_walkable(tile, "surface"), gate["id"])
	var wall_pair: Array = proposal["defenses"]["boundary_polygon"][0]
	assert_eq(chunks.get_tile_kind(Vector2i(int(wall_pair[0]), int(wall_pair[1]))), "wood_wall")
	for id in ["object_briarwatch_northgate_coach", "object_northgate_briarwatch_coach"]:
		var matches: Array = content.world_object_entries().filter(
			func(entry): return entry.get("id", "") == id
		)
		assert_eq(matches.size(), 1)
		var target: Array = matches[0]["portal"]["target_tile"]
		assert_true(query.is_walkable(Vector2i(int(target[0]), int(target[1])), "surface"))


func test_northgate_residents_services_and_local_quest_are_loaded() -> void:
	var residents: Array = content.world_object_entries().filter(
		func(entry): return String(entry.get("id", "")).begins_with("npc_northgate_")
	)
	assert_eq(residents.size(), 16)
	assert_true(residents.all(func(entry): return not String(entry.get("assigned_home_structure_id", "")).is_empty()))
	assert_true(residents.all(func(entry): return entry.get("canon_status", "") == "proposal"))
	assert_true(content.has_shop("shop_northgate_general"))
	assert_true(content.has_shop("shop_northgate_smith"))
	assert_true(content.has_quest("quest_northgate_missing_manifest"))
	for id in [
		"object_northgate_inn_bed", "object_northgate_player_storage",
		"poi_northgate_notice_board", "poi_northgate_repair_bench",
		"pickup_northgate_missing_manifest"
	]:
		assert_true(content.world_object_entries().any(func(entry): return entry.get("id", "") == id), id)
	assert_eq(content.validate_all(), [])


func test_northgate_civilian_schedule_runtime_has_farmer_commute_and_shop_worker_binding() -> void:
	var farmer_binding: Dictionary = content.get_schedule_binding("binding_northgate_farmer")
	assert_eq(farmer_binding.get("schedule_id", ""), "schedule_farmer_standard")
	assert_eq(farmer_binding.get("work_destination_id", ""), "northgate_farm_field_runtime")
	var farm_tile: Array = content.get_schedule_destinations()["northgate_farm_field_runtime"]["global_tile"]
	assert_eq(Vector2i(int(farm_tile[0]), int(farm_tile[1])), Vector2i(-3148, -3843))
	assert_eq(content.get_shop("shop_northgate_general").get("worker_npc_id", ""), "npc_northgate_shopkeeper")
	var farmer_objects: Array = content.world_object_entries().filter(
		func(entry): return String(entry.get("npc_id", "")) == "npc_northgate_farmer"
	)
	assert_eq(farmer_objects.size(), 1)
	assert_eq(farmer_objects[0].get("brain_id", ""), "civilian_schedule")
	assert_true(chunks.is_walkable(Vector2i(-3282, -3902)))
	assert_true(chunks.is_walkable(Vector2i(-3148, -3843)))
