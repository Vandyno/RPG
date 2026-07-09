# gdlint:disable=max-file-lines
class_name HumanoidAvatar2D
extends Node2D

const HumanoidProfile = preload("res://scripts/characters/humanoid_profile.gd")
const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")
const FacingBuckets = preload("res://scripts/core/facing_buckets.gd")
const HumanoidPeopleFeatureDrawer = preload(
	"res://scripts/characters/humanoid_people_feature_drawer.gd"
)
const HumanoidRavenfolkFeatureDrawer = preload(
	"res://scripts/characters/humanoid_ravenfolk_feature_drawer.gd"
)
const HumanoidEquipmentDrawer = preload("res://scripts/characters/humanoid_equipment_drawer.gd")
const HumanoidHeldItemDrawer = preload("res://scripts/characters/humanoid_held_item_drawer.gd")
const ItemVisual2D = preload("res://scripts/items/item_visual_2d.gd")

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
var attack_pose: Dictionary = {}


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


func set_attack_pose(attack_data: Dictionary, direction: Vector2, progress: float) -> void:
	var safe_direction := direction.normalized()
	if safe_direction.length() <= 0.01:
		safe_direction = _facing_forward()
	attack_pose = {
		"active": true,
		"shape": String(attack_data.get("shape", "swing")),
		"attack": attack_data.duplicate(true),
		"direction": safe_direction,
		"progress": clampf(progress, 0.0, 1.0)
	}
	queue_redraw()


func clear_attack_pose() -> void:
	if attack_pose.is_empty():
		return
	attack_pose.clear()
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
	if HumanoidPeopleFeatureDrawer.should_draw_hair(people_id):
		order.append("hair")
	if equipped_visuals.has("head"):
		order.append("equipment:head")
	if _should_draw_marking(String(appearance.get("marking_id", ""))):
		order.append("marking")
	if HumanoidPeopleFeatureDrawer.should_draw_generic_face(people_id):
		order.append("face:generic")
	return order


