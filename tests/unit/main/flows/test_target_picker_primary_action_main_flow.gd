extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainFlowInputHelper = preload("res://tests/unit/main/flows/main_flow_input_helper.gd")


func test_rpg_target_picker_is_disabled() -> void:
	var main := Main.new()
	add_child_autofree(main)

	main.hud.toggle_target_picker()

	assert_false(main.hud.is_target_picker_visible())
	assert_null(main.hud.target_panel)
	assert_eq(main.hud.target_action_button.text, "Sneak")


func test_sneak_button_does_not_select_or_use_targets() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var notice = main.entities.get_entity("object_road_notice")
	main.player.set_world_position(notice.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	var selected_before := main.selected_target_id

	await MainFlowInputHelper.click(main.hud.target_action_button, get_tree())

	assert_true(main.player.is_sneaking)
	assert_eq(main.hud.message_log[-1], "Sneaking.")
	assert_false(main.hud.is_target_picker_visible())
	assert_eq(main.selected_target_id, selected_before)
	assert_false(main.hud.is_content_card_visible())
