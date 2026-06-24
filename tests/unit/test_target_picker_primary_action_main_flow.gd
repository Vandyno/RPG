extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_primary_action_uses_selected_target_when_target_picker_is_open() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var notice = main.entities.get_entity("object_road_notice")
	main.player.set_world_position(notice.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()

	main._handle_target_selected("object_road_notice")
	main.hud.toggle_target_picker()
	assert_true(main.hud.is_target_picker_visible())
	assert_eq(main.get_debug_state()["primary_action"], "Read")
	assert_eq(main.hud.primary_action_button.text, "Attack")

	main._handle_interact_requested()

	assert_false(main.hud.is_target_picker_visible())
	assert_true(main.hud.is_content_card_visible())
	assert_true(main.hud.content_title_label.text.contains("Road Notice"))


func test_selected_target_picker_row_uses_target_directly() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var notice = main.entities.get_entity("object_road_notice")
	main.player.set_world_position(notice.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()

	main._handle_target_selected("object_road_notice")
	main.hud.toggle_target_picker()
	assert_true(main.hud.is_target_picker_visible())
	var selected_row := _selected_button_containing(main.hud.target_list, "Road Notice")
	assert_not_null(selected_row)
	assert_true(selected_row.text.contains("Read"))
	assert_false(selected_row.text.contains("Read - Readable"))
	assert_false(selected_row.text.contains("Selected:"))

	selected_row.pressed.emit()

	assert_false(main.hud.is_target_picker_visible())
	assert_true(main.hud.is_content_card_visible())
	assert_true(main.hud.content_title_label.text.contains("Road Notice"))


func test_unselected_target_picker_row_uses_target_directly() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var notice = main.entities.get_entity("object_road_notice")
	main.player.set_world_position(notice.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()

	main._handle_target_selected("object_road_notice")
	main.hud.toggle_target_picker()
	assert_true(main.hud.is_target_picker_visible())
	var strongbox_row := _button_containing(main.hud.target_list, "Sealed Strongbox")
	assert_not_null(strongbox_row)
	assert_false(strongbox_row.text.contains("Selected:"))
	assert_false(bool(strongbox_row.get_meta("selected_target", false)))

	strongbox_row.pressed.emit()

	assert_false(main.hud.is_target_picker_visible())
	assert_eq(main.selected_target_id, "object_sealed_strongbox")


func _selected_button_containing(container: Control, text: String) -> Button:
	for child in container.get_children():
		if (
			child is Button
			and child.text.contains(text)
			and bool(child.get_meta("selected_target", false))
		):
			return child
	return null


func _button_containing(container: Control, text: String) -> Button:
	for child in container.get_children():
		if child is Button and child.text.contains(text):
			return child
	return null
