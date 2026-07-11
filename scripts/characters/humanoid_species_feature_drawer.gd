# gdlint:disable=max-file-lines
class_name HumanoidSpeciesFeatureDrawer
extends RefCounted

const StableHash = preload("res://scripts/core/stable_hash.gd")

const PEOPLE_TANGLEKIN := "people_tanglekin"
const PEOPLE_TUSKFOLK := "people_tuskfolk"
const PEOPLE_MIREFOLK := "people_mirefolk"
const PEOPLE_ROOTBORN := "people_rootborn"
const PEOPLE_RAVENFOLK := "people_ravenfolk"

const LAYER_BACK := "back"
const LAYER_BODY := "body"
const LAYER_FRONT := "front"

const FEATURE_TANGLEKIN_TAIL := "feature_tanglekin_tail"
const FEATURE_RAVENFOLK_TAIL := "feature_ravenfolk_tail_feathers"
const FEATURE_RAVENFOLK_BODY := "feature_ravenfolk_body_feathers"
const RAVENFOLK_FRONT_FEATURES := [
	"feature_ravenfolk_head_crest", "feature_ravenfolk_beak", "feature_ravenfolk_quill_marks"
]
const OUTLINE := Color(0.045, 0.035, 0.025, 0.95)
const TUSKFOLK_CLAN_TINTS := [
	Color(0.42, 0.18, 0.12),
	Color(0.24, 0.34, 0.30),
	Color(0.48, 0.38, 0.18),
	Color(0.24, 0.25, 0.32),
	Color(0.36, 0.24, 0.18)
]
const MIREFOLK_PATTERN_TINTS := [
	Color(0.76, 0.78, 0.42),
	Color(0.30, 0.58, 0.54),
	Color(0.42, 0.64, 0.32),
	Color(0.24, 0.42, 0.38),
	Color(0.62, 0.70, 0.48)
]
const ROOTBORN_GROWTH_TINTS := [
	Color(0.34, 0.56, 0.25),
	Color(0.46, 0.52, 0.30),
	Color(0.50, 0.44, 0.26),
	Color(0.38, 0.50, 0.42),
	Color(0.28, 0.42, 0.20)
]


static func _face_id(appearance: Dictionary, field_id: String, fallback: String) -> String:
	var value := String(appearance.get(field_id, "")).strip_edges()
	return value if not value.is_empty() else fallback


static func draw_layer(
	avatar,
	people_id: String,
	skin: Color,
	proportions: Dictionary,
	feature_ids: Array[String],
	layer_id: String
) -> bool:
	match people_id:
		PEOPLE_TANGLEKIN:
			return _draw_tanglekin_layer(avatar, skin, proportions, feature_ids, layer_id)
		PEOPLE_TUSKFOLK:
			return _draw_tuskfolk_layer(avatar, skin, proportions, feature_ids, layer_id)
		PEOPLE_MIREFOLK:
			return _draw_mirefolk_layer(avatar, skin, proportions, feature_ids, layer_id)
		PEOPLE_ROOTBORN:
			return _draw_rootborn_layer(avatar, skin, proportions, feature_ids, layer_id)
	return false


static func draw_headgear_face_overlay(
	canvas: HumanoidAvatar2D,
	people_id: String,
	skin: Color,
	proportions: Dictionary,
	_feature_ids: Array[String],
	appearance: Dictionary
) -> void:
	if people_id != PEOPLE_MIREFOLK or canvas._back_turn_amount() > 0.55:
		return
	var head_size := canvas._proportion(proportions, "head_size")
	var head_offset := canvas._head_turn_offset()
	var side_turn := canvas._side_turn_amount()
	var side := canvas._face_side()
	var eye_id := _face_id(appearance, "eye_id", "eyes_mirefolk_high")
	var brow_id := _face_id(appearance, "brow_id", "brows_mirefolk_none")
	var nose_id := _face_id(appearance, "nose_id", "nose_mirefolk_slits")
	var mouth_id := _face_id(appearance, "mouth_id", "mouth_mirefolk_wide")
	_draw_mirefolk_eyes(
		canvas,
		head_size,
		head_offset,
		side_turn,
		side,
		true,
		eye_id.ends_with("_high"),
		Color(0.90, 0.88, 0.62)
	)
	_draw_mirefolk_brow(canvas, head_size, head_offset, skin, brow_id)
	_draw_mirefolk_nose(canvas, head_size, head_offset, side_turn, skin, nose_id)
	_draw_mirefolk_mouth(canvas, head_size, head_offset, skin, mouth_id)


static func feature_ids_for_layer(
	source_ids: Array[String], people_id: String, layer_id: String
) -> Array[String]:
	var result: Array[String] = []
	for feature_id in source_ids:
		if _feature_belongs_to_layer(people_id, String(feature_id), layer_id):
			result.append(String(feature_id))
	return result


static func _draw_tanglekin_layer(
	avatar, skin: Color, proportions: Dictionary, feature_ids: Array[String], layer_id: String
) -> bool:
	if layer_id == LAYER_BACK:
		_draw_tanglekin_back_feature(avatar, skin, proportions, feature_ids)
		return true
	if layer_id == LAYER_FRONT:
		var appearance: Dictionary = avatar.profile.get("appearance", {})
		_draw_tanglekin_feature(avatar, skin, proportions, feature_ids, appearance)
		return true
	return false


static func _draw_tuskfolk_layer(
	avatar, skin: Color, proportions: Dictionary, feature_ids: Array[String], layer_id: String
) -> bool:
	if layer_id != LAYER_FRONT:
		return false
	_draw_tuskfolk_feature(avatar, skin, proportions, feature_ids)
	return true


static func _draw_mirefolk_layer(
	avatar, skin: Color, proportions: Dictionary, feature_ids: Array[String], layer_id: String
) -> bool:
	if layer_id != LAYER_FRONT:
		return false
	var appearance: Dictionary = avatar.profile.get("appearance", {})
	_draw_mirefolk_feature(avatar, skin, proportions, feature_ids, appearance)
	return true


