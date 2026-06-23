extends GutTest

const EventBus = preload("res://scripts/core/event_bus.gd")
const Main = preload("res://scripts/main/main.gd")
const RpgHud = preload("res://scripts/ui/rpg_hud.gd")


func test_main_uses_player_facing_rpg_hud() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_eq(main.hud.name, "RpgHud")
	assert_true(main.hud is RpgHud)
	assert_eq(main.get_hud_state()["primary_action"], main.get_debug_state()["primary_action"])
	assert_true(main.hud.get_state.get_method() == "get_hud_state")


func test_rpg_hud_adds_mockup_style_navigation_without_debug_prompt() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))

	assert_false(hud.prompt_panel.visible)
	assert_true(hud.location_banner_panel.visible)
	assert_eq(hud.location_banner_label.text, "Briarwatch")
	assert_true(hud.top_nav_panel.visible)
	assert_eq(_button_texts(hud.top_nav_buttons), ["Quests", "Journal", "Map", "Menu"])
	assert_true(hud.status_label.text.contains("Adventurer"))
	assert_true(hud.status_label.text.contains("Level 2"))
	assert_true(hud.status_label.text.contains("Quest: The Missing Tools"))
	assert_false(hud.status_label.text.contains("Briarwatch  Day"))
	assert_false(hud.debug_panel.visible)
	hud.toggle_debug()
	assert_false(hud.debug_panel.visible)

	var screen := Rect2(Vector2.ZERO, Vector2(1152, 648))
	var status_rect := _top_left_rect(hud.status_panel)
	var banner_rect := _center_top_rect(hud.location_banner_panel, Vector2(1152, 648))
	var nav_rect := _right_rect(hud.top_nav_panel, Vector2(1152, 648))
	var message_rect := _bottom_left_rect(hud.message_panel, Vector2(1152, 648))

	assert_true(_rect_inside(status_rect, screen), "Status panel should stay on screen.")
	assert_true(_rect_inside(banner_rect, screen), "Location banner should stay on screen.")
	assert_true(_rect_inside(nav_rect, screen), "Top nav should stay on screen.")
	assert_false(status_rect.intersects(banner_rect), "Status should not cover location.")
	assert_false(banner_rect.intersects(nav_rect), "Location should not cover nav.")
	assert_false(nav_rect.intersects(message_rect), "Top nav should not cover messages.")


func test_rpg_hud_top_nav_controls_real_systems_panel() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))

	_press_nav(hud, "Quests")
	assert_true(hud.is_systems_panel_visible())
	assert_eq(hud.get_systems_tab(), "quests")

	_press_nav(hud, "Journal")
	assert_true(hud.is_systems_panel_visible())
	assert_eq(hud.get_systems_tab(), "journal")

	_press_nav(hud, "Map")
	assert_true(hud.is_systems_panel_visible())
	assert_eq(hud.get_systems_tab(), "map")

	hud.hide_systems_panel()
	_press_nav(hud, "Menu")
	assert_true(hud.is_systems_panel_visible())


func test_rpg_target_picker_uses_framed_focus_panel_and_routes_targets() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))

	var used_targets: Array[String] = []
	hud.target_used.connect(func(entity_id: String) -> void: used_targets.append(entity_id))
	hud.toggle_target_picker()

	assert_true(hud.is_target_picker_visible())
	assert_eq((hud.target_panel.find_child("TargetTitle", true, false) as Label).text, "Focus Target")
	assert_eq(hud.target_scroll.get_child(0), hud.target_list)
	var row := _button_containing(hud.target_list, "Harrow Venn")
	assert_not_null(row)
	assert_true(row.text.contains("Talk"))
	assert_true(row.text.contains("Blacksmith"))
	assert_true(row.text.contains("Road Notice"))
	row.pressed.emit()
	assert_eq(used_targets, ["npc_harrow_venn_world"])

	var close := hud.target_panel.find_child("TargetCloseButton", true, false) as Button
	assert_not_null(close)
	close.pressed.emit()
	assert_false(hud.is_target_picker_visible())


