class_name CrimeManager
extends Node

const ActorRules = preload("res://scripts/core/actor_rules.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")

const REPUTATION_PENALTIES := {
	"assault": -3,
	"murder": -15,
	"theft": -2,
	"trespass": -1
}
const DISPOSITION_PENALTIES := {
	"assault": -20,
	"murder": -50,
	"theft": -12,
	"trespass": -8
}
const JAIL_LAYER := "interior:structure_northgate_jail"
const JAIL_CELL_TILE := Vector2i(2, 3)
const JAIL_RELEASE_LAYER := "surface"
const JAIL_RELEASE_TILE := Vector2i(-3244, -3953)
const AMENDS_COST := 25
const AMENDS_REPUTATION_GAIN := 5
const BRIBE_MULTIPLIER := 0.75

var event_bus
var entities
var perception
var time
var factions
var schedules
var chunks
var inventory
var player
var allegiances
var crimes: Array[Dictionary] = []
var witness_memories: Dictionary = {}
var reports: Array[Dictionary] = []
var disposition_by_npc_id: Dictionary = {}
var pending_report_by_npc_id: Dictionary = {}
var guard_response_by_npc_id: Dictionary = {}
var bounty := 0
var jail_state: Dictionary = {}
var next_crime_number := 1


func setup(
	bus,
	entity_manager,
	perception_manager,
	time_manager,
	faction_manager,
	schedule_manager = null,
	chunk_manager = null,
	inventory_manager = null
) -> void:
	event_bus = bus
	entities = entity_manager
	perception = perception_manager
	time = time_manager
	factions = faction_manager
	schedules = schedule_manager
	chunks = chunk_manager
	inventory = inventory_manager
	if event_bus and event_bus.player_crime_committed.is_connected(_on_player_crime_committed) == false:
		event_bus.player_crime_committed.connect(_on_player_crime_committed)


func set_player(player_actor) -> void:
	player = player_actor


func set_allegiance_manager(manager) -> void:
	allegiances = manager


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	_process_pending_witnesses(delta)
	_process_guard_responses(delta)
	if is_player_jailed() and _absolute_minute() >= int(jail_state.get("release_absolute_minute", 0)):
		_finish_sentence()


func record_player_crime(event: Dictionary) -> Dictionary:
	var kind := String(event.get("kind", ""))
	if not REPUTATION_PENALTIES.has(kind):
		return {}
	var crime := event.duplicate(true)
	crime["id"] = "crime_%06d" % next_crime_number
	next_crime_number += 1
	crime["kind"] = kind
	crime["offender_id"] = String(event.get("offender_id", "player"))
	crime["absolute_minute"] = _absolute_minute()
	crime["world_layer"] = String(event.get("world_layer", "surface"))
	crime["world_position"] = _numeric_pair(event.get("world_position", []))
	crime["victim_entity_id"] = String(event.get("victim_entity_id", ""))
	crime["victim_npc_id"] = String(event.get("victim_npc_id", ""))
	crime["victim_faction_id"] = String(event.get("victim_faction_id", ""))
	crime["status"] = "unreported"
	var witness_entries := _witnesses_for_crime(crime)
	crime["witness_npc_ids"] = witness_entries.map(
		func(entry: Dictionary): return String(entry.get("npc_id", ""))
	)
	crimes.append(crime)
	for witness in witness_entries:
		_remember_crime(witness, crime)
		if _is_guard_witness(witness) and bool(witness.get("saw", false)):
			report_crime(String(witness.get("npc_id", "")), String(crime["id"]))
	if not witness_entries.is_empty() and event_bus:
		event_bus.post_message("Crime witnessed by %d NPC%s." % [
			witness_entries.size(), "" if witness_entries.size() == 1 else "s"
		])
	return get_crime(String(crime["id"]))