static func _draw_rootborn_layer(
	avatar, skin: Color, proportions: Dictionary, feature_ids: Array[String], layer_id: String
) -> bool:
	if layer_id != LAYER_FRONT:
		return false
	var appearance: Dictionary = avatar.profile.get("appearance", {})
	_draw_rootborn_feature(avatar, skin, proportions, feature_ids, appearance)
	return true


static func _feature_belongs_to_layer(
	people_id: String, feature_id: String, layer_id: String
) -> bool:
	match people_id:
		PEOPLE_TANGLEKIN:
			return _tanglekin_feature_belongs_to_layer(feature_id, layer_id)
		PEOPLE_RAVENFOLK:
			return _ravenfolk_feature_belongs_to_layer(feature_id, layer_id)
	return layer_id == LAYER_FRONT


static func _tanglekin_feature_belongs_to_layer(feature_id: String, layer_id: String) -> bool:
	if layer_id == LAYER_BACK:
		return feature_id == FEATURE_TANGLEKIN_TAIL
	if layer_id == LAYER_FRONT:
		return feature_id != FEATURE_TANGLEKIN_TAIL
	return false


static func _ravenfolk_feature_belongs_to_layer(feature_id: String, layer_id: String) -> bool:
	if layer_id == LAYER_BACK:
		return feature_id == FEATURE_RAVENFOLK_TAIL
	if layer_id == LAYER_BODY:
		return feature_id == FEATURE_RAVENFOLK_BODY
	if layer_id == LAYER_FRONT:
		return feature_id in RAVENFOLK_FRONT_FEATURES
	return false


static func _draw_tanglekin_back_feature(
	canvas: HumanoidAvatar2D, skin: Color, _proportions: Dictionary, feature_ids: Array[String]
) -> void:
	if not feature_ids.has("feature_tanglekin_tail"):
		return
	var side_turn := canvas._side_turn_amount()
	var back_turn := canvas._back_turn_amount()
	var front_turn := canvas._front_turn_amount()
	var curl_side := canvas._face_side()
	var tail_side := curl_side if side_turn > 0.08 else 1.0
	var root_y := 4.7 + front_turn * 1.2 - back_turn * 1.4
	var middle_y := 8.8 + front_turn * 1.0 - back_turn * 3.0
	var curl_y := 6.1 - front_turn * 0.5 - back_turn * 1.1
	var tip_y := 2.8 - front_turn * 0.6 + back_turn * 2.2
	var visible_turn := maxf(side_turn, back_turn * 0.78)
	var side_reach := lerpf(1.4, 10.2, visible_turn)
	if back_turn > 0.55 and side_turn < 0.18:
		tail_side *= 0.38
	var back_lift := lerpf(0.0, 2.2, back_turn)
	var root := canvas._body_point(-canvas._facing_forward().x * 0.9, root_y)
	var middle := canvas._body_point(tail_side * side_reach * 0.58, middle_y)
	var curl := canvas._body_point(tail_side * side_reach, curl_y - back_lift)
	var tip := canvas._body_point(tail_side * side_reach * 0.74, tip_y - back_lift)
	var tail_color := skin.darkened(0.10)
	var tail_shadow := skin.darkened(0.38)
	canvas.draw_line(root, middle, tail_shadow, 4.0)
	canvas.draw_line(middle, curl, tail_shadow, 3.6)
	canvas.draw_line(curl, tip, tail_shadow, 3.1)
	canvas.draw_line(root, middle, tail_color, 2.55)
	canvas.draw_line(middle, curl, tail_color.lightened(0.04), 2.25)
	canvas.draw_line(curl, tip, tail_color.lightened(0.08), 1.85)
	canvas.draw_circle(root, 1.7, tail_shadow)
	canvas.draw_circle(root, 1.05, tail_color)
	canvas.draw_circle(tip, 1.25, tail_shadow)
	canvas.draw_circle(tip, 0.78, tail_color.lightened(0.08))


static func _draw_tanglekin_feature(
	canvas: HumanoidAvatar2D,
	skin: Color,
	proportions: Dictionary,
	feature_ids: Array[String],
	appearance: Dictionary = {}
) -> void:
	var head_size := canvas._proportion(proportions, "head_size")
	var head_offset := canvas._head_turn_offset()
	var side_turn := canvas._side_turn_amount()
	var back_turn := canvas._back_turn_amount()
	var front_visible := back_turn < 0.55
	var side := canvas._face_side()
	var fur_shadow := skin.darkened(0.30)
	var eye_id := _face_id(appearance, "eye_id", "eyes_tanglekin_amber")
	var brow_id := _face_id(appearance, "brow_id", "brows_tanglekin_tufted")
	var nose_id := _face_id(appearance, "nose_id", "nose_tanglekin_muzzle_round")
	var mouth_id := _face_id(appearance, "mouth_id", "mouth_tanglekin_short")
	var mark_id := _face_id(appearance, "facial_mark_id", "")
	if feature_ids.has("feature_tanglekin_grasping_hands"):
		_draw_tanglekin_grasping_hands(canvas, skin, proportions, fur_shadow)
	if front_visible:
		_draw_tanglekin_front_or_side_ears(canvas, skin, head_size, head_offset, side_turn, side)
		if feature_ids.has("feature_tanglekin_muzzle"):
			_draw_tanglekin_muzzle(
				canvas, skin, head_size, head_offset, side_turn, side, fur_shadow,
				eye_id, nose_id, mouth_id, mark_id
			)
	elif back_turn > 0.55:
		_draw_tanglekin_rear_ears(canvas, skin, head_size, head_offset, side_turn)
	_draw_tanglekin_brow(canvas, brow_id, head_size, head_offset, fur_shadow, front_visible)


