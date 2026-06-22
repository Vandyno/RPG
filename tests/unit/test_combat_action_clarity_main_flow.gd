extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_enemy_attack_is_primary_and_guard_is_only_context_action() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "enemy_road_thug")

	assert_eq(main.get_debug_state()["primary_action"], "Attack")
	assert_true(main.hud.context_action_panel.visible)
	assert_null(_visible_button_containing(main.hud.context_action_buttons, "Attack"))
	assert_not_null(_visible_button_containing(main.hud.context_action_buttons, "Guard"))


func test_guard_stance_hides_redundant_guard_action_until_attack() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "enemy_road_thug")
	var guard := _visible_button_containing(main.hud.context_action_buttons, "Guard")
	assert_not_null(guard)

	guard.pressed.emit()

	assert_eq(main.get_debug_state()["primary_action"], "Attack")
	assert_eq(main.get_debug_state()["target_detail"], "Enemy HP 12/12, counter 4, guarding")
	assert_false(main.hud.context_action_panel.visible)

	main._handle_interact_requested()

	assert_eq(main.get_debug_state()["target_detail"], "Enemy HP 6/12, counter 4")
	assert_true(main.hud.context_action_panel.visible)
	assert_not_null(_visible_button_containing(main.hud.context_action_buttons, "Guard"))


func _select_entity(main, entity_id: String) -> void:
	for _i in range(40):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			main._update_nearby()
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)


func _visible_button_containing(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.visible and child.text.contains(text):
			return child
	return null
