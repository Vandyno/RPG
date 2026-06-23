class_name RpgIconButton
extends Button

var icon_kind := "item"
var icon_layout := "left"
var compact := false


func setup_icon(kind: String, layout: String) -> void:
	icon_kind = kind
	icon_layout = layout
	add_theme_color_override("font_color", Color.TRANSPARENT)
	add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	add_theme_color_override("font_focus_color", Color.TRANSPARENT)
	queue_redraw()


func set_compact(value: bool) -> void:
	compact = value
	queue_redraw()


func _draw() -> void:
	if text.is_empty():
		return
	var selected := button_pressed or bool(get_meta("nav_selected", false))
	var color := Color(0.76, 1.0, 0.50, 0.96) if selected else Color(0.92, 0.76, 0.42, 0.94)
	if icon_layout == "top":
		_draw_top_icon(color)
	else:
		_draw_left_icon(color)


func _draw_top_icon(color: Color) -> void:
	var icon_size := 20.0 if compact else 25.0
	var icon_rect := Rect2(Vector2((size.x - icon_size) * 0.5, 6.0), Vector2(icon_size, icon_size))
	_draw_icon_badge(icon_rect, color)
	_draw_label(Vector2(4.0, size.y - (9.0 if compact else 11.0)), size.x - 8.0, 9 if compact else 12)


func _draw_left_icon(color: Color) -> void:
	var icon_size := 20.0 if compact else 31.0
	var icon_rect := Rect2(Vector2(7.0, (size.y - icon_size) * 0.5), Vector2(icon_size, icon_size))
	_draw_icon_badge(icon_rect, color)
	var text_x := icon_rect.end.x + (7.0 if compact else 12.0)
	_draw_label(Vector2(text_x, size.y * 0.58), size.x - text_x - 6.0, 9 if compact else 15)


func _draw_label(position: Vector2, width: float, font_size: int) -> void:
	draw_string(
		get_theme_default_font(),
		position,
		text,
		HORIZONTAL_ALIGNMENT_CENTER if icon_layout == "top" else HORIZONTAL_ALIGNMENT_LEFT,
		width,
		font_size,
		Color(0.96, 0.90, 0.78, 0.98)
	)


func _draw_icon_badge(rect: Rect2, color: Color) -> void:
	draw_rect(rect.grow(4.0), Color(0.03, 0.027, 0.021, 0.50), true)
	draw_rect(rect.grow(4.0), color, false, 1.1)
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.42
	match icon_kind:
		"quests":
			_draw_quest(center, radius, color)
		"journal":
			_draw_book(center, radius, color)
		"map":
			_draw_map(center, radius, color)
		"menu":
			_draw_menu(center, radius, color)
		"inventory":
			_draw_bag(center, radius, color)
		"spells":
			_draw_spell(center, radius, color)
		"character":
			_draw_helm(center, radius, color)
		"trade":
			_draw_trade(center, radius, color)
		_:
			_draw_item(center, radius, color)


func _draw_quest(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius, 0),
		center + Vector2(0, -radius)
	])
	draw_polyline(points, color, 2.0)
	draw_circle(center, radius * 0.22, color)


func _draw_book(center: Vector2, radius: float, color: Color) -> void:
	var rect := Rect2(
		center + Vector2(-radius * 0.85, -radius), Vector2(radius * 1.7, radius * 2.0)
	)
	draw_rect(rect, color, false, 1.7)
	draw_line(
		rect.position + Vector2(radius * 0.45, 0),
		rect.position + Vector2(radius * 0.45, rect.size.y),
		color,
		1.2
	)
	draw_line(
		center + Vector2(-radius * 0.28, -radius * 0.35),
		center + Vector2(radius * 0.52, -radius * 0.35),
		color,
		1.2
	)
	draw_line(
		center + Vector2(-radius * 0.28, radius * 0.15),
		center + Vector2(radius * 0.52, radius * 0.15),
		color,
		1.2
	)


func _draw_map(center: Vector2, radius: float, color: Color) -> void:
	var rect := Rect2(
		center + Vector2(-radius, -radius * 0.72), Vector2(radius * 2.0, radius * 1.44)
	)
	draw_rect(rect, color, false, 1.7)
	draw_line(
		center + Vector2(-radius * 0.34, -radius * 0.72),
		center + Vector2(-radius * 0.20, radius * 0.72),
		color,
		1.2
	)
	draw_line(
		center + Vector2(radius * 0.34, -radius * 0.72),
		center + Vector2(radius * 0.20, radius * 0.72),
		color,
		1.2
	)


func _draw_menu(center: Vector2, radius: float, color: Color) -> void:
	for y in [-0.55, 0.0, 0.55]:
		draw_line(center + Vector2(-radius, radius * y), center + Vector2(radius, radius * y), color, 2.0)


func _draw_bag(center: Vector2, radius: float, color: Color) -> void:
	draw_arc(center + Vector2(0, -radius * 0.45), radius * 0.45, PI, TAU, 24, color, 1.6)
	draw_rect(
		Rect2(
			center + Vector2(-radius * 0.78, -radius * 0.28),
			Vector2(radius * 1.56, radius * 1.18)
		),
		color,
		false,
		1.8
	)


func _draw_spell(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(-radius * 0.20, -radius),
		center + Vector2(radius * 0.38, -radius * 0.10),
		center + Vector2(-radius * 0.06, -radius * 0.05),
		center + Vector2(radius * 0.18, radius),
		center + Vector2(-radius * 0.48, radius * 0.06),
		center
	])
	draw_polyline(points, color, 2.0)


func _draw_helm(center: Vector2, radius: float, color: Color) -> void:
	draw_arc(center, radius, PI, TAU, 28, color, 2.0)
	draw_line(center + Vector2(-radius, 0), center + Vector2(radius, 0), color, 1.6)
	draw_line(
		center + Vector2(-radius * 0.45, 0),
		center + Vector2(-radius * 0.25, radius),
		color,
		1.4
	)
	draw_line(
		center + Vector2(radius * 0.45, 0),
		center + Vector2(radius * 0.25, radius),
		color,
		1.4
	)


func _draw_trade(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center + Vector2(-radius * 0.28, 0), radius * 0.46, color)
	draw_circle(center + Vector2(radius * 0.34, 0), radius * 0.46, color)
	draw_circle(
		center + Vector2(-radius * 0.28, 0),
		radius * 0.25,
		Color(0.03, 0.027, 0.021, 0.70)
	)
	draw_circle(
		center + Vector2(radius * 0.34, 0),
		radius * 0.25,
		Color(0.03, 0.027, 0.021, 0.70)
	)


func _draw_item(center: Vector2, radius: float, color: Color) -> void:
	var rect := Rect2(
		center + Vector2(-radius * 0.68, -radius * 0.58),
		Vector2(radius * 1.36, radius * 1.16)
	)
	draw_rect(rect, color, false, 1.8)
