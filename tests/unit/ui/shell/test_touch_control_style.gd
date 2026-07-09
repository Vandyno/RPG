extends GutTest

const TouchControlStyle = preload("res://scripts/ui/shell/touch_control_style.gd")


func test_direction_labels_and_tooltips_cover_cardinal_actions() -> void:
	assert_eq(TouchControlStyle.direction_label("move_up"), String.chr(8593))
	assert_eq(TouchControlStyle.direction_label("move_down"), String.chr(8595))
	assert_eq(TouchControlStyle.direction_label("move_left"), String.chr(8592))
	assert_eq(TouchControlStyle.direction_label("move_right"), String.chr(8594))
	assert_eq(TouchControlStyle.direction_label("unknown"), "")
	assert_eq(TouchControlStyle.direction_tooltip("move_right"), "Move east")
	assert_eq(TouchControlStyle.direction_tooltip("unknown"), "Move")


func test_apply_direction_button_style_sets_focus_colors_and_styleboxes() -> void:
	var button := Button.new()
	add_child_autofree(button)
	var border := Color(0.5, 0.4, 0.3, 1.0)

	TouchControlStyle.apply_direction_button_style(button, border)
	var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
	var pressed := button.get_theme_stylebox("pressed") as StyleBoxFlat

	assert_eq(button.focus_mode, Control.FOCUS_NONE)
	assert_eq(button.get_theme_color("font_color"), Color(0.90, 0.84, 0.66, 0.96))
	assert_eq(normal.border_color, border)
	assert_eq(normal.corner_radius_top_left, 6)
	assert_eq(pressed.bg_color, Color(0.83, 0.70, 0.34, 0.88))
