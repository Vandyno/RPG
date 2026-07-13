class_name EntityManager
extends Node2D

const GridMath = preload("res://scripts/core/grid_math.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")
const WorldEntityScript = preload("res://scripts/world/world_entity.gd")
const DEFAULT_INTERACTION_RADIUS_PIXELS := 32.0
const DOOR_INTERACTION_RADIUS_PIXELS := 48.0
const NON_INTERACTIVE_KINDS := ["location", "fixture", "surface_detail"]

var event_bus: EventBus
var content: ContentDatabase
var chunk_manager: ChunkManager
var condition_evaluator: ConditionEvaluator
var inventory: InventoryManager
var entities_by_id: Dictionary = {}
var runtime_entities_by_id: Dictionary = {}
var entity_runtime_state_by_id: Dictionary = {}
var actor_life_state_by_id: Dictionary = {}
var container_inventory_seeded_by_id: Dictionary = {}
var highlighted_entity_id := ""
var active_chunk_keys: Dictionary = {}
var has_active_chunk_filter := false
var respawn_queued := false


func setup(
	bus: EventBus,
	content_database: ContentDatabase,
	chunks: ChunkManager,
	conditions: ConditionEvaluator = null,
	inventory_manager: InventoryManager = null
) -> void:
	event_bus = bus
	content = content_database
	chunk_manager = chunks
	condition_evaluator = conditions
	inventory = inventory_manager
	if event_bus:
		event_bus.chunks_changed.connect(_on_chunks_changed)
		event_bus.world_flag_changed.connect(_queue_respawn)
		event_bus.quest_changed.connect(_queue_respawn)
		event_bus.readable_read.connect(_queue_respawn)
		event_bus.item_count_changed.connect(_queue_respawn)
		event_bus.faction_reputation_changed.connect(_queue_respawn)
		event_bus.progression_changed.connect(_queue_respawn)
		event_bus.time_changed.connect(_queue_respawn)
		event_bus.load_completed.connect(_on_load_completed)


func spawn_all() -> void:
	_capture_live_runtime_state()
	_clear_spawned_entities()
	entities_by_id.clear()
	highlighted_entity_id = ""
	var seen_ids: Dictionary = {}
	for entry in content.world_object_entries():
		var entity_id := String(entry.get("id", ""))
		if entity_id.is_empty() or seen_ids.has(entity_id) or not _has_valid_tile(entry):
			continue
		seen_ids[entity_id] = true
		_spawn_entry(entry)
	for entity_id in runtime_entities_by_id:
		if seen_ids.has(entity_id):
			continue
		seen_ids[entity_id] = true
		_spawn_entry(runtime_entities_by_id[entity_id])


## Returns the spawned WorldEntity, or null when the entry has no valid id/tile
## or is outside spawn rules.
func add_runtime_entity(entry: Dictionary) -> WorldEntity:
	var entity_id := String(entry.get("id", ""))
	if entity_id.is_empty() or not _has_valid_tile(entry):
		return null
	runtime_entities_by_id[entity_id] = entry.duplicate(true)
	if entities_by_id.has(entity_id):
		remove_entity(entity_id)
	_spawn_entry(runtime_entities_by_id[entity_id])
	return entities_by_id.get(entity_id) as WorldEntity


func set_scheduled_entity_location(
	entity_id: String, tile: Vector2i, layer: String
) -> void:
	if entity_id.is_empty():
		return
	var resolved_layer := "surface" if layer.is_empty() else layer
	var state: Dictionary = _dictionary_field(
		entity_runtime_state_by_id.get(entity_id, {})
	).duplicate(true)
	var world_position := GridMath.tile_to_world(tile) + Vector2.ONE * float(GridMath.TILE_SIZE) * 0.5
	state["global_tile"] = [tile.x, tile.y]
	state["world_position"] = [world_position.x, world_position.y]
	state["world_layer"] = resolved_layer
	state["behavior_state"] = "scheduled"
	entity_runtime_state_by_id[entity_id] = state
	_queue_respawn()