func get_body_part_anchors() -> Dictionary:
	var appearance: Dictionary = profile.get("appearance", {})
	var proportions: Dictionary = appearance.get("proportions", {})
	var anchors := {
		"head": _head_turn_offset() + Vector2(0.0, -14.2),
		"chest": _body_point(0.0, -2.0),
		"waist": _body_point(0.0, 4.8),
		"left_hand": _hand_position(-1.0, proportions),
		"right_hand": _hand_position(1.0, proportions),
		"left_foot": Vector2.ZERO + _foot_anchor(-1.0, proportions),
		"right_foot": Vector2.ZERO + _foot_anchor(1.0, proportions)
	}
	var body_height := _proportion(proportions, "body_height")
	for anchor_id in anchors:
		var point: Vector2 = anchors[anchor_id]
		anchors[anchor_id] = Vector2(point.x, point.y * body_height)
	var dominant_hand_id := _hand_slot_id(_dominant_hand_side())
	var off_hand_id := _hand_slot_id(-_dominant_hand_side())
	anchors["weapon_hand"] = anchors[dominant_hand_id]
	anchors["draw_hand"] = anchors[dominant_hand_id]
	anchors["off_hand"] = anchors[off_hand_id]
	anchors["bow_hand"] = anchors[off_hand_id]
	return {
		"head": anchors["head"],
		"chest": anchors["chest"],
		"waist": anchors["waist"],
		"left_hand": anchors["left_hand"],
		"right_hand": anchors["right_hand"],
		"weapon_hand": anchors["weapon_hand"],
		"draw_hand": anchors["draw_hand"],
		"off_hand": anchors["off_hand"],
		"bow_hand": anchors["bow_hand"],
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
	if HumanoidPeopleFeatureDrawer.should_draw_hair(people_id):
		_draw_hair(hair_id, hair, proportions)
	HumanoidEquipmentDrawer.draw_head_layer(self, proportions)
	_draw_marking(String(appearance.get("marking_id", "")), skin, proportions)
	if HumanoidPeopleFeatureDrawer.should_draw_generic_face(people_id):
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
		chest_plane, skin.lightened(0.03 + front_turn * 0.02), Color(0.0, 0.0, 0.0, 0.0), 0.0
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
	_draw_mitten(_hand_position(-1.0, proportions), 3.2 * hand_size, -1.0, skin)
	_draw_mitten(_hand_position(1.0, proportions), 3.2 * hand_size, 1.0, skin)


func _draw_hand_layer(skin: Color, proportions: Dictionary, layer_id: String) -> void:
	for side in _hand_sides_for_layer(layer_id, proportions):
		_draw_hand_with_equipment(float(side), skin, proportions)


func _draw_hand_with_equipment(side: float, skin: Color, proportions: Dictionary) -> void:
	HumanoidHeldItemDrawer.draw_hand_with_equipment(self, side, skin, proportions)


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
				(
					head_offset
					+ Vector2(side * radius * (0.72 + float(curl_index % 2) * 0.05), curl_y)
				),
				1.7 * head_size,
				hair
			)
			draw_arc(
				(
					head_offset
					+ Vector2(side * radius * (0.72 + float(curl_index % 2) * 0.05), curl_y)
				),
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
			draw_line(_body_point(-5.4, -2.4), _body_point(5.4, -0.6), mark_color, 0.85)
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


func _draw_face(proportions: Dictionary) -> void:
	if _back_turn_amount() > 0.55:
		return
	var head_size := _proportion(proportions, "head_size")
	var side_turn := _side_turn_amount()
	var features := _face_feature_positions(head_size)
	var eye_color := Color(0.025, 0.020, 0.016)
	var mouth_color := Color(0.16, 0.08, 0.045, 0.55)
	if side_turn > 0.70:
		draw_line(features["eye_a"], features["eye_b"], eye_color, 1.0 * head_size)
		draw_line(features["mouth_a"], features["mouth_b"], mouth_color, 0.75)
		return

	draw_line(features["left_eye_a"], features["left_eye_b"], eye_color, 1.0 * head_size)
	if side_turn < 0.75:
		draw_line(features["right_eye_a"], features["right_eye_b"], eye_color, 1.0 * head_size)
	draw_line(features["mouth_a"], features["mouth_b"], mouth_color, 0.8)


func _equipment_color(slot_id: String) -> Color:
	return EQUIPMENT_COLORS.get(_equipment_layer_id(slot_id), Color(0.82, 0.74, 0.52))


func _current_skin_color() -> Color:
	var appearance: Dictionary = profile.get("appearance", {})
	var palette: Dictionary = PALETTES.get(
		String(appearance.get("palette_id", "")), PALETTES["palette_human_warm_brown"]
	)
	return palette["skin"]


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
		if HumanoidHeldItemDrawer.hand_is_replaced_by_held_item(self, float(side)):
			var draw_slot_id := HumanoidHeldItemDrawer.held_item_draw_slot_for_side(
				self, float(side)
			)
			if not draw_slot_id.is_empty():
				order.append("equipment:%s" % draw_slot_id)
			order.append("item_grip:%s" % slot_id)
			continue
		order.append("hand:%s" % slot_id)
		if equipped_visuals.has("gloves"):
			order.append("equipment:gloves:%s" % slot_id)
		if equipped_visuals.has(slot_id):
			order.append("equipment:%s" % slot_id)


func _draw_oval(rect: Rect2, color: Color) -> void:
	draw_ellipse(rect.get_center(), rect.size.x * 0.5, rect.size.y * 0.5, color)


func _draw_outlined_oval(
	rect: Rect2, color: Color, outline: Color = OUTLINE, outline_width: float = 1.0
) -> void:
	var center := rect.get_center()
	draw_ellipse(
		center, rect.size.x * 0.5 + outline_width, rect.size.y * 0.5 + outline_width, outline
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
		return (
			(_facing_forward() * phase * 2.35 + Vector2(0.0, -absf(phase) * 0.25)) * move_intensity
		)
	if locomotion_state == LOCOMOTION_SNEAK:
		var phase := sin(_walk_phase() + (PI if side > 0.0 else 0.0))
		return (
			(_facing_forward() * phase * 1.05 + Vector2(0.0, -absf(phase) * 0.10)) * move_intensity
		)
	return Vector2.ZERO


func _hand_sway(side: float) -> Vector2:
	if locomotion_state == LOCOMOTION_WALK:
		var phase := sin(_walk_phase() + (PI if side < 0.0 else 0.0))
		return Vector2(phase * 0.55 * side, phase * 1.35) * move_intensity
	if locomotion_state == LOCOMOTION_SNEAK:
		var phase := sin(_walk_phase() + (PI if side < 0.0 else 0.0))
		return Vector2(phase * 0.25 * side, phase * 0.45) * move_intensity
	return Vector2(0.0, sin(animation_time) * 0.12)


func _hand_position(side: float, proportions: Dictionary) -> Vector2:
	var base := _base_hand_position(side, proportions)
	return base + HumanoidHeldItemDrawer.attack_hand_offset(self, side, proportions, base)


func _base_hand_position(side: float, proportions: Dictionary) -> Vector2:
	var sneak_lower := 1.6 if is_sneaking else 0.0
	return _hand_anchor(side, proportions) + Vector2(0.0, sneak_lower) + _hand_sway(side)


func _sneak_crouch_offset() -> float:
	if is_sneaking:
		return 3.2
	return 0.0


func _body_turn_x() -> float:
	return _facing_forward().x * _side_turn_amount() * 0.9


func _body_side_axis() -> Vector2:
	var side_turn := _side_turn_amount()
	return Vector2(lerpf(1.0, 0.54, side_turn), _facing_forward().x * side_turn * 0.22)


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
	var left_y := _hand_position(-1.0, proportions).y
	var right_y := _hand_position(1.0, proportions).y
	if absf(left_y - right_y) < 0.05:
		return [-1.0, 1.0]
	return [-1.0] if left_y > right_y else [1.0]


func _hand_slot_id(side: float) -> String:
	return "left_hand" if side < 0.0 else "right_hand"


func _dominant_hand_side() -> float:
	return -1.0 if String(profile.get("handedness", "right")) == "left" else 1.0


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


func _ravenfolk_near_eye_point(head_size: float) -> Vector2:
	return HumanoidRavenfolkFeatureDrawer.near_eye_point(self, head_size)


func _ravenfolk_side_beak_points(head_size: float) -> PackedVector2Array:
	return HumanoidRavenfolkFeatureDrawer.side_beak_points(self, head_size)


func _proportion(proportions: Dictionary, field_id: String) -> float:
	return HumanoidProfile.proportion_value(proportions, field_id)


func _hair_color(hair_id: String) -> Color:
	return HAIR_COLORS.get(hair_id, HAIR_COLORS["hair_black"])
