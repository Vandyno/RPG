class_name HumanoidHeldItemDrawer
extends RefCounted

const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")
const ItemVisual2D = preload("res://scripts/items/item_visual_2d.gd")


static func draw_hand_with_equipment(
	avatar, side: float, skin: Color, proportions: Dictionary
) -> void:
	if hand_is_replaced_by_held_item(avatar, side):
		var draw_slot_id := held_item_draw_slot_for_side(avatar, side)
		if not draw_slot_id.is_empty():
			draw_hand_equipment(avatar, draw_slot_id, proportions)
		draw_held_item_arm_and_hand(avatar, side, skin, proportions)
		return
	var hand_size: float = avatar._proportion(proportions, "hand_size")
	avatar._draw_mitten(avatar._hand_position(side, proportions), 3.2 * hand_size, side, skin)
	draw_glove_equipment(avatar, side, proportions)
	draw_hand_equipment(avatar, avatar._hand_slot_id(side), proportions)


static func draw_glove_equipment(avatar, side: float, proportions: Dictionary) -> void:
	if not avatar.equipped_visuals.has("gloves"):
		return
	var hand_size: float = avatar._proportion(proportions, "hand_size")
	avatar._draw_mitten(
		avatar._hand_position(side, proportions),
		3.0 * hand_size,
		side,
		avatar._equipment_color("gloves")
	)
	_draw_glove_finish(avatar, avatar._hand_position(side, proportions), side, hand_size)


static func draw_hand_equipment(avatar, slot_id: String, proportions: Dictionary) -> void:
	var normalized_slot := EquipmentSlots.normalize(slot_id)
	if not avatar.equipped_visuals.has(normalized_slot):
		return
	var item_model := held_item_model(avatar, normalized_slot, proportions)
	if item_model.is_empty():
		return
	ItemVisual2D.draw_visual(avatar, item_model)


static func held_item_model(avatar, slot_id: String, proportions: Dictionary) -> Dictionary:
	var normalized_slot := EquipmentSlots.normalize(slot_id)
	var visual_id: String = avatar._equipment_layer_id(normalized_slot)
	if not ItemVisual2D.is_item_visual(visual_id):
		return {}
	match visual_id:
		"placeholder_polearm":
			return polearm_item_model(avatar, proportions)
		"placeholder_bow":
			return bow_item_model(avatar, proportions)
		_:
			var item_side := item_side_for_slot(avatar, normalized_slot)
			var direction: Vector2 = (
				weapon_direction(avatar)
				if visual_uses_dominant_weapon_side(visual_id)
				else avatar._facing_forward()
			)
			return ItemVisual2D.model(
				visual_id,
				avatar._hand_position(item_side, proportions),
				direction,
				{"color": avatar._equipment_color(normalized_slot)}
			)


static func draw_held_item_arm_and_hand(
	avatar, side: float, skin: Color, proportions: Dictionary
) -> void:
	var grip_value: Variant = held_item_grip_position_for_side(avatar, side, proportions)
	if grip_value == null:
		return
	var grip: Vector2 = grip_value
	var hand_size: float = avatar._proportion(proportions, "hand_size")
	var shoulder: Vector2 = avatar._shoulder_anchor(side, proportions)
	var base_hand: Vector2 = avatar._base_hand_position(side, proportions)
	var elbow_bias: Vector2 = avatar._body_side_axis() * side * 2.1 * lerpf(
		1.0, 0.55, avatar._side_turn_amount()
	)
	var elbow: Vector2 = base_hand.lerp(grip, 0.48) + elbow_bias
	var arm_color := skin.darkened(0.08)
	avatar.draw_line(shoulder, elbow, avatar.OUTLINE, 3.0 * hand_size)
	avatar.draw_line(elbow, grip, avatar.OUTLINE, 2.8 * hand_size)
	avatar.draw_line(shoulder, elbow, arm_color, 1.85 * hand_size)
	avatar.draw_line(elbow, grip, arm_color.lightened(0.04), 1.7 * hand_size)
	draw_weapon_grip_hand(avatar, grip, side, proportions)


static func draw_weapon_grip_hand(
	avatar, center: Vector2, side: float, proportions: Dictionary
) -> void:
	var hand_size: float = avatar._proportion(proportions, "hand_size")
	var color: Color = (
		avatar._equipment_color("gloves")
		if avatar.equipped_visuals.has("gloves")
		else avatar._current_skin_color()
	)
	avatar._draw_mitten(center, 2.55 * hand_size, side, color)
	if avatar.equipped_visuals.has("gloves"):
		_draw_glove_finish(avatar, center, side, hand_size)