func transition_actor_to_dead(entity) -> WorldEntity:
	if not entity or not (entity.data is Dictionary):
		return null
	if not ActorRules.is_actor_data(entity.data):
		return null
	var entity_id: String = entity.get_entity_id()
	var previous: Dictionary = _dictionary_field(actor_life_state_by_id.get(entity_id, {}))
	if not bool(previous.get("inventory_seeded", false)):
		_seed_actor_inventory(ActorRules.inventory_owner_id(entity.data), entity.data)
	entity.set_actor_state(ActorRules.STATE_DEAD)
	actor_life_state_by_id[entity_id] = _actor_life_state_snapshot(entity, true)
	_emit_actor_state_changed(entity)
	return entity


func set_actor_alive(entity_id: String) -> WorldEntity:
	var entity := get_entity(entity_id)
	if not entity:
		return null
	var previous: Dictionary = _dictionary_field(actor_life_state_by_id.get(entity_id, {}))
	entity.set_actor_state(ActorRules.STATE_ALIVE)
	actor_life_state_by_id[entity_id] = _actor_life_state_snapshot(
		entity, bool(previous.get("inventory_seeded", false))
	)
	_emit_actor_state_changed(entity)
	return entity


func persist_actor_state(entity) -> void:
	if not entity or not (entity.data is Dictionary) or not ActorRules.is_actor_data(entity.data):
		return
	var previous: Dictionary = _dictionary_field(actor_life_state_by_id.get(entity.get_entity_id(), {}))
	actor_life_state_by_id[entity.get_entity_id()] = _actor_life_state_snapshot(
		entity, bool(previous.get("inventory_seeded", false))
	)


func set_actor_location(entity_id: String, tile: Vector2i, layer: String) -> void:
	if entity_id.is_empty():
		return
	var actor := get_entity(entity_id)
	if actor:
		actor.set_world_layer(layer)
		actor.set_global_tile(tile)
		persist_actor_state(actor)
	else:
		var state: Dictionary = _dictionary_field(actor_life_state_by_id.get(entity_id, {})).duplicate(true)
		if state.is_empty():
			return
		var position := GridMath.tile_to_world(tile) + Vector2.ONE * float(GridMath.TILE_SIZE) * 0.5
		state["global_tile"] = [tile.x, tile.y]
		state["world_position"] = [position.x, position.y]
		state["world_layer"] = "surface" if layer.is_empty() else layer
		actor_life_state_by_id[entity_id] = state
	_queue_respawn()


func get_actor_state(entity_id: String) -> String:
	var entity := get_entity(entity_id)
	if entity:
		return ActorRules.actor_state(entity.data)
	var saved: Dictionary = _dictionary_field(actor_life_state_by_id.get(entity_id, {}))
	return String(saved.get("state", ActorRules.STATE_ALIVE))


func is_npc_dead(npc_id: String) -> bool:
	if npc_id.is_empty():
		return false
	for entity in entities_by_id.values():
		if String(entity.data.get("npc_id", "")) == npc_id:
			return ActorRules.is_dead_actor_data(entity.data)
	for saved in actor_life_state_by_id.values():
		if saved is Dictionary and String(saved.get("npc_id", "")) == npc_id:
			return ActorRules.DEAD_STATES.has(String(saved.get("state", "")))
	return false


func get_save_data() -> Dictionary:
	_capture_live_runtime_state()
	return {
		"actor_life_states": actor_life_state_by_id.duplicate(true),
		"container_inventory_seeded_by_id": container_inventory_seeded_by_id.duplicate(true)
	}


