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
	assert_true(_rect_inside(status_rect, screen), "Compact status should stay on screen.")
	assert_true(_rect_inside(message_rect, screen), "Compact messages should stay on screen.")
	assert_false(status_rect.intersects(message_rect), "Compact top panels should not overlap.")


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
		"equipment": "Weapon: Road Hatchet\nOffhand: empty\nBody: empty",
		"factions": "Marches of Velcor +5",
		"progression": "Level 2  XP 10/40  Points 1",
		"time": "Day 1, 16:00 (Afternoon)",
		"location_details": "Briarwatch Crossroads - Marches of Velcor",
		"nearby_targets": []
	}


func _button_texts(parent: Node) -> Array:
	var texts := []
	for child in parent.get_children():
		if child is Button:
			texts.append(child.text)
	return texts


func _press_nav(hud: RpgHud, text: String) -> void:
	var button := _button_containing(hud.top_nav_buttons, text)
	assert_not_null(button)
	button.pressed.emit()


func _button_containing(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text.contains(text):
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
