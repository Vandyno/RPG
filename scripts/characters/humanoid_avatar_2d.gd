# gdlint:disable=max-file-lines
class_name HumanoidAvatar2D
extends Node2D

const HumanoidProfile = preload("res://scripts/characters/humanoid_profile.gd")
const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")
const FacingBuckets = preload("res://scripts/core/facing_buckets.gd")
const HumanoidPeopleFeatureDrawer = preload(
	"res://scripts/characters/humanoid_people_feature_drawer.gd"
)
const HumanoidEquipmentDrawer = preload("res://scripts/characters/humanoid_equipment_drawer.gd")

const PALETTES := {
	"palette_human_warm_brown":
	{"skin": Color(0.58, 0.38, 0.25), "shadow": Color(0.03, 0.025, 0.02, 0.35)},
	"palette_human_light_olive":
	{"skin": Color(0.70, 0.55, 0.38), "shadow": Color(0.03, 0.025, 0.02, 0.35)},
	"palette_human_deep_brown":
	{"skin": Color(0.34, 0.22, 0.16), "shadow": Color(0.03, 0.025, 0.02, 0.35)},
	"palette_tanglekin_sun_ochre":
	{"skin": Color(0.58, 0.47, 0.27), "shadow": Color(0.03, 0.025, 0.02, 0.35)},
	"palette_tanglekin_fur_brown":
	{"skin": Color(0.43, 0.34, 0.21), "shadow": Color(0.03, 0.025, 0.02, 0.35)},
	"palette_tanglekin_dust_gold":
	{"skin": Color(0.64, 0.54, 0.32), "shadow": Color(0.03, 0.025, 0.02, 0.35)},
	"palette_tuskfolk_umber":
	{"skin": Color(0.43, 0.30, 0.22), "shadow": Color(0.03, 0.025, 0.02, 0.38)},
	"palette_tuskfolk_ash":
	{"skin": Color(0.42, 0.39, 0.34), "shadow": Color(0.03, 0.025, 0.02, 0.38)},
	"palette_tuskfolk_red_clay":
	{"skin": Color(0.49, 0.29, 0.22), "shadow": Color(0.03, 0.025, 0.02, 0.38)},
	"palette_mirefolk_reed_green":
	{"skin": Color(0.38, 0.62, 0.45), "shadow": Color(0.02, 0.03, 0.025, 0.36)},
	"palette_mirefolk_bog_blue":
	{"skin": Color(0.30, 0.50, 0.54), "shadow": Color(0.02, 0.03, 0.035, 0.36)},
	"palette_mirefolk_silt_olive":
	{"skin": Color(0.45, 0.56, 0.34), "shadow": Color(0.02, 0.03, 0.025, 0.36)},
	"palette_ravenfolk_black":
	{"skin": Color(0.12, 0.13, 0.16), "shadow": Color(0.02, 0.018, 0.02, 0.46)},
	"palette_ravenfolk_archive_grey":
	{"skin": Color(0.24, 0.25, 0.30), "shadow": Color(0.02, 0.018, 0.02, 0.46)},
	"palette_ravenfolk_blue_black":
	{"skin": Color(0.10, 0.14, 0.22), "shadow": Color(0.02, 0.018, 0.02, 0.46)},
	"palette_rootborn_moss":
	{"skin": Color(0.46, 0.52, 0.29), "shadow": Color(0.02, 0.028, 0.018, 0.38)},
	"palette_rootborn_bark":
	{"skin": Color(0.34, 0.27, 0.18), "shadow": Color(0.02, 0.028, 0.018, 0.38)},
	"palette_rootborn_lichen_grey":
	{"skin": Color(0.42, 0.47, 0.34), "shadow": Color(0.02, 0.028, 0.018, 0.38)}
}
const HAIR_COLORS := {
	"hair_black": Color(0.05, 0.04, 0.035),
	"hair_brown": Color(0.22, 0.12, 0.06),
	"hair_grey": Color(0.55, 0.54, 0.50)
}
const RAVENFOLK_FEATHER_TINTS := [
	Color(0.15, 0.16, 0.20),
	Color(0.10, 0.14, 0.22),
	Color(0.17, 0.15, 0.14),
	Color(0.14, 0.17, 0.16),
	Color(0.20, 0.18, 0.14)
]
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
const EQUIPMENT_COLORS := {
	"placeholder_hatchet": Color(0.62, 0.58, 0.48),
	"placeholder_sword": Color(0.72, 0.72, 0.68),
	"placeholder_polearm": Color(0.48, 0.34, 0.18),
	"placeholder_bow": Color(0.40, 0.22, 0.08),
	"placeholder_buckler": Color(0.42, 0.30, 0.18),
	"placeholder_smith_apron": Color(0.38, 0.24, 0.15),
	"placeholder_leather_vest": Color(0.36, 0.24, 0.14),
	"placeholder_leather_cap": Color(0.25, 0.18, 0.12),
	"placeholder_trousers": Color(0.25, 0.22, 0.18),
	"placeholder_gloves": Color(0.30, 0.22, 0.14),
	"placeholder_boots": Color(0.18, 0.14, 0.10),
	"placeholder_cloak": Color(0.16, 0.20, 0.22)
}
const OUTLINE := Color(0.045, 0.035, 0.025, 0.95)
const INNER_LINE := Color(0.10, 0.08, 0.055, 0.58)
const WARM_HIGHLIGHT := Color(1.0, 0.88, 0.58, 0.22)
const COOL_SHADOW := Color(0.02, 0.025, 0.028, 0.24)
const LOCOMOTION_IDLE := "idle"
const LOCOMOTION_WALK := "walk"
const LOCOMOTION_SNEAK := "sneak"
const WALK_CYCLE_SPEED := 8.0
const SNEAK_CYCLE_SPEED := 4.8
const IDLE_BREATH_SPEED := 1.7
const BODY_EQUIPMENT_SLOTS := ["head", "chest", "legs", "gloves", "boots", "back"]
const PEOPLE_FEATURE_LAYER_BACK := "back"
const PEOPLE_FEATURE_LAYER_BODY := "body"
const PEOPLE_FEATURE_LAYER_FRONT := "front"

var profile: Dictionary = HumanoidProfile.from_data({})
var equipped_visuals: Dictionary = {}
var facing_direction := Vector2.DOWN
var locomotion_state := LOCOMOTION_IDLE
var animation_time := 0.0
var move_intensity := 0.0
var is_sneaking := false


func setup(
	profile_data: Dictionary = {}, equipped_by_slot: Dictionary = {}, content = null
) -> void:
	profile = HumanoidProfile.from_data(profile_data)
	set_equipped_items(equipped_by_slot, content)


func set_profile(profile_data: Dictionary) -> void:
	profile = HumanoidProfile.from_data(profile_data)
	queue_redraw()


func set_facing_direction(value: Vector2) -> void:
	if value.length() <= 0.01:
		return
	facing_direction = FacingBuckets.snap_direction(value, facing_direction)
	queue_redraw()


func set_equipped_items(equipped_by_slot: Dictionary, content = null) -> void:
	equipped_visuals.clear()
	for slot_id in equipped_by_slot:
		var item_id := String(equipped_by_slot[slot_id])
		var item: Dictionary = {}
		if content and content.has_method("get_item"):
			item = content.get_item(item_id)
		var visual: Dictionary = {}
		if item.get("avatar_visual", {}) is Dictionary:
			visual = item.get("avatar_visual", {})
		if visual.is_empty():
			continue
		equipped_visuals[EquipmentSlots.normalize(String(slot_id))] = visual.duplicate(true)
	queue_redraw()


func set_locomotion(is_moving: bool, sneaking: bool, delta: float) -> void:
	is_sneaking = sneaking
	if is_moving:
		locomotion_state = LOCOMOTION_SNEAK if sneaking else LOCOMOTION_WALK
		move_intensity = minf(1.0, move_intensity + maxf(delta, 0.0) * 8.0)
	else:
		locomotion_state = LOCOMOTION_IDLE
		move_intensity = maxf(0.0, move_intensity - maxf(delta, 0.0) * 5.0)

	var cycle_speed := IDLE_BREATH_SPEED
	if locomotion_state == LOCOMOTION_WALK:
		cycle_speed = WALK_CYCLE_SPEED
	elif locomotion_state == LOCOMOTION_SNEAK:
		cycle_speed = SNEAK_CYCLE_SPEED
	animation_time += maxf(delta, 0.0) * cycle_speed
	queue_redraw()


func set_sneaking(value: bool) -> void:
	is_sneaking = value
	if locomotion_state == LOCOMOTION_WALK and is_sneaking:
		locomotion_state = LOCOMOTION_SNEAK
	elif locomotion_state == LOCOMOTION_SNEAK and not is_sneaking:
		locomotion_state = LOCOMOTION_WALK
	queue_redraw()


func has_body_stack() -> bool:
	return true


func has_equipment_visual(slot_id: String) -> bool:
	return equipped_visuals.has(EquipmentSlots.normalize(slot_id))


func get_proportion(field_id: String) -> float:
	var appearance: Dictionary = profile.get("appearance", {})
	var proportions: Dictionary = appearance.get("proportions", {})
	return _proportion(proportions, field_id)


func get_equipment_body_slots() -> Array:
	return BODY_EQUIPMENT_SLOTS.duplicate()


func get_supported_palette_ids() -> Array:
	return PALETTES.keys()


func get_facing_bucket_count() -> int:
	return FacingBuckets.COUNT


func get_facing_bucket_index() -> int:
	return _facing_bucket_index()


func get_facing_bucket_id() -> String:
	return FacingBuckets.bucket_id(_facing_forward())


func get_debug_turn_profile() -> Dictionary:
	var axis := _body_side_axis()
	return {
		"bucket_id": get_facing_bucket_id(),
		"front": _front_turn_amount(),
		"side": _side_turn_amount(),
		"back": _back_turn_amount(),
		"face_side": _face_side(),
		"body_axis": axis,
		"head_offset": _head_turn_offset()
	}


func get_debug_draw_layer_order() -> Array[String]:
	var order: Array[String] = ["shadow"]
	var appearance: Dictionary = profile.get("appearance", {})
	var proportions: Dictionary = appearance.get("proportions", {})
	var people_id := String(profile.get("people_id", ""))
	order.append_array(
		HumanoidPeopleFeatureDrawer.debug_layer_entries(self, people_id, PEOPLE_FEATURE_LAYER_BACK)
	)
	if equipped_visuals.has("back") and not _is_back_view():
		order.append("equipment:back:rear")
	order.append("body:feet")
	if equipped_visuals.has("boots"):
		order.append("equipment:boots")
	order.append("body:waist")
	if equipped_visuals.has("legs"):
		order.append("equipment:legs")
	_append_debug_hand_layer(order, PEOPLE_FEATURE_LAYER_BACK, proportions)
	order.append("body:torso")
	if equipped_visuals.has("back") and _is_back_view():
		order.append("equipment:back:front")
	if equipped_visuals.has("chest"):
		order.append("equipment:chest")
	order.append_array(
		HumanoidPeopleFeatureDrawer.debug_layer_entries(self, people_id, PEOPLE_FEATURE_LAYER_BODY)
	)
	_append_debug_hand_layer(order, PEOPLE_FEATURE_LAYER_FRONT, proportions)
	order.append("body:head")
	order.append_array(
		HumanoidPeopleFeatureDrawer.debug_layer_entries(self, people_id, PEOPLE_FEATURE_LAYER_FRONT)
	)
	if _should_draw_hair(people_id):
		order.append("hair")
	if equipped_visuals.has("head"):
		order.append("equipment:head")
	if _should_draw_marking(String(appearance.get("marking_id", ""))):
		order.append("marking")
	if _should_draw_generic_face(people_id):
		order.append("face:generic")
	return order


