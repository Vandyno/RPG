extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_primary_action_uses_selected_target_when_target_picker_is_open() -> void:
	var main := Main.new()
	add_child_autofree(main)

	main._handle_target_selected("object_road_notice")
	main.hud.toggle_target_picker()
	assert_true(main.hud.is_target_picker_visible())
	assert_eq(main.hud.primary_action_button.text, "Read")

	main._handle_interact_requested()

	assert_false(main.hud.is_target_picker_visible())
	assert_true(main.hud.is_content_card_visible())
	assert_true(main.hud.content_title_label.text.contains("Road Notice"))


func test_selected_target_picker_row_uses_target_directly() -> void:
	var main := Main.new()
	add_child_autofree(main)

	main._handle_target_selected("object_road_notice")
	main.hud.toggle_target_picker()
	assert_true(main.hud.is_target_picker_visible())
	var selected_row := _selected_button_containing(main.hud.target_list, "Road Notice")
	assert_not_null(selected_row)

	selected_row.pressed.emit()

	assert_false(main.hud.is_target_picker_visible())
	assert_true(main.hud.is_content_card_visible())
	assert_true(main.hud.content_title_label.text.contains("Road Notice"))


func test_unselected_target_picker_row_uses_target_directly() -> void:
	var main := Main.new()
	add_child_autofree(main)

	main._handle_target_selected("object_road_notice")
	main.hud.toggle_target_picker()
	assert_true(main.hud.is_target_picker_visible())
	var harrow_row := _button_containing(main.hud.target_list, "Harrow Venn")
	assert_not_null(harrow_row)
	assert_false(harrow_row.text.contains("Current Target"))

	harrow_row.pressed.emit()

	assert_false(main.hud.is_target_picker_visible())
	assert_eq(main.selected_target_id, "npc_harrow_venn_world")
	assert_true(main.hud.is_content_card_visible())
	assert_true(main.hud.content_body_label.text.contains("need my old toolbox"))


func _selected_button_containing(container: Control, text: String) -> Button:
	for child in container.get_children():
		if child is Button and child.text.contains("Current Target") and child.text.contains(text):
			return child
	return null


func _button_containing(container: Control, text: String) -> Button:
	for child in container.get_children():
		if child is Button and child.text.contains(text):
			return child
	return null
