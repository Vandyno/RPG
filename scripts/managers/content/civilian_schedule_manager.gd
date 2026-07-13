class_name CivilianScheduleManager
extends Node

const GridMath = preload("res://scripts/core/grid_math.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")
const ScheduleResolver = preload("res://scripts/core/schedule_resolver.gd")
const ScheduleDestinationRegistry = preload("res://scripts/core/schedule_destination_registry.gd")
const ScheduleReservationManager = preload("res://scripts/managers/content/schedule_reservation_manager.gd")
const WorldPathfinder = preload("res://scripts/world/world_pathfinder.gd")
const WorldEntityMovement = preload("res://scripts/world/world_entity_movement.gd")

const BRAIN_ID := "civilian_schedule"
const ARRIVAL_DISTANCE := 10.0
const PORTAL_ARRIVAL_DISTANCE := 32.0
const DEFAULT_MOVE_SPEED := 64.0
const NEED_MAX := 100.0
const HUNGER_RATE_PER_MINUTE := 0.045
const FATIGUE_AWAKE_RATE_PER_MINUTE := 0.06
const FATIGUE_SLEEP_RECOVERY_PER_MINUTE := 0.32
const CRITICAL_HUNGER := 86.0
const CRITICAL_FATIGUE := 90.0
const MEAL_RECOVERY_PER_MINUTE := 0.55
const FLEE_HEALTH_RATIO := 0.35
const RECOVERY_MINUTES := 60
const TRESPASS_REACTION_MINUTES := 2
const TRESPASS_COOLDOWN_MINUTES := 30
const ATTACK_WARY_MINUTES := 1440
const TRESPASS_WARY_MINUTES := 180

var event_bus
var content
var time
var entities
var chunks
var world_query
var combat
var quest_manager
var player
var profiles: Dictionary = {}
var bindings: Dictionary = {}
var destinations := ScheduleDestinationRegistry.new()
var reservations := ScheduleReservationManager.new()
var state_by_npc_id: Dictionary = {}
var social_relationships: Dictionary = {}
var work_records: Dictionary = {}
var player_memories: Dictionary = {}
var _last_absolute_minute := -1
var _social_snapshot_key := ""
var _suppress_social_memory := false


func setup(
	bus,
	content_database,
	time_manager,
	entity_manager = null,
	chunk_manager = null,
	navigation_query = null,
	combat_manager = null,
	quest_manager_value = null
) -> void:
	event_bus = bus
	content = content_database
	time = time_manager
	entities = entity_manager
	chunks = chunk_manager
	world_query = navigation_query
	combat = combat_manager
	quest_manager = quest_manager_value
	if content:
		profiles = content.schedule_profiles.duplicate(true)
		bindings = content.schedule_bindings.duplicate(true)
		destinations.load_data(content.get_schedule_destinations())
		destinations.load_portals(content.world_object_entries())
	if event_bus:
		event_bus.time_changed.connect(_on_time_changed)
		event_bus.chunks_changed.connect(_on_chunks_changed)
		event_bus.load_completed.connect(_on_load_completed)
		event_bus.quest_changed.connect(_on_quest_changed)
	_sync_all(false)


func set_player(player_actor) -> void:
	player = player_actor


func set_quest_manager(manager) -> void:
	quest_manager = manager
	_sync_quest_routines_from_manager()


func load_authored_data(authored_profiles: Dictionary, authored_bindings: Dictionary, authored_destinations: Dictionary) -> void:
	profiles = authored_profiles.duplicate(true)
	bindings = authored_bindings.duplicate(true)
	destinations.load_data(authored_destinations)
	_sync_all(false)


func update(delta: float) -> void:
	if not time or delta <= 0.0:
		return
	if _last_absolute_minute < 0:
		_sync_all(false)
	if not entities:
		return
	for entity_id in entities.entities_by_id:
		var actor = entities.entities_by_id[entity_id]
		_advance_recovery_if_ready(actor)
		_advance_trespass_reaction_if_ready(actor)
		if actor and actor.data is Dictionary and bool(actor.data.get("schedule_resume_requested", false)):
			actor.data.erase("schedule_resume_requested")
			resume(_npc_id_for_actor(actor))
		_record_reactive_schedule_interrupt(actor)
		_record_trespass_reaction(actor)
		if _is_scheduled_actor(actor):
			_update_visible_actor(actor, delta)
	_refresh_social_groups()


func interrupt(npc_id: String, reason: String, resume_policy: String = "advance_to_current_block") -> bool:
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if state.is_empty():
		return false
	state["interruption"] = {"reason": reason, "started_at": _absolute_minute()}
	state["resume_policy"] = resume_policy
	state["reason"] = "interrupted: %s" % reason
	state_by_npc_id[npc_id] = state
	_write_state_to_actor(npc_id, state)
	return true


func resume(npc_id: String) -> bool:
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if state.is_empty():
		return false
	state.erase("interruption")
	var policy := String(state.get("resume_policy", "advance_to_current_block"))
	if policy != "resume_current":
		state["block_index"] = -1
		state["block_id"] = ""
	state["reason"] = "schedule resumed"
	state_by_npc_id[npc_id] = state
	_sync_npc(npc_id, true)
	return true


func assign_quest_routine(npc_id: String, package: Dictionary) -> bool:
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if state.is_empty() or package.is_empty():
		return false
	var destination_id := String(package.get("destination_id", package.get("destination", "")))
	var destination := destinations.get_destination(destination_id)
	if destination_id.is_empty() or destination.is_empty():
		return false
	var destination_tile := _destination_tile(
		destination,
		npc_id,
		time.day if time else 1,
		int(state.get("block_index", 0)),
		time.minute_of_day if time else 0,
		0
	)
	if not _valid_tile(destination_tile):
		return false
	var routine: Dictionary = package.duplicate(true)
	routine["npc_id"] = npc_id
	routine["destination_id"] = destination_id
	routine["activity"] = "quest"
	routine["action"] = String(package.get("action", "attend to the quest"))
	routine["resume_policy"] = String(package.get("resume_policy", "advance_to_current_block"))
	var next_state: Dictionary = state.duplicate(true)
	next_state["interruption"] = {
		"reason": "quest",
		"started_at": _absolute_minute()
	}
	next_state["resume_policy"] = routine["resume_policy"]
	next_state["quest_routine"] = routine
	next_state["quest_id"] = String(package.get("quest_id", ""))
	next_state["quest_routine_id"] = String(package.get("routine_id", ""))
	next_state["activity"] = "quest"
	next_state["activity_action"] = routine["action"]
	next_state["activity_status"] = "on_quest"
	next_state["destination_id"] = destination_id
	next_state["destination_layer"] = String(destination.get("world_layer", "surface"))
	next_state["destination_tile"] = destination_tile
	next_state["path_target"] = destination_tile
	next_state["portal_chain"] = destinations.resolve_portal_chain(_actor_layer(_actor_for_npc(npc_id)), destination)
	next_state["portal_step_index"] = 0
	next_state["at_destination"] = false
	next_state["behavior_state"] = "quest"
	next_state["reason"] = String(package.get("reason", "quest routine"))
	next_state["activity_started_absolute"] = _absolute_minute()
	next_state["activity_progress"] = 0.0
	next_state.erase("_travel_path")
	next_state.erase("_travel_path_index")
	next_state.erase("_travel_path_target")
	state_by_npc_id[npc_id] = next_state
	_write_state_to_actor(npc_id, next_state)
	return true