func load_save_data(data: Dictionary) -> void:
	actor_life_state_by_id.clear()
	container_inventory_seeded_by_id.clear()
	var saved_container_seeds: Variant = data.get("container_inventory_seeded_by_id", {})
	if saved_container_seeds is Dictionary:
		for entity_id in saved_container_seeds:
			if bool(saved_container_seeds[entity_id]):
				container_inventory_seeded_by_id[String(entity_id)] = true
	var saved_states: Variant = data.get("actor_life_states", {})
	if saved_states is Dictionary:
		for entity_id in saved_states:
			var saved: Variant = saved_states[entity_id]
			if not saved is Dictionary:
				continue
			var state := String(saved.get("state", ""))
			if not ActorRules.VALID_STATES.has(state):
				continue
			actor_life_state_by_id[String(entity_id)] = saved.duplicate(true)
	_clear_spawned_entities()
	entities_by_id.clear()
	spawn_all()


func remove_entity(entity_id: String) -> void:
	var entity = entities_by_id.get(entity_id)
	if not entity:
		return
	chunk_manager.mark_entity_removed(
		entity_id, _persistent_removal_tile(entity), _world_layer_from_entry(entity.data)
	)
	entity_runtime_state_by_id.erase(entity_id)
	entities_by_id.erase(entity_id)
	if highlighted_entity_id == entity_id:
		highlighted_entity_id = ""
	remove_child(entity)
	entity.free()


## Returns the nearest interactable WorldEntity, or null when none is in tile range.
func get_nearest_interactable(player_tile: Vector2i, max_distance: int = 1) -> WorldEntity:
	var interactables := []
	for entity_id in entities_by_id:
		var entity = entities_by_id[entity_id]
		if not _is_interactable(entity):
			continue
		var distance := GridMath.manhattan_distance(player_tile, entity.global_tile)
		if distance <= max_distance:
			interactables.append({"entity": entity, "distance": float(distance)})
	_sort_entity_matches(interactables)
	if interactables.is_empty():
		return null
	return interactables[0]["entity"] as WorldEntity


## Returns the nearest interactable WorldEntity, or null when none is in pixel range.
func get_nearest_interactable_world(
	world_position: Vector2, max_distance_pixels: float = DEFAULT_INTERACTION_RADIUS_PIXELS
) -> WorldEntity:
	var interactables := get_interactables_world(world_position, max_distance_pixels)
	if interactables.is_empty():
		return null
	return interactables[0] as WorldEntity


## Returns the picked interactable WorldEntity, or null when no hit is within the pick radius.
func get_interactable_at_world(
	world_position: Vector2, pick_radius_pixels: float = 28.0
) -> WorldEntity:
	var matches := []
	for entity_id in entities_by_id:
		var entity = entities_by_id[entity_id]
		if not _is_interactable(entity):
			continue
		var pick_match := _entity_pick_match(entity, world_position, pick_radius_pixels)
		var pick_distance: float = float(pick_match.get("distance", INF))
		if pick_distance < INF:
			matches.append(
				{
					"entity": entity,
					"distance": pick_distance,
					"pick_kind": String(pick_match.get("kind", "")),
					"selected_hint": bool(pick_match.get("selected", false))
				}
			)
	_sort_pick_matches(matches)
	if matches.is_empty():
		return null
	return matches[0]["entity"] as WorldEntity


func get_interactables_world(
	world_position: Vector2, max_distance_pixels: float = DEFAULT_INTERACTION_RADIUS_PIXELS
) -> Array:
	var interactables := []
	for entity_id in entities_by_id:
		var entity = entities_by_id[entity_id]
		if not _is_interactable(entity):
			continue
		var distance := world_position.distance_to(entity.global_position)
		if distance <= _interaction_radius_for(entity, max_distance_pixels):
			interactables.append({"entity": entity, "distance": distance})
	_sort_entity_matches(interactables)

	var result := []
	for entry in interactables:
		result.append(entry["entity"])
	return result


func get_entities_world(
	world_position: Vector2,
	max_distance_pixels: float = DEFAULT_INTERACTION_RADIUS_PIXELS,
	kind_filter: String = ""
) -> Array:
	var matches := []
	for entity_id in entities_by_id:
		var entity = entities_by_id[entity_id]
		if not _matches_kind_filter(entity, kind_filter):
			continue
		var distance := world_position.distance_to(entity.global_position)
		if distance <= max_distance_pixels:
			matches.append({"entity": entity, "distance": distance})
	_sort_entity_matches(matches)

	var result := []
	for entry in matches:
		result.append(entry["entity"])
	return result