static func _draw_glove_finish(avatar, center: Vector2, side: float, hand_size: float) -> void:
	var color: Color = avatar._equipment_color("gloves")
	var layer_id: String = avatar._equipment_layer_id("gloves")
	var cuff_start := center + Vector2(-side * 2.05 * hand_size, 0.62 * hand_size)
	var cuff_end := center + Vector2(side * 0.30 * hand_size, 0.62 * hand_size)
	if layer_id == "placeholder_iron_gauntlets":
		avatar.draw_line(cuff_start, cuff_end, color.lightened(0.30), 0.72)
		avatar.draw_line(
			center + Vector2(side * 0.18 * hand_size, -1.15 * hand_size),
			center + Vector2(side * 0.72 * hand_size, 0.85 * hand_size),
			color.darkened(0.30),
			0.48
		)
		return
	avatar.draw_line(cuff_start, cuff_end, color.darkened(0.30), 0.62)
	avatar.draw_line(
		center + Vector2(-side * 0.92 * hand_size, -0.92 * hand_size),
		center + Vector2(side * 0.48 * hand_size, 1.05 * hand_size),
		color.lightened(0.14),
		0.38
	)


static func held_item_grip_position_for_side(
	avatar, side: float, proportions: Dictionary
) -> Variant:
	var slot_id := held_item_slot_for_side(avatar, side)
	if slot_id.is_empty():
		return null
	var grip_id := held_item_grip_id_for_side(avatar, slot_id, side)
	if grip_id.is_empty():
		return null
	return ItemVisual2D.grip_position(held_item_model(avatar, slot_id, proportions), grip_id)


static func slot_item_grip_sides(avatar, slot_id: String) -> Array[float]:
	var visual_id: String = avatar._equipment_layer_id(slot_id)
	var result: Array[float] = []
	for grip_id in ItemVisual2D.grip_ids(visual_id):
		var side := grip_side_for_slot(avatar, grip_id, slot_id)
		if not is_zero_approx(side) and not result.has(side):
			result.append(side)
	return result


static func grip_side_for_slot(avatar, grip_id: String, slot_id: String) -> float:
	match grip_id:
		"front", "bow":
			return -avatar._dominant_hand_side()
		"rear", "draw":
			return avatar._dominant_hand_side()
		"primary":
			return item_side_for_slot(avatar, slot_id)
	return 0.0


static func hand_is_replaced_by_held_item(avatar, side: float) -> bool:
	return not held_item_slot_for_side(avatar, side).is_empty()


static func held_item_slot_for_side(avatar, side: float) -> String:
	for slot_id in ["left_hand", "right_hand"]:
		if slot_item_grip_sides(avatar, slot_id).has(side):
			return slot_id
	return ""


static func held_item_grip_id_for_side(avatar, slot_id: String, side: float) -> String:
	var visual_id: String = avatar._equipment_layer_id(slot_id)
	for grip_id in ItemVisual2D.grip_ids(visual_id):
		if is_equal_approx(grip_side_for_slot(avatar, grip_id, slot_id), side):
			return grip_id
	return ""


static func should_draw_held_item_from_side(avatar, side: float) -> bool:
	return not held_item_draw_slot_for_side(avatar, side).is_empty()


static func held_item_draw_slot_for_side(avatar, side: float) -> String:
	for slot_id in ["left_hand", "right_hand"]:
		if not avatar.equipped_visuals.has(slot_id):
			continue
		if not slot_item_grip_sides(avatar, slot_id).has(side):
			continue
		if is_equal_approx(held_item_draw_side(avatar, slot_id), side):
			return slot_id
	return ""


static func held_item_draw_side(avatar, slot_id: String) -> float:
	return item_side_for_slot(avatar, slot_id)


static func item_side_for_slot(avatar, slot_id: String) -> float:
	var visual_id: String = avatar._equipment_layer_id(slot_id)
	if visual_id == "placeholder_bow":
		return -avatar._dominant_hand_side()
	if visual_uses_dominant_weapon_side(visual_id):
		return avatar._dominant_hand_side()
	return slot_side(slot_id)


static func slot_side(slot_id: String) -> float:
	return -1.0 if EquipmentSlots.normalize(slot_id) == "left_hand" else 1.0


static func visual_uses_dominant_weapon_side(visual_id: String) -> bool:
	return visual_id in ["placeholder_hatchet", "placeholder_sword", "placeholder_polearm"]


static func visual_is_primary_weapon(visual_id: String) -> bool:
	return (
		visual_id
		in ["placeholder_hatchet", "placeholder_sword", "placeholder_polearm", "placeholder_bow"]
	)


static func primary_weapon_slot_id(avatar) -> String:
	for slot_id in ["right_hand", "left_hand"]:
		if visual_is_primary_weapon(avatar._equipment_layer_id(slot_id)):
			return slot_id
	return ""