func get_body_part_anchors() -> Dictionary:
	var appearance: Dictionary = profile.get("appearance", {})
	var proportions: Dictionary = appearance.get("proportions", {})
	var anchors := {
		"head": _head_turn_offset() + Vector2(0.0, -14.2),
		"chest": _body_point(0.0, -2.0),
		"waist": _body_point(0.0, 4.8),
		"left_hand": _hand_anchor(-1.0, proportions) + _hand_sway(-1.0),
		"right_hand": _hand_anchor(1.0, proportions) + _hand_sway(1.0),
		"left_foot": Vector2.ZERO + _foot_anchor(-1.0, proportions),
		"right_foot": Vector2.ZERO + _foot_anchor(1.0, proportions)
	}
	var body_height := _proportion(proportions, "body_height")
	for anchor_id in anchors:
		var point: Vector2 = anchors[anchor_id]
		anchors[anchor_id] = Vector2(point.x, point.y * body_height)
	return {
		"head": anchors["head"],
		"chest": anchors["chest"],
		"waist": anchors["waist"],
		"left_hand": anchors["left_hand"],
		"right_hand": anchors["right_hand"],
		"left_foot": anchors["left_foot"],
		"right_foot": anchors["right_foot"]
	}


func _draw() -> void:
	var appearance: Dictionary = profile.get("appearance", {})
	var proportions: Dictionary = appearance.get("proportions", {})
	var palette: Dictionary = PALETTES.get(
		String(appearance.get("palette_id", "")), PALETTES["palette_human_warm_brown"]
	)
	var people_id := String(profile.get("people_id", ""))
	var skin: Color = palette["skin"]
	var shadow: Color = palette["shadow"]
	var hair_id := String(appearance.get("hair_id", ""))
	var hair := _hair_color(String(appearance.get("hair_color_id", "")))

	_draw_shadow(proportions, shadow)
	draw_set_transform(
		Vector2(0.0, _bob_offset() + _sneak_crouch_offset()),
		0.0,
		Vector2(1.0, _proportion(proportions, "body_height"))
	)
	HumanoidPeopleFeatureDrawer.draw_layer(self, skin, proportions, PEOPLE_FEATURE_LAYER_BACK)
	HumanoidEquipmentDrawer.draw_back_layer(self, proportions, PEOPLE_FEATURE_LAYER_BACK)
	_draw_feet(skin, proportions)
	HumanoidEquipmentDrawer.draw_boot_layer(self, proportions)
	_draw_waist(skin, proportions)
	HumanoidEquipmentDrawer.draw_leg_layer(self, proportions)
	_draw_hand_layer(skin, proportions, PEOPLE_FEATURE_LAYER_BACK)
	_draw_torso(skin, proportions)
	HumanoidEquipmentDrawer.draw_back_layer(self, proportions, PEOPLE_FEATURE_LAYER_FRONT)
	HumanoidEquipmentDrawer.draw_chest_layer(self, proportions)
	HumanoidPeopleFeatureDrawer.draw_layer(self, skin, proportions, PEOPLE_FEATURE_LAYER_BODY)
	_draw_hand_layer(skin, proportions, PEOPLE_FEATURE_LAYER_FRONT)
	_draw_head(skin, proportions)
	HumanoidPeopleFeatureDrawer.draw_layer(self, skin, proportions, PEOPLE_FEATURE_LAYER_FRONT)
	if _should_draw_hair(people_id):
		_draw_hair(hair_id, hair, proportions)
	HumanoidEquipmentDrawer.draw_head_layer(self, proportions)
	_draw_marking(String(appearance.get("marking_id", "")), skin, proportions)
	if _should_draw_generic_face(people_id):
		_draw_face(proportions)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_shadow(proportions: Dictionary, shadow: Color) -> void:
	var shoulder_width := _proportion(proportions, "shoulder_width")
	var foot_size := _proportion(proportions, "foot_size")
	var width := 24.0 * maxf(shoulder_width, foot_size) + (_sneak_crouch_offset() * 0.8)
	_draw_oval(Rect2(Vector2(-width * 0.5, 5.5), Vector2(width, 7.5)), shadow)


func _draw_feet(skin: Color, proportions: Dictionary) -> void:
	var foot_size := _proportion(proportions, "foot_size")
	var boot_width := 4.8 * foot_size
	var boot_height := 6.6 * foot_size
	_draw_foot(
		_foot_anchor(-1.0, proportions) + _stride_offset(-1.0),
		boot_width,
		boot_height,
		-1.0,
		skin.darkened(0.12)
	)
	_draw_foot(
		_foot_anchor(1.0, proportions) + _stride_offset(1.0),
		boot_width,
		boot_height,
		1.0,
		skin.darkened(0.12)
	)


func _draw_waist(skin: Color, proportions: Dictionary) -> void:
	var waist_width := 14.0 * _proportion(proportions, "waist_width")
	var back_turn := _back_turn_amount()
	var side_turn := _side_turn_amount()
	var points := _body_polygon(
		[
			Vector2(-waist_width * 0.42, -1.0),
			Vector2(waist_width * 0.42, -1.0),
			Vector2(waist_width * 0.56, 7.0),
			Vector2(waist_width * 0.22, 10.0),
			Vector2(-waist_width * 0.22, 10.0),
			Vector2(-waist_width * 0.56, 7.0)
		]
	)
	_draw_shape(points, skin.darkened(0.08), OUTLINE, 1.2)
	if back_turn > 0.45:
		draw_line(_body_point(0.0, 0.0), _body_point(0.0, 7.0), skin.darkened(0.30), 0.75)
	elif side_turn > 0.55:
		var side := _face_side()
		draw_line(
			_body_point(side * waist_width * 0.08, 0.1),
			_body_point(side * waist_width * 0.12, 7.2),
			skin.darkened(0.24),
			0.7
		)
	else:
		draw_line(_body_point(0.0, 0.0), _body_point(0.0, 7.0), skin.darkened(0.24), 0.65)
		draw_line(
			_body_point(-waist_width * 0.32, 2.0),
			_body_point(waist_width * 0.32, 2.0),
			skin.lightened(0.12),
			0.8
		)


func _draw_torso(skin: Color, proportions: Dictionary) -> void:
	var shoulder_width := 18.0 * _proportion(proportions, "shoulder_width")
	var torso_width := 15.0 * _proportion(proportions, "torso_width")
	var side_turn := _side_turn_amount()
	var back_turn := _back_turn_amount()
	var front_turn := _front_turn_amount()
	var shoulder_roll := sin(_walk_phase()) * move_intensity
	var shoulder_y := -7.2 + (0.35 * shoulder_roll)
	var waist_y := 3.3 + (0.15 * shoulder_roll)
	var torso_points := _body_polygon(
		[
			Vector2(-shoulder_width * 0.50, shoulder_y),
			Vector2(-shoulder_width * 0.18, shoulder_y - 2.2),
			Vector2(shoulder_width * 0.18, shoulder_y - 2.2),
			Vector2(shoulder_width * 0.50, shoulder_y),
			Vector2(torso_width * 0.34, waist_y),
			Vector2(-torso_width * 0.34, waist_y)
		]
	)
	_draw_shape(torso_points, skin, OUTLINE, 1.25)

	if back_turn > 0.45:
		var back_plane := _body_polygon(
			[
				Vector2(-shoulder_width * 0.26, shoulder_y - 0.5),
				Vector2(shoulder_width * 0.24, shoulder_y - 0.7),
				Vector2(torso_width * 0.20, waist_y - 0.4),
				Vector2(0.0, waist_y + 0.5),
				Vector2(-torso_width * 0.20, waist_y - 0.4)
			]
		)
		_draw_shape(back_plane, skin.darkened(0.06), Color(0.0, 0.0, 0.0, 0.0), 0.0)
		draw_line(
			_body_point(0.0, shoulder_y - 1.0),
			_body_point(0.0, waist_y + 0.8),
			skin.darkened(0.25),
			0.85
		)
		return
	if side_turn > 0.62:
		var side := _face_side()
		draw_line(
			_body_point(side * torso_width * 0.07, shoulder_y - 1.0),
			_body_point(side * torso_width * 0.09, waist_y + 0.4),
			skin.lightened(0.10),
			0.8
		)
		draw_line(
			_body_point(-side * torso_width * 0.22, shoulder_y + 1.0),
			_body_point(-side * torso_width * 0.16, waist_y),
			COOL_SHADOW,
			1.0
		)
		return
	var chest_plane := _body_polygon(
		[
			Vector2(-shoulder_width * 0.30, shoulder_y - 0.7),
			Vector2(0.0, shoulder_y - 1.5),
			Vector2(shoulder_width * 0.30, shoulder_y - 0.7),
			Vector2(torso_width * 0.22, waist_y - 0.5),
			Vector2(0.0, waist_y + 0.6),
			Vector2(-torso_width * 0.22, waist_y - 0.5)
		]
	)
	_draw_shape(
		chest_plane,
		skin.lightened(0.03 + front_turn * 0.02),
		Color(0.0, 0.0, 0.0, 0.0),
		0.0
	)
	draw_line(
		_body_point(0.0, shoulder_y - 0.8),
		_body_point(0.0, waist_y + 0.5),
		skin.darkened(0.18),
		0.8
	)
	draw_line(
		_body_point(-torso_width * 0.26, shoulder_y + 1.8),
		_body_point(-torso_width * 0.18, waist_y),
		skin.lightened(0.14),
		0.9
	)
	draw_line(
		_body_point(torso_width * 0.28, shoulder_y + 1.0),
		_body_point(torso_width * 0.20, waist_y),
		COOL_SHADOW,
		1.2
	)


func _draw_hands(skin: Color, proportions: Dictionary) -> void:
	var hand_size := _proportion(proportions, "hand_size")
	var sneak_lower := 1.6 if is_sneaking else 0.0
	_draw_mitten(
		_hand_anchor(-1.0, proportions) + Vector2(0.0, sneak_lower) + _hand_sway(-1.0),
		3.2 * hand_size,
		-1.0,
		skin
	)
	_draw_mitten(
		_hand_anchor(1.0, proportions) + Vector2(0.0, sneak_lower) + _hand_sway(1.0),
		3.2 * hand_size,
		1.0,
		skin
	)


func _draw_hand_layer(skin: Color, proportions: Dictionary, layer_id: String) -> void:
	for side in _hand_sides_for_layer(layer_id, proportions):
		_draw_hand_with_equipment(float(side), skin, proportions)


func _draw_hand_with_equipment(side: float, skin: Color, proportions: Dictionary) -> void:
	var hand_size := _proportion(proportions, "hand_size")
	var sneak_lower := 1.6 if is_sneaking else 0.0
	_draw_mitten(
		_hand_anchor(side, proportions) + Vector2(0.0, sneak_lower) + _hand_sway(side),
		3.2 * hand_size,
		side,
		skin
	)
	_draw_glove_equipment(side, proportions)
	_draw_hand_equipment(_hand_slot_id(side), proportions)


