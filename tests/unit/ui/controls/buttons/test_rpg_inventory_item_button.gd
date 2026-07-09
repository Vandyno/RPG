extends GutTest

const RpgInventoryItemButton = preload(
	"res://scripts/ui/controls/buttons/rpg_inventory_item_button.gd"
)


func test_set_card_data_stores_card_metadata_and_hides_native_text() -> void:
	var button := RpgInventoryItemButton.new()
	add_child_autofree(button)

	button.set_card_data(
		{
			"title": "Road Hatchet",
			"meta": "Weapon",
			"subtitle": "A sturdy trail tool.",
			"equipment_slot": "right_hand"
		}
	)

	assert_eq(button.get_meta("card_icon"), "W")
	assert_eq(button.get_meta("card_title"), "Road Hatchet")
	assert_eq(button.get_meta("card_meta"), "Weapon")
	assert_eq(button.get_meta("card_detail"), "A sturdy trail tool.")
	assert_eq(button.get_theme_color("font_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_hover_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_pressed_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_focus_color"), Color.TRANSPARENT)


func test_card_icon_classifies_rows_by_player_facing_text() -> void:
	var button := RpgInventoryItemButton.new()
	add_child_autofree(button)

	assert_eq(button._card_icon({"meta": "Weapon"}), "W")
	assert_eq(button._card_icon({"title": "Traveler Shield"}), "A")
	assert_eq(button._card_icon({"subtitle": "Ingredient"}), "G")
	assert_eq(button._card_icon({"meta": "Quest item"}), "Q")
	assert_eq(button._card_icon({"subtitle": "Spell school: Fire"}), "S")
	assert_eq(button._card_icon({"title": "Known Route Map"}), "M")
	assert_eq(button._card_icon({"title": "Journal Log"}), "J")
	assert_eq(button._card_icon({"subtitle": "Buy from merchant shop"}), "T")
	assert_eq(button._card_icon({"title": "Health Vitals"}), "H")
	assert_eq(button._card_icon({"title": "River Mint"}), "I")


func test_drag_payload_prefers_spell_payload() -> void:
	var button := RpgInventoryItemButton.new()
	add_child_autofree(button)
	button.set_meta("spell_id", "spell_fire_blast")
	button.set_meta("item_id", "item_road_hatchet")
	button.set_meta("equipment_slot", "right_hand")

	assert_eq(button._drag_payload(), {"type": "spell", "spell_id": "spell_fire_blast"})


func test_drag_payload_uses_inventory_item_with_equipment_slot() -> void:
	var button := RpgInventoryItemButton.new()
	add_child_autofree(button)
	button.set_meta("item_id", "item_road_hatchet")
	button.set_meta("equipment_slot", "right_hand")

	assert_eq(
		button._drag_payload(),
		{"type": "inventory_item", "item_id": "item_road_hatchet", "equipment_slot": "right_hand"}
	)


func test_drag_payload_is_empty_without_complete_drag_metadata() -> void:
	var button := RpgInventoryItemButton.new()
	add_child_autofree(button)

	assert_true(button._drag_payload().is_empty())
	button.set_meta("item_id", "item_road_hatchet")
	assert_true(button._drag_payload().is_empty())
	button.set_meta("item_id", "")
	button.set_meta("equipment_slot", "right_hand")
	assert_true(button._drag_payload().is_empty())


func test_get_drag_data_returns_payload_and_frees_preview_when_not_dragging() -> void:
	var button := RpgInventoryItemButton.new()
	add_child_autofree(button)
	button.text = "Road Hatchet\nWeapon"
	button.set_meta("item_id", "item_road_hatchet")
	button.set_meta("equipment_slot", "right_hand")

	assert_eq(
		button._get_drag_data(Vector2.ZERO),
		{"type": "inventory_item", "item_id": "item_road_hatchet", "equipment_slot": "right_hand"}
	)


func test_preview_text_uses_first_text_line_or_item_id_fallback() -> void:
	var button := RpgInventoryItemButton.new()
	add_child_autofree(button)
	button.text = "Fire Blast\nCost 3"
	assert_eq(button._preview_text(), "Fire Blast")

	button.text = ""
	button.set_meta("item_id", "item_road_hatchet")
	assert_eq(button._preview_text(), "item_road_hatchet")


func test_gui_input_tracks_mouse_and_touch_drag_start() -> void:
	var button := RpgInventoryItemButton.new()
	add_child_autofree(button)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.pressed = true
	mouse.position = Vector2(4, 5)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(9, 10)

	button._gui_input(mouse)
	assert_true(button.drag_pointer_down)
	assert_eq(button.drag_start, Vector2(4, 5))
	mouse.pressed = false
	button._gui_input(mouse)
	assert_false(button.drag_pointer_down)

	button._gui_input(touch)
	assert_true(button.drag_pointer_down)
	assert_eq(button.drag_start, Vector2(9, 10))
