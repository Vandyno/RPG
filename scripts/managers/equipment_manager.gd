class_name EquipmentManager
extends Node

const EQUIPMENT_SLOTS := ["weapon", "offhand", "body"]

var event_bus
var content
var inventory
var equipped_by_slot: Dictionary = {}


func setup(bus, content_database = null, inventory_manager = null) -> void:
	event_bus = bus
	content = content_database
	inventory = inventory_manager
	if event_bus:
		event_bus.item_count_changed.connect(_on_item_count_changed)


func equip_item(item_id: String) -> bool:
	var item := _item(item_id)
	var slot := String(item.get("equipment_slot", ""))
	if item.is_empty() or not EQUIPMENT_SLOTS.has(slot) or not _has_item(item_id):
		return false
	if String(equipped_by_slot.get(slot, "")) == item_id:
		return false
	equipped_by_slot[slot] = item_id
	_emit_changed()
	return true


func unequip_slot(slot: String) -> bool:
	if not EQUIPMENT_SLOTS.has(slot) or not equipped_by_slot.has(slot):
		return false
	equipped_by_slot.erase(slot)
	_emit_changed()
	return true


func get_equipped_item(slot: String) -> String:
	return String(equipped_by_slot.get(slot, ""))


func get_player_damage_bonus() -> int:
	var bonus := 0
	for item_id in equipped_by_slot.values():
		var item := _item(String(item_id))
		bonus += _non_negative_int_value(item.get("damage_bonus", 0), 0)
	return bonus


func guarded_counter_multiplier(base_multiplier: float) -> float:
	var multiplier := maxf(0.0, base_multiplier)
	for item_id in equipped_by_slot.values():
		var item := _item(String(item_id))
		var item_multiplier := _positive_float_value(
			item.get("guard_counter_multiplier", multiplier), multiplier
		)
		multiplier = minf(multiplier, item_multiplier)
	return multiplier


func get_summary() -> String:
	var lines: Array[String] = []
	for slot in EQUIPMENT_SLOTS:
		var item_id := get_equipped_item(slot)
		if item_id.is_empty():
			lines.append("%s: empty" % _slot_label(slot))
			continue
		var item := _item(item_id)
		lines.append("%s: %s" % [_slot_label(slot), String(item.get("name", item_id))])
	return "\n".join(lines)


func get_save_data() -> Dictionary:
	var equipped: Dictionary = {}
	for slot in EQUIPMENT_SLOTS:
		var item_id := get_equipped_item(slot)
		if not item_id.is_empty() and _has_item(item_id) and _item_slot(item_id) == slot:
			equipped[slot] = item_id
	return {"equipped": equipped}


func load_save_data(data: Dictionary) -> void:
	equipped_by_slot.clear()
	var equipped := _dictionary_field(data.get("equipped", {}))
	for slot_id in equipped:
		var slot := String(slot_id)
		var item_id := String(equipped[slot_id])
		if EQUIPMENT_SLOTS.has(slot) and _has_item(item_id) and _item_slot(item_id) == slot:
			equipped_by_slot[slot] = item_id
	_emit_changed()


func _on_item_count_changed(item_id: String, count: int) -> void:
	if count > 0:
		return
	var removed := false
	for slot in EQUIPMENT_SLOTS:
		if get_equipped_item(slot) == item_id:
			equipped_by_slot.erase(slot)
			removed = true
	if removed:
		_emit_changed()


func _emit_changed() -> void:
	if event_bus:
		event_bus.equipment_changed.emit(equipped_by_slot.duplicate(true))


func _item(item_id: String) -> Dictionary:
	if item_id.is_empty() or not content:
		return {}
	return content.get_item(item_id)


func _item_slot(item_id: String) -> String:
	return String(_item(item_id).get("equipment_slot", ""))


func _has_item(item_id: String) -> bool:
	return not inventory or inventory.has_item(item_id)


func _slot_label(slot: String) -> String:
	match slot:
		"weapon":
			return "Weapon"
		"offhand":
			return "Offhand"
		"body":
			return "Body"
		_:
			return slot.capitalize()


func _dictionary_field(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _non_negative_int_value(value: Variant, fallback: int) -> int:
	if not _is_number(value):
		return maxi(0, fallback)
	return maxi(0, int(value))


func _positive_float_value(value: Variant, fallback: float) -> float:
	if not _is_number(value):
		return maxf(0.001, fallback)
	return maxf(0.001, float(value))


func _is_number(value: Variant) -> bool:
	return value is int or value is float
