class_name HumanoidEquipmentDrawer
extends RefCounted

const HumanoidHeldItemDrawer = preload("res://scripts/characters/humanoid_held_item_drawer.gd")


static func draw_all_layers(avatar: HumanoidAvatar2D, proportions: Dictionary) -> void:
	draw_back_layer(avatar, proportions, "back")
	draw_boot_layer(avatar, proportions)
	draw_leg_layer(avatar, proportions)
	draw_chest_layer(avatar, proportions)
	draw_back_layer(avatar, proportions, "front")
	draw_head_layer(avatar, proportions)
	HumanoidHeldItemDrawer.draw_hand_equipment(avatar, "left_hand", proportions)
	HumanoidHeldItemDrawer.draw_hand_equipment(avatar, "right_hand", proportions)


static func draw_body_layers(avatar: HumanoidAvatar2D, proportions: Dictionary) -> void:
	draw_chest_layer(avatar, proportions)


static func draw_back_layer(
	avatar: HumanoidAvatar2D, proportions: Dictionary, layer_id: String
) -> void:
	if not avatar.equipped_visuals.has("back"):
		return
	var back_view := avatar._is_back_view()
	if layer_id == "back" and back_view:
		return
	if layer_id == "front" and not back_view:
		return
	var color := avatar._equipment_color("back")
	var shoulder_width := 19.0 * avatar._proportion(proportions, "shoulder_width")
	var waist_width := 16.0 * avatar._proportion(proportions, "waist_width")
	var y_top := -8.5
	var y_bottom := 10.6
	var points := avatar._body_polygon(
		[
			Vector2(-shoulder_width * 0.44, y_top),
			Vector2(shoulder_width * 0.44, y_top),
			Vector2(waist_width * 0.42, y_bottom),
			Vector2(0.0, y_bottom + 2.0),
			Vector2(-waist_width * 0.42, y_bottom)
		]
	)
	avatar._draw_shape(points, color, avatar.OUTLINE, 0.75)
	avatar.draw_line(
		avatar._body_point(0.0, y_top + 1.0),
		avatar._body_point(0.0, y_bottom),
		color.darkened(0.28),
		0.55
	)


static func draw_boot_layer(avatar: HumanoidAvatar2D, proportions: Dictionary) -> void:
	if not avatar.equipped_visuals.has("boots"):
		return
	var color := avatar._equipment_color("boots")
	var foot_size := avatar._proportion(proportions, "foot_size")
	for side in [-1.0, 1.0]:
		avatar._draw_foot(
			avatar._foot_anchor(side, proportions)
			+ avatar._stride_offset(side)
			+ Vector2(0.0, 0.8 * foot_size),
			4.6 * foot_size,
			3.8 * foot_size,
			side,
			color
		)


static func draw_leg_layer(avatar: HumanoidAvatar2D, proportions: Dictionary) -> void:
	if not avatar.equipped_visuals.has("legs"):
		return
	var color := avatar._equipment_color("legs")
	var waist_width := 13.0 * avatar._proportion(proportions, "waist_width")
	for side in [-1.0, 1.0]:
		var hip := avatar._body_point(side * waist_width * 0.20, 2.7)
		var knee := avatar._body_point(side * waist_width * 0.14, 7.9)
		avatar.draw_line(hip, knee, color, 3.4)
		avatar.draw_line(hip + Vector2(side * 0.7, 0.2), knee, color.lightened(0.16), 0.55)


static func draw_chest_layer(avatar: HumanoidAvatar2D, proportions: Dictionary) -> void:
	if not avatar.equipped_visuals.has("chest"):
		return
	if avatar._chest_equipment_uses_wrap_style():
		_draw_smith_apron_layer(avatar, proportions)
		return
	_draw_chest_armour_layer(avatar, proportions)


