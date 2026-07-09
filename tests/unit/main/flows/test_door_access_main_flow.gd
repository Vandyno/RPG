extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainFlowInputHelper = preload("res://tests/unit/main/flows/main_flow_input_helper.gd")


func test_door_open_conditions_gate_route_effects_until_unlocked() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "object_north_gate")
	assert_eq(main.get_debug_state()["target_detail"], "Door: locked")
	assert_eq(main.get_debug_state()["primary_action"], "Locked")
	main._handle_interact_requested()
	assert_false(main.world_state.has_flag("flag_north_gate_opened"))
	assert_false(main.chunks.is_object_opened("object_north_gate", Vector2i(3, -8)))
	assert_true(main.hud.log_label.text.contains("north gate chain"))

	_select_entity(main, "object_road_notice")
	main._handle_interact_requested()
	main.hud.hide_content_card()
	_select_entity(main, "object_north_gate")
	assert_eq(main.get_debug_state()["target_detail"], "Door: closed")
	assert_eq(main.get_debug_state()["primary_action"], "Open")
	main._handle_interact_requested()

	assert_true(main.world_state.has_flag("flag_north_gate_opened"))
	assert_true(main.chunks.is_object_opened("object_north_gate", Vector2i(3, -8)))
	assert_eq(main.time.get_summary(), "Day 1, 08:15 (Morning)")
	assert_eq(main.get_debug_state()["target_detail"], "Door: opened")
	assert_eq(main.get_debug_state()["primary_action"], "Opened")

	main._handle_interact_requested()
	assert_true(main.hud.log_label.text.contains("North Gate is already open."))


func test_forge_portal_door_real_click_enters_and_exits_interior() -> void:
	var main := Main.new()
	add_child_autofree(main)

	var entrance = main.entities.get_entity("object_harrow_forge_door")
	assert_not_null(entrance)
	main.player.set_world_position(entrance.global_position + Vector2(-12.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	await MainFlowInputHelper.world_click(main, entrance.global_position, get_tree())

	assert_eq(main.player.world_layer, "interior:structure_briarwatch_harrow_forge")
	assert_eq(main.player.global_tile, Vector2i(5, 6))
	assert_null(main.entities.get_entity("object_harrow_forge_door"))
	var exit = main.entities.get_entity("object_harrow_forge_exit")
	assert_not_null(exit)
	assert_not_null(main.entities.get_entity("poi_harrow_forge_hearth"))
	assert_true(main.hud.log_label.text.contains("Entered Harrow's Forge."))

	await MainFlowInputHelper.world_click(main, exit.global_position, get_tree())

	assert_eq(main.player.world_layer, "surface")
	assert_eq(main.player.global_tile, Vector2i(8, 1))
	assert_not_null(main.entities.get_entity("object_harrow_forge_door"))
	assert_null(main.entities.get_entity("object_harrow_forge_exit"))
	assert_true(main.hud.log_label.text.contains("Stepped back into Briarwatch."))


func _select_entity(main, entity_id: String) -> void:
	var target = main.entities.get_entity(entity_id)
	if target:
		main.player.set_world_position(target.global_position + Vector2(-8.0, 0.0))
		main.player.set_facing_direction(Vector2.RIGHT)
		main._update_nearby()
	for _i in range(32):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)
