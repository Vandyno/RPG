extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_quest_feedback_reports_start_stage_and_completion_rewards() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "npc_harrow_venn_world")
	main._handle_interact_requested()
	_choose_content(main, "I'll find it.")

	assert_true(main.hud.log_label.text.contains("Quest started: The Missing Tools."))

	main.hud.hide_content_card()
	_select_entity(main, "pickup_old_toolbox")
	main._handle_interact_requested()

	assert_true(main.hud.log_label.text.contains("Picked up Old Toolbox"))
	assert_true(main.hud.log_label.text.contains("Quest updated: The Missing Tools."))

	_select_entity(main, "npc_harrow_venn_world")
	main._handle_interact_requested()

	assert_true(main.hud.log_label.text.contains("Quest complete: The Missing Tools."))
	assert_true(main.hud.log_label.text.contains("Gold Coin x25"))
	assert_true(main.hud.log_label.text.contains("Marches of Velcor +5"))
	assert_true(main.hud.log_label.text.contains("XP +20"))


func test_container_feedback_reports_rewards_before_open_confirmation_scrolls_away() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "object_road_cache")
	main._handle_interact_requested()

	assert_true(main.hud.log_label.text.contains("Gained Gold Coin x2."))
	assert_true(main.hud.log_label.text.contains("XP +2."))
	assert_true(main.hud.log_label.text.contains("Opened Roadside Cache."))


func test_combat_defeat_feedback_keeps_defeat_and_reward_summary_visible() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "enemy_road_thug")
	main._handle_interact_requested()
	main._handle_interact_requested()

	assert_true(main.hud.log_label.text.contains("Defeated Road Thug."))
	assert_true(main.hud.log_label.text.contains("Rewards: Gold Coin x3, Road Bandits -5, XP +10."))


func _select_entity(main, entity_id: String) -> void:
	var target = main.entities.get_entity(entity_id)
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
