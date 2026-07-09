class_name EntityManager
extends Node2D

const GridMath = preload("res://scripts/core/grid_math.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")
const WorldEntityScript = preload("res://scripts/world/world_entity.gd")
const DEFAULT_INTERACTION_RADIUS_PIXELS := 32.0
const DOOR_INTERACTION_RADIUS_PIXELS := 48.0
const NON_INTERACTIVE_KINDS := ["location"]

var event_bus: EventBus
var content: ContentDatabase
var chunk_manager: ChunkManager
var condition_evaluator: ConditionEvaluator
var inventory: InventoryManager
var entities_by_id: Dictionary = {}
var runtime_entities_by_id: Dictionary = {}
var entity_runtime_state_by_id: Dictionary = {}
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


func create_body_for_defeated_actor(entity) -> WorldEntity:
	if not entity or not (entity.data is Dictionary):
		return null
	var body_entry := _defeated_actor_body_entry(entity)
	if body_entry.is_empty():
		return null
	_seed_body_inventory(ActorRules.inventory_owner_id(entity.data), entity.data)
	return add_runtime_entity(body_entry)


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
	if not _conditions_pass(entry):
		return
	var entity_id := String(entry.get("id", ""))
	var spawn_entry := _entry_with_runtime_state(entity_id, entry)
	var tile := _tile_from_entry(spawn_entry)
	var layer := _world_layer_from_entry(spawn_entry)
	if not _is_in_active_chunk_window(tile, layer):
		return
	if chunk_manager.is_entity_removed(
		entity_id, _persistent_removal_tile_from_entry(spawn_entry), layer
	):
		return
	spawn_entry = _entry_with_filtered_equipment(_entry_with_profile(spawn_entry))
	var entity := WorldEntityScript.new()
	add_child(entity)
	entity.setup(spawn_entry, content)
	entities_by_id[entity_id] = entity


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


func _defeated_actor_body_entry(entity) -> Dictionary:
	var profile: Dictionary = ActorRules.profile(entity.data)
	var owner_id := ActorRules.inventory_owner_id(entity.data)
	if profile.is_empty() or owner_id.is_empty():
		return {}
	var body_profile := profile.duplicate(true)
	body_profile["state"] = ActorRules.STATE_DEAD_BODY
	var entity_id: String = entity.get_entity_id()
	return {
		"id": "body_%s" % entity_id,
		"name": "%s Body" % entity.get_display_name(),
		"kind": "body",
		"global_tile": [entity.global_tile.x, entity.global_tile.y],
		"interaction_radius": 128,
		"character_id": String(profile.get("character_id", "")),
		"character_profile_id": String(entity.data.get("character_profile_id", "")),
		"character_profile": body_profile,
		"inventory_owner_id": owner_id,
		"equipment_owner_id": ActorRules.equipment_owner_id(entity.data),
		"equipped_items": _dictionary_field(entity.data.get("equipped_items", {})),
		"collapsed_pose_id": "pose_fallen_side"
	}


func _seed_body_inventory(owner_id: String, data: Dictionary) -> void:
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
