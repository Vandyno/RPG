class_name ProgressionManager
extends Node

const MIN_LEVEL := 1
const MAX_LEVEL := 50
const BASE_XP_TO_LEVEL := 20

var event_bus: EventBus
var level := MIN_LEVEL
var experience := 0
var skill_points := 0


func setup(bus: EventBus) -> void:
	event_bus = bus
	_emit_changed()


func add_experience(amount: int) -> bool:
	if amount <= 0 or level >= MAX_LEVEL:
		return false
	experience += amount
	while level < MAX_LEVEL and experience >= experience_to_next_level():
		experience -= experience_to_next_level()
		level += 1
		skill_points += 1
	if level >= MAX_LEVEL:
		experience = 0
	_emit_changed()
	return true


func experience_to_next_level() -> int:
	return level * BASE_XP_TO_LEVEL


func get_player_damage_bonus() -> int:
	return maxi(0, level - MIN_LEVEL)


func guarded_counter_multiplier(base_multiplier: float) -> float:
	return maxf(0.0, base_multiplier)


func spend_point(_stat_id: String) -> bool:
	return false


func get_stat_rank(_stat_id: String) -> int:
	return 0


func get_stat_label(stat_id: String) -> String:
	return stat_id.capitalize()


func get_trainable_stat_ids() -> Array[String]:
	return []


func train_stat(stat_id: String) -> Dictionary:
	var stat_label := get_stat_label(stat_id)
	if not spend_point(stat_id):
		return {"ok": false, "message": "Could not train %s." % stat_label}
	return {"ok": true, "message": "Trained %s." % stat_label}


func is_level_at_least(required_level: int) -> bool:
	return required_level > 0 and level >= required_level


func get_summary() -> String:
	return (
		"Level %d  XP %d/%d  Points %d"
		% [
			level,
			experience,
			experience_to_next_level(),
			skill_points
		]
	)


func get_details() -> String:
	var lines: Array[String] = []
	lines.append("Level: %d" % level)
	lines.append("XP: %d/%d" % [experience, experience_to_next_level()])
	lines.append("Unspent points: %d" % skill_points)
	lines.append("Damage bonus: +%d" % get_player_damage_bonus())
	return "\n".join(lines)


func get_save_data() -> Dictionary:
	return {
		"level": level,
		"experience": experience,
		"skill_points": skill_points
	}


func load_save_data(data: Dictionary) -> void:
	level = clampi(_int_field(data, "level", MIN_LEVEL), MIN_LEVEL, MAX_LEVEL)
	var next_level_xp := experience_to_next_level()
	experience = clampi(_int_field(data, "experience", 0), 0, maxi(0, next_level_xp - 1))
	if level >= MAX_LEVEL:
		experience = 0
	skill_points = maxi(0, _int_field(data, "skill_points", 0))
	_emit_changed()


func _emit_changed() -> void:
	if event_bus:
		event_bus.progression_changed.emit(
			level, experience, experience_to_next_level(), skill_points
		)


func _int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	var value: Variant = source.get(field_id, fallback)
	if not _is_number(value):
		return fallback
	return int(value)


func _is_number(value: Variant) -> bool:
	return value is int or value is float
