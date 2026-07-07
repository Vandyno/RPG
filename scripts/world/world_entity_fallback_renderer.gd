class_name WorldEntityFallbackRenderer
extends RefCounted

const ItemVisual2D = preload("res://scripts/items/item_visual_2d.gd")


static func draw_entity(
	canvas: CanvasItem, kind: String, combat_target: bool, pickup_item_model: Dictionary
) -> void:
	var color := Color(0.75, 0.20, 0.16) if combat_target else color_for_kind(kind)
	canvas.draw_circle(Vector2.ZERO, 10.0, color)
	canvas.draw_circle(Vector2.ZERO, 10.0, Color(0.04, 0.04, 0.04), false, 2.0)
	if combat_target:
		canvas.draw_line(Vector2(-5, -5), Vector2(5, 5), Color(0.12, 0.02, 0.02), 2.0)
		canvas.draw_line(Vector2(5, -5), Vector2(-5, 5), Color(0.12, 0.02, 0.02), 2.0)
	elif kind == "npc":
		canvas.draw_circle(Vector2(0, -2), 3.0, Color(0.96, 0.88, 0.62))
	elif kind == "pickup":
		_draw_pickup(canvas, pickup_item_model)
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
		_draw_poi(canvas)
	elif kind == "location":
		var points := PackedVector2Array(
			[Vector2(0, -8), Vector2(8, 0), Vector2(0, 8), Vector2(-8, 0)]
		)
		canvas.draw_polygon(points, PackedColorArray([Color(0.42, 0.68, 0.92)]))


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
