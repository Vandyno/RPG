class_name RpgContentChoiceButton
extends Button

var choice_icon := "action"
var choice_title := ""
var choice_subtitle := ""
var centered := false


func set_choice_card(icon: String, title: String, subtitle: String, center_text := false) -> void:
	choice_icon = icon
	choice_title = title
	choice_subtitle = subtitle
	centered = center_text
	add_theme_color_override("font_color", Color.TRANSPARENT)
	add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	add_theme_color_override("font_focus_color", Color.TRANSPARENT)
	queue_redraw()


func _draw() -> void:
	if centered:
		_draw_centered_text()
		return
	var icon_rect := Rect2(Vector2(10, 8), Vector2(34, maxf(30.0, size.y - 16.0)))
	var color := Color(0.92, 0.76, 0.42, 0.95)
	if bool(get_meta("choice_recommended", false)):
		color = Color(0.76, 1.0, 0.50, 0.96)
	draw_rect(icon_rect, Color(0.03, 0.027, 0.021, 0.50), true)
	draw_rect(icon_rect, color, false, 1.2)
	_draw_icon(icon_rect, color)
	var font := get_theme_default_font()
	var title_size := 11 if size.y < 52.0 else 14
	var subtitle_size := 9 if size.y < 52.0 else 11
	var text_x := icon_rect.end.x + 10.0
	var text_width := maxf(0.0, size.x - text_x - 10.0)
	var fitted_title := _fit_line(choice_title, text_width, font, title_size)
	draw_string(
		font,
		Vector2(text_x, 22.0),
		fitted_title,
		HORIZONTAL_ALIGNMENT_LEFT,
		text_width,
		title_size,
		Color(0.98, 0.92, 0.78, 0.98)
	)
	if not choice_subtitle.is_empty():
		var subtitle := _fit_line(choice_subtitle, text_width, font, subtitle_size)
		draw_string(
			font,
			Vector2(text_x, size.y - 10.0),
			subtitle,
			HORIZONTAL_ALIGNMENT_LEFT,
			text_width,
			subtitle_size,
			Color(0.88, 0.80, 0.65, 0.95)
		)


func _draw_centered_text() -> void:
	var font := get_theme_default_font()
	draw_string(
		font,
		Vector2(0.0, size.y * 0.58),
		choice_title,
		HORIZONTAL_ALIGNMENT_CENTER,
		size.x,
		12,
		Color(0.98, 0.92, 0.78, 0.98)
	)


func _fit_line(value: String, text_width: float, font: Font, font_size: int) -> String:
	if _line_width(value, font, font_size) <= text_width:
		return value
	var suffix := "..."
	var suffix_width := _line_width(suffix, font, font_size)
	if suffix_width >= text_width:
		return suffix
	var best := ""
	for index in range(1, value.length() + 1):
		var candidate := value.substr(0, index).strip_edges()
		if _line_width(candidate, font, font_size) + suffix_width > text_width:
			break
		best = candidate
	return "%s%s" % [best, suffix]


func _line_width(value: String, font: Font, font_size: int) -> float:
	return font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func _draw_icon(rect: Rect2, color: Color) -> void:
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.28
	match choice_icon:
		"quest":
			_draw_quest_icon(center, radius, color)
		"service":
			_draw_service_icon(center, radius, color)
		"trade":
			_draw_trade_icon(center, radius, color)
		"dialogue":
			_draw_dialogue_icon(center, radius, color)
		_:
			_draw_action_icon(center, radius, color)


func _draw_quest_icon(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius, 0),
		center + Vector2(0, -radius)
	])
	draw_polyline(points, color, 2.0)
	draw_circle(center, radius * 0.22, color)


func _draw_service_icon(center: Vector2, radius: float, color: Color) -> void:
	draw_line(center + Vector2(-radius, radius), center + Vector2(radius, -radius), color, 2.4)
	draw_line(
		center + Vector2(-radius * 0.35, radius * 0.35),
		center + Vector2(radius * 0.05, radius),
		color,
		1.8
	)
	draw_rect(Rect2(center + Vector2(-radius * 0.65, radius * 0.36), Vector2(radius * 1.3, 3)), color)


func _draw_trade_icon(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center + Vector2(-radius * 0.25, 0), radius * 0.45, color)
	draw_circle(center + Vector2(radius * 0.35, 0), radius * 0.45, color)
	draw_circle(
		center + Vector2(-radius * 0.25, 0),
		radius * 0.24,
		Color(0.03, 0.027, 0.021, 0.70)
	)
	draw_circle(
		center + Vector2(radius * 0.35, 0),
		radius * 0.24,
		Color(0.03, 0.027, 0.021, 0.70)
	)


func _draw_dialogue_icon(center: Vector2, radius: float, color: Color) -> void:
	draw_arc(center, radius, 0.0, TAU, 32, color, 2.0)
	draw_line(
		center + Vector2(-radius * 0.20, radius),
		center + Vector2(-radius * 0.55, radius * 1.32),
		color,
		1.8
	)


func _draw_action_icon(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(-radius * 0.55, -radius),
		center + Vector2(radius * 0.65, 0),
		center + Vector2(-radius * 0.55, radius)
	])
	draw_polyline(points, color, 2.4)
