class_name RpgIconDrawer
extends RefCounted


static func draw_icon(
	canvas: CanvasItem, kind: String, center: Vector2, radius: float, color: Color
) -> void:
	match kind:
		"quest":
			_draw_quest(canvas, center, radius, color)
		"spell":
			_draw_spell(canvas, center, radius, color)
		"map":
			_draw_map(canvas, center, radius, color)
		"journal", "book":
			_draw_journal(canvas, center, radius, color)
		"trade":
			_draw_trade(canvas, center, radius, color)
		_:
			_draw_item(canvas, center, radius, color)


static func _draw_quest(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius, 0),
		center + Vector2(0, radius),
		center + Vector2(-radius, 0),
		center + Vector2(0, -radius)
	])
	canvas.draw_polyline(points, color, 2.2)
	canvas.draw_circle(center, radius * 0.22, color)


static func _draw_spell(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(-radius * 0.20, -radius),
		center + Vector2(radius * 0.38, -radius * 0.12),
		center + Vector2(-radius * 0.05, -radius * 0.05),
		center + Vector2(radius * 0.20, radius),
		center + Vector2(-radius * 0.45, radius * 0.08),
		center
	])
	canvas.draw_polyline(points, color, 2.2)


static func _draw_map(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var rect := Rect2(
		center + Vector2(-radius, -radius * 0.72), Vector2(radius * 2.0, radius * 1.44)
	)
	canvas.draw_rect(rect, color, false, 1.8)
	canvas.draw_line(
		center + Vector2(-radius * 0.34, -radius * 0.72),
		center + Vector2(-radius * 0.20, radius * 0.72),
		color,
		1.2
	)
	canvas.draw_line(
		center + Vector2(radius * 0.34, -radius * 0.72),
		center + Vector2(radius * 0.20, radius * 0.72),
		color,
		1.2
	)


static func _draw_journal(
	canvas: CanvasItem, center: Vector2, radius: float, color: Color
) -> void:
	var rect := Rect2(
		center + Vector2(-radius * 0.78, -radius), Vector2(radius * 1.56, radius * 2.0)
	)
	canvas.draw_rect(rect, color, false, 1.8)
	canvas.draw_line(
		rect.position + Vector2(radius * 0.30, 0),
		rect.position + Vector2(radius * 0.30, rect.size.y),
		color,
		1.2
	)
	canvas.draw_line(
		center + Vector2(-radius * 0.36, -radius * 0.42),
		center + Vector2(radius * 0.48, -radius * 0.42),
		color,
		1.2
	)
	canvas.draw_line(
		center + Vector2(-radius * 0.36, radius * 0.05),
		center + Vector2(radius * 0.48, radius * 0.05),
		color,
		1.2
	)


static func _draw_trade(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var cutout := Color(0.03, 0.027, 0.021, 0.70)
	canvas.draw_circle(center + Vector2(-radius * 0.28, 0), radius * 0.48, color)
	canvas.draw_circle(center + Vector2(radius * 0.34, 0), radius * 0.48, color)
	canvas.draw_circle(center + Vector2(-radius * 0.28, 0), radius * 0.28, cutout)
	canvas.draw_circle(center + Vector2(radius * 0.34, 0), radius * 0.28, cutout)


static func _draw_item(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var rect := Rect2(
		center + Vector2(-radius * 0.68, -radius * 0.58),
		Vector2(radius * 1.36, radius * 1.16)
	)
	canvas.draw_rect(rect, color, false, 1.8)
	canvas.draw_line(
		rect.position, rect.position + Vector2(radius * 0.32, -radius * 0.36), color, 1.4
	)
	canvas.draw_line(
		rect.position + Vector2(rect.size.x, 0),
		rect.position + Vector2(radius * 1.04, -radius * 0.36),
		color,
		1.4
	)
