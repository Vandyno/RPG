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
	assert_eq(northgate_structures.size(), 28)
	assert_eq(
		northgate_structures.filter(func(entry): return entry["world_layer"] == "surface").size(),
		14
	)
	assert_eq(
		northgate_structures.filter(func(entry): return entry["world_layer"] != "surface").size(),
		14
	)
	assert_true(northgate_structures.all(func(entry): return structures.has_structure(entry["id"])))


func test_runtime_geometry_is_a_direct_promotion_of_the_reviewed_proposal() -> void:
	var proposal := _load_dictionary("res://data/proposals/settlement_northgate_seed_2701.json")
	var runtime_structures := _load_array("res://data/runtime/northgate_structures.json")
	var runtime_archetypes := _load_dictionary("res://data/runtime/northgate_structure_archetypes.json")
	var runtime_objects := _load_array("res://data/runtime/northgate_objects.json")
	var structures_by_id := {}
	for entry in runtime_structures:
		structures_by_id[String(entry.get("id", ""))] = entry
	for source in proposal.get("structures", []):
		var promoted: Dictionary = structures_by_id.get(String(source.get("id", "")), {})
		assert_false(promoted.is_empty(), String(source.get("id", "")))
		var offset := _proposal_reauthor_offset(proposal, String(source.get("id", "")))
		assert_eq(_vector(promoted.get("origin_tile", [])), _vector(source.get("origin_tile", [])) + offset)
	for archetype_id in proposal.get("structure_archetypes", {}):
		var source: Dictionary = proposal["structure_archetypes"][archetype_id]
		var promoted: Dictionary = runtime_archetypes.get(archetype_id, {})
		assert_eq(_vector(promoted.get("size", [])), _vector(source.get("size", [])), archetype_id)
		assert_eq(promoted.get("terrain_rows", []), source.get("terrain_rows", []), archetype_id)
		assert_eq(promoted.get("anchors", {}), source.get("anchors", {}), archetype_id)
	var objects_by_id := {}
	for entry in runtime_objects:
		objects_by_id[String(entry.get("id", ""))] = entry
	for source in proposal.get("portals", []):
		var promoted: Dictionary = objects_by_id.get(String(source.get("id", "")), {})
		var offset := _portal_reauthor_offset(proposal, String(source.get("id", "")))
		var source_offset := offset if String(source.get("world_layer", "")) == "surface" else Vector2i.ZERO
		var target_offset := offset if String(source.get("target_layer", "")) == "surface" else Vector2i.ZERO
		assert_eq(_vector(promoted.get("global_tile", [])), _vector(source.get("global_tile", [])) + source_offset)
		assert_eq(_vector(promoted.get("portal", {}).get("target_tile", [])), _vector(source.get("target_tile", [])) + target_offset)


func test_every_northgate_building_has_walkable_reciprocal_runtime_portals() -> void:
	var portals: Array = content.world_object_entries().filter(
		func(entry): return String(entry.get("id", "")).begins_with("portal_structure_northgate_")
	)
	assert_eq(portals.size(), 26)
	for portal in portals:
		var source_tile := Vector2i(int(portal["global_tile"][0]), int(portal["global_tile"][1]))
		assert_true(query.is_walkable(source_tile, String(portal["world_layer"])), portal["id"])
		var target: Dictionary = portal["portal"]
		var tile := Vector2i(int(target["target_tile"][0]), int(target["target_tile"][1]))
		assert_true(query.is_walkable(tile, String(target["target_layer"])), portal["id"])
		if String(portal["world_layer"]).begins_with("interior:"):
			assert_eq(int(portal.get("interaction_radius", 0)), 48, portal["id"])