static func draw_head_layer(avatar: HumanoidAvatar2D, proportions: Dictionary) -> void:
	if not avatar.equipped_visuals.has("head"):
		return
	var color := avatar._equipment_color("head")
	var head_size := avatar._proportion(proportions, "head_size")
	var radius := 7.1 * head_size
	var head_offset := avatar._head_turn_offset()
	var back_turn := avatar._back_turn_amount()
	var cap := PackedVector2Array(
		[
			head_offset + Vector2(-radius * 0.78, -15.2 - back_turn * 0.4),
			head_offset + Vector2(-radius * 0.52, -19.2),
			head_offset + Vector2(0.0, -21.3),
			head_offset + Vector2(radius * 0.52, -19.2),
			head_offset + Vector2(radius * 0.78, -15.2 - back_turn * 0.4),
			head_offset + Vector2(radius * 0.48, -13.4 + back_turn * 1.4),
			head_offset + Vector2(-radius * 0.48, -13.4 + back_turn * 1.4)
		]
	)
	avatar._draw_shape(cap, color, avatar.OUTLINE, 0.75)
	avatar.draw_line(
		head_offset + Vector2(-radius * 0.42, -15.0),
		head_offset + Vector2(radius * 0.42, -15.2),
		color.lightened(0.18),
		0.55
	)


static func _draw_chest_armour_layer(
	avatar: HumanoidAvatar2D, proportions: Dictionary
) -> void:
	var chest_width := 16.0 * avatar._proportion(proportions, "torso_width")
	var color := avatar._equipment_color("chest")
	var armour_points := avatar._body_polygon(
		[
			Vector2(-chest_width * 0.43, -6.0),
			Vector2(chest_width * 0.43, -6.0),
			Vector2(chest_width * 0.34, 3.6),
			Vector2(0.0, 5.2),
			Vector2(-chest_width * 0.34, 3.6)
		]
	)
	avatar._draw_shape(armour_points, color, avatar.OUTLINE, 1.0)
	avatar.draw_line(
		avatar._body_point(-chest_width * 0.22, -3.0),
		avatar._body_point(chest_width * 0.20, -3.3),
		avatar.WARM_HIGHLIGHT,
		0.8
	)


static func _draw_smith_apron_layer(avatar: HumanoidAvatar2D, proportions: Dictionary) -> void:
	var color := avatar._equipment_color("chest")
	var back_turn := avatar._back_turn_amount()
	var shoulder_width := 17.0 * avatar._proportion(proportions, "shoulder_width")
	var torso_width := 15.5 * avatar._proportion(proportions, "torso_width")
	var waist_width := 14.5 * avatar._proportion(proportions, "waist_width")
	var upper_top_y := -6.5
	var waist_y := 3.9
	var hem_y := 10.8

	match _apron_draw_mode(avatar):
		"back":
			_draw_apron_back_straps(avatar, shoulder_width, waist_width, color, back_turn)
			return
		"side":
			_draw_apron_side_panel(avatar, torso_width, waist_width, color, upper_top_y, waist_y, hem_y)
			return
	_draw_apron_front_panel(
		avatar, shoulder_width, torso_width, waist_width, color, upper_top_y, waist_y, hem_y
	)


