extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainWorldGuidance = preload("res://scripts/main/main_world_guidance.gd")


func test_nearby_spawn_hints_stay_sparse_around_selected_target() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var campfire = main.entities.get_entity("object_roadside_campfire")

	assert_not_null(campfire)
	main.player.set_world_position(campfire.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	campfire = main.entities.get_entity("object_roadside_campfire")
	main._handle_target_selected("object_roadside_campfire")
	main._update_nearby()

	var visible_hint_count := 0
	for entity in main.entities.entities_by_id.values():
		if entity.action_hint_visible:
			visible_hint_count += 1

	assert_true(campfire.action_hint_visible)
	assert_lte(visible_hint_count, 2)


func test_nearby_spawn_hints_do_not_overlap_selected_hint() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var campfire = main.entities.get_entity("object_roadside_campfire")

	assert_not_null(campfire)
	main.player.set_world_position(campfire.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	campfire = main.entities.get_entity("object_roadside_campfire")
	main._handle_target_selected("object_roadside_campfire")
	main._update_nearby()

	var selected_rect: Rect2 = MainWorldGuidance._hint_rect(
		campfire.global_position, campfire.action_hint_text, campfire.action_hint_offset_y
	).grow(MainWorldGuidance.ACTION_HINT_MARGIN)
	for entity in main.entities.entities_by_id.values():
		if entity == campfire or not entity.action_hint_visible:
			continue
		var rect: Rect2 = MainWorldGuidance._hint_rect(
			entity.global_position, entity.action_hint_text, entity.action_hint_offset_y
		)
		assert_false(
			rect.intersects(selected_rect),
			"%s hint should not overlap selected hint." % entity.get_entity_id()
		)


func test_unselected_spawn_hints_do_not_compete_with_player_ring() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var campfire = main.entities.get_entity("object_roadside_campfire")

	assert_not_null(campfire)
	main.player.set_world_position(campfire.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	campfire = main.entities.get_entity("object_roadside_campfire")
	main._handle_target_selected("object_roadside_campfire")
	main._update_nearby()

	var player_rect: Rect2 = MainWorldGuidance._player_clearance_rect(main.player.global_position)
	for entity in main.entities.entities_by_id.values():
		if entity == campfire or not entity.action_hint_visible:
			continue
		var rect: Rect2 = MainWorldGuidance._hint_rect(
			entity.global_position, entity.action_hint_text, entity.action_hint_offset_y
		)
		assert_false(
			rect.intersects(player_rect),
			"%s hint should not sit under the player ring." % entity.get_entity_id()
		)


func test_compact_landscape_shows_only_selected_world_hint() -> void:
	assert_eq(MainWorldGuidance._max_world_action_hints_for_width(640.0), 1)
	assert_eq(MainWorldGuidance._max_world_action_hints_for_width(1152.0), 2)


func test_compact_selected_world_hint_names_target_without_repeating_action() -> void:
	assert_eq(
		MainWorldGuidance._hint_text_for_width("Rest", "Bridge Campfire", true, 640.0),
		"Bridge Campfire"
	)
	assert_eq(
		MainWorldGuidance._hint_text_for_width("Rest", "Bridge Campfire", true, 1152.0),
		"Rest Bridge Campfire"
	)
	assert_eq(
		MainWorldGuidance._hint_text_for_width(
			"Inspect", "Ancient Boundary Stone", true, 640.0
		),
		"Inspect"
	)
