class_name EntityManager
extends Node2D

const GridMath = preload("res://scripts/core/grid_math.gd")
const WorldEntityScript = preload("res://scripts/world/world_entity.gd")
const DEFAULT_INTERACTION_RADIUS_PIXELS := 32.0
const DOOR_INTERACTION_RADIUS_PIXELS := 48.0
const NON_INTERACTIVE_KINDS := ["location"]

var event_bus
var content
var chunk_manager
var condition_evaluator
var entities_by_id: Dictionary = {}
var highlighted_entity_id := ""
var active_chunk_keys: Dictionary = {}
var has_active_chunk_filter := false
var respawn_queued := false


func setup(bus, content_database, chunks, conditions = null) -> void:
	event_bus = bus
	content = content_database
	chunk_manager = chunks
	condition_evaluator = conditions
	if event_bus:
		event_bus.chunks_changed.connect(_on_chunks_changed)
		event_bus.world_flag_changed.connect(_queue_respawn)
		event_bus.quest_changed.connect(_queue_respawn)
		event_bus.readable_read.connect(_queue_respawn)
		event_bus.item_count_changed.connect(_queue_respawn)
		event_bus.faction_reputation_changed.connect(_queue_respawn)
		event_bus.progression_changed.connect(_queue_respawn)
		event_bus.time_changed.connect(_queue_respawn)
		event_bus.load_completed.connect(_queue_respawn)
	spawn_all()


func spawn_all() -> void:
	_clear_spawned_entities()
	entities_by_id.clear()
	highlighted_entity_id = ""
	var seen_ids: Dictionary = {}
	for entry in content.world_objects:
		var entity_id := String(entry.get("id", ""))
		if entity_id.is_empty() or seen_ids.has(entity_id) or not _has_valid_tile(entry):
			continue
		seen_ids[entity_id] = true
		if not _conditions_pass(entry):
			continue
		var tile := _tile_from_entry(entry)
		if not _is_in_active_chunk_window(tile):
			continue
		if chunk_manager.is_entity_removed(entity_id, tile):
			continue
		var entity := WorldEntityScript.new()
		add_child(entity)
		entity.setup(entry)
		entities_by_id[entity_id] = entity


func remove_entity(entity_id: String) -> void:
	var entity = entities_by_id.get(entity_id)
	if not entity:
		return
	chunk_manager.mark_entity_removed(entity_id, entity.global_tile)
	entities_by_id.erase(entity_id)
	if highlighted_entity_id == entity_id:
		highlighted_entity_id = ""
	remove_child(entity)
	entity.free()


func get_nearest_interactable(player_tile: Vector2i, max_distance: int = 1):
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
	return interactables[0]["entity"]


func get_nearest_interactable_world(
	world_position: Vector2, max_distance_pixels: float = DEFAULT_INTERACTION_RADIUS_PIXELS
):
	var interactables := get_interactables_world(world_position, max_distance_pixels)
	if interactables.is_empty():
		return null
	return interactables[0]


func get_interactable_at_world(world_position: Vector2, pick_radius_pixels: float = 28.0):
	var matches := []
	for entity_id in entities_by_id:
		var entity = entities_by_id[entity_id]
		if not _is_interactable(entity):
			continue
		var pick_distance: float = entity.get_pick_distance(world_position, pick_radius_pixels)
		if pick_distance < INF:
			matches.append({"entity": entity, "distance": pick_distance})
	_sort_entity_matches(matches)
	return null if matches.is_empty() else matches[0]["entity"]


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
		if not kind_filter.is_empty() and entity.get_kind() != kind_filter:
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


func get_entity(entity_id: String):
	return entities_by_id.get(entity_id)


func get_interaction_radius(entity, fallback: float = DEFAULT_INTERACTION_RADIUS_PIXELS) -> float:
	return _interaction_radius_for(entity, fallback)


func _clear_spawned_entities() -> void:
	for child in get_children():
		remove_child(child)
		child.free()


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


func _has_valid_tile(entry: Dictionary) -> bool:
	var tile: Variant = entry.get("global_tile", [])
	return tile is Array and tile.size() >= 2 and _is_number(tile[0]) and _is_number(tile[1])


func _tile_from_entry(entry: Dictionary) -> Vector2i:
	var tile: Array = entry.get("global_tile", [0, 0])
	return Vector2i(int(tile[0]), int(tile[1]))


func _is_in_active_chunk_window(tile: Vector2i) -> bool:
	if not has_active_chunk_filter:
		return true
	return active_chunk_keys.has(GridMath.chunk_key(GridMath.tile_to_chunk(tile)))


func _conditions_pass(entry: Dictionary) -> bool:
	var conditions: Variant = entry.get("conditions", [])
	if not conditions is Array or conditions.is_empty():
		return true
	return condition_evaluator and condition_evaluator.evaluate_all(conditions)


func _interaction_radius_for(entity, fallback: float) -> float:
	var value: Variant = entity.data.get("interaction_radius", fallback)
	if not _is_number(value) or float(value) <= 0.0:
		value = fallback
	var capped := minf(fallback, float(value))
	if entity.get_kind() == "door":
		return maxf(capped, DOOR_INTERACTION_RADIUS_PIXELS)
	return capped


func _is_interactable(entity) -> bool:
	return not NON_INTERACTIVE_KINDS.has(entity.get_kind())


func _sort_entity_matches(matches: Array) -> void:
	matches.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			var distance_a := float(a["distance"])
			var distance_b := float(b["distance"])
			if not is_equal_approx(distance_a, distance_b):
				return distance_a < distance_b
			return _entity_sort_key(a["entity"]) < _entity_sort_key(b["entity"])
	)


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