static func _draw_tanglekin_grasping_hands(
	canvas: HumanoidAvatar2D, skin: Color, proportions: Dictionary, fur_shadow: Color
) -> void:
	var hand_size := canvas._proportion(proportions, "hand_size")
	var foot_size := canvas._proportion(proportions, "foot_size")
	var hands_covered := canvas.equipped_visuals.has("gloves")
	var feet_covered := canvas.equipped_visuals.has("boots")
	for limb_side in [-1.0, 1.0]:
		var hand := canvas._hand_anchor(limb_side, proportions) + canvas._hand_sway(limb_side)
		var foot := canvas._foot_anchor(limb_side, proportions) + canvas._stride_offset(limb_side)
		if not hands_covered:
			canvas.draw_circle(hand, 2.9 * hand_size, OUTLINE)
			canvas.draw_circle(hand, 2.1 * hand_size, skin.lightened(0.07))
			canvas.draw_circle(hand + Vector2(limb_side * 1.0, -0.4), 0.62 * hand_size, fur_shadow)
			canvas.draw_line(
				hand + Vector2(-limb_side * 0.55, 0.55),
				hand + Vector2(limb_side * 1.20, 1.20),
				fur_shadow,
				0.44
			)
		if not feet_covered:
			canvas.draw_circle(foot + Vector2(0.0, 0.8), 2.7 * foot_size, OUTLINE)
			canvas.draw_circle(foot + Vector2(0.0, 0.8), 1.9 * foot_size, skin.darkened(0.03))
			canvas.draw_line(
				foot + Vector2(-limb_side * 1.7, -0.4),
				foot + Vector2(limb_side * 1.8, 0.5),
				fur_shadow,
				0.65
			)


static func _draw_tanglekin_front_or_side_ears(
	canvas: HumanoidAvatar2D,
	skin: Color,
	head_size: float,
	head_offset: Vector2,
	side_turn: float,
	side: float
) -> void:
	if side_turn < 0.72:
		for ear_side in [-1.0, 1.0]:
			var ear_center := head_offset + Vector2(ear_side * 7.0 * head_size, -15.1)
			canvas.draw_circle(ear_center, 2.0 * head_size, OUTLINE)
			canvas.draw_circle(ear_center, 1.35 * head_size, skin.darkened(0.05))
		return
	var ear_center := head_offset + Vector2(-side * 5.6 * head_size, -15.4)
	canvas.draw_circle(ear_center, 1.75 * head_size, OUTLINE)
	canvas.draw_circle(ear_center, 1.12 * head_size, skin.darkened(0.05))


static func _draw_tanglekin_rear_ears(
	canvas: HumanoidAvatar2D, skin: Color, head_size: float, head_offset: Vector2, side_turn: float
) -> void:
	var rear_ear_scale := lerpf(1.0, 0.72, side_turn)
	for ear_side in [-1.0, 1.0]:
		var ear_center := head_offset + Vector2(ear_side * 6.4 * head_size * rear_ear_scale, -15.0)
		canvas.draw_circle(ear_center, 1.9 * head_size * rear_ear_scale, OUTLINE)
		canvas.draw_circle(ear_center, 1.18 * head_size * rear_ear_scale, skin.darkened(0.14))


static func _draw_tanglekin_muzzle(
	canvas: HumanoidAvatar2D,
	skin: Color,
	head_size: float,
	head_offset: Vector2,
	side_turn: float,
	side: float,
	fur_shadow: Color,
	eye_id: String,
	nose_id: String,
	mouth_id: String,
	mark_id: String
) -> void:
	var muzzle_color := skin.lightened(0.13)
	var eye_color := Color(0.035, 0.027, 0.018)
	if eye_id.ends_with("_amber"):
		eye_color = Color(0.78, 0.53, 0.16)
	var long_muzzle := nose_id.ends_with("_long")
	var muzzle_width := 9.0 if long_muzzle else 7.6
	var eye_spacing := 3.1 if long_muzzle else 2.6
	if side_turn < 0.58:
		canvas._draw_outlined_oval(
			Rect2(
				head_offset + Vector2(-muzzle_width * 0.5 * head_size, -12.3),
				Vector2(muzzle_width * head_size, 4.3 * head_size)
			),
			muzzle_color,
			OUTLINE,
			0.55
		)
		canvas.draw_circle(
			head_offset + Vector2(-eye_spacing * head_size, -14.8), 0.75 * head_size, eye_color
		)
		canvas.draw_circle(
			head_offset + Vector2(eye_spacing * head_size, -14.8), 0.75 * head_size, eye_color
		)
		_draw_tanglekin_mouth(canvas, head_offset, head_size, fur_shadow, mouth_id)
		_draw_tanglekin_face_mark(canvas, head_offset, head_size, fur_shadow, mark_id)
		return
	canvas._draw_outlined_oval(
		_tanglekin_side_muzzle_rect_for_face(canvas, head_size, long_muzzle), muzzle_color, OUTLINE, 0.55
	)
	canvas.draw_circle(
		head_offset + Vector2(side * 2.0 * head_size, -14.8), 0.78 * head_size, eye_color
	)
	_draw_tanglekin_side_mouth(canvas, head_offset, head_size, side, fur_shadow, mouth_id)
	_draw_tanglekin_face_mark(canvas, head_offset, head_size, fur_shadow, mark_id)


static func _draw_tanglekin_brow(
	canvas: HumanoidAvatar2D,
	brow_id: String,
	head_size: float,
	head_offset: Vector2,
	fur_shadow: Color,
	front_visible: bool
) -> void:
	if brow_id.ends_with("_tufted"):
		for tuft_index in 3:
			var offset := float(tuft_index - 1)
			canvas.draw_line(
				head_offset + Vector2(offset * 1.6 * head_size, -18.6),
				head_offset + Vector2(offset * 2.4 * head_size, -22.4 - absf(offset) * 0.6),
				fur_shadow,
				1.0
			)
	elif front_visible:
		canvas.draw_line(
			head_offset + Vector2(-3.8 * head_size, -16.5),
			head_offset + Vector2(3.8 * head_size, -16.3),
			fur_shadow,
			0.9
		)


static func _tanglekin_side_muzzle_rect_for_face(
	canvas: HumanoidAvatar2D, head_size: float, long_muzzle: bool
) -> Rect2:
	var rect := tanglekin_side_muzzle_rect(canvas, head_size)
	if long_muzzle:
		rect.size.x *= 1.22
	return rect


