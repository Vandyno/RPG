class_name ItemVisual2D
extends Node2D

const OUTLINE := Color(0.045, 0.035, 0.025, 0.95)
const DEFAULT_COLORS := {
	"placeholder_hatchet": Color(0.62, 0.58, 0.48),
	"placeholder_sword": Color(0.72, 0.72, 0.68),
	"placeholder_polearm": Color(0.48, 0.34, 0.18),
	"placeholder_bow": Color(0.40, 0.22, 0.08),
	"placeholder_buckler": Color(0.42, 0.30, 0.18)
}

var visual_id := ""
var visual_state: Dictionary = {}


func setup(visual_layer_id: String, state: Dictionary = {}) -> void:
	visual_id = visual_layer_id
	visual_state = state.duplicate(true)
	queue_redraw()


func _draw() -> void:
	var model := visual_state.duplicate(true)
	model["visual_id"] = visual_id
	if not model.has("origin"):
		model["origin"] = Vector2.ZERO
	if not model.has("direction"):
		model["direction"] = Vector2.RIGHT
	draw_visual(self, model)


static func visual_id_from_item(item: Dictionary) -> String:
	var visual_value: Variant = item.get("avatar_visual", {})
	if not visual_value is Dictionary:
		return ""
	return String((visual_value as Dictionary).get("visual_layer_id", ""))


static func default_color(visual_layer_id: String) -> Color:
	return DEFAULT_COLORS.get(visual_layer_id, Color(0.82, 0.74, 0.52))


static func is_item_visual(visual_layer_id: String) -> bool:
	return DEFAULT_COLORS.has(visual_layer_id)


static func model(
	visual_layer_id: String, origin: Vector2, direction: Vector2, options: Dictionary = {}
) -> Dictionary:
	var safe_direction := _safe_direction(direction)
	var result := options.duplicate(true)
	result["visual_id"] = visual_layer_id
	result["origin"] = origin
	result["direction"] = safe_direction
	if not result.has("color"):
		result["color"] = default_color(visual_layer_id)
	return result


static func grip_ids(visual_layer_id: String) -> Array[String]:
	match visual_layer_id:
		"placeholder_polearm":
			return ["front", "rear"]
		"placeholder_bow":
			return ["bow", "draw"]
		"placeholder_buckler":
			return ["center"]
		"placeholder_hatchet", "placeholder_sword":
			return ["primary"]
		_:
			return []


static func grip_position(item_model: Dictionary, grip_id: String) -> Vector2:
	var visual_layer_id := String(item_model.get("visual_id", ""))
	var origin := _vector_value(item_model.get("origin", Vector2.ZERO), Vector2.ZERO)
	var direction := _safe_direction(item_model.get("direction", Vector2.RIGHT))
	var side_axis := _side_axis(item_model, direction)
	match visual_layer_id:
		"placeholder_polearm":
			var grip_side_offset := float(item_model.get("grip_side_offset", 2.1))
			match grip_id:
				"front":
					return origin + direction * 10.0 - side_axis * grip_side_offset
				"rear":
					return origin - direction * 6.0 + side_axis * grip_side_offset
		"placeholder_bow":
			var draw_amount := clampf(float(item_model.get("draw_amount", 0.0)), 0.0, 1.0)
			match grip_id:
				"bow":
					return origin - direction * 0.5
				"draw":
					return origin - direction * (8.0 + 8.5 * draw_amount) - side_axis * 0.8
		"placeholder_buckler":
			return origin
		"placeholder_hatchet", "placeholder_sword":
			return origin
	return origin


static func visual_bounds(item_model: Dictionary) -> Rect2:
	var points := _model_points(item_model)
	if points.is_empty():
		var origin := _vector_value(item_model.get("origin", Vector2.ZERO), Vector2.ZERO)
		return Rect2(origin - Vector2.ONE, Vector2.ONE * 2.0)
	var min_point: Vector2 = points[0]
	var max_point: Vector2 = points[0]
	for point in points:
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)


static func draw_visual(canvas: CanvasItem, item_model: Dictionary) -> void:
	match String(item_model.get("visual_id", "")):
		"placeholder_hatchet":
			_draw_hatchet(canvas, item_model)
		"placeholder_sword":
			_draw_sword(canvas, item_model)
		"placeholder_polearm":
			_draw_polearm(canvas, item_model)
		"placeholder_bow":
			_draw_bow(canvas, item_model)
		"placeholder_buckler":
			_draw_buckler(canvas, item_model)


