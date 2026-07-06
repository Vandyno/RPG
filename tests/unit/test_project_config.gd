extends GutTest


func test_project_uses_mobile_landscape_viewport_baseline() -> void:
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1152)
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 648)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")


func test_debug_character_creator_uses_p_key() -> void:
	var events := InputMap.action_get_events("toggle_character_creator")
	var has_p := false
	for event in events:
		if event is InputEventKey and event.keycode == KEY_P:
			has_p = true
	assert_true(has_p)