func report_crime(witness_npc_id: String, crime_id: String) -> bool:
	var index := _crime_index(crime_id)
	if index < 0 or witness_npc_id.is_empty():
		return false
	var crime: Dictionary = crimes[index]
	for report in reports:
		if String(report.get("crime_id", "")) == crime_id:
			return false
	var report := {
		"id": "report_%06d" % (reports.size() + 1),
		"crime_id": crime_id,
		"witness_npc_id": witness_npc_id,
		"kind": String(crime.get("kind", "")),
		"absolute_minute": _absolute_minute(),
		"status": "active"
	}
	reports.append(report)
	crime["status"] = "reported"
	crime["reported_by_npc_id"] = witness_npc_id
	crimes[index] = crime
	_apply_report_consequences(crime)
	_activate_guard_response(witness_npc_id, crime)
	pending_report_by_npc_id.erase(witness_npc_id)
	if event_bus:
		event_bus.crime_reported.emit(report.duplicate(true))
		event_bus.post_message(
			"%s reported. Bounty is now %dg." % [String(crime.get("kind", "Crime")).capitalize(), bounty]
		)
	return true


func get_crime(crime_id: String) -> Dictionary:
	var index := _crime_index(crime_id)
	return crimes[index].duplicate(true) if index >= 0 else {}


func get_witness_memory(npc_id: String) -> Array[Dictionary]:
	var value: Variant = witness_memories.get(npc_id, [])
	var result: Array[Dictionary] = []
	if value is Array:
		for entry in value:
			if entry is Dictionary:
				result.append(entry.duplicate(true))
	return result


func get_disposition(npc_id: String) -> int:
	return clampi(int(disposition_by_npc_id.get(npc_id, 0)), -100, 100)


func get_guard_response(npc_id: String) -> Dictionary:
	var value: Variant = guard_response_by_npc_id.get(npc_id, {})
	return value.duplicate(true) if value is Dictionary else {}


func is_player_jailed() -> bool:
	return bool(jail_state.get("active", false))


func sentence_remaining_hours() -> int:
	if not is_player_jailed():
		return 0
	return maxi(0, ceili(float(int(jail_state.get("release_absolute_minute", 0)) - _absolute_minute()) / 60.0))


func get_status_data() -> Dictionary:
	return {
		"bounty": bounty,
		"wanted": bounty > 0,
		"jailed": is_player_jailed(),
		"sentence_hours": sentence_remaining_hours(),
		"active_reports": _active_report_count()
	}


func area_status(world_layer: String) -> String:
	if world_layer == JAIL_LAYER:
		return "Restricted: Northgate Lockup"
	if world_layer.begins_with("interior:structure_northgate_") and world_layer.contains("home_plot"):
		return "Private property"
	return "Public area"


func resolve_guard_response(npc_id: String, response: String) -> Dictionary:
	var guard_response := get_guard_response(npc_id)
	if guard_response.is_empty():
		return {"ok": false, "message": "No guard is confronting you."}
	match response:
		"pay_fine":
			var fine := int(guard_response.get("fine", bounty))
			if fine <= 0 or not inventory or not inventory.has_item("item_gold_coin", fine):
				return {"ok": false, "message": "You cannot pay the %dg fine." % fine}
			inventory.remove_item("item_gold_coin", fine)
			_resolve_legal_response(npc_id)
			return {"ok": true, "message": "You pay %dg. The guard records the settlement." % fine}
		"bribe":
			var bribe := _bribe_cost(guard_response)
			if not inventory or not inventory.has_item("item_gold_coin", bribe):
				return {"ok": false, "message": "You cannot afford the %dg bribe." % bribe}
			inventory.remove_item("item_gold_coin", bribe)
			_resolve_legal_response(npc_id)
			return {"ok": true, "message": "The guard pockets %dg and closes the charge." % bribe}
		"submit":
			return _begin_jail_sentence(npc_id)
		"resist":
			var guard: Variant = _actor_for_npc(npc_id)
			if guard:
				_make_guard_hostile(guard)
				if allegiances and allegiances.has_method("alert_actor"):
					allegiances.alert_actor(guard)
			guard_response["state"] = "attacking"
			guard_response_by_npc_id[npc_id] = guard_response
			return {"ok": true, "message": "You resist arrest."}
	return {"ok": false, "message": "That response is unavailable."}


