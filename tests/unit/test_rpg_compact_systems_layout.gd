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


func test_navigation_controls_use_icon_buttons() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("spells")

	for child in hud.top_nav_buttons.get_children():
		assert_true(child is RpgIconButton)
		assert_eq((child as RpgIconButton).icon_layout, "top")
	for tab_id in ["inventory", "spells", "character", "quests", "map", "journal", "trade"]:
		var button := hud.systems_tab_buttons[tab_id] as RpgIconButton
		assert_not_null(button)
		assert_eq(button.icon_kind, tab_id)
		assert_eq(button.icon_layout, "left")
	assert_true(bool((hud.systems_tab_buttons["spells"] as Button).get_meta("nav_selected")))

	hud._apply_layout_for_size(Vector2(640, 360))
	assert_true((hud.top_nav_buttons.get_child(0) as RpgIconButton).compact)
	assert_true((hud.systems_tab_buttons["inventory"] as RpgIconButton).compact)


func test_action_cluster_utility_controls_use_icon_buttons() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))
	var utility_stack := hud.action_buttons.find_child("UtilityButtonStack", true, false)
	assert_not_null(utility_stack)
	for id in ["inventory", "target", "menu"]:
		var button := utility_stack.find_child("%sButton" % id.to_pascal_case(), true, false)
		assert_true(button is RpgIconButton)
		assert_eq((button as RpgIconButton).icon_kind, id)
		assert_eq((button as RpgIconButton).icon_layout, "top")


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
	assert_false(ask.text.begins_with("D  "))
	assert_false(turn_in.text.begins_with("Q  "))
	assert_false(forge.text.begins_with("S  "))


func test_content_identity_icon_matches_content_kind() -> void:
	var hud := _new_hud()
	var art := hud.content_portrait_panel.find_child(
		"ContentPortraitSilhouette", true, false
	) as RpgPortraitSilhouette
	assert_not_null(art)
	hud.show_content_card("Harrow Venn", "Hello.", [], "dialogue")
	assert_eq(art.identity_kind, "person")
	hud.show_content_card("Road Notice", "Read this.", [], "readable")
	assert_eq(art.identity_kind, "readable")
	hud.show_content_card("Briarwatch Square", "Town green.", [], "place")
	assert_eq(art.identity_kind, "place")
	hud.show_content_card("Done", "Complete.", [], "response")
	assert_eq(art.identity_kind, "response")


func test_desktop_quick_actions_do_not_cover_action_cluster() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud._refresh_context_actions(
		{
			"nearby": "Rest Bridge Campfire",
			"context_actions":
			[
				{"id": "dialogue:accept", "text": "I'll find it."},
				{"id": "poi:sharpen", "text": "Sharpen Road Hatchet"},
				{"id": "trade:shop_crossroads_peddler", "text": "Trade"}
			]
		}
	)

	var quick_rect := _anchored_rect(hud.context_action_panel, Vector2(1152, 648))
	for action_rect in _visible_button_rects(hud.action_buttons):
		assert_false(quick_rect.intersects(action_rect))


func test_desktop_target_picker_does_not_cover_action_cluster() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.toggle_target_picker()

	var target_rect := _anchored_rect(hud.target_panel, Vector2(1152, 648))
	for action_rect in _visible_button_rects(hud.action_buttons):
		assert_false(target_rect.intersects(action_rect))


func test_desktop_systems_character_pane_scrolls_when_visible() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("inventory")

	assert_true(hud.systems_character_panel.visible)
	assert_not_null(hud.systems_character_panel.find_child("SystemsCharacterScroll", true, false))


func test_desktop_inventory_categories_use_tight_widths() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("inventory")

	var all := _button_containing(hud.systems_category_row, "All") as Button
	var ingredients := _button_containing(hud.systems_category_row, "Ingredients") as Button
	assert_eq(all.custom_minimum_size.x, 52.0)
	assert_eq(ingredients.custom_minimum_size.x, 88.0)


func test_ability_joysticks_need_drag_direction_before_casting() -> void:
	var hud := _new_hud()
	var events: Array[Dictionary] = []
	hud.aim_action_released.connect(
		func(action_id: String, direction: Vector2) -> void:
			events.append({"action_id": action_id, "direction": direction})
	)
	var ability := hud.ability_slot_buttons["ability_1"] as RpgAimJoystick
	ability._start_aim(Vector2.ZERO)
	ability._finish_aim(Vector2(2, 2))
	assert_true(events.is_empty())
	ability._start_aim(Vector2.ZERO)
	ability._finish_aim(Vector2(32, 0))
	assert_eq(events[0]["action_id"], "ability_1")
	assert_eq(events[0]["direction"], Vector2.RIGHT)


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


func _visible_button_rects(parent: Node) -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for child in parent.get_children():
		if child is Button and child.visible:
			rects.append((child as Button).get_global_rect())
		rects.append_array(_visible_button_rects(child))
	return rects


func _anchored_rect(panel: Control, viewport_size: Vector2) -> Rect2:
	var left := panel.anchor_left * viewport_size.x + panel.offset_left
	var right := panel.anchor_right * viewport_size.x + panel.offset_right
	var top := panel.anchor_top * viewport_size.y + panel.offset_top
	var bottom := panel.anchor_bottom * viewport_size.y + panel.offset_bottom
	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))