func test_rpg_move_pad_is_joystick_style_and_routes_touch_vector() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))

	assert_not_null(hud.move_pad.get_node("MovePadOuterRing"))
	assert_not_null(hud.move_pad.get_node("MovePadInnerWell"))
	assert_not_null(hud.move_pad.get_node("MoveKnob"))
	for child in hud.move_pad.get_children():
		assert_false(child is Button, "RPG movement pad should not expose debug D-pad buttons.")

	var vectors: Array[Vector2] = []
	hud.move_vector_changed.connect(func(direction: Vector2) -> void: vectors.append(direction))
	var press := InputEventMouseButton.new()
	press.pressed = true
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = Vector2(128, 128)
	hud._on_move_pad_gui_input(press)
	assert_eq(hud.get_touch_move_vector(), Vector2(1, 1).normalized())
	assert_eq(vectors[0], Vector2(1, 1).normalized())

	var release := InputEventMouseButton.new()
	release.pressed = false
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = Vector2(128, 128)
	hud._on_move_pad_gui_input(release)
	assert_eq(hud.get_touch_move_vector(), Vector2.ZERO)
	assert_eq(vectors[-1], Vector2.ZERO)


func test_rpg_action_cluster_uses_player_facing_commands_and_routes_actions() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))

	assert_eq(_button_texts(hud.action_buttons), ["Inventory", "Target", "Talk", "Menu"])
	assert_gt(
		hud.primary_action_button.custom_minimum_size.x,
		hud.inventory_action_button.custom_minimum_size.x
	)

	var interact_events := []
	var cycle_events := []
	hud.interact_pressed.connect(func() -> void: interact_events.append("interact"))
	hud.cycle_target_pressed.connect(func() -> void: cycle_events.append("cycle"))

	hud.inventory_action_button.pressed.emit()
	assert_true(hud.is_systems_panel_visible())
	assert_eq(hud.get_systems_tab(), "inventory")

	hud.hide_systems_panel()
	hud.primary_action_button.pressed.emit()
	assert_eq(interact_events, ["interact"])

	hud.target_action_button.pressed.emit()
	assert_eq(cycle_events, ["cycle"])

	var menu_button := _button_containing(hud.action_buttons, "Menu")
	assert_not_null(menu_button)
	menu_button.pressed.emit()
	assert_true(hud.is_systems_panel_visible())


func test_rpg_quick_actions_use_player_facing_strip_and_route_actions() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))

	var context_actions: Array[String] = []
	var combat_actions: Array[String] = []
	hud.context_action_selected.connect(
		func(action_id: String) -> void: context_actions.append(action_id)
	)
	hud.combat_action_selected.connect(
		func(action_id: String) -> void: combat_actions.append(action_id)
	)

	hud._refresh_context_actions(
		{
			"context_actions":
			[
				{"id": "dialogue:accept", "text": "I'll find it."},
				{"id": "forge:sharpen", "text": "Sharpen Road Hatchet"},
				{"id": "trade:shop_crossroads_peddler", "text": "Trade"}
			]
		}
	)
	assert_true(hud.context_action_panel.visible)
	assert_eq(
		(hud.context_action_panel.find_child("QuickActionTitle", true, false) as Label).text,
		"Quick Actions"
	)
	var screen := Rect2(Vector2.ZERO, Vector2(640, 360))
	var quick_rect := _anchored_rect(hud.context_action_panel, Vector2(640, 360))
	var action_rect := _anchored_rect(hud.action_buttons, Vector2(640, 360))
	assert_true(_rect_inside(quick_rect, screen))
	assert_gte(quick_rect.size.x, 470.0)
	assert_false(quick_rect.intersects(action_rect), "Quick actions should not cover main commands.")
	var accept := _button_containing(hud.context_action_buttons, "I'll find it.")
	assert_not_null(accept)
	assert_gte(accept.custom_minimum_size.x, 142.0)
	assert_gte(accept.custom_minimum_size.y, 52.0)
	accept.pressed.emit()
	assert_eq(context_actions, ["dialogue:accept"])

	hud._refresh_context_actions({"combat_actions": [{"id": "guard", "text": "Guard"}]})
	var guard := _button_containing(hud.context_action_buttons, "Guard")
	assert_not_null(guard)
	guard.pressed.emit()
	assert_eq(combat_actions, ["guard"])


