extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_door_open_conditions_gate_route_effects_until_unlocked() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "object_north_gate")
	assert_eq(main.get_debug_state()["target_detail"], "Door: locked")
	assert_eq(main.get_debug_state()["primary_action"], "Locked")
	main._handle_interact_requested()
	assert_false(main.world_state.has_flag("flag_north_gate_opened"))
	assert_false(main.chunks.is_object_opened("object_north_gate", Vector2i(0, -7)))
	assert_true(main.hud.log_label.text.contains("north gate chain"))

	_select_entity(main, "object_road_notice")
	main._handle_interact_requested()
	main.hud.hide_content_card()
	_select_entity(main, "object_north_gate")
	assert_eq(main.get_debug_state()["target_detail"], "Door: closed")
	assert_eq(main.get_debug_state()["primary_action"], "Open")
	main._handle_interact_requested()

	assert_true(main.world_state.has_flag("flag_north_gate_opened"))
	assert_true(main.chunks.is_object_opened("object_north_gate", Vector2i(0, -7)))
	assert_eq(main.time.get_summary(), "Day 1, 08:15 (Morning)")
	assert_eq(main.get_debug_state()["target_detail"], "Door: opened")
	assert_eq(main.get_debug_state()["primary_action"], "Opened")

	main._handle_interact_requested()
	assert_true(main.hud.log_label.text.contains("North Gate is already open."))


func _select_entity(main, entity_id: String) -> void:
	for _i in range(32):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)
