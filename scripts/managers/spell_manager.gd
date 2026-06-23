class_name SpellManager
extends Node

const SLOTS := ["ability_1", "ability_2", "ability_3"]

var event_bus
var content
var assigned_by_slot: Dictionary = {}


func setup(bus, content_database = null) -> void:
	event_bus = bus
	content = content_database


func assign_spell_to_slot(spell_id: String, slot_id: String) -> bool:
	var slot := _normalize_slot(slot_id)
	if slot.is_empty() or _spell(spell_id).is_empty():
		return false
	if String(assigned_by_slot.get(slot, "")) == spell_id:
		return true
	assigned_by_slot[slot] = spell_id
	_emit_changed()
	return true


func clear_slot(slot_id: String) -> bool:
	var slot := _normalize_slot(slot_id)
	if slot.is_empty() or not assigned_by_slot.has(slot):
		return false
	assigned_by_slot.erase(slot)
	_emit_changed()
	return true


func get_assigned_spell(slot_id: String) -> String:
	return String(assigned_by_slot.get(_normalize_slot(slot_id), ""))


func get_save_data() -> Dictionary:
	var assigned := {}
	for slot in SLOTS:
		var spell_id := get_assigned_spell(slot)
		if not spell_id.is_empty() and not _spell(spell_id).is_empty():
			assigned[slot] = spell_id
	return {"assigned": assigned}


func load_save_data(data: Dictionary) -> void:
	assigned_by_slot.clear()
	var assigned: Variant = data.get("assigned", {})
	if not assigned is Dictionary:
		_emit_changed()
		return
	for slot_id in assigned:
		var slot := _normalize_slot(String(slot_id))
		var spell_id := String(assigned[slot_id])
		if not slot.is_empty() and not _spell(spell_id).is_empty():
			assigned_by_slot[slot] = spell_id
	_emit_changed()


func _spell(spell_id: String) -> Dictionary:
	if spell_id.is_empty() or not content or not content.has_method("get_spell"):
		return {}
	return content.get_spell(spell_id)


func _normalize_slot(slot_id: String) -> String:
	return slot_id if SLOTS.has(slot_id) else ""


func _emit_changed() -> void:
	if event_bus and event_bus.has_signal("spell_slots_changed"):
		event_bus.spell_slots_changed.emit(assigned_by_slot.duplicate(true))
