class_name ChunkManager
extends Node

const GridMath = preload("res://scripts/core/grid_math.gd")

const SPAWN_TOWN_MIN := Vector2i(-12, -10)
const SPAWN_TOWN_MAX := Vector2i(14, 10)
const RIVER_X := [-4, -3]
const BRIDGE_Y := [-2, -1, 0, 1, 2, 3, 4]
const GATE_WIDTH := [0, 1]
const BLOCKED_TILE_KINDS := ["water", "stone_wall", "wood_wall"]

var modified_chunks: Dictionary = {}


func get_chunk_data(chunk_coord: Vector2i, layer: String = "surface") -> Dictionary:
	var key := GridMath.chunk_key(chunk_coord, layer)
	return {
		"id": key,
		"layer": layer,
		"chunk_coord": [chunk_coord.x, chunk_coord.y],
		"chunk_size": GridMath.CHUNK_SIZE,
		"tiles": _generate_tiles(chunk_coord)
	}


func get_tile_kind(global_tile: Vector2i) -> String:
	var town_kind := _spawn_town_tile_kind(global_tile)
	if not town_kind.is_empty():
		return town_kind

	if global_tile.x == 0 or global_tile.y == 0 or global_tile.x == global_tile.y:
		return "road"

	var n := _hash_noise(global_tile)
	if n < 8:
		return "water"
	if n < 18:
		return "forest"
	if n < 26:
		return "hill"
	return "grass"


func is_walkable(global_tile: Vector2i) -> bool:
	return not BLOCKED_TILE_KINDS.has(get_tile_kind(global_tile))


func mark_entity_removed(entity_id: String, tile: Vector2i, layer: String = "surface") -> void:
	if entity_id.is_empty():
		return
	var chunk := GridMath.tile_to_chunk(tile)
	var key := GridMath.chunk_key(chunk, layer)
	if not modified_chunks.has(key):
		modified_chunks[key] = {"removed_entities": []}
	var removed: Array = _array_field(modified_chunks[key].get("removed_entities", []))
	if not removed.has(entity_id):
		removed.append(entity_id)
	modified_chunks[key]["removed_entities"] = removed


func mark_object_opened(object_id: String, tile: Vector2i, layer: String = "surface") -> void:
	if object_id.is_empty():
		return
	var chunk := GridMath.tile_to_chunk(tile)
	var key := GridMath.chunk_key(chunk, layer)
	if not modified_chunks.has(key):
		modified_chunks[key] = {"removed_entities": []}
	var modified_objects := _dictionary_field(modified_chunks[key].get("modified_objects", {}))
	modified_objects[object_id] = {"opened": true}
	modified_chunks[key]["modified_objects"] = modified_objects


func is_entity_removed(entity_id: String, tile: Vector2i, layer: String = "surface") -> bool:
	var key := GridMath.chunk_key(GridMath.tile_to_chunk(tile), layer)
	return modified_chunks.get(key, {}).get("removed_entities", []).has(entity_id)


func is_object_opened(object_id: String, tile: Vector2i, layer: String = "surface") -> bool:
	var key := GridMath.chunk_key(GridMath.tile_to_chunk(tile), layer)
	var modified_objects := _dictionary_field(
		modified_chunks.get(key, {}).get("modified_objects", {})
	)
	var object_state := _dictionary_field(modified_objects.get(object_id, {}))
	return bool(object_state.get("opened", false))


func get_save_data() -> Dictionary:
	return modified_chunks.duplicate(true)


func load_save_data(data: Dictionary) -> void:
	modified_chunks.clear()
	for chunk_key in data:
		var source_chunk = data[chunk_key]
		if not source_chunk is Dictionary:
			continue
		var removed_entities: Array = []
		for entity_id in _array_field(source_chunk.get("removed_entities", [])):
			var key := String(entity_id)
			if not key.is_empty() and not removed_entities.has(key):
				removed_entities.append(key)
		var modified_objects := _sanitized_modified_objects(
			source_chunk.get("modified_objects", {})
		)
		if not removed_entities.is_empty() or not modified_objects.is_empty():
			var chunk_state: Dictionary = {}
			if not removed_entities.is_empty():
				chunk_state["removed_entities"] = removed_entities
			if not modified_objects.is_empty():
				chunk_state["modified_objects"] = modified_objects
			modified_chunks[String(chunk_key)] = chunk_state


func _generate_tiles(chunk_coord: Vector2i) -> Array[Dictionary]:
	var tiles: Array[Dictionary] = []
	var origin := GridMath.chunk_origin_tile(chunk_coord)
	for y in range(GridMath.CHUNK_SIZE):
		for x in range(GridMath.CHUNK_SIZE):
			var tile := origin + Vector2i(x, y)
			tiles.append(
				{
					"tile": [tile.x, tile.y],
					"kind": get_tile_kind(tile),
					"walkable": is_walkable(tile)
				}
			)
	return tiles


