extends GutTest


func test_project_uses_mobile_landscape_viewport_baseline() -> void:
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_width")), 1152)
	assert_eq(int(ProjectSettings.get_setting("display/window/size/viewport_height")), 648)
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")