func release_quest_routine(npc_id: String, quest_id: String = "") -> bool:
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if state.is_empty() or not state.has("quest_routine"):
		return false
	if not quest_id.is_empty() and String(state.get("quest_id", "")) != quest_id:
		return false
	state.erase("quest_routine")
	state.erase("quest_id")
	state.erase("quest_routine_id")
	state_by_npc_id[npc_id] = state
	return resume(npc_id)


func wake_npc(npc_id: String) -> bool:
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if state.is_empty() or String(state.get("activity", "")) != "sleep":
		return false
	var next_minute := int(state.get("next_transition_minute", 0))
	var wake_until: int = time.day * 1440 + next_minute if time else next_minute
	if wake_until <= _absolute_minute():
		wake_until += 1440
	state["wake_override_until_absolute"] = wake_until
	state["activity"] = "wake"
	state["activity_action"] = "get up when woken"
	state["activity_status"] = "getting_ready"
	state["behavior_state"] = "wake"
	state["at_destination"] = true
	state["reason"] = "woken by player"
	state_by_npc_id[npc_id] = state
	_write_state_to_actor(npc_id, state)
	return true


func get_schedule_debug(npc_id: String) -> Dictionary:
	return state_by_npc_id.get(npc_id, {}).duplicate(true)


func get_work_record(npc_id: String) -> Dictionary:
	return work_records.get(npc_id, {}).duplicate(true)


func get_local_rumor(npc_id: String) -> String:
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if state.is_empty() or String(state.get("social_presence", "")) != "with_companions":
		return ""
	var topic := String(state.get("social_topic", ""))
	if topic.is_empty():
		return ""
	return "Rumor: %s" % topic


func get_player_memory(npc_id: String) -> Dictionary:
	var memory: Variant = player_memories.get(npc_id, {})
	return memory.duplicate(true) if memory is Dictionary else {}


func can_address_player_incident(npc_id: String) -> bool:
	var memory := get_player_memory(npc_id)
	if memory.is_empty() or not bool(memory.get("unresolved", false)):
		return false
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if state.is_empty() or String(state.get("activity", "")) in ["sleep", "flee", "recover", "investigate", "quest"]:
		return false
	var actor = _actor_for_npc(npc_id)
	return actor != null and not _actor_is_unavailable(actor)


func acknowledge_player_incident(npc_id: String) -> bool:
	if not can_address_player_incident(npc_id):
		return false
	var memory := get_player_memory(npc_id)
	memory["unresolved"] = false
	memory["wary_until_absolute"] = _absolute_minute()
	memory["last_acknowledged_absolute"] = _absolute_minute()
	player_memories[npc_id] = memory
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	state["reason"] = "player addressed the incident"
	state_by_npc_id[npc_id] = state
	_write_state_to_actor(npc_id, state)
	return true


func get_debug_snapshot() -> Dictionary:
	return {
		"brain_id": BRAIN_ID,
		"current_absolute_minute": _absolute_minute(),
		"current_time": time.get_time_label() if time else "--:--",
		"states": _compact_save_states(),
		"reservations": reservations.get_save_data(),
		"social_relationships": social_relationships.duplicate(true),
		"work_records": work_records.duplicate(true),
		"player_memories": player_memories.duplicate(true)
	}


func is_service_available(service_id: String) -> bool:
	for binding_id in bindings:
		var binding: Dictionary = bindings[binding_id]
		var service_ids: Variant = binding.get("service_ids", [])
		if not service_ids is Array:
			continue
		if not (service_ids as Array).has(service_id):
			continue
		var npc_id := String(binding.get("npc_id", ""))
		var state: Dictionary = state_by_npc_id.get(npc_id, {})
		if _service_state_is_present(npc_id, state):
			return true
	return false


func service_unavailable_reason(service_id: String) -> String:
	for binding_id in bindings:
		var binding: Dictionary = bindings[binding_id]
		var service_ids: Variant = binding.get("service_ids", [])
		if not service_ids is Array:
			continue
		if not (service_ids as Array).has(service_id):
			continue
		var npc_id := String(binding.get("npc_id", ""))
		var state: Dictionary = state_by_npc_id.get(npc_id, {})
		if state.is_empty():
			return "Worker has not entered the world."
		var actor = _actor_for_npc(npc_id)
		if not actor:
			return "Worker is outside the loaded area."
		if _actor_is_unavailable(actor):
			return "Worker is unable to serve right now."
		if String(state.get("activity", "")) != "work":
			return "Worker is %s; expected back at %s." % [String(state.get("activity", "away")), _format_minute(int(state.get("next_transition_minute", 0)))]
		return "Worker is travelling to the service."
	return "No qualified worker is bound to this service."


func dialogue_block_reason(npc_id: String) -> String:
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if state.is_empty():
		return ""
	var activity := String(state.get("activity", ""))
	if activity == "sleep":
		return "They are asleep."
	if activity == "flee":
		return "They are fleeing."
	if activity == "recover":
		return "They are recovering."
	if activity == "investigate" or String(state.get("behavior_state", "")) == "confronting":
		return "They are dealing with an intruder."
	if activity == "quest":
		return "They are occupied with a task."
	if state.has("interruption"):
		return "They are unavailable right now."
	var memory := get_player_memory(npc_id)
	if bool(memory.get("unresolved", false)) and _absolute_minute() < int(memory.get("wary_until_absolute", 0)):
		return "They are wary of you."
	var actor = _actor_for_npc(npc_id)
	if actor and _actor_is_unavailable(actor):
		return "They cannot answer right now."
	return ""


func get_save_data() -> Dictionary:
	return {
		"last_absolute_minute": _last_absolute_minute,
		"states": _compact_save_states(),
		"reservations": reservations.get_save_data(),
		"social_relationships": social_relationships.duplicate(true),
		"work_records": work_records.duplicate(true),
		"player_memories": player_memories.duplicate(true)
	}


func load_save_data(data: Dictionary) -> void:
	state_by_npc_id.clear()
	social_relationships.clear()
	work_records.clear()
	player_memories.clear()
	var states: Variant = data.get("states", {})
	if states is Dictionary:
		for npc_id in states:
			if states[npc_id] is Dictionary:
				state_by_npc_id[String(npc_id)] = states[npc_id].duplicate(true)
	_last_absolute_minute = int(data.get("last_absolute_minute", -1))
	var saved_relationships: Variant = data.get("social_relationships", {})
	if saved_relationships is Dictionary:
		social_relationships = saved_relationships.duplicate(true)
	var saved_work_records: Variant = data.get("work_records", {})
	if saved_work_records is Dictionary:
		work_records = saved_work_records.duplicate(true)
	var saved_player_memories: Variant = data.get("player_memories", {})
	if saved_player_memories is Dictionary:
		player_memories = saved_player_memories.duplicate(true)
	reservations.load_save_data(data.get("reservations", {}) if data.get("reservations", {}) is Dictionary else {})
	_suppress_social_memory = true
	_sync_all(true)
	_suppress_social_memory = false


func _on_time_changed(_day: int, _hour: int, _minute: int, _phase: String) -> void:
	_sync_all(false)


func _on_chunks_changed(_loaded_chunks: Array) -> void:
	_sync_all(true)


func _on_load_completed(_path: String = "") -> void:
	_sync_all(true)
	_sync_quest_routines_from_manager()


func _on_quest_changed(quest_id: String, state: Dictionary) -> void:
	if String(state.get("state", "inactive")) != "active":
		_release_quest_routines(quest_id)
		return
	_release_quest_routines(quest_id)
	_apply_quest_stage_routines(quest_id, String(state.get("stage", "")))


