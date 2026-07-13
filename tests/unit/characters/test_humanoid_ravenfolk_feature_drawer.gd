extends GutTest

const HumanoidRavenfolkFeatureDrawer = preload(
	"res://scripts/characters/humanoid_ravenfolk_feature_drawer.gd"
)


class CanvasStub:
	extends RefCounted

	var side_turn := 0.0
	var back_turn := 0.0
	var front_turn := 0.0
	var face_side := 1.0
	var facing_forward := Vector2.DOWN
	var head_offset := Vector2.ZERO
	var shapes: Array[Dictionary] = []
	var lines: Array[Dictionary] = []
	var circles: Array[Dictionary] = []

	func _proportion(proportions: Dictionary, key: String) -> float:
		return float(proportions.get(key, 1.0))

	func _side_turn_amount() -> float:
		return side_turn

	func _back_turn_amount() -> float:
		return back_turn

	func _front_turn_amount() -> float:
		return front_turn

	func _face_side() -> float:
		return face_side

	func _facing_forward() -> Vector2:
		return facing_forward

	func _head_turn_offset() -> Vector2:
		return head_offset

	func _body_point(x: float, y: float) -> Vector2:
		return Vector2(x, y)

	func _body_polygon(points: Array) -> PackedVector2Array:
		return PackedVector2Array(points)

	func _draw_shape(
		points: PackedVector2Array, fill: Color, outline: Color, width: float
	) -> void:
		shapes.append({"points": points, "fill": fill, "outline": outline, "width": width})

	func draw_line(from: Vector2, to: Vector2, color: Color, width: float = 1.0) -> void:
		lines.append({"from": from, "to": to, "color": color, "width": width})

	func draw_circle(position: Vector2, radius: float, color: Color) -> void:
		circles.append({"position": position, "radius": radius, "color": color})


func test_near_eye_and_side_beak_points_use_head_turn_and_face_side() -> void:
	var canvas := CanvasStub.new()
	canvas.head_offset = Vector2(2, 3)
	canvas.face_side = -1.0

	assert_eq(HumanoidRavenfolkFeatureDrawer.near_eye_point(canvas, 2.0), Vector2(-1.5, -11.45))
	var beak_points := HumanoidRavenfolkFeatureDrawer.side_beak_points(canvas, 2.0)
	_assert_vector_close(beak_points[0], Vector2(0.5, -9.9))
	_assert_vector_close(beak_points[1], Vector2(-5.7, -8.65))
	_assert_vector_close(beak_points[2], Vector2(-4.7, -7.35))
	_assert_vector_close(beak_points[3], Vector2(0.4, -6.15))


func test_feather_variant_and_color_are_stable_for_visual_keys() -> void:
	var appearance := {"visual_model_id": "ravenfolk_guard", "palette_id": "ignored"}
	var first := HumanoidRavenfolkFeatureDrawer._variant_index(appearance)
	var second := HumanoidRavenfolkFeatureDrawer._variant_index(appearance)
	var color := HumanoidRavenfolkFeatureDrawer._feather_color(Color(0.4, 0.3, 0.2), appearance)

	assert_eq(first, second)
	assert_gte(first, 0)
	assert_lt(first, HumanoidRavenfolkFeatureDrawer.FEATHER_TINTS.size())
	assert_ne(color, Color(0.4, 0.3, 0.2))


func test_draw_back_requires_tail_feature_and_visibility() -> void:
	var canvas := CanvasStub.new()

	HumanoidRavenfolkFeatureDrawer.draw_back(
		canvas,
		Color(0.4, 0.3, 0.2),
		{},
		[],
		{}
	)

	assert_true(canvas.shapes.is_empty())

	canvas.side_turn = 0.9
	canvas.back_turn = 0.6
	HumanoidRavenfolkFeatureDrawer.draw_back(
		canvas,
		Color(0.4, 0.3, 0.2),
		{"waist_width": 1.1},
		["feature_ravenfolk_tail_feathers"],
		{"palette_id": "tail"}
	)

	assert_eq(canvas.shapes.size(), 5)


func test_draw_body_adds_feather_shapes_and_highlight_lines() -> void:
	var canvas := CanvasStub.new()
	canvas.side_turn = 0.25
	canvas.back_turn = 0.2

	HumanoidRavenfolkFeatureDrawer.draw_body(
		canvas,
		Color(0.4, 0.3, 0.2),
		{"shoulder_width": 1.1, "torso_width": 0.9},
		["feature_ravenfolk_body_feathers"],
		{"palette_id": "body"}
	)

	assert_gt(canvas.shapes.size(), 10)
	assert_gt(canvas.lines.size(), 10)


func test_draw_front_adds_crest_brow_beak_and_quill_marks_when_visible() -> void:
	var canvas := CanvasStub.new()
	canvas.side_turn = 0.2

	HumanoidRavenfolkFeatureDrawer.draw_front(
		canvas,
		Color(0.4, 0.3, 0.2),
		{"head_size": 1.0},
		[
			"feature_ravenfolk_head_crest",
			"feature_ravenfolk_beak",
			"feature_ravenfolk_quill_marks"
		],
		{"visual_model_id": "front"}
	)

	assert_gt(canvas.shapes.size(), 5)
	assert_gt(canvas.lines.size(), 3)
	assert_eq(canvas.circles.size(), 2)


func test_draw_front_side_turn_uses_side_beak_and_single_near_eye() -> void:
	var canvas := CanvasStub.new()
	canvas.side_turn = 0.8
	canvas.face_side = -1.0

	HumanoidRavenfolkFeatureDrawer.draw_front(
		canvas,
		Color(0.4, 0.3, 0.2),
		{"head_size": 1.0},
		["feature_ravenfolk_beak"],
		{"visual_model_id": "side"}
	)

	assert_eq(canvas.circles.size(), 1)
	assert_gt(canvas.shapes.size(), 1)


func _assert_vector_close(actual: Vector2, expected: Vector2) -> void:
	assert_almost_eq(actual.x, expected.x, 0.001)
	assert_almost_eq(actual.y, expected.y, 0.001)