static func _draw_tanglekin_mouth(
	canvas: HumanoidAvatar2D,
	head_offset: Vector2,
	head_size: float,
	fur_shadow: Color,
	mouth_id: String
) -> void:
	var start := head_offset + Vector2(-1.8 * head_size, -10.1)
	var end := head_offset + Vector2(1.9 * head_size, -10.0)
	if mouth_id.ends_with("_grin"):
		canvas.draw_line(start, head_offset + Vector2(0.0, -9.55), fur_shadow, 0.75)
		canvas.draw_line(head_offset + Vector2(0.0, -9.55), end, fur_shadow, 0.75)
		return
	canvas.draw_line(start, end, fur_shadow, 0.75)


static func _draw_tanglekin_side_mouth(
	canvas: HumanoidAvatar2D,
	head_offset: Vector2,
	head_size: float,
	side: float,
	fur_shadow: Color,
	mouth_id: String
) -> void:
	var start := head_offset + Vector2(side * 2.0 * head_size, -10.5)
	var end := head_offset + Vector2(side * 3.3 * head_size, -10.6)
	if mouth_id.ends_with("_grin"):
		end.y -= 0.45
	canvas.draw_line(start, end, fur_shadow, 0.65)


static func _draw_tanglekin_face_mark(
	canvas: HumanoidAvatar2D,
	head_offset: Vector2,
	head_size: float,
	color: Color,
	mark_id: String
) -> void:
	if mark_id.ends_with("_cheeks"):
		for side in [-1.0, 1.0]:
			canvas.draw_circle(head_offset + Vector2(side * 4.6 * head_size, -12.8), 0.46, color)
	elif mark_id.ends_with("_brow"):
		canvas.draw_line(
			head_offset + Vector2(-2.4 * head_size, -17.7),
			head_offset + Vector2(2.4 * head_size, -17.7),
			color,
			0.55
		)


static func _draw_tuskfolk_feature(
	canvas: HumanoidAvatar2D,
	skin: Color,
	proportions: Dictionary,
	feature_ids: Array[String],
	appearance: Dictionary = {}
) -> void:
	var head_size := canvas._proportion(proportions, "head_size")
	var head_offset := canvas._head_turn_offset()
	var side_turn := canvas._side_turn_amount()
	var back_turn := canvas._back_turn_amount()
	var front_visible := back_turn < 0.55
	var shoulder_width := 18.0 * canvas._proportion(proportions, "shoulder_width")
	var tusk_color := Color(0.86, 0.78, 0.58)
	var tusk_length := 9.2 if feature_ids.has("feature_tusks_broad") else 7.0
	var variant_key := String(appearance.get("visual_model_id", ""))
	if variant_key.is_empty():
		variant_key = String(appearance.get("palette_id", ""))
	var variant_index := StableHash.index(variant_key, TUSKFOLK_CLAN_TINTS.size())
	var clan_color: Color = skin.darkened(0.12).lerp(TUSKFOLK_CLAN_TINTS[variant_index], 0.56)
	var ring_color := Color(0.58, 0.43, 0.22).lerp(clan_color.lightened(0.12), 0.24)
	_draw_tuskfolk_head_shape(canvas, skin, head_size, head_offset, front_visible)
	if (
		front_visible
		and feature_ids.has("feature_tuskfolk_clan_marks")
		and not canvas.equipped_visuals.has("chest")
	):
		_draw_tuskfolk_clan_marks(canvas, shoulder_width, clan_color)
	if front_visible:
		_draw_tuskfolk_tusks(
			canvas, head_size, head_offset, side_turn, tusk_length, tusk_color, ring_color
		)
static func _draw_tuskfolk_head_shape(
	canvas: HumanoidAvatar2D,
	skin: Color,
	head_size: float,
	head_offset: Vector2,
	front_visible: bool
) -> void:
	if front_visible:
		var jaw := PackedVector2Array(
			[
				head_offset + Vector2(-5.8 * head_size, -10.2),
				head_offset + Vector2(-3.6 * head_size, -7.2),
				head_offset + Vector2(0.0, -6.1),
				head_offset + Vector2(3.6 * head_size, -7.2),
				head_offset + Vector2(5.8 * head_size, -10.2),
				head_offset + Vector2(3.2 * head_size, -8.6),
				head_offset + Vector2(-3.2 * head_size, -8.6)
			]
		)
		canvas._draw_shape(jaw, skin.darkened(0.10), Color(0.0, 0.0, 0.0, 0.0), 0.0)
		var brow := PackedVector2Array(
			[
				head_offset + Vector2(-6.0 * head_size, -14.8),
				head_offset + Vector2(0.0, -16.6),
				head_offset + Vector2(6.0 * head_size, -14.8),
				head_offset + Vector2(4.5 * head_size, -13.2),
				head_offset + Vector2(-4.5 * head_size, -13.2)
			]
		)
		canvas._draw_shape(brow, skin.darkened(0.16), Color(0.0, 0.0, 0.0, 0.0), 0.0)
	else:
		canvas._draw_oval(
			Rect2(head_offset + Vector2(-4.6 * head_size, -15.4), Vector2(9.2 * head_size, 7.6)),
			skin.darkened(0.14)
		)


static func _draw_tuskfolk_clan_marks(
	canvas: HumanoidAvatar2D, shoulder_width: float, clan_color: Color
) -> void:
	canvas.draw_line(
		canvas._body_point(-shoulder_width * 0.34, -5.4),
		canvas._body_point(-shoulder_width * 0.14, -1.8),
		clan_color.darkened(0.30),
		1.0
	)
	canvas.draw_line(
		canvas._body_point(shoulder_width * 0.34, -5.4),
		canvas._body_point(shoulder_width * 0.14, -1.8),
		clan_color.darkened(0.30),
		1.0
	)
	canvas.draw_line(
		canvas._body_point(-shoulder_width * 0.28, -2.0),
		canvas._body_point(shoulder_width * 0.28, -2.3),
		clan_color.lightened(0.10),
		0.65
	)


