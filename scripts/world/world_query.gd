class_name WorldQuery
extends RefCounted

const GridMath = preload("res://scripts/core/grid_math.gd")

const SURFACE_LAYER := "surface"
const INTERIOR_FALLBACK_KIND := "stone_wall"
const BLOCKED_TILE_KINDS := ["water", "stone_wall", "wood_wall"]

var chunk_manager
var structure_manager: StructureManager
var current_layer := SURFACE_LAYER


func setup(chunks, structures: StructureManager = null) -> void:
	chunk_manager = chunks
	structure_manager = structures


func set_layer(layer: String) -> void:
	current_layer = _normalized_layer(layer)


func get_current_layer() -> String:
	return current_layer


func get_chunk_data(chunk_coord: Vector2i, layer: String = "") -> Dictionary:
	var resolved_layer := _resolved_layer(layer)
	var tiles: Array[Dictionary] = []
	for tile in GridMath.chunk_tiles(chunk_coord):
		var explicit := (
			structure_manager and structure_manager.has_tile_override(tile, resolved_layer)
		)
		var kind := get_tile_kind(tile, resolved_layer)
		tiles.append(
			{
				"tile": [tile.x, tile.y],
				"kind": kind,
				"walkable": is_walkable(tile, resolved_layer),
				"explicit": explicit
			}
		)
	var structures: Array[Dictionary] = []
	if structure_manager:
		structures = structure_manager.get_structures_for_chunk(chunk_coord, resolved_layer)
	return {
		"id": GridMath.chunk_key(chunk_coord, resolved_layer),
		"layer": resolved_layer,
		"chunk_coord": [chunk_coord.x, chunk_coord.y],
		"chunk_size": GridMath.CHUNK_SIZE,
		"tiles": tiles,
		"structures": structures
	}


func get_tile_kind(global_tile: Vector2i, layer: String = "") -> String:
	var resolved_layer := _resolved_layer(layer)
	if structure_manager and structure_manager.has_tile_override(global_tile, resolved_layer):
		return structure_manager.get_tile_kind(global_tile, resolved_layer)
	if resolved_layer != SURFACE_LAYER:
		return INTERIOR_FALLBACK_KIND
	if chunk_manager and chunk_manager.has_method("get_tile_kind"):
		return String(chunk_manager.get_tile_kind(global_tile))
	return "grass"


func is_walkable(global_tile: Vector2i, layer: String = "") -> bool:
	var resolved_layer := _resolved_layer(layer)
	if structure_manager and structure_manager.has_tile_override(global_tile, resolved_layer):
		return structure_manager.is_walkable_tile(global_tile, resolved_layer)
	if resolved_layer != SURFACE_LAYER:
		return false
	if chunk_manager and chunk_manager.has_method("is_walkable"):
		return bool(chunk_manager.is_walkable(global_tile))
	return not BLOCKED_TILE_KINDS.has(get_tile_kind(global_tile, resolved_layer))


func _resolved_layer(layer: String) -> String:
	if layer.is_empty():
		return current_layer
	return _normalized_layer(layer)


func _normalized_layer(layer: String) -> String:
	if layer.is_empty():
		return SURFACE_LAYER
	return layer