func _sync_quest_routines_from_manager() -> void:
	if not quest_manager or not quest_manager.get("quests") is Dictionary:
		return
	for quest_id in quest_manager.quests:
		var state: Variant = quest_manager.quests[quest_id]
		if state is Dictionary and String(state.get("state", "")) == "active":
			_apply_quest_stage_routines(String(quest_id), String(state.get("stage", "")))


func _apply_quest_stage_routines(quest_id: String, stage_id: String) -> void:
	if not content or quest_id.is_empty() or stage_id.is_empty():
		return
	var definition: Dictionary = content.get_quest(quest_id)
	var stages: Variant = definition.get("stages", {})
	if not stages is Dictionary or not (stages as Dictionary).has(stage_id):
		return
	var stage: Variant = (stages as Dictionary)[stage_id]
	if not stage is Dictionary:
		return
	var routines: Variant = (stage as Dictionary).get("npc_routines", (stage as Dictionary).get("schedule_routines", []))
	if not routines is Array:
		return
	for routine_value in routines:
		if not routine_value is Dictionary:
			continue
		var routine: Dictionary = routine_value.duplicate(true)
		routine["quest_id"] = quest_id
		routine["stage_id"] = stage_id
		assign_quest_routine(String(routine.get("npc_id", "")), routine)


func _release_quest_routines(quest_id: String) -> void:
	if quest_id.is_empty():
		return
	var npc_ids: Array[String] = []
	for npc_id in state_by_npc_id:
		var state: Dictionary = state_by_npc_id[npc_id]
		if String(state.get("quest_id", "")) == quest_id:
			npc_ids.append(String(npc_id))
	for npc_id in npc_ids:
		release_quest_routine(npc_id, quest_id)


func _sync_all(apply_loaded_position: bool) -> void:
	if not time:
		return
	var now := _absolute_minute()
	reservations.prune(now)
	for binding_id in bindings:
		var binding: Dictionary = bindings[binding_id]
		_sync_binding(binding, apply_loaded_position)
	_refresh_social_groups(true)
	_last_absolute_minute = now


func _sync_npc(npc_id: String, apply_loaded_position: bool) -> void:
	for binding_id in bindings:
		var binding: Dictionary = bindings[binding_id]
		if String(binding.get("npc_id", "")) == npc_id:
			_sync_binding(binding, apply_loaded_position)
			return


func _sync_binding(binding: Dictionary, apply_loaded_position: bool) -> void:
	var npc_id := String(binding.get("npc_id", ""))
	if entities and entities.has_method("is_npc_dead") and entities.is_npc_dead(npc_id):
		return
	var profile: Dictionary = profiles.get(String(binding.get("schedule_id", "")), {})
	if npc_id.is_empty() or not profile is Dictionary or profile.is_empty():
		return
	var overrides: Variant = binding.get("personal_overrides", [])
	var resolved: Dictionary = ScheduleResolver.resolve(
		profile,
		time.minute_of_day,
		time.day,
		overrides if overrides is Array else [],
		npc_id,
		String(time.get_weather()) if time.has_method("get_weather") else ""
	)
	if resolved.is_empty():
		return
	var old_state: Dictionary = state_by_npc_id.get(npc_id, {})
	if not old_state.is_empty():
		_advance_needs(old_state, _absolute_minute())
	_record_work_presence(npc_id, old_state)
	var scheduled_activity := String(resolved.get("activity", "sandbox"))
	var scheduled_destination := String(resolved.get("destination", ""))
	var wake_override_until := int(old_state.get("wake_override_until_absolute", 0))
	if scheduled_activity == "sleep" and wake_override_until > _absolute_minute():
		resolved["activity"] = "wake"
		resolved["destination"] = "home"
		resolved["destination_pool"] = ""
		resolved["action"] = "get up when woken"
	var need_override := _critical_need_override(old_state, scheduled_activity)
	if not need_override.is_empty():
		resolved["activity"] = need_override
		resolved["destination"] = "home.meal" if need_override == "eat" else "home"
		resolved["destination_pool"] = ""
		resolved["action"] = "eat urgently" if need_override == "eat" else "sleep urgently"
	if old_state.has("interruption"):
		old_state["next_transition_minute"] = resolved.get("next_transition_minute", 0)
		state_by_npc_id[npc_id] = old_state
		_write_state_to_actor(npc_id, old_state)
		return
	var destination_key := String(resolved.get("destination", ""))
	if destination_key.is_empty() and not String(resolved.get("destination_pool", "")).is_empty():
		destination_key = String(resolved.get("destination_pool", ""))
	var destination := destinations.resolve(binding, destination_key, time.day, int(resolved.get("index", 0)))
	if destination_key == "visit":
		var target_ids: Variant = binding.get("visit_target_npc_ids", [])
		if target_ids is Array and not (target_ids as Array).is_empty():
			var selected_target: Variant = ScheduleResolver.choose_deterministic(
				target_ids, npc_id, time.day, int(resolved.get("index", 0))
			)
			destination["visit_target_npc_id"] = String(selected_target if selected_target != null else "")
	var actor = _actor_for_npc(npc_id)
	var destination_tile: Array = _destination_tile(
		destination,
		npc_id,
		time.day,
		int(resolved.get("index", 0)),
		time.minute_of_day,
		int(resolved.get("start_minute", 0))
	)
	var changed: bool = (
		old_state.is_empty()
		or String(old_state.get("block_id", "")) != String(resolved.get("block_id", ""))
		or String(old_state.get("destination_id", "")) != String(destination.get("id", ""))
		or String(old_state.get("activity", "")) != String(resolved.get("activity", ""))
		or String(old_state.get("need_override", "")) != need_override
		or old_state.get("destination_tile", []) != destination_tile
	)
	var state: Dictionary = old_state.duplicate(true)
	if changed:
		reservations.release_for_npc(npc_id)
		state = {
			"npc_id": npc_id,
			"schedule_id": String(binding.get("schedule_id", "")),
			"block_index": int(resolved.get("index", 0)),
			"block_id": String(resolved.get("block_id", "")),
			"activity": String(resolved.get("activity", "sandbox")),
			"activity_action": _activity_action(resolved, npc_id, destination),
			"scheduled_activity": scheduled_activity,
			"scheduled_destination": scheduled_destination,
			"weather": String(resolved.get("weather", "")),
			"visit_target_npc_id": String(destination.get("visit_target_npc_id", "")),
			"need_override": need_override,
			"trespass_cooldown_until": int(old_state.get("trespass_cooldown_until", 0)),
			"wake_override_until_absolute": wake_override_until,
			"needs": old_state.get("needs", _default_needs()),
			"destination_id": String(destination.get("id", "")),
			"destination_layer": String(destination.get("world_layer", "surface")),
			"destination_tile": destination_tile,
			"path_target": destination_tile,
			"portal_chain": destination.get("portal_chain", []),
			"start_minute": int(resolved.get("start_minute", 0)),
			"scheduled_start_absolute": _schedule_start_absolute(resolved),
			"activity_started_absolute": _schedule_start_absolute(resolved),
			"next_transition_minute": int(resolved.get("next_transition_minute", 0)),
			"activity_progress": 0.0,
			"work_presence_last_absolute": _absolute_minute() if String(resolved.get("activity", "")) == "work" else -1,
			"activity_status": _activity_status(String(resolved.get("activity", "sandbox"))),
			"lateness_minutes": 0,
			"simulation_mode": "near" if actor else "streamed_out",
			"reason": "schedule block",
			"last_simulated_absolute_minute": _absolute_minute()
		}
	else:
		state["next_transition_minute"] = int(resolved.get("next_transition_minute", 0))
		state["activity_action"] = _activity_action(resolved, npc_id, destination)
		state["scheduled_activity"] = scheduled_activity
		state["scheduled_destination"] = scheduled_destination
		state["weather"] = String(resolved.get("weather", ""))
		state["visit_target_npc_id"] = String(destination.get("visit_target_npc_id", ""))
		state["need_override"] = need_override
		state["needs"] = old_state.get("needs", _default_needs())
		if String(state.get("activity", "")) == "work" and not state.has("work_presence_last_absolute"):
			state["work_presence_last_absolute"] = _absolute_minute()
		state["simulation_mode"] = "near" if actor else "streamed_out"
		state["last_simulated_absolute_minute"] = _absolute_minute()
	_update_local_activity_state(state, resolved)
	if not destination.is_empty() and bool(destination.get("exclusive", false)):
		var anchor_id := String(destination.get("id", ""))
		var reserved := reservations.reserve(anchor_id, npc_id, _absolute_minute(), int(destination.get("reservation_minutes", 90)))
		if not reserved:
			var fallback_id := String(destination.get("fallback_destination_id", destination.get("fallback_id", binding.get("fallback_destination_id", ""))))
			var fallback := destinations.get_destination(fallback_id)
			if not fallback.is_empty():
				fallback["id"] = fallback_id
				destination = fallback
				destination_tile = _destination_tile(
					destination,
					npc_id,
				time.day,
				int(resolved.get("index", 0)),
				time.minute_of_day,
				int(resolved.get("start_minute", 0))
				)
				state["destination_id"] = fallback_id
				state["destination_layer"] = String(fallback.get("world_layer", "surface"))
				state["destination_tile"] = destination_tile
				state["path_target"] = destination_tile
				state["reason"] = "exclusive anchor occupied; using fallback"
	state["portal_chain"] = destinations.resolve_portal_chain(_actor_layer(actor), destination)
	state["portal_step_index"] = 0
	_update_local_activity_state(state, resolved)
	if actor and apply_loaded_position:
		_apply_saved_position(actor, state)
	state_by_npc_id[npc_id] = state
	if (
		actor == null
		and entities
		and entities.has_method("set_scheduled_entity_location")
		and _valid_tile(destination_tile)
	):
		# Streamed-out civilians do not walk frame-by-frame. Move their runtime
		# spawn record to the resolved schedule destination so they materialize
		# when that layer/chunk enters the active window.
		entities.set_scheduled_entity_location(
			"%s_world" % npc_id,
			Vector2i(int(destination_tile[0]), int(destination_tile[1])),
			String(state.get("destination_layer", "surface"))
		)
	_write_state_to_actor(npc_id, state)