func pay_bounty() -> Dictionary:
	if bounty <= 0:
		return {"ok": false, "message": "You have no active bounty."}
	if not inventory or not inventory.has_item("item_gold_coin", bounty):
		return {"ok": false, "message": "You need %dg to settle the bounty." % bounty}
	var paid := bounty
	inventory.remove_item("item_gold_coin", paid)
	_resolve_legal_response("")
	return {"ok": true, "message": "You pay %dg and settle the active bounty." % paid}


func surrender_to_guard(npc_id: String) -> Dictionary:
	if bounty <= 0:
		return {"ok": false, "message": "There is no active charge to surrender for."}
	return _begin_jail_sentence(npc_id)


func serve_sentence() -> Dictionary:
	if not is_player_jailed():
		return {"ok": false, "message": "You are not serving a sentence."}
	var hours := sentence_remaining_hours()
	if hours > 0 and time and time.has_method("advance_hours"):
		time.advance_hours(hours)
	_finish_sentence()
	return {"ok": true, "message": "Sentence served. You are released outside the lockup."}


func make_amends() -> Dictionary:
	if bounty > 0:
		return {"ok": false, "message": "Settle your active bounty first."}
	var faction_id := _legal_faction_id()
	if faction_id.is_empty() or not factions or factions.get_reputation(faction_id) >= 0:
		return {"ok": false, "message": "No restitution is currently required."}
	if not inventory or not inventory.has_item("item_gold_coin", AMENDS_COST):
		return {"ok": false, "message": "Restitution costs %dg." % AMENDS_COST}
	inventory.remove_item("item_gold_coin", AMENDS_COST)
	factions.change_reputation(faction_id, AMENDS_REPUTATION_GAIN)
	for npc_id in disposition_by_npc_id:
		disposition_by_npc_id[npc_id] = clampi(get_disposition(String(npc_id)) + 10, -100, 100)
	return {"ok": true, "message": "You pay restitution. Local reputation improves."}


func can_make_amends() -> bool:
	var faction_id := _legal_faction_id()
	return (
		bounty <= 0
		and not faction_id.is_empty()
		and factions
		and factions.get_reputation(faction_id) < 0
	)


func has_active_report_for_faction(faction_id: String) -> bool:
	if faction_id.is_empty():
		return false
	for crime in crimes:
		if (
			String(crime.get("status", "")) == "reported"
			and String(crime.get("victim_faction_id", "")) == faction_id
		):
			return true
	return false


func get_save_data() -> Dictionary:
	return {
		"crimes": crimes.duplicate(true),
		"witness_memories": witness_memories.duplicate(true),
		"reports": reports.duplicate(true),
		"disposition_by_npc_id": disposition_by_npc_id.duplicate(true),
		"pending_report_by_npc_id": pending_report_by_npc_id.duplicate(true),
		"guard_response_by_npc_id": guard_response_by_npc_id.duplicate(true),
		"bounty": bounty,
		"jail_state": jail_state.duplicate(true),
		"next_crime_number": next_crime_number
	}


func load_save_data(data: Dictionary) -> void:
	crimes = _dictionary_array(data.get("crimes", []))
	witness_memories.clear()
	var saved_memories: Variant = data.get("witness_memories", {})
	if saved_memories is Dictionary:
		for npc_id in saved_memories:
			witness_memories[String(npc_id)] = _dictionary_array(saved_memories[npc_id])
	reports = _dictionary_array(data.get("reports", []))
	disposition_by_npc_id.clear()
	var dispositions: Variant = data.get("disposition_by_npc_id", {})
	if dispositions is Dictionary:
		for npc_id in dispositions:
			var value: Variant = dispositions[npc_id]
			if VariantFields.is_number(value):
				disposition_by_npc_id[String(npc_id)] = clampi(int(value), -100, 100)
	pending_report_by_npc_id = _dictionary_field(data.get("pending_report_by_npc_id", {}))
	guard_response_by_npc_id = _dictionary_field(data.get("guard_response_by_npc_id", {}))
	bounty = maxi(0, int(data.get("bounty", 0)))
	jail_state = _dictionary_field(data.get("jail_state", {}))
	if bool(jail_state.get("active", false)):
		jail_state["release_absolute_minute"] = maxi(
			_absolute_minute(), int(jail_state.get("release_absolute_minute", _absolute_minute()))
		)
	next_crime_number = maxi(int(data.get("next_crime_number", crimes.size() + 1)), crimes.size() + 1)