func _draw_head(skin: Color, proportions: Dictionary) -> void:
	var head_radius := 7.0 * _proportion(proportions, "head_size")
	var head_offset := _head_turn_offset()
	var side_turn := _side_turn_amount()
	var face_side := _face_side()
	var head_points := PackedVector2Array(
		[
			head_offset + Vector2(-head_radius * 0.82, -13.4),
			head_offset + Vector2(-head_radius * 0.66, -17.4),
			head_offset + Vector2(-head_radius * 0.28, -20.0),
			head_offset + Vector2(head_radius * 0.28, -20.0),
			head_offset + Vector2(head_radius * 0.66, -17.4),
			head_offset + Vector2(head_radius * 0.82, -13.4),
			head_offset + Vector2(head_radius * 0.54, -9.4),
			head_offset + Vector2(0.0, -7.8),
			head_offset + Vector2(-head_radius * 0.54, -9.4)
		]
	)
	_draw_shape(head_points, skin, OUTLINE, 1.2)
	draw_line(
		head_offset + Vector2(-head_radius * 0.30, -18.5),
		head_offset + Vector2(head_radius * 0.25, -18.7),
		skin.lightened(0.16),
		1.0
	)
	draw_line(
		head_offset + Vector2(face_side * head_radius * lerpf(0.50, 0.42, side_turn), -14.0),
		head_offset + Vector2(face_side * head_radius * lerpf(0.32, 0.24, side_turn), -10.2),
		skin.darkened(0.16),
		1.0
	)


func _draw_tanglekin_back_feature(
	skin: Color, _proportions: Dictionary, feature_ids: Array[String]
) -> void:
	if not feature_ids.has("feature_tanglekin_tail"):
		return
	var side_turn := _side_turn_amount()
	var back_turn := _back_turn_amount()
	var front_turn := _front_turn_amount()
	var curl_side := _face_side()
	var tail_side := curl_side if side_turn > 0.08 else 1.0
	var root_y := 4.7 + front_turn * 1.2 - back_turn * 1.4
	var middle_y := 8.8 + front_turn * 1.0 - back_turn * 3.0
	var curl_y := 6.1 - front_turn * 0.5 - back_turn * 1.1
	var tip_y := 2.8 - front_turn * 0.6 + back_turn * 2.2
	var side_reach := lerpf(4.6, 10.8, side_turn)
	var back_lift := lerpf(0.0, 2.2, back_turn)
	var root := _body_point(-_facing_forward().x * 0.9, root_y)
	var middle := _body_point(tail_side * side_reach * 0.58, middle_y)
	var curl := _body_point(tail_side * side_reach, curl_y - back_lift)
	var tip := _body_point(tail_side * side_reach * 0.74, tip_y - back_lift)
	var tail_color := skin.darkened(0.10)
	var tail_shadow := skin.darkened(0.38)
	draw_line(root, middle, tail_shadow, 4.0)
	draw_line(middle, curl, tail_shadow, 3.6)
	draw_line(curl, tip, tail_shadow, 3.1)
	draw_line(root, middle, tail_color, 2.55)
	draw_line(middle, curl, tail_color.lightened(0.04), 2.25)
	draw_line(curl, tip, tail_color.lightened(0.08), 1.85)
	draw_circle(root, 1.7, tail_shadow)
	draw_circle(root, 1.05, tail_color)
	draw_circle(tip, 1.25, tail_shadow)
	draw_circle(tip, 0.78, tail_color.lightened(0.08))


func _draw_tanglekin_feature(
	skin: Color, proportions: Dictionary, feature_ids: Array[String]
) -> void:
	var head_size := _proportion(proportions, "head_size")
	var head_offset := _head_turn_offset()
	var side_turn := _side_turn_amount()
	var back_turn := _back_turn_amount()
	var front_visible := back_turn < 0.55
	var side := _face_side()
	var fur_shadow := skin.darkened(0.30)
	var muzzle_color := skin.lightened(0.13)
	var eye_color := Color(0.035, 0.027, 0.018)
	if feature_ids.has("feature_tanglekin_grasping_hands"):
		var hand_size := _proportion(proportions, "hand_size")
		var foot_size := _proportion(proportions, "foot_size")
		for limb_side in [-1.0, 1.0]:
			var hand := _hand_anchor(limb_side, proportions) + _hand_sway(limb_side)
			var foot := _foot_anchor(limb_side, proportions) + _stride_offset(limb_side)
			draw_circle(hand, 2.9 * hand_size, OUTLINE)
			draw_circle(hand, 2.1 * hand_size, skin.lightened(0.07))
			draw_circle(hand + Vector2(limb_side * 1.0, -0.4), 0.62 * hand_size, fur_shadow)
			draw_circle(foot + Vector2(0.0, 0.8), 2.7 * foot_size, OUTLINE)
			draw_circle(foot + Vector2(0.0, 0.8), 1.9 * foot_size, skin.darkened(0.03))
			draw_line(
				foot + Vector2(-limb_side * 1.7, -0.4),
				foot + Vector2(limb_side * 1.8, 0.5),
				fur_shadow,
				0.65
			)
	if front_visible:
		if side_turn < 0.72:
			for ear_side in [-1.0, 1.0]:
				var ear_center := head_offset + Vector2(ear_side * 7.0 * head_size, -15.1)
				draw_circle(ear_center, 2.0 * head_size, OUTLINE)
				draw_circle(ear_center, 1.35 * head_size, skin.darkened(0.05))
		else:
			var ear_center := head_offset + Vector2(-side * 5.6 * head_size, -15.4)
			draw_circle(ear_center, 1.75 * head_size, OUTLINE)
			draw_circle(ear_center, 1.12 * head_size, skin.darkened(0.05))
		if feature_ids.has("feature_tanglekin_muzzle"):
			if side_turn < 0.58:
				_draw_outlined_oval(
					Rect2(
						head_offset + Vector2(-3.8 * head_size, -12.3),
						Vector2(7.6 * head_size, 4.3 * head_size)
					),
					muzzle_color,
					OUTLINE,
					0.55
				)
				draw_circle(head_offset + Vector2(-2.6 * head_size, -14.8), 0.75 * head_size, eye_color)
				draw_circle(head_offset + Vector2(2.6 * head_size, -14.8), 0.75 * head_size, eye_color)
				draw_line(
					head_offset + Vector2(-1.8 * head_size, -10.1),
					head_offset + Vector2(1.9 * head_size, -10.0),
					fur_shadow,
					0.75
				)
			else:
				_draw_outlined_oval(
					_tanglekin_side_muzzle_rect(head_size),
					muzzle_color,
					OUTLINE,
					0.55
				)
				draw_circle(head_offset + Vector2(side * 2.0 * head_size, -14.8), 0.78 * head_size, eye_color)
				draw_line(
					head_offset + Vector2(side * 2.0 * head_size, -10.5),
					head_offset + Vector2(side * 3.3 * head_size, -10.6),
					fur_shadow,
					0.65
				)
	elif back_turn > 0.55:
		var rear_ear_scale := lerpf(1.0, 0.72, side_turn)
		for ear_side in [-1.0, 1.0]:
			var ear_center := head_offset + Vector2(
				ear_side * 6.4 * head_size * rear_ear_scale,
				-15.0
			)
			draw_circle(ear_center, 1.9 * head_size * rear_ear_scale, OUTLINE)
			draw_circle(
				ear_center,
				1.18 * head_size * rear_ear_scale,
				skin.darkened(0.14)
			)
	if feature_ids.has("feature_tanglekin_brow_tuft"):
		for tuft_index in 3:
			var offset := float(tuft_index - 1)
			draw_line(
				head_offset + Vector2(offset * 1.6 * head_size, -18.6),
				head_offset + Vector2(offset * 2.4 * head_size, -22.4 - absf(offset) * 0.6),
				fur_shadow,
				1.0
			)
	elif front_visible:
		draw_line(
			head_offset + Vector2(-3.8 * head_size, -16.5),
			head_offset + Vector2(3.8 * head_size, -16.3),
			fur_shadow,
			0.9
		)


