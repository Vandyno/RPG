extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainFlowInputHelper = preload("res://tests/unit/main/flows/main_flow_input_helper.gd")


func test_world_quest_marker_tracks_objective_target_changes() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "npc_harrow_venn_world")
	main._handle_interact_requested()
	_choose_content(main, "I'll find it.")
	assert_true(MainFlowInputHelper.exit_forge_direct(main))

	assert_true(main.entities.get_entity("pickup_old_toolbox").quest_marker_visible)
	assert_false(main.entities.get_entity("object_harrow_forge_door").quest_marker_visible)
	main.hud.show_systems_panel("quests")
	var target_toolbox := _button_containing(main.hud.systems_action_list, "Target Old Toolbox")
	assert_not_null(target_toolbox)
	target_toolbox.pressed.emit()
	assert_false(main.hud.is_systems_panel_visible())
	assert_true(main.entities.get_entity("pickup_old_toolbox").quest_marker_visible)
	main.auto_interact_target_id = ""
	main.auto_move_path = []

	main.hud.hide_content_card()
	_select_entity(main, "pickup_old_toolbox")
	main._handle_interact_requested()

	assert_null(main.entities.get_entity("pickup_old_toolbox"))
	assert_true(main.entities.get_entity("object_harrow_forge_door").quest_marker_visible)

	_select_entity(main, "npc_harrow_venn_world")
	main._handle_interact_requested()

	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "completed")
	assert_false(main.entities.get_entity("npc_harrow_venn_world").quest_marker_visible)


func _select_entity(main, entity_id: String) -> void:
	var target = main.entities.get_entity(entity_id)
	if not target:
		if entity_id == "npc_harrow_venn_world":
			MainFlowInputHelper.enter_forge_direct(main)
		elif main.player.world_layer != "surface":
			MainFlowInputHelper.exit_forge_direct(main)
		target = main.entities.get_entity(entity_id)
	if target:
		main.player.set_world_position(target.global_position + Vector2(-8.0, 0.0))
		main.player.set_facing_direction(Vector2.RIGHT)
		main._update_nearby()
	for _i in range(24):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)


func _choose_content(main, text: String) -> void:
	var button := _button_containing(main.hud.content_choice_list, text)
	assert_not_null(button)
	button.pressed.emit()


func _button_containing(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text.contains(text):
			return child
	return null
