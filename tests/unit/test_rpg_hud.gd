extends GutTest

const EventBus = preload("res://scripts/core/event_bus.gd")
const Main = preload("res://scripts/main/main.gd")
const RpgHud = preload("res://scripts/ui/rpg_hud.gd")


func test_main_uses_player_facing_rpg_hud() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_eq(main.hud.name, "RpgHud")
	assert_true(main.hud is RpgHud)


func test_rpg_hud_adds_mockup_style_navigation_without_debug_prompt() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))

	assert_false(hud.prompt_panel.visible)
	assert_true(hud.location_banner_panel.visible)
	assert_eq(hud.location_banner_label.text, "Briarwatch")
	assert_true(hud.top_nav_panel.visible)
	assert_eq(_button_texts(hud.top_nav_buttons), ["Quests", "Journal", "Map", "Menu"])

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


func test_rpg_action_cluster_uses_player_facing_commands_and_routes_actions() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(1152, 648))

	assert_eq(_button_texts(hud.action_buttons), ["Inventory", "Next", "Talk", "Menu"])
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
	assert_eq(_button_texts(hud.systems_category_row), ["All", "Gear", "Use", "Quest"])
	var toolbox_row := _button_containing(hud.systems_item_list, "Old Toolbox")
	assert_not_null(toolbox_row)
	assert_true(toolbox_row.text.contains("Count 1"))
	assert_true(hud.systems_body_label.text.contains("Old Toolbox x1"))
	assert_true(hud.systems_detail_label.text.contains("A heavy wooden toolbox"))
	assert_true(hud.systems_character_label.text.contains("Weapon: Road Hatchet"))
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


func test_rpg_hud_collapses_top_chrome_on_compact_landscape() -> void:
	var hud := _new_hud()
	hud._apply_layout_for_size(Vector2(640, 360))

	assert_false(hud.prompt_panel.visible)
	assert_false(hud.location_banner_panel.visible)
	assert_false(hud.top_nav_panel.visible)
	assert_true(hud.message_panel.visible)

	var screen := Rect2(Vector2.ZERO, Vector2(640, 360))
	var status_rect := _top_left_rect(hud.status_panel)
	var message_rect := _top_left_rect(hud.message_panel)
	var action_rect := _anchored_rect(hud.action_buttons, Vector2(640, 360))
	var move_rect := _anchored_rect(hud.move_pad, Vector2(640, 360))
	assert_true(_rect_inside(status_rect, screen), "Compact status should stay on screen.")
	assert_true(_rect_inside(message_rect, screen), "Compact messages should stay on screen.")
	assert_true(_rect_inside(action_rect, screen), "Compact actions should stay on screen.")
	assert_false(status_rect.intersects(message_rect), "Compact top panels should not overlap.")
	assert_false(action_rect.intersects(move_rect), "Actions should not cover movement.")


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
		"location_details": "Briarwatch Crossroads - Marches of Velcor",
		"nearby_targets": [],
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