func _draw_tuskfolk_feature(
	skin: Color, proportions: Dictionary, feature_ids: Array[String], appearance: Dictionary = {}
) -> void:
	var head_size := _proportion(proportions, "head_size")
	var head_offset := _head_turn_offset()
	var torso_x := _body_turn_x()
	var side_turn := _side_turn_amount()
	var back_turn := _back_turn_amount()
	var front_visible := back_turn < 0.55
	var shoulder_width := 18.0 * _proportion(proportions, "shoulder_width")
	var waist_width := 14.0 * _proportion(proportions, "waist_width")
	var tusk_color := Color(0.86, 0.78, 0.58)
	var tusk_length := 9.2 if feature_ids.has("feature_tusks_broad") else 7.0
	var variant_key := String(appearance.get("visual_model_id", ""))
	if variant_key.is_empty():
		variant_key = String(appearance.get("palette_id", ""))
	var variant_index := _stable_index(variant_key, TUSKFOLK_CLAN_TINTS.size())
	var clan_color: Color = skin.darkened(0.12).lerp(TUSKFOLK_CLAN_TINTS[variant_index], 0.56)
	var ring_color := Color(0.58, 0.43, 0.22).lerp(clan_color.lightened(0.12), 0.24)
	_draw_shape(
		_body_polygon(
			[
				Vector2(-waist_width * 0.38, 2.0),
				Vector2(waist_width * 0.38, 2.0),
				Vector2(waist_width * 0.44, 7.6),
				Vector2(waist_width * 0.18, 10.4),
				Vector2(-waist_width * 0.18, 10.4),
				Vector2(-waist_width * 0.44, 7.6)
			]
		),
		skin.darkened(0.08 + back_turn * 0.03),
		Color(0.0, 0.0, 0.0, 0.0),
		0.0
	)
	draw_line(
		_body_point(-waist_width * 0.34, 6.2),
		_body_point(waist_width * 0.34, 6.0),
		skin.darkened(0.24),
		0.75
	)
	draw_line(
		_body_point(-waist_width * 0.42, 2.6),
		_body_point(waist_width * 0.42, 2.8),
		clan_color.darkened(0.08),
		1.2
	)
	draw_rect(
		Rect2(_body_point(0.0, 1.1) - Vector2(1.5, 0.0), Vector2(3.0, 3.2)),
		ring_color.darkened(0.08)
	)
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
		_draw_shape(jaw, skin.darkened(0.10), Color(0.0, 0.0, 0.0, 0.0), 0.0)
		var brow := PackedVector2Array(
			[
				head_offset + Vector2(-6.0 * head_size, -14.8),
				head_offset + Vector2(0.0, -16.6),
				head_offset + Vector2(6.0 * head_size, -14.8),
				head_offset + Vector2(4.5 * head_size, -13.2),
				head_offset + Vector2(-4.5 * head_size, -13.2)
			]
		)
		_draw_shape(brow, skin.darkened(0.16), Color(0.0, 0.0, 0.0, 0.0), 0.0)
	else:
		_draw_oval(
			Rect2(
				head_offset + Vector2(-4.6 * head_size, -15.4),
				Vector2(9.2 * head_size, 7.6)
			),
			skin.darkened(0.14)
		)
	if front_visible and feature_ids.has("feature_tuskfolk_clan_marks"):
		draw_line(
			_body_point(-shoulder_width * 0.34, -5.4),
			_body_point(-shoulder_width * 0.14, -1.8),
			clan_color.darkened(0.30),
			1.0
		)
		draw_line(
			_body_point(shoulder_width * 0.34, -5.4),
			_body_point(shoulder_width * 0.14, -1.8),
			clan_color.darkened(0.30),
			1.0
		)
		draw_line(
			_body_point(-shoulder_width * 0.28, -2.0),
			_body_point(shoulder_width * 0.28, -2.3),
			clan_color.lightened(0.10),
			0.65
		)
	if front_visible and side_turn < 0.45:
		var front_tusk_x := minf(tusk_length * 0.55, 5.2)
		_draw_shape(
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
		_draw_shape(
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
		draw_line(
			head_offset + Vector2(-3.9 * head_size, -8.8),
			head_offset + Vector2(-4.7 * head_size, -7.6),
			ring_color,
			0.85
		)
		draw_line(
			head_offset + Vector2(3.9 * head_size, -8.8),
			head_offset + Vector2(4.7 * head_size, -7.6),
			ring_color,
			0.85
		)
	elif front_visible:
		var side := _face_side()
		_draw_shape(
			_tuskfolk_side_tusk_points(head_size, tusk_length),
			tusk_color,
			OUTLINE,
			0.85
		)
		draw_line(
			head_offset + Vector2(side * 2.8 * head_size, -8.8),
			head_offset + Vector2(side * 3.5 * head_size, -7.9),
			ring_color,
			0.85
		)


func _draw_mirefolk_feature(
	skin: Color, proportions: Dictionary, feature_ids: Array[String], appearance: Dictionary = {}
) -> void:
	var head_size := _proportion(proportions, "head_size")
	var head_offset := _head_turn_offset()
	var eye_color := Color(0.90, 0.88, 0.62)
	var variant_key := String(appearance.get("visual_model_id", ""))
	if variant_key.is_empty():
		variant_key = String(appearance.get("palette_id", ""))
	var variant_index := _stable_index(variant_key, MIREFOLK_PATTERN_TINTS.size())
	var pattern_color: Color = MIREFOLK_PATTERN_TINTS[variant_index].lerp(skin.lightened(0.12), 0.42)
	var throat_color := skin.lightened(0.18).lerp(pattern_color.lightened(0.16), 0.26)
	var torso_x := _body_turn_x()
	var back_turn := _back_turn_amount()
	var side_turn := _side_turn_amount()
	var front_visible := back_turn < 0.55
	var side := _face_side()
	var belly_width := 7.6 * _proportion(proportions, "torso_width")
	var belly_side_width := belly_width * lerpf(1.0, 0.58, side_turn)
	var belly_height := lerpf(12.2, 9.2, back_turn)
	if front_visible:
		_draw_shape(
			_body_polygon(
				[
					Vector2(-belly_side_width * 0.48, -6.9),
					Vector2(belly_side_width * 0.48, -6.9),
					Vector2(belly_side_width * 0.42, -6.9 + belly_height * 0.58),
					Vector2(0.0, -6.9 + belly_height),
					Vector2(-belly_side_width * 0.42, -6.9 + belly_height * 0.58)
				]
			),
			throat_color.darkened(back_turn * 0.10),
			Color(0.0, 0.0, 0.0, 0.0),
			0.0
		)
		draw_line(
			_body_point(-belly_width * 0.25, -5.2),
			_body_point(belly_width * 0.25, -4.2),
			skin.darkened(0.18),
			0.55
		)
		var spot_count := 2 + variant_index % 3
		for spot_index in spot_count:
			var offset_x := -belly_width * 0.24 + float(spot_index) * belly_width * 0.18
			var offset_y := -3.6 + float((spot_index + variant_index) % 3) * 2.3
			draw_circle(
				_body_point(offset_x, offset_y),
				0.45 + 0.10 * float(spot_index % 2),
				pattern_color.darkened(0.18)
			)
		if variant_index % 2 == 1:
			draw_line(
				_body_point(-belly_width * 0.36, -1.2),
				_body_point(belly_width * 0.30, 1.1),
				pattern_color.darkened(0.10),
				0.55
			)
	if feature_ids.has("feature_mirefolk_webbed_hands"):
		var web_color := skin.lightened(0.22).lerp(pattern_color.lightened(0.08), 0.28)
		for limb_side in [-1.0, 1.0]:
			var hand := _hand_anchor(limb_side, proportions) + _hand_sway(limb_side)
			_draw_shape(
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
			var foot := _foot_anchor(limb_side, proportions) + _stride_offset(limb_side)
			_draw_shape(
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
	var has_high_eyes := feature_ids.has("feature_mirefolk_high_eyes")
	if has_high_eyes:
		if not front_visible:
			draw_circle(
				head_offset + Vector2(-4.8 * head_size, -18.1),
				0.75 * head_size,
				eye_color.darkened(0.22)
			)
			draw_circle(
				head_offset + Vector2(4.8 * head_size, -18.1),
				0.75 * head_size,
				eye_color.darkened(0.22)
			)
		elif side_turn > 0.70:
			var near_eye := head_offset + Vector2(side * 4.5 * head_size, -18.0)
			var far_eye := head_offset + Vector2(-side * 2.5 * head_size, -18.5)
			draw_circle(far_eye, 1.4 * head_size, eye_color.darkened(0.18))
			draw_circle(near_eye, 2.85 * head_size, eye_color)
			draw_circle(near_eye, 1.0 * head_size, OUTLINE)
		else:
			draw_circle(head_offset + Vector2(-4.8 * head_size, -18.1), 2.8 * head_size, eye_color)
			draw_circle(head_offset + Vector2(4.8 * head_size, -18.1), 2.8 * head_size, eye_color)
			draw_circle(head_offset + Vector2(-4.8 * head_size, -18.1), 1.0 * head_size, OUTLINE)
			draw_circle(head_offset + Vector2(4.8 * head_size, -18.1), 1.0 * head_size, OUTLINE)
	elif front_visible:
		draw_circle(
			head_offset + Vector2(-4.1 * head_size, -16.9),
			1.55 * head_size,
			eye_color.lightened(0.05)
		)
		draw_circle(head_offset + Vector2(-4.1 * head_size, -16.9), 0.72 * head_size, OUTLINE)
		if side_turn < 0.70:
			draw_circle(
				head_offset + Vector2(4.1 * head_size, -16.9),
				1.55 * head_size,
				eye_color.lightened(0.05)
			)
			draw_circle(head_offset + Vector2(4.1 * head_size, -16.9), 0.72 * head_size, OUTLINE)
	if front_visible and feature_ids.has("feature_mirefolk_reed_marks"):
		if _face_detail_visible_on_side(-1.0):
			draw_line(
				_face_mark_point(-5.8, -15.4, head_size),
				_face_mark_point(-2.0, -12.4, head_size),
				pattern_color.darkened(0.28),
				0.8
			)
			draw_circle(
				_face_mark_point(-4.8, -10.2, head_size), 0.55, pattern_color.darkened(0.24)
			)
		if _face_detail_visible_on_side(1.0):
			draw_line(
				_face_mark_point(5.6, -15.0, head_size),
				_face_mark_point(2.0, -12.0, head_size),
				pattern_color.darkened(0.22),
				0.7
			)
			draw_circle(
				_face_mark_point(4.6, -10.1, head_size), 0.55, pattern_color.darkened(0.24)
			)
		if variant_index > 2 and side_turn < 0.70:
			draw_line(
				head_offset + Vector2(-3.0 * head_size, -17.2),
				head_offset + Vector2(3.2 * head_size, -17.1),
				pattern_color.lightened(0.08),
				0.55
			)
	if front_visible:
		draw_line(
			head_offset + Vector2(-5.3 * head_size, -11.0),
			head_offset + Vector2(5.3 * head_size, -10.8),
			skin.darkened(0.22),
			0.9
		)
	else:
		for spot_index in 4:
			draw_circle(
				_body_point(-4.0 + spot_index * 2.6, -4.4 + float((spot_index + variant_index) % 3) * 1.8),
				0.65,
				pattern_color.darkened(0.22)
			)


func _ravenfolk_variant_index(appearance: Dictionary = {}) -> int:
	var variant_key := String(appearance.get("visual_model_id", ""))
	if variant_key.is_empty():
		variant_key = String(appearance.get("palette_id", ""))
	return _stable_index(variant_key, RAVENFOLK_FEATHER_TINTS.size())


func _ravenfolk_feather_color(skin: Color, appearance: Dictionary = {}) -> Color:
	var feather_tint: Color = RAVENFOLK_FEATHER_TINTS[_ravenfolk_variant_index(appearance)]
	return skin.darkened(0.08).lerp(feather_tint, 0.46)


func _draw_ravenfolk_back_feature(
	skin: Color, proportions: Dictionary, feature_ids: Array[String], appearance: Dictionary = {}
) -> void:
	if not feature_ids.has("feature_ravenfolk_tail_feathers"):
		return
	var feather_color := _ravenfolk_feather_color(skin, appearance)
	var tail_shadow := feather_color.darkened(0.36)
	var waist_width := 14.0 * _proportion(proportions, "waist_width")
	var side_turn := _side_turn_amount()
	var back_turn := _back_turn_amount()
	var front_turn := _front_turn_amount()
	var tail_visibility := clampf(
		(side_turn + back_turn - front_turn * 0.25 - 0.20) / 0.80, 0.0, 1.0
	)
	if tail_visibility < 0.16:
		return
	var side := _face_side()
	var root_x := -_facing_forward().x * 1.4
	var root_y := 5.8 + (1.4 * (1.0 - tail_visibility))
	var spread := waist_width * lerpf(0.10, 0.42, maxf(back_turn, side_turn * 0.55))
	var visible_side := side if side_turn > 0.45 else 0.0
	for feather_index in 5:
		var offset := float(feather_index - 2)
		var x_spread := offset * spread * 0.32 + visible_side * side_turn * 3.4
		var tip := _body_point(
			root_x + x_spread,
			root_y + (6.2 + absf(offset) * 0.55) * tail_visibility + back_turn * 2.2
		)
		var base_left := _body_point(root_x + offset * spread * 0.18 - 1.1, root_y + 0.5)
		var base_right := _body_point(root_x + offset * spread * 0.18 + 1.1, root_y + 0.5)
		_draw_shape(
			PackedVector2Array([base_left, tip, base_right]),
			feather_color.darkened(0.04 + absf(offset) * 0.03 + (1.0 - tail_visibility) * 0.08),
			tail_shadow,
			0.45
		)


func _draw_ravenfolk_body_feature(
	skin: Color, proportions: Dictionary, feature_ids: Array[String], appearance: Dictionary = {}
) -> void:
	if not feature_ids.has("feature_ravenfolk_body_feathers"):
		return
	var feather_color := _ravenfolk_feather_color(skin, appearance)
	var highlight := feather_color.lightened(0.18)
	var shadow := feather_color.darkened(0.34)
	var side_turn := _side_turn_amount()
	var back_turn := _back_turn_amount()
	var shoulder_width := 18.0 * _proportion(proportions, "shoulder_width")
	var torso_width := 15.0 * _proportion(proportions, "torso_width")
	var width_turn_scale := lerpf(1.0, 0.66, side_turn) * lerpf(1.0, 0.90, back_turn)
	var upper_patch := _body_polygon(
		[
			Vector2(-shoulder_width * 0.36 * width_turn_scale, -7.4),
			Vector2(0.0, -9.2 - back_turn * 0.4),
			Vector2(shoulder_width * 0.36 * width_turn_scale, -7.4),
			Vector2(torso_width * 0.24 * width_turn_scale, 1.8),
			Vector2(0.0, 4.2),
			Vector2(-torso_width * 0.24 * width_turn_scale, 1.8)
		]
	)
	_draw_shape(
		upper_patch,
		feather_color.darkened(back_turn * 0.05),
		Color(0.0, 0.0, 0.0, 0.0),
		0.0
	)
	for row_index in 4:
		var count := 3 + row_index
		var row_t := float(row_index) / 3.0
		var row_width := lerpf(shoulder_width * 0.46, torso_width * 0.38, row_t) * width_turn_scale
		var y := -6.2 + row_index * 2.45
		for feather_index in count:
			var x_t := 0.0 if count <= 1 else float(feather_index) / float(count - 1)
			var x := -row_width * 0.5 + row_width * x_t
			var scale := lerpf(1.15, 0.82, row_t)
			_draw_shape(
				_body_polygon(
					[
						Vector2(x - 1.2 * scale, y - 0.2),
						Vector2(x + _face_side() * side_turn * 0.45, y + 2.6 * scale),
						Vector2(x + 1.2 * scale, y - 0.2)
					]
				),
				feather_color.lightened(0.03 + row_t * 0.08).darkened(back_turn * 0.08),
				shadow,
				0.28
			)
			if back_turn < 0.65:
				draw_line(_body_point(x, y), _body_point(x, y + 2.0 * scale), highlight, 0.28)
	for side in [-1.0, 1.0]:
		var shoulder := _body_point(side * shoulder_width * 0.43, -6.5)
		for fringe_index in 3:
			var tip := shoulder + Vector2(side * (1.8 + fringe_index * 1.2), 2.4 + fringe_index * 1.7)
			draw_line(shoulder + Vector2(side * fringe_index * 0.9, fringe_index * 0.5), tip, shadow, 0.8)


func _draw_ravenfolk_front_feature(
	skin: Color, proportions: Dictionary, feature_ids: Array[String], appearance: Dictionary = {}
) -> void:
	var head_size := _proportion(proportions, "head_size")
	var head_offset := _head_turn_offset()
	var side_turn := _side_turn_amount()
	var back_turn := _back_turn_amount()
	var front_visible := back_turn < 0.55
	var side := _face_side()
	var feather_color := _ravenfolk_feather_color(skin, appearance)
	var feather_shadow := feather_color.darkened(0.38)
	var bone_color := Color(0.74, 0.66, 0.42).lerp(feather_color.lightened(0.24), 0.18)
	if feature_ids.has("feature_ravenfolk_head_crest"):
		var crest_count := 5
		var crest_spread := lerpf(1.0, 0.50, side_turn) * lerpf(1.0, 0.84, back_turn)
		var crest_height := lerpf(1.0, 0.86, side_turn) * lerpf(1.0, 0.94, back_turn)
		var crest_shift := side * side_turn * 1.0 - _facing_forward().x * back_turn * 0.5
		var crest_fill := feather_color.lightened(0.07).darkened(back_turn * 0.10)
		for crest_index in crest_count:
			var offset := float(crest_index - 2)
			var base := head_offset + Vector2(
				crest_shift + offset * 1.35 * head_size * crest_spread,
				-18.8 + back_turn * 0.8
			)
			var tip := head_offset + Vector2(
				crest_shift
				+ offset * 2.05 * head_size * crest_spread
				+ side * side_turn * 0.45 * absf(offset),
				-18.8 - (5.4 + absf(offset) * 0.65) * head_size * crest_height
			)
			_draw_shape(
				PackedVector2Array(
					[
						base + Vector2(-0.9 * head_size, 0.7),
						tip,
						base + Vector2(0.9 * head_size, 0.7)
					]
				),
				crest_fill,
				feather_shadow,
				0.35
			)
	if front_visible:
		var brow := PackedVector2Array(
			[
				head_offset + Vector2(-4.8 * head_size, -16.2),
				head_offset + Vector2(-1.2 * head_size, -18.0),
				head_offset + Vector2(4.8 * head_size, -16.2),
				head_offset + Vector2(3.8 * head_size, -13.6),
				head_offset + Vector2(-3.8 * head_size, -13.6)
			]
		)
		_draw_shape(brow, feather_shadow, Color(0.0, 0.0, 0.0, 0.0), 0.0)
		if side_turn >= 0.70:
			draw_circle(_ravenfolk_near_eye_point(head_size), 0.85 * head_size, bone_color)
		else:
			draw_circle(head_offset + Vector2(-1.8 * head_size, -14.4), 0.85 * head_size, bone_color)
			draw_circle(
				head_offset + Vector2(1.8 * head_size, -14.4), 0.72 * head_size, bone_color
			)
		if feature_ids.has("feature_ravenfolk_beak"):
			if side_turn < 0.45:
				_draw_shape(
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
				draw_line(
					head_offset + Vector2(0.0, -12.4),
					head_offset + Vector2(0.0, -7.4),
					bone_color.lightened(0.22),
					0.45
				)
			else:
				_draw_shape(
					_ravenfolk_side_beak_points(head_size),
					bone_color.darkened(0.06),
					OUTLINE,
					0.62
				)
				draw_line(
					head_offset + Vector2(side * 1.0 * head_size, -12.6),
					head_offset + Vector2(side * 4.3 * head_size, -11.7),
					bone_color.lightened(0.24),
					0.45
				)
	if feature_ids.has("feature_ravenfolk_quill_marks") and front_visible:
		var quill_color := feather_shadow.darkened(0.10)
		for mark_index in 3:
			var x := -4.4 + mark_index * 4.4
			draw_line(_body_point(x, -6.2), _body_point(x + 0.9, -5.0), quill_color, 0.42)


func _draw_rootborn_feature(
	skin: Color, proportions: Dictionary, feature_ids: Array[String], appearance: Dictionary = {}
) -> void:
	var head_size := _proportion(proportions, "head_size")
	var head_offset := _head_turn_offset()
	var side_turn := _side_turn_amount()
	var back_turn := _back_turn_amount()
	var side := _face_side()
	var front_visible := back_turn < 0.55
	var variant_key := String(appearance.get("visual_model_id", ""))
	if variant_key.is_empty():
		variant_key = String(appearance.get("palette_id", ""))
	var variant_index := _stable_index(variant_key, ROOTBORN_GROWTH_TINTS.size())
	var growth_tint: Color = ROOTBORN_GROWTH_TINTS[variant_index]
	var leaf := Color(0.30, 0.50, 0.24).lerp(growth_tint.lightened(0.10), 0.45)
	var lichen := Color(0.55, 0.63, 0.42).lerp(growth_tint.lightened(0.18), 0.32)
	var root_color := skin.darkened(0.32)
	var torso_width := 15.0 * _proportion(proportions, "torso_width")
	var waist_width := 14.0 * _proportion(proportions, "waist_width")
	var bark_line := root_color.darkened(0.12).lerp(growth_tint.darkened(0.20), 0.18)
	draw_line(
		_body_point(-torso_width * 0.28, -3.8),
		_body_point(torso_width * 0.26, -3.2),
		bark_line,
		0.55
	)
	draw_line(
		_body_point(-torso_width * 0.22, 0.4),
		_body_point(torso_width * 0.24, -0.1),
		bark_line.lightened(0.08),
		0.5
	)
	draw_line(
		_body_point(-waist_width * 0.25, 4.6),
		_body_point(waist_width * 0.24, 4.0),
		bark_line,
		0.55
	)
	for patch_index in 2 + variant_index % 2:
		draw_circle(
			_body_point(
				-torso_width * 0.26 + float(patch_index) * torso_width * 0.22,
				-5.8 + float((patch_index + variant_index) % 3) * 3.4
			),
			0.65,
			lichen.darkened(0.08)
		)
	for root_side in [-1.0, 1.0]:
		var foot := _foot_anchor(root_side, proportions) + _stride_offset(root_side)
		draw_line(
			foot + Vector2(root_side * 1.4, 1.5),
			foot + Vector2(root_side * 4.8, 3.8),
			root_color,
			0.9
		)
		draw_line(
			foot + Vector2(root_side * 0.1, 1.8),
			foot + Vector2(root_side * 2.9, 4.4),
			root_color.darkened(0.10),
			0.8
		)
		draw_line(
			foot + Vector2(root_side * -1.1, 1.7),
			foot + Vector2(root_side * -3.5, 3.7),
			root_color.darkened(0.05),
			0.65
		)
	if feature_ids.has("feature_rootborn_branch_crown"):
		var branch_color := skin.darkened(0.42)
		var left_lift := 23.0 + float(variant_index % 3) * 0.7
		var right_lift := 23.4 + float((variant_index + 1) % 3) * 0.7
		var near_scale := 1.0 + side_turn * 0.10
		var far_scale := 1.0 - side_turn * 0.28
		var left_scale := far_scale if side > 0.0 else near_scale
		var right_scale := near_scale if side > 0.0 else far_scale
		var crown_shift := side * side_turn * 1.2 - _facing_forward().x * back_turn * 0.8
		var left_base := head_offset + Vector2(crown_shift - 2.4 * head_size * left_scale, -19.0)
		var left_tip := head_offset + Vector2(
			crown_shift - 3.2 * head_size * left_scale, -left_lift * head_size
		)
		var right_base := head_offset + Vector2(
			crown_shift + 2.2 * head_size * right_scale, -19.0
		)
		var right_tip := head_offset + Vector2(
			crown_shift + 2.9 * head_size * right_scale, -right_lift * head_size
		)
		var left_branch := head_offset + Vector2(
			crown_shift - 5.1 * head_size * left_scale, -23.6 * head_size
		)
		var right_branch := head_offset + Vector2(
			crown_shift + 4.6 * head_size * right_scale, -24.1 * head_size
		)
		draw_line(
			left_base,
			left_tip,
			branch_color,
			1.05
		)
		draw_line(
			right_base,
			right_tip,
			branch_color,
			1.05
		)
		draw_line(
			head_offset + Vector2(crown_shift - 3.0 * head_size * left_scale, -22.5 * head_size),
			left_branch,
			branch_color,
			0.75
		)
		draw_line(
			head_offset + Vector2(crown_shift + 2.7 * head_size * right_scale, -22.9 * head_size),
			right_branch,
			branch_color,
			0.75
		)
		draw_circle(left_tip, 0.9, leaf)
		draw_circle(right_tip, 0.9, leaf)
		draw_circle(left_branch + Vector2(0.0, -0.1), 0.7, leaf)
		draw_circle(right_branch + Vector2(0.0, -0.1), 0.7, leaf)
		if variant_index % 2 == 0:
			draw_circle(head_offset + Vector2(crown_shift, -22.2 * head_size), 0.65, lichen)
	if feature_ids.has("feature_rootborn_leaf_crown"):
		draw_line(
			head_offset + Vector2(side * side_turn * 0.8, -18.0),
			head_offset + Vector2(side * side_turn * 1.5, -24.8 * head_size),
			skin.darkened(0.36),
			1.25
		)
		var leaf_spread := lerpf(1.0, 0.62, side_turn)
		var left_leaf_tip := head_offset + Vector2(
			(-5.8 * leaf_spread + side_turn * side) * head_size,
			-25.0 * head_size
		)
		var left_leaf_inner := head_offset + Vector2(
			(-2.0 * leaf_spread + side_turn * side) * head_size,
			-23.2 * head_size
		)
		var right_leaf_tip := head_offset + Vector2(
			(5.8 * leaf_spread + side_turn * side) * head_size,
			-25.0 * head_size
		)
		var right_leaf_inner := head_offset + Vector2(
			(2.0 * leaf_spread + side_turn * side) * head_size,
			-23.2 * head_size
		)
		_draw_shape(
			PackedVector2Array(
				[
					head_offset + Vector2(-1.0, -20.2),
					left_leaf_tip,
					left_leaf_inner
				]
			),
			leaf,
			OUTLINE,
			0.8
		)
		_draw_shape(
			PackedVector2Array(
				[
					head_offset + Vector2(1.0, -20.2),
					right_leaf_tip,
					right_leaf_inner
				]
			),
			leaf,
			OUTLINE,
			0.8
		)
		if variant_index > 1:
			_draw_shape(
				PackedVector2Array(
					[
						head_offset + Vector2(0.0, -20.8),
						head_offset + Vector2(1.3 * head_size, -25.8 * head_size),
						head_offset + Vector2(-1.3 * head_size, -23.4 * head_size)
					]
				),
				leaf.lightened(0.08),
				OUTLINE,
				0.6
			)
	if feature_ids.has("feature_rootborn_bark_marks"):
		if front_visible:
			draw_line(
				head_offset + Vector2(-3.6 * head_size, -13.0),
				head_offset + Vector2(-1.0 * head_size, -9.5),
				skin.darkened(0.34),
				0.9
			)
			if side_turn < 0.72:
				draw_line(
					head_offset + Vector2(3.5 * head_size, -13.2),
					head_offset + Vector2(0.8 * head_size, -9.2),
					skin.darkened(0.32),
					0.75
				)
		draw_line(
			_body_point(-torso_width * 0.24, -5.5),
			_body_point(-torso_width * 0.04, 5.8),
			root_color,
			0.95
		)
		draw_line(
			_body_point(torso_width * 0.18, -4.0),
			_body_point(torso_width * 0.02, 6.5),
			root_color.lightened(0.10),
			0.85
		)
		draw_line(
			_body_point(-torso_width * 0.14, 2.8),
			_body_point(torso_width * 0.18, 1.2),
			root_color.darkened(0.12),
			0.7
		)
		draw_line(
			_body_point(-torso_width * 0.18, -0.6),
			_body_point(torso_width * 0.16, -1.5),
			root_color.darkened(0.18),
			0.65
		)
		if variant_index % 2 == 1:
			draw_line(
				_body_point(-torso_width * 0.22, -2.8),
				_body_point(torso_width * 0.20, -3.4),
				lichen.darkened(0.22),
				0.55
			)


func _draw_hair(hair_id: String, hair: Color, proportions: Dictionary) -> void:
	var head_size := _proportion(proportions, "head_size")
	var radius := 7.0 * head_size
	var head_offset := _head_turn_offset()
	var back_turn := _back_turn_amount()
	var shape_id := hair_id if not hair_id.is_empty() else "hair_short_waves"
	var cap_scale := 1.0
	if shape_id == "hair_close_crop":
		cap_scale = 0.86
	elif shape_id == "hair_shaved_crown":
		cap_scale = 0.72
	var cap := PackedVector2Array(
		[
			head_offset + Vector2(-radius * 0.72 * cap_scale, -15.2 - back_turn * 0.6),
			head_offset + Vector2(-radius * 0.52 * cap_scale, -18.7),
			head_offset + Vector2(-radius * 0.18 * cap_scale, -20.7),
			head_offset + Vector2(radius * 0.30 * cap_scale, -20.5),
			head_offset + Vector2(radius * 0.65 * cap_scale, -18.0),
			head_offset + Vector2(radius * 0.78 * cap_scale, -14.4 - back_turn * 0.6),
			head_offset + Vector2(radius * 0.42 * cap_scale, -15.7 + back_turn * 1.9),
			head_offset + Vector2(radius * 0.10 * cap_scale, -15.0 + back_turn * 2.4),
			head_offset + Vector2(-radius * 0.24 * cap_scale, -16.0 + back_turn * 1.9)
		]
	)
	_draw_shape(cap, hair, OUTLINE, 0.9)
	if shape_id == "hair_wide_curls":
		for curl_index in 4:
			var side := -1.0 if curl_index < 2 else 1.0
			var curl_y := -17.2 + float(curl_index % 2) * 2.1
			draw_circle(
				head_offset + Vector2(side * radius * (0.72 + float(curl_index % 2) * 0.05), curl_y),
				1.7 * head_size,
				hair
			)
			draw_arc(
				head_offset + Vector2(side * radius * (0.72 + float(curl_index % 2) * 0.05), curl_y),
				1.7 * head_size,
				0.0,
				TAU,
				12,
				OUTLINE,
				0.65
			)
	if shape_id == "hair_tied_back":
		draw_circle(
			head_offset + Vector2(0.0, -21.1 + back_turn * 4.2),
			1.9 * head_size,
			hair.darkened(0.04)
		)
		draw_arc(
			head_offset + Vector2(0.0, -21.1 + back_turn * 4.2),
			1.9 * head_size,
			0.0,
			TAU,
			12,
			OUTLINE,
			0.65
		)
	if shape_id == "hair_shaved_crown":
		_draw_oval(
			Rect2(head_offset + Vector2(-radius * 0.34, -18.5), Vector2(radius * 0.68, 3.8)),
			hair.lightened(0.35)
		)
	draw_line(
		head_offset + Vector2(-radius * 0.45, -17.0),
		head_offset + Vector2(radius * 0.35, -18.0),
		hair.lightened(0.20),
		0.9
	)
	if shape_id == "hair_side_part":
		draw_line(
			head_offset + Vector2(radius * 0.10, -20.0),
			head_offset + Vector2(radius * 0.00, -15.6),
			hair.lightened(0.38),
			0.75
		)


func _draw_marking(marking_id: String, skin: Color, proportions: Dictionary) -> void:
	if not _should_draw_marking(marking_id):
		return
	var head_size := _proportion(proportions, "head_size")
	var mark_color := skin.darkened(0.36)
	match marking_id:
		"marking_brow_left":
			draw_line(
				_face_mark_point(-4.8, -15.8, head_size),
				_face_mark_point(-1.8, -14.4, head_size),
				mark_color,
				0.85
			)
		"marking_cheek_dots":
			for dot_index in 3:
				draw_circle(
					_face_mark_point(-2.6 - dot_index * 1.2, -11.7, head_size),
					0.45 * head_size,
					mark_color
				)
		"marking_chest_band":
			draw_line(
				_body_point(-5.4, -2.4),
				_body_point(5.4, -0.6),
				mark_color,
				0.85
			)
		"marking_hand_wraps":
			draw_line(
				_hand_anchor(-1.0, proportions),
				_hand_anchor(-1.0, proportions) + Vector2(3.4, 0.8),
				mark_color,
				0.7
			)
			draw_line(
				_hand_anchor(1.0, proportions),
				_hand_anchor(1.0, proportions) + Vector2(-3.4, 0.8),
				mark_color,
				0.7
			)
		"marking_leaf_specks":
			var head_offset := _head_turn_offset()
			for dot_index in 3:
				draw_circle(
					head_offset + Vector2((-2.2 + dot_index * 2.2) * head_size, -18.7),
					0.50 * head_size,
					Color(0.55, 0.68, 0.28)
				)
		"marking_ash_streak":
			draw_line(
				_face_mark_point(3.8, -17.2, head_size),
				_face_mark_point(0.8, -9.8, head_size),
				Color(0.68, 0.67, 0.60, 0.78),
				0.9
			)


func _draw_equipment_layers(proportions: Dictionary) -> void:
	_draw_back_equipment_layer(proportions, PEOPLE_FEATURE_LAYER_BACK)
	_draw_boot_equipment_layer(proportions)
	_draw_leg_equipment_layer(proportions)
	_draw_chest_equipment_layer(proportions)
	_draw_back_equipment_layer(proportions, PEOPLE_FEATURE_LAYER_FRONT)
	_draw_head_equipment_layer(proportions)
	_draw_hand_equipment("left_hand", proportions)
	_draw_hand_equipment("right_hand", proportions)


func _draw_body_equipment_layers(proportions: Dictionary) -> void:
	_draw_chest_equipment_layer(proportions)


func _draw_back_equipment_layer(proportions: Dictionary, layer_id: String) -> void:
	if not equipped_visuals.has("back"):
		return
	var back_view := _is_back_view()
	if layer_id == PEOPLE_FEATURE_LAYER_BACK and back_view:
		return
	if layer_id == PEOPLE_FEATURE_LAYER_FRONT and not back_view:
		return
	var color := _equipment_color("back")
	var shoulder_width := 19.0 * _proportion(proportions, "shoulder_width")
	var waist_width := 16.0 * _proportion(proportions, "waist_width")
	var y_top := -8.5
	var y_bottom := 10.6
	var points := _body_polygon(
		[
			Vector2(-shoulder_width * 0.44, y_top),
			Vector2(shoulder_width * 0.44, y_top),
			Vector2(waist_width * 0.42, y_bottom),
			Vector2(0.0, y_bottom + 2.0),
			Vector2(-waist_width * 0.42, y_bottom)
		]
	)
	_draw_shape(points, color, OUTLINE, 0.75)
	draw_line(
		_body_point(0.0, y_top + 1.0),
		_body_point(0.0, y_bottom),
		color.darkened(0.28),
		0.55
	)


func _draw_boot_equipment_layer(proportions: Dictionary) -> void:
	if not equipped_visuals.has("boots"):
		return
	var color := _equipment_color("boots")
	var foot_size := _proportion(proportions, "foot_size")
	for side in [-1.0, 1.0]:
		_draw_foot(
			_foot_anchor(side, proportions) + _stride_offset(side) + Vector2(0.0, 0.8 * foot_size),
			4.6 * foot_size,
			3.8 * foot_size,
			side,
			color
		)


func _draw_leg_equipment_layer(proportions: Dictionary) -> void:
	if not equipped_visuals.has("legs"):
		return
	var color := _equipment_color("legs")
	var waist_width := 13.0 * _proportion(proportions, "waist_width")
	for side in [-1.0, 1.0]:
		var hip := _body_point(side * waist_width * 0.20, 2.7)
		var knee := _body_point(side * waist_width * 0.14, 7.9)
		draw_line(hip, knee, color, 3.4)
		draw_line(hip + Vector2(side * 0.7, 0.2), knee, color.lightened(0.16), 0.55)


func _draw_chest_equipment_layer(proportions: Dictionary) -> void:
	if not equipped_visuals.has("chest"):
		return
	if _chest_equipment_uses_wrap_style():
		_draw_smith_apron_equipment_layer(proportions)
		return
	_draw_chest_armour_equipment_layer(proportions)


func _draw_chest_armour_equipment_layer(proportions: Dictionary) -> void:
	var chest_width := 16.0 * _proportion(proportions, "torso_width")
	var color := _equipment_color("chest")
	var armour_points := _body_polygon(
		[
			Vector2(-chest_width * 0.43, -6.0),
			Vector2(chest_width * 0.43, -6.0),
			Vector2(chest_width * 0.34, 3.6),
			Vector2(0.0, 5.2),
			Vector2(-chest_width * 0.34, 3.6)
		]
	)
	_draw_shape(armour_points, color, OUTLINE, 1.0)
	draw_line(
		_body_point(-chest_width * 0.22, -3.0),
		_body_point(chest_width * 0.20, -3.3),
		WARM_HIGHLIGHT,
		0.8
	)


func _draw_smith_apron_equipment_layer(proportions: Dictionary) -> void:
	var color := _equipment_color("chest")
	var back_turn := _back_turn_amount()
	var shoulder_width := 17.0 * _proportion(proportions, "shoulder_width")
	var torso_width := 15.5 * _proportion(proportions, "torso_width")
	var waist_width := 14.5 * _proportion(proportions, "waist_width")
	var upper_top_y := -6.5
	var waist_y := 3.9
	var hem_y := 10.8

	match _apron_draw_mode():
		"back":
			_draw_apron_back_straps(shoulder_width, waist_width, color, back_turn)
			return
		"side":
			_draw_apron_side_panel(torso_width, waist_width, color, upper_top_y, waist_y, hem_y)
			return
	_draw_apron_front_panel(
		shoulder_width, torso_width, waist_width, color, upper_top_y, waist_y, hem_y
	)


func _draw_apron_front_panel(
	shoulder_width: float,
	torso_width: float,
	waist_width: float,
	color: Color,
	upper_top_y: float,
	waist_y: float,
	hem_y: float
) -> void:
	var side_turn := _side_turn_amount()
	var side := _face_side()
	var shift := side * torso_width * 0.08 * side_turn
	var far_shrink := 1.0 - 0.34 * side_turn
	var near_boost := 1.0 + 0.06 * side_turn
	var left_scale := near_boost if side < 0.0 else far_shrink
	var right_scale := near_boost if side > 0.0 else far_shrink
	var upper_points := _body_polygon(
		[
			Vector2(shift - shoulder_width * 0.28 * left_scale, upper_top_y),
			Vector2(shift + shoulder_width * 0.28 * right_scale, upper_top_y),
			Vector2(shift + torso_width * 0.38 * right_scale, waist_y),
			Vector2(shift - torso_width * 0.38 * left_scale, waist_y)
		]
	)
	var lower_points := _body_polygon(
		[
			Vector2(shift - waist_width * 0.36 * left_scale, waist_y - 0.2),
			Vector2(shift + waist_width * 0.36 * right_scale, waist_y - 0.2),
			Vector2(shift + waist_width * 0.24 * right_scale, hem_y),
			Vector2(shift - waist_width * 0.24 * left_scale, hem_y)
		]
	)
	_draw_shape(upper_points, color, OUTLINE, 0.95)
	_draw_shape(lower_points, color.darkened(0.04), OUTLINE, 0.95)
	draw_line(
		_body_point(shift - shoulder_width * 0.34 * left_scale, upper_top_y + 1.2),
		_body_point(shift - torso_width * 0.43 * left_scale, waist_y + 0.2),
		color.darkened(0.24),
		0.75
	)
	draw_line(
		_body_point(shift + shoulder_width * 0.34 * right_scale, upper_top_y + 1.2),
		_body_point(shift + torso_width * 0.43 * right_scale, waist_y + 0.2),
		color.darkened(0.24),
		0.75
	)
	draw_line(
		_body_point(shift - waist_width * 0.32 * left_scale, waist_y),
		_body_point(shift + waist_width * 0.32 * right_scale, waist_y),
		color.lightened(0.16),
		0.85
	)
	draw_line(
		_body_point(shift - side * waist_width * 0.05, waist_y + 1.5),
		_body_point(shift - side * waist_width * 0.03, hem_y - 0.5),
		color.darkened(0.18),
		0.55
	)


func _draw_apron_side_panel(
	torso_width: float,
	waist_width: float,
	color: Color,
	upper_top_y: float,
	waist_y: float,
	hem_y: float
) -> void:
	var side := _face_side()
	var side_points := _body_polygon(
		[
			Vector2(side * torso_width * 0.06, upper_top_y + 0.3),
			Vector2(side * torso_width * 0.38, upper_top_y + 1.0),
			Vector2(side * waist_width * 0.32, hem_y),
			Vector2(side * waist_width * 0.06, hem_y - 0.4)
		]
	)
	_draw_shape(side_points, color.darkened(0.03), OUTLINE, 0.85)
	draw_line(
		_body_point(side * torso_width * 0.04, upper_top_y + 1.0),
		_body_point(side * waist_width * 0.03, waist_y + 0.3),
		color.darkened(0.28),
		0.70
	)
	draw_line(
		_body_point(side * waist_width * 0.04, waist_y),
		_body_point(side * waist_width * 0.35, waist_y + 0.4),
		color.lightened(0.12),
		0.75
	)
	draw_line(
		_body_point(side * torso_width * 0.08, upper_top_y + 0.4),
		_body_point(-side * torso_width * 0.16, upper_top_y - 0.2),
		color.darkened(0.18),
		0.65
	)


func _draw_apron_back_straps(
	shoulder_width: float, waist_width: float, color: Color, back_turn: float
) -> void:
	var strap_color := color.darkened(0.18)
	var top_y := -6.2 - back_turn * 0.35
	var waist_y := 4.2
	draw_line(
		_body_point(-shoulder_width * 0.24, top_y),
		_body_point(waist_width * 0.35, waist_y),
		strap_color,
		0.85
	)
	draw_line(
		_body_point(shoulder_width * 0.24, top_y),
		_body_point(-waist_width * 0.35, waist_y),
		strap_color,
		0.85
	)
	draw_line(
		_body_point(-waist_width * 0.42, waist_y),
		_body_point(waist_width * 0.42, waist_y),
		color,
		0.9
	)


func _apron_draw_mode() -> String:
	var forward := _facing_forward()
	if maxf(0.0, -forward.y) > 0.55:
		return "back"
	if absf(forward.x) > 0.72 and maxf(0.0, forward.y) < 0.32:
		return "side"
	return "front"


func _draw_head_equipment_layer(proportions: Dictionary) -> void:
	if not equipped_visuals.has("head"):
		return
	var color := _equipment_color("head")
	var head_size := _proportion(proportions, "head_size")
	var radius := 7.1 * head_size
	var head_offset := _head_turn_offset()
	var back_turn := _back_turn_amount()
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
	_draw_shape(cap, color, OUTLINE, 0.75)
	draw_line(
		head_offset + Vector2(-radius * 0.42, -15.0),
		head_offset + Vector2(radius * 0.42, -15.2),
		color.lightened(0.18),
		0.55
	)


func _draw_glove_equipment(side: float, proportions: Dictionary) -> void:
	if not equipped_visuals.has("gloves"):
		return
	var hand_size := _proportion(proportions, "hand_size")
	var sneak_lower := 1.6 if is_sneaking else 0.0
	_draw_mitten(
		_hand_anchor(side, proportions) + Vector2(0.0, sneak_lower) + _hand_sway(side),
		3.0 * hand_size,
		side,
		_equipment_color("gloves")
	)


func _draw_hand_equipment(slot_id: String, proportions: Dictionary) -> void:
	var normalized_slot := EquipmentSlots.normalize(slot_id)
	if normalized_slot == "left_hand" and equipped_visuals.has("left_hand"):
		var hand_center := (
			_hand_anchor(-1.0, proportions)
			+ Vector2(0.0, 1.6 if is_sneaking else 0.0)
			+ _hand_sway(-1.0)
		)
		draw_circle(
			hand_center,
			5.0 * _proportion(proportions, "hand_size"),
			_equipment_color("left_hand")
		)
	if normalized_slot == "right_hand" and equipped_visuals.has("right_hand"):
		var color := _equipment_color("right_hand")
		var direction := facing_direction.normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.DOWN
		var start := (
			_hand_anchor(1.0, proportions)
			+ direction * 3.0
			+ Vector2(0.0, 1.6 if is_sneaking else 0.0)
			+ _hand_sway(1.0)
		)
		var end := start + direction * 13.0
		draw_line(start, end, color, 3.0)
		draw_circle(end, 2.0, color.lightened(0.2))


func _draw_face(proportions: Dictionary) -> void:
	if _back_turn_amount() > 0.55:
		return
	var head_size := _proportion(proportions, "head_size")
	var side_turn := _side_turn_amount()
	var features := _face_feature_positions(head_size)
	var eye_color := Color(0.025, 0.020, 0.016)
	var mouth_color := Color(0.16, 0.08, 0.045, 0.55)
	if side_turn > 0.70:
		draw_line(
			features["eye_a"],
			features["eye_b"],
			eye_color,
			1.0 * head_size
		)
		draw_line(
			features["mouth_a"],
			features["mouth_b"],
			mouth_color,
			0.75
		)
		return

	draw_line(
		features["left_eye_a"],
		features["left_eye_b"],
		eye_color,
		1.0 * head_size
	)
	if side_turn < 0.75:
		draw_line(
			features["right_eye_a"],
			features["right_eye_b"],
			eye_color,
			1.0 * head_size
		)
	draw_line(
		features["mouth_a"],
		features["mouth_b"],
		mouth_color,
		0.8
	)


func _equipment_color(slot_id: String) -> Color:
	return EQUIPMENT_COLORS.get(_equipment_layer_id(slot_id), Color(0.82, 0.74, 0.52))


func _equipment_layer_id(slot_id: String) -> String:
	var visual: Dictionary = equipped_visuals.get(EquipmentSlots.normalize(slot_id), {})
	return String(visual.get("visual_layer_id", ""))


func _chest_equipment_uses_wrap_style() -> bool:
	return _equipment_layer_id("chest") == "placeholder_smith_apron"


func _append_debug_hand_layer(
	order: Array[String], layer_id: String, proportions: Dictionary
) -> void:
	for side in _hand_sides_for_layer(layer_id, proportions):
		var slot_id := _hand_slot_id(float(side))
		order.append("hand:%s" % slot_id)
		if equipped_visuals.has("gloves"):
			order.append("equipment:gloves:%s" % slot_id)
		if equipped_visuals.has(slot_id):
			order.append("equipment:%s" % slot_id)


func _people_feature_layer_ids(people_id: String, layer_id: String) -> Array[String]:
	var source_ids := _appearance_feature_ids(people_id)
	var result: Array[String] = []
	for feature_id in source_ids:
		if people_id == "people_tanglekin":
			if layer_id == PEOPLE_FEATURE_LAYER_BACK and feature_id == "feature_tanglekin_tail":
				result.append(feature_id)
			elif layer_id == PEOPLE_FEATURE_LAYER_FRONT and feature_id != "feature_tanglekin_tail":
				result.append(feature_id)
		elif people_id == "people_ravenfolk":
			if layer_id == PEOPLE_FEATURE_LAYER_BACK and feature_id == "feature_ravenfolk_tail_feathers":
				result.append(feature_id)
			elif (
				layer_id == PEOPLE_FEATURE_LAYER_BODY
				and feature_id == "feature_ravenfolk_body_feathers"
			):
				result.append(feature_id)
			elif (
				layer_id == PEOPLE_FEATURE_LAYER_FRONT
				and feature_id
				in [
					"feature_ravenfolk_head_crest",
					"feature_ravenfolk_beak",
					"feature_ravenfolk_quill_marks"
				]
			):
				result.append(feature_id)
		elif layer_id == PEOPLE_FEATURE_LAYER_FRONT:
			result.append(feature_id)
	return result


func _appearance_feature_ids(people_id: String) -> Array[String]:
	var appearance: Dictionary = profile.get("appearance", {})
	var feature_ids := HumanoidProfile.string_array(appearance.get("feature_ids", []))
	if people_id == "people_mirefolk" and not feature_ids.has("feature_mirefolk_high_eyes"):
		feature_ids.append("feature_mirefolk_high_eyes")
	if not feature_ids.is_empty():
		return feature_ids
	var defaults := {
		"people_tanglekin": [
			"feature_tanglekin_tail",
			"feature_tanglekin_grasping_hands",
			"feature_tanglekin_muzzle"
		],
		"people_tuskfolk": ["feature_tusks_broad"],
		"people_mirefolk": ["feature_mirefolk_high_eyes"],
		"people_ravenfolk": [
			"feature_ravenfolk_body_feathers",
			"feature_ravenfolk_head_crest",
			"feature_ravenfolk_beak"
		],
		"people_rootborn": [
			"feature_rootborn_leaf_crown",
			"feature_rootborn_bark_marks",
			"feature_rootborn_branch_crown"
		]
	}
	var fallback: Array[String] = []
	for feature_id in defaults.get(people_id, []):
		fallback.append(str(feature_id))
	return fallback


func _should_draw_hair(people_id: String) -> bool:
	return people_id == "people_human"


func _should_draw_generic_face(people_id: String) -> bool:
	return not ["people_tanglekin", "people_mirefolk", "people_ravenfolk"].has(people_id)


func _draw_oval(rect: Rect2, color: Color) -> void:
	draw_ellipse(rect.get_center(), rect.size.x * 0.5, rect.size.y * 0.5, color)


func _draw_outlined_oval(
	rect: Rect2, color: Color, outline: Color = OUTLINE, outline_width: float = 1.0
) -> void:
	var center := rect.get_center()
	draw_ellipse(
		center,
		rect.size.x * 0.5 + outline_width,
		rect.size.y * 0.5 + outline_width,
		outline
	)
	draw_ellipse(center, rect.size.x * 0.5, rect.size.y * 0.5, color)


func _draw_shape(
	points: PackedVector2Array, fill: Color, outline: Color = OUTLINE, outline_width: float = 1.0
) -> void:
	draw_polygon(points, PackedColorArray([fill]))
	var outline_points := points.duplicate()
	outline_points.append(points[0])
	draw_polyline(outline_points, outline, outline_width)


func _draw_foot(center: Vector2, width: float, height: float, side: float, color: Color) -> void:
	var forward := _facing_forward()
	var lateral := _facing_lateral()
	var toe_bias := lateral * width * 0.12 * side
	var points := PackedVector2Array(
		[
			center - forward * height * 0.44 - lateral * width * 0.36,
			center - forward * height * 0.44 + lateral * width * 0.36,
			center + forward * height * 0.28 + lateral * width * 0.45 + toe_bias,
			center + forward * height * 0.52 + toe_bias,
			center + forward * height * 0.28 - lateral * width * 0.45 + toe_bias
		]
	)
	_draw_shape(points, color, OUTLINE, 1.0)


func _draw_mitten(center: Vector2, radius: float, side: float, skin: Color) -> void:
	var points := PackedVector2Array(
		[
			center + Vector2(-radius * 0.65 * side, -radius * 0.85),
			center + Vector2(radius * 0.25 * side, -radius * 0.98),
			center + Vector2(radius * 0.78 * side, -radius * 0.22),
			center + Vector2(radius * 0.46 * side, radius * 0.74),
			center + Vector2(-radius * 0.30 * side, radius * 0.86),
			center + Vector2(-radius * 0.82 * side, radius * 0.20)
		]
	)
	_draw_shape(points, skin, OUTLINE, 1.0)
	draw_line(
		center + Vector2(-radius * 0.15 * side, -radius * 0.30),
		center + Vector2(radius * 0.35 * side, radius * 0.18),
		skin.lightened(0.14),
		0.7
	)


func _foot_anchor(side: float, proportions: Dictionary) -> Vector2:
	var foot_size := _proportion(proportions, "foot_size")
	var stance := 3.0 + foot_size * 0.55 + (0.8 if is_sneaking else 0.0)
	var lateral := _facing_lateral()
	return Vector2(0.0, 10.0) + lateral * side * stance


func _walk_phase() -> float:
	return animation_time


func _bob_offset() -> float:
	if locomotion_state == LOCOMOTION_WALK:
		return -absf(sin(_walk_phase())) * 0.35 * move_intensity
	if locomotion_state == LOCOMOTION_SNEAK:
		return -absf(sin(_walk_phase())) * 0.12 * move_intensity
	return sin(animation_time) * 0.25


func _stride_offset(side: float) -> Vector2:
	if locomotion_state == LOCOMOTION_WALK:
		var phase := sin(_walk_phase() + (PI if side > 0.0 else 0.0))
		return (_facing_forward() * phase * 2.35 + Vector2(0.0, -absf(phase) * 0.25)) * move_intensity
	if locomotion_state == LOCOMOTION_SNEAK:
		var phase := sin(_walk_phase() + (PI if side > 0.0 else 0.0))
		return (_facing_forward() * phase * 1.05 + Vector2(0.0, -absf(phase) * 0.10)) * move_intensity
	return Vector2.ZERO


func _hand_sway(side: float) -> Vector2:
	if locomotion_state == LOCOMOTION_WALK:
		var phase := sin(_walk_phase() + (PI if side < 0.0 else 0.0))
		return Vector2(phase * 0.55 * side, phase * 1.35) * move_intensity
	if locomotion_state == LOCOMOTION_SNEAK:
		var phase := sin(_walk_phase() + (PI if side < 0.0 else 0.0))
		return Vector2(phase * 0.25 * side, phase * 0.45) * move_intensity
	return Vector2(0.0, sin(animation_time) * 0.12)


func _sneak_crouch_offset() -> float:
	if is_sneaking:
		return 3.2
	return 0.0


func _body_turn_x() -> float:
	return _facing_forward().x * _side_turn_amount() * 0.9


func _body_side_axis() -> Vector2:
	var side_turn := _side_turn_amount()
	return Vector2(
		lerpf(1.0, 0.54, side_turn),
		_facing_forward().x * side_turn * 0.22
	)


func _body_point(local_x: float, local_y: float) -> Vector2:
	return Vector2(_body_turn_x(), 0.0) + _body_side_axis() * local_x + Vector2(0.0, local_y)


func _body_polygon(local_points: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for local_point in local_points:
		var point: Vector2 = local_point
		points.append(_body_point(point.x, point.y))
	return points


func _shoulder_anchor(side: float, proportions: Dictionary) -> Vector2:
	var shoulder_width := 18.0 * _proportion(proportions, "shoulder_width")
	var shoulder_roll := sin(_walk_phase()) * move_intensity
	return _body_point(side * shoulder_width * 0.50, -6.6 + 0.35 * shoulder_roll)


func _hand_anchor(side: float, proportions: Dictionary) -> Vector2:
	var shoulder := _shoulder_anchor(side, proportions)
	var drop := Vector2(0.0, 6.2)
	var outside := _body_side_axis() * side * 1.2 * lerpf(1.0, 0.45, _side_turn_amount())
	return shoulder + outside + drop


func _hand_sides_for_layer(layer_id: String, proportions: Dictionary) -> Array:
	var near_sides := _near_hand_sides(proportions)
	var sides := []
	for side in [-1.0, 1.0]:
		var is_near := near_sides.has(side)
		if layer_id == PEOPLE_FEATURE_LAYER_FRONT and is_near:
			sides.append(side)
		elif layer_id == PEOPLE_FEATURE_LAYER_BACK and not is_near:
			sides.append(side)
	return sides


func _near_hand_sides(proportions: Dictionary) -> Array:
	var forward := _facing_forward()
	if forward.y > 0.45:
		return [-1.0, 1.0]
	if forward.y < -0.45:
		return []
	var left_y := (_hand_anchor(-1.0, proportions) + _hand_sway(-1.0)).y
	var right_y := (_hand_anchor(1.0, proportions) + _hand_sway(1.0)).y
	if absf(left_y - right_y) < 0.05:
		return [-1.0, 1.0]
	return [-1.0] if left_y > right_y else [1.0]


func _hand_slot_id(side: float) -> String:
	return "left_hand" if side < 0.0 else "right_hand"


func _facing_forward() -> Vector2:
	if facing_direction.length() <= 0.01:
		return Vector2.DOWN
	return facing_direction.normalized()


func _facing_bucket_index() -> int:
	return FacingBuckets.bucket_index(_facing_forward())


func _facing_lateral() -> Vector2:
	var forward := _facing_forward()
	return Vector2(-forward.y, forward.x)


func _side_turn_amount() -> float:
	return clampf(absf(_facing_forward().x), 0.0, 1.0)


func _front_turn_amount() -> float:
	return clampf(maxf(0.0, _facing_forward().y), 0.0, 1.0)


func _back_turn_amount() -> float:
	return clampf(maxf(0.0, -_facing_forward().y), 0.0, 1.0)


func _is_back_view() -> bool:
	return _back_turn_amount() > 0.55


func _head_turn_offset() -> Vector2:
	var forward := _facing_forward()
	return Vector2(
		forward.x * _side_turn_amount() * 1.4,
		maxf(0.0, forward.y) * 0.35 - _back_turn_amount() * 0.55
	)


func _face_side() -> float:
	var side := signf(_facing_forward().x)
	return 1.0 if side == 0.0 else side


func _face_feature_positions(head_size: float) -> Dictionary:
	var head_offset := _head_turn_offset()
	var side_turn := _side_turn_amount()
	if side_turn > 0.70:
		var side := _face_side()
		return {
			"eye_a": head_offset + Vector2(side * 0.65 * head_size, -14.15),
			"eye_b": head_offset + Vector2(side * 1.85 * head_size, -14.20),
			"mouth_a": head_offset + Vector2(side * 0.95 * head_size, -11.55),
			"mouth_b": head_offset + Vector2(side * 2.15 * head_size, -11.40)
		}
	var look_x := facing_direction.x * side_turn * 0.45
	return {
		"left_eye_a": head_offset + Vector2((-3.1 + look_x) * head_size, -14.1),
		"left_eye_b": head_offset + Vector2((-1.6 + look_x) * head_size, -14.0),
		"right_eye_a": head_offset + Vector2((1.6 + look_x) * head_size, -14.0),
		"right_eye_b": head_offset + Vector2((3.1 + look_x) * head_size, -14.1),
		"mouth_a": head_offset + Vector2((-1.1 + look_x) * head_size, -11.6),
		"mouth_b": head_offset + Vector2((1.0 + look_x) * head_size, -11.4)
	}


func _should_draw_marking(marking_id: String) -> bool:
	if marking_id.is_empty():
		return false
	match marking_id:
		"marking_brow_left":
			return _face_detail_visible_on_side(-1.0)
		"marking_cheek_dots":
			return _face_detail_visible_on_side(-1.0)
		"marking_ash_streak":
			return _face_detail_visible_on_side(1.0)
		"marking_chest_band":
			return _front_surface_visible()
	return true


func _face_detail_visible_on_side(local_side: float) -> bool:
	if not _front_surface_visible():
		return false
	if _side_turn_amount() <= 0.62:
		return true
	return signf(local_side) == _face_side()


func _front_surface_visible() -> bool:
	return _back_turn_amount() < 0.55


func _face_mark_point(local_x: float, y: float, head_size: float) -> Vector2:
	var side_turn := _side_turn_amount()
	var x := local_x
	if side_turn > 0.62:
		x = _face_side() * absf(local_x) * lerpf(0.72, 0.34, side_turn)
	else:
		x += facing_direction.x * side_turn * 0.45
	return _head_turn_offset() + Vector2(x * head_size, y)


func _tanglekin_side_muzzle_rect(head_size: float) -> Rect2:
	var side := _face_side()
	var center := _head_turn_offset() + Vector2(side * 2.45 * head_size, -11.25)
	var size := Vector2(4.45 * head_size, 3.35 * head_size)
	return Rect2(center - size * 0.5, size)


func _ravenfolk_near_eye_point(head_size: float) -> Vector2:
	return _head_turn_offset() + Vector2(_face_side() * 1.75 * head_size, -14.45)


func _ravenfolk_side_beak_points(head_size: float) -> PackedVector2Array:
	var side := _face_side()
	var head_offset := _head_turn_offset()
	return PackedVector2Array(
		[
			head_offset + Vector2(side * 0.75 * head_size, -12.9),
			head_offset + Vector2(side * 3.85 * head_size, -11.65),
			head_offset + Vector2(side * 3.35 * head_size, -10.35),
			head_offset + Vector2(side * 0.80 * head_size, -9.15)
		]
	)


func _tuskfolk_side_tusk_points(head_size: float, tusk_length: float) -> PackedVector2Array:
	var side := _face_side()
	var head_offset := _head_turn_offset()
	var side_tusk_length := minf(tusk_length * 0.46, 4.05)
	return PackedVector2Array(
		[
			head_offset + Vector2(side * 1.8 * head_size, -9.45),
			head_offset + Vector2(side * side_tusk_length * head_size, -5.75),
			head_offset + Vector2(side * 2.95 * head_size, -10.55)
		]
	)


func _stable_index(text: String, size: int) -> int:
	if size <= 0:
		return 0
	var total: int = 0
	for index in text.length():
		total += text.unicode_at(index) * (index + 1)
	return total % size


func _proportion(proportions: Dictionary, field_id: String) -> float:
	var value: Variant = proportions.get(field_id, 1.0)
	if not (value is int or value is float):
		return 1.0
	return clampf(float(value), HumanoidProfile.MIN_PROPORTION, HumanoidProfile.MAX_PROPORTION)


func _hair_color(hair_id: String) -> Color:
	return HAIR_COLORS.get(hair_id, HAIR_COLORS["hair_black"])
