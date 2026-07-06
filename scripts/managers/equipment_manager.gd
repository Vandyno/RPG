class_name EquipmentManager
extends Node

const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")
const EQUIPMENT_SLOTS := EquipmentSlots.SLOTS
const LEGACY_SUMMARY_SLOTS := ["weapon", "offhand", "body"]

var event_bus: EventBus
var content: ContentDatabase
var inventory: InventoryManager
var equipped_by_slot: Dictionary = {}
var last_mainhand_weapon_id := ""


func setup(
	bus: EventBus, content_database: ContentDatabase = null, inventory_manager: InventoryManager = null
) -> void:
	event_bus = bus
	content = content_database
	inventory = inventory_manager
	if event_bus:
		event_bus.item_count_changed.connect(_on_item_count_changed)


func equip_item(item_id: String) -> bool:
	var item := _item(item_id)
	var slot := EquipmentSlots.first_slot_for_item_slot(
		String(item.get("equipment_slot", "")), equipped_by_slot
	)
	return equip_item_to_slot(item_id, slot)


func equip_item_to_slot(item_id: String, slot_id: String) -> bool:
	var item := _item(item_id)
	var slot := EquipmentSlots.normalize(slot_id)
	var item_slot := String(item.get("equipment_slot", ""))
	if (
		item.is_empty()
		or not EquipmentSlots.is_supported(slot)
		or not EquipmentSlots.accepts(slot, item_slot)
		or not _has_item(item_id)
	):
		return false
	var current_item_id := String(equipped_by_slot.get(slot, ""))
	if current_item_id == item_id:
		return false
	if slot == "right_hand":
		if current_item_id.is_empty() and last_mainhand_weapon_id == item_id:
			last_mainhand_weapon_id = ""
		else:
			_remember_mainhand_weapon(current_item_id)
	equipped_by_slot[slot] = item_id
	_emit_changed()
	return true


func equip_last_mainhand_weapon() -> bool:
	var current_item_id := get_equipped_item("right_hand")
	var needs_fallback := not _is_valid_mainhand_weapon(last_mainhand_weapon_id)
	if needs_fallback or last_mainhand_weapon_id == current_item_id:
		last_mainhand_weapon_id = _fallback_mainhand_weapon_id()
	if last_mainhand_weapon_id.is_empty():
		return false
	return equip_item_to_slot(last_mainhand_weapon_id, "right_hand")


func unequip_slot(slot: String) -> bool:
	var normalized := EquipmentSlots.normalize(slot)
	if not EQUIPMENT_SLOTS.has(normalized) or not equipped_by_slot.has(normalized):
		return false
	if normalized == "right_hand":
		_remember_mainhand_weapon(String(equipped_by_slot.get(normalized, "")))
	equipped_by_slot.erase(normalized)
	_emit_changed()
	return true


func get_equipped_item(slot: String) -> String:
	return String(equipped_by_slot.get(EquipmentSlots.normalize(slot), ""))


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
	for slot in LEGACY_SUMMARY_SLOTS:
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
		if (
			not item_id.is_empty()
			and _has_item(item_id)
			and EquipmentSlots.accepts(slot, _item_slot(item_id))
		):
			equipped[EquipmentSlots.normalize(slot)] = item_id
	var data := {"equipped": equipped}
	if (
		_is_valid_mainhand_weapon(last_mainhand_weapon_id)
		and last_mainhand_weapon_id != get_equipped_item("right_hand")
	):
		data["last_mainhand_weapon"] = last_mainhand_weapon_id
	return data


func load_save_data(data: Dictionary) -> void:
	equipped_by_slot.clear()
	var equipped := _dictionary_field(data.get("equipped", {}))
	for slot_id in equipped:
		var slot := EquipmentSlots.normalize(String(slot_id))
		var item_id := String(equipped[slot_id])
		if (
			EQUIPMENT_SLOTS.has(slot)
			and _has_item(item_id)
			and EquipmentSlots.accepts(slot, _item_slot(item_id))
		):
			equipped_by_slot[slot] = item_id
	var last_weapon := String(data.get("last_mainhand_weapon", ""))
	last_mainhand_weapon_id = last_weapon if _is_valid_mainhand_weapon(last_weapon) else ""
	if last_mainhand_weapon_id == get_equipped_item("right_hand"):
		last_mainhand_weapon_id = ""
	_emit_changed()


func _on_item_count_changed(item_id: String, count: int) -> void:
	if count > 0:
		return
	var removed := false
	for slot in EQUIPMENT_SLOTS:
		if get_equipped_item(slot) == item_id:
			if slot == "right_hand":
				last_mainhand_weapon_id = ""
			equipped_by_slot.erase(slot)
			removed = true
	var last_cleared := false
	if last_mainhand_weapon_id == item_id:
		last_mainhand_weapon_id = ""
		last_cleared = true
	if removed or last_cleared:
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


func _remember_mainhand_weapon(item_id: String) -> void:
	if _is_valid_mainhand_weapon(item_id):
		last_mainhand_weapon_id = item_id


func _is_valid_mainhand_weapon(item_id: String) -> bool:
	return (
		not item_id.is_empty()
		and _has_item(item_id)
		and EquipmentSlots.accepts("right_hand", _item_slot(item_id))
	)


func _fallback_mainhand_weapon_id() -> String:
	if not inventory:
		return ""
	var current_item_id := get_equipped_item("right_hand")
	var item_ids: Array = inventory.items.keys()
	item_ids.sort()
	for item_id_value in item_ids:
		var item_id := String(item_id_value)
		if item_id != current_item_id and _is_valid_mainhand_weapon(item_id):
			return item_id
	return ""


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
	return EquipmentSlots.label(slot)


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
