class_name WorldStateManager
extends Node

var event_bus
var flags: Dictionary = {}
var discovered_locations: Dictionary = {}


func setup(bus) -> void:
	event_bus = bus


func set_flag(flag_id: String, value: bool = true) -> void:
	if flag_id.is_empty():
		return
	if flags.get(flag_id) == value:
		return
	flags[flag_id] = value
	if event_bus:
		event_bus.world_flag_changed.emit(flag_id, value)


func has_flag(flag_id: String) -> bool:
	var value: Variant = flags.get(flag_id, false)
	return value is bool and value


func discover_location(location_id: String) -> bool:
	if location_id.is_empty():
		return false
	if discovered_locations.has(location_id):
		return false
	discovered_locations[location_id] = true
	if event_bus:
		event_bus.location_discovered.emit(location_id)
	return true


func get_save_data() -> Dictionary:
	return {"flags": flags.duplicate(true), "discovered_locations": discovered_locations.keys()}


func load_save_data(data: Dictionary) -> void:
	flags.clear()
	var loaded_flags := _dictionary_field(data.get("flags", {}))
	for flag_id in loaded_flags:
		var key := _string_key(flag_id)
		var value: Variant = loaded_flags[flag_id]
		if not key.is_empty() and value is bool:
			flags[key] = value
	discovered_locations.clear()
	for location_id in _array_field(data.get("discovered_locations", [])):
		var key := _string_key(location_id)
		if not key.is_empty():
			discovered_locations[key] = true


func _dictionary_field(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []


func _string_key(value: Variant) -> String:
	if value is String or value is StringName:
		return String(value)
	return ""
