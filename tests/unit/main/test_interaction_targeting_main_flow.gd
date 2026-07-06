extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainInputRouter = preload("res://scripts/main/main_input_router.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")


class BlockingChunks:
	var blocked_tiles: Dictionary = {}

	func block(tile: Vector2i) -> void:
		blocked_tiles["%d:%d" % [tile.x, tile.y]] = true

	func is_walkable(tile: Vector2i) -> bool:
		return not blocked_tiles.has("%d:%d" % [tile.x, tile.y])

	func get_tile_kind(tile: Vector2i) -> String:
		return "water" if not is_walkable(tile) else "grass"


func test_default_interact_ignores_enemy_as_interaction_target() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_null(main._get_nearby_entity())
	assert_eq(main.get_debug_state()["primary_action"], "Explore")

	var enemy = main.entities.get_entity("enemy_road_thug")
	main.player.set_world_position(enemy.global_position + Vector2(8.0, 0.0))
	main.player.set_facing_direction(Vector2.LEFT)
	var target = main._get_nearby_entity()

	assert_true(target == null or target.get_kind() != "enemy")
	assert_ne(main.get_debug_state()["primary_action"], "Attack")
	assert_false(main.manual_target_locked)
	assert_false(main.combat.health_by_entity_id.has("enemy_road_thug"))

	var harrow = main.entities.get_entity("npc_harrow_venn_world")
	main.player.set_world_position(harrow.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	var east_target = main._get_nearby_entity()

	assert_not_null(east_target)
	assert_eq(east_target.get_entity_id(), "npc_harrow_venn_world")
	assert_eq(main.get_debug_state()["primary_action"], "Talk")
	assert_false(main.manual_target_locked)

	main._handle_interact_requested()

	assert_true(main.hud.content_body_label.text.contains("need my old toolbox"))


func test_manual_target_cycle_still_overrides_facing_until_target_is_gone() -> void:
	var main := Main.new()
	add_child_autofree(main)

	var harrow = main.entities.get_entity("npc_harrow_venn_world")
	main.player.set_world_position(harrow.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	assert_eq(main._get_nearby_entity().get_entity_id(), "npc_harrow_venn_world")

	main._handle_cycle_target_requested()
	var manual_target_id := main.selected_target_id
	main.player.set_facing_direction(Vector2.LEFT)

	assert_true(main.manual_target_locked)
	assert_eq(main._get_nearby_entity().get_entity_id(), manual_target_id)


func test_manual_movement_clears_stale_manual_target_lock() -> void:
	var main := Main.new()
	add_child_autofree(main)

	var harrow = main.entities.get_entity("npc_harrow_venn_world")
	main.player.set_world_position(harrow.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	assert_eq(main._get_nearby_entity().get_entity_id(), "npc_harrow_venn_world")
	main._handle_cycle_target_requested()
	assert_true(main.manual_target_locked)

	main.player.set_external_move_vector(Vector2.LEFT)
	MainInputRouter.update_auto_interaction(main, 0.016)
	main.player.set_external_move_vector(Vector2.ZERO)

	assert_false(main.manual_target_locked)
	assert_ne(main.selected_target_id, "npc_harrow_venn_world")


func test_world_tap_interacts_with_exact_reachable_pickup_without_target_menu() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var toolbox = main.entities.get_entity("pickup_old_toolbox")

	assert_not_null(toolbox)
	var toolbox_position: Vector2 = toolbox.global_position
	main.player.set_world_position(toolbox_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	assert_true(MainInputRouter.target_world(main, toolbox_position))

	assert_true(main.inventory.has_item("item_old_toolbox"))
	assert_null(main.entities.get_entity("pickup_old_toolbox"))
	assert_true(main.hud.log_label.text.contains("Picked up Old Toolbox"))


func test_world_tap_uses_forgiving_marker_pick_radius() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var toolbox = main.entities.get_entity("pickup_old_toolbox")

	assert_not_null(toolbox)
	var toolbox_position: Vector2 = toolbox.global_position
	main.player.set_world_position(toolbox_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	assert_true(MainInputRouter.target_world(main, toolbox_position + Vector2(0.0, -34.0)))

	assert_true(main.inventory.has_item("item_old_toolbox"))
	assert_false(main.auto_move_active)


func test_world_tap_interacts_with_exact_reachable_npc_without_target_menu() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var harrow = main.entities.get_entity("npc_harrow_venn_world")

	assert_not_null(harrow)
	main.player.set_world_position(harrow.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	assert_true(MainInputRouter.target_world(main, harrow.global_position))

	assert_eq(main.selected_target_id, "npc_harrow_venn_world")
	assert_true(main.manual_target_locked)
	assert_true(main.hud.content_body_label.text.contains("need my old toolbox"))


func test_world_action_hint_can_be_tapped_without_target_menu() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var harrow = main.entities.get_entity("npc_harrow_venn_world")

	assert_not_null(harrow)
	main.player.set_world_position(harrow.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	main._update_nearby()

	assert_true(harrow.action_hint_visible)
	assert_eq(harrow.action_hint_text, "Talk Harrow Venn")
	assert_true(harrow.action_hint_selected)

	var label_world: Vector2 = harrow.global_position + Vector2(0.0, -35.0)
	assert_true(MainInputRouter.target_world(main, label_world))

	assert_false(main.hud.is_target_picker_visible())
	assert_true(main.hud.content_body_label.text.contains("need my old toolbox"))


func test_world_tap_on_target_closes_content_card_and_uses_target() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var harrow = main.entities.get_entity("npc_harrow_venn_world")
	var toolbox = main.entities.get_entity("pickup_old_toolbox")

	assert_not_null(harrow)
	assert_not_null(toolbox)
	main.player.set_world_position(harrow.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	var toolbox_position: Vector2 = toolbox.global_position
	assert_true(MainInputRouter.target_world(main, harrow.global_position))
	assert_true(main.hud.is_content_card_visible())

	main.player.set_world_position(toolbox_position)
	main._update_nearby()
	assert_true(MainInputRouter.target_world(main, toolbox_position))

	assert_false(main.hud.is_content_card_visible())
	assert_true(main.inventory.has_item("item_old_toolbox"))
	assert_null(main.entities.get_entity("pickup_old_toolbox"))


func test_next_target_closes_content_card_and_cycles_immediately() -> void:
	var main := Main.new()
	add_child_autofree(main)

	var harrow = main.entities.get_entity("npc_harrow_venn_world")
	main.player.set_world_position(harrow.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	main._handle_target_selected("npc_harrow_venn_world")
	main._handle_interact_requested()
	assert_true(main.hud.is_content_card_visible())
	assert_eq(main.selected_target_id, "npc_harrow_venn_world")

	main._handle_cycle_target_requested()

	assert_false(main.hud.is_content_card_visible())
	assert_ne(main.selected_target_id, "npc_harrow_venn_world")
	assert_true(main.manual_target_locked)
	assert_true(main.hud.log_label.text.contains("Targeting "))


func test_selected_target_keeps_world_hint_in_crowded_spawn() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var strongbox = main.entities.get_entity("object_sealed_strongbox")

	assert_not_null(strongbox)
	main.player.set_world_position(strongbox.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	main._handle_target_selected("object_sealed_strongbox")
	main._update_nearby()

	assert_eq(main.selected_target_id, "object_sealed_strongbox")
	assert_true(strongbox.action_hint_visible)
	assert_true(strongbox.action_hint_selected)
	assert_eq(strongbox.action_hint_text, "Locked")
	assert_eq(strongbox.action_hint_offset_y, 0.0)


func test_nearby_spawn_hints_stagger_without_moving_selected_target() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var strongbox = main.entities.get_entity("object_sealed_strongbox")

	assert_not_null(strongbox)
	main.player.set_world_position(strongbox.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	main._handle_target_selected("object_sealed_strongbox")
	main._update_nearby()

	var visible_hint_count := 0
	for entity in main.entities.entities_by_id.values():
		if entity == strongbox or not entity.action_hint_visible:
			continue
		visible_hint_count += 1

	assert_true(strongbox.action_hint_selected)
	assert_eq(strongbox.action_hint_offset_y, 0.0)
	assert_lte(visible_hint_count, 1)


func test_selected_world_hint_keeps_target_name_when_it_fits() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var campfire = main.entities.get_entity("object_roadside_campfire")

	assert_not_null(campfire)
	var campfire_position: Vector2 = campfire.global_position
	main.player.set_world_position(campfire_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	main._handle_target_selected("object_roadside_campfire")
	main._update_nearby()
	campfire = main.entities.get_entity("object_roadside_campfire")

	assert_true(campfire.action_hint_visible)
	assert_true(campfire.action_hint_selected)
	assert_eq(campfire.action_hint_text, "Rest Bridge Campfire")


func test_world_tap_approaches_and_interacts_with_far_target() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.player.set_world_position(Vector2(-96.0, 40.0))
	var harrow = main.entities.get_entity("npc_harrow_venn_world")

	assert_not_null(harrow)
	assert_true(MainInputRouter.target_world(main, harrow.global_position))
	assert_eq(main.auto_interact_target_id, "npc_harrow_venn_world")
	assert_eq(main.get_debug_state()["nearby"], "Harrow Venn")
	assert_eq(main.get_debug_state()["primary_action"], "Stop")
	assert_true(main.hud.prompt_label.text.begins_with("Stop\nHarrow Venn"))
	assert_eq(main.hud.primary_action_button.text, "Attack")
	assert_true(main.hud.log_label.text.contains("Moving to Harrow Venn."))

	for _i in range(90):
		MainInputRouter.update_auto_interaction(main, 0.016)
		if main.hud.is_content_card_visible():
			break

	assert_eq(main.auto_interact_target_id, "")
	assert_eq(main.selected_target_id, "npc_harrow_venn_world")
	assert_true(main.hud.content_body_label.text.contains("need my old toolbox"))


func test_world_tap_interacts_with_target_on_blocked_tile_from_reachable_edge() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var chunks := BlockingChunks.new()
	var harrow = main.entities.get_entity("npc_harrow_venn_world")

	assert_not_null(harrow)
	var harrow_position: Vector2 = harrow.global_position
	chunks.block(GridMath.world_to_tile(harrow_position))
	main.player.chunk_manager = chunks
	main.player.set_world_position(Vector2(-96.0, 40.0))
	harrow = main.entities.get_entity("npc_harrow_venn_world")

	assert_not_null(harrow)
	assert_true(MainInputRouter.target_world(main, harrow_position))
	assert_eq(main.auto_interact_target_id, "npc_harrow_venn_world")
	if not main.auto_move_path.is_empty():
		assert_lte(
			main.auto_move_path[main.auto_move_path.size() - 1].distance_to(harrow_position),
			main.entities.get_interaction_radius(harrow)
		)

	for _i in range(160):
		MainInputRouter.update_auto_interaction(main, 0.016)
		if main.hud.is_content_card_visible():
			break

	assert_eq(main.auto_interact_target_id, "")
	assert_eq(main.selected_target_id, "npc_harrow_venn_world")
	assert_true(main.hud.content_body_label.text.contains("need my old toolbox"))
	assert_true(chunks.is_walkable(main.player.global_tile))


func test_world_tap_moves_to_empty_ground_without_target_menu() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var destination: Vector2 = GridMath.tile_to_world(Vector2i(0, -1)) + Vector2(8.0, 8.0)

	assert_true(MainInputRouter.move_to_world(main, destination))
	assert_true(main.auto_move_active)
	assert_eq(main.get_debug_state()["nearby"], "Destination")
	assert_eq(main.get_debug_state()["primary_action"], "Stop")
	assert_true(main.hud.prompt_label.text.begins_with("Stop\nDestination"))
	assert_eq(main.hud.primary_action_button.text, "Attack")
	assert_false(main.manual_target_locked)
	assert_false(main.entities.get_entity("npc_harrow_venn_world").action_hint_visible)

	for _i in range(90):
		MainInputRouter.update_auto_interaction(main, 0.016)
		if not main.auto_move_active:
			break

	assert_false(main.auto_move_active)
	assert_lte(main.player.global_position.distance_to(destination), 10.0)


func test_world_tap_move_follows_grid_path_around_blocked_tile() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var chunks := BlockingChunks.new()
	chunks.block(Vector2i(2, 0))
	main.player.chunk_manager = chunks
	var destination := GridMath.tile_to_world(Vector2i(4, 0)) + Vector2(8.0, 8.0)

	assert_true(MainInputRouter.move_to_world(main, destination))
	assert_true(main.auto_move_active)
	assert_false(main.auto_move_path.is_empty())
	assert_gt(main.auto_move_path[0].y, main.player.global_position.y)

	for _i in range(180):
		MainInputRouter.update_auto_interaction(main, 0.016)
		if not main.auto_move_active:
			break

	assert_false(main.auto_move_active)
	assert_lte(main.player.global_position.distance_to(destination), 10.0)
	assert_true(chunks.is_walkable(main.player.global_tile))


func test_manual_movement_cancels_world_tap_approach() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.player.set_world_position(Vector2(-96.0, 40.0))
	var harrow = main.entities.get_entity("npc_harrow_venn_world")

	assert_true(MainInputRouter.target_world(main, harrow.global_position))
	main.player.set_external_move_vector(Vector2.LEFT)
	MainInputRouter.update_auto_interaction(main, 0.016)

	assert_eq(main.auto_interact_target_id, "")
	assert_false(main.hud.is_content_card_visible())


func test_manual_movement_cancels_empty_ground_move() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var destination: Vector2 = GridMath.tile_to_world(Vector2i(0, -1)) + Vector2(8.0, 8.0)

	assert_true(MainInputRouter.move_to_world(main, destination))
	main.player.set_external_move_vector(Vector2.LEFT)
	MainInputRouter.update_auto_interaction(main, 0.016)

	assert_false(main.auto_move_active)
	assert_ne(main.get_debug_state()["primary_action"], "Stop")


func test_primary_button_cancels_world_tap_approach() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.player.set_world_position(Vector2(-96.0, 40.0))
	var harrow = main.entities.get_entity("npc_harrow_venn_world")

	assert_true(MainInputRouter.target_world(main, harrow.global_position))
	main._handle_interact_requested()

	assert_eq(main.auto_interact_target_id, "")
	assert_false(main.manual_target_locked)
	assert_true(main.hud.log_label.text.contains("Stopped."))


func test_primary_button_cancels_empty_ground_move() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var destination: Vector2 = GridMath.tile_to_world(Vector2i(0, -1)) + Vector2(8.0, 8.0)

	assert_true(MainInputRouter.move_to_world(main, destination))
	main._handle_interact_requested()

	assert_false(main.auto_move_active)
	assert_true(main.hud.log_label.text.contains("Stopped."))