func _update_visible_actor(actor, delta: float) -> void:
	var npc_id := _npc_id_for_actor(actor)
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	var interruption_reason := String(state.get("interruption", {}).get("reason", "")) if state.get("interruption", {}) is Dictionary else ""
	if state.is_empty() or (state.has("interruption") and not ["flee", "trespass", "quest"].has(interruption_reason)):
		if actor.has_method("set_locomotion"):
			actor.set_locomotion(false, delta)
		return
	var destination_layer := String(state.get("destination_layer", "surface"))
	var actor_layer := String(actor.data.get("world_layer", "surface"))
	if actor_layer != destination_layer:
		_update_portal_travel(actor, state, destination_layer, delta)
		return
	var tile: Variant = state.get("destination_tile", [])
	if not tile is Array or tile.size() < 2:
		return
	var destination := _tile_center(Vector2i(int(tile[0]), int(tile[1])))
	if actor.global_position.distance_to(destination) <= ARRIVAL_DISTANCE:
		if String(state.get("activity", "")) == "flee":
			_finish_flee(actor, state)
			return
		if String(state.get("activity", "")) == "investigate":
			_finish_trespass_arrival(actor, state)
			return
		state["behavior_state"] = String(state.get("activity", "sandbox"))
		state["at_destination"] = true
		state["lateness_minutes"] = maxi(0, _absolute_minute() - int(state.get("scheduled_start_absolute", _absolute_minute())))
		_write_state(actor, state)
		if actor.has_method("set_locomotion"):
			actor.set_locomotion(false, delta)
		return
	state["behavior_state"] = "traveling"
	state["at_destination"] = false
	_move_towards(actor, destination, actor_layer, state, delta)
	if actor.global_position.distance_to(destination) <= ARRIVAL_DISTANCE:
		if String(state.get("activity", "")) == "flee":
			_finish_flee(actor, state)
			return
		if String(state.get("activity", "")) == "investigate":
			_finish_trespass_arrival(actor, state)
			return
		state["behavior_state"] = String(state.get("activity", "sandbox"))
		state["at_destination"] = true
	_write_state(actor, state)


func _update_portal_travel(actor, state: Dictionary, destination_layer: String, delta: float) -> void:
	var chain: Array = state.get("portal_chain", []) if state.get("portal_chain", []) is Array else []
	var step_index := clampi(int(state.get("portal_step_index", 0)), 0, chain.size())
	if chain.is_empty():
		chain = destinations.resolve_portal_chain(String(actor.data.get("world_layer", "surface")), {"world_layer": destination_layer})
		state["portal_chain"] = chain
		step_index = 0
	if step_index >= chain.size():
		state["reason"] = "No reachable portal route to destination."
		state["behavior_state"] = "travel_blocked"
		_write_state(actor, state)
		return
	var step: Dictionary = chain[step_index] if chain[step_index] is Dictionary else {}
	var from_layer := String(step.get("from_layer", ""))
	var to_layer := String(step.get("to_layer", ""))
	var from_tile: Variant = step.get("from_tile", [])
	var to_tile: Variant = step.get("to_tile", [])
	if from_layer.is_empty() or to_layer.is_empty() or not _valid_tile(from_tile) or not _valid_tile(to_tile):
		state["reason"] = "Malformed portal route."
		state["behavior_state"] = "travel_blocked"
		_write_state(actor, state)
		return
	var actor_layer := String(actor.data.get("world_layer", "surface"))
	if actor_layer != from_layer:
		state["portal_chain"] = destinations.resolve_portal_chain(actor_layer, {"world_layer": destination_layer})
		state["portal_step_index"] = 0
		state.erase("_travel_path")
		_write_state(actor, state)
		return
	var portal_position := _tile_center(Vector2i(int(from_tile[0]), int(from_tile[1])))
	state["behavior_state"] = "traveling_portal"
	state["portal_target_layer"] = to_layer
	state["portal_target_tile"] = [int(to_tile[0]), int(to_tile[1])]
	state["at_destination"] = false
	if actor.global_position.distance_to(portal_position) > PORTAL_ARRIVAL_DISTANCE:
		_move_towards(actor, portal_position, actor_layer, state, delta, PORTAL_ARRIVAL_DISTANCE)
		_write_state(actor, state)
		return
	if actor.has_method("set_world_layer"):
		actor.set_world_layer(to_layer)
	if actor.has_method("set_global_tile"):
		actor.set_global_tile(Vector2i(int(to_tile[0]), int(to_tile[1])))
	state["portal_step_index"] = step_index + 1
	state.erase("_travel_path")
	state["reason"] = "Passed through portal."
	_write_state(actor, state)


