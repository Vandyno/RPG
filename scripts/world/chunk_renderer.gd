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
		var kind := String(tile_data.get("kind", "grass"))
		draw_rect(rect, _color_for_kind(kind), true)
		_draw_material_detail(kind, rect, global_tile)
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


func _draw_material_detail(kind: String, rect: Rect2, global_tile: Vector2i) -> void:
	var inset := rect.grow(-3.0)
	match kind:
		"water":
			_draw_water_detail(rect, global_tile)
		"bridge":
			_draw_bridge_detail(rect)
		"stone_wall":
			_draw_stone_detail(rect)
		"wood_wall":
			_draw_wood_detail(rect, true)
		"wood_floor":
			_draw_wood_detail(rect, false)
		"road":
			draw_rect(inset, Color(0.65, 0.58, 0.43, 0.28), true)
			if int(global_tile.x + global_tile.y) % 2 == 0:
				draw_line(
					rect.position + Vector2(3.0, 11.0),
					rect.position + Vector2(13.0, 9.0),
					Color(0.29, 0.24, 0.16, 0.20),
					1.0
				)
		"grass":
			if _hash_detail(global_tile) < 3:
				draw_line(
					rect.position + Vector2(5.0, 12.0),
					rect.position + Vector2(8.0, 8.0),
					Color(0.18, 0.35, 0.16, 0.36),
					1.0
				)
		"forest":
			draw_circle(rect.position + Vector2(8.0, 8.0), 4.5, Color(0.10, 0.24, 0.11, 0.38))
		"hill":
			draw_line(
				rect.position + Vector2(3.0, 11.0),
				rect.position + Vector2(8.0, 5.0),
				Color(0.70, 0.65, 0.48, 0.22),
				1.0
			)
			draw_line(
				rect.position + Vector2(8.0, 5.0),
				rect.position + Vector2(13.0, 11.0),
				Color(0.19, 0.16, 0.11, 0.20),
				1.0
			)


func _draw_water_detail(rect: Rect2, global_tile: Vector2i) -> void:
	var wave_y := 5.0 + float(_hash_detail(global_tile) % 5)
	draw_line(
		rect.position + Vector2(2.0, wave_y),
		rect.position + Vector2(14.0, wave_y - 1.5),
		Color(0.52, 0.74, 0.86, 0.22),
		1.0
	)
	draw_line(
		rect.position + Vector2(3.0, wave_y + 6.0),
		rect.position + Vector2(13.0, wave_y + 5.0),
		Color(0.05, 0.14, 0.24, 0.18),
		1.0
	)


func _draw_bridge_detail(rect: Rect2) -> void:
	draw_rect(rect.grow(-2.0), Color(0.64, 0.46, 0.27, 0.32), true)
	for y in [4.0, 8.0, 12.0]:
		draw_line(
			rect.position + Vector2(2.0, y),
			rect.position + Vector2(14.0, y),
			Color(0.21, 0.13, 0.07, 0.34),
			1.0
		)
	draw_line(
		rect.position + Vector2(2.0, 2.0),
		rect.position + Vector2(2.0, 14.0),
		Color(0.18, 0.10, 0.06, 0.30),
		1.0
	)
	draw_line(
		rect.position + Vector2(14.0, 2.0),
		rect.position + Vector2(14.0, 14.0),
		Color(0.18, 0.10, 0.06, 0.30),
		1.0
	)


func _draw_stone_detail(rect: Rect2) -> void:
	draw_rect(rect.grow(-2.0), Color(0.54, 0.55, 0.52, 0.18), true)
	draw_line(
		rect.position + Vector2(2.0, 6.0),
		rect.position + Vector2(14.0, 6.0),
		Color(0.11, 0.12, 0.12, 0.32),
		1.0
	)
	draw_line(
		rect.position + Vector2(2.0, 11.0),
		rect.position + Vector2(14.0, 11.0),
		Color(0.11, 0.12, 0.12, 0.26),
		1.0
	)
	draw_line(
		rect.position + Vector2(6.0, 2.0),
		rect.position + Vector2(6.0, 6.0),
		Color(0.11, 0.12, 0.12, 0.28),
		1.0
	)
	draw_line(
		rect.position + Vector2(10.0, 6.0),
		rect.position + Vector2(10.0, 11.0),
		Color(0.11, 0.12, 0.12, 0.28),
		1.0
	)


func _draw_wood_detail(rect: Rect2, is_wall: bool) -> void:
	var line_color := Color(0.17, 0.09, 0.04, 0.36 if is_wall else 0.24)
	for x in [5.0, 10.0]:
		draw_line(
			rect.position + Vector2(x, 2.0),
			rect.position + Vector2(x, 14.0),
			line_color,
			1.0
		)
	if is_wall:
		draw_rect(rect.grow(-2.0), Color(0.18, 0.10, 0.05, 0.24), false, 1.0)
	else:
		draw_line(
			rect.position + Vector2(2.0, 8.0),
			rect.position + Vector2(14.0, 8.0),
			line_color,
			1.0
		)


func _hash_detail(tile: Vector2i) -> int:
	return absi((tile.x * 17 + tile.y * 31 + tile.x * tile.y * 7) % 10)


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
