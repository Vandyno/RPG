class_name DirectionalAttack
extends RefCounted

const ActorRules = preload("res://scripts/core/actor_rules.gd")

const DEFAULT_ATTACK := {
	"name": "Unarmed",
	"shape": "punch",
	"range_pixels": 34.0,
	"width_pixels": 26.0,
	"arc_degrees": 100.0,
	"damage": 2,
	"attack_interval_seconds": 0.45,
	"visual": "punch",
	"miss_text": "Punched"
}


static func weapon_attack(content, equipment) -> Dictionary:
	var item := equipped_weapon(content, equipment)
	return weapon_attack_from_item(item)


static func weapon_attack_for_item(content, item_id: String) -> Dictionary:
	if not content or item_id.is_empty():
		return weapon_attack_from_item({})
	return weapon_attack_from_item(content.get_item(item_id))


static func weapon_attack_from_item(item: Dictionary) -> Dictionary:
	var attack := _dictionary_field(item.get("weapon_attack", {}))
	if attack.is_empty():
		attack = DEFAULT_ATTACK.duplicate(true)
	else:
		attack = _merged_attack(DEFAULT_ATTACK, attack)
		attack["item_id"] = String(item.get("id", ""))
		var avatar_visual := _dictionary_field(item.get("avatar_visual", {}))
		if not avatar_visual.is_empty():
			attack["weapon_visual_id"] = String(avatar_visual.get("visual_layer_id", ""))
	attack["item_name"] = String(item.get("name", attack.get("name", "Weapon")))
	return attack


static func equipped_weapon(content, equipment) -> Dictionary:
	if not content or not equipment or not equipment.has_method("get_equipped_item"):
		return {}
	var item_id: String = equipment.get_equipped_item("right_hand")
	if not item_id.is_empty():
		return content.get_item(item_id)
	return {}


static func targets_in_shape(candidate_entities: Array, query: Dictionary) -> Array:
	var result := []
	for entity in candidate_entities:
		if not ActorRules.is_combat_target_entity(entity):
			continue
		if contains_point(entity.global_position, query):
			result.append(entity)
	return result


static func targets_in_weapon_sweep(candidate_entities: Array, query: Dictionary) -> Array:
	var result := []
	for entity in candidate_entities:
		if not ActorRules.is_combat_target_entity(entity):
			continue
		if weapon_sweep_contains_point(entity.global_position, query):
			result.append(entity)
	return result


static func contains_point(point: Vector2, query: Dictionary) -> bool:
	var origin := _query_origin(query)
	var direction := _query_direction(query)
	var attack := _query_attack(query)
	var facing := direction.normalized()
	if facing.length() <= 0.01:
		return false
	var delta := point - origin
	var forward := delta.dot(facing)
	var range_px := maxf(1.0, float(attack.get("range_pixels", 32.0)))
	if forward < -4.0 or forward > range_px:
		return false
	var lateral := absf(delta.cross(facing))
	var width := maxf(1.0, float(attack.get("width_pixels", 24.0)))
	match String(attack.get("shape", "swing")):
		"thrust", "projectile":
			return lateral <= width * 0.5
		"cone", "stream":
			var t := clampf(forward / range_px, 0.0, 1.0)
			return lateral <= lerpf(width * 0.20, width * 0.5, t)
		_:
			var arc := deg_to_rad(maxf(1.0, float(attack.get("arc_degrees", 100.0))))
			if delta.length() <= 4.0:
				return true
			return facing.dot(delta.normalized()) >= cos(arc * 0.5)
	return false


static func weapon_sweep_contains_point(point: Vector2, query: Dictionary) -> bool:
	var attack := _query_attack(query)
	match String(attack.get("shape", "swing")):
		"swing":
			return _swing_sweep_contains_point(point, query)
		_:
			return contains_point(point, query)


static func spell_attack(spell: Dictionary) -> Dictionary:
	return _merged_attack(
		{
			"name": String(spell.get("name", "Spell")),
			"shape": "cone",
			"range_pixels": 96.0,
			"width_pixels": 48.0,
			"damage_per_second": 8.0,
			"visual": "fire_stream"
		},
		_dictionary_field(spell.get("attack", {}))
	)


static func is_melee_attack(attack: Dictionary) -> bool:
	return not ["projectile"].has(String(attack.get("shape", "swing")))


static func _swing_sweep_contains_point(point: Vector2, query: Dictionary) -> bool:
	var origin := _query_origin(query)
	var direction := _query_direction(query)
	var attack := _query_attack(query)
	var facing := direction.normalized()
	if facing.length() <= 0.01:
		return false
	var delta := point - origin
	var distance := delta.length()
	var range_px := maxf(1.0, float(attack.get("range_pixels", 32.0)))
	var inner_px := maxf(0.0, float(attack.get("inner_range_pixels", range_px * 0.22)))
	var attack_width := float(
		attack.get("blade_hit_width_pixels", attack.get("width_pixels", 24.0))
	)
	var hit_width := maxf(4.0, attack_width * 0.45)
	if distance < inner_px - hit_width or distance > range_px + hit_width:
		return false
	if distance <= 4.0:
		return true
	var arc := deg_to_rad(maxf(1.0, float(attack.get("arc_degrees", 100.0))))
	var progress_from := _query_progress(query, "progress_from", 0.0)
	var progress_to := _query_progress(query, "progress_to", 1.0)
	var start_progress := clampf(minf(progress_from, progress_to), 0.0, 1.0)
	var end_progress := clampf(maxf(progress_from, progress_to), 0.0, 1.0)
	var angle_from := lerpf(-arc * 0.5, arc * 0.5, start_progress)
	var angle_to := lerpf(-arc * 0.5, arc * 0.5, end_progress)
	var relative_angle := wrapf(delta.angle() - facing.angle(), -PI, PI)
	var angle_tolerance := atan2(hit_width, maxf(1.0, distance))
	return (
		relative_angle >= angle_from - angle_tolerance
		and relative_angle <= angle_to + angle_tolerance
	)


static func _merged_attack(base: Dictionary, override: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key in override:
		result[key] = override[key]
	return result


static func _dictionary_field(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func _query_origin(query: Dictionary) -> Vector2:
	var value: Variant = query.get("origin", Vector2.ZERO)
	return value if value is Vector2 else Vector2.ZERO


static func _query_direction(query: Dictionary) -> Vector2:
	var value: Variant = query.get("direction", Vector2.ZERO)
	return value if value is Vector2 else Vector2.ZERO


static func _query_attack(query: Dictionary) -> Dictionary:
	return _dictionary_field(query.get("attack", {}))


static func _query_progress(query: Dictionary, field_id: String, fallback: float) -> float:
	var value: Variant = query.get(field_id, fallback)
	if not (value is int or value is float):
		return fallback
	return float(value)
