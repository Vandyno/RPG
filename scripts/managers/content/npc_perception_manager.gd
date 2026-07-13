class_name NpcPerceptionManager
extends Node

const ActorRules = preload("res://scripts/core/actor_rules.gd")
const NpcPerception = preload("res://scripts/core/npc_perception.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")

const RECENT_NOISE_SECONDS := 8.0
const SUSPICIOUS_THRESHOLD := 20.0
const DETECTED_THRESHOLD := 60.0
const HEARING_AWARENESS := 35.0
const SIGHT_AWARENESS := 100.0
const AWARENESS_DECAY_PER_SECOND := 6.0

var event_bus
var entities
var world_query
var time
var recent_noise_by_npc_id: Dictionary = {}
var awareness_by_npc_id: Dictionary = {}


func setup(bus, entity_manager, query, time_manager = null) -> void:
	event_bus = bus
	entities = entity_manager
	world_query = query
	time = time_manager
	if event_bus and event_bus.noise_emitted.is_connected(_on_noise_emitted) == false:
		event_bus.noise_emitted.connect(_on_noise_emitted)


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	for npc_id in recent_noise_by_npc_id.keys():
		var memory: Dictionary = recent_noise_by_npc_id[npc_id]
		memory["remaining_seconds"] = float(memory.get("remaining_seconds", 0.0)) - delta
		if float(memory["remaining_seconds"]) <= 0.0:
			recent_noise_by_npc_id.erase(npc_id)
		else:
			recent_noise_by_npc_id[npc_id] = memory
	for npc_id in awareness_by_npc_id.keys():
		var awareness: Dictionary = awareness_by_npc_id[npc_id]
		var score := maxf(0.0, float(awareness.get("score", 0.0)) - AWARENESS_DECAY_PER_SECOND * delta)
		awareness["score"] = score
		awareness["state"] = _awareness_state(score)
		if score <= 0.0:
			awareness_by_npc_id.erase(npc_id)
		else:
			awareness_by_npc_id[npc_id] = awareness


func perceive_event(event: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not entities:
		return result
	var origin := VariantFields.vector2_from_pair(event.get("world_position", []), Vector2.ZERO)
	var layer := String(event.get("world_layer", "surface"))
	var noise_radius := maxf(0.0, float(event.get("noise_radius", 0.0)))
	var context := {
		"target_sneaking": bool(event.get("target_sneaking", false)),
		"sneak_visibility": float(event.get("sneak_visibility", 0.55)),
		"light_level": _event_light_level(event, layer),
		"loudness": _event_loudness(event)
	}
	var excluded_ids := _string_set(event.get("excluded_entity_ids", []))
	for entity in entities.entities_by_id.values():
		if not entity or not (entity.data is Dictionary):
			continue
		var entity_id: String = entity.get_entity_id()
		if excluded_ids.has(entity_id) or not ActorRules.is_living_actor_data(entity.data):
			continue
		var saw := bool(event.get("visible", true)) and can_see_position(
			entity, origin, layer, context
		)
		var propagated_noise_radius := noise_radius
		if _closed_door_blocks(entity.global_position, origin, layer):
			propagated_noise_radius *= 0.45
		var heard := NpcPerception.can_hear(
			entity, origin, layer, propagated_noise_radius, world_query, context
		)
		if not saw and not heard:
			continue
		var perception := {
				"entity_id": entity_id,
				"npc_id": String(entity.data.get("npc_id", entity_id)),
				"sense": "sight" if saw else "hearing",
				"saw": saw,
				"heard": heard
			}
		result.append(perception)
		_register_awareness(perception, event)
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["entity_id"] < b["entity_id"])
	return result


func heard_recently(npc_id: String, source_id: String = "") -> bool:
	var memory: Dictionary = recent_noise_by_npc_id.get(npc_id, {})
	if memory.is_empty():
		return false
	return source_id.is_empty() or String(memory.get("source_id", "")) == source_id


func can_see(observer, target, context: Dictionary = {}) -> bool:
	if not target:
		return false
	var resolved := context.duplicate(true)
	var target_layer := _target_layer(target)
	resolved["light_level"] = float(resolved.get("light_level", _light_level_for_layer(target_layer)))
	if target.get("is_sneaking") is bool:
		resolved["target_sneaking"] = bool(target.get("is_sneaking"))
	return can_see_position(
		observer,
		target.global_position,
		target_layer,
		resolved
	)


func can_see_position(
	observer, target_position: Vector2, target_layer: String, context: Dictionary = {}
) -> bool:
	if not NpcPerception.can_see_position(observer, target_position, target_layer, world_query, context):
		return false
	return not _closed_door_blocks(observer.global_position, target_position, target_layer)


