class_name HumanoidRavenfolkFeatureDrawer
extends RefCounted

const StableHash = preload("res://scripts/core/stable_hash.gd")

const OUTLINE := Color(0.045, 0.035, 0.025, 0.95)
const FEATHER_TINTS := [
	Color(0.15, 0.16, 0.20),
	Color(0.10, 0.14, 0.22),
	Color(0.17, 0.15, 0.14),
	Color(0.14, 0.17, 0.16),
	Color(0.20, 0.18, 0.14)
]


static func draw_back(
	canvas,
	skin: Color,
	proportions: Dictionary,
	feature_ids: Array[String],
	appearance: Dictionary = {}
) -> void:
	if not feature_ids.has("feature_ravenfolk_tail_feathers"):
		return
	var feather_color: Color = _feather_color(skin, appearance)
	var tail_shadow: Color = feather_color.darkened(0.36)
	var waist_width: float = 14.0 * float(canvas._proportion(proportions, "waist_width"))
	var side_turn: float = float(canvas._side_turn_amount())
	var back_turn: float = float(canvas._back_turn_amount())
	var front_turn: float = float(canvas._front_turn_amount())
	var tail_visibility: float = clampf(
		(side_turn + back_turn - front_turn * 0.25 - 0.20) / 0.80, 0.0, 1.0
	)
	if tail_visibility < 0.16:
		return
	var side: float = float(canvas._face_side())
	var forward: Vector2 = canvas._facing_forward()
	var root_x: float = -forward.x * 1.4
	var root_y: float = 5.8 + (1.4 * (1.0 - tail_visibility))
	var spread: float = waist_width * lerpf(0.10, 0.42, maxf(back_turn, side_turn * 0.55))
	var visible_side: float = side if side_turn > 0.45 else 0.0
	for feather_index in 5:
		var offset: float = float(feather_index - 2)
		var x_spread: float = offset * spread * 0.32 + visible_side * side_turn * 3.4
		var tip: Vector2 = canvas._body_point(
			root_x + x_spread,
			root_y + (6.2 + absf(offset) * 0.55) * tail_visibility + back_turn * 2.2
		)
		var base_left: Vector2 = canvas._body_point(
			root_x + offset * spread * 0.18 - 1.1, root_y + 0.5
		)
		var base_right: Vector2 = canvas._body_point(
			root_x + offset * spread * 0.18 + 1.1, root_y + 0.5
		)
		canvas._draw_shape(
			PackedVector2Array([base_left, tip, base_right]),
			feather_color.darkened(0.04 + absf(offset) * 0.03 + (1.0 - tail_visibility) * 0.08),
			tail_shadow,
			0.45
		)


