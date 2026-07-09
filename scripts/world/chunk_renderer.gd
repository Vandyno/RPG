class_name ChunkRenderer
extends Node2D

const GridMath = preload("res://scripts/core/grid_math.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")

var chunk_data: Dictionary


func setup(data: Dictionary) -> void:
	chunk_data = data
	var coord := VariantFields.vector2i_from_pair(data.get("chunk_coord", []), Vector2i.ZERO)
	position = GridMath.tile_to_world(GridMath.chunk_origin_tile(coord))
	queue_redraw()


func _draw() -> void:
	if chunk_data.is_empty():
		return
	var layer := String(chunk_data.get("layer", "surface"))
	var is_interior := _is_interior_layer(layer)
	for tile_data in VariantFields.array(chunk_data.get("tiles", [])):
		if not tile_data is Dictionary:
			continue
		var tile_pair := VariantFields.numeric_pair(tile_data.get("tile", []))
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
		var explicit := bool(tile_data.get("explicit", not is_interior))
		if is_interior and not explicit:
			_draw_void_tile(rect)
			continue
		draw_rect(rect, _color_for_kind(kind), true)
		_draw_material_detail(kind, rect, global_tile)
		var grid_alpha := 0.08 if is_interior else 0.13
		draw_rect(rect, Color(0.06, 0.08, 0.07, grid_alpha), false, 1.0)
	for structure in VariantFields.array(chunk_data.get("structures", [])):
		if structure is Dictionary:
			_draw_structure(structure)


func _is_interior_layer(layer: String) -> bool:
	return layer.begins_with("interior:")


func _draw_void_tile(rect: Rect2) -> void:
	draw_rect(rect, Color(0.045, 0.045, 0.042), true)


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


func _draw_structure(structure: Dictionary) -> void:
	var origin := VariantFields.vector2i_from_pair(structure.get("origin_tile", []), Vector2i.ZERO)
	var size := VariantFields.vector2i_from_pair(structure.get("size", []), Vector2i.ZERO)
	if size.x <= 0 or size.y <= 0:
		return
	var chunk_coord := VariantFields.vector2i_from_pair(
		chunk_data.get("chunk_coord", []), Vector2i.ZERO
	)
	var local_tile := origin - GridMath.chunk_origin_tile(chunk_coord)
	var rect := Rect2(
		Vector2(local_tile.x * GridMath.TILE_SIZE, local_tile.y * GridMath.TILE_SIZE),
		Vector2(size.x * GridMath.TILE_SIZE, size.y * GridMath.TILE_SIZE)
	)
	match String(structure.get("visual_style", "")):
		"forge_exterior":
			_draw_forge_exterior(rect)
		"forge_interior":
			_draw_forge_interior(rect)
		"shop_front":
			_draw_shop_front(rect)
		"town_hall_front":
			_draw_town_hall_front(rect)


