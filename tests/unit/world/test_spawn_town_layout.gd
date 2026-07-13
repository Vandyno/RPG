extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainPathfinder = preload("res://scripts/main/input/main_pathfinder.gd")
const MainFlowInputHelper = preload("res://tests/unit/main/flows/main_flow_input_helper.gd")


func test_spawn_town_places_existing_content_in_logical_groups() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_eq(_tile(main, "object_harrow_forge_door"), Vector2i(8, 0))
	assert_eq(_tile(main, "npc_maera_pike_world"), Vector2i(3, -5))
	assert_null(main.entities.get_entity("poi_maera_stall"))
	assert_eq(_tile(main, "poi_briarwatch_square"), Vector2i(7, 7))
	assert_eq(_tile(main, "object_briarwatch_town_hall_door"), Vector2i(5, 7))
	assert_eq(_tile(main, "object_roadside_campfire"), Vector2i(-1, 4))
	assert_eq(_tile(main, "pickup_old_toolbox"), Vector2i(-7, 1))
	assert_eq(_tile(main, "npc_road_thug"), Vector2i(-6, 1))
	assert_eq(_tile(main, "npc_test_raider"), Vector2i(-10, 1))
	assert_eq(_tile(main, "object_road_cache"), Vector2i(-8, 2))
	assert_eq(main.chunks.get_tile_kind(_tile(main, "object_roadside_campfire")), "road")
	assert_eq(main.chunks.get_tile_kind(_tile(main, "pickup_old_toolbox")), "road")
	assert_eq(main.chunks.get_tile_kind(_tile(main, "npc_road_thug")), "road")
	var road_thug = main.entities.get_entity("npc_road_thug")
	assert_gt(
		road_thug.global_position.distance_to(main.player.global_position),
		float(road_thug.data.get("aggro_radius", 0.0)),
		"Road thug should not aggro the player at spawn."
	)
	assert_eq(main.chunks.get_tile_kind(_tile(main, "npc_test_raider")), "road")
	assert_eq(main.chunks.get_tile_kind(_tile(main, "object_road_cache")), "road")
	assert_lte(
		main.entities.get_entity("pickup_old_toolbox").global_position.distance_to(
			road_thug.global_position
		),
		32.0
	)
	assert_lt(
		main.entities.get_entity("pickup_old_toolbox").global_position.x,
		road_thug.global_position.x
	)
	assert_true(MainFlowInputHelper.enter_forge_direct(main))
	assert_eq(_tile(main, "npc_harrow_venn_world"), Vector2i(4, 5))
	assert_null(main.entities.get_entity("poi_harrow_forge"))
	assert_null(main.entities.get_entity("poi_harrow_forge_hearth"))
	assert_true(MainFlowInputHelper.exit_forge_direct(main))
	assert_true(MainFlowInputHelper.enter_town_hall_direct(main))
	assert_eq(_tile(main, "object_road_notice"), Vector2i(2, 2))
	assert_eq(_tile(main, "object_sealed_strongbox"), Vector2i(9, 5))


func test_spawn_town_keeps_west_road_clear_for_missing_tools_quest() -> void:
	var main := Main.new()
	add_child_autofree(main)

	for tile in [Vector2i(-10, 1), Vector2i(-9, 1), Vector2i(-8, 1), Vector2i(-7, 1), Vector2i(-6, 1)]:
		assert_eq(main.chunks.get_tile_kind(tile), "road")
		assert_true(main.chunks.is_walkable(tile))
	for tile in [Vector2i(-1, 4), Vector2i(0, 4)]:
		assert_eq(main.chunks.get_tile_kind(tile), "road")
		assert_true(main.chunks.is_walkable(tile))
	assert_eq(main.chunks.get_tile_kind(Vector2i(-10, 3)), "wood_floor")
	assert_eq(main.chunks.get_tile_kind(Vector2i(-11, 4)), "wood_wall")


func test_outside_gate_species_raiders_showcase_full_armour_sets() -> void:
	var main := Main.new()
	add_child_autofree(main)

	var tanglekin = main.entities.get_entity("npc_people_test_tanglekin")
	var mirefolk = main.entities.get_entity("npc_people_test_mirefolk")
	assert_not_null(tanglekin)
	assert_not_null(mirefolk)
	assert_eq(
		tanglekin.data.get("equipped_items", {}),
		{
			"head": "item_leather_cap",
			"chest": "item_leather_cuirass",
			"legs": "item_leather_leggings",
			"gloves": "item_leather_gloves",
			"boots": "item_leather_boots",
			"right_hand": "item_training_sword"
		}
	)
	assert_eq(
		mirefolk.data.get("equipped_items", {}),
		{
			"head": "item_iron_helm",
			"chest": "item_iron_cuirass",
			"legs": "item_iron_leggings",
			"gloves": "item_iron_gauntlets",
			"boots": "item_iron_boots",
			"right_hand": "item_training_sword"
		}
	)


func test_spawn_town_interactables_have_reachable_approach_points() -> void:
	var main := Main.new()
	add_child_autofree(main)

	for entity_id in main.entities.entities_by_id.keys():
		var entity = main.entities.get_entity(String(entity_id))
		if not entity or entity.get_kind() == "location":
			continue
		if entity.get_kind() == "door":
			continue
		var stop_distance := 32.0
		var path := MainPathfinder.approach_path_to(
			Callable(main.player, "_can_stand_at"),
			main.player.global_position,
			entity.global_position,
			stop_distance
		)
		assert_false(path.is_empty(), "%s should be reachable from spawn." % entity_id)


func _tile(main, entity_id: String) -> Vector2i:
	var entity = main.entities.get_entity(entity_id)
	assert_not_null(entity)
	return entity.global_tile if entity else Vector2i.ZERO