static func _draw_hatchet(canvas: CanvasItem, item_model: Dictionary) -> void:
	var origin := _vector_value(item_model.get("origin", Vector2.ZERO), Vector2.ZERO)
	var direction := _safe_direction(item_model.get("direction", Vector2.RIGHT))
	var side_axis := _side_axis(item_model, direction)
	var color := _color_value(item_model.get("color", default_color("placeholder_hatchet")))
	var grip_color := Color(0.30, 0.18, 0.09, 0.96)
	var grip_start := origin - direction * 5.5
	var grip_end := origin + direction * 8.0
	var head_center := grip_end + direction * 2.8
	canvas.draw_line(grip_start, grip_end, OUTLINE, 4.0)
	canvas.draw_line(grip_start, grip_end, grip_color, 2.7)
	_draw_shape(
		canvas,
		PackedVector2Array(
			[
				head_center + direction * 3.8 + side_axis * 4.2,
				head_center + direction * 4.2 - side_axis * 2.0,
				head_center - direction * 2.7 - side_axis * 4.0,
				head_center - direction * 3.5 + side_axis * 1.2
			]
		),
		color.lightened(0.12),
		OUTLINE,
		0.75
	)
	canvas.draw_line(
		head_center - side_axis * 2.8, head_center + side_axis * 2.8, color.lightened(0.22), 0.7
	)


static func _draw_sword(canvas: CanvasItem, item_model: Dictionary) -> void:
	var origin := _vector_value(item_model.get("origin", Vector2.ZERO), Vector2.ZERO)
	var direction := _safe_direction(item_model.get("direction", Vector2.RIGHT))
	var side_axis := _side_axis(item_model, direction)
	var color := _color_value(item_model.get("color", default_color("placeholder_sword")))
	var grip_color := Color(0.30, 0.18, 0.09, 0.96)
	var guard_color := Color(0.54, 0.38, 0.18, 0.96)
	var pommel := origin - direction * 5.2
	var grip_end := origin + direction * 2.4
	var guard_center := origin + direction * 2.6
	var blade_base := origin + direction * 4.0
	var blade_tip := origin + direction * 22.0
	canvas.draw_line(pommel, grip_end, OUTLINE, 4.2)
	canvas.draw_line(pommel, grip_end, grip_color, 2.8)
	canvas.draw_line(guard_center - side_axis * 4.4, guard_center + side_axis * 4.4, OUTLINE, 3.0)
	canvas.draw_line(
		guard_center - side_axis * 3.6, guard_center + side_axis * 3.6, guard_color, 1.7
	)
	_draw_shape(
		canvas,
		PackedVector2Array(
			[
				blade_base - side_axis * 1.45,
				blade_tip - side_axis * 0.35,
				blade_tip + direction * 2.0,
				blade_tip + side_axis * 0.35,
				blade_base + side_axis * 1.45
			]
		),
		color,
		OUTLINE,
		0.65
	)
	canvas.draw_line(blade_base, blade_tip, color.lightened(0.24), 0.75)
	canvas.draw_circle(pommel, 1.45, guard_color)


static func _draw_polearm(canvas: CanvasItem, item_model: Dictionary) -> void:
	var origin := _vector_value(item_model.get("origin", Vector2.ZERO), Vector2.ZERO)
	var direction := _safe_direction(item_model.get("direction", Vector2.RIGHT))
	var side_axis := _side_axis(item_model, direction)
	var shaft_color := _color_value(item_model.get("color", default_color("placeholder_polearm")))
	var metal_color := Color(0.70, 0.70, 0.64, 0.96)
	var butt := origin - direction * 24.0
	var socket_start := origin + direction * 27.0
	var socket_end := origin + direction * 33.5
	var blade_base := origin + direction * 33.0
	var blade_tip := origin + direction * 42.0
	canvas.draw_line(butt, socket_end, OUTLINE, 4.3)
	canvas.draw_line(butt, socket_end, shaft_color, 2.7)
	canvas.draw_line(
		butt + side_axis * 0.7, socket_start + side_axis * 0.7, shaft_color.lightened(0.18), 0.75
	)
	_draw_shape(
		canvas,
		PackedVector2Array(
			[
				socket_end + side_axis * 2.2,
				socket_end - side_axis * 2.2,
				socket_start - side_axis * 1.4,
				socket_start + side_axis * 1.4
			]
		),
		metal_color.darkened(0.10),
		OUTLINE,
		0.55
	)
	_draw_shape(
		canvas,
		PackedVector2Array(
			[
				blade_tip,
				blade_base + side_axis * 3.2,
				socket_end + side_axis * 1.7,
				socket_end - side_axis * 1.7,
				blade_base - side_axis * 3.2
			]
		),
		metal_color,
		OUTLINE,
		0.75
	)
	canvas.draw_line(blade_base, blade_tip, metal_color.lightened(0.24), 0.75)


