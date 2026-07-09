extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainFlowInputHelper = preload("res://tests/unit/main/flows/main_flow_input_helper.gd")


func test_training_sword_unlocks_nearby_access_object() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "object_training_gate")
	assert_eq(main.get_debug_state()["target_detail"], "Door: locked")
	MainFlowInputHelper.interact_action(main)
	assert_false(main.world_state.has_flag("flag_training_gate_opened"))
	assert_false(main.chunks.is_object_opened("object_training_gate", Vector2i(3, 8)))
	assert_true(main.hud.log_label.text.contains("notched for a training sword"))

	assert_true(main.inventory.add_item("item_training_sword", 1))

	_select_entity(main, "object_training_gate")
	assert_eq(main.get_debug_state()["target_detail"], "Door: closed")
	MainFlowInputHelper.interact_action(main)

	assert_true(main.world_state.has_flag("flag_training_gate_opened"))
	assert_true(main.chunks.is_object_opened("object_training_gate", Vector2i(3, 8)))
	assert_eq(main.time.get_summary(), "Day 1, 08:05 (Morning)")
	assert_eq(main.get_debug_state()["target_detail"], "Door: opened")


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
		MainFlowInputHelper.cycle_target_action(main)
	fail_test("Could not select nearby entity: %s" % entity_id)
