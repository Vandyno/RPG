class_name ChunkManager
extends Node

const GridMath = preload("res://scripts/core/grid_math.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")

const AUTHORED_TERRAIN_PATH := "res://data/world_terrain.json"
const BLOCKED_TILE_KINDS := [
	"water", "stone_wall", "wood_wall", "palisade", "structure_blocker"
]

var authored_areas: Array[Dictionary] = []
var modified_chunks: Dictionary = {}


func load_world_terrain(terrain: Dictionary) -> void:
	authored_areas.clear()
	for area_value in VariantFields.array(terrain.get("areas", [])):
		if not area_value is Dictionary:
			continue
		var area := _sanitized_area(area_value)
		if not area.is_empty():
			authored_areas.append(area)


func load_authored_terrain(path: String) -> Array[String]:
	if not FileAccess.file_exists(path):
		authored_areas.clear()
		return ["Missing authored terrain file: %s" % path]
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		authored_areas.clear()
		return [
			"Could not read authored terrain file %s: %s"
			% [path, error_string(FileAccess.get_open_error())]
		]
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	if parse_error != OK:
		authored_areas.clear()
		return [
			"Invalid JSON at %s line %d: %s"
			% [path, parser.get_error_line(), parser.get_error_message()]
		]
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		authored_areas.clear()
		return ["Expected dictionary JSON at %s" % path]
	load_world_terrain(parsed)
	return []


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
	var removed: Array = VariantFields.array(modified_chunks[key].get("removed_entities", []))
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
	var modified_objects := VariantFields.dictionary(modified_chunks[key].get("modified_objects", {}))
	modified_objects[object_id] = {"opened": true}
	modified_chunks[key]["modified_objects"] = modified_objects


func is_entity_removed(entity_id: String, tile: Vector2i, layer: String = "surface") -> bool:
	var key := GridMath.chunk_key(GridMath.tile_to_chunk(tile), layer)
	return modified_chunks.get(key, {}).get("removed_entities", []).has(entity_id)


func is_object_opened(object_id: String, tile: Vector2i, layer: String = "surface") -> bool:
	var key := GridMath.chunk_key(GridMath.tile_to_chunk(tile), layer)
	var modified_objects := VariantFields.dictionary(
		modified_chunks.get(key, {}).get("modified_objects", {})
	)
	var object_state := VariantFields.dictionary(modified_objects.get(object_id, {}))
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
		for entity_id in VariantFields.array(source_chunk.get("removed_entities", [])):
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
	for tile in GridMath.chunk_tiles(chunk_coord):
		tiles.append(
			{"tile": [tile.x, tile.y], "kind": get_tile_kind(tile), "walkable": is_walkable(tile)}
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
		for region in VariantFields.array(area.get("regions", [])):
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
	for region_value in VariantFields.array(source.get("regions", [])):
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
	var source := VariantFields.dictionary(value)
	var min_tile := VariantFields.vector2i_from_pair(source.get("min", []), Vector2i.ZERO)
	var max_tile := VariantFields.vector2i_from_pair(source.get("max", []), Vector2i.ZERO)
	if max_tile.x < min_tile.x or max_tile.y < min_tile.y:
		return Rect2i()
	return Rect2i(min_tile, max_tile - min_tile + Vector2i.ONE)


func _rect_from_dictionary(value: Variant) -> Rect2i:
	var source := VariantFields.dictionary(value)
	var position := VariantFields.vector2i_from_pair(source.get("position", []), Vector2i.ZERO)
	var size := VariantFields.vector2i_from_pair(source.get("size", []), Vector2i.ZERO)
	if size.x <= 0 or size.y <= 0:
		return Rect2i()
	return Rect2i(position, size)


func _tiles_from_array(value: Variant) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for tile_value in VariantFields.array(value):
		var tile := VariantFields.vector2i_from_pair(tile_value, Vector2i.ZERO)
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


func _sanitized_modified_objects(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	var modified_objects := VariantFields.dictionary(value)
	for object_id in modified_objects:
		var key := String(object_id)
		var object_state := VariantFields.dictionary(modified_objects[object_id])
		if key.is_empty() or not bool(object_state.get("opened", false)):
			continue
		result[key] = {"opened": true}
	return result