func _hash_noise(tile: Vector2i) -> int:
	var value := tile.x * 928371 + tile.y * 689287 + tile.x * tile.y * 31
	value = absi(value % 100)
	return value


func _spawn_town_tile_kind(tile: Vector2i) -> String:
	var result := ""
	if not _is_in_spawn_town(tile):
		return result
	if _is_town_gate(tile):
		result = "road"
	elif _is_town_wall(tile):
		result = "stone_wall"
	elif _is_town_bridge(tile):
		result = "bridge"
	elif _is_town_river(tile):
		result = "water"
	else:
		var building_kind := _building_tile_kind(tile)
		if not building_kind.is_empty():
			result = building_kind
		elif _is_town_path(tile):
			result = "road"
		else:
			result = "grass"
	return result


func _is_in_spawn_town(tile: Vector2i) -> bool:
	return (
		tile.x >= SPAWN_TOWN_MIN.x
		and tile.x <= SPAWN_TOWN_MAX.x
		and tile.y >= SPAWN_TOWN_MIN.y
		and tile.y <= SPAWN_TOWN_MAX.y
	)


func _is_town_wall(tile: Vector2i) -> bool:
	return (
		tile.x == SPAWN_TOWN_MIN.x
		or tile.x == SPAWN_TOWN_MAX.x
		or tile.y == SPAWN_TOWN_MIN.y
		or tile.y == SPAWN_TOWN_MAX.y
	)


func _is_town_gate(tile: Vector2i) -> bool:
	return (
		(tile.x == SPAWN_TOWN_MIN.x and GATE_WIDTH.has(tile.y))
		or (tile.x == SPAWN_TOWN_MAX.x and GATE_WIDTH.has(tile.y))
		or (tile.y == SPAWN_TOWN_MIN.y and [2, 3].has(tile.x))
		or (tile.y == SPAWN_TOWN_MAX.y and [2, 3].has(tile.x))
	)


func _is_town_river(tile: Vector2i) -> bool:
	return RIVER_X.has(tile.x)


func _is_town_bridge(tile: Vector2i) -> bool:
	return _is_town_river(tile) and BRIDGE_Y.has(tile.y)


func _is_town_path(tile: Vector2i) -> bool:
	return (
		([1, 2].has(tile.y) and tile.x >= SPAWN_TOWN_MIN.x and tile.x <= SPAWN_TOWN_MAX.x)
		or ([2, 3].has(tile.x) and tile.y >= SPAWN_TOWN_MIN.y and tile.y <= SPAWN_TOWN_MAX.y)
		or (tile.x >= -1 and tile.x <= 5 and tile.y >= -1 and tile.y <= 4)
	)


func _building_tile_kind(tile: Vector2i) -> String:
	for rect in _building_rects():
		if not rect.has_point(tile):
			continue
		if _building_door_tiles().has(tile):
			return "wood_floor"
		if _is_rect_edge(tile, rect):
			return "wood_wall"
		return "wood_floor"
	return ""


func _building_rects() -> Array[Rect2i]:
	return [
		Rect2i(Vector2i(-11, 3), Vector2i(4, 4)),
		Rect2i(Vector2i(4, -1), Vector2i(5, 5)),
		Rect2i(Vector2i(1, -7), Vector2i(5, 5)),
		Rect2i(Vector2i(-6, -7), Vector2i(5, 5)),
		Rect2i(Vector2i(1, 4), Vector2i(5, 4)),
		Rect2i(Vector2i(9, -7), Vector2i(4, 5))
	]


func _building_door_tiles() -> Array[Vector2i]:
	return [
		Vector2i(-10, 3), Vector2i(-9, 3), Vector2i(-8, 3),
		Vector2i(4, -1), Vector2i(4, 0), Vector2i(4, 1), Vector2i(4, 2), Vector2i(4, 3),
		Vector2i(2, -3), Vector2i(3, -3), Vector2i(4, -3), Vector2i(5, -3),
		Vector2i(-5, -3), Vector2i(-4, -3), Vector2i(-3, -3), Vector2i(-2, -3),
		Vector2i(2, 4), Vector2i(3, 4), Vector2i(4, 4), Vector2i(5, 4),
		Vector2i(10, -3), Vector2i(11, -3), Vector2i(12, -3)
	]


func _is_rect_edge(tile: Vector2i, rect: Rect2i) -> bool:
	var last := rect.position + rect.size - Vector2i.ONE
	return (
		tile.x == rect.position.x
		or tile.x == last.x
		or tile.y == rect.position.y
		or tile.y == last.y
	)


func _array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []


func _dictionary_field(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _sanitized_modified_objects(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	var modified_objects := _dictionary_field(value)
	for object_id in modified_objects:
		var key := String(object_id)
		var object_state := _dictionary_field(modified_objects[object_id])
		if key.is_empty() or not bool(object_state.get("opened", false)):
			continue
		result[key] = {"opened": true}
	return result
