class_name HumanoidSurfaceDetailDrawer
extends RefCounted

const StableHash = preload("res://scripts/core/stable_hash.gd")


static func draw(avatar, skin: Color, proportions: Dictionary) -> void:
	var people_id := String(avatar.profile.get("people_id", ""))
	var pattern_index := _pattern_index(avatar)
	match people_id:
		"people_human":
			_draw_human_skin(avatar, skin, proportions, pattern_index)
		"people_tanglekin":
			_draw_tanglekin_fur(avatar, skin, proportions, pattern_index)
		"people_tuskfolk":
			_draw_tuskfolk_bristles(avatar, skin, proportions, pattern_index)
		"people_mirefolk":
			_draw_mirefolk_spots(avatar, skin, proportions, pattern_index)
		"people_ravenfolk":
			_draw_ravenfolk_quills(avatar, skin, proportions, pattern_index)
		"people_rootborn":
			_draw_rootborn_grain(avatar, skin, proportions, pattern_index)


static func _draw_human_skin(
	avatar, skin: Color, proportions: Dictionary, pattern_index: int
) -> void:
	if avatar._back_turn_amount() > 0.55:
		return
	var torso_width: float = 15.0 * float(avatar._proportion(proportions, "torso_width"))
	var detail := skin.darkened(0.28)
	for mark_index in 2:
		var side: float = -1.0 if mark_index == 0 else 1.0
		var y: float = -0.3 + float((pattern_index + mark_index) % 2) * 1.45
		avatar.draw_line(
			avatar._body_point(side * torso_width * 0.17, y),
			avatar._body_point(side * torso_width * 0.22, y + 0.75),
			detail,
			0.46
		)


static func _draw_tanglekin_fur(
	avatar, skin: Color, proportions: Dictionary, pattern_index: int
) -> void:
	var torso_width: float = 15.0 * float(avatar._proportion(proportions, "torso_width"))
	var fur := skin.darkened(0.38)
	for tuft_index in 4:
		var side: float = -1.0 if tuft_index % 2 == 0 else 1.0
		var y: float = -4.0 + float(tuft_index) * 2.15
		var x: float = side * torso_width * (0.23 + 0.04 * float((tuft_index + pattern_index) % 2))
		avatar.draw_line(
			avatar._body_point(x, y), avatar._body_point(x + side * 0.85, y + 1.05), fur, 0.58
		)


static func _draw_tuskfolk_bristles(
	avatar, skin: Color, proportions: Dictionary, pattern_index: int
) -> void:
	if avatar._back_turn_amount() > 0.55:
		return
	var shoulder_width: float = 18.0 * float(avatar._proportion(proportions, "shoulder_width"))
	var bristle := skin.darkened(0.40)
	for bristle_index in 3:
		var side: float = -1.0 if bristle_index % 2 == 0 else 1.0
		var x: float = side * shoulder_width * (0.12 + 0.08 * float(bristle_index))
		var y: float = -5.0 + float((bristle_index + pattern_index) % 2) * 1.1
		avatar.draw_line(
			avatar._body_point(x, y), avatar._body_point(x + side * 0.55, y + 0.95), bristle, 0.54
		)


static func _draw_mirefolk_spots(
	avatar, skin: Color, proportions: Dictionary, pattern_index: int
) -> void:
	if avatar._back_turn_amount() > 0.55:
		return
	var torso_width: float = 15.0 * float(avatar._proportion(proportions, "torso_width"))
	var spot_color := skin.darkened(0.32)
	for spot_index in 3:
		var side: float = -1.0 if spot_index % 2 == 0 else 1.0
		var x: float = side * torso_width * (0.13 + 0.06 * float(spot_index % 2))
		var y: float = -2.5 + float((spot_index + pattern_index) % 3) * 1.55
		avatar.draw_circle(avatar._body_point(x, y), 0.48 + 0.08 * float(spot_index % 2), spot_color)


static func _draw_ravenfolk_quills(
	avatar, skin: Color, proportions: Dictionary, pattern_index: int
) -> void:
	var torso_width: float = 15.0 * float(avatar._proportion(proportions, "torso_width"))
	var quill := skin.lightened(0.28)
	for quill_index in 3:
		var x: float = -torso_width * 0.16 + float(quill_index) * torso_width * 0.16
		var y: float = -4.3 + float((quill_index + pattern_index) % 2) * 1.4
		avatar.draw_line(
			avatar._body_point(x, y), avatar._body_point(x + 0.35, y + 1.0), quill, 0.38
		)


static func _draw_rootborn_grain(
	avatar, skin: Color, proportions: Dictionary, pattern_index: int
) -> void:
	var torso_width: float = 15.0 * float(avatar._proportion(proportions, "torso_width"))
	var grain := skin.darkened(0.40)
	for grain_index in 3:
		var side: float = -1.0 if grain_index % 2 == 0 else 1.0
		var x: float = side * torso_width * (0.09 + 0.07 * float(grain_index))
		var y: float = -3.9 + float((grain_index + pattern_index) % 3) * 1.8
		avatar.draw_line(
			avatar._body_point(x, y), avatar._body_point(x + side * 0.35, y + 1.25), grain, 0.44
		)


static func _pattern_index(avatar) -> int:
	var appearance: Dictionary = avatar.profile.get("appearance", {})
	var key := String(appearance.get("visual_model_id", ""))
	if key.is_empty():
		key = String(appearance.get("palette_id", ""))
	return StableHash.index("surface:%s" % key, 5)