static func _draw_tuskfolk_tusks(
	canvas: HumanoidAvatar2D,
	head_size: float,
	head_offset: Vector2,
	side_turn: float,
	tusk_length: float,
	tusk_color: Color,
	ring_color: Color
) -> void:
	if side_turn < 0.45:
		var front_tusk_x := minf(tusk_length * 0.55, 5.2)
		canvas._draw_shape(
			PackedVector2Array(
				[
					head_offset + Vector2(-2.5 * head_size, -9.8),
					head_offset + Vector2(-front_tusk_x * head_size, -4.8),
					head_offset + Vector2(-3.9 * head_size, -10.6)
				]
			),
			tusk_color,
			OUTLINE,
			0.85
		)
		canvas._draw_shape(
			PackedVector2Array(
				[
					head_offset + Vector2(2.5 * head_size, -9.8),
					head_offset + Vector2(front_tusk_x * head_size, -4.8),
					head_offset + Vector2(3.9 * head_size, -10.6)
				]
			),
			tusk_color,
			OUTLINE,
			0.85
		)
		canvas.draw_line(
			head_offset + Vector2(-3.9 * head_size, -8.8),
			head_offset + Vector2(-4.7 * head_size, -7.6),
			ring_color,
			0.85
		)
		canvas.draw_line(
			head_offset + Vector2(3.9 * head_size, -8.8),
			head_offset + Vector2(4.7 * head_size, -7.6),
			ring_color,
			0.85
		)
	else:
		var side := canvas._face_side()
		canvas._draw_shape(
			tuskfolk_side_tusk_points(canvas, head_size, tusk_length), tusk_color, OUTLINE, 0.85
		)
		canvas.draw_line(
			head_offset + Vector2(side * 2.8 * head_size, -8.8),
			head_offset + Vector2(side * 3.5 * head_size, -7.9),
			ring_color,
			0.85
		)


static func _draw_mirefolk_feature(
	canvas: HumanoidAvatar2D,
	skin: Color,
	proportions: Dictionary,
	feature_ids: Array[String],
	appearance: Dictionary = {}
) -> void:
	var head_size := canvas._proportion(proportions, "head_size")
	var head_offset := canvas._head_turn_offset()
	var eye_color := Color(0.90, 0.88, 0.62)
	var variant_key := String(appearance.get("visual_model_id", ""))
	if variant_key.is_empty():
		variant_key = String(appearance.get("palette_id", ""))
	var variant_index := StableHash.index(variant_key, MIREFOLK_PATTERN_TINTS.size())
	var pattern_color: Color = MIREFOLK_PATTERN_TINTS[variant_index].lerp(
		skin.lightened(0.12), 0.42
	)
	var back_turn := canvas._back_turn_amount()
	var side_turn := canvas._side_turn_amount()
	var front_visible := back_turn < 0.55
	var side := canvas._face_side()
	var eye_id := _face_id(appearance, "eye_id", "eyes_mirefolk_high")
	var brow_id := _face_id(appearance, "brow_id", "brows_mirefolk_none")
	var nose_id := _face_id(appearance, "nose_id", "nose_mirefolk_slits")
	var mouth_id := _face_id(appearance, "mouth_id", "mouth_mirefolk_wide")
	var mark_id := _face_id(appearance, "facial_mark_id", "")
	if feature_ids.has("feature_mirefolk_webbed_hands"):
		_draw_mirefolk_webbing(canvas, skin, proportions, pattern_color)
	_draw_mirefolk_eyes(
		canvas,
		head_size,
		head_offset,
		side_turn,
		side,
		front_visible,
		eye_id.ends_with("_high"),
		eye_color
	)
	if front_visible and mark_id.ends_with("_reed"):
		_draw_mirefolk_reed_marks(
			canvas, head_size, head_offset, side_turn, variant_index, pattern_color
		)
	elif front_visible and mark_id.ends_with("_spots"):
		_draw_mirefolk_face_spots(canvas, head_size, head_offset, pattern_color)
	elif front_visible and mark_id.is_empty() and feature_ids.has("feature_mirefolk_reed_marks"):
		_draw_mirefolk_reed_marks(
			canvas, head_size, head_offset, side_turn, variant_index, pattern_color
		)
	if front_visible:
		_draw_mirefolk_brow(canvas, head_size, head_offset, skin, brow_id)
		_draw_mirefolk_nose(canvas, head_size, head_offset, side_turn, skin, nose_id)
		_draw_mirefolk_mouth(canvas, head_size, head_offset, skin, mouth_id)
	else:
		_draw_mirefolk_back_spots(canvas, variant_index, pattern_color)


static func _draw_mirefolk_webbing(
	canvas: HumanoidAvatar2D, skin: Color, proportions: Dictionary, pattern_color: Color
) -> void:
	var web_color := skin.lightened(0.22).lerp(pattern_color.lightened(0.08), 0.28)
	var hands_covered := canvas.equipped_visuals.has("gloves")
	var feet_covered := canvas.equipped_visuals.has("boots")
	for limb_side in [-1.0, 1.0]:
		var hand := canvas._hand_anchor(limb_side, proportions) + canvas._hand_sway(limb_side)
		if not hands_covered:
			canvas._draw_shape(
				PackedVector2Array(
					[
						hand + Vector2(-2.6 * limb_side, -1.5),
						hand + Vector2(2.8 * limb_side, -0.8),
						hand + Vector2(2.0 * limb_side, 2.6),
						hand + Vector2(-1.8 * limb_side, 2.0)
					]
				),
				web_color,
				OUTLINE,
				0.45
			)
		var foot := canvas._foot_anchor(limb_side, proportions) + canvas._stride_offset(limb_side)
		if not feet_covered:
			canvas._draw_shape(
				PackedVector2Array(
					[
						foot + Vector2(-2.4 * limb_side, 1.2),
						foot + Vector2(2.8 * limb_side, 1.0),
						foot + Vector2(3.0 * limb_side, 3.4),
						foot + Vector2(-2.0 * limb_side, 3.2)
					]
				),
				web_color.darkened(0.05),
				OUTLINE,
				0.35
			)


static func _draw_mirefolk_eyes(
	canvas: HumanoidAvatar2D,
	head_size: float,
	head_offset: Vector2,
	side_turn: float,
	side: float,
	front_visible: bool,
	has_high_eyes: bool,
	eye_color: Color
) -> void:
	if has_high_eyes:
		_draw_mirefolk_high_eyes(
			canvas, head_size, head_offset, side_turn, side, front_visible, eye_color
		)
	elif front_visible:
		_draw_mirefolk_low_eyes(canvas, head_size, head_offset, side_turn, eye_color)