func _move_towards(
	actor, target: Vector2, layer: String, state: Dictionary, delta: float, stop_distance: float = 0.0
) -> void:
	var path: Array = state.get("_travel_path", []) if state.get("_travel_path", []) is Array else []
	var path_target: Variant = state.get("_travel_path_target", [])
	var target_pair := [target.x, target.y]
	if path.is_empty() or path_target != target_pair:
		var can_stand := func(world_position: Vector2) -> bool: return _can_stand_at(world_position, layer)
		path = (
			WorldPathfinder.approach_path_to(can_stand, actor.global_position, target, stop_distance)
			if stop_distance > 0.0
			else WorldPathfinder.path_to(can_stand, actor.global_position, target)
		)
		state["_travel_path"] = path
		state["_travel_path_index"] = 0
		state["_travel_path_target"] = target_pair
	if path.is_empty():
		state["reason"] = "Path blocked."
		state["behavior_state"] = "travel_blocked"
		return
	var path_index := clampi(int(state.get("_travel_path_index", 0)), 0, path.size() - 1)
	while path_index < path.size() - 1 and actor.global_position.distance_to(path[path_index]) <= ARRIVAL_DISTANCE:
		path_index += 1
	state["_travel_path_index"] = path_index
	var waypoint: Vector2 = path[path_index]
	var speed := float(actor.data.get("move_speed", DEFAULT_MOVE_SPEED))
	if actor.has_method("set_facing_direction"):
		actor.set_facing_direction(waypoint - actor.global_position)
	if actor.has_method("try_move"):
		var distance: float = actor.global_position.distance_to(waypoint)
		var movement_delta := minf(delta, distance / maxf(1.0, speed))
		actor.try_move(waypoint - actor.global_position, movement_delta, world_query if world_query else chunks, speed)


func _can_stand_at(world_position: Vector2, layer: String) -> bool:
	var tile := GridMath.world_to_tile(world_position)
	if world_query:
		return WorldEntityMovement.can_stand_at(world_position, world_query, layer)
	if chunks and chunks.has_method("is_walkable"):
		return chunks.is_walkable(tile)
	return true


func _valid_tile(value: Variant) -> bool:
	return value is Array and value.size() >= 2 and _is_number(value[0]) and _is_number(value[1])


func _compact_save_states() -> Dictionary:
	var result: Dictionary = {}
	for npc_id in state_by_npc_id:
		var state: Dictionary = state_by_npc_id[npc_id].duplicate(true)
		state.erase("_travel_path")
		state.erase("_travel_path_index")
		state.erase("_travel_path_target")
		result[String(npc_id)] = state
	return result


func _service_state_is_present(npc_id: String, state: Dictionary) -> bool:
	if state.is_empty() or String(state.get("activity", "")) != "work":
		return false
	if not bool(state.get("at_destination", false)) or state.has("interruption"):
		return false
	if String(state.get("simulation_mode", "streamed_out")) != "near":
		return false
	var actor = _actor_for_npc(npc_id)
	return actor != null and not _actor_is_unavailable(actor)


func _actor_is_unavailable(actor) -> bool:
	if not actor or not actor.data is Dictionary:
		return true
	if not ActorRules.is_living_actor_data(actor.data):
		return true
	if bool(actor.data.get("dead", false)) or bool(actor.data.get("incapacitated", false)):
		return true
	var health: Variant = actor.data.get("health", null)
	if _is_number(health) and float(health) <= 0.0:
		return true
	return String(actor.data.get("hostility", "neutral")) == "hostile" or bool(actor.data.get("hostile_to_player", false))


func _write_state_to_actor(npc_id: String, state: Dictionary) -> void:
	var actor = _actor_for_npc(npc_id)
	if actor:
		_write_state(actor, state)


func _write_state(actor, state: Dictionary) -> void:
	state["simulation_mode"] = "near"
	state["last_simulated_absolute_minute"] = _absolute_minute()
	state["world_layer"] = String(actor.data.get("world_layer", "surface"))
	if actor.has_method("get_entity_id"):
		state["global_tile"] = [actor.global_tile.x, actor.global_tile.y]
		state["world_position"] = [actor.global_position.x, actor.global_position.y]
	state["behavior_state"] = String(state.get("behavior_state", state.get("activity", "idle")))
	actor.data["schedule_activity_action"] = String(state.get("activity_action", ""))
	actor.data["schedule_activity_status"] = String(state.get("activity_status", "idle"))
	actor.data["schedule_activity_progress"] = float(state.get("activity_progress", 0.0))
	actor.data["schedule_work_summary"] = String(state.get("work_summary", ""))
	actor.data["schedule_work_output"] = String(state.get("work_output", ""))
	actor.data["schedule_weather"] = String(state.get("weather", ""))
	actor.data["schedule_social_presence"] = String(state.get("social_presence", ""))
	actor.data["schedule_social_exchange"] = String(state.get("social_exchange", ""))
	actor.data["schedule_player_memory"] = get_player_memory(String(state.get("npc_id", "")))
	actor.data["schedule_state"] = state.duplicate(true)
	actor.data["behavior_state"] = String(state.get("behavior_state", state.get("activity", "idle")))
	state_by_npc_id[String(state.get("npc_id", ""))] = state


func _apply_saved_position(actor, state: Dictionary) -> void:
	var position: Variant = state.get("world_position", [])
	if position is Array and position.size() >= 2 and actor.has_method("set_world_position"):
		actor.set_world_position(Vector2(float(position[0]), float(position[1])))


func _actor_for_npc(npc_id: String):
	if not entities:
		return null
	for entity_id in entities.entities_by_id:
		var actor = entities.entities_by_id[entity_id]
		if _npc_id_for_actor(actor) == npc_id:
			return actor
	return null


func _actor_layer(actor) -> String:
	if actor and actor.data is Dictionary:
		return String(actor.data.get("world_layer", "surface"))
	return "surface"


func _npc_id_for_actor(actor) -> String:
	return String(actor.data.get("npc_id", actor.data.get("id", ""))) if actor and actor.data is Dictionary else ""


func _is_scheduled_actor(actor) -> bool:
	if not actor or not actor.data is Dictionary:
		return false
	if not ActorRules.is_living_actor_data(actor.data):
		return false
	if String(actor.data.get("brain_id", "")) != BRAIN_ID:
		return false
	if bool(actor.data.get("dead", false)) or bool(actor.data.get("incapacitated", false)):
		return false
	var health: Variant = actor.data.get("health", null)
	if _is_number(health) and float(health) <= 0.0:
		return false
	return String(actor.data.get("hostility", "neutral")) != "hostile"


func _record_player_incident(npc_id: String, incident_kind: String) -> void:
	if npc_id.is_empty() or incident_kind.is_empty():
		return
	var saved: Variant = player_memories.get(npc_id, {})
	var memory: Dictionary = saved.duplicate(true) if saved is Dictionary else {}
	var count_key := "%s_count" % incident_kind
	memory[count_key] = int(memory.get(count_key, 0)) + 1
	memory["last_incident"] = incident_kind
	memory["last_incident_absolute"] = _absolute_minute()
	memory["unresolved"] = true
	memory["rumor"] = (
		"Someone attacked me."
		if incident_kind == "attack"
		else "Someone entered my home without permission."
	)
	var wary_minutes := ATTACK_WARY_MINUTES if incident_kind == "attack" else TRESPASS_WARY_MINUTES
	memory["wary_until_absolute"] = maxi(
		int(memory.get("wary_until_absolute", 0)), _absolute_minute() + wary_minutes
	)
	player_memories[npc_id] = memory
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if not state.is_empty():
		state["player_memory"] = memory.duplicate(true)
		state_by_npc_id[npc_id] = state