func _draw_forge_exterior(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	draw_rect(rect.grow(3.0), Color(0.02, 0.018, 0.014, 0.25), true)
	var wall := Rect2(rect.position + Vector2(0.0, tile * 1.35), Vector2(rect.size.x, tile * 1.65))
	draw_rect(wall, Color(0.45, 0.29, 0.15), true)
	draw_rect(wall, Color(0.08, 0.045, 0.025, 0.58), false, 1.0)
	for x in [tile, tile * 2.0, tile * 4.0, tile * 5.0]:
		draw_line(
			wall.position + Vector2(x, 2.0),
			wall.position + Vector2(x + 2.0, wall.size.y - 3.0),
			Color(0.18, 0.09, 0.035, 0.34),
			1.0
		)
	var roof := Rect2(rect.position + Vector2(-5.0, -7.0), Vector2(rect.size.x + 10.0, 34.0))
	draw_polygon(
		[
			roof.position + Vector2(0.0, 8.0),
			roof.position + Vector2(roof.size.x * 0.50, 0.0),
			roof.position + Vector2(roof.size.x, 8.0),
			roof.position + Vector2(roof.size.x, roof.size.y),
			roof.position + Vector2(0.0, roof.size.y)
		],
		[Color(0.31, 0.13, 0.06, 0.96)]
	)
	draw_line(
		roof.position + Vector2(5.0, 26.0),
		roof.end - Vector2(4.0, 5.0),
		Color(0.05, 0.02, 0.01, 0.40),
		2.0
	)
	draw_line(
		roof.position + Vector2(roof.size.x * 0.5, 1.0),
		roof.position + Vector2(roof.size.x * 0.5, roof.size.y - 3.0),
		Color(0.58, 0.28, 0.13, 0.22),
		1.0
	)
	for offset in [11.0, 27.0, 43.0, 59.0, 75.0, 91.0]:
		draw_line(
			roof.position + Vector2(offset, 9.0),
			roof.position + Vector2(offset + 3.0, roof.size.y - 4.0),
			Color(0.52, 0.27, 0.15, 0.26),
			1.0
		)
	var chimney := Rect2(rect.position + Vector2(rect.size.x - 18.0, -9.0), Vector2(10.0, 20.0))
	draw_rect(chimney, Color(0.24, 0.24, 0.22), true)
	draw_rect(chimney, Color(0.07, 0.07, 0.06), false, 1.0)
	draw_circle(chimney.position + Vector2(5.0, 2.0), 3.5, Color(0.12, 0.11, 0.10, 0.45))
	var entry := Rect2(rect.position + Vector2(tile * 2.0, tile * 2.0), Vector2(tile * 2.0, tile))
	draw_rect(entry.grow(-2.0), Color(0.08, 0.045, 0.025, 0.85), true)
	draw_rect(entry.grow(-1.0), Color(0.92, 0.68, 0.25, 0.35), false, 1.0)
	draw_rect(
		Rect2(entry.position + Vector2(5.0, 1.0), Vector2(4.0, 11.0)),
		Color(0.22, 0.12, 0.06),
		true
	)
	draw_circle(entry.position + Vector2(21.0, 8.0), 1.3, Color(0.82, 0.62, 0.22))
	var sign := Rect2(rect.position + Vector2(tile * 4.25, tile * 2.05), Vector2(18.0, 10.0))
	draw_rect(sign, Color(0.14, 0.08, 0.035), true)
	draw_line(
		sign.position + Vector2(4.0, 6.0),
		sign.position + Vector2(14.0, 3.0),
		Color(0.62, 0.58, 0.46),
		2.0
	)


func _draw_forge_interior(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	draw_rect(rect.grow(4.0), Color(0.0, 0.0, 0.0, 0.30), true)
	draw_rect(rect.grow(-tile), Color(0.69, 0.44, 0.22, 0.08), true)
	var exit := Rect2(rect.position + Vector2(tile * 5.0, tile * 7.0), Vector2(tile * 2.0, tile))
	draw_rect(exit.grow(-2.0), Color(0.08, 0.045, 0.025, 0.70), true)
	draw_rect(exit.grow(-1.0), Color(0.92, 0.68, 0.25, 0.28), false, 1.0)
	var hearth_position := rect.position + Vector2(tile * 8.0, tile * 2.0)
	var hearth := Rect2(hearth_position, Vector2(tile * 2.0, tile * 2.0))
	draw_rect(hearth, Color(0.23, 0.23, 0.21), true)
	draw_rect(hearth, Color(0.06, 0.06, 0.05), false, 2.0)
	draw_circle(hearth.get_center(), 11.0, Color(0.95, 0.37, 0.09, 0.72))
	draw_circle(hearth.get_center(), 6.0, Color(1.0, 0.78, 0.21, 0.85))
	draw_circle(hearth.get_center(), 28.0, Color(0.90, 0.42, 0.10, 0.08))
	var anvil := Rect2(rect.position + Vector2(tile * 3.0, tile * 5.0), Vector2(30.0, 12.0))
	draw_rect(anvil, Color(0.12, 0.13, 0.13), true)
	var anvil_base := Rect2(anvil.position + Vector2(4.0, 9.0), Vector2(9.0, 13.0))
	draw_rect(anvil_base, Color(0.10, 0.10, 0.10), true)
	draw_line(
		anvil.position + Vector2(-5.0, 5.0),
		anvil.position + Vector2(27.0, 5.0),
		Color(0.34, 0.34, 0.32),
		2.0
	)
	var bench_position := rect.position + Vector2(tile * 7.4, tile * 6.2)
	var bench := Rect2(bench_position, Vector2(50.0, 12.0))
	draw_rect(bench, Color(0.30, 0.18, 0.09), true)
	draw_rect(bench, Color(0.10, 0.06, 0.03), false, 1.0)
	draw_line(
		bench.position + Vector2(6.0, 3.0),
		bench.position + Vector2(22.0, 8.0),
		Color(0.55, 0.55, 0.50),
		2.0
	)
	var rack := Rect2(rect.position + Vector2(tile * 1.7, tile * 2.0), Vector2(44.0, 10.0))
	draw_rect(rack, Color(0.23, 0.13, 0.06), true)
	draw_line(
		rack.position + Vector2(5.0, 2.0),
		rack.position + Vector2(15.0, 8.0),
		Color(0.50, 0.50, 0.46),
		2.0
	)
	draw_line(
		rack.position + Vector2(23.0, 8.0),
		rack.position + Vector2(35.0, 2.0),
		Color(0.50, 0.50, 0.46),
		2.0
	)
	var storage := Rect2(rect.position + Vector2(tile * 1.6, tile * 6.3), Vector2(28.0, 12.0))
	draw_rect(storage, Color(0.13, 0.08, 0.04), true)
	draw_rect(storage, Color(0.48, 0.29, 0.12), false, 1.0)


func _draw_shop_front(rect: Rect2) -> void:
	var body := Rect2(rect.position + Vector2(6.0, 13.0), Vector2(rect.size.x - 12.0, 54.0))
	draw_rect(rect.grow(2.0), Color(0.02, 0.018, 0.012, 0.20), true)
	draw_rect(body, Color(0.42, 0.25, 0.12), true)
	draw_rect(body, Color(0.10, 0.06, 0.03, 0.50), false, 1.0)
	for x in [body.position.x + 12.0, body.position.x + 28.0, body.position.x + 44.0]:
		draw_line(
			Vector2(x, body.position.y + 3.0),
			Vector2(x + 2.0, body.end.y - 3.0),
			Color(0.18, 0.09, 0.04, 0.28),
			1.0
		)
	var roof := Rect2(rect.position + Vector2(0.0, -2.0), Vector2(rect.size.x, 25.0))
	draw_polygon(
		[
			roof.position + Vector2(4.0, roof.size.y),
			roof.position + Vector2(roof.size.x * 0.5, 0.0),
			roof.position + Vector2(roof.size.x - 4.0, roof.size.y)
		],
		[Color(0.33, 0.15, 0.07, 0.94)]
	)
	var awning := Rect2(rect.position + Vector2(8.0, 24.0), Vector2(rect.size.x - 16.0, 18.0))
	draw_rect(awning, Color(0.53, 0.11, 0.09), true)
	for x in range(0, int(awning.size.x), 10):
		draw_rect(
			Rect2(awning.position + Vector2(float(x), 0.0), Vector2(6.0, awning.size.y)),
			Color(0.84, 0.73, 0.48),
			true
		)
	draw_rect(awning, Color(0.12, 0.05, 0.03), false, 1.0)
	var counter := Rect2(rect.position + Vector2(12.0, 49.0), Vector2(rect.size.x - 24.0, 10.0))
	draw_rect(counter, Color(0.34, 0.20, 0.10), true)
	draw_rect(counter, Color(0.11, 0.07, 0.04), false, 1.0)
	draw_rect(
		Rect2(rect.position + Vector2(31.0, 59.0), Vector2(18.0, 16.0)),
		Color(0.13, 0.07, 0.03),
		true
	)
	draw_circle(counter.position + Vector2(12.0, -4.0), 3.0, Color(0.20, 0.42, 0.18))
	draw_circle(counter.position + Vector2(29.0, -4.0), 3.0, Color(0.53, 0.36, 0.12))
	draw_circle(counter.position + Vector2(46.0, -4.0), 3.0, Color(0.28, 0.37, 0.56))
	var crate := Rect2(rect.position + Vector2(8.0, 62.0), Vector2(14.0, 12.0))
	draw_rect(crate, Color(0.46, 0.28, 0.12), true)
	draw_rect(crate, Color(0.11, 0.06, 0.03), false, 1.0)


func _draw_town_hall_front(rect: Rect2) -> void:
	draw_rect(rect.grow(3.0), Color(0.02, 0.018, 0.012, 0.22), true)
	var body := Rect2(rect.position + Vector2(4.0, 17.0), Vector2(rect.size.x - 8.0, 45.0))
	draw_rect(body, Color(0.45, 0.30, 0.15), true)
	draw_rect(body, Color(0.09, 0.055, 0.03, 0.50), false, 1.0)
	for x in [body.position.x + 12.0, body.position.x + body.size.x - 12.0]:
		draw_rect(
			Rect2(Vector2(x - 2.0, body.position.y + 10.0), Vector2(4.0, 31.0)),
			Color(0.25, 0.15, 0.07),
			true
		)
	var roof := Rect2(rect.position + Vector2(-2.0, -5.0), Vector2(rect.size.x + 4.0, 28.0))
	draw_polygon(
		[
			roof.position + Vector2(0.0, roof.size.y),
			roof.position + Vector2(roof.size.x * 0.5, 0.0),
			roof.position + Vector2(roof.size.x, roof.size.y)
		],
		[Color(0.30, 0.15, 0.07, 0.95)]
	)
	draw_line(
		roof.position + Vector2(roof.size.x * 0.5, 1.0),
		roof.position + Vector2(roof.size.x * 0.5, roof.size.y - 3.0),
		Color(0.58, 0.31, 0.14, 0.25),
		1.0
	)
	var door := Rect2(rect.position + Vector2(rect.size.x * 0.5 - 10.0, 42.0), Vector2(20.0, 20.0))
	draw_rect(door, Color(0.12, 0.07, 0.035), true)
	draw_line(
		door.position + Vector2(10.0, 2.0),
		door.position + Vector2(10.0, 18.0),
		Color(0.44, 0.28, 0.11),
		1.0
	)
	draw_circle(door.position + Vector2(7.0, 11.0), 1.2, Color(0.82, 0.62, 0.22))
	draw_circle(door.position + Vector2(13.0, 11.0), 1.2, Color(0.82, 0.62, 0.22))
	var step := Rect2(door.position + Vector2(-5.0, 18.0), Vector2(30.0, 8.0))
	draw_rect(step, Color(0.39, 0.38, 0.34), true)
	draw_rect(step, Color(0.10, 0.10, 0.09, 0.40), false, 1.0)
	var board := Rect2(rect.position + Vector2(rect.size.x - 26.0, 29.0), Vector2(18.0, 16.0))
	draw_rect(board, Color(0.55, 0.43, 0.22), true)
	draw_rect(board, Color(0.12, 0.08, 0.04), false, 1.0)
	draw_line(
		board.position + Vector2(3.0, 5.0),
		board.position + Vector2(15.0, 5.0),
		Color(0.11, 0.07, 0.03),
		1.0
	)
	draw_line(
		board.position + Vector2(4.0, 10.0),
		board.position + Vector2(13.0, 10.0),
		Color(0.11, 0.07, 0.03),
		1.0
	)


func _hash_detail(tile: Vector2i) -> int:
	return absi((tile.x * 17 + tile.y * 31 + tile.x * tile.y * 7) % 10)
