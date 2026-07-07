class_name FactionManager
extends Node

const MIN_REPUTATION := -100
const MAX_REPUTATION := 100

var event_bus: EventBus
var content: ContentDatabase
var reputation_by_faction_id: Dictionary = {}


func setup(bus: EventBus, content_database: ContentDatabase = null) -> void:
	event_bus = bus
	content = content_database


func change_reputation(faction_id: String, amount: int) -> bool:
	if faction_id.is_empty() or amount == 0 or not _is_known_faction(faction_id):
		return false
	var current := get_reputation(faction_id)
	var next_reputation := clampi(current + amount, MIN_REPUTATION, MAX_REPUTATION)
	if next_reputation == current:
		return false
	reputation_by_faction_id[faction_id] = next_reputation
	if event_bus:
		event_bus.faction_reputation_changed.emit(faction_id, next_reputation)
	return true


func get_reputation(faction_id: String) -> int:
	var faction := _faction(faction_id)
	var fallback := _int_value(faction.get("starting_reputation", 0), 0)
	var stored: Variant = reputation_by_faction_id.get(faction_id, fallback)
	return clampi(_int_value(stored, fallback), MIN_REPUTATION, MAX_REPUTATION)


func is_reputation_at_least(faction_id: String, threshold: int) -> bool:
	return _is_known_faction(faction_id) and get_reputation(faction_id) >= threshold


func get_summary() -> String:
	var ids := _known_faction_ids()
	if ids.is_empty():
		return "none"
	var lines: Array[String] = []
	for faction_id in ids:
		var faction := _faction(faction_id)
		lines.append(
			"%s %+d" % [String(faction.get("name", faction_id)), get_reputation(faction_id)]
		)
	return "\n".join(lines)


func get_save_data() -> Dictionary:
	var reputation: Dictionary = {}
	for faction_id in reputation_by_faction_id:
		var key := String(faction_id)
		if key.is_empty() or not _is_known_faction(key):
			continue
		var value := get_reputation(key)
		if value != _starting_reputation(key):
			reputation[key] = value
	return {"reputation": reputation}


func load_save_data(data: Dictionary) -> void:
	reputation_by_faction_id.clear()
	var reputation := _dictionary_field(data.get("reputation", {}))
	for faction_id in reputation:
		var key := String(faction_id)
		var value: Variant = reputation[faction_id]
		if key.is_empty() or not _is_known_faction(key) or not _is_number(value):
			continue
		var reputation_value := clampi(int(value), MIN_REPUTATION, MAX_REPUTATION)
		if reputation_value != _starting_reputation(key):
			reputation_by_faction_id[key] = reputation_value


func _known_faction_ids() -> Array[String]:
	var ids: Array[String] = []
	if not content:
		for faction_id in reputation_by_faction_id:
			ids.append(String(faction_id))
	else:
		for faction_id in content.factions:
			ids.append(String(faction_id))
	ids.sort()
	return ids


func _starting_reputation(faction_id: String) -> int:
	return clampi(
		_int_value(_faction(faction_id).get("starting_reputation", 0), 0),
		MIN_REPUTATION,
		MAX_REPUTATION
	)


func _faction(faction_id: String) -> Dictionary:
	if faction_id.is_empty() or not content:
		return {}
	return content.get_faction(faction_id)


func _is_known_faction(faction_id: String) -> bool:
	return not content or not _faction(faction_id).is_empty()


func _dictionary_field(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _int_value(value: Variant, fallback: int) -> int:
	if not _is_number(value):
		return fallback
	return int(value)


func _is_number(value: Variant) -> bool:
	return value is int or value is float