static func primary_weapon_visual_id(avatar) -> String:
	var slot_id := primary_weapon_slot_id(avatar)
	if slot_id.is_empty():
		return ""
	return avatar._equipment_layer_id(slot_id)


static func attack_hand_offset(
	avatar, side: float, proportions: Dictionary, base_position: Vector2
) -> Vector2:
	if is_polearm_item_held(avatar):
		var grip_id := "rear" if is_equal_approx(side, avatar._dominant_hand_side()) else "front"
		return (
			ItemVisual2D.grip_position(polearm_item_model(avatar, proportions), grip_id)
			- base_position
		)
	if is_bow_item_held(avatar):
		var grip_id := "draw" if is_equal_approx(side, avatar._dominant_hand_side()) else "bow"
		return ItemVisual2D.grip_position(bow_item_model(avatar, proportions), grip_id) - base_position
	if not attack_pose_active(avatar):
		return Vector2.ZERO
	var progress := attack_pose_progress(avatar)
	var pulse := sin(progress * PI)
	var direction := attack_pose_direction(avatar)
	var side_axis := direction.orthogonal()
	var shape := attack_pose_shape(avatar)
	var offset := Vector2.ZERO
	match shape:
		"punch":
			if is_equal_approx(side, avatar._dominant_hand_side()):
				var eased := smooth_step(progress)
				var start := -direction * 2.5 + side_axis * 4.8
				var peak := direction * 15.5 + side_axis * 2.4
				var finish := direction * 8.5 - side_axis * 5.4
				offset = quadratic_bezier(start, peak, finish, eased)
				offset += direction * 1.6 * pulse
		"thrust":
			if is_polearm_attack_pose(avatar):
				var grip_id := (
					"rear" if is_equal_approx(side, avatar._dominant_hand_side()) else "front"
				)
				offset = (
					ItemVisual2D.grip_position(polearm_item_model(avatar, proportions), grip_id)
					- base_position
				)
			else:
				var reach := 8.0 if is_equal_approx(side, avatar._dominant_hand_side()) else 3.5
				offset = direction * reach * pulse
		"projectile":
			var draw_amount := bow_draw_amount(avatar)
			offset = (
				-direction * (4.0 + 8.5 * draw_amount) - side_axis * 0.8
				if is_equal_approx(side, avatar._dominant_hand_side())
				else direction * 4.0
			)
		_:
			if is_equal_approx(side, avatar._dominant_hand_side()):
				var attack: Dictionary = avatar.attack_pose.get("attack", {})
				var arc := deg_to_rad(float(attack.get("arc_degrees", 110.0)))
				var angle := direction.angle() + lerpf(-arc * 0.28, arc * 0.28, progress)
				offset = Vector2.RIGHT.rotated(angle) * (3.0 + 4.5 * pulse)
	return offset


static func attack_pose_active(avatar) -> bool:
	return bool(avatar.attack_pose.get("active", false))


static func attack_pose_shape(avatar) -> String:
	return String(avatar.attack_pose.get("shape", ""))


static func attack_pose_progress(avatar) -> float:
	return clampf(float(avatar.attack_pose.get("progress", 0.0)), 0.0, 1.0)


static func attack_pose_direction(avatar) -> Vector2:
	var value: Variant = avatar.attack_pose.get("direction", avatar._facing_forward())
	if value is Vector2 and value.length() > 0.01:
		return value.normalized()
	return avatar._facing_forward()


static func weapon_direction(avatar) -> Vector2:
	if not attack_pose_active(avatar):
		return avatar._facing_forward()
	var direction := attack_pose_direction(avatar)
	if attack_pose_shape(avatar) != "swing":
		return direction
	var attack: Dictionary = avatar.attack_pose.get("attack", {})
	var arc := deg_to_rad(float(attack.get("arc_degrees", 110.0)))
	var angle := direction.angle() + lerpf(-arc * 0.5, arc * 0.5, attack_pose_progress(avatar))
	return Vector2.RIGHT.rotated(angle).normalized()


static func bow_draw_amount(avatar) -> float:
	if not attack_pose_active(avatar) or attack_pose_shape(avatar) != "projectile":
		return 0.0
	var progress := attack_pose_progress(avatar)
	var attack: Dictionary = avatar.attack_pose.get("attack", {})
	if bool(attack.get("released", false)):
		var charge_ratio := clampf(float(attack.get("charge_ratio", 1.0)), 0.0, 1.0)
		return charge_ratio * (1.0 - clampf(progress / 0.30, 0.0, 1.0))
	return progress