func _record_reactive_schedule_interrupt(actor) -> void:
	if not actor or not actor.data is Dictionary:
		return
	if String(actor.data.get("schedule_brain_id", "")) != BRAIN_ID:
		return
	if String(actor.data.get("hostility", "neutral")) != "hostile" and not bool(actor.data.get("hostile_to_player", false)):
		return
	var npc_id := _npc_id_for_actor(actor)
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if npc_id.is_empty() or state.is_empty():
		return
	if _should_flee(actor):
		var interruption: Variant = state.get("interruption", {})
		var interruption_reason := String(interruption.get("reason", "")) if interruption is Dictionary else ""
		if interruption_reason.is_empty() or interruption_reason == "combat":
			_begin_flee(actor, npc_id)
		return
	if state.has("interruption"):
		return
	_record_player_incident(npc_id, "attack")
	interrupt(npc_id, "combat", "advance_to_current_block")


func _record_trespass_reaction(actor) -> void:
	if not player or not _is_scheduled_actor(actor):
		return
	var npc_id := _npc_id_for_actor(actor)
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if npc_id.is_empty() or state.is_empty() or state.has("interruption"):
		return
	if _absolute_minute() < int(state.get("trespass_cooldown_until", 0)):
		return
	if not _player_is_trespassing_in_home(actor, npc_id):
		return
	_record_player_incident(npc_id, "trespass")
	_emit_trespass_crime(actor, npc_id)
	_begin_trespass_reaction(actor, npc_id)


func _emit_trespass_crime(actor, npc_id: String) -> void:
	if not event_bus or not actor or not player:
		return
	var profile := ActorRules.profile(actor.data)
	var target_sneaking := false
	var sneaking_value: Variant = player.get("is_sneaking")
	if sneaking_value is bool:
		target_sneaking = sneaking_value
	event_bus.player_crime_committed.emit(
		{
			"kind": "trespass",
			"offender_id": "player",
			"victim_entity_id": actor.get_entity_id(),
			"victim_npc_id": npc_id,
			"victim_faction_id": String(profile.get("faction_id", actor.data.get("faction_id", ""))),
			"world_position": [player.global_position.x, player.global_position.y],
			"world_layer": String(player.world_layer),
			"noise_radius": 0.0,
			"visible": true,
			"target_sneaking": target_sneaking
		}
	)


func _player_is_trespassing_in_home(actor, npc_id: String) -> bool:
	if not player or not actor:
		return false
	var binding := _binding_for_npc(npc_id)
	var home_id := String(binding.get("home_destination_id", ""))
	var home := destinations.get_destination(home_id)
	var home_layer := String(home.get("world_layer", ""))
	if home_layer.is_empty() or not home_layer.begins_with("interior:"):
		return false
	if String(player.world_layer) != home_layer:
		return false
	if String(actor.data.get("world_layer", "surface")) != home_layer:
		return false
	return actor.global_position.distance_to(player.global_position) <= 512.0


func _begin_trespass_reaction(actor, npc_id: String) -> void:
	var old_state: Dictionary = state_by_npc_id.get(npc_id, {})
	if old_state.is_empty():
		return
	var target_tile := GridMath.world_to_tile(player.global_position)
	var state: Dictionary = old_state.duplicate(true)
	state["interruption"] = {"reason": "trespass", "started_at": _absolute_minute()}
	state["resume_policy"] = "advance_to_current_block"
	state["activity"] = "investigate"
	state["activity_action"] = "challenge trespasser"
	state["activity_status"] = "investigating"
	state["destination_id"] = "__trespasser__"
	state["destination_layer"] = String(actor.data.get("world_layer", "surface"))
	state["destination_tile"] = [target_tile.x, target_tile.y]
	state["path_target"] = state["destination_tile"]
	state["portal_chain"] = []
	state["portal_step_index"] = 0
	state["at_destination"] = false
	state["behavior_state"] = "investigating"
	state["reason"] = "private home trespass"
	state["reaction_until_absolute"] = _absolute_minute() + TRESPASS_REACTION_MINUTES
	state.erase("_travel_path")
	state.erase("_travel_path_index")
	state.erase("_travel_path_target")
	state_by_npc_id[npc_id] = state
	actor.data["schedule_reaction"] = "trespass"
	_write_state(actor, state)


func _finish_trespass_arrival(actor, state: Dictionary) -> void:
	state["behavior_state"] = "confronting"
	state["at_destination"] = true
	state["reason"] = "confronting trespasser"
	_write_state(actor, state)
	if actor.has_method("set_locomotion"):
		actor.set_locomotion(false, 0.0)


func _advance_trespass_reaction_if_ready(actor) -> void:
	if not actor or not actor.data is Dictionary:
		return
	var npc_id := _npc_id_for_actor(actor)
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if npc_id.is_empty() or state.is_empty() or String(state.get("activity", "")) != "investigate":
		return
	if _absolute_minute() < int(state.get("reaction_until_absolute", 0)):
		return
	state.erase("reaction_until_absolute")
	state["trespass_cooldown_until"] = _absolute_minute() + TRESPASS_COOLDOWN_MINUTES
	state_by_npc_id[npc_id] = state
	resume(npc_id)


func _should_flee(actor) -> bool:
	if not combat or not combat.has_method("get_entity_health"):
		return false
	var max_health_value: Variant = actor.data.get("max_health", 0)
	if not _is_number(max_health_value) or float(max_health_value) <= 0.0:
		return false
	var health := int(combat.get_entity_health(actor))
	return float(health) / float(max_health_value) <= FLEE_HEALTH_RATIO


func _begin_flee(actor, npc_id: String) -> void:
	var old_state: Dictionary = state_by_npc_id.get(npc_id, {})
	var binding := _binding_for_npc(npc_id)
	if old_state.is_empty() or binding.is_empty():
		return
	var destination := destinations.resolve(binding, "home", time.day, int(old_state.get("block_index", 0)))
	if destination.is_empty():
		interrupt(npc_id, "combat", "advance_to_current_block")
		return
	var destination_tile: Array = _destination_tile(
		destination,
		npc_id,
		time.day,
		int(old_state.get("block_index", 0)),
		time.minute_of_day,
		0
	)
	var state: Dictionary = old_state.duplicate(true)
	state["interruption"] = {"reason": "flee", "started_at": _absolute_minute()}
	state["resume_policy"] = "advance_to_current_block"
	state["activity"] = "flee"
	state["activity_action"] = "run home"
	state["destination_id"] = String(destination.get("id", ""))
	state["destination_layer"] = String(destination.get("world_layer", "surface"))
	state["destination_tile"] = destination_tile
	state["path_target"] = destination_tile
	state["portal_chain"] = destinations.resolve_portal_chain(_actor_layer(actor), destination)
	state["portal_step_index"] = 0
	state["at_destination"] = false
	state["behavior_state"] = "fleeing"
	state["reason"] = "wounded civilian fleeing home"
	state.erase("_travel_path")
	state.erase("_travel_path_index")
	state.erase("_travel_path_target")
	state_by_npc_id[npc_id] = state
	actor.data["brain_id"] = BRAIN_ID
	actor.data["hostility"] = "neutral"
	actor.data["hostile_to_player"] = false
	actor.data["schedule_reaction"] = "fleeing"
	_write_state(actor, state)


func _finish_flee(actor, state: Dictionary) -> void:
	state["activity"] = "recover"
	state["activity_action"] = "recover from injury"
	state["behavior_state"] = "recovering"
	state["at_destination"] = true
	state["reason"] = "recovering at home"
	state["recovery_until_absolute"] = _absolute_minute() + RECOVERY_MINUTES
	state["interruption"] = {"reason": "recovering", "started_at": _absolute_minute()}
	state["resume_policy"] = "advance_to_current_block"
	_write_state(actor, state)