static func _draw_mirefolk_high_eyes(
	canvas: HumanoidAvatar2D,
	head_size: float,
	head_offset: Vector2,
	side_turn: float,
	side: float,
	front_visible: bool,
	eye_color: Color
) -> void:
	if not front_visible:
		# Eyes do not belong on a rear-facing Mirefolk head. Back spots and the
		# head silhouette already carry the rear read.
		return
	if side_turn > 0.70:
		var near_eye := head_offset + Vector2(side * 4.5 * head_size, -18.0)
		var far_eye := head_offset + Vector2(-side * 2.5 * head_size, -18.5)
		canvas.draw_circle(far_eye, 0.42 * head_size, eye_color.darkened(0.18))
		canvas.draw_circle(near_eye, 1.28 * head_size, eye_color)
		canvas.draw_circle(near_eye, 0.46 * head_size, OUTLINE)
	else:
		canvas.draw_circle(
			head_offset + Vector2(-4.8 * head_size, -18.1), 1.18 * head_size, eye_color
		)
		canvas.draw_circle(
			head_offset + Vector2(4.8 * head_size, -18.1), 1.18 * head_size, eye_color
		)
		canvas.draw_circle(head_offset + Vector2(-4.8 * head_size, -18.1), 0.44 * head_size, OUTLINE)
		canvas.draw_circle(head_offset + Vector2(4.8 * head_size, -18.1), 0.44 * head_size, OUTLINE)


static func _draw_mirefolk_low_eyes(
	canvas: HumanoidAvatar2D,
	head_size: float,
	head_offset: Vector2,
	side_turn: float,
	eye_color: Color
) -> void:
	canvas.draw_circle(
		head_offset + Vector2(-4.1 * head_size, -16.9), 1.55 * head_size, eye_color.lightened(0.05)
	)
	canvas.draw_circle(head_offset + Vector2(-4.1 * head_size, -16.9), 0.72 * head_size, OUTLINE)
	if side_turn < 0.70:
		canvas.draw_circle(
			head_offset + Vector2(4.1 * head_size, -16.9),
			1.55 * head_size,
			eye_color.lightened(0.05)
		)
		canvas.draw_circle(head_offset + Vector2(4.1 * head_size, -16.9), 0.72 * head_size, OUTLINE)


static func _draw_mirefolk_reed_marks(
	canvas: HumanoidAvatar2D,
	head_size: float,
	head_offset: Vector2,
	side_turn: float,
	variant_index: int,
	pattern_color: Color
) -> void:
	if canvas._face_detail_visible_on_side(-1.0):
		canvas.draw_line(
			canvas._face_mark_point(-5.8, -15.4, head_size),
			canvas._face_mark_point(-2.0, -12.4, head_size),
			pattern_color.darkened(0.28),
			0.8
		)
		canvas.draw_circle(
			canvas._face_mark_point(-4.8, -10.2, head_size), 0.55, pattern_color.darkened(0.24)
		)
	if canvas._face_detail_visible_on_side(1.0):
		canvas.draw_line(
			canvas._face_mark_point(5.6, -15.0, head_size),
			canvas._face_mark_point(2.0, -12.0, head_size),
			pattern_color.darkened(0.22),
			0.7
		)
		canvas.draw_circle(
			canvas._face_mark_point(4.6, -10.1, head_size), 0.55, pattern_color.darkened(0.24)
		)
	if variant_index > 2 and side_turn < 0.70:
		canvas.draw_line(
			head_offset + Vector2(-3.0 * head_size, -17.2),
			head_offset + Vector2(3.2 * head_size, -17.1),
			pattern_color.lightened(0.08),
			0.55
		)


static func _draw_mirefolk_brow(
	canvas: HumanoidAvatar2D,
	head_size: float,
	head_offset: Vector2,
	skin: Color,
	brow_id: String
) -> void:
	if not brow_id.ends_with("_ridge"):
		return
	canvas.draw_line(
		head_offset + Vector2(-4.6 * head_size, -19.8),
		head_offset + Vector2(4.6 * head_size, -19.7),
		skin.darkened(0.32),
		0.55
	)


static func _draw_mirefolk_nose(
	canvas: HumanoidAvatar2D,
	head_size: float,
	head_offset: Vector2,
	side_turn: float,
	skin: Color,
	nose_id: String
) -> void:
	if not nose_id.ends_with("_slits"):
		return
	var nose_color := skin.darkened(0.32)
	canvas.draw_line(
		head_offset + Vector2(-1.4 * head_size, -13.0),
		head_offset + Vector2(-1.2 * head_size, -11.8),
		nose_color,
		0.55
	)
	if side_turn < 0.70:
		canvas.draw_line(
			head_offset + Vector2(1.4 * head_size, -13.0),
			head_offset + Vector2(1.2 * head_size, -11.8),
			nose_color,
			0.55
		)


static func _draw_mirefolk_mouth(
	canvas: HumanoidAvatar2D,
	head_size: float,
	head_offset: Vector2,
	skin: Color,
	mouth_id: String
) -> void:
	var width := 3.0 if mouth_id.ends_with("_short") else 5.3
	canvas.draw_line(
		head_offset + Vector2(-width * head_size, -11.0),
		head_offset + Vector2(width * head_size, -10.8),
		skin.darkened(0.22),
		0.9
	)


static func _draw_mirefolk_face_spots(
	canvas: HumanoidAvatar2D, head_size: float, head_offset: Vector2, pattern_color: Color
) -> void:
	for side in [-1.0, 1.0]:
		canvas.draw_circle(
			head_offset + Vector2(side * 5.0 * head_size, -13.3),
			0.55,
			pattern_color.darkened(0.26)
		)


