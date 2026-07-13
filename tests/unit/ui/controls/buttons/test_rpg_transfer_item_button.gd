extends GutTest

const RpgTransferItemButton = preload(
	"res://scripts/ui/controls/buttons/rpg_transfer_item_button.gd"
)


func test_set_transfer_data_populates_button_state_and_accessible_text() -> void:
	var button := RpgTransferItemButton.new()
	add_child_autofree(button)

	button.set_transfer_data(
		{"name": "Old Toolbox", "count": 2, "value": 12, "weight": 3.5},
		"Take",
		"Inventory"
	)

	assert_eq(button.item_name, "Old Toolbox")
	assert_eq(button.item_count, 2)
	assert_eq(button.action_label, "Take")
	assert_eq(button.destination_label, "Inventory")
	assert_eq(button.value, 12)
	assert_eq(button.weight, 3.5)
	assert_eq(button.text, "Old Toolbox x2 Take to Inventory")
	assert_false(button.clip_text)


func test_set_transfer_data_uses_item_id_fallback_and_clamps_bad_numbers() -> void:
	var button := RpgTransferItemButton.new()
	add_child_autofree(button)

	button.set_transfer_data(
		{"item_id": "item_road_hatchet", "count": -4, "value": -10, "weight": -2.0},
		"Put",
		"Chest"
	)

	assert_eq(button.item_name, "item_road_hatchet")
	assert_eq(button.item_count, 0)
	assert_eq(button.value, 0)
	assert_eq(button.weight, 0.0)
	assert_eq(button.text, "item_road_hatchet x0 Put to Chest")


func test_set_transfer_data_falls_back_to_item_label_when_name_and_id_missing() -> void:
	var button := RpgTransferItemButton.new()
	add_child_autofree(button)

	button.set_transfer_data({}, "Move", "Storage")

	assert_eq(button.item_name, "Item")
	assert_eq(button.text, "Item x0 Move to Storage")


func test_set_transfer_data_hides_native_button_text_for_custom_drawn_label() -> void:
	var button := RpgTransferItemButton.new()
	add_child_autofree(button)

	button.set_transfer_data({"name": "Mint", "count": 1}, "Take", "Inventory")

	assert_eq(button.get_theme_color("font_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_hover_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_pressed_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_focus_color"), Color.TRANSPARENT)
