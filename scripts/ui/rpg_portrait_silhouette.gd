class_name RpgPortraitSilhouette
extends Control

var identity_kind := "person"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_identity_kind(kind: String) -> void:
	identity_kind = kind
	queue_redraw()


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.5)
	var radius := minf(size.x, size.y) * 0.5
	if radius <= 0.0:
		return
	var line := Color(0.92, 0.76, 0.46, 0.72)
	var fill := Color(0.03, 0.027, 0.021, 0.58)
	match identity_kind:
		"readable":
			_draw_readable(center, radius, line)
		"place":
			_draw_place(center, radius, line)
		"response":
			_draw_response(center, radius, line)
		_:
			_draw_person(center, radius, line, fill)


func _draw_person(center: Vector2, radius: float, line: Color, fill: Color) -> void:
	var head_center := center + Vector2(0.0, -radius * 0.22)
	var head_radius := radius * 0.24
	draw_circle(head_center, head_radius, fill)
	draw_arc(head_center, head_radius, 0.0, TAU, 36, line, 1.5)
	var shoulder_rect := Rect2(
		center + Vector2(-radius * 0.46, radius * 0.12),
		Vector2(radius * 0.92, radius * 0.42)
	)
	draw_arc(shoulder_rect.get_center(), shoulder_rect.size.x * 0.5, PI, TAU, 36, line, 2.0)
	draw_line(
		center + Vector2(-radius * 0.42, radius * 0.33),
		center + Vector2(radius * 0.42, radius * 0.33),
		line,
		1.4
	)


func _draw_readable(center: Vector2, radius: float, line: Color) -> void:
	var rect := Rect2(
		center + Vector2(-radius * 0.34, -radius * 0.46),
		Vector2(radius * 0.68, radius * 0.92)
	)
	draw_rect(rect, line, false, 1.5)
	draw_line(
		rect.position + Vector2(radius * 0.16, 0),
		rect.end - Vector2(radius * 0.16, 0),
		line,
		1.2
	)
	for offset in [-0.16, 0.08, 0.32]:
		draw_line(
			center + Vector2(-radius * 0.20, radius * offset),
			center + Vector2(radius * 0.22, radius * offset),
			line,
			1.1
		)


func _draw_place(center: Vector2, radius: float, line: Color) -> void:
	draw_arc(
		center + Vector2(0, -radius * 0.10),
		radius * 0.34,
		0.0,
		TAU,
		32,
		line,
		1.6
	)
	draw_line(
		center + Vector2(0, radius * 0.24),
		center + Vector2(0, radius * 0.56),
		line,
		1.5
	)
	draw_line(
		center + Vector2(-radius * 0.34, radius * 0.56),
		center + Vector2(radius * 0.34, radius * 0.56),
		line,
		1.5
	)
	draw_line(
		center + Vector2(-radius * 0.54, radius * 0.06),
		center + Vector2(-radius * 0.34, radius * 0.56),
		line,
		1.3
	)
	draw_line(
		center + Vector2(radius * 0.54, radius * 0.06),
		center + Vector2(radius * 0.34, radius * 0.56),
		line,
		1.3
	)


func _draw_response(center: Vector2, radius: float, line: Color) -> void:
	draw_arc(center, radius * 0.44, 0.0, TAU, 36, line, 1.6)
	draw_line(
		center + Vector2(-radius * 0.22, 0),
		center + Vector2(-radius * 0.02, radius * 0.20),
		line,
		2.0
	)
	draw_line(
		center + Vector2(-radius * 0.02, radius * 0.20),
		center + Vector2(radius * 0.30, -radius * 0.24),
		line,
		2.0
	)