func test_rpg_content_panel_uses_bottom_dialogue_structure_and_routes_choices() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))

	var selected_choices: Array[String] = []
	hud.content_choice_selected.connect(
		func(choice_id: String) -> void: selected_choices.append(choice_id)
	)
	hud.show_content_card(
		"Harrow Venn",
		"Evening. You look like someone who gets their hands dirty.",
		[
			{
				"id": "ask_tools",
				"text": "Ask about tools",
				"response": "Harrow needs the old toolbox from the west road."
			},
			{
				"id": "accept_tools",
				"text": "I'll find it.",
				"effects": [{"type": "start_quest", "quest_id": "quest_missing_tools"}]
			},
			{"id": "leave", "text": "Leave"}
		],
		"dialogue"
	)

	assert_true(hud.is_content_card_visible())
	assert_eq(hud.content_kind_label.text, "Dialogue")
	assert_eq(hud.content_title_label.text, "Harrow Venn")
	assert_true(hud.content_body_label.text.contains("hands dirty"))
	assert_eq(hud.content_scroll.get_child(0), hud.content_body_label)
	assert_true(hud.content_identity_panel.visible)
	assert_true(hud.content_portrait_panel.visible)
	assert_eq(hud.content_portrait_label.text, "HV")
	assert_true(hud.content_preview_panel.visible)
	assert_true(hud.content_preview_label.text.contains("I'll find it."))
	assert_true(hud.content_preview_label.text.contains("Starts quest"))
	assert_false(hud.move_pad.visible)
	assert_false(hud.action_buttons.visible)
	assert_false(hud.message_panel.visible)
	var ask_button := _button_containing(hud.content_choice_list, "Ask about tools")
	assert_not_null(ask_button)
	assert_true(ask_button.text.contains("Learn more before acting."))
	var accept_button := _button_containing(hud.content_choice_list, "I'll find it.")
	assert_not_null(accept_button)
	assert_true(accept_button.text.contains("Starts quest"))
	assert_true((accept_button as Button).text.contains("\n"))

	ask_button.pressed.emit()
	assert_eq(selected_choices, ["ask_tools"])

	var close_events: Array[String] = []
	hud.content_card_closed.connect(func() -> void: close_events.append("closed"))
	var close_button := hud.content_panel.find_child("ContentCloseButton", true, false) as Button
	assert_not_null(close_button)
	close_button.pressed.emit()
	assert_false(hud.is_content_card_visible())
	assert_true(hud.move_pad.visible)
	assert_true(hud.action_buttons.visible)
	assert_eq(close_events, ["closed"])


