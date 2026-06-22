class_name CombatManager
extends Node

const DEFAULT_MAX_HEALTH := 12
const DEFAULT_PLAYER_DAMAGE := 6
const DEFAULT_ENEMY_DAMAGE := 4
const GUARD_COUNTER_DAMAGE_MULTIPLIER := 0.5

var event_bus
var equipment
var progression
var statuses
var health_by_entity_id: Dictionary = {}
var player_damage := DEFAULT_PLAYER_DAMAGE


func setup(
	bus, equipment_manager = null, progression_manager = null, status_effect_manager = null
) -> void:
	event_bus = bus
	equipment = equipment_manager
	progression = progression_manager
	statuses = status_effect_manager


func attack_entity(entity, guarded: bool = false) -> Dictionary:
	var entity_id: String = entity.get_entity_id()
	var max_health := _max_health_for_entity(entity)
	var current_health := _clamped_entity_health(entity_id, max_health)
	var damage := _attack_damage_for_entity(entity)
	var next_health := maxi(0, current_health - damage)
	var defeated := next_health <= 0
	var raw_counter_damage := (
		0
		if defeated
		else _non_negative_int_field(entity.data, "attack_damage", DEFAULT_ENEMY_DAMAGE)
	)
	var counter_damage := (
		_guarded_counter_damage(raw_counter_damage) if guarded else raw_counter_damage
	)

	if defeated:
		health_by_entity_id.erase(entity_id)
	else:
		health_by_entity_id[entity_id] = next_health
	if statuses and statuses.has_method("consume_attack_charge"):
		statuses.consume_attack_charge()

	var result := {
		"entity_id": entity_id,
		"name": entity.get_display_name(),
		"damage": damage,
		"counter_damage": counter_damage,
		"raw_counter_damage": raw_counter_damage,
		"guarded": guarded and raw_counter_damage > counter_damage,
		"health": next_health,
		"max_health": max_health,
		"defeated": defeated
	}
	if event_bus:
		event_bus.combat_resolved.emit(result.duplicate(true))
	return result


func get_entity_health(entity) -> int:
	var entity_id: String = entity.get_entity_id()
	var max_health := _max_health_for_entity(entity)
	return _clamped_entity_health(entity_id, max_health)


func clear_entity(entity_id: String) -> void:
	health_by_entity_id.erase(entity_id)


func get_save_data() -> Dictionary:
	return {"health_by_entity_id": health_by_entity_id.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	health_by_entity_id.clear()
	var loaded_health := _dictionary_field(data.get("health_by_entity_id", {}))
	for entity_id in loaded_health:
		var key := String(entity_id)
		var health_value: Variant = loaded_health[entity_id]
		if not key.is_empty() and _is_number(health_value) and int(health_value) > 0:
			health_by_entity_id[key] = int(health_value)


func _clamped_entity_health(entity_id: String, max_health: int) -> int:
	var safe_max := maxi(1, max_health)
	var stored_value: Variant = health_by_entity_id.get(entity_id, safe_max)
	var stored := int(stored_value) if _is_number(stored_value) else safe_max
	return clampi(stored, 0, safe_max)


func _max_health_for_entity(entity) -> int:
	return _positive_int_field(entity.data, "max_health", DEFAULT_MAX_HEALTH)


func _attack_damage_for_entity(entity) -> int:
	var base_damage := _positive_int_field(entity.data, "damage_taken_per_hit", player_damage)
	var bonus := 0
	if equipment and equipment.has_method("get_player_damage_bonus"):
		bonus += equipment.get_player_damage_bonus()
	if progression and progression.has_method("get_player_damage_bonus"):
		bonus += progression.get_player_damage_bonus()
	if statuses and statuses.has_method("get_player_damage_bonus"):
		bonus += statuses.get_player_damage_bonus()
	return maxi(1, base_damage + bonus)


func _positive_int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	return _positive_int_value(source.get(field_id, fallback), fallback)


func _positive_int_value(value: Variant, fallback: int) -> int:
	if not _is_number(value):
		return maxi(1, fallback)
	return maxi(1, int(value))


func _non_negative_int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	return _non_negative_int_value(source.get(field_id, fallback), fallback)


func _non_negative_int_value(value: Variant, fallback: int) -> int:
	if not _is_number(value):
		return maxi(0, fallback)
	return maxi(0, int(value))


func _guarded_counter_damage(counter_damage: int) -> int:
	if counter_damage <= 0:
		return 0
	var multiplier := GUARD_COUNTER_DAMAGE_MULTIPLIER
	if equipment and equipment.has_method("guarded_counter_multiplier"):
		multiplier = equipment.guarded_counter_multiplier(multiplier)
	if progression and progression.has_method("guarded_counter_multiplier"):
		multiplier = progression.guarded_counter_multiplier(multiplier)
	if statuses and statuses.has_method("guarded_counter_multiplier"):
		multiplier = statuses.guarded_counter_multiplier(multiplier)
	return ceili(float(counter_damage) * multiplier)


func _dictionary_field(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _is_number(value: Variant) -> bool:
	return value is int or value is float
