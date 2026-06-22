extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainPathfinder = preload("res://scripts/main/main_pathfinder.gd")


func test_spawn_town_places_existing_content_in_logical_groups() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_eq(_tile(main, "npc_harrow_venn_world"), Vector2i(5, 1))
	assert_eq(_tile(main, "poi_harrow_forge"), Vector2i(6, 2))
	assert_eq(_tile(main, "npc_maera_pike_world"), Vector2i(3, -5))
	assert_eq(_tile(main, "poi_maera_stall"), Vector2i(3, -4))
	assert_eq(_tile(main, "poi_briarwatch_square"), Vector2i(4, 5))
	assert_eq(_tile(main, "object_road_notice"), Vector2i(2, 6))
	assert_eq(_tile(main, "pickup_old_toolbox"), Vector2i(-5, 2))
	assert_eq(_tile(main, "enemy_road_thug"), Vector2i(-4, 2))
	assert_lte(
		main.entities.get_entity("pickup_old_toolbox").global_position.distance_to(
			main.entities.get_entity("enemy_road_thug").global_position
		),
		32.0
	)


func test_spawn_town_interactables_have_reachable_approach_points() -> void:
	var main := Main.new()
	add_child_autofree(main)

	for entity_id in main.entities.entities_by_id.keys():
		var entity = main.entities.get_entity(String(entity_id))
		if not entity or entity.get_kind() == "location":
			continue
		var stop_distance := 32.0
		if entity.get_kind() == "door":
			stop_distance = maxf(stop_distance, main.entities.get_interaction_radius(entity) - 4.0)
		var path := MainPathfinder.approach_path_to(
			main, main.player.global_position, entity.global_position, stop_distance
		)
		assert_false(path.is_empty(), "%s should be reachable from spawn." % entity_id)


func _tile(main, entity_id: String) -> Vector2i:
	var entity = main.entities.get_entity(entity_id)
	assert_not_null(entity)
	return entity.global_tile if entity else Vector2i.ZERO