func test_northgate_lockup_has_walkable_structure_cell_legal_service_and_scheduled_guard() -> void:
	assert_true(structures.has_structure("structure_northgate_jail"))
	assert_true(structures.has_structure("structure_northgate_jail_interior"))
	for object_id in [
		"portal_northgate_jail_entry", "portal_northgate_jail_exit",
		"poi_northgate_jail_cot", "poi_northgate_jail_ledger",
		"container_northgate_jail_evidence"
	]:
		var matches: Array = content.world_object_entries().filter(
			func(entry): return String(entry.get("id", "")) == object_id
		)
		assert_eq(matches.size(), 1, object_id)
		var tile: Array = matches[0].get("global_tile", [])
		assert_true(
			query.is_walkable(
				Vector2i(int(tile[0]), int(tile[1])), String(matches[0].get("world_layer", "surface"))
			),
			object_id
		)
	var binding: Dictionary = content.get_schedule_binding("binding_northgate_jail_guard")
	assert_eq(binding.get("npc_id", ""), "npc_northgate_jail_guard")
	assert_eq(binding.get("patrol_destination_id", ""), "northgate_jail_guard_patrol")
	assert_eq(content.get_npc("npc_northgate_jail_guard").get("canon_status", ""), "proposal")


func test_roads_gates_palisade_and_coach_routes_are_walkable_as_intended() -> void:
	for gate_tile in [
		Vector2i(-3260, -3958), Vector2i(-3229, -3940),
		Vector2i(-3260, -3921), Vector2i(-3281, -3941)
	]:
		var tile: Vector2i = gate_tile
		assert_true(query.is_walkable(tile, "surface"), str(gate_tile))
	# The north approach is the settlement's visual axis and must not be occupied
	# by a building footprint (the first guardhouse layout blocked it entirely).
	for y in range(-3957, -3941):
		assert_true(query.is_walkable(Vector2i(-3260, y), "surface"), "north road y=%d" % y)
	assert_eq(chunks.get_tile_kind(Vector2i(-3262, -3968)), "road")
	assert_ne(chunks.get_tile_kind(Vector2i(-3263, -3968)), "road")
	assert_eq(chunks.get_tile_kind(Vector2i(-3274, -3957)), "palisade")
	assert_eq(chunks.get_tile_kind(Vector2i(-3273, -3956)), "hill")
	var north_route: Dictionary = content.world_object_entries().filter(
		func(entry): return entry.get("id", "") == "poi_northgate_north_gate_route"
	)[0]
	var north_route_tile: Array = north_route.get("global_tile", [])
	assert_eq(Vector2i(int(north_route_tile[0]), int(north_route_tile[1])), Vector2i(-3264, -3961))
	assert_eq(north_route.get("visual_style", ""), "sign")
	for id in ["object_briarwatch_northgate_coach", "object_northgate_briarwatch_coach"]:
		var matches: Array = content.world_object_entries().filter(
			func(entry): return entry.get("id", "") == id
		)
		assert_eq(matches.size(), 1)
		var source: Array = matches[0]["global_tile"]
		assert_true(query.is_walkable(Vector2i(int(source[0]), int(source[1])), String(matches[0].get("world_layer", "surface"))), id)
		var target: Array = matches[0]["portal"]["target_tile"]
		assert_true(query.is_walkable(Vector2i(int(target[0]), int(target[1])), "surface"))


func test_northgate_residents_services_and_local_quest_are_loaded() -> void:
	var residents: Array = content.world_object_entries().filter(
		func(entry): return String(entry.get("id", "")).begins_with("npc_northgate_")
	)
	assert_eq(residents.size(), 17)
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


func test_surface_dressing_does_not_overlap_building_collision() -> void:
	var details: Array = content.world_object_entries().filter(
		func(entry):
			return (
				entry.get("kind", "") == "surface_detail"
				and entry.get("visual_style", "") != "fixture:gate_tower"
			)
	)
	assert_gt(details.size(), 20)
	var occupied := {}
	for detail in details:
		var tile := _vector(detail.get("global_tile", []))
		assert_true(query.is_walkable(tile, "surface"), detail.get("id", ""))
		assert_false(occupied.has(tile), "%s overlaps %s" % [detail.get("id", ""), occupied.get(tile, "")])
		occupied[tile] = detail.get("id", "")