func get_navigation_summary(
	world_position: Vector2, max_distance_pixels: float = DEFAULT_INTERACTION_RADIUS_PIXELS
) -> String:
	var interactables := get_interactables_world(world_position, max_distance_pixels)
	if interactables.is_empty():
		return "none"
	var lines: Array[String] = []
	for entity in interactables:
		lines.append(
			"%s %s" % [get_navigation_hint(world_position, entity), entity.get_display_name()]
		)
	return "\n".join(lines)


func get_navigation_hint(world_position: Vector2, entity) -> String:
	if not entity:
		return ""
	var delta: Vector2 = entity.global_position - world_position
	return "%s %.1ft" % [_direction_label(delta), delta.length() / GridMath.TILE_SIZE]


func set_highlighted_entity(entity_id: String) -> void:
	if highlighted_entity_id == entity_id:
		return
	if entities_by_id.has(highlighted_entity_id):
		entities_by_id[highlighted_entity_id].set_highlighted(false)
	highlighted_entity_id = entity_id
	if entities_by_id.has(highlighted_entity_id):
		entities_by_id[highlighted_entity_id].set_highlighted(true)


func set_action_hints(hints_by_entity_id: Dictionary) -> void:
	for entity_id in entities_by_id:
		var entity = entities_by_id[entity_id]
		var hint: Variant = hints_by_entity_id.get(entity_id, {})
		if hint is Dictionary and not hint.is_empty():
			var offset_y := 0.0
			var offset_value: Variant = hint.get("offset_y", 0.0)
			if _is_number(offset_value):
				offset_y = float(offset_value)
			entity.set_action_hint(
				true, String(hint.get("text", "")), bool(hint.get("selected", false)), offset_y
			)
		else:
			entity.set_action_hint(false)


func set_quest_markers(markers_by_entity_id: Dictionary) -> void:
	for entity_id in entities_by_id:
		var entity = entities_by_id[entity_id]
		var marker: Variant = markers_by_entity_id.get(entity_id, {})
		if marker is Dictionary and not marker.is_empty():
			entity.set_quest_marker(true, String(marker.get("text", "Quest")))
		else:
			entity.set_quest_marker(false)


## Returns the live WorldEntity for entity_id, or null when it is not currently spawned.
func get_entity(entity_id: String) -> WorldEntity:
	return entities_by_id.get(entity_id) as WorldEntity


func refresh_equipment_for_owner(owner_id: String) -> void:
	if owner_id.is_empty():
		return
	for entity_id in entities_by_id:
		var entity = entities_by_id[entity_id]
		if not _entry_matches_equipment_owner(entity.data, owner_id):
			continue
		if not entity.data.has("_authored_equipped_items"):
			entity.data["_authored_equipped_items"] = _dictionary_field(
				entity.data.get("equipped_items", {})
			)
		var equipped := _filtered_equipped_items(entity.data)
		entity.data["equipped_items"] = equipped
		if entity.humanoid_avatar:
			entity.humanoid_avatar.set_equipped_items(equipped, content)


func get_interaction_radius(entity, fallback: float = DEFAULT_INTERACTION_RADIUS_PIXELS) -> float:
	return _interaction_radius_for(entity, fallback)


func _clear_spawned_entities() -> void:
	for child in get_children():
		remove_child(child)
		child.free()