func test_rpg_systems_menu_uses_full_screen_player_facing_structure() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))
	hud.show_systems_panel("inventory")

	var screen := Rect2(Vector2.ZERO, Vector2(1152, 648))
	var menu_rect := _anchored_rect(hud.systems_panel, Vector2(1152, 648))
	assert_true(hud.is_systems_panel_visible())
	assert_true(_rect_inside(menu_rect, screen), "Systems menu should stay on screen.")
	assert_gt(hud.systems_panel.z_index, hud.top_nav_panel.z_index)
	assert_gt(hud.systems_panel.z_index, hud.action_buttons.z_index)
	assert_gte(menu_rect.size.x, 1100.0)
	assert_gte(menu_rect.size.y, 600.0)
	assert_eq(hud.systems_title_label.text, "Briarwatch")
	assert_true(hud.systems_subtitle_label.text.contains("Inventory"))
	assert_true(hud.systems_subtitle_label.text.contains("Gear"))
	assert_true(hud.systems_resources_label.text.contains("D1, 16:00"))
	assert_eq(_button_texts(hud.systems_nav), [
		"Inventory", "Character", "Quests", "Map", "Journal", "Trade"
	])
	assert_false(hud.systems_body_label.visible)
	assert_eq(hud.systems_scroll.get_child(0), hud.systems_item_list)
	assert_true(hud.systems_action_list is HFlowContainer)
	assert_eq(_button_texts(hud.systems_category_row), ["All", "Gear", "Use", "Quest"])
	var toolbox_row := _button_containing(hud.systems_item_list, "Old Toolbox")
	assert_not_null(toolbox_row)
	assert_true(toolbox_row.text.contains("Count 1"))
	assert_true(hud.systems_body_label.text.contains("Old Toolbox x1"))
	assert_true(hud.systems_detail_label.text.contains("A heavy wooden toolbox"))
	assert_false(hud.systems_character_label.visible)
	assert_true(hud.systems_character_label.text.contains("Weapon: Road Hatchet"))
	assert_not_null(hud.systems_character_panel.find_child("SystemsCharacterPortrait", true, false))
	var character_health := hud.systems_character_panel.find_child(
		"SystemsCharacterHealthBar", true, false
	) as ProgressBar
	assert_not_null(character_health)
	assert_eq(int(character_health.value), 76)
	assert_eq(int(character_health.max_value), 100)
	assert_not_null(_button_containing(hud.systems_character_rows, "Vitals"))
	assert_not_null(_button_containing(hud.systems_character_rows, "Training"))
	var equipment_row := _button_containing(hud.systems_character_rows, "Equipment")
	assert_not_null(equipment_row)
	assert_true(equipment_row.text.contains("Weapon: Road Hatchet"))
	assert_not_null(_button_containing(hud.systems_action_list, "Use Roadside Draught"))

	hud.set_systems_tab("quests")
	assert_eq(hud.systems_title_label.text, "Briarwatch")
	assert_true(hud.systems_subtitle_label.text.contains("Quests"))
	assert_eq(_button_texts(hud.systems_category_row), ["Active", "Routes", "Rewards"])
	assert_not_null(_button_containing(hud.systems_item_list, "The Missing Tools"))
	assert_true(hud.systems_detail_label.text.contains("The Missing Tools"))
	assert_not_null(_button_containing(hud.systems_action_list, "Target Harrow Venn"))

	hud.set_systems_tab("journal")
	assert_eq(hud.systems_title_label.text, "Briarwatch")
	assert_true(hud.systems_subtitle_label.text.contains("Journal"))
	assert_not_null(_button_containing(hud.systems_item_list, "Recent Events"))
	assert_not_null(_button_containing(hud.systems_action_list, "Save Game"))
	assert_not_null(_button_containing(hud.systems_action_list, "Load Game"))

	hud.set_systems_tab("trade")
	assert_eq(_button_texts(hud.systems_category_row), ["Stock", "Buy", "Sell"])
	assert_not_null(_button_containing(hud.systems_item_list, "Crossroads Peddler"))
	var draught_row := _button_containing(hud.systems_item_list, "Roadside Draught")
	assert_not_null(draught_row)
	assert_true(draught_row.text.contains("8g"))
	assert_false(draught_row.text.contains("Trade\nTrade"))
	assert_not_null(_button_containing(hud.systems_action_list, "Buy Roadside Draught"))

	hud.set_systems_tab("character")
	var training_row := _button_containing(hud.systems_item_list, "Training")
	assert_not_null(training_row)
	assert_false(training_row.text.contains("Training    Progression"))
	assert_true(training_row.text.contains("Progression - "))