func _advance_recovery_if_ready(actor) -> void:
	if not actor or not actor.data is Dictionary:
		return
	var npc_id := _npc_id_for_actor(actor)
	var state: Dictionary = state_by_npc_id.get(npc_id, {})
	if npc_id.is_empty() or state.is_empty() or not state.has("recovery_until_absolute"):
		return
	if _absolute_minute() < int(state.get("recovery_until_absolute", 0)):
		return
	state.erase("recovery_until_absolute")
	state_by_npc_id[npc_id] = state
	if combat and combat.has_method("heal_entity"):
		combat.heal_entity(actor, int(actor.data.get("max_health", 0)))
	resume(npc_id)


func _binding_for_npc(npc_id: String) -> Dictionary:
	for binding_id in bindings:
		var binding: Dictionary = bindings[binding_id]
		if String(binding.get("npc_id", "")) == npc_id:
			return binding
	return {}


func _schedule_start_absolute(resolved: Dictionary) -> int:
	if not time:
		return int(resolved.get("start_minute", 0))
	var start_minute := int(resolved.get("start_minute", 0))
	var result: int = time.day * 1440 + start_minute
	if start_minute > time.minute_of_day:
		result -= 1440
	return result


func _activity_status(activity: String) -> String:
	return {
		"sleep": "sleeping",
		"wake": "getting_ready",
		"work": "working",
		"eat": "eating",
		"relax": "socializing",
		"travel": "travelling",
		"quest": "on_quest",
		"sandbox": "wandering"
	}.get(activity, "idle")


func _update_local_activity_state(state: Dictionary, resolved: Dictionary) -> void:
	var start_absolute := int(state.get("activity_started_absolute", _schedule_start_absolute(resolved)))
	var elapsed := maxi(0, _absolute_minute() - start_absolute)
	var duration := maxi(1, int(resolved.get("minutes_until_transition", 1)))
	state["activity_progress"] = clampf(float(elapsed) / float(duration), 0.0, 1.0)
	state["activity_status"] = _activity_status(String(state.get("activity", "sandbox")))
	state["activity_elapsed_minutes"] = elapsed
	if String(state.get("activity", "")) == "work":
		var record: Variant = work_records.get(String(state.get("npc_id", "")), {})
		if record is Dictionary:
			state["work_summary"] = _work_summary(record)
			state["work_output"] = String(record.get("last_output", ""))


func _record_work_presence(npc_id: String, state: Dictionary) -> void:
	if state.is_empty() or String(state.get("activity", "")) != "work":
		return
	if not bool(state.get("at_destination", false)):
		return
	if String(state.get("simulation_mode", "near")) != "near":
		return
	var now := _absolute_minute()
	var last := int(state.get("work_presence_last_absolute", now))
	if last < 0:
		last = now
	var elapsed := maxi(0, now - last)
	state["work_presence_last_absolute"] = now
	if elapsed <= 0:
		return
	var action := String(state.get("activity_action", "work"))
	var record_variant: Variant = work_records.get(npc_id, {})
	var record: Dictionary = record_variant.duplicate(true) if record_variant is Dictionary else {}
	record["npc_id"] = npc_id
	record["total_minutes"] = int(record.get("total_minutes", 0)) + elapsed
	var action_minutes_variant: Variant = record.get("action_minutes", {})
	var action_minutes: Dictionary = action_minutes_variant.duplicate(true) if action_minutes_variant is Dictionary else {}
	action_minutes[action] = int(action_minutes.get(action, 0)) + elapsed
	record["action_minutes"] = action_minutes
	record["last_action"] = action
	record["last_output"] = _work_output_for_action(action)
	record["last_work_absolute"] = now
	work_records[npc_id] = record
	state["work_summary"] = _work_summary(record)
	state["work_output"] = String(record.get("last_output", ""))


func _work_output_for_action(action: String) -> String:
	return {
		"hoe_rows": "Tended the field rows.",
		"check_livestock": "Checked the livestock.",
		"carry_hay": "Moved fresh hay to the animals.",
		"repair_fence": "Repaired part of the fence.",
		"gather_harvest": "Gathered produce for market.",
		"serve_customer": "Served a customer.",
		"appraise_goods": "Appraised incoming goods.",
		"haggle": "Settled a difficult bargain.",
		"sweep_shop": "Swept and prepared the shop.",
		"arrange_stock": "Arranged the shop stock.",
		"count_coins": "Counted the day's takings.",
		"patrol_gate": "Patrolled the gate.",
		"check_gate": "Checked the gate and watch posts.",
		"walk_watch": "Walked the town watch route."
	}.get(action, "Worked through the day's duties.")


func _work_summary(record: Dictionary) -> String:
	if record.is_empty():
		return ""
	var total := int(record.get("total_minutes", 0))
	var output := String(record.get("last_output", ""))
	if output.is_empty():
		return "%d minutes worked" % total
	return "%s (%d minutes)" % [output, total]


func _default_needs() -> Dictionary:
	return {
		"hunger": 20.0,
		"fatigue": 20.0,
		"last_updated_absolute": _absolute_minute()
	}


func _advance_needs(state: Dictionary, now: int) -> void:
	var needs: Dictionary = _default_needs()
	var saved_needs: Variant = state.get("needs", {})
	if saved_needs is Dictionary:
		needs = (saved_needs as Dictionary).duplicate(true)
	var last_updated: int = int(needs.get("last_updated_absolute", now))
	var elapsed: int = maxi(0, now - last_updated)
	if elapsed <= 0:
		state["needs"] = needs
		return
	var activity: String = String(state.get("activity", "sandbox"))
	var hunger: float = clampf(float(needs.get("hunger", 20.0)), 0.0, NEED_MAX)
	var fatigue: float = clampf(float(needs.get("fatigue", 20.0)), 0.0, NEED_MAX)
	hunger += float(elapsed) * HUNGER_RATE_PER_MINUTE
	if activity == "eat":
		hunger -= float(elapsed) * MEAL_RECOVERY_PER_MINUTE
	if activity == "sleep":
		fatigue -= float(elapsed) * FATIGUE_SLEEP_RECOVERY_PER_MINUTE
	else:
		fatigue += float(elapsed) * FATIGUE_AWAKE_RATE_PER_MINUTE
	needs["hunger"] = clampf(hunger, 0.0, NEED_MAX)
	needs["fatigue"] = clampf(fatigue, 0.0, NEED_MAX)
	needs["last_updated_absolute"] = now
	state["needs"] = needs


func _critical_need_override(state: Dictionary, scheduled_activity: String) -> String:
	if state.is_empty() or scheduled_activity == "sleep" or scheduled_activity == "eat":
		return ""
	var needs: Variant = state.get("needs", {})
	if not needs is Dictionary:
		return ""
	if float((needs as Dictionary).get("fatigue", 0.0)) >= CRITICAL_FATIGUE:
		return "sleep"
	if float((needs as Dictionary).get("hunger", 0.0)) >= CRITICAL_HUNGER:
		return "eat"
	return ""


func _absolute_minute() -> int:
	return time.day * 1440 + time.minute_of_day if time else 0


func _format_minute(value: int) -> String:
	return "%02d:%02d" % [posmod(value, 1440) / 60, posmod(value, 60)]


func _tile_center(tile: Vector2i) -> Vector2:
	return GridMath.tile_to_world(tile) + Vector2(GridMath.TILE_SIZE, GridMath.TILE_SIZE) * 0.5


func _is_number(value: Variant) -> bool:
	return value is int or value is float