static func _draw_mirefolk_back_spots(
	canvas: HumanoidAvatar2D, variant_index: int, pattern_color: Color
) -> void:
	for spot_index in 4:
		canvas.draw_circle(
			canvas._body_point(
				-4.0 + spot_index * 2.6, -4.4 + float((spot_index + variant_index) % 3) * 1.8
			),
			0.65,
			pattern_color.darkened(0.22)
		)


static func _draw_rootborn_feature(
	canvas: HumanoidAvatar2D,
	skin: Color,
	proportions: Dictionary,
	feature_ids: Array[String],
	appearance: Dictionary = {}
) -> void:
	var head_size := canvas._proportion(proportions, "head_size")
	var head_offset := canvas._head_turn_offset()
	var side_turn := canvas._side_turn_amount()
	var back_turn := canvas._back_turn_amount()
	var side := canvas._face_side()
	var front_visible := back_turn < 0.55
	var variant_key := String(appearance.get("visual_model_id", ""))
	if variant_key.is_empty():
		variant_key = String(appearance.get("palette_id", ""))
	var variant_index := StableHash.index(variant_key, ROOTBORN_GROWTH_TINTS.size())
	var growth_tint: Color = ROOTBORN_GROWTH_TINTS[variant_index]
	var leaf := Color(0.30, 0.50, 0.24).lerp(growth_tint.lightened(0.10), 0.45)
	var lichen := Color(0.55, 0.63, 0.42).lerp(growth_tint.lightened(0.18), 0.32)
	var root_color := skin.darkened(0.32)
	var torso_width := 15.0 * canvas._proportion(proportions, "torso_width")
	var waist_width := 14.0 * canvas._proportion(proportions, "waist_width")
	var bark_line := root_color.darkened(0.12).lerp(growth_tint.darkened(0.20), 0.18)
	if not canvas.equipped_visuals.has("chest"):
		_draw_rootborn_body_growth(canvas, torso_width, waist_width, variant_index, bark_line, lichen)
	if not canvas.equipped_visuals.has("boots"):
		_draw_rootborn_roots(canvas, proportions, root_color)
	if feature_ids.has("feature_rootborn_branch_crown"):
		_draw_rootborn_branch_crown(
			canvas,
			skin,
			head_size,
			head_offset,
			side_turn,
			back_turn,
			side,
			variant_index,
			leaf,
			lichen
		)
	if feature_ids.has("feature_rootborn_leaf_crown"):
		_draw_rootborn_leaf_crown(
			canvas, skin, head_size, head_offset, side_turn, side, variant_index, leaf
		)
	if feature_ids.has("feature_rootborn_bark_marks"):
		_draw_rootborn_bark_marks(
			canvas,
			skin,
			head_size,
			head_offset,
			torso_width,
			variant_index,
			root_color,
			lichen,
			front_visible,
			side_turn,
			not canvas.equipped_visuals.has("chest")
		)


static func _draw_rootborn_body_growth(
	canvas: HumanoidAvatar2D,
	torso_width: float,
	waist_width: float,
	variant_index: int,
	bark_line: Color,
	lichen: Color
) -> void:
	canvas.draw_line(
		canvas._body_point(-torso_width * 0.28, -3.8),
		canvas._body_point(torso_width * 0.26, -3.2),
		bark_line,
		0.55
	)
	canvas.draw_line(
		canvas._body_point(-torso_width * 0.22, 0.4),
		canvas._body_point(torso_width * 0.24, -0.1),
		bark_line.lightened(0.08),
		0.5
	)
	canvas.draw_line(
		canvas._body_point(-waist_width * 0.25, 4.6),
		canvas._body_point(waist_width * 0.24, 4.0),
		bark_line,
		0.55
	)
	for patch_index in 2 + variant_index % 2:
		canvas.draw_circle(
			canvas._body_point(
				-torso_width * 0.26 + float(patch_index) * torso_width * 0.22,
				-5.8 + float((patch_index + variant_index) % 3) * 3.4
			),
			0.65,
			lichen.darkened(0.08)
		)


static func _draw_rootborn_roots(
	canvas: HumanoidAvatar2D, proportions: Dictionary, root_color: Color
) -> void:
	for root_side in [-1.0, 1.0]:
		var foot := canvas._foot_anchor(root_side, proportions) + canvas._stride_offset(root_side)
		canvas.draw_line(
			foot + Vector2(root_side * 1.4, 1.5),
			foot + Vector2(root_side * 4.8, 3.8),
			root_color,
			0.9
		)
		canvas.draw_line(
			foot + Vector2(root_side * 0.1, 1.8),
			foot + Vector2(root_side * 2.9, 4.4),
			root_color.darkened(0.10),
			0.8
		)
		canvas.draw_line(
			foot + Vector2(root_side * -1.1, 1.7),
			foot + Vector2(root_side * -3.5, 3.7),
			root_color.darkened(0.05),
			0.65
		)


static func _draw_rootborn_branch_crown(
	canvas: HumanoidAvatar2D,
	skin: Color,
	head_size: float,
	head_offset: Vector2,
	side_turn: float,
	back_turn: float,
	side: float,
	variant_index: int,
	leaf: Color,
	lichen: Color
) -> void:
	var branch_color := skin.darkened(0.42)
	var left_lift := 21.0 + float(variant_index % 3) * 0.55
	var right_lift := 21.4 + float((variant_index + 1) % 3) * 0.55
	var near_scale := 1.0 + side_turn * 0.10
	var far_scale := 1.0 - side_turn * 0.28
	var left_scale := far_scale if side > 0.0 else near_scale
	var right_scale := near_scale if side > 0.0 else far_scale
	var crown_shift := side * side_turn * 1.2 - canvas._facing_forward().x * back_turn * 0.8
	var left_base := head_offset + Vector2(crown_shift - 2.4 * head_size * left_scale, -19.0)
	var left_tip := (
		head_offset + Vector2(crown_shift - 3.2 * head_size * left_scale, -left_lift * head_size)
	)
	var right_base := head_offset + Vector2(crown_shift + 2.2 * head_size * right_scale, -19.0)
	var right_tip := (
		head_offset + Vector2(crown_shift + 2.9 * head_size * right_scale, -right_lift * head_size)
	)
	var left_branch := (
		head_offset + Vector2(crown_shift - 4.4 * head_size * left_scale, -22.0 * head_size)
	)
	var right_branch := (
		head_offset + Vector2(crown_shift + 4.0 * head_size * right_scale, -22.4 * head_size)
	)
	canvas.draw_line(left_base, left_tip, branch_color, 1.05)
	canvas.draw_line(right_base, right_tip, branch_color, 1.05)
	canvas.draw_line(
		head_offset + Vector2(crown_shift - 3.0 * head_size * left_scale, -22.5 * head_size),
		left_branch,
		branch_color,
		0.75
	)
	canvas.draw_line(
		head_offset + Vector2(crown_shift + 2.7 * head_size * right_scale, -22.9 * head_size),
		right_branch,
		branch_color,
		0.75
	)
	canvas.draw_circle(left_tip, 0.9, leaf)
	canvas.draw_circle(right_tip, 0.9, leaf)
	canvas.draw_circle(left_branch + Vector2(0.0, -0.1), 0.58, leaf)
	canvas.draw_circle(right_branch + Vector2(0.0, -0.1), 0.58, leaf)
	if variant_index % 2 == 0:
		canvas.draw_circle(head_offset + Vector2(crown_shift, -22.2 * head_size), 0.65, lichen)


