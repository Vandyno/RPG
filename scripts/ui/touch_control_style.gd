class_name TouchControlStyle
extends RefCounted


const DIRECTION_TOOLTIPS := {
	"move_up": "Move north",
	"move_down": "Move south",
	"move_left": "Move west",
	"move_right": "Move east"
}


static func direction_label(action: String) -> String:
	match action:
		"move_up":
			return String.chr(8593)
		"move_down":
			return String.chr(8595)
		"move_left":
			return String.chr(8592)
		"move_right":
			return String.chr(8594)
		_:
			return ""


static func direction_tooltip(action: String) -> String:
	return String(DIRECTION_TOOLTIPS.get(action, "Move"))


static func apply_direction_button_style(button: Button, panel_border: Color) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_color_override("font_color", Color(0.90, 0.84, 0.66, 0.96))
	button.add_theme_color_override("font_hover_color", Color(0.98, 0.91, 0.68, 1.0))
	button.add_theme_color_override("font_pressed_color", Color(0.18, 0.14, 0.08, 1.0))
	button.add_theme_stylebox_override(
		"normal",
		_button_style(Color(0.04, 0.05, 0.04, 0.58), panel_border)
	)
	button.add_theme_stylebox_override(
		"hover",
		_button_style(Color(0.10, 0.12, 0.09, 0.72), Color(0.92, 0.82, 0.54, 0.62))
	)
	button.add_theme_stylebox_override(
		"pressed",
		_button_style(Color(0.83, 0.70, 0.34, 0.88), Color(0.98, 0.90, 0.62, 0.80))
	)


static func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style
