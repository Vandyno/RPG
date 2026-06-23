extends GutTest


func test_compact_system_rows_wrap_long_player_text() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))
	hud.show_systems_panel("trade")

	var row := _button_containing(hud.systems_item_list, "Roadside Draught")
	assert_not_null(row)
	assert_eq(row.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
	assert_gte(row.custom_minimum_size.y, 82.0)
	assert_true(row.text.contains("Crossroads Peddler"))


func test_trade_rows_use_trade_card_icons() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("trade")

	var stock := _button_containing(hud.systems_item_list, "Roadside Draught")
	var merchant := _button_containing(hud.systems_item_list, "Crossroads Peddler")
	assert_not_null(stock)
	assert_not_null(merchant)
	assert_eq(stock.get_meta("card_icon"), "T")
	assert_eq(merchant.get_meta("card_icon"), "T")


func test_system_rows_render_player_facing_card_data() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("inventory")

	var row := _button_containing(hud.systems_item_list, "Roadside Draught")
	assert_not_null(row)
	assert_true(row is RpgInventoryItemButton)
	assert_eq(row.get_meta("card_title"), "Roadside Draught")
	assert_eq(row.get_meta("card_icon"), "I")
	assert_eq(row.get_meta("card_meta"), "Misc")
	assert_true(String(row.get_meta("card_detail")).contains("Count 1"))


func test_detail_pane_uses_player_facing_renderer() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("inventory")

	assert_true(hud.systems_detail_label is RpgDetailLabel)
	assert_true(hud.systems_detail_label.text.contains("Roadside Draught x1"))
	assert_true(hud.systems_detail_label.text.contains("A bitter green tonic."))


func test_detail_equipment_pane_has_section_header_and_tight_slots() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("inventory")

	var title := hud.systems_detail_panel.find_child("SystemsDetailEquipmentTitle", true, false)
	var right := hud.systems_detail_panel.find_child("EquipmentSlot_RightHand", true, false) as Button
	assert_not_null(title)
	assert_eq((title as Label).text, "Equipment")
	assert_not_null(right)
	assert_eq(right.custom_minimum_size.y, 38.0)
	assert_true(right.text.begins_with("R Hand\n"))


func test_spell_categories_use_compact_readable_labels() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))
	hud.show_systems_panel("spells")

	var restore := _button_containing(hud.systems_category_row, "Restore")
	assert_not_null(restore)
	restore.pressed.emit()
	assert_eq(hud.systems_active_category, "restoration")
	assert_null(_button_containing(hud.systems_category_row, "Restoration"))


func test_dialogue_choices_use_player_facing_action_icons() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_content_card(
		"Harrow Venn",
		"What can I do for you?",
		[
			{"id": "ask", "text": "Ask about tools"},
			{
				"id": "turn_in",
				"text": "Turn in Toolbox",
				"effects": [{"type": "complete_quest", "quest_id": "quest_missing_tools"}]
			},
			{"id": "forge", "text": "Forge Services"}
		],
		"dialogue"
	)

	var ask := _button_containing(hud.content_choice_list, "Ask about tools") as Button
	var turn_in := _button_containing(hud.content_choice_list, "Turn in Toolbox") as Button
	var forge := _button_containing(hud.content_choice_list, "Forge Services") as Button
	assert_true(ask.text.begins_with("D  "))
	assert_true(turn_in.text.begins_with("Q  "))
	assert_true(forge.text.begins_with("S  "))


func _new_hud() -> RpgHud:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := RpgHud.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_sample_state"))
	return hud


func _sample_state() -> Dictionary:
	return {
		"player_health": "100/100",
		"player_health_value": 100,
		"player_max_health": 100,
		"locations": "Briarwatch Crossroads",
		"inventory": "Roadside Draught x1",
		"inventory_items":
		[
			{
				"item_id": "item_roadside_draught",
				"name": "Roadside Draught",
				"count": 1,
				"type": "consumable",
				"tags": ["consumable"],
				"value": 12,
				"weight": 0.3,
				"description": "A bitter green tonic."
			}
		],
		"spells":
		[
			{
				"spell_id": "spell_fire_blast",
				"name": "Fire Blast",
				"school": "Fire",
				"mana_cost": 5,
				"range": "6 tiles",
				"behavior": "Launches a direct burst of flame at the selected target.",
				"assigned_label": "Ability I"
			}
		],
		"spell_slots":
		{
			"ability_1":
			{
				"slot": "ability_1",
				"slot_label": "Ability I",
				"spell_id": "spell_fire_blast",
				"name": "Fire Blast",
				"mana_cost": 5
			},
			"ability_2": {"slot": "ability_2", "slot_label": "Ability II", "spell_id": ""},
			"ability_3": {"slot": "ability_3", "slot_label": "Ability III", "spell_id": ""}
		},
		"trade":
		(
			"Crossroads Peddler\n"
			+ "Hours: 08:00-18:00\n"
			+ "Gold: 25\n\n"
			+ "Stock:\n"
			+ "- Roadside Draught: 8g\n\n"
			+ "Sell: none"
		),
		"trade_actions": [{"id": "buy:item_roadside_draught", "text": "Buy Roadside Draught"}],
		"time": "Day 1, 08:00"
	}


func _button_containing(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.visible and child.text.contains(text):
			return child
	return null