func _spawn_entry(entry: Dictionary) -> void:
	var entity_id := String(entry.get("id", ""))
	var has_saved_life_state := actor_life_state_by_id.has(entity_id)
	if not has_saved_life_state and not _conditions_pass(entry):
		return
	var spawn_entry := _entry_with_runtime_state(entity_id, entry)
	spawn_entry = _entry_with_actor_life_state(entity_id, spawn_entry)
	var tile := _tile_from_entry(spawn_entry)
	var layer := _world_layer_from_entry(spawn_entry)
	if not _is_in_active_chunk_window(tile, layer):
		return
	if chunk_manager.is_entity_removed(
		entity_id, _persistent_removal_tile_from_entry(spawn_entry), layer
	):
		return
	spawn_entry = _entry_with_filtered_equipment(_entry_with_profile(spawn_entry))
	spawn_entry = _entry_with_schedule_binding(spawn_entry)
	var entity := WorldEntityScript.new()
	add_child(entity)
	entity.setup(spawn_entry, content)
	entities_by_id[entity_id] = entity
	_seed_container_inventory_once(entity_id, spawn_entry)


func _on_chunks_changed(loaded_chunks: Array) -> void:
	active_chunk_keys.clear()
	for chunk_key in loaded_chunks:
		var key := String(chunk_key)
		if not key.is_empty():
			active_chunk_keys[key] = true
	has_active_chunk_filter = true
	spawn_all()


func _queue_respawn(_a = null, _b = null, _c = null, _d = null) -> void:
	if respawn_queued:
		return
	respawn_queued = true
	call_deferred("_respawn_after_state_change")


func _respawn_after_state_change() -> void:
	respawn_queued = false
	spawn_all()


func _on_load_completed(_path: String = "") -> void:
	entity_runtime_state_by_id.clear()
	spawn_all()


func _has_valid_tile(entry: Dictionary) -> bool:
	var tile: Variant = entry.get("global_tile", [])
	return tile is Array and tile.size() >= 2 and _is_number(tile[0]) and _is_number(tile[1])


func _tile_from_entry(entry: Dictionary) -> Vector2i:
	var tile: Array = entry.get("global_tile", [0, 0])
	return Vector2i(int(tile[0]), int(tile[1]))


func _persistent_removal_tile(entity) -> Vector2i:
	if not entity or not (entity.data is Dictionary):
		return Vector2i.ZERO
	return _persistent_removal_tile_from_entry(entity.data)


func _persistent_removal_tile_from_entry(entry: Dictionary) -> Vector2i:
	var tile: Variant = entry.get("_spawn_global_tile", entry.get("home_tile", []))
	if tile is Array and tile.size() >= 2 and _is_number(tile[0]) and _is_number(tile[1]):
		return Vector2i(int(tile[0]), int(tile[1]))
	return _tile_from_entry(entry)


func _is_in_active_chunk_window(tile: Vector2i, layer: String = "surface") -> bool:
	if not has_active_chunk_filter:
		return true
	return active_chunk_keys.has(GridMath.chunk_key(GridMath.tile_to_chunk(tile), layer))


func _world_layer_from_entry(entry: Dictionary) -> String:
	var layer := String(entry.get("world_layer", "surface"))
	return "surface" if layer.is_empty() else layer


func _conditions_pass(entry: Dictionary) -> bool:
	var conditions: Variant = entry.get("conditions", [])
	if not conditions is Array or conditions.is_empty():
		return true
	return condition_evaluator and condition_evaluator.evaluate_all(conditions)


func _capture_live_runtime_state() -> void:
	for entity_id in entities_by_id:
		var entity = entities_by_id[entity_id]
		if not entity or not (entity.data is Dictionary):
			continue
		if ActorRules.is_dead_actor_data(entity.data) or actor_life_state_by_id.has(String(entity_id)):
			var previous: Dictionary = _dictionary_field(
				actor_life_state_by_id.get(String(entity_id), {})
			)
			actor_life_state_by_id[String(entity_id)] = _actor_life_state_snapshot(
				entity, bool(previous.get("inventory_seeded", false))
			)
			continue
		if not _should_capture_runtime_state(entity.data):
			continue
		var state := {
			"global_tile": [entity.global_tile.x, entity.global_tile.y],
			"world_position": [entity.global_position.x, entity.global_position.y],
			"world_layer": _world_layer_from_entry(entity.data)
		}
		if entity.data.has("_spawn_global_tile"):
			state["_spawn_global_tile"] = entity.data["_spawn_global_tile"]
		if entity.data.has("behavior_state"):
			state["behavior_state"] = entity.data["behavior_state"]
		if entity.data.has("_brain_attack_cooldown"):
			state["_brain_attack_cooldown"] = entity.data["_brain_attack_cooldown"]
		if entity.has_method("get_facing_direction"):
			var facing: Vector2 = entity.get_facing_direction()
			state["facing_direction"] = [facing.x, facing.y]
		entity_runtime_state_by_id[String(entity_id)] = state