static func draw_body(
	canvas,
	skin: Color,
	proportions: Dictionary,
	feature_ids: Array[String],
	appearance: Dictionary = {}
) -> void:
	if not feature_ids.has("feature_ravenfolk_body_feathers"):
		return
	var feather_color: Color = _feather_color(skin, appearance)
	var highlight: Color = feather_color.lightened(0.18)
	var shadow: Color = feather_color.darkened(0.34)
	var side_turn: float = float(canvas._side_turn_amount())
	var back_turn: float = float(canvas._back_turn_amount())
	var face_side: float = float(canvas._face_side())
	var shoulder_width: float = 18.0 * float(canvas._proportion(proportions, "shoulder_width"))
	var torso_width: float = 15.0 * float(canvas._proportion(proportions, "torso_width"))
	var width_turn_scale: float = lerpf(1.0, 0.66, side_turn) * lerpf(1.0, 0.90, back_turn)
	var upper_patch: PackedVector2Array = canvas._body_polygon(
		[
			Vector2(-shoulder_width * 0.36 * width_turn_scale, -7.4),
			Vector2(0.0, -9.2 - back_turn * 0.4),
			Vector2(shoulder_width * 0.36 * width_turn_scale, -7.4),
			Vector2(torso_width * 0.24 * width_turn_scale, 1.8),
			Vector2(0.0, 4.2),
			Vector2(-torso_width * 0.24 * width_turn_scale, 1.8)
		]
	)
	canvas._draw_shape(
		upper_patch, feather_color.darkened(back_turn * 0.05), Color(0.0, 0.0, 0.0, 0.0), 0.0
	)
	for row_index in 4:
		var count: int = 3 + row_index
		var row_t: float = float(row_index) / 3.0
		var row_width: float = (
			lerpf(shoulder_width * 0.46, torso_width * 0.38, row_t) * width_turn_scale
		)
		var y: float = -6.2 + row_index * 2.45
		for feather_index in count:
			var x_t: float = 0.0 if count <= 1 else float(feather_index) / float(count - 1)
			var x: float = -row_width * 0.5 + row_width * x_t
			var scale: float = lerpf(1.15, 0.82, row_t)
			canvas._draw_shape(
				canvas._body_polygon(
					[
						Vector2(x - 1.2 * scale, y - 0.2),
						Vector2(x + face_side * side_turn * 0.45, y + 2.6 * scale),
						Vector2(x + 1.2 * scale, y - 0.2)
					]
				),
				feather_color.lightened(0.03 + row_t * 0.08).darkened(back_turn * 0.08),
				shadow,
				0.28
			)
			if back_turn < 0.65:
				canvas.draw_line(
					canvas._body_point(x, y),
					canvas._body_point(x, y + 2.0 * scale),
					highlight,
					0.28
				)
	for side_value in [-1.0, 1.0]:
		var side: float = float(side_value)
		var shoulder: Vector2 = canvas._body_point(side * shoulder_width * 0.43, -6.5)
		for fringe_index in 3:
			var tip: Vector2 = (
				shoulder + Vector2(side * (1.8 + fringe_index * 1.2), 2.4 + fringe_index * 1.7)
			)
			canvas.draw_line(
				shoulder + Vector2(side * fringe_index * 0.9, fringe_index * 0.5), tip, shadow, 0.8
			)


static func draw_front(
	canvas,
	skin: Color,
	proportions: Dictionary,
	feature_ids: Array[String],
	appearance: Dictionary = {}
) -> void:
	var head_size: float = float(canvas._proportion(proportions, "head_size"))
	var head_offset: Vector2 = canvas._head_turn_offset()
	var side_turn: float = float(canvas._side_turn_amount())
	var back_turn: float = float(canvas._back_turn_amount())
	var front_visible: bool = back_turn < 0.55
	var side: float = float(canvas._face_side())
	var feather_color: Color = _feather_color(skin, appearance)
	var feather_shadow: Color = feather_color.darkened(0.38)
	var bone_color: Color = Color(0.74, 0.66, 0.42).lerp(feather_color.lightened(0.24), 0.18)
	if feature_ids.has("feature_ravenfolk_head_crest"):
		_draw_head_crest(
			canvas,
			head_size,
			head_offset,
			side_turn,
			back_turn,
			side,
			feather_color,
			feather_shadow
		)
	if front_visible:
		_draw_brow(canvas, head_size, head_offset, side_turn, bone_color, feather_shadow)
		if feature_ids.has("feature_ravenfolk_beak"):
			_draw_beak(canvas, head_size, head_offset, side_turn, side, bone_color)
	if feature_ids.has("feature_ravenfolk_quill_marks") and front_visible:
		var quill_color: Color = feather_shadow.darkened(0.10)
		for mark_index in 3:
			var x: float = -4.4 + mark_index * 4.4
			canvas.draw_line(
				canvas._body_point(x, -6.2), canvas._body_point(x + 0.9, -5.0), quill_color, 0.42
			)


static func near_eye_point(canvas, head_size: float) -> Vector2:
	var head_offset: Vector2 = canvas._head_turn_offset()
	var side: float = float(canvas._face_side())
	return head_offset + Vector2(side * 1.75 * head_size, -14.45)


static func side_beak_points(canvas, head_size: float) -> PackedVector2Array:
	var side: float = float(canvas._face_side())
	var head_offset: Vector2 = canvas._head_turn_offset()
	return PackedVector2Array(
		[
			head_offset + Vector2(side * 0.75 * head_size, -12.9),
			head_offset + Vector2(side * 3.85 * head_size, -11.65),
			head_offset + Vector2(side * 3.35 * head_size, -10.35),
			head_offset + Vector2(side * 0.80 * head_size, -9.15)
		]
	)


