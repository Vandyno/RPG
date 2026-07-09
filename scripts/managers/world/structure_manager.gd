class_name StructureManager
extends Node

const GridMath = preload("res://scripts/core/grid_math.gd")

const BLOCKED_TILE_KINDS := ["water", "stone_wall", "wood_wall"]

var archetypes: Dictionary = {}
var structures: Array[Dictionary] = []
var structures_by_id: Dictionary = {}
var structures_by_layer: Dictionary = {}
var tile_kinds_by_key: Dictionary = {}


func setup(content: ContentDatabase) -> void:
	clear()
	if not content:
		return
	for archetype_id in content.structure_archetype_ids():
		archetypes[String(archetype_id)] = content.get_structure_archetype(String(archetype_id))
	for entry in content.world_structure_entries():
		var resolved := _resolved_structure(entry)
		if resolved.is_empty():
			continue
		structures.append(resolved)
		structures_by_id[String(resolved["id"])] = resolved
		var layer := String(resolved["world_layer"])
		if not structures_by_layer.has(layer):
			structures_by_layer[layer] = []
		structures_by_layer[layer].append(resolved)
		_index_structure_tiles(resolved)


func clear() -> void:
	archetypes.clear()
	structures.clear()
	structures_by_id.clear()
	structures_by_layer.clear()
	tile_kinds_by_key.clear()


func has_structure(structure_id: String) -> bool:
	return structures_by_id.has(structure_id)


func get_structure(structure_id: String) -> Dictionary:
	var structure: Variant = structures_by_id.get(structure_id, {})
	return structure.duplicate(true) if structure is Dictionary else {}


func get_tile_kind(tile: Vector2i, layer: String = "surface") -> String:
	return String(tile_kinds_by_key.get(GridMath.tile_key(tile, layer), ""))


func has_tile_override(tile: Vector2i, layer: String = "surface") -> bool:
	return tile_kinds_by_key.has(GridMath.tile_key(tile, layer))


func is_walkable_tile(tile: Vector2i, layer: String = "surface") -> bool:
	var kind := get_tile_kind(tile, layer)
	if kind.is_empty():
		return false
	return not BLOCKED_TILE_KINDS.has(kind)


func get_structures_for_chunk(
	chunk_coord: Vector2i, layer: String = "surface"
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for structure in _array_field(structures_by_layer.get(layer, [])):
		var origin: Vector2i = structure.get("origin_tile", Vector2i.ZERO)
		if GridMath.tile_to_chunk(origin) != chunk_coord:
			continue
		result.append(_structure_visual_data(structure))
	return result


func get_anchor_tile(structure_id: String, anchor_id: String) -> Vector2i:
	var structure := _dictionary_field(structures_by_id.get(structure_id, {}))
	if structure.is_empty():
		return Vector2i.ZERO
	var anchors := _dictionary_field(structure.get("anchors", {}))
	var anchor := _vector2i_from_pair(anchors.get(anchor_id, []), Vector2i.ZERO)
	var origin: Vector2i = structure.get("origin_tile", Vector2i.ZERO)
	return origin + anchor


func _resolved_structure(entry: Dictionary) -> Dictionary:
	var structure_id := String(entry.get("id", ""))
	var archetype_id := String(entry.get("archetype_id", ""))
	var archetype := _dictionary_field(archetypes.get(archetype_id, {}))
	if structure_id.is_empty() or archetype.is_empty():
		return {}
	var origin := _vector2i_from_pair(entry.get("origin_tile", []), Vector2i.ZERO)
	var size := _vector2i_from_pair(archetype.get("size", []), Vector2i.ZERO)
	if size.x <= 0 or size.y <= 0:
		return {}
	var layer := String(entry.get("world_layer", "surface"))
	if layer.is_empty():
		layer = "surface"
	return {
		"id": structure_id,
		"name": String(entry.get("name", archetype.get("name", structure_id))),
		"archetype_id": archetype_id,
		"world_layer": layer,
		"origin_tile": origin,
		"size": size,
		"bounds": Rect2i(origin, size),
		"visual_style": String(archetype.get("visual_style", "")),
		"seed": String(entry.get("seed", structure_id)),
		"terrain_rows": _array_field(archetype.get("terrain_rows", [])),
		"tile_kinds": _dictionary_field(archetype.get("tile_kinds", {})),
		"anchors": _dictionary_field(archetype.get("anchors", {}))
	}


func _index_structure_tiles(structure: Dictionary) -> void:
	var rows := _array_field(structure.get("terrain_rows", []))
	if rows.is_empty():
		return
	var origin: Vector2i = structure.get("origin_tile", Vector2i.ZERO)
	var layer := String(structure.get("world_layer", "surface"))
	var tile_kinds := _dictionary_field(structure.get("tile_kinds", {}))
	for y in range(rows.size()):
		var row := String(rows[y])
		for x in range(row.length()):
			var code := row.substr(x, 1)
			if code == ".":
				continue
			var kind := String(tile_kinds.get(code, ""))
			if kind.is_empty():
				continue
			var tile := origin + Vector2i(x, y)
			tile_kinds_by_key[GridMath.tile_key(tile, layer)] = kind


func _structure_visual_data(structure: Dictionary) -> Dictionary:
	var origin: Vector2i = structure.get("origin_tile", Vector2i.ZERO)
	var size: Vector2i = structure.get("size", Vector2i.ZERO)
	return {
		"id": String(structure.get("id", "")),
		"name": String(structure.get("name", "")),
		"world_layer": String(structure.get("world_layer", "surface")),
		"origin_tile": [origin.x, origin.y],
		"size": [size.x, size.y],
		"visual_style": String(structure.get("visual_style", "")),
		"seed": String(structure.get("seed", "")),
		"anchors": _dictionary_field(structure.get("anchors", {})).duplicate(true)
	}


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
