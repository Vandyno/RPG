class_name HumanoidBodyFeatureDrawer
extends RefCounted

const PEOPLE_HUMAN := "people_human"
const PEOPLE_TUSKFOLK := "people_tuskfolk"
const PEOPLE_MIREFOLK := "people_mirefolk"


static func draw(avatar, skin: Color, proportions: Dictionary) -> void:
	if avatar._back_turn_amount() > 0.55:
		return
	match String(avatar.profile.get("people_id", "")):
		PEOPLE_HUMAN:
			_draw_human_anatomy(avatar, skin, proportions)
		PEOPLE_TUSKFOLK:
			_draw_tuskfolk_anatomy(avatar, skin, proportions)
		PEOPLE_MIREFOLK:
			_draw_mirefolk_belly(avatar, skin, proportions)


static func _draw_human_anatomy(avatar, skin: Color, proportions: Dictionary) -> void:
	var torso_width: float = 15.0 * float(avatar._proportion(proportions, "torso_width"))
	var shoulder_width: float = 18.0 * float(avatar._proportion(proportions, "shoulder_width"))
	var definition := skin.darkened(0.30)
	if avatar._side_turn_amount() > 0.62:
		var side: float = float(avatar._face_side())
		avatar.draw_line(
			avatar._body_point(side * torso_width * 0.20, -3.9),
			avatar._body_point(side * torso_width * 0.25, -1.2),
			definition,
			0.46
		)
		return
	for side in [-1.0, 1.0]:
		avatar.draw_line(
			avatar._body_point(side * shoulder_width * 0.20, -3.9),
			avatar._body_point(side * torso_width * 0.10, -2.4),
			definition,
			0.46
		)
	avatar.draw_line(
		avatar._body_point(0.0, -1.8), avatar._body_point(0.0, 0.35), definition, 0.42
	)


static func _draw_tuskfolk_anatomy(avatar, skin: Color, proportions: Dictionary) -> void:
	var torso_width: float = 15.0 * float(avatar._proportion(proportions, "torso_width"))
	var shoulder_width: float = 18.0 * float(avatar._proportion(proportions, "shoulder_width"))
	var definition := skin.darkened(0.26)
	if avatar._side_turn_amount() > 0.62:
		var side: float = float(avatar._face_side())
		avatar.draw_line(
			avatar._body_point(side * torso_width * 0.18, -3.2),
			avatar._body_point(side * torso_width * 0.23, 0.8),
			definition,
			0.58
		)
		return
	for side in [-1.0, 1.0]:
		avatar.draw_line(
			avatar._body_point(side * shoulder_width * 0.24, -3.6),
			avatar._body_point(side * torso_width * 0.12, -1.7),
			definition,
			0.62
		)
	avatar.draw_line(
		avatar._body_point(0.0, -1.5), avatar._body_point(0.0, 0.9), definition, 0.55
	)
	avatar.draw_circle(avatar._body_point(0.0, 1.25), 0.45, definition)


static func _draw_mirefolk_belly(avatar, skin: Color, proportions: Dictionary) -> void:
	var torso_width: float = 15.0 * float(avatar._proportion(proportions, "torso_width"))
	var side_scale: float = lerpf(1.0, 0.60, float(avatar._side_turn_amount()))
	var belly_width: float = torso_width * 0.31 * side_scale
	var belly: PackedVector2Array = avatar._body_polygon(
		[
			Vector2(-belly_width, -4.5),
			Vector2(belly_width, -4.5),
			Vector2(belly_width * 0.82, 1.5),
			Vector2(0.0, 3.2),
			Vector2(-belly_width * 0.82, 1.5)
		]
	)
	avatar.draw_polygon(belly, PackedColorArray([skin.lightened(0.10)]))
	if avatar._side_turn_amount() < 0.62:
		avatar.draw_circle(avatar._body_point(0.0, 0.85), 0.42, skin.darkened(0.24))