func _on_player_crime_committed(event: Dictionary) -> void:
	record_player_crime(event)


func _witnesses_for_crime(crime: Dictionary) -> Array[Dictionary]:
	var event := crime.duplicate(true)
	event["visible"] = true
	var excluded := [String(crime.get("victim_entity_id", ""))]
	event["excluded_entity_ids"] = excluded
	var witnesses: Array[Dictionary] = perception.perceive_event(event) if perception else []
	var victim: Variant = (
		entities.get_entity(String(crime.get("victim_entity_id", ""))) if entities else null
	)
	if victim and ActorRules.is_living_actor_data(victim.data):
		witnesses.append(
			{
				"entity_id": victim.get_entity_id(),
				"npc_id": String(victim.data.get("npc_id", victim.get_entity_id())),
				"sense": "victim",
				"saw": true,
				"heard": true
			}
		)
	return _unique_witnesses(witnesses)


func _remember_crime(witness: Dictionary, crime: Dictionary) -> void:
	var npc_id := String(witness.get("npc_id", ""))
	if npc_id.is_empty():
		return
	var memories: Array = witness_memories.get(npc_id, [])
	var identified_offender := bool(witness.get("saw", false)) or String(witness.get("sense", "")) == "victim"
	memories.append(
		{
			"crime_id": String(crime.get("id", "")),
			"kind": String(crime.get("kind", "")),
			"offender_id": String(crime.get("offender_id", "player")),
			"victim_npc_id": String(crime.get("victim_npc_id", "")),
			"world_position": crime.get("world_position", []),
			"world_layer": String(crime.get("world_layer", "surface")),
			"absolute_minute": int(crime.get("absolute_minute", 0)),
			"sense": String(witness.get("sense", "sight")),
			"identified_offender": identified_offender,
			"report_status": (
				"reported"
				if _is_guard_witness(witness) and identified_offender
				else ("needs_report" if identified_offender else "unknown_offender")
			)
		}
	)
	witness_memories[npc_id] = memories
	var penalty := int(DISPOSITION_PENALTIES.get(String(crime.get("kind", "")), 0))
	disposition_by_npc_id[npc_id] = clampi(get_disposition(npc_id) + penalty, -100, 100)
	if identified_offender and not _is_guard_witness(witness) and String(witness.get("sense", "")) != "victim":
		pending_report_by_npc_id[npc_id] = {
			"crime_id": String(crime.get("id", "")),
			"state": "fleeing_to_guard"
		}
		var actor: Variant = _actor_for_npc(npc_id)
		if actor:
			actor.data["witness_response"] = pending_report_by_npc_id[npc_id].duplicate(true)


func _apply_report_consequences(crime: Dictionary) -> void:
	var faction_id := String(crime.get("victim_faction_id", ""))
	var penalty := int(REPUTATION_PENALTIES.get(String(crime.get("kind", "")), 0))
	if factions and not faction_id.is_empty() and penalty != 0:
		factions.change_reputation(faction_id, penalty)
	bounty += _crime_bounty(String(crime.get("kind", "")))


func _activate_guard_response(guard_npc_id: String, crime: Dictionary) -> void:
	var guard: Variant = _actor_for_npc(guard_npc_id)
	if not guard or not _actor_is_guard(guard):
		guard = _nearest_guard_to_position(
			VariantFields.vector2_from_pair(crime.get("world_position", []), Vector2.ZERO),
			String(crime.get("world_layer", "surface"))
		)
	if not guard:
		return
	var npc_id := String(guard.data.get("npc_id", guard.get_entity_id()))
	var kind := String(crime.get("kind", ""))
	var action := "arrest" if kind in ["assault", "murder"] else "fine"
	var response := {
		"crime_id": String(crime.get("id", "")),
		"kind": kind,
		"action": action,
		"state": "investigating",
		"fine": _crime_bounty(kind),
		"bribe": _bribe_cost_for_bounty(_crime_bounty(kind)),
		"crime_world_position": crime.get("world_position", []),
		"crime_world_layer": String(crime.get("world_layer", "surface"))
	}
	guard_response_by_npc_id[npc_id] = response
	guard.data["guard_response"] = response.duplicate(true)