func _destination_tile(
	destination: Dictionary,
	npc_id: String,
	day: int,
	block_index: int,
	minute_of_day: int = 0,
	start_minute: int = 0
) -> Array:
	var activity_tiles: Variant = destination.get("activity_tiles", [])
	if activity_tiles is Array and not activity_tiles.is_empty():
		var cycle_minutes := maxi(1, int(destination.get("activity_cycle_minutes", 60)))
		var elapsed := minute_of_day - start_minute
		if elapsed < 0:
			elapsed += 1440
		var cycle_index := block_index + floori(float(elapsed) / float(cycle_minutes))
		var selected: Variant = ScheduleResolver.choose_deterministic(
			activity_tiles, npc_id, day, cycle_index
		)
		if _valid_tile(selected):
			return [int(selected[0]), int(selected[1])]
	var tile: Variant = destination.get("global_tile", [])
	return [int(tile[0]), int(tile[1])] if _valid_tile(tile) else []


func _refresh_social_groups(force: bool = false) -> void:
	var snapshot_ids: Array[String] = []
	for npc_id in state_by_npc_id:
		snapshot_ids.append(String(npc_id))
	snapshot_ids.sort()
	var snapshot_parts: Array[String] = []
	for npc_id in snapshot_ids:
		var snapshot_state: Dictionary = state_by_npc_id[npc_id]
		snapshot_parts.append("%s:%s:%s:%s:%s:%s" % [
			npc_id,
			String(snapshot_state.get("activity", "")),
			String(snapshot_state.get("activity_action", "")),
			String(snapshot_state.get("destination_id", "")),
			str(bool(snapshot_state.get("at_destination", false))),
			str(snapshot_state.has("interruption"))
		])
	var snapshot_key := ";".join(snapshot_parts)
	var snapshot_changed := snapshot_key != _social_snapshot_key
	if not force and not snapshot_changed:
		return
	_social_snapshot_key = snapshot_key
	var groups: Dictionary = {}
	var households: Dictionary = {}
	for binding_id in bindings:
		var binding: Dictionary = bindings[binding_id]
		var home_id := String(binding.get("home_destination_id", ""))
		var npc_id := String(binding.get("npc_id", ""))
		if home_id.is_empty() or npc_id.is_empty():
			continue
		if not households.has(home_id):
			households[home_id] = []
		households[home_id].append(npc_id)
	for npc_id in state_by_npc_id:
		var state: Dictionary = state_by_npc_id[npc_id]
		state.erase("household_id")
		state.erase("household_members")
		for home_id in households:
			var members: Array = households[home_id]
			if members.has(String(npc_id)):
				state["household_id"] = "household:%s" % home_id
				state["household_members"] = members.filter(func(other_id): return other_id != npc_id)
				break
		var is_socially_available := (
			String(state.get("activity", "")) == "relax"
			and not state.has("interruption")
			and bool(state.get("at_destination", false))
			and String(state.get("simulation_mode", "streamed_out")) == "near"
		)
		if not is_socially_available:
			state.erase("companions")
			state.erase("social_group_id")
			state.erase("social_presence")
			state.erase("social_exchange")
			state.erase("social_topic")
			state.erase("social_relationship_ids")
			continue
		state["social_presence"] = "alone"
		state["social_relationship_ids"] = []
		var group_key := "%s:%s" % [
			String(state.get("destination_id", "")),
			String(state.get("destination_layer", "surface"))
		]
		if not groups.has(group_key):
			groups[group_key] = []
		groups[group_key].append(String(npc_id))
	for group_key in groups:
		var companions: Array = groups[group_key]
		companions.sort()
		var group_exchange := String(ScheduleResolver.choose_deterministic(
			["talk", "listen", "laugh", "share_news"],
			String(companions[0]) if not companions.is_empty() else "",
			time.day if time else 1,
			floori(float(_absolute_minute()) / 5.0)
		)) if companions.size() > 1 else ""
		var group_topic := _social_topic_for_group(companions)
		for npc_id in companions:
			var state: Dictionary = state_by_npc_id[npc_id]
			state["social_group_id"] = group_key
			state["companions"] = companions.filter(func(other_id): return other_id != npc_id)
			state["social_presence"] = "with_companions" if companions.size() > 1 else "alone"
			state["social_exchange"] = group_exchange
			state["social_topic"] = group_topic
		var relationship_ids: Array[String] = []
		for left_index in range(companions.size()):
			for right_index in range(left_index + 1, companions.size()):
				var relationship_key := _social_relationship_key(
					String(companions[left_index]), String(companions[right_index])
				)
				relationship_ids.append(relationship_key)
				if snapshot_changed and not _suppress_social_memory:
					_record_social_meeting(
						String(companions[left_index]),
						String(companions[right_index]),
						group_exchange if not group_exchange.is_empty() else "talk",
						group_topic
					)
		for npc_id in companions:
			var state: Dictionary = state_by_npc_id[npc_id]
			state["social_relationship_ids"] = relationship_ids.duplicate()
	for npc_id in state_by_npc_id:
		_write_state_to_actor(String(npc_id), state_by_npc_id[npc_id])


func _social_relationship_key(first_npc_id: String, second_npc_id: String) -> String:
	var ids := [first_npc_id, second_npc_id]
	ids.sort()
	return "%s|%s" % [ids[0], ids[1]]


func _record_social_meeting(
	first_npc_id: String, second_npc_id: String, exchange: String, topic: String = ""
) -> void:
	var key := _social_relationship_key(first_npc_id, second_npc_id)
	var relationship_variant: Variant = social_relationships.get(key, {})
	var relationship: Dictionary = relationship_variant.duplicate(true) if relationship_variant is Dictionary else {}
	relationship["npc_ids"] = key.split("|")
	relationship["meetings"] = int(relationship.get("meetings", 0)) + 1
	relationship["familiarity"] = minf(100.0, float(relationship.get("familiarity", 0.0)) + 1.0)
	relationship["last_interaction_absolute"] = _absolute_minute()
	relationship["last_exchange"] = exchange
	relationship["last_topic"] = topic
	social_relationships[key] = relationship


func _social_topic_for_group(companions: Array) -> String:
	for npc_id in companions:
		var memory: Variant = player_memories.get(String(npc_id), {})
		if memory is Dictionary and bool((memory as Dictionary).get("unresolved", false)):
			var incident_rumor := String((memory as Dictionary).get("rumor", ""))
			if not incident_rumor.is_empty():
				return incident_rumor
		var record: Dictionary = work_records.get(String(npc_id), {})
		var output := String(record.get("last_output", "")) if record is Dictionary else ""
		if not output.is_empty():
			return output
	return ""


func _activity_action(resolved: Dictionary, npc_id: String, destination: Dictionary = {}) -> String:
	var pool: Variant = resolved.get("action_pool", [])
	if pool is Array and not pool.is_empty():
		var cycle_minutes := maxi(1, int(destination.get("activity_cycle_minutes", 60)))
		var elapsed: int = (time.minute_of_day if time else 0) - int(resolved.get("start_minute", 0))
		if elapsed < 0:
			elapsed += 1440
		var cycle_index := int(resolved.get("index", 0)) + floori(float(elapsed) / float(cycle_minutes))
		var selected: Variant = ScheduleResolver.choose_deterministic(
			pool, npc_id, time.day if time else 1, cycle_index
		)
		return String(selected if selected != null else "")
	var authored_action := String(resolved.get("action", ""))
	if not authored_action.is_empty():
		return authored_action
	return {
		"sleep": "sleep",
		"wake": "dress_and_prepare",
		"work": "perform_trade",
		"eat": "eat",
		"relax": "socialize",
		"sandbox": "wander"
	}.get(String(resolved.get("activity", "sandbox")), "idle")