static func _draw_apron_front_panel(
	avatar: HumanoidAvatar2D,
	shoulder_width: float,
	torso_width: float,
	waist_width: float,
	color: Color,
	upper_top_y: float,
	waist_y: float,
	hem_y: float
) -> void:
	var side_turn := avatar._side_turn_amount()
	var side := avatar._face_side()
	var shift := side * torso_width * 0.08 * side_turn
	var far_shrink := 1.0 - 0.34 * side_turn
	var near_boost := 1.0 + 0.06 * side_turn
	var left_scale := near_boost if side < 0.0 else far_shrink
	var right_scale := near_boost if side > 0.0 else far_shrink
	var upper_points := avatar._body_polygon(
		[
			Vector2(shift - shoulder_width * 0.28 * left_scale, upper_top_y),
			Vector2(shift + shoulder_width * 0.28 * right_scale, upper_top_y),
			Vector2(shift + torso_width * 0.38 * right_scale, waist_y),
			Vector2(shift - torso_width * 0.38 * left_scale, waist_y)
		]
	)
	var lower_points := avatar._body_polygon(
		[
			Vector2(shift - waist_width * 0.36 * left_scale, waist_y - 0.2),
			Vector2(shift + waist_width * 0.36 * right_scale, waist_y - 0.2),
			Vector2(shift + waist_width * 0.24 * right_scale, hem_y),
			Vector2(shift - waist_width * 0.24 * left_scale, hem_y)
		]
	)
	avatar._draw_shape(upper_points, color, avatar.OUTLINE, 0.95)
	avatar._draw_shape(lower_points, color.darkened(0.04), avatar.OUTLINE, 0.95)
	avatar.draw_line(
		avatar._body_point(shift - shoulder_width * 0.34 * left_scale, upper_top_y + 1.2),
		avatar._body_point(shift - torso_width * 0.43 * left_scale, waist_y + 0.2),
		color.darkened(0.24),
		0.75
	)
	avatar.draw_line(
		avatar._body_point(shift + shoulder_width * 0.34 * right_scale, upper_top_y + 1.2),
		avatar._body_point(shift + torso_width * 0.43 * right_scale, waist_y + 0.2),
		color.darkened(0.24),
		0.75
	)
	avatar.draw_line(
		avatar._body_point(shift - waist_width * 0.32 * left_scale, waist_y),
		avatar._body_point(shift + waist_width * 0.32 * right_scale, waist_y),
		color.lightened(0.16),
		0.85
	)
	avatar.draw_line(
		avatar._body_point(shift - side * waist_width * 0.05, waist_y + 1.5),
		avatar._body_point(shift - side * waist_width * 0.03, hem_y - 0.5),
		color.darkened(0.18),
		0.55
	)


static func _draw_apron_side_panel(
	avatar: HumanoidAvatar2D,
	torso_width: float,
	waist_width: float,
	color: Color,
	upper_top_y: float,
	waist_y: float,
	hem_y: float
) -> void:
	var side := avatar._face_side()
	var side_points := avatar._body_polygon(
		[
			Vector2(side * torso_width * 0.06, upper_top_y + 0.3),
			Vector2(side * torso_width * 0.38, upper_top_y + 1.0),
			Vector2(side * waist_width * 0.32, hem_y),
			Vector2(side * waist_width * 0.06, hem_y - 0.4)
		]
	)
	avatar._draw_shape(side_points, color.darkened(0.03), avatar.OUTLINE, 0.85)
	avatar.draw_line(
		avatar._body_point(side * torso_width * 0.04, upper_top_y + 1.0),
		avatar._body_point(side * waist_width * 0.03, waist_y + 0.3),
		color.darkened(0.28),
		0.70
	)
	avatar.draw_line(
		avatar._body_point(side * waist_width * 0.04, waist_y),
		avatar._body_point(side * waist_width * 0.35, waist_y + 0.4),
		color.lightened(0.12),
		0.75
	)
	avatar.draw_line(
		avatar._body_point(side * torso_width * 0.08, upper_top_y + 0.4),
		avatar._body_point(-side * torso_width * 0.16, upper_top_y - 0.2),
		color.darkened(0.18),
		0.65
	)


static func _draw_apron_back_straps(
	avatar: HumanoidAvatar2D,
	shoulder_width: float,
	waist_width: float,
	color: Color,
	back_turn: float
) -> void:
	var strap_color := color.darkened(0.18)
	var top_y := -6.2 - back_turn * 0.35
	var waist_y := 4.2
	avatar.draw_line(
		avatar._body_point(-shoulder_width * 0.24, top_y),
		avatar._body_point(waist_width * 0.35, waist_y),
		strap_color,
		0.85
	)
	avatar.draw_line(
		avatar._body_point(shoulder_width * 0.24, top_y),
		avatar._body_point(-waist_width * 0.35, waist_y),
		strap_color,
		0.85
	)
	avatar.draw_line(
		avatar._body_point(-waist_width * 0.42, waist_y),
		avatar._body_point(waist_width * 0.42, waist_y),
		color,
		0.9
	)


static func _apron_draw_mode(avatar: HumanoidAvatar2D) -> String:
	var forward := avatar._facing_forward()
	if maxf(0.0, -forward.y) > 0.55:
		return "back"
	if absf(forward.x) > 0.72 and maxf(0.0, forward.y) < 0.32:
		return "side"
	return "front"
