class_name RpgPortraitSilhouette
extends Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.5)
	var radius := minf(size.x, size.y) * 0.5
	if radius <= 0.0:
		return
	var line := Color(0.92, 0.76, 0.46, 0.72)
	var fill := Color(0.03, 0.027, 0.021, 0.58)
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