func _entry_with_runtime_state(entity_id: String, entry: Dictionary) -> Dictionary:
	var state := _dictionary_field(entity_runtime_state_by_id.get(entity_id, {}))
	if state.is_empty():
		return entry
	var next_entry := entry.duplicate(true)
	for key in state:
		next_entry[key] = state[key]
	return next_entry


func _entry_with_actor_life_state(entity_id: String, entry: Dictionary) -> Dictionary:
	var saved := _dictionary_field(actor_life_state_by_id.get(entity_id, {}))
	if saved.is_empty():
		return entry
	var next_entry := entry.duplicate(true)
	for key in [
		"state", "global_tile", "world_position", "world_layer", "facing_direction",
		"allegiance", "allegiance_owner_id", "companion_command", "companion_restore",
		"brain_id", "schedule_brain_id", "schedule_suspended", "hostility",
		"hostile_to_player", "combat_enabled", "behavior_state"
	]:
		if saved.has(key):
			next_entry[key] = saved[key]
	return next_entry


func _should_capture_runtime_state(data: Dictionary) -> bool:
	if not ActorRules.is_living_actor_data(data):
		return false
	return bool(data.get("_runtime_moved", false)) or not String(data.get("brain_id", "")).is_empty()


func _entry_with_profile(entry: Dictionary) -> Dictionary:
	var profile_value: Variant = entry.get("character_profile", {})
	if profile_value is Dictionary and not profile_value.is_empty():
		return entry
	if not content:
		return entry
	if not content.has_method("get_resolved_character_profile"):
		return entry
	var profile_id := String(entry.get("character_profile_id", ""))
	var should_use_npc_profile := profile_id.is_empty() and String(entry.get("kind", "")) == "npc"
	if should_use_npc_profile and content.has_method("get_npc"):
		var npc: Dictionary = content.get_npc(String(entry.get("npc_id", "")))
		profile_id = String(npc.get("character_profile_id", ""))
	if profile_id.is_empty():
		return entry
	var profile: Dictionary = content.get_resolved_character_profile(profile_id)
	if profile.is_empty():
		return entry
	var next_entry := entry.duplicate(true)
	next_entry["character_profile_id"] = profile_id
	next_entry["character_profile"] = profile
	return next_entry


func _entry_with_schedule_binding(entry: Dictionary) -> Dictionary:
	if not content or String(entry.get("kind", "")) != "npc":
		return entry
	if not content.has_method("get_schedule_binding_for_npc"):
		return entry
	if ["companion", "thrall"].has(String(entry.get("allegiance", ""))):
		return entry
	var binding: Dictionary = content.get_schedule_binding_for_npc(String(entry.get("npc_id", "")))
	if binding.is_empty():
		return entry
	var next_entry := entry.duplicate(true)
	next_entry["brain_id"] = "civilian_schedule"
	next_entry["schedule_brain_id"] = "civilian_schedule"
	next_entry["schedule_binding_id"] = String(binding.get("id", ""))
	next_entry["hostility"] = "neutral"
	# Civilians are not combat targets while neutral, but they remain damageable
	# so an attack can trigger a defensive reaction.
	next_entry["combat_enabled"] = true
	return next_entry