static func _variant_index(appearance: Dictionary = {}) -> int:
	var variant_key := String(appearance.get("visual_model_id", ""))
	if variant_key.is_empty():
		variant_key = String(appearance.get("palette_id", ""))
	return StableHash.index(variant_key, FEATHER_TINTS.size())


static func _feather_color(skin: Color, appearance: Dictionary = {}) -> Color:
	var feather_tint: Color = FEATHER_TINTS[_variant_index(appearance)]
	return skin.darkened(0.08).lerp(feather_tint, 0.46)


static func _draw_head_crest(
	canvas,
	head_size: float,
	head_offset: Vector2,
	side_turn: float,
	back_turn: float,
	side: float,
	feather_color: Color,
	feather_shadow: Color
) -> void:
	var crest_count := 5
	var crest_spread: float = lerpf(1.0, 0.50, side_turn) * lerpf(1.0, 0.84, back_turn)
	var crest_height: float = lerpf(1.0, 0.86, side_turn) * lerpf(1.0, 0.94, back_turn)
	var forward: Vector2 = canvas._facing_forward()
	var crest_shift: float = side * side_turn * 1.0 - forward.x * back_turn * 0.5
	var crest_fill: Color = feather_color.lightened(0.07).darkened(back_turn * 0.10)
	for crest_index in crest_count:
		var offset: float = float(crest_index - 2)
		var base: Vector2 = (
			head_offset
			+ Vector2(
				crest_shift + offset * 1.35 * head_size * crest_spread, -18.8 + back_turn * 0.8
			)
		)
		var tip: Vector2 = (
			head_offset
			+ Vector2(
				(
					crest_shift
					+ offset * 2.05 * head_size * crest_spread
					+ side * side_turn * 0.45 * absf(offset)
				),
				-18.8 - (5.4 + absf(offset) * 0.65) * head_size * crest_height
			)
		)
		canvas._draw_shape(
			PackedVector2Array(
				[base + Vector2(-0.9 * head_size, 0.7), tip, base + Vector2(0.9 * head_size, 0.7)]
			),
			crest_fill,
			feather_shadow,
			0.35
		)


static func _draw_brow(
	canvas,
	head_size: float,
	head_offset: Vector2,
	side_turn: float,
	bone_color: Color,
	feather_shadow: Color
) -> void:
	var brow := PackedVector2Array(
		[
			head_offset + Vector2(-4.8 * head_size, -16.2),
			head_offset + Vector2(-1.2 * head_size, -18.0),
			head_offset + Vector2(4.8 * head_size, -16.2),
			head_offset + Vector2(3.8 * head_size, -13.6),
			head_offset + Vector2(-3.8 * head_size, -13.6)
		]
	)
	canvas._draw_shape(brow, feather_shadow, Color(0.0, 0.0, 0.0, 0.0), 0.0)
	if side_turn >= 0.70:
		canvas.draw_circle(near_eye_point(canvas, head_size), 0.85 * head_size, bone_color)
	else:
		canvas.draw_circle(
			head_offset + Vector2(-1.8 * head_size, -14.4), 0.85 * head_size, bone_color
		)
		canvas.draw_circle(
			head_offset + Vector2(1.8 * head_size, -14.4), 0.72 * head_size, bone_color
		)


static func _draw_beak(
	canvas, head_size: float, head_offset: Vector2, side_turn: float, side: float, bone_color: Color
) -> void:
	if side_turn < 0.45:
		canvas._draw_shape(
			PackedVector2Array(
				[
					head_offset + Vector2(-1.9 * head_size, -12.8),
					head_offset + Vector2(1.9 * head_size, -12.8),
					head_offset + Vector2(0.0, -7.0)
				]
			),
			bone_color.darkened(0.06),
			OUTLINE,
			0.62
		)
		canvas.draw_line(
			head_offset + Vector2(0.0, -12.4),
			head_offset + Vector2(0.0, -7.4),
			bone_color.lightened(0.22),
			0.45
		)
		return
	canvas._draw_shape(
		side_beak_points(canvas, head_size), bone_color.darkened(0.06), OUTLINE, 0.62
	)
	canvas.draw_line(
		head_offset + Vector2(side * 1.0 * head_size, -12.6),
		head_offset + Vector2(side * 4.3 * head_size, -11.7),
		bone_color.lightened(0.24),
		0.45
	)