func update_awareness_of_target(observer, target) -> String:
	if not observer or not target:
		return "unaware"
	var npc_id := String(observer.data.get("npc_id", observer.get_entity_id()))
	if can_see(observer, target):
		_register_awareness(
			{"npc_id": npc_id, "entity_id": observer.get_entity_id(), "saw": true, "heard": false},
			{
				"source_id": "player",
				"world_position": [target.global_position.x, target.global_position.y],
				"world_layer": _target_layer(target)
			}
		)
	elif heard_recently(npc_id, "player"):
		var recent: Dictionary = recent_noise_by_npc_id.get(npc_id, {})
		_register_awareness(
			{"npc_id": npc_id, "entity_id": observer.get_entity_id(), "saw": false, "heard": true},
			recent
		)
	return get_awareness_state(npc_id)


func get_awareness_state(npc_id: String) -> String:
	return String(awareness_by_npc_id.get(npc_id, {}).get("state", "unaware"))


func get_awareness(npc_id: String) -> Dictionary:
	var value: Variant = awareness_by_npc_id.get(npc_id, {})
	return value.duplicate(true) if value is Dictionary else {}


func _on_noise_emitted(noise: Dictionary) -> void:
	for perception in perceive_event(noise):
		if not bool(perception.get("heard", false)):
			continue
		var npc_id := String(perception.get("npc_id", ""))
		recent_noise_by_npc_id[npc_id] = {
			"source_id": String(noise.get("source_id", "")),
			"kind": String(noise.get("kind", "noise")),
			"world_position": noise.get("world_position", []),
			"world_layer": String(noise.get("world_layer", "surface")),
			"remaining_seconds": RECENT_NOISE_SECONDS
		}
		if event_bus:
			event_bus.npc_perceived_event.emit(perception.merged(noise, false))


func _register_awareness(perception: Dictionary, event: Dictionary) -> void:
	var npc_id := String(perception.get("npc_id", ""))
	if npc_id.is_empty():
		return
	var awareness: Dictionary = awareness_by_npc_id.get(npc_id, {})
	var stimulus := SIGHT_AWARENESS if bool(perception.get("saw", false)) else HEARING_AWARENESS
	var score := maxf(float(awareness.get("score", 0.0)), stimulus)
	awareness["score"] = score
	awareness["state"] = _awareness_state(score)
	awareness["source_id"] = String(event.get("source_id", event.get("offender_id", "")))
	awareness["last_world_position"] = event.get("world_position", [])
	awareness["last_world_layer"] = String(event.get("world_layer", "surface"))
	awareness["last_sense"] = String(perception.get("sense", "sight"))
	awareness_by_npc_id[npc_id] = awareness


func _awareness_state(score: float) -> String:
	if score >= DETECTED_THRESHOLD:
		return "detected"
	if score >= SUSPICIOUS_THRESHOLD:
		return "suspicious"
	return "unaware"


func _event_loudness(event: Dictionary) -> float:
	var value: Variant = event.get("loudness", 1.0)
	if value is int or value is float:
		return maxf(0.0, float(value))
	match String(value).to_lower():
		"quiet":
			return 0.5
		"loud":
			return 1.5
		"very_loud":
			return 2.0
	return 1.0


func _event_light_level(event: Dictionary, layer: String) -> float:
	var value: Variant = event.get("light_level", null)
	if value is int or value is float:
		return clampf(float(value), 0.0, 1.0)
	return _light_level_for_layer(layer)


func _light_level_for_layer(layer: String) -> float:
	if layer.begins_with("interior:"):
		return 0.72
	if not time or not time.has_method("get_phase"):
		return 1.0
	match String(time.get_phase()).to_lower():
		"night":
			return 0.35
		"evening":
			return 0.7
	return 1.0


func _closed_door_blocks(from_position: Vector2, to_position: Vector2, layer: String) -> bool:
	if not entities:
		return false
	for entity in entities.entities_by_id.values():
		if (
			not entity
			or entity.get_kind() != "door"
			or String(entity.data.get("world_layer", "surface")) != layer
			or bool(entity.data.get("vision_transparent", false))
		):
			continue
		if _distance_to_segment(entity.global_position, from_position, to_position) > 12.0:
			continue
		var chunks = entities.get("chunk_manager")
		if not chunks or not chunks.has_method("is_object_opened"):
			return true
		if not chunks.is_object_opened(entity.get_entity_id(), entity.global_tile, layer):
			return true
	return false


func _distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	if segment.length_squared() <= 0.001:
		return point.distance_to(start)
	var ratio := clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * ratio)


func _target_layer(target) -> String:
	if target.has_method("get_world_layer"):
		return String(target.get_world_layer())
	var data: Variant = target.get("data")
	return String(data.get("world_layer", "surface")) if data is Dictionary else "surface"


func _string_set(value: Variant) -> Dictionary:
	var result := {}
	if value is Array:
		for item in value:
			var key := String(item)
			if not key.is_empty():
				result[key] = true
	return result