static func is_polearm_attack_pose(avatar) -> bool:
	if attack_pose_shape(avatar) != "thrust":
		return false
	var attack: Dictionary = avatar.attack_pose.get("attack", {})
	var weapon_visual_id := String(attack.get("weapon_visual_id", primary_weapon_visual_id(avatar)))
	return weapon_visual_id == "placeholder_polearm"


static func is_polearm_item_held(avatar) -> bool:
	return primary_weapon_visual_id(avatar) == "placeholder_polearm"


static func is_bow_item_held(avatar) -> bool:
	return primary_weapon_visual_id(avatar) == "placeholder_bow"


static func polearm_item_model(avatar, proportions: Dictionary) -> Dictionary:
	var direction := weapon_direction(avatar)
	var progress := attack_pose_progress(avatar)
	if not attack_pose_active(avatar) or attack_pose_shape(avatar) != "thrust":
		progress = 0.0
	var thrust := sin(progress * PI) * 8.0
	var shoulder_scale: float = avatar._proportion(proportions, "shoulder_width")
	var side_axis := polearm_hold_side_axis(avatar, direction)
	var grip_side_offset: float = 2.1 * shoulder_scale
	var lane_offset: Vector2 = side_axis * (8.2 * shoulder_scale)
	var rear_target: Vector2 = (
		avatar._base_hand_position(avatar._dominant_hand_side(), proportions)
		+ lane_offset
		+ direction * thrust
	)
	var front_target: Vector2 = (
		avatar._base_hand_position(-avatar._dominant_hand_side(), proportions)
		+ lane_offset
		+ direction * (thrust * 0.65)
	)
	var origin_from_rear: Vector2 = rear_target + direction * 6.0 - side_axis * grip_side_offset
	var origin_from_front: Vector2 = front_target - direction * 10.0 + side_axis * grip_side_offset
	var origin: Vector2 = origin_from_rear.lerp(origin_from_front, 0.42)
	var slot_id := primary_weapon_slot_id(avatar)
	return ItemVisual2D.model(
		"placeholder_polearm",
		origin,
		direction,
		{
			"color": avatar._equipment_color(slot_id),
			"grip_side_offset": grip_side_offset,
			"side_axis": side_axis
		}
	)


static func polearm_hold_side_axis(avatar, direction: Vector2) -> Vector2:
	var safe_direction := direction.normalized()
	if safe_direction.length() <= 0.01:
		safe_direction = avatar._facing_forward()
	var side_axis := safe_direction.orthogonal()
	var wanted_side_axis: Vector2 = avatar._body_side_axis() * avatar._dominant_hand_side()
	if side_axis.dot(wanted_side_axis) < 0.0:
		side_axis = -side_axis
	return side_axis.normalized()


static func bow_hold_side_axis(avatar, direction: Vector2) -> Vector2:
	var safe_direction := direction.normalized()
	if safe_direction.length() <= 0.01:
		safe_direction = avatar._facing_forward()
	var side_axis := safe_direction.orthogonal()
	var wanted_draw_axis: Vector2 = avatar._body_side_axis() * avatar._dominant_hand_side()
	if (-side_axis).dot(wanted_draw_axis) < 0.0:
		side_axis = -side_axis
	return side_axis.normalized()


static func bow_item_model(avatar, proportions: Dictionary) -> Dictionary:
	var direction := attack_pose_direction(avatar)
	var side_axis := bow_hold_side_axis(avatar, direction)
	var origin: Vector2 = (
		avatar._base_hand_position(-avatar._dominant_hand_side(), proportions) + direction * 0.5
	)
	var attack: Dictionary = avatar.attack_pose.get("attack", {})
	var released := bool(attack.get("released", false))
	var arrow_visible := (
		attack_pose_active(avatar)
		and attack_pose_shape(avatar) == "projectile"
		and (not released or attack_pose_progress(avatar) < 0.26)
	)
	return ItemVisual2D.model(
		"placeholder_bow",
		origin,
		direction,
		{
			"color": avatar._equipment_color(primary_weapon_slot_id(avatar)),
			"draw_amount": bow_draw_amount(avatar),
			"arrow_visible": arrow_visible,
			"side_axis": side_axis
		}
	)


static func smooth_step(value: float) -> float:
	var safe_value := clampf(value, 0.0, 1.0)
	return safe_value * safe_value * (3.0 - 2.0 * safe_value)


static func quadratic_bezier(start: Vector2, control: Vector2, end: Vector2, t: float) -> Vector2:
	var safe_t := clampf(t, 0.0, 1.0)
	var one_minus_t := 1.0 - safe_t
	return (
		start * one_minus_t * one_minus_t
		+ control * 2.0 * one_minus_t * safe_t
		+ end * safe_t * safe_t
	)