static func _draw_bow(canvas: CanvasItem, item_model: Dictionary) -> void:
	var origin := _vector_value(item_model.get("origin", Vector2.ZERO), Vector2.ZERO)
	var direction := _safe_direction(item_model.get("direction", Vector2.RIGHT))
	var side_axis := _side_axis(item_model, direction)
	var color := _color_value(item_model.get("color", default_color("placeholder_bow")))
	var draw_amount := clampf(float(item_model.get("draw_amount", 0.0)), 0.0, 1.0)
	var string_center := origin - direction * lerpf(2.0, 11.0, draw_amount)
	var upper_tip := origin + side_axis * 13.0 - direction * 2.6
	var lower_tip := origin - side_axis * 13.0 - direction * 2.6
	var bow_curve := PackedVector2Array(
		[
			upper_tip,
			origin + side_axis * 7.0 + direction * 1.0,
			origin + direction * 3.0,
			origin - side_axis * 7.0 + direction * 1.0,
			lower_tip
		]
	)
	canvas.draw_polyline(bow_curve, OUTLINE, 4.2)
	canvas.draw_polyline(bow_curve, color, 3.0)
	canvas.draw_line(upper_tip, string_center, OUTLINE, 2.1)
	canvas.draw_line(lower_tip, string_center, OUTLINE, 2.1)
	canvas.draw_line(upper_tip, string_center, Color(0.82, 0.74, 0.56), 1.1)
	canvas.draw_line(lower_tip, string_center, Color(0.82, 0.74, 0.56), 1.1)
	if bool(item_model.get("arrow_visible", false)):
		_draw_nocked_arrow(canvas, item_model)


static func _draw_nocked_arrow(canvas: CanvasItem, item_model: Dictionary) -> void:
	var origin := _vector_value(item_model.get("origin", Vector2.ZERO), Vector2.ZERO)
	var direction := _safe_direction(item_model.get("direction", Vector2.RIGHT))
	var side_axis := _side_axis(item_model, direction)
	var draw_amount := clampf(float(item_model.get("draw_amount", 0.0)), 0.0, 1.0)
	var arrow_tip := origin + direction * lerpf(9.0, 15.0, draw_amount)
	var arrow_tail := grip_position(item_model, "draw") - direction * 1.2
	canvas.draw_line(arrow_tail, arrow_tip, Color(0.74, 0.52, 0.28), 1.7)
	_draw_shape(
		canvas,
		PackedVector2Array(
			[
				arrow_tip,
				arrow_tip - direction * 3.4 + side_axis * 1.4,
				arrow_tip - direction * 3.4 - side_axis * 1.4
			]
		),
		Color(0.86, 0.86, 0.78, 0.96),
		OUTLINE,
		0.45
	)
	canvas.draw_line(
		arrow_tail,
		arrow_tail - direction * 2.8 + side_axis * 1.8,
		Color(0.70, 0.62, 0.45, 0.82),
		0.9
	)
	canvas.draw_line(
		arrow_tail,
		arrow_tail - direction * 2.8 - side_axis * 1.8,
		Color(0.70, 0.62, 0.45, 0.82),
		0.9
	)


static func _draw_buckler(canvas: CanvasItem, item_model: Dictionary) -> void:
	var origin := _vector_value(item_model.get("origin", Vector2.ZERO), Vector2.ZERO)
	var color := _color_value(item_model.get("color", default_color("placeholder_buckler")))
	canvas.draw_circle(origin, 5.0, color)
	canvas.draw_circle(origin, 5.0, OUTLINE, false, 1.5)
	canvas.draw_circle(origin, 1.8, color.lightened(0.22))


static func _model_points(item_model: Dictionary) -> Array[Vector2]:
	var origin := _vector_value(item_model.get("origin", Vector2.ZERO), Vector2.ZERO)
	var direction := _safe_direction(item_model.get("direction", Vector2.RIGHT))
	var side_axis := _side_axis(item_model, direction)
	match String(item_model.get("visual_id", "")):
		"placeholder_polearm":
			return [origin - direction * 24.0, origin + direction * 42.0 + side_axis * 3.2]
		"placeholder_bow":
			return [origin + side_axis * 13.0, origin - side_axis * 13.0]
		"placeholder_hatchet":
			return [origin - direction * 5.5, origin + direction * 14.8 + side_axis * 4.2]
		"placeholder_sword":
			return [origin - direction * 5.2, origin + direction * 24.0 + side_axis * 4.4]
		"placeholder_buckler":
			return [origin - Vector2.ONE * 5.0, origin + Vector2.ONE * 5.0]
	return []


static func _draw_shape(
	canvas: CanvasItem,
	points: PackedVector2Array,
	fill: Color,
	outline: Color = OUTLINE,
	outline_width: float = 1.0
) -> void:
	canvas.draw_polygon(points, PackedColorArray([fill]))
	var outline_points := points.duplicate()
	outline_points.append(points[0])
	canvas.draw_polyline(outline_points, outline, outline_width)


static func _safe_direction(value: Variant) -> Vector2:
	if value is Vector2 and value.length() > 0.01:
		return value.normalized()
	return Vector2.RIGHT


static func _side_axis(item_model: Dictionary, direction: Vector2) -> Vector2:
	var value: Variant = item_model.get("side_axis", Vector2.ZERO)
	if value is Vector2 and value.length() > 0.01:
		return value.normalized()
	return direction.orthogonal()


static func _vector_value(value: Variant, fallback: Vector2) -> Vector2:
	return value if value is Vector2 else fallback


static func _color_value(value: Variant) -> Color:
	return value if value is Color else Color(0.82, 0.74, 0.52)
