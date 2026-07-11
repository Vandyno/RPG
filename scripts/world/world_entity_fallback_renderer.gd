class_name WorldEntityFallbackRenderer
extends RefCounted

const ItemVisual2D = preload("res://scripts/items/item_visual_2d.gd")


static func draw_entity(
	canvas: CanvasItem,
	kind: String,
	combat_target: bool,
	pickup_item_model: Dictionary,
	visual_style: String = ""
) -> void:
	if kind == "pickup":
		_draw_pickup(canvas, pickup_item_model)
		return
	if combat_target:
		_draw_hostile_marker(canvas)
	elif kind == "npc":
		_draw_npc_marker(canvas)
	elif kind == "container":
		canvas.draw_rect(Rect2(Vector2(-7, -5), Vector2(14, 10)), Color(0.55, 0.34, 0.14), true)
		canvas.draw_line(Vector2(-7, -1), Vector2(7, -1), Color(0.92, 0.76, 0.42), 1.5)
	elif kind == "door":
		canvas.draw_rect(Rect2(Vector2(-4, -9), Vector2(8, 18)), Color(0.44, 0.28, 0.16), true)
		canvas.draw_circle(Vector2(2, 0), 1.5, Color(0.96, 0.78, 0.34))
	elif kind == "readable":
		canvas.draw_rect(Rect2(Vector2(-6, -8), Vector2(12, 16)), Color(0.93, 0.88, 0.67), true)
	elif kind == "body":
		canvas.draw_ellipse(Vector2(0.0, 2.0), 11.0, 6.0, Color(0.36, 0.25, 0.17))
		canvas.draw_ellipse(Vector2(0.0, 2.0), 11.0, 6.0, Color(0.05, 0.04, 0.03), false, 1.5)
	elif kind == "rest":
		canvas.draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.45, 0.16))
		canvas.draw_line(Vector2(-6, 6), Vector2(6, 6), Color(0.25, 0.12, 0.05), 2.0)
	elif kind == "poi":
		if visual_style == "sign":
			_draw_sign(canvas)
		else:
			_draw_poi(canvas)
	elif kind == "location":
		var points := PackedVector2Array(
			[Vector2(0, -8), Vector2(8, 0), Vector2(0, 8), Vector2(-8, 0)]
		)
		canvas.draw_polygon(points, PackedColorArray([Color(0.42, 0.68, 0.92)]))
	else:
		canvas.draw_rect(Rect2(Vector2(-4.0, -4.0), Vector2(8.0, 8.0)), color_for_kind(kind), true)


static func color_for_kind(kind: String) -> Color:
	var color := Color(0.60, 0.60, 0.60)
	match kind:
		"npc":
			color = Color(0.61, 0.43, 0.24)
		"pickup":
			color = Color(0.78, 0.58, 0.12)
		"container":
			color = Color(0.50, 0.32, 0.16)
		"door":
			color = Color(0.38, 0.25, 0.16)
		"readable":
			color = Color(0.84, 0.80, 0.58)
		"rest":
			color = Color(0.94, 0.45, 0.18)
		"poi":
			color = Color(0.48, 0.38, 0.24)
		"location":
			color = Color(0.18, 0.38, 0.56)
	return color


static func _draw_pickup(canvas: CanvasItem, pickup_item_model: Dictionary) -> void:
	if pickup_item_model.is_empty():
		canvas.draw_rect(Rect2(Vector2(-5, -5), Vector2(10, 10)), Color(0.93, 0.76, 0.25), true)
		return
	ItemVisual2D.draw_visual(canvas, pickup_item_model)


static func _draw_poi(canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(Vector2(-9, -3), Vector2(18, 12)), Color(0.46, 0.36, 0.22), true)
	var roof := PackedVector2Array([Vector2(-11, -3), Vector2(0, -11), Vector2(11, -3)])
	canvas.draw_polygon(roof, PackedColorArray([Color(0.58, 0.18, 0.14)]))
	canvas.draw_rect(Rect2(Vector2(-2, 2), Vector2(4, 7)), Color(0.18, 0.11, 0.07), true)


static func _draw_sign(canvas: CanvasItem) -> void:
	canvas.draw_line(Vector2(0.0, -8.0), Vector2(0.0, 8.0), Color(0.18, 0.10, 0.045), 2.0)
	var board := Rect2(Vector2(-8.0, -8.0), Vector2(16.0, 10.0))
	canvas.draw_rect(board, Color(0.50, 0.35, 0.16), true)
	canvas.draw_rect(board, Color(0.10, 0.06, 0.025), false, 1.0)
	canvas.draw_line(
		board.position + Vector2(3.0, 3.5),
		board.position + Vector2(13.0, 3.5),
		Color(0.82, 0.72, 0.48),
		0.8
	)
	canvas.draw_line(
		board.position + Vector2(3.0, 6.5),
		board.position + Vector2(11.0, 6.5),
		Color(0.82, 0.72, 0.48),
		0.8
	)


static func _draw_npc_marker(canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(Vector2(-3.0, -7.0), Vector2(6.0, 8.0)), Color(0.61, 0.43, 0.24), true)
	canvas.draw_rect(Rect2(Vector2(-5.0, 1.0), Vector2(10.0, 7.0)), Color(0.47, 0.31, 0.18), true)


static func _draw_hostile_marker(canvas: CanvasItem) -> void:
	var points := PackedVector2Array(
		[Vector2(0.0, -9.0), Vector2(7.0, 0.0), Vector2(0.0, 9.0), Vector2(-7.0, 0.0)]
	)
	canvas.draw_polygon(points, PackedColorArray([Color(0.75, 0.20, 0.16)]))
	points.append(points[0])
	canvas.draw_polyline(points, Color(0.12, 0.02, 0.02), 1.5)