func test_rpg_systems_menu_collapses_side_panes_on_compact_landscape() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))
	hud.show_systems_panel("inventory")

	var screen := Rect2(Vector2.ZERO, Vector2(640, 360))
	var menu_rect := _anchored_rect(hud.systems_panel, Vector2(640, 360))
	assert_true(_rect_inside(menu_rect, screen), "Compact systems menu should stay on screen.")
	assert_gte(menu_rect.size.x, 600.0)
	assert_false(hud.systems_detail_panel.visible)
	assert_false(hud.systems_character_panel.visible)
	assert_true(hud.systems_left_panel.visible)
	assert_true(hud.systems_center_panel.visible)
	assert_true(hud.systems_category_row.visible)
	assert_true(hud.systems_item_list.visible)
	assert_lte(hud.systems_left_panel.custom_minimum_size.x, 116.0)
	assert_eq((hud.systems_tab_buttons["inventory"] as Button).custom_minimum_size, Vector2(96, 40))
	assert_true(hud.systems_action_list is HFlowContainer)


func test_rpg_hud_collapses_top_chrome_on_compact_landscape() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))
	hud.show_content_card(
		"Road Notice",
		"Boundary stones are not to be moved.",
		[{"id": "accept", "text": "Accept"}],
		"readable"
	)

	assert_false(hud.prompt_panel.visible)
	assert_false(hud.location_banner_panel.visible)
	assert_false(hud.top_nav_panel.visible)
	assert_false(hud.message_panel.visible)

	var screen := Rect2(Vector2.ZERO, Vector2(640, 360))
	var status_rect := _top_left_rect(hud.status_panel)
	var message_rect := _top_left_rect(hud.message_panel)
	var action_rect := _anchored_rect(hud.action_buttons, Vector2(640, 360))
	var move_rect := _anchored_rect(hud.move_pad, Vector2(640, 360))
	var content_rect := _anchored_rect(hud.content_panel, Vector2(640, 360))
	assert_true(_rect_inside(status_rect, screen), "Compact status should stay on screen.")
	assert_true(_rect_inside(message_rect, screen), "Compact messages should stay on screen.")
	assert_true(_rect_inside(action_rect, screen), "Compact actions should stay on screen.")
	assert_true(_rect_inside(content_rect, screen), "Compact content should stay on screen.")
	assert_gte(content_rect.size.y, 260.0)
	assert_false(status_rect.intersects(message_rect), "Compact top panels should not overlap.")
	assert_false(action_rect.intersects(move_rect), "Actions should not cover movement.")
	assert_true(content_rect.intersects(action_rect), "Content should own the bottom action lane.")
	assert_false(hud.action_buttons.visible)
	assert_false(hud.move_pad.visible)
	assert_true(hud.content_identity_panel.visible)
	assert_true(hud.content_portrait_panel.visible)
	assert_false(hud.content_preview_panel.visible)
	assert_lte(hud.content_identity_panel.custom_minimum_size.x, 92.0)
	assert_gte(hud.content_right_stack.custom_minimum_size.x, 232.0)
	assert_gte(hud.content_body_label.get_theme_font_size("font_size"), 22)
	var accept_button := _button_containing(hud.content_choice_list, "Accept") as Button
	assert_not_null(accept_button)
	assert_gte(accept_button.custom_minimum_size.y, 46.0)
	assert_gte(accept_button.get_theme_font_size("font_size"), 14)


func _new_hud() -> RpgHud:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := RpgHud.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_sample_state"))
	return hud