func test_every_northgate_civilian_runs_its_authored_schedule() -> void:
	var farmer_binding: Dictionary = content.get_schedule_binding("binding_northgate_farmer")
	assert_eq(farmer_binding.get("schedule_id", ""), "schedule_farmer_standard")
	assert_eq(farmer_binding.get("work_destination_id", ""), "northgate_farm_field_runtime")
	var farm_tile: Array = content.get_schedule_destinations()["northgate_farm_field_runtime"]["global_tile"]
	assert_eq(Vector2i(int(farm_tile[0]), int(farm_tile[1])), Vector2i(-3148, -3843))
	assert_eq(content.get_shop("shop_northgate_general").get("worker_npc_id", ""), "npc_northgate_shopkeeper")
	var guard_patrol: Array = content.get_schedule_destinations()["northgate_guard_gate_runtime"]["global_tile"]
	assert_true(query.is_walkable(Vector2i(int(guard_patrol[0]), int(guard_patrol[1])), "surface"))
	var square_destination: Dictionary = content.get_schedule_destinations()["northgate_square_runtime"]
	assert_eq(square_destination.get("activity_tiles", []).size(), 8)
	for tile in square_destination.get("activity_tiles", []):
		assert_true(query.is_walkable(Vector2i(int(tile[0]), int(tile[1])), "surface"), str(tile))
	var repair_bench: Dictionary = content.world_object_entries().filter(
		func(entry): return entry.get("id", "") == "poi_northgate_repair_bench"
	)[0]
	var repair_tile := _vector(repair_bench.get("global_tile", []))
	var smith_destination: Dictionary = content.get_schedule_destinations()["northgate_smith_service_runtime"]
	for tile in smith_destination.get("activity_tiles", []):
		var smith_tile := _vector(tile)
		assert_ne(smith_tile, repair_tile, "Smith must not cover the repair bench")
		assert_true(query.is_walkable(smith_tile, "interior:structure_northgate_smith_plot"))
	var farmer_objects: Array = content.world_object_entries().filter(
		func(entry): return String(entry.get("npc_id", "")) == "npc_northgate_farmer"
	)
	assert_eq(farmer_objects.size(), 1)
	assert_eq(farmer_objects[0].get("brain_id", ""), "civilian_schedule")
	for binding_id in content.schedule_bindings:
		if not String(binding_id).begins_with("binding_northgate_"):
			continue
		var binding: Dictionary = content.schedule_bindings[binding_id]
		var npc_id := String(binding.get("npc_id", ""))
		var bound_objects: Array = content.world_object_entries().filter(
			func(entry): return String(entry.get("npc_id", "")) == npc_id
		)
		assert_eq(bound_objects.size(), 1, String(binding_id))
		assert_eq(bound_objects[0].get("brain_id", ""), "civilian_schedule", npc_id)
	assert_true(chunks.is_walkable(Vector2i(-3282, -3902)))
	assert_true(chunks.is_walkable(Vector2i(-3148, -3843)))


func _load_dictionary(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _proposal_reauthor_offset(proposal: Dictionary, structure_id: String) -> Vector2i:
	return _vector(proposal.get("runtime_reauthor_offsets", {}).get(structure_id, [0, 0]))


func _portal_reauthor_offset(proposal: Dictionary, portal_id: String) -> Vector2i:
	for structure_id in proposal.get("runtime_reauthor_offsets", {}):
		if portal_id.contains(String(structure_id)):
			return _proposal_reauthor_offset(proposal, String(structure_id))
	return Vector2i.ZERO


func _load_array(path: String) -> Array:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Array else []


func _vector(value: Variant) -> Vector2i:
	if not value is Array or value.size() < 2:
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))
