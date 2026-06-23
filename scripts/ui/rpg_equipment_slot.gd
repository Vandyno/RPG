class_name RpgEquipmentSlot
extends Button

signal item_dropped(slot_id: String, item_id: String)

const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")

var slot_id := ""


func setup_slot(next_slot_id: String) -> void:
	slot_id = EquipmentSlots.normalize(next_slot_id)
	set_meta("slot_id", slot_id)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if String(data.get("type", "")) != "inventory_item":
		return false
	var item_id := String(data.get("item_id", ""))
	var item_slot := String(data.get("equipment_slot", ""))
	return not item_id.is_empty() and EquipmentSlots.accepts(slot_id, item_slot)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return
	item_dropped.emit(slot_id, String(data.get("item_id", "")))