func _actor_life_state_snapshot(entity, inventory_seeded: bool) -> Dictionary:
	var state := {
		"state": ActorRules.actor_state(entity.data),
		"npc_id": String(entity.data.get("npc_id", "")),
		"global_tile": [entity.global_tile.x, entity.global_tile.y],
		"world_position": [entity.global_position.x, entity.global_position.y],
		"world_layer": _world_layer_from_entry(entity.data),
		"inventory_seeded": inventory_seeded
	}
	if entity.has_method("get_facing_direction"):
		var facing: Vector2 = entity.get_facing_direction()
		state["facing_direction"] = [facing.x, facing.y]
	for key in [
		"allegiance", "allegiance_owner_id", "companion_command", "companion_restore",
		"brain_id", "schedule_brain_id", "schedule_suspended", "hostility",
		"hostile_to_player", "combat_enabled", "behavior_state"
	]:
		if entity.data.has(key):
			state[key] = entity.data[key]
	return state


func _seed_actor_inventory(owner_id: String, data: Dictionary) -> void:
	if owner_id.is_empty() or not inventory:
		return
	for entry in _array_field(data.get("inventory", [])):
		if not entry is Dictionary:
			continue
		var item_id := String(entry.get("item_id", ""))
		var count := _positive_int_value(entry.get("count", 1), 1)
		inventory.add_item_to_owner(owner_id, item_id, count)
	for item_id_value in _dictionary_field(data.get("equipped_items", {})).values():
		var item_id := String(item_id_value)
		if not item_id.is_empty():
			inventory.add_item_to_owner(owner_id, item_id, 1)


func _seed_container_inventory_once(entity_id: String, data: Dictionary) -> void:
	if (
		entity_id.is_empty()
		or String(data.get("kind", "")) != "container"
		or container_inventory_seeded_by_id.has(entity_id)
		or not inventory
	):
		return
	var owner_id := String(data.get("inventory_owner_id", ""))
	if owner_id.is_empty():
		return
	for entry in _array_field(data.get("inventory", [])):
		if not entry is Dictionary:
			continue
		var item_id := String(entry.get("item_id", ""))
		var count := _positive_int_value(entry.get("count", 1), 1)
		inventory.add_item_to_owner(owner_id, item_id, count)
	container_inventory_seeded_by_id[entity_id] = true


func _emit_actor_state_changed(entity) -> void:
	if not event_bus or not event_bus.has_signal("actor_state_changed") or not entity:
		return
	event_bus.actor_state_changed.emit(
		entity.get_entity_id(),
		String(entity.data.get("npc_id", entity.get_entity_id())),
		ActorRules.actor_state(entity.data)
	)


func _entry_with_filtered_equipment(entry: Dictionary) -> Dictionary:
	var equipped := _filtered_equipped_items(entry)
	if equipped == _dictionary_field(entry.get("equipped_items", {})):
		return entry
	var next_entry := entry.duplicate(true)
	next_entry["_authored_equipped_items"] = _base_equipped_items(entry)
	next_entry["equipped_items"] = equipped
	return next_entry


func _filtered_equipped_items(entry: Dictionary) -> Dictionary:
	var equipped := _base_equipped_items(entry)
	if equipped.is_empty() or not inventory or not inventory.has_method("get_items_for_owner"):
		return equipped.duplicate(true)
	var owner_id := _entry_inventory_owner_id(entry)
	if owner_id.is_empty():
		return equipped.duplicate(true)
	var owner_inventory_known := false
	if inventory.has_method("has_inventory_for_owner"):
		owner_inventory_known = inventory.has_inventory_for_owner(owner_id)
		if not owner_inventory_known:
			return equipped.duplicate(true)
	var owner_items: Dictionary = inventory.get_items_for_owner(owner_id)
	if owner_items.is_empty() and not owner_inventory_known:
		return equipped.duplicate(true)
	var filtered := {}
	for slot_id in equipped:
		var item_id := String(equipped[slot_id])
		if inventory.has_item_for_owner(owner_id, item_id, 1):
			filtered[slot_id] = item_id
	return filtered


func _base_equipped_items(entry: Dictionary) -> Dictionary:
	var authored := _dictionary_field(entry.get("_authored_equipped_items", {}))
	if not authored.is_empty():
		return authored
	return _dictionary_field(entry.get("equipped_items", {}))