static func _draw_rootborn_leaf_crown(
	canvas: HumanoidAvatar2D,
	skin: Color,
	head_size: float,
	head_offset: Vector2,
	side_turn: float,
	side: float,
	variant_index: int,
	leaf: Color
) -> void:
	canvas.draw_line(
		head_offset + Vector2(side * side_turn * 0.8, -18.0),
		head_offset + Vector2(side * side_turn * 1.5, -23.7 * head_size),
		skin.darkened(0.36),
		1.25
	)
	var leaf_spread := lerpf(1.0, 0.62, side_turn)
	var left_leaf_tip := (
		head_offset
		+ Vector2((-5.1 * leaf_spread + side_turn * side) * head_size, -23.9 * head_size)
	)
	var left_leaf_inner := (
		head_offset
		+ Vector2((-1.8 * leaf_spread + side_turn * side) * head_size, -22.7 * head_size)
	)
	var right_leaf_tip := (
		head_offset + Vector2((5.1 * leaf_spread + side_turn * side) * head_size, -23.9 * head_size)
	)
	var right_leaf_inner := (
		head_offset + Vector2((1.8 * leaf_spread + side_turn * side) * head_size, -22.7 * head_size)
	)
	canvas._draw_shape(
		PackedVector2Array([head_offset + Vector2(-1.0, -20.2), left_leaf_tip, left_leaf_inner]),
		leaf,
		OUTLINE,
		0.8
	)
	canvas._draw_shape(
		PackedVector2Array([head_offset + Vector2(1.0, -20.2), right_leaf_tip, right_leaf_inner]),
		leaf,
		OUTLINE,
		0.8
	)
	if variant_index > 3:
		canvas._draw_shape(
			PackedVector2Array(
				[
					head_offset + Vector2(0.0, -20.8),
					head_offset + Vector2(1.1 * head_size, -24.4 * head_size),
					head_offset + Vector2(-1.1 * head_size, -22.9 * head_size)
				]
			),
			leaf.lightened(0.08),
			OUTLINE,
			0.6
		)


static func _draw_rootborn_bark_marks(
	canvas: HumanoidAvatar2D,
	skin: Color,
	head_size: float,
	head_offset: Vector2,
	torso_width: float,
	variant_index: int,
	root_color: Color,
	lichen: Color,
	front_visible: bool,
	side_turn: float,
	show_body_marks: bool
) -> void:
	if front_visible:
		canvas.draw_line(
			head_offset + Vector2(-3.6 * head_size, -13.0),
			head_offset + Vector2(-1.0 * head_size, -9.5),
			skin.darkened(0.34),
			0.9
		)
		if side_turn < 0.72:
			canvas.draw_line(
				head_offset + Vector2(3.5 * head_size, -13.2),
				head_offset + Vector2(0.8 * head_size, -9.2),
				skin.darkened(0.32),
				0.75
			)
	if not show_body_marks:
		return
	canvas.draw_line(
		canvas._body_point(-torso_width * 0.24, -5.5),
		canvas._body_point(-torso_width * 0.04, 5.8),
		root_color,
		0.95
	)
	canvas.draw_line(
		canvas._body_point(torso_width * 0.18, -4.0),
		canvas._body_point(torso_width * 0.02, 6.5),
		root_color.lightened(0.10),
		0.85
	)
	canvas.draw_line(
		canvas._body_point(-torso_width * 0.14, 2.8),
		canvas._body_point(torso_width * 0.18, 1.2),
		root_color.darkened(0.12),
		0.7
	)
	canvas.draw_line(
		canvas._body_point(-torso_width * 0.18, -0.6),
		canvas._body_point(torso_width * 0.16, -1.5),
		root_color.darkened(0.18),
		0.65
	)
	if variant_index % 2 == 1:
		canvas.draw_line(
			canvas._body_point(-torso_width * 0.22, -2.8),
			canvas._body_point(torso_width * 0.20, -3.4),
			lichen.darkened(0.22),
			0.55
		)


static func tanglekin_side_muzzle_rect(canvas: HumanoidAvatar2D, head_size: float) -> Rect2:
	var side := canvas._face_side()
	var center := canvas._head_turn_offset() + Vector2(side * 2.45 * head_size, -11.25)
	var size := Vector2(4.45 * head_size, 3.35 * head_size)
	return Rect2(center - size * 0.5, size)


static func tuskfolk_side_tusk_points(
	canvas: HumanoidAvatar2D, head_size: float, tusk_length: float
) -> PackedVector2Array:
	var side := canvas._face_side()
	var head_offset := canvas._head_turn_offset()
	var side_tusk_length := minf(tusk_length * 0.46, 4.05)
	return PackedVector2Array(
		[
			head_offset + Vector2(side * 1.8 * head_size, -9.45),
			head_offset + Vector2(side * side_tusk_length * head_size, -5.75),
			head_offset + Vector2(side * 2.95 * head_size, -10.55)
		]
	)
