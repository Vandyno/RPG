class_name CompanionManager
extends Node

const ActorRules = preload("res://scripts/core/actor_rules.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")

const ALLEGIANCE_COMPANION := "companion"
const ALLEGIANCE_THRALL := "thrall"
const COMMAND_FOLLOW := "follow"
const COMMAND_HOLD := "hold"
const FOLLOW_DISTANCE := 30.0
const CATCH_UP_DISTANCE := 224.0
const FOLLOW_SPEED := 96.0
const ASSIST_RANGE := 144.0
const ASSIST_ATTACK_RANGE := 28.0
const ASSIST_DAMAGE := 3
const ASSIST_INTERVAL := 0.75

var event_bus
var entities
var chunks
var combat
var player
var companions_by_entity_id: Dictionary = {}


func setup(bus, entity_manager, chunk_manager, combat_manager) -> void:
	event_bus = bus
	entities = entity_manager
	chunks = chunk_manager
	combat = combat_manager


func set_player(player_controller) -> void:
	player = player_controller


func resurrect_as_thrall(entity_id: String) -> Dictionary:
	if entity_id.is_empty() or not entities:
		return {"ok": false, "message": "No body is available."}
	var actor = entities.get_entity(entity_id)
	if not actor or not ActorRules.is_dead_actor_data(actor.data):
		return {"ok": false, "message": "That body cannot be raised."}
	var original := _restore_snapshot(actor.data)
	entities.set_actor_alive(entity_id)
	actor = entities.get_entity(entity_id)
	if not actor:
		return {"ok": false, "message": "The body is out of reach."}
	_apply_allegiance(actor, ALLEGIANCE_THRALL, original)
	return {"ok": true, "message": "%s rises as your thrall." % actor.get_display_name()}


func make_companion(entity_id: String) -> Dictionary:
	if entity_id.is_empty() or not entities:
		return {"ok": false, "message": "No companion is available."}
	var actor = entities.get_entity(entity_id)
	if not actor or not ActorRules.is_living_actor_data(actor.data):
		return {"ok": false, "message": "They cannot travel with you."}
	_apply_allegiance(actor, ALLEGIANCE_COMPANION, _restore_snapshot(actor.data))
	return {"ok": true, "message": "%s joins you." % actor.get_display_name()}


func is_player_owned(entity) -> bool:
	if not entity or not (entity.data is Dictionary):
		return false
	var allegiance := String(entity.data.get("allegiance", ""))
	return (
		[ALLEGIANCE_COMPANION, ALLEGIANCE_THRALL].has(allegiance)
		and String(entity.data.get("allegiance_owner_id", "")) == "player"
	)


func command(entity_id: String, command_id: String) -> Dictionary:
	var actor = entities.get_entity(entity_id) if entities else null
	if not is_player_owned(actor):
		return {"ok": false, "message": "They do not answer to you."}
	if not [COMMAND_FOLLOW, COMMAND_HOLD].has(command_id):
		return {"ok": false, "message": "Unknown companion command."}
	actor.data["companion_command"] = command_id
	_persist(actor)
	return {
		"ok": true,
		"message": "%s: %s." % [actor.get_display_name(), "Following" if command_id == COMMAND_FOLLOW else "Holding position"]
	}


func dismiss(entity_id: String) -> Dictionary:
	var actor = entities.get_entity(entity_id) if entities else null
	if not is_player_owned(actor):
		return {"ok": false, "message": "They do not answer to you."}
	if String(actor.data.get("allegiance", "")) == ALLEGIANCE_THRALL:
		return {"ok": false, "message": "A thrall remains bound until released by magic."}
	var restore: Dictionary = _restore_snapshot(actor.data)
	for key in ["allegiance", "allegiance_owner_id", "companion_command", "companion_restore"]:
		actor.data.erase(key)
	for key in restore:
		actor.data[key] = restore[key]
	companions_by_entity_id.erase(entity_id)
	_persist(actor)
	return {"ok": true, "message": "%s leaves your company." % actor.get_display_name()}


func update(delta: float) -> void:
	if delta <= 0.0 or not player or not entities:
		return
	_sync_known_companions()
	for entity_id in companions_by_entity_id.keys():
		var actor = entities.get_entity(String(entity_id))
		if actor and is_player_owned(actor) and ActorRules.is_living_actor_data(actor.data):
			_update_companion(actor, delta)


