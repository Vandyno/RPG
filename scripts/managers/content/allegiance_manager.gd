class_name AllegianceManager
extends Node

const ActorRules = preload("res://scripts/core/actor_rules.gd")

var event_bus
var entities
var alerted_by_allegiance_id: Dictionary = {}


func setup(bus, entity_manager) -> void:
	event_bus = bus
	entities = entity_manager


func alert_actor(actor) -> bool:
	if not actor or not (actor.data is Dictionary):
		return false
	var allegiance_id := ActorRules.allegiance_id(actor.data)
	if allegiance_id.is_empty() or allegiance_id == "player":
		return false
	if not alerted_by_allegiance_id.has(allegiance_id):
		alerted_by_allegiance_id[allegiance_id] = true
		if event_bus:
			event_bus.post_message("%s has been alerted." % _display_name(allegiance_id))
	_apply_alert(allegiance_id)
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
		if ActorRules.allegiance_id(actor.data) != allegiance_id:
			continue
		_make_hostile(actor)


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