func _entry_matches_equipment_owner(entry: Dictionary, owner_id: String) -> bool:
	if ActorRules.equipment_owner_id(entry) == owner_id:
		return true
	if _entry_inventory_owner_id(entry) == owner_id:
		return true
	return false


func _entry_inventory_owner_id(entry: Dictionary) -> String:
	return ActorRules.inventory_owner_id(entry)


func _interaction_radius_for(entity, fallback: float) -> float:
	var value: Variant = entity.data.get("interaction_radius", fallback)
	if not _is_number(value) or float(value) <= 0.0:
		value = fallback
	var capped := minf(fallback, float(value))
	if entity.get_kind() == "door":
		return maxf(capped, DOOR_INTERACTION_RADIUS_PIXELS)
	return capped


func _is_interactable(entity) -> bool:
	if NON_INTERACTIVE_KINDS.has(entity.get_kind()):
		return false
	if _is_combat_entity(entity):
		return false
	return true


func _matches_kind_filter(entity, kind_filter: String) -> bool:
	if kind_filter.is_empty():
		return true
	if ["enemy", "hostile", "combat"].has(kind_filter):
		return ActorRules.is_combat_target_entity(entity)
	return entity.get_kind() == kind_filter


func _is_combat_entity(entity) -> bool:
	return ActorRules.is_combat_target_entity(entity)


func _sort_entity_matches(matches: Array) -> void:
	matches.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var distance_a := float(a["distance"])
			var distance_b := float(b["distance"])
			if not is_equal_approx(distance_a, distance_b):
				return distance_a < distance_b
			return _entity_sort_key(a["entity"]) < _entity_sort_key(b["entity"])
	)


func _sort_pick_matches(matches: Array) -> void:
	matches.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var rank_a := _pick_rank(a)
			var rank_b := _pick_rank(b)
			if rank_a != rank_b:
				return rank_a < rank_b
			var distance_a := float(a["distance"])
			var distance_b := float(b["distance"])
			if not is_equal_approx(distance_a, distance_b):
				return distance_a < distance_b
			return _entity_sort_key(a["entity"]) < _entity_sort_key(b["entity"])
	)


func _pick_rank(match: Dictionary) -> int:
	var kind := String(match.get("pick_kind", ""))
	var distance := float(match.get("distance", INF))
	if kind == "body" and distance <= 12.0:
		return 0
	if kind == "hint" and bool(match.get("selected_hint", false)):
		return 1
	if kind == "hint":
		return 2
	if kind == "quest":
		return 3
	return 4


func _entity_pick_match(entity, world_position: Vector2, pick_radius_pixels: float) -> Dictionary:
	if entity and entity.has_method("get_pick_match"):
		return entity.get_pick_match(world_position, pick_radius_pixels)
	return {"distance": entity.get_pick_distance(world_position, pick_radius_pixels), "kind": "body"}


func _entity_sort_key(entity) -> String:
	return "%s:%s" % [entity.get_display_name(), entity.get_entity_id()]


func _direction_label(delta: Vector2) -> String:
	if delta.length() < 1.0:
		return "Here"
	var vertical := ""
	var horizontal := ""
	if delta.y < -GridMath.TILE_SIZE * 0.35:
		vertical = "N"
	elif delta.y > GridMath.TILE_SIZE * 0.35:
		vertical = "S"
	if delta.x < -GridMath.TILE_SIZE * 0.35:
		horizontal = "W"
	elif delta.x > GridMath.TILE_SIZE * 0.35:
		horizontal = "E"
	return vertical + horizontal if not (vertical + horizontal).is_empty() else "Here"


func _is_number(value: Variant) -> bool:
	return value is int or value is float


func _array_field(value: Variant) -> Array:
	return value if value is Array else []


func _dictionary_field(value: Variant) -> Dictionary:
	return value.duplicate(true) if value is Dictionary else {}


func _positive_int_value(value: Variant, fallback: int) -> int:
	if not (value is int or value is float):
		return maxi(1, fallback)
	return maxi(1, int(value))
