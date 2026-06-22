class_name StatusEffectManager
extends Node

var event_bus
var content
var active_statuses: Dictionary = {}


func setup(bus, content_database) -> void:
	event_bus = bus
	content = content_database
	_emit_changed()


func apply_status(status_id: String, charges_override: int = 0) -> bool:
	var definition := _status_definition(status_id)
	if definition.is_empty():
		return false
	var charges := (
		charges_override
		if charges_override > 0
		else _positive_int_field(definition, "attack_charges", 0)
	)
	if charges <= 0:
		return false
	var current_charges := get_remaining_charges(status_id)
	active_statuses[status_id] = {"charges": maxi(current_charges, charges)}
	if event_bus:
		event_bus.post_message("Gained %s." % String(definition.get("name", status_id)))
	_emit_changed()
	return true


func consume_attack_charge() -> void:
	var changed := false
	for status_id in active_statuses.keys():
		var charges := get_remaining_charges(String(status_id)) - 1
		if charges > 0:
			active_statuses[status_id] = {"charges": charges}
		else:
			active_statuses.erase(status_id)
		changed = true
	if changed:
		_emit_changed()


func get_player_damage_bonus() -> int:
	var bonus := 0
	for status_id in active_statuses:
		var definition := _status_definition(String(status_id))
		bonus += _non_negative_int_field(definition, "damage_bonus", 0)
	return bonus


func guarded_counter_multiplier(base_multiplier: float) -> float:
	var multiplier := maxf(0.0, base_multiplier)
	for status_id in active_statuses:
		var definition := _status_definition(String(status_id))
		if (
			definition.has("guard_counter_multiplier")
			and _is_number(definition["guard_counter_multiplier"])
		):
			multiplier *= maxf(0.0, float(definition["guard_counter_multiplier"]))
	return multiplier


func get_remaining_charges(status_id: String) -> int:
	var state := _dictionary_field(active_statuses.get(status_id, {}))
	return maxi(0, int(state.get("charges", 0))) if _is_number(state.get("charges", 0)) else 0


func get_summary() -> String:
	if active_statuses.is_empty():
		return "none"
	var parts: Array[String] = []
	for status_id in _sorted_status_ids():
		var definition := _status_definition(status_id)
		var name := String(definition.get("name", status_id))
		parts.append("%s (%d attacks)" % [name, get_remaining_charges(status_id)])
	return ", ".join(parts)


func get_details() -> String:
	if active_statuses.is_empty():
		return "Active effects: none"
	var lines: Array[String] = ["Active effects:"]
	for status_id in _sorted_status_ids():
		var definition := _status_definition(status_id)
		var name := String(definition.get("name", status_id))
		var description := String(definition.get("description", ""))
		var bonus := _non_negative_int_field(definition, "damage_bonus", 0)
		var detail := "%s: %d attacks remaining" % [name, get_remaining_charges(status_id)]
		if bonus > 0:
			detail += ", +%d damage" % bonus
		if not description.is_empty():
			detail += ". %s" % description
		lines.append(detail)
	return "\n".join(lines)


func get_save_data() -> Dictionary:
	var entries: Array[Dictionary] = []
	for status_id in _sorted_status_ids():
		entries.append({"status_id": status_id, "charges": get_remaining_charges(status_id)})
	return {"active": entries}


func load_save_data(data: Dictionary) -> void:
	active_statuses.clear()
	for entry in _array_field(data.get("active", [])):
		var status := _dictionary_field(entry)
		var status_id := String(status.get("status_id", ""))
		var charges := _non_negative_int_field(status, "charges", 0)
		if not _status_definition(status_id).is_empty() and charges > 0:
			active_statuses[status_id] = {"charges": charges}
	_emit_changed()


func _emit_changed() -> void:
	if event_bus and event_bus.has_signal("status_effects_changed"):
		event_bus.status_effects_changed.emit(active_statuses.duplicate(true))


func _status_definition(status_id: String) -> Dictionary:
	if status_id.is_empty() or not content or not content.has_method("get_status_effect"):
		return {}
	return content.get_status_effect(status_id)


func _sorted_status_ids() -> Array[String]:
	var ids: Array[String] = []
	for status_id in active_statuses:
		ids.append(String(status_id))
	ids.sort()
	return ids


func _positive_int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	var value: Variant = source.get(field_id, fallback)
	if not _is_number(value):
		return maxi(0, fallback)
	return maxi(0, int(value))


func _non_negative_int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	var value: Variant = source.get(field_id, fallback)
	if not _is_number(value):
		return maxi(0, fallback)
	return maxi(0, int(value))


func _array_field(value: Variant) -> Array:
	return value if value is Array else []


func _dictionary_field(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


func _is_number(value: Variant) -> bool:
	return value is int or value is float