func _process_pending_witnesses(delta: float) -> void:
	for npc_id_value in pending_report_by_npc_id.keys():
		var npc_id := String(npc_id_value)
		var actor: Variant = _actor_for_npc(npc_id)
		if not actor:
			continue
		var guard: Variant = _nearest_guard_to_position(
			actor.global_position, String(actor.data.get("world_layer", "surface"))
		)
		if not guard:
			continue
		if actor.global_position.distance_to(guard.global_position) <= 28.0:
			report_crime(npc_id, String(pending_report_by_npc_id[npc_id].get("crime_id", "")))
			actor.data.erase("witness_response")
			continue
		actor.data["behavior_state"] = "fleeing_to_guard"
		actor.set_facing_direction(guard.global_position - actor.global_position)
		actor.try_move(guard.global_position - actor.global_position, delta, chunks, 112.0)


func _process_guard_responses(delta: float) -> void:
	if not player:
		return
	for npc_id_value in guard_response_by_npc_id.keys():
		var npc_id := String(npc_id_value)
		var response: Dictionary = guard_response_by_npc_id[npc_id]
		if String(response.get("state", "")) in ["resolved", "attacking", "confronting"]:
			continue
		var guard: Variant = _actor_for_npc(npc_id)
		if not guard or String(guard.data.get("world_layer", "surface")) != String(player.world_layer):
			continue
		if guard.global_position.distance_to(player.global_position) <= 32.0:
			response["state"] = "confronting"
			guard_response_by_npc_id[npc_id] = response
			guard.data["guard_response"] = response.duplicate(true)
			guard.data["behavior_state"] = "confronting_criminal"
			if event_bus:
				event_bus.post_message(_guard_confrontation_text(response))
			continue
		guard.data["behavior_state"] = "pursuing_criminal"
		guard.set_facing_direction(player.global_position - guard.global_position)
		guard.try_move(player.global_position - guard.global_position, delta, chunks, 96.0)


func _resolve_legal_response(npc_id: String) -> void:
	bounty = 0
	for index in range(reports.size()):
		if String(reports[index].get("status", "")) == "active":
			reports[index]["status"] = "resolved"
	_clear_guard_responses()


func _begin_jail_sentence(npc_id: String) -> Dictionary:
	if is_player_jailed():
		return {"ok": false, "message": "You are already serving a sentence."}
	var sentence_hours := clampi(maxi(8, ceili(float(maxi(1, bounty)) / 25.0) * 8), 8, 72)
	jail_state = {
		"active": true,
		"arresting_npc_id": npc_id,
		"started_absolute_minute": _absolute_minute(),
		"release_absolute_minute": _absolute_minute() + sentence_hours * 60,
		"sentence_hours": sentence_hours,
		"bounty_at_arrest": bounty
	}
	_clear_guard_responses()
	if event_bus:
		event_bus.player_jailed.emit(jail_state.merged({"target_layer": JAIL_LAYER, "target_tile": [JAIL_CELL_TILE.x, JAIL_CELL_TILE.y]}))
	return {"ok": true, "message": "You surrender and are taken to the Northgate Lockup for %dh." % sentence_hours}


func _finish_sentence() -> void:
	if not is_player_jailed():
		return
	jail_state["active"] = false
	jail_state["served_absolute_minute"] = _absolute_minute()
	_resolve_legal_response("")
	if event_bus:
		event_bus.player_released_from_jail.emit(
			{"target_layer": JAIL_RELEASE_LAYER, "target_tile": [JAIL_RELEASE_TILE.x, JAIL_RELEASE_TILE.y]}
		)


