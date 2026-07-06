class_name ConditionEvaluator
extends RefCounted

var world_state
var quests
var inventory
var readables
var factions
var progression
var time


func setup(
	world_state_manager,
	quest_manager,
	inventory_manager,
	readable_manager,
	faction_manager = null,
	progression_manager = null,
	time_manager = null
) -> void:
	world_state = world_state_manager
	quests = quest_manager
	inventory = inventory_manager
	readables = readable_manager
	factions = faction_manager
	progression = progression_manager
	time = time_manager


func evaluate(condition: Dictionary) -> bool:
	var condition_type := String(condition.get("type", ""))
	var passed := false
	match condition_type:
		"has_flag":
			passed = _has_flag(condition)
		"not_flag":
			passed = _not_flag(condition)
		"has_item":
			passed = _has_item(condition)
		"quest_state":
			passed = _quest_state(condition)
		"quest_stage":
			passed = _quest_stage(condition)
		"read_readable":
			passed = _read_readable(condition)
		"location_discovered":
			passed = _location_discovered(condition)
		"faction_reputation_at_least":
			passed = _faction_reputation_at_least(condition)
		"player_level_at_least":
			passed = _player_level_at_least(condition)
		"time_phase":
			passed = _time_phase(condition)
		"time_hour_between":
			passed = _time_hour_between(condition)
	return passed


func evaluate_all(conditions: Array) -> bool:
	for condition in conditions:
		if not condition is Dictionary or not evaluate(condition):
			return false
	return true


func _has_flag(condition: Dictionary) -> bool:
	var flag_id := String(condition.get("flag_id", ""))
	return not flag_id.is_empty() and world_state and world_state.has_flag(flag_id)


func _not_flag(condition: Dictionary) -> bool:
	var flag_id := String(condition.get("flag_id", ""))
	return not flag_id.is_empty() and world_state and not world_state.has_flag(flag_id)


func _has_item(condition: Dictionary) -> bool:
	var item_id := String(condition.get("item_id", ""))
	var count := _positive_count(condition)
	return not item_id.is_empty() and count > 0 and inventory and inventory.has_item(item_id, count)


func _quest_state(condition: Dictionary) -> bool:
	var quest_id := String(condition.get("quest_id", ""))
	var state := String(condition.get("state", ""))
	return (
		not quest_id.is_empty()
		and not state.is_empty()
		and quests
		and quests.get_quest_state(quest_id) == state
	)


func _quest_stage(condition: Dictionary) -> bool:
	var quest_id := String(condition.get("quest_id", ""))
	var stage := String(condition.get("stage", ""))
	return (
		not quest_id.is_empty()
		and not stage.is_empty()
		and quests
		and quests.quests.get(quest_id, {}).get("stage", "") == stage
	)


func _read_readable(condition: Dictionary) -> bool:
	var readable_id := String(condition.get("readable_id", ""))
	return not readable_id.is_empty() and readables and readables.has_read(readable_id)


func _location_discovered(condition: Dictionary) -> bool:
	var location_id := String(condition.get("location_id", ""))
	return (
		not location_id.is_empty()
		and world_state
		and world_state.discovered_locations.has(location_id)
	)


func _faction_reputation_at_least(condition: Dictionary) -> bool:
	var faction_id := String(condition.get("faction_id", ""))
	var reputation := _int_field(condition, "reputation", 0)
	return (
		not faction_id.is_empty()
		and factions
		and factions.is_reputation_at_least(faction_id, reputation)
	)


func _player_level_at_least(condition: Dictionary) -> bool:
	var required_level := _int_field(condition, "level", 0)
	return required_level > 0 and progression and progression.is_level_at_least(required_level)


func _time_phase(condition: Dictionary) -> bool:
	var phase := String(condition.get("phase", ""))
	return not phase.is_empty() and time and time.is_phase(phase)


func _time_hour_between(condition: Dictionary) -> bool:
	if not time or not _is_number(condition.get("start_hour", null)):
		return false
	if not _is_number(condition.get("end_hour", null)):
		return false
	return time.is_hour_between(int(condition["start_hour"]), int(condition["end_hour"]))


func _int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	var value: Variant = source.get(field_id, fallback)
	if not _is_number(value):
		return fallback
	return int(value)


func _positive_count(source: Dictionary) -> int:
	var value: Variant = source.get("count", 1)
	if not _is_number(value):
		return 0
	return int(value)


func _is_number(value: Variant) -> bool:
	return value is int or value is float