func get_save_data() -> Dictionary:
	return {"companions_by_entity_id": companions_by_entity_id.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	companions_by_entity_id.clear()
	var loaded: Variant = data.get("companions_by_entity_id", {})
	if not loaded is Dictionary:
		return
	for entity_id in loaded:
		if loaded[entity_id] is Dictionary:
			companions_by_entity_id[String(entity_id)] = loaded[entity_id].duplicate(true)


func _apply_allegiance(actor, allegiance: String, restore: Dictionary) -> void:
	actor.data["allegiance"] = allegiance
	actor.data["allegiance_owner_id"] = "player"
	actor.data["companion_command"] = COMMAND_FOLLOW
	actor.data["companion_restore"] = restore
	actor.data["brain_id"] = "companion"
	actor.data["schedule_suspended"] = true
	actor.data["hostility"] = "friendly"
	actor.data["hostile_to_player"] = false
	actor.data["combat_enabled"] = true
	actor.data["behavior_state"] = COMMAND_FOLLOW
	if actor.has_method("set_allegiance_visual"):
		actor.set_allegiance_visual(allegiance)
	companions_by_entity_id[actor.get_entity_id()] = {"allegiance": allegiance}
	_persist(actor)


func _sync_known_companions() -> void:
	for entity_id in companions_by_entity_id.keys():
		var actor = entities.get_entity(String(entity_id))
		if actor:
			continue
		var tile := _follow_tile(String(entity_id))
		entities.set_actor_location(String(entity_id), tile, String(player.world_layer))


func _update_companion(actor, delta: float) -> void:
	if String(actor.world_layer) != String(player.world_layer):
		entities.set_actor_location(actor.get_entity_id(), _follow_tile(actor.get_entity_id()), player.world_layer)
		return
	var target = _nearest_hostile(actor)
	if target:
		_assist(actor, target, delta)
		return
	if String(actor.data.get("companion_command", COMMAND_FOLLOW)) == COMMAND_HOLD:
		actor.data["behavior_state"] = COMMAND_HOLD
		actor.set_locomotion(false, delta)
		return
	var desired := GridMath.tile_to_world(_follow_tile(actor.get_entity_id())) + Vector2.ONE * 8.0
	var distance: float = actor.global_position.distance_to(desired)
	if distance >= CATCH_UP_DISTANCE:
		entities.set_actor_location(actor.get_entity_id(), _follow_tile(actor.get_entity_id()), player.world_layer)
		return
	actor.data["behavior_state"] = COMMAND_FOLLOW
	if distance <= FOLLOW_DISTANCE:
		actor.set_locomotion(false, delta)
		return
	actor.set_facing_direction(desired - actor.global_position)
	actor.try_move(desired - actor.global_position, delta, chunks, FOLLOW_SPEED)


func _assist(actor, target, delta: float) -> void:
	var offset: Vector2 = target.global_position - actor.global_position
	var distance: float = offset.length()
	actor.data["behavior_state"] = "assisting"
	if distance > ASSIST_ATTACK_RANGE:
		actor.set_facing_direction(offset)
		actor.try_move(offset, delta, chunks, FOLLOW_SPEED)
		return
	actor.set_locomotion(false, delta)
	var cooldown := maxf(0.0, float(actor.data.get("_companion_attack_cooldown", 0.0)) - delta)
	actor.data["_companion_attack_cooldown"] = cooldown
	if cooldown > 0.0 or not combat:
		return
	actor.data["_companion_attack_cooldown"] = ASSIST_INTERVAL
	var result: Dictionary = combat.damage_entity(target, ASSIST_DAMAGE)
	if bool(result.get("defeated", false)):
		entities.transition_actor_to_dead(target)
		combat.clear_entity(target.get_entity_id())
	if event_bus:
		event_bus.post_message("%s strikes %s." % [actor.get_display_name(), target.get_display_name()])


func _nearest_hostile(actor):
	var nearest = null
	var nearest_distance := ASSIST_RANGE
	for candidate in entities.entities_by_id.values():
		if not ActorRules.is_combat_target_entity(candidate):
			continue
		if String(candidate.world_layer) != String(actor.world_layer):
			continue
		var distance: float = actor.global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


func _follow_tile(entity_id: String) -> Vector2i:
	var slot: int = abs(entity_id.hash()) % 3
	var facing: Vector2 = player.get_facing_direction() if player.has_method("get_facing_direction") else Vector2.DOWN
	var lateral := Vector2i(-roundi(facing.y), roundi(facing.x))
	var behind := Vector2i(-roundi(facing.x), -roundi(facing.y))
	return player.global_tile + behind * 2 + lateral * (slot - 1)


func _restore_snapshot(data: Dictionary) -> Dictionary:
	var result := {}
	for key in ["brain_id", "schedule_brain_id", "hostility", "hostile_to_player", "combat_enabled", "schedule_suspended"]:
		if data.has(key):
			result[key] = data[key]
	return result


func _persist(actor) -> void:
	if entities and entities.has_method("persist_actor_state"):
		entities.persist_actor_state(actor)