func _clear_guard_responses() -> void:
	for guard_npc_id in guard_response_by_npc_id:
		var guard: Variant = _actor_for_npc(String(guard_npc_id))
		if guard:
			guard.data.erase("guard_response")
	guard_response_by_npc_id.clear()


func _guard_confrontation_text(response: Dictionary) -> String:
	var kind := String(response.get("kind", "crime"))
	var fine := int(response.get("fine", bounty))
	if String(response.get("action", "")) == "arrest":
		return "Guard: You are wanted for %s. Surrender, pay what is owed, or resist." % kind
	return "Guard: The charge is %s. Pay the %dg fine, surrender, or resist." % [kind, fine]


func _active_report_count() -> int:
	var count := 0
	for report in reports:
		if String(report.get("status", "")) == "active":
			count += 1
	return count


func _legal_faction_id() -> String:
	for crime in crimes:
		var faction_id := String(crime.get("victim_faction_id", ""))
		if not faction_id.is_empty():
			return faction_id
	return ""


func _make_guard_hostile(guard) -> void:
	guard.data["hostility"] = "hostile"
	guard.data["hostile_to_player"] = true
	guard.data["combat_enabled"] = true
	guard.data["brain_id"] = "hostile_basic"
	guard.data["behavior_state"] = "chasing"
	guard.data["_brain_mode"] = "engaged"


func _crime_bounty(kind: String) -> int:
	return {"trespass": 5, "theft": 10, "assault": 25, "murder": 100}.get(kind, 0)


func _bribe_cost(response: Dictionary) -> int:
	return _bribe_cost_for_bounty(maxi(1, int(response.get("fine", bounty))))


func _bribe_cost_for_bounty(value: int) -> int:
	return maxi(1, ceili(float(maxi(1, value)) * BRIBE_MULTIPLIER))


func _actor_for_npc(npc_id: String):
	if not entities:
		return null
	for actor in entities.entities_by_id.values():
		if actor and String(actor.data.get("npc_id", actor.get_entity_id())) == npc_id:
			return actor
	return null


func _nearest_guard_to_position(position: Vector2, layer: String):
	var nearest = null
	var nearest_distance := INF
	if not entities:
		return null
	for actor in entities.entities_by_id.values():
		if not actor or not _actor_is_guard(actor) or String(actor.data.get("world_layer", "surface")) != layer:
			continue
		var distance: float = actor.global_position.distance_to(position)
		if distance < nearest_distance:
			nearest = actor
			nearest_distance = distance
	return nearest


func _actor_is_guard(actor) -> bool:
	if not actor or not (actor.data is Dictionary):
		return false
	var role := String(actor.data.get("role", actor.data.get("npc_role", ""))).to_lower()
	var npc_id := String(actor.data.get("npc_id", "")).to_lower()
	var schedule_id := String(actor.data.get("schedule_binding_id", "")).to_lower()
	return role.contains("guard") or npc_id.contains("guard") or schedule_id.contains("guard")


func _is_guard_witness(witness: Dictionary) -> bool:
	var entity = entities.get_entity(String(witness.get("entity_id", ""))) if entities else null
	if not entity:
		return false
	return _actor_is_guard(entity)


func _unique_witnesses(entries: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen := {}
	for entry in entries:
		var npc_id := String(entry.get("npc_id", ""))
		if npc_id.is_empty() or seen.has(npc_id):
			continue
		seen[npc_id] = true
		result.append(entry)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["npc_id"] < b["npc_id"])
	return result


func _crime_index(crime_id: String) -> int:
	for index in range(crimes.size()):
		if String(crimes[index].get("id", "")) == crime_id:
			return index
	return -1


func _absolute_minute() -> int:
	return int(time.day) * 1440 + int(time.minute_of_day) if time else 0


func _numeric_pair(value: Variant) -> Array:
	return VariantFields.numeric_pair(value)


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if value is Array:
		for entry in value:
			if entry is Dictionary:
				result.append(entry.duplicate(true))
	return result


func _dictionary_field(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}