func _sample_state() -> Dictionary:
	return {
		"player_health": "76/100",
		"player_health_value": 76,
		"player_max_health": 100,
		"terrain": "grass",
		"nearby": "Harrow Venn",
		"target_kind": "npc",
		"primary_action": "Talk",
		"locations": "Briarwatch Crossroads",
		"quests": ["The Missing Tools: Return the toolbox to Harrow Venn."],
		"inventory": "Old Toolbox x1",
		"inventory_details": "Old Toolbox x1: A heavy wooden toolbox.",
		"inventory_actions":
		[
			{"id": "use:item_roadside_draught", "text": "Use Roadside Draught"},
			{"id": "equip:item_road_hatchet", "text": "Equip Road Hatchet"}
		],
		"equipment": "Weapon: Road Hatchet\nOffhand: empty\nBody: empty",
		"factions": "Marches of Velcor +5",
		"progression": "Level 2  XP 10/40  Points 1",
		"progression_details": "Level: 2\nXP: 10/40\nUnspent points: 1",
		"time_actions": [{"id": "wait:1", "text": "Wait 1h"}],
		"time": "Day 1, 16:00 (Afternoon)",
		"trade":
		(
			"Crossroads Peddler\n"
			+ "Hours: 08:00-18:00\n"
			+ "Gold: 25\n\n"
			+ "Stock:\n"
			+ "- Roadside Draught: 8g\n"
			+ "- Traveler Buckler: 18g\n\n"
			+ "Sell: none"
		),
		"trade_actions": [{"id": "buy:item_roadside_draught", "text": "Buy Roadside Draught (8g)"}],
		"location_details": "Briarwatch Crossroads - Marches of Velcor",
		"nearby_targets":
		[
			{
				"id": "npc_harrow_venn_world",
				"name": "Harrow Venn",
				"kind": "npc",
				"detail": "Blacksmith, quest giver",
				"navigation": "Near Road Notice",
				"selected": true
			},
			{
				"id": "readable_road_notice",
				"name": "Road Notice",
				"kind": "readable",
				"detail": "Readable notice board",
				"navigation": "East of the bridge"
			}
		],
		"quest_directions": "The Missing Tools: E 5.0t Harrow Venn",
		"quest_target_actions": [{"id": "target:npc_harrow_venn_world", "text": "Target Harrow Venn"}]
	}


func _button_texts(parent: Node) -> Array:
	var texts := []
	for child in parent.get_children():
		if child is Button and child.visible:
			texts.append(child.text)
	return texts


func _press_nav(hud: RpgHud, text: String) -> void:
	var button := _button_containing(hud.top_nav_buttons, text)
	assert_not_null(button)
	button.pressed.emit()


func _button_containing(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.visible and child.text.contains(text):
			return child
	return null


func _rect_inside(inner: Rect2, outer: Rect2) -> bool:
	return (
		inner.position.x >= outer.position.x
		and inner.position.y >= outer.position.y
		and inner.end.x <= outer.end.x
		and inner.end.y <= outer.end.y
	)


func _top_left_rect(panel: Control) -> Rect2:
	return Rect2(
		Vector2(panel.offset_left, panel.offset_top),
		Vector2(panel.offset_right - panel.offset_left, panel.offset_bottom - panel.offset_top)
	)


func _center_top_rect(panel: Control, viewport_size: Vector2) -> Rect2:
	var center_x := viewport_size.x * 0.5
	return Rect2(
		Vector2(center_x + panel.offset_left, panel.offset_top),
		Vector2(panel.offset_right - panel.offset_left, panel.offset_bottom - panel.offset_top)
	)


func _right_rect(panel: Control, viewport_size: Vector2) -> Rect2:
	var left := viewport_size.x + panel.offset_left
	var right := viewport_size.x + panel.offset_right
	return Rect2(
		Vector2(left, panel.offset_top),
		Vector2(right - left, panel.offset_bottom - panel.offset_top)
	)


func _bottom_left_rect(panel: Control, viewport_size: Vector2) -> Rect2:
	var top := viewport_size.y + panel.offset_top
	var bottom := viewport_size.y + panel.offset_bottom
	return Rect2(
		Vector2(panel.offset_left, top),
		Vector2(panel.offset_right - panel.offset_left, bottom - top)
	)


func _anchored_rect(panel: Control, viewport_size: Vector2) -> Rect2:
	var left := panel.anchor_left * viewport_size.x + panel.offset_left
	var right := panel.anchor_right * viewport_size.x + panel.offset_right
	var top := panel.anchor_top * viewport_size.y + panel.offset_top
	var bottom := panel.anchor_bottom * viewport_size.y + panel.offset_bottom
	return Rect2(Vector2(left, top), Vector2(right - left, bottom - top))
