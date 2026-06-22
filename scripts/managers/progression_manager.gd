class_name ProgressionManager
extends Node

const MIN_LEVEL := 1
const MAX_LEVEL := 50
const BASE_XP_TO_LEVEL := 20
const MIN_GUARD_MULTIPLIER := 0.2
const STAT_IDS := ["might", "grit"]
const STAT_LABELS := {"might": "Might", "grit": "Grit"}
const STAT_DESCRIPTIONS := {"might": "+1 attack damage", "grit": "-5% guarded counter damage"}

var event_bus
var level := MIN_LEVEL
var experience := 0
var skill_points := 0
var stats: Dictionary = {"might": 0, "grit": 0}


func setup(bus) -> void:
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
	return maxi(0, level - MIN_LEVEL) + get_stat_rank("might")


func guarded_counter_multiplier(base_multiplier: float) -> float:
	var grit_bonus := float(get_stat_rank("grit")) * 0.05
	return maxf(MIN_GUARD_MULTIPLIER, maxf(0.0, base_multiplier) - grit_bonus)


func spend_point(stat_id: String) -> bool:
	if skill_points <= 0 or not STAT_IDS.has(stat_id):
		return false
	stats[stat_id] = get_stat_rank(stat_id) + 1
	skill_points -= 1
	_emit_changed()
	return true


func get_stat_rank(stat_id: String) -> int:
	return maxi(0, int(stats.get(stat_id, 0))) if _is_number(stats.get(stat_id, 0)) else 0


func get_stat_label(stat_id: String) -> String:
	return String(STAT_LABELS.get(stat_id, stat_id.capitalize()))


func get_trainable_stat_ids() -> Array[String]:
	var result: Array[String] = []
	for stat_id in STAT_IDS:
		result.append(String(stat_id))
	return result


func is_level_at_least(required_level: int) -> bool:
	return required_level > 0 and level >= required_level


func get_summary() -> String:
	return (
		"Level %d  XP %d/%d  Points %d  Might %d  Grit %d"
		% [
			level,
			experience,
			experience_to_next_level(),
			skill_points,
			get_stat_rank("might"),
			get_stat_rank("grit")
		]
	)


func get_details() -> String:
	var lines: Array[String] = []
	lines.append("Level: %d" % level)
	lines.append("XP: %d/%d" % [experience, experience_to_next_level()])
	lines.append("Unspent points: %d" % skill_points)
	lines.append("Might %d: %s" % [get_stat_rank("might"), STAT_DESCRIPTIONS["might"]])
	lines.append("Grit %d: %s" % [get_stat_rank("grit"), STAT_DESCRIPTIONS["grit"]])
	lines.append("Damage bonus: +%d" % get_player_damage_bonus())
	lines.append("Guard multiplier: %.0f%%" % (guarded_counter_multiplier(0.5) * 100.0))
	return "\n".join(lines)


func get_save_data() -> Dictionary:
	return {
		"level": level,
		"experience": experience,
		"skill_points": skill_points,
		"stats": _sanitized_stats(stats)
	}


func load_save_data(data: Dictionary) -> void:
	level = clampi(_int_field(data, "level", MIN_LEVEL), MIN_LEVEL, MAX_LEVEL)
	var next_level_xp := experience_to_next_level()
	experience = clampi(_int_field(data, "experience", 0), 0, maxi(0, next_level_xp - 1))
	if level >= MAX_LEVEL:
		experience = 0
	skill_points = maxi(0, _int_field(data, "skill_points", 0))
	stats = _sanitized_stats(data.get("stats", {}))
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


func _sanitized_stats(value: Variant) -> Dictionary:
	var source: Dictionary = value if value is Dictionary else {}
	var result: Dictionary = {}
	for stat_id in STAT_IDS:
		var rank_value: Variant = source.get(stat_id, 0)
		result[stat_id] = maxi(0, int(rank_value)) if _is_number(rank_value) else 0
	return result


func _is_number(value: Variant) -> bool:
	return value is int or value is float
