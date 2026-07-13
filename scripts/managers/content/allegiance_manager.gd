class_name AllegianceManager
extends Node

const ActorRules = preload("res://scripts/core/actor_rules.gd")

var event_bus
var entities
var combat_allegiances: Dictionary = {}
var alerted_by_allegiance_id: Dictionary = {}


func setup(bus, entity_manager, content = null) -> void:
	event_bus = bus
	entities = entity_manager
	if content and content.has_method("get_combat_allegiances"):
		combat_allegiances = content.get_combat_allegiances()


func alert_actor(actor) -> bool:
	if not actor or not (actor.data is Dictionary):
		return false
	var allegiance_id := _allegiance_id_for_actor(actor)
	if allegiance_id.is_empty() or allegiance_id == "player":
		return false
	var alerted_now := false
	for alerted_id in _linked_allegiance_ids(allegiance_id):
		if alerted_by_allegiance_id.has(alerted_id):
			continue
		alerted_by_allegiance_id[alerted_id] = true
		alerted_now = true
	if alerted_now:
		if event_bus:
			event_bus.post_message("%s has been alerted." % _display_name(allegiance_id))
	for alerted_id in _linked_allegiance_ids(allegiance_id):
		_apply_alert(alerted_id)
	return true


func update(_delta: float = 0.0) -> void:
	for allegiance_id in alerted_by_allegiance_id:
		_apply_alert(String(allegiance_id))


func is_alerted(allegiance_id: String) -> bool:
	return not allegiance_id.is_empty() and bool(alerted_by_allegiance_id.get(allegiance_id, false))


func get_save_data() -> Dictionary:
	return {"alerted_by_allegiance_id": alerted_by_allegiance_id.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	alerted_by_allegiance_id.clear()
	var saved: Variant = data.get("alerted_by_allegiance_id", {})
	if not saved is Dictionary:
		return
	for allegiance_id in saved:
		if bool(saved[allegiance_id]) and not String(allegiance_id).is_empty():
			alerted_by_allegiance_id[String(allegiance_id)] = true


func _apply_alert(allegiance_id: String) -> void:
	if allegiance_id.is_empty() or not entities:
		return
	for actor in entities.entities_by_id.values():
		if not actor or not (actor.data is Dictionary):
			continue
		if _allegiance_id_for_actor(actor) != allegiance_id:
			continue
		_make_hostile(actor)


func _allegiance_id_for_actor(actor) -> String:
	if not actor or not (actor.data is Dictionary):
		return ""
	if ActorRules.is_player_owned_data(actor.data):
		return "player"
	var npc_id := String(actor.data.get("npc_id", ""))
	var assignments: Variant = combat_allegiances.get("npc_assignments", {})
	if assignments is Dictionary:
		var configured := String(assignments.get(npc_id, ""))
		if not configured.is_empty():
			return configured
	return ActorRules.allegiance_id(actor.data)


func _linked_allegiance_ids(allegiance_id: String) -> Array[String]:
	var result: Array[String] = [allegiance_id]
	var groups: Variant = combat_allegiances.get("groups", {})
	if not groups is Dictionary:
		return result
	var group: Variant = groups.get(allegiance_id, {})
	if not group is Dictionary:
		return result
	var allies: Variant = group.get("allies", [])
	if not allies is Array:
		return result
	for value in allies:
		var ally_id := String(value)
		if not ally_id.is_empty() and not result.has(ally_id):
			result.append(ally_id)
	return result


func _make_hostile(actor) -> void:
	if not ActorRules.is_living_actor_data(actor.data) or ActorRules.is_player_owned_data(actor.data):
		return
	actor.data["hostility"] = "hostile"
	actor.data["hostile_to_player"] = true
	actor.data["combat_enabled"] = true
	if String(actor.data.get("brain_id", "")) == "civilian_schedule":
		actor.data["schedule_brain_id"] = "civilian_schedule"
		actor.data["brain_id"] = "hostile_basic"
		actor.data["schedule_reaction"] = "defending_allegiance"
	elif String(actor.data.get("brain_id", "")).is_empty():
		actor.data["brain_id"] = "hostile_basic"
	actor.data["_brain_mode"] = "engaged"
	actor.data["behavior_state"] = "chasing"


func _display_name(allegiance_id: String) -> String:
	return allegiance_id.trim_prefix("faction:").replace("_", " ").capitalize()
