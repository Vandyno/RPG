class_name DirectionalAttack
extends RefCounted

const ActorRules = preload("res://scripts/core/actor_rules.gd")

const DEFAULT_ATTACK := {
	"name": "Unarmed",
	"shape": "swing",
	"range_pixels": 34.0,
	"width_pixels": 30.0,
	"arc_degrees": 100.0,
	"damage": 2,
	"attack_interval_seconds": 0.55,
	"visual": "swing"
}


static func weapon_attack(content, equipment) -> Dictionary:
	var item := equipped_weapon(content, equipment)
	var attack := _dictionary_field(item.get("weapon_attack", {}))
	if attack.is_empty():
		attack = DEFAULT_ATTACK.duplicate(true)
	else:
		attack = _merged_attack(DEFAULT_ATTACK, attack)
	attack["item_name"] = String(item.get("name", attack.get("name", "Weapon")))
	return attack


static func equipped_weapon(content, equipment) -> Dictionary:
	if not content or not equipment or not equipment.has_method("get_equipped_item"):
		return {}
	var item_id: String = equipment.get_equipped_item("right_hand")
	if not item_id.is_empty():
		return content.get_item(item_id)
	return {}


static func targets_in_shape(
	candidate_entities: Array, origin: Vector2, direction: Vector2, attack: Dictionary
) -> Array:
	var result := []
	for entity in candidate_entities:
		if not _is_combat_target(entity):
			continue
		if contains_point(origin, direction, entity.global_position, attack):
			result.append(entity)
	return result


static func contains_point(
	origin: Vector2, direction: Vector2, point: Vector2, attack: Dictionary
) -> bool:
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


static func _is_combat_target(entity) -> bool:
	if not entity:
		return false
	if entity.has_method("is_combat_target"):
		return bool(entity.is_combat_target())
	if entity.get("data") is Dictionary:
		return ActorRules.is_combat_target_data(entity.data)
	return false


static func _merged_attack(base: Dictionary, override: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key in override:
		result[key] = override[key]
	return result


static func _dictionary_field(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}
