class_name ChunkManager
extends Node

const GridMath = preload("res://scripts/core/grid_math.gd")

const AUTHORED_TERRAIN_PATH := "res://data/world_terrain.json"
const BLOCKED_TILE_KINDS := ["water", "stone_wall", "wood_wall"]

var authored_areas: Array[Dictionary] = []
var modified_chunks: Dictionary = {}


func load_authored_terrain(path: String) -> void:
	authored_areas.clear()
	if not FileAccess.file_exists(path):
		push_warning("Missing authored terrain file: %s" % path)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_warning("Expected dictionary JSON at %s" % path)
		return
	for area_value in _array_field(parsed.get("areas", [])):
		if not area_value is Dictionary:
			continue
		var area := _sanitized_area(area_value)
		if not area.is_empty():
			authored_areas.append(area)


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
	var authored_kind := _authored_tile_kind(global_tile)
	if not authored_kind.is_empty():
		return authored_kind

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


func _authored_tile_kind(tile: Vector2i) -> String:
	for area in authored_areas:
		var bounds: Rect2i = area.get("bounds", Rect2i())
		if not bounds.has_point(tile):
			continue
		var kind := String(area.get("default_kind", "grass"))
		for region in _array_field(area.get("regions", [])):
			var region_kind := _region_kind_at(region, tile)
			if not region_kind.is_empty():
				kind = region_kind
		return kind
	return ""


func _region_kind_at(region: Dictionary, tile: Vector2i) -> String:
	var kind := String(region.get("kind", ""))
	if kind.is_empty():
		return ""
	var tiles: Array = region.get("tiles", [])
	if tiles.has(tile):
		return kind
	var rect: Rect2i = region.get("rect", Rect2i())
	if rect.size == Vector2i.ZERO or not rect.has_point(tile):
		return ""
	if bool(region.get("border_only", false)) and not _is_rect_edge(tile, rect):
		return ""
	return kind


func _sanitized_area(source: Dictionary) -> Dictionary:
	var bounds := _bounds_from_dictionary(source.get("bounds", {}))
	if bounds.size == Vector2i.ZERO:
		return {}
	var regions: Array[Dictionary] = []
	for region_value in _array_field(source.get("regions", [])):
		if not region_value is Dictionary:
			continue
		var region := _sanitized_region(region_value)
		if not region.is_empty():
			regions.append(region)
	return {
		"id": String(source.get("id", "")),
		"bounds": bounds,
		"default_kind": String(source.get("default_kind", "grass")),
		"regions": regions
	}


func _sanitized_region(source: Dictionary) -> Dictionary:
	var kind := String(source.get("kind", ""))
	if kind.is_empty():
		return {}
	var region := {
		"id": String(source.get("id", "")),
		"kind": kind,
		"border_only": bool(source.get("border_only", false)),
		"rect": _rect_from_dictionary(source.get("rect", {})),
		"tiles": _tiles_from_array(source.get("tiles", []))
	}
	if (region["rect"] as Rect2i).size == Vector2i.ZERO and (region["tiles"] as Array).is_empty():
		return {}
	return region


func _bounds_from_dictionary(value: Variant) -> Rect2i:
	var source := _dictionary_field(value)
	var min_tile := _vector2i_from_pair(source.get("min", []), Vector2i.ZERO)
	var max_tile := _vector2i_from_pair(source.get("max", []), Vector2i.ZERO)
	if max_tile.x < min_tile.x or max_tile.y < min_tile.y:
		return Rect2i()
	return Rect2i(min_tile, max_tile - min_tile + Vector2i.ONE)


func _rect_from_dictionary(value: Variant) -> Rect2i:
	var source := _dictionary_field(value)
	var position := _vector2i_from_pair(source.get("position", []), Vector2i.ZERO)
	var size := _vector2i_from_pair(source.get("size", []), Vector2i.ZERO)
	if size.x <= 0 or size.y <= 0:
		return Rect2i()
	return Rect2i(position, size)


func _tiles_from_array(value: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for tile_value in _array_field(value):
		var tile := _vector2i_from_pair(tile_value, Vector2i.ZERO)
		if not result.has(tile):
			result.append(tile)
	return result


func _is_rect_edge(tile: Vector2i, rect: Rect2i) -> bool:
	var last := rect.position + rect.size - Vector2i.ONE
	return (
		tile.x == rect.position.x
		or tile.x == last.x
		or tile.y == rect.position.y
		or tile.y == last.y
	)


func _vector2i_from_pair(value: Variant, fallback: Vector2i) -> Vector2i:
	if not value is Array or value.size() < 2:
		return fallback
	if not _is_number(value[0]) or not _is_number(value[1]):
		return fallback
	return Vector2i(int(value[0]), int(value[1]))


func _array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []


func _dictionary_field(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _is_number(value: Variant) -> bool:
	return value is int or value is float


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
