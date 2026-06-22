extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_training_stat_unlocks_nearby_access_object() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "object_training_gate")
	assert_eq(main.get_debug_state()["target_detail"], "Door: locked")
	main._handle_interact_requested()
	assert_false(main.world_state.has_flag("flag_training_gate_opened"))
	assert_false(main.chunks.is_object_opened("object_training_gate", Vector2i(-7, 1)))
	assert_true(main.hud.log_label.text.contains("counterweight needs a stronger pull"))

	main.progression.load_save_data({"level": 2, "skill_points": 1})
	main._refresh_hud()
	main.hud.toggle_systems()
	main.hud.set_systems_tab("character")
	var train_might_button := _button_containing(main.hud.systems_action_list, "Train Might")
	assert_not_null(train_might_button)
	train_might_button.pressed.emit()
	main.hud.hide_systems_panel()

	_select_entity(main, "object_training_gate")
	assert_eq(main.get_debug_state()["target_detail"], "Door: closed")
	main._handle_interact_requested()

	assert_true(main.world_state.has_flag("flag_training_gate_opened"))
	assert_true(main.chunks.is_object_opened("object_training_gate", Vector2i(-7, 1)))
	assert_eq(main.time.get_summary(), "Day 1, 08:05 (Morning)")
	assert_eq(main.get_debug_state()["target_detail"], "Door: opened")


func _select_entity(main, entity_id: String) -> void:
	for _i in range(32):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)


func _button_containing(container: Node, text: String) -> Button:
	for child in container.get_children():
		if child is Button and child.text.contains(text):
			return child
	return null
