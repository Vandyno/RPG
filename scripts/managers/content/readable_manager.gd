class_name ReadableManager
extends Node

var event_bus
var content
var read: Dictionary = {}
var discovered: Dictionary = {}
var effect_handler: Callable


func setup(bus, content_database, effects: Callable) -> void:
	event_bus = bus
	content = content_database
	effect_handler = effects


func read_readable(readable_id: String) -> Dictionary:
	var definition: Dictionary = content.get_readable(readable_id)
	if definition.is_empty():
		return {}
	var was_read := has_read(readable_id)
	discovered[readable_id] = true
	read[readable_id] = true
	if not was_read:
		for effect in definition.get("effects_on_read", []):
			if effect is Dictionary and effect_handler.is_valid():
				effect_handler.call(effect)
	if event_bus:
		event_bus.readable_read.emit(readable_id)
	return definition


func has_read(readable_id: String) -> bool:
	return bool(read.get(readable_id, false))


func get_save_data() -> Dictionary:
	return {"read": read.keys(), "discovered": discovered.keys()}


func load_save_data(data: Dictionary) -> void:
	read.clear()
	for readable_id in _array_field(data.get("read", [])):
		var key := String(readable_id)
		if _is_known_readable(key):
			read[key] = true
	discovered.clear()
	for readable_id in _array_field(data.get("discovered", [])):
		var key := String(readable_id)
		if _is_known_readable(key):
			discovered[key] = true


func _is_known_readable(readable_id: String) -> bool:
	return (
		not readable_id.is_empty() and content and not content.get_readable(readable_id).is_empty()
	)


func _array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []
