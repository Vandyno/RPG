class_name SpellManager
extends Node

const SpellSlots = preload("res://scripts/core/spell_slots.gd")
const SLOTS := SpellSlots.SLOTS
const PLAYER_OWNER_ID := "char_player"

var event_bus: EventBus
var content: ContentDatabase
var assigned_by_slot: Dictionary = {}
var assigned_by_owner_id: Dictionary = {}


func setup(bus: EventBus, content_database: ContentDatabase = null) -> void:
	event_bus = bus
	content = content_database
	_sync_player_alias()


func assign_spell_to_slot(spell_id: String, slot_id: String) -> bool:
	return assign_spell_to_owner_slot(PLAYER_OWNER_ID, spell_id, slot_id)


func assign_spell_to_owner_slot(owner_id: String, spell_id: String, slot_id: String) -> bool:
	var slot := _normalize_slot(slot_id)
	if slot.is_empty() or _spell(spell_id).is_empty():
		return false
	var assigned := _assigned_for_owner(owner_id)
	if String(assigned.get(slot, "")) == spell_id:
		return true
	assigned[slot] = spell_id
	_emit_changed(owner_id)
	return true


func clear_slot(slot_id: String) -> bool:
	return clear_owner_slot(PLAYER_OWNER_ID, slot_id)


func clear_owner_slot(owner_id: String, slot_id: String) -> bool:
	var slot := _normalize_slot(slot_id)
	var assigned := _assigned_for_owner(owner_id)
	if slot.is_empty() or not assigned.has(slot):
		return false
	assigned.erase(slot)
	_emit_changed(owner_id)
	return true


func get_assigned_spell(slot_id: String) -> String:
	return get_assigned_spell_for_owner(PLAYER_OWNER_ID, slot_id)


func get_assigned_spell_for_owner(owner_id: String, slot_id: String) -> String:
	return String(_assigned_for_owner_or_empty(owner_id).get(_normalize_slot(slot_id), ""))


func get_save_data() -> Dictionary:
	var assigned := _save_slots_for_owner(PLAYER_OWNER_ID)
	var owner_loadouts: Array[Dictionary] = []
	for owner_id in assigned_by_owner_id:
		var normalized_owner := String(owner_id)
		if normalized_owner == PLAYER_OWNER_ID:
			continue
		var owner_assigned := _save_slots_for_owner(normalized_owner)
		if owner_assigned.is_empty():
			continue
		owner_loadouts.append({"owner_id": normalized_owner, "assigned": owner_assigned})
	var data := {"assigned": assigned}
	if not owner_loadouts.is_empty():
		data["owner_loadouts"] = owner_loadouts
	return data


func load_save_data(data: Dictionary) -> void:
	assigned_by_owner_id.clear()
	var assigned: Variant = data.get("assigned", {})
	if assigned is Dictionary:
		_load_owner_assigned(PLAYER_OWNER_ID, assigned)
	for entry in _array_field(data.get("owner_loadouts", [])):
		if not entry is Dictionary:
			continue
		var owner_id := _owner_id(String(entry.get("owner_id", "")))
		if owner_id == PLAYER_OWNER_ID:
			continue
		_load_owner_assigned(owner_id, entry.get("assigned", {}))
	_sync_player_alias()
	_emit_changed(PLAYER_OWNER_ID)


func _save_slots_for_owner(owner_id: String) -> Dictionary:
	var assigned := {}
	for slot in SLOTS:
		var spell_id := get_assigned_spell_for_owner(owner_id, slot)
		if not spell_id.is_empty() and not _spell(spell_id).is_empty():
			assigned[slot] = spell_id
	return assigned


func _load_owner_assigned(owner_id: String, assigned: Variant) -> void:
	if not assigned is Dictionary:
		return
	var target := _assigned_for_owner(owner_id)
	for slot_id in assigned:
		var slot := _normalize_slot(String(slot_id))
		var spell_id := String(assigned[slot_id])
		if not slot.is_empty() and not _spell(spell_id).is_empty():
			target[slot] = spell_id


func _spell(spell_id: String) -> Dictionary:
	if spell_id.is_empty() or not content or not content.has_method("get_spell"):
		return {}
	return content.get_spell(spell_id)


func _normalize_slot(slot_id: String) -> String:
	return slot_id if SpellSlots.is_supported(slot_id) else ""


func _assigned_for_owner(owner_id: String) -> Dictionary:
	var normalized_owner := _owner_id(owner_id)
	if not assigned_by_owner_id.has(normalized_owner):
		assigned_by_owner_id[normalized_owner] = {}
	if not assigned_by_owner_id[normalized_owner] is Dictionary:
		assigned_by_owner_id[normalized_owner] = {}
	if normalized_owner == PLAYER_OWNER_ID:
		assigned_by_slot = assigned_by_owner_id[normalized_owner]
	return assigned_by_owner_id[normalized_owner]


func _assigned_for_owner_or_empty(owner_id: String) -> Dictionary:
	var normalized_owner := _owner_id(owner_id)
	if normalized_owner == PLAYER_OWNER_ID and assigned_by_owner_id.has(PLAYER_OWNER_ID):
		return assigned_by_slot
	var assigned: Variant = assigned_by_owner_id.get(normalized_owner, {})
	return assigned if assigned is Dictionary else {}


func _sync_player_alias() -> void:
	assigned_by_slot = _assigned_for_owner(PLAYER_OWNER_ID)


func _owner_id(owner_id: String) -> String:
	return PLAYER_OWNER_ID if owner_id.is_empty() else owner_id


func _emit_changed(owner_id: String = PLAYER_OWNER_ID) -> void:
	if _owner_id(owner_id) == PLAYER_OWNER_ID:
		_sync_player_alias()
	if event_bus and event_bus.has_signal("spell_slots_changed"):
		event_bus.spell_slots_changed.emit(assigned_by_slot.duplicate(true))


func _array_field(value: Variant) -> Array:
	return value if value is Array else []
