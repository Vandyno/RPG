class_name ChunkRenderer
extends Node2D

const GridMath = preload("res://scripts/core/grid_math.gd")

var chunk_data: Dictionary


func setup(data: Dictionary) -> void:
	chunk_data = data
	var coord := _vector2i_from_pair(data.get("chunk_coord", []), Vector2i.ZERO)
	position = GridMath.tile_to_world(GridMath.chunk_origin_tile(coord))
	queue_redraw()


func _draw() -> void:
	if chunk_data.is_empty():
		return
	for tile_data in _array_field(chunk_data.get("tiles", [])):
		if not tile_data is Dictionary:
			continue
		var tile_pair := _array_pair(tile_data.get("tile", []))
		if tile_pair.is_empty():
			continue
		var global_tile := Vector2i(int(tile_pair[0]), int(tile_pair[1]))
		var local_tile := (
			global_tile - GridMath.chunk_origin_tile(GridMath.tile_to_chunk(global_tile))
		)
		var rect := Rect2(
			Vector2(local_tile.x * GridMath.TILE_SIZE, local_tile.y * GridMath.TILE_SIZE),
			Vector2(GridMath.TILE_SIZE, GridMath.TILE_SIZE)
		)
		draw_rect(rect, _color_for_kind(String(tile_data.get("kind", "grass"))), true)
		draw_rect(rect, Color(0.06, 0.08, 0.07, 0.18), false, 1.0)


func _color_for_kind(kind: String) -> Color:
	var color := Color(0.34, 0.49, 0.27)
	match kind:
		"water":
			color = Color(0.16, 0.36, 0.58)
		"bridge":
			color = Color(0.50, 0.35, 0.20)
		"stone_wall":
			color = Color(0.36, 0.38, 0.38)
		"wood_wall":
			color = Color(0.36, 0.22, 0.12)
		"wood_floor":
			color = Color(0.50, 0.34, 0.18)
		"forest":
			color = Color(0.18, 0.35, 0.17)
		"hill":
			color = Color(0.48, 0.43, 0.31)
		"road":
			color = Color(0.58, 0.51, 0.38)
	return color


func _vector2i_from_pair(value: Variant, fallback: Vector2i) -> Vector2i:
	var pair := _array_pair(value)
	if pair.is_empty():
		return fallback
	return Vector2i(int(pair[0]), int(pair[1]))


func _array_pair(value: Variant) -> Array:
	if not value is Array or value.size() < 2:
		return []
	if not _is_number(value[0]) or not _is_number(value[1]):
		return []
	return [value[0], value[1]]


func _array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []


func _is_number(value: Variant) -> bool:
	return value is int or value is float
