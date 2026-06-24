extends GutTest


func test_icon_buttons_hide_native_text_in_hover_states() -> void:
	var button := RpgIconButton.new()
	add_child_autofree(button)
	button.text = "Spells"
	button.setup_icon("spells", "left")

	assert_eq(button.get_theme_color("font_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_hover_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_hover_pressed_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_pressed_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_focus_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_disabled_color"), Color.TRANSPARENT)
