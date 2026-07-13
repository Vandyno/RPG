class_name ChunkRenderer
extends Node2D

const GridMath = preload("res://scripts/core/grid_math.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")
const NORTHGATE_COTTAGE_ROOFS := [
	preload("res://assets/world/northgate/roofs/cottage_shingle_a.png"),
	preload("res://assets/world/northgate/roofs/cottage_shingle_b.png"),
	preload("res://assets/world/northgate/roofs/cottage_shingle_c.png"),
	preload("res://assets/world/northgate/roofs/cottage_thatch.png")
]
const NORTHGATE_COTTAGE_FACADES := [
	preload("res://assets/world/northgate/facades/cottage_a.png"),
	preload("res://assets/world/northgate/facades/cottage_b.png"),
	preload("res://assets/world/northgate/facades/cottage_c.png"),
	preload("res://assets/world/northgate/facades/cottage_thatch.png")
]
const NORTHGATE_SERVICE_ROOFS := {
	"civic": preload("res://assets/world/northgate/roofs/civic_hall.png"),
	"inn": preload("res://assets/world/northgate/roofs/coaching_inn.png"),
	"smithy": preload("res://assets/world/northgate/roofs/smithy.png"),
	"utility": preload("res://assets/world/northgate/roofs/stable_store.png")
}
const NORTHGATE_HOME_ROOFS_V2 := {
	"structure_northgate_west_home_plot": preload("res://assets/world/northgate/roofs/crooked_shingle_a.png"),
	"structure_northgate_south_home_plot": preload("res://assets/world/northgate/roofs/patched_thatch_a.png"),
	"structure_northgate_east_home_plot": preload("res://assets/world/northgate/roofs/crooked_shingle_b.png"),
	"structure_northgate_southeast_home_plot": preload("res://assets/world/northgate/roofs/patched_thatch_b.png"),
	"structure_northgate_far_east_home_plot": preload("res://assets/world/northgate/roofs/crooked_shingle_c.png")
}
const NORTHGATE_SERVICE_ROOFS_V2 := {
	"structure_northgate_hall_plot": preload("res://assets/world/northgate/roofs/civic_hipped_v2.png"),
	"structure_northgate_inn_plot": preload("res://assets/world/northgate/roofs/coaching_inn.png"),
	"structure_northgate_stable_plot": preload("res://assets/world/northgate/roofs/stable_hayloft_v2.png"),
	"structure_northgate_shop_plot": preload("res://assets/world/northgate/roofs/crooked_shingle_c.png"),
	"structure_northgate_store_plot": preload("res://assets/world/northgate/roofs/stable_store.png"),
	"structure_northgate_smith_plot": preload("res://assets/world/northgate/roofs/smith_soot_v2.png")
}
const NORTHGATE_LEAN_TO_ROOFS := [
	preload("res://assets/world/northgate/roofs/lean_to_a.png"),
	preload("res://assets/world/northgate/roofs/lean_to_b.png")
]
const NORTHGATE_INN_WEST_ENTRANCE := preload("res://assets/world/northgate/inn_v3/exterior/inn_west_entrance.png")
const NORTHGATE_INN_INTERIOR_SHELL := preload("res://assets/world/northgate/inn_v3/interior/inn_interior_shell.png")
const NORTHGATE_SERVICE_FACADES := {
	"civic": preload("res://assets/world/northgate/facades/civic_hall.png"),
	"inn": preload("res://assets/world/northgate/facades/coaching_inn.png"),
	"smithy": preload("res://assets/world/northgate/facades/smithy.png"),
	"utility": preload("res://assets/world/northgate/facades/stable_store.png")
}

var chunk_data: Dictionary
var render_mode := "combined"
var tile_kind_by_global: Dictionary = {}


func setup(data: Dictionary, mode: String = "combined") -> void:
	chunk_data = data
	render_mode = mode
	tile_kind_by_global.clear()
	for tile_data in VariantFields.array(data.get("tiles", [])):
		if not tile_data is Dictionary:
			continue
		var tile_pair := VariantFields.numeric_pair(tile_data.get("tile", []))
		if tile_pair.size() >= 2:
			tile_kind_by_global[Vector2i(int(tile_pair[0]), int(tile_pair[1]))] = String(tile_data.get("kind", "grass"))
	var coord := VariantFields.vector2i_from_pair(data.get("chunk_coord", []), Vector2i.ZERO)
	position = (
		Vector2.ZERO
		if render_mode == "structures"
		else GridMath.tile_to_world(GridMath.chunk_origin_tile(coord))
	)
	if render_mode == "combined":
		render_mode = "terrain"
		z_index = -2
		var structure_overlay := ChunkRenderer.new()
		structure_overlay.name = "StructureOverlay"
		structure_overlay.z_index = 1
		add_child(structure_overlay)
		structure_overlay.setup(data, "structures")
	queue_redraw()


func _draw() -> void:
	if chunk_data.is_empty():
		return
	if render_mode != "structures":
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
			var grid_alpha := 0.08 if is_interior else 0.09
			if not is_interior and kind in ["grass", "structure_blocker", "road", "soil", "worn_ground", "hill"]:
				grid_alpha = 0.018
			draw_rect(rect, Color(0.06, 0.08, 0.07, grid_alpha), false, 1.0)
	if render_mode != "terrain":
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
		"palisade":
			color = Color(0.31, 0.18, 0.075)
		"structure_blocker":
			color = Color(0.34, 0.49, 0.27)
		"wood_floor":
			color = Color(0.50, 0.34, 0.18)
		"forest":
			color = Color(0.18, 0.35, 0.17)
		"hill":
			color = Color(0.48, 0.43, 0.31)
		"soil":
			color = Color(0.39, 0.29, 0.17)
		"worn_ground":
			color = Color(0.48, 0.41, 0.30)
		"road":
			color = Color(0.58, 0.51, 0.38)
	return color


func _draw_material_detail(kind: String, rect: Rect2, global_tile: Vector2i) -> void:
	var detail := _hash_detail(global_tile)
	match kind:
		"water":
			_draw_water_detail(rect, global_tile)
		"bridge":
			_draw_bridge_detail(rect)
		"stone_wall":
			_draw_stone_detail(rect)
		"wood_wall":
			_draw_wood_detail(rect, true)
		"palisade":
			_draw_palisade_detail(rect)
		"wood_floor":
			_draw_wood_detail(rect, false)
		"road":
			# Keep dirt continuous across tile seams. Variation is sparse and
			# directional so the road reads as worn ground rather than paving slabs.
			if detail < 7:
				draw_circle(
					rect.position + Vector2(4.0 + float(detail % 4) * 2.4, 5.0 + float(detail % 3) * 2.8),
					3.4 + float(detail % 2),
					Color(0.40, 0.34, 0.24, 0.10)
				)
			if detail in [0, 2, 4, 6]:
				draw_line(
					rect.position + Vector2(0.0, 5.0 + float(detail % 3)),
					rect.position + Vector2(rect.size.x, 6.0 + float((detail + 1) % 3)),
					Color(0.25, 0.20, 0.13, 0.16),
					0.8
				)
			if detail in [1, 4, 7]:
				draw_circle(
					rect.position + Vector2(4.0 + float(detail), 4.0 + float(detail % 4)),
					0.8,
					Color(0.30, 0.27, 0.20, 0.34)
				)
			_draw_surface_edge_detail(rect, global_tile, detail, "road")
		"grass", "structure_blocker":
			_draw_grass_detail(rect, detail)
		"forest":
			_draw_forest_detail(rect, detail)
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
			if detail < 5:
				draw_line(
					rect.position + Vector2(3.0, 13.0),
					rect.position + Vector2(12.0, 10.0),
					Color(0.25, 0.22, 0.15, 0.20),
					0.8
				)
		"soil":
			# Alternating furrows make garden beds legible without turning them
			# into collision or a road-colored rectangle.
			var furrow_y := 4.0 + float(detail % 3)
			for row_index in 3:
				draw_line(
					rect.position + Vector2(2.0, furrow_y + float(row_index) * 4.0),
					rect.position + Vector2(14.0, furrow_y + float(row_index) * 4.0),
					Color(0.20, 0.13, 0.07, 0.35), 1.0
				)
			if detail < 5:
				draw_circle(rect.position + Vector2(5.0 + float(detail), 7.0), 1.2, Color(0.35, 0.55, 0.21, 0.62))
		"worn_ground":
			if detail in [0, 2, 5]:
				draw_circle(
					rect.position + Vector2(5.0 + float(detail % 3) * 2.0, 6.0 + float(detail % 2) * 3.0),
					2.4,
					Color(0.25, 0.19, 0.12, 0.14)
				)
			if detail in [1, 4, 6]:
				draw_line(
					rect.position + Vector2(2.0, 11.0),
					rect.position + Vector2(12.0, 9.0 + float(detail % 2)),
					Color(0.22, 0.17, 0.11, 0.16),
					0.8
				)
			_draw_surface_edge_detail(rect, global_tile, detail, "worn_ground")


func _draw_surface_edge_detail(
	rect: Rect2, global_tile: Vector2i, detail: int, surface_kind: String
) -> void:
	# Break the ruler-straight tile edge without turning every sixteen-pixel
	# boundary into a saw blade. The larger first pass looked generated again.
	var depth_a := 1.0 + float(detail % 2) * 0.5
	var depth_b := 1.0 + float((detail + 1) % 3) * 0.5
	for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var cardinal := Vector2i(direction)
		var neighbor_tile: Vector2i = global_tile + cardinal
		if not tile_kind_by_global.has(neighbor_tile):
			continue
		var neighbor_kind := String(tile_kind_by_global[neighbor_tile])
		if neighbor_kind == surface_kind:
			continue
		var edge_color := _color_for_kind(neighbor_kind)
		var points := PackedVector2Array()
		if cardinal == Vector2i.LEFT:
			points = PackedVector2Array([rect.position, rect.position + Vector2(depth_a, 0), rect.position + Vector2(depth_b, rect.size.y * 0.52), rect.position + Vector2(depth_a, rect.size.y), rect.position + Vector2(0, rect.size.y)])
		elif cardinal == Vector2i.RIGHT:
			points = PackedVector2Array([Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x - depth_a, rect.position.y), Vector2(rect.end.x - depth_b, rect.position.y + rect.size.y * 0.48), Vector2(rect.end.x - depth_a, rect.end.y), rect.end])
		elif cardinal == Vector2i.UP:
			points = PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), Vector2(rect.end.x, rect.position.y + depth_a), Vector2(rect.position.x + rect.size.x * 0.48, rect.position.y + depth_b), Vector2(rect.position.x, rect.position.y + depth_a)])
		else:
			points = PackedVector2Array([Vector2(rect.position.x, rect.end.y), rect.end, Vector2(rect.end.x, rect.end.y - depth_a), Vector2(rect.position.x + rect.size.x * 0.52, rect.end.y - depth_b), Vector2(rect.position.x, rect.end.y - depth_a)])
		draw_polygon(points, PackedColorArray([edge_color]))


func _draw_grass_detail(rect: Rect2, detail: int) -> void:
	if detail > 6:
		return
	var base := rect.position + Vector2(3.5 + float(detail % 4) * 2.1, 12.8)
	var blade := Color(0.14, 0.30, 0.13, 0.42)
	draw_line(base, base + Vector2(1.5, -3.8), blade, 0.8)
	draw_line(base + Vector2(1.2, 0.2), base + Vector2(3.1, -2.7), blade, 0.75)
	if detail < 3:
		draw_line(base + Vector2(-1.0, 0.4), base + Vector2(-1.8, -2.4), blade, 0.7)


func _draw_forest_detail(rect: Rect2, detail: int) -> void:
	var center := rect.get_center() + Vector2(float(detail % 3) - 1.0, float(detail % 2) - 0.5)
	draw_circle(center + Vector2(0.0, 1.5), 5.5, Color(0.07, 0.17, 0.08, 0.34))
	draw_circle(center + Vector2(-2.6, -1.6), 3.6, Color(0.10, 0.26, 0.12, 0.48))
	draw_circle(center + Vector2(2.8, -0.9), 3.2, Color(0.13, 0.30, 0.14, 0.42))
	draw_line(
		center + Vector2(0.0, -0.5),
		center + Vector2(0.0, 5.5),
		Color(0.15, 0.10, 0.05, 0.46),
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


func _draw_palisade_detail(rect: Rect2) -> void:
	var post_color := Color(0.48, 0.29, 0.12)
	for x in [3.0, 8.0, 13.0]:
		draw_polygon(
			PackedVector2Array([
				rect.position + Vector2(x - 2.0, 14.0),
				rect.position + Vector2(x - 2.0, 4.0),
				rect.position + Vector2(x, 1.0),
				rect.position + Vector2(x + 2.0, 4.0),
				rect.position + Vector2(x + 2.0, 14.0)
			]),
			PackedColorArray([post_color])
		)
		draw_line(rect.position + Vector2(x - 1.0, 5.0), rect.position + Vector2(x - 1.0, 13.0), Color(0.74, 0.48, 0.22, 0.34), 1.0)
	for y in [7.0, 12.0]:
		draw_line(rect.position + Vector2(1.0, y), rect.position + Vector2(15.0, y), Color(0.16, 0.085, 0.035), 1.5)


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
	var visual_style := String(structure.get("visual_style", ""))
	var structure_id := String(structure.get("id", ""))
	var anchors := VariantFields.dictionary(structure.get("anchors", {}))
	if visual_style.begins_with("northgate_") or structure_id.begins_with("structure_northgate_"):
		_draw_northgate_structure(rect, visual_style, structure_id, anchors)
		return
	match visual_style:
		"forge_exterior":
			_draw_forge_exterior(rect)
		"forge_interior":
			_draw_forge_interior(rect)
		"shop_front":
			_draw_shop_front(rect)
		"town_hall_exterior":
			_draw_town_hall_exterior(rect)
		"town_hall_interior":
			_draw_town_hall_interior(rect)


func _draw_northgate_structure(
	rect: Rect2, visual_style: String, structure_id: String, anchors: Dictionary
) -> void:
	var tile := float(GridMath.TILE_SIZE)
	var interior := visual_style.ends_with("_interior")
	var variant := absi(structure_id.hash()) % 3
	var size_tiles := Vector2i(
		maxi(1, roundi(rect.size.x / tile)), maxi(1, roundi(rect.size.y / tile))
	)
	var entry_anchor := VariantFields.vector2i_from_pair(
		anchors.get("entry", []), Vector2i(size_tiles.x / 2, size_tiles.y - 1)
	)
	if interior:
		_draw_northgate_interior(rect, visual_style, variant)
		return
	if visual_style.contains("timber_home"):
		_draw_briarwatch_home_exterior_v2(rect, structure_id, variant, entry_anchor)
		return
	_draw_compact_northgate_exterior(
		rect, visual_style, structure_id, variant, entry_anchor
	)
	return

	var shadow := rect.grow(5.0)
	draw_rect(shadow, Color(0.03, 0.025, 0.018, 0.34), true)
	var wall_inset := 5.0 + float(variant) * 2.0
	var body := rect.grow(-wall_inset)
	var body_color := Color(0.42, 0.27, 0.15)
	var roof_color := Color(0.25, 0.12, 0.075)
	var trim_color := Color(0.74, 0.53, 0.29)
	if visual_style.contains("coaching_inn"):
		body_color = Color(0.48, 0.30, 0.16)
		roof_color = Color(0.31, 0.12, 0.075)
		trim_color = Color(0.86, 0.68, 0.36)
	elif visual_style.contains("shop"):
		body_color = Color(0.36, 0.31, 0.19)
		roof_color = Color(0.20, 0.16, 0.12)
		trim_color = Color(0.72, 0.67, 0.42)
	elif visual_style.contains("smithy"):
		body_color = Color(0.33, 0.25, 0.18)
		roof_color = Color(0.19, 0.13, 0.10)
		trim_color = Color(0.84, 0.48, 0.21)
	elif visual_style.contains("shrine"):
		body_color = Color(0.39, 0.40, 0.35)
		roof_color = Color(0.17, 0.20, 0.19)
		trim_color = Color(0.83, 0.70, 0.39)
	elif visual_style.contains("hall"):
		body_color = Color(0.46, 0.32, 0.19)
		roof_color = Color(0.22, 0.12, 0.08)
		trim_color = Color(0.86, 0.67, 0.34)
	elif visual_style.contains("stable") or visual_style.contains("storehouse"):
		body_color = Color(0.37, 0.27, 0.16)
		roof_color = Color(0.23, 0.15, 0.10)

	draw_rect(body, body_color, true)
	draw_rect(body, Color(0.10, 0.055, 0.025, 0.72), false, 1.5)
	var roof_height := clampf(rect.size.y * (0.25 if visual_style.contains("shrine") else 0.38), 22.0, 54.0)
	var roof := Rect2(rect.position + Vector2(-8.0, -8.0), Vector2(rect.size.x + 16.0, roof_height))
	var ridge_x := roof.position.x + roof.size.x * (0.43 + float(variant) * 0.07)
	var roof_points := PackedVector2Array([
		roof.position + Vector2(0.0, roof.size.y),
		roof.position + Vector2(12.0, roof.size.y * 0.42),
		Vector2(ridge_x, roof.position.y),
		roof.position + Vector2(roof.size.x - 12.0, roof.size.y * 0.55),
		roof.position + Vector2(roof.size.x, roof.size.y)
	])
	draw_polygon(roof_points, PackedColorArray([roof_color]))
	draw_polyline(PackedVector2Array([roof_points[0], roof_points[2], roof_points[4]]), Color(0.08, 0.035, 0.02, 0.72), 2.0)
	for x in range(12, int(roof.size.x) - 8, 13):
		draw_line(
			roof.position + Vector2(float(x), roof.size.y * 0.52),
			roof.position + Vector2(float(x + 4), roof.size.y - 3.0),
			Color(0.62, 0.36, 0.18, 0.28), 1.0
		)

	if visual_style.contains("shrine"):
		var altar := Rect2(body.get_center() + Vector2(-12.0, 3.0), Vector2(24.0, 12.0))
		draw_rect(altar, Color(0.22, 0.22, 0.19), true)
		draw_circle(altar.get_center() + Vector2(0.0, -4.0), 4.0, Color(0.95, 0.56, 0.18, 0.8))
	elif visual_style.contains("stable"):
		for x in range(12, int(body.size.x) - 8, 18):
			draw_line(body.position + Vector2(float(x), 8.0), body.position + Vector2(float(x), body.size.y - 4.0), Color(0.17, 0.09, 0.04, 0.56), 2.0)
	elif visual_style.contains("storehouse"):
		draw_rect(Rect2(body.position + Vector2(4.0, body.size.y - 14.0), Vector2(body.size.x - 8.0, 9.0)), Color(0.23, 0.14, 0.07), true)
	elif visual_style.contains("smithy"):
		draw_circle(body.position + Vector2(body.size.x * 0.30, body.size.y * 0.55), 10.0, Color(0.98, 0.39, 0.10, 0.22))
		draw_rect(Rect2(body.position + Vector2(body.size.x * 0.22, body.size.y * 0.52), Vector2(28.0, 10.0)), Color(0.17, 0.18, 0.17), true)
	else:
		var window_y := body.position.y + minf(body.size.y * 0.44, 26.0)
		for x in [body.position.x + 15.0, body.end.x - 25.0]:
			if x + 10.0 < body.end.x:
				draw_rect(Rect2(x, window_y, 10.0, 12.0), Color(0.18, 0.29, 0.28), true)
				draw_line(Vector2(x + 5.0, window_y), Vector2(x + 5.0, window_y + 12.0), trim_color, 1.0)
				draw_line(Vector2(x, window_y + 6.0), Vector2(x + 10.0, window_y + 6.0), trim_color, 1.0)

	var porch_width := minf(42.0, body.size.x * 0.34)
	var porch := Rect2(body.get_center() + Vector2(-porch_width * 0.5, body.size.y * 0.32), Vector2(porch_width, 15.0))
	draw_rect(porch, Color(0.24, 0.13, 0.06), true)
	draw_rect(porch, trim_color, false, 1.0)
	draw_line(porch.position + Vector2(5.0, 0.0), porch.position + Vector2(5.0, 11.0), trim_color, 1.5)
	draw_line(porch.end - Vector2(5.0, 0.0), porch.end - Vector2(5.0, 4.0), trim_color, 1.5)

	if visual_style.contains("inn") or visual_style.contains("shop"):
		var sign_rect := Rect2(body.get_center() + Vector2(-24.0, -body.size.y * 0.12), Vector2(48.0, 12.0))
		draw_rect(sign_rect, Color(0.13, 0.075, 0.035), true)
		draw_rect(sign_rect, trim_color, false, 1.0)
		draw_circle(sign_rect.get_center(), 3.0, Color(0.92, 0.68, 0.22))
	if visual_style.contains("inn") or visual_style.contains("smithy"):
		var chimney := Rect2(body.position + Vector2(body.size.x * 0.72, -18.0), Vector2(10.0, 22.0))
		draw_rect(chimney, Color(0.23, 0.22, 0.19), true)
		draw_rect(chimney, Color(0.06, 0.045, 0.03), false, 1.0)


func _draw_briarwatch_home_exterior_v2(
	rect: Rect2, structure_id: String, variant: int, entry_anchor: Vector2i
) -> void:
	_draw_northgate_topdown_exterior(
		rect, "northgate_timber_home", structure_id, variant, entry_anchor
	)
	return
	var tile := float(GridMath.TILE_SIZE)
	var size_tiles := Vector2i(
		maxi(1, roundi(rect.size.x / tile)), maxi(1, roundi(rect.size.y / tile))
	)
	var facade := rect.grow(-3.0)
	var side := _entry_side(entry_anchor, size_tiles)
	var wall_colors := [
		Color(0.43, 0.27, 0.14), Color(0.36, 0.23, 0.13), Color(0.47, 0.29, 0.14)
	]
	var timber := Color(0.13, 0.06, 0.025)
	var warm_trim := Color(0.48, 0.30, 0.13)
	draw_rect(facade.grow(3.0), Color(0.025, 0.018, 0.012, 0.34), true)

	# Harrow's forge language: a readable wall face beneath a steep, uneven
	# roof. The previous pass roofed almost the whole footprint and reduced the
	# cottage to a flat bar.
	var wall_height := 44.0
	var front_wall := Rect2(
		Vector2(facade.position.x + 2.0, facade.end.y - wall_height),
		Vector2(facade.size.x - 4.0, wall_height - 1.0)
	)
	draw_rect(front_wall, wall_colors[variant], true)
	var facade_texture: Texture2D = NORTHGATE_COTTAGE_FACADES[variant]
	if structure_id.contains("south_home") and not structure_id.contains("southeast"):
		facade_texture = NORTHGATE_COTTAGE_FACADES[3]
	draw_texture_rect(facade_texture, front_wall, false)
	draw_rect(front_wall, timber, false, 1.0)

	var roof_index := variant
	if structure_id.contains("south_home") and not structure_id.contains("southeast"):
		roof_index = 3
	elif structure_id.contains("southeast_home"):
		roof_index = 2
	elif structure_id.contains("far_east_home"):
		roof_index = 1
	var roof_texture: Texture2D = NORTHGATE_COTTAGE_ROOFS[roof_index]
	var roof_rect := Rect2(
		facade.position + Vector2(-3.0, -2.0),
		Vector2(facade.size.x + 6.0, minf(72.0, facade.size.y * 0.78))
	)
	draw_texture_rect(roof_texture, roof_rect, false)

	var wall_strip: Rect2
	match side:
		"north":
			wall_strip = Rect2(facade.position + Vector2(3, 1), Vector2(facade.size.x - 6, 13))
		"west":
			wall_strip = Rect2(facade.position + Vector2(1, 8), Vector2(13, facade.size.y - 11))
		"east":
			wall_strip = Rect2(Vector2(facade.end.x - 14, facade.position.y + 8), Vector2(13, facade.size.y - 11))
		_:
			wall_strip = front_wall
	if side != "south":
		draw_rect(wall_strip, wall_colors[variant].darkened(0.10), true)
		draw_rect(wall_strip, timber, false, 1.5)

	var entry := _exterior_entry_rect(facade, entry_anchor, size_tiles, 12.0)
	draw_rect(entry, Color(0.075, 0.038, 0.018), true)
	draw_rect(entry, warm_trim, false, 1.0)
	draw_circle(entry.get_center() + Vector2(2.5, 0.0), 1.1, Color(0.70, 0.50, 0.20))
	# Small, low-tech household identifiers. These read as lived-in craft,
	# garden, courier, kitchen, and lodging details without changing canon.
	if structure_id.contains("west_home"):
		for offset in [0.0, 6.0, 12.0]:
			draw_line(
				facade.position + Vector2(8.0 + offset, facade.size.y - 7.0),
				facade.position + Vector2(11.0 + offset, facade.size.y - 2.0),
				Color(0.62, 0.45, 0.22), 1.5
			)
	elif structure_id.contains("south_home"):
		for offset in [-7.0, 0.0, 7.0]:
			draw_circle(entry.get_center() + Vector2(offset, -9.0), 1.8, Color(0.58, 0.19, 0.13))
	elif structure_id.contains("east_home") and not structure_id.contains("southeast") and not structure_id.contains("far_east"):
		var mark := facade.get_center() + Vector2(0.0, -2.0)
		draw_polyline(
			PackedVector2Array([mark + Vector2(-5, 2), mark + Vector2(0, -3), mark + Vector2(5, 2)]),
			Color(0.67, 0.43, 0.16), 2.0
		)
	elif structure_id.contains("southeast_home"):
		for y in range(5, int(facade.size.y) - 3, 6):
			draw_circle(facade.position + Vector2(5.0, float(y)), 2.0, Color(0.22, 0.42, 0.16))
	elif structure_id.contains("far_east_home"):
		var sign := Rect2(facade.end - Vector2(19.0, 14.0), Vector2(13.0, 8.0))
		draw_rect(sign, Color(0.26, 0.13, 0.05), true)
		draw_circle(sign.get_center(), 2.0, Color(0.70, 0.48, 0.18))

	if variant == 1:
		var chimney := Rect2(facade.position + Vector2(facade.size.x * 0.70, 4.0), Vector2(8.0, 9.0))
		draw_rect(chimney, Color(0.30, 0.29, 0.26), true)
		draw_rect(chimney, Color(0.08, 0.06, 0.04), false, 1.0)


func _draw_northgate_topdown_exterior(
	rect: Rect2,
	visual_style: String,
	structure_id: String,
	variant: int,
	entry_anchor: Vector2i
) -> void:
	if visual_style.contains("coaching_inn"):
		_draw_northgate_coaching_inn_exterior(rect)
		return
	var tile := float(GridMath.TILE_SIZE)
	var size_tiles := Vector2i(
		maxi(1, roundi(rect.size.x / tile)), maxi(1, roundi(rect.size.y / tile))
	)
	var side := _entry_side(entry_anchor, size_tiles)
	var body := rect.grow(-3.0)
	var is_home := visual_style.contains("timber_home")
	var wall_depth := 11.0 if is_home else 14.0
	var wall_color := Color(0.43, 0.27, 0.14)
	var timber := Color(0.12, 0.055, 0.025)
	var trim := Color(0.57, 0.36, 0.15)
	if visual_style.contains("shrine"):
		wall_color = Color(0.40, 0.40, 0.35)
		timber = Color(0.17, 0.17, 0.15)
		trim = Color(0.66, 0.60, 0.38)
	elif visual_style.contains("smithy"):
		wall_color = Color(0.33, 0.24, 0.16)
		trim = Color(0.60, 0.32, 0.14)
	elif visual_style.contains("shop"):
		wall_color = Color(0.44, 0.33, 0.19)
	elif visual_style.contains("hall") or visual_style.contains("coaching_inn"):
		wall_color = Color(0.48, 0.30, 0.16)
		trim = Color(0.66, 0.44, 0.20)

	# A grounded top-down building: full footprint shadow, narrow visible wall on
	# the entry edge, and a roof covering the rest. This is the same spatial
	# grammar as Harrow's forge and prevents side doors from floating on facades.
	draw_rect(body.grow(5.0), Color(0.025, 0.018, 0.012, 0.34), true)
	draw_rect(body, wall_color, true)
	draw_rect(body, timber, false, 1.5)
	var wall_strip := _northgate_wall_strip(body, side, wall_depth)
	var roof_rect := _northgate_roof_rect(body, side, wall_depth).grow(3.0)

	var roof_texture: Texture2D
	if is_home:
		roof_texture = NORTHGATE_HOME_ROOFS_V2.get(
			structure_id, NORTHGATE_COTTAGE_ROOFS[variant]
		)
	else:
		var roof_key := "utility"
		if visual_style.contains("coaching_inn"):
			roof_key = "inn"
		elif visual_style.contains("smithy"):
			roof_key = "smithy"
		elif visual_style.contains("hall") or visual_style.contains("shrine"):
			roof_key = "civic"
		roof_texture = NORTHGATE_SERVICE_ROOFS_V2.get(
			structure_id, NORTHGATE_SERVICE_ROOFS[roof_key]
		)
	draw_texture_rect(roof_texture, roof_rect, false)
	draw_rect(roof_rect.grow(-2.0), Color(0.07, 0.035, 0.02, 0.55), false, 1.2)
	_draw_northgate_lean_to_annex(roof_rect, structure_id, side)

	# Repaint the inhabited edge over the eaves, then place the authoritative
	# portal exactly in that edge.
	draw_rect(wall_strip, wall_color, true)
	draw_rect(wall_strip, timber, false, 1.2)
	_northgate_wall_beams(wall_strip, side, timber)
	var entry := _exterior_entry_rect(body, entry_anchor, size_tiles, 12.0 if is_home else 15.0)
	draw_rect(entry, Color(0.075, 0.038, 0.018), true)
	draw_rect(entry, trim, false, 1.2)
	draw_circle(entry.get_center() + (Vector2(2.5, 0.0) if side in ["north", "south"] else Vector2(0.0, 2.5)), 1.1, Color(0.76, 0.55, 0.22))
	_northgate_entry_step(entry, side)
	_draw_home_windows(body, wall_strip, entry, side, trim)
	_northgate_landmark_details(body, roof_rect, entry, side, visual_style, structure_id, variant)


func _draw_northgate_coaching_inn_exterior(rect: Rect2) -> void:
	var body := rect.grow(-3.0)
	draw_rect(body.grow(5.0), Color(0.025, 0.018, 0.012, 0.34), true)
	var roof: Texture2D = NORTHGATE_SERVICE_ROOFS_V2["structure_northgate_inn_plot"]
	draw_texture_rect(roof, body.grow(3.0), false)
	# The authored portal is the center of west tile (0, 1). The replacement
	# annex's painted door sits near 59%/78% of its source sprite.
	var portal_center := rect.position + Vector2(16.0, 48.0)
	var entrance_size := Vector2(42.0, 64.0)
	var painted_door_center := entrance_size * Vector2(0.59, 0.78)
	var entrance := Rect2(portal_center - painted_door_center, entrance_size)
	draw_texture_rect(NORTHGATE_INN_WEST_ENTRANCE, entrance, false)


func _draw_northgate_lean_to_annex(
	roof: Rect2, structure_id: String, side: String
) -> void:
	if not structure_id in [
		"structure_northgate_west_home_plot",
		"structure_northgate_far_east_home_plot",
		"structure_northgate_shop_plot",
		"structure_northgate_store_plot"
	]:
		return
	var texture: Texture2D = NORTHGATE_LEAN_TO_ROOFS[absi(structure_id.hash()) % 2]
	var annex_size := Vector2(minf(30.0, roof.size.x * 0.32), roof.size.y * 0.72)
	var annex_position := Vector2(roof.end.x - annex_size.x + 2.0, roof.position.y + roof.size.y * 0.18)
	if structure_id.contains("far_east"):
		annex_position.x = roof.position.x - 2.0
	if side in ["west", "east"]:
		annex_size = Vector2(roof.size.x * 0.70, minf(30.0, roof.size.y * 0.38))
		annex_position = Vector2(roof.position.x + roof.size.x * 0.15, roof.end.y - annex_size.y + 2.0)
	draw_texture_rect(texture, Rect2(annex_position, annex_size), false)


func _northgate_wall_strip(body: Rect2, side: String, depth: float) -> Rect2:
	match side:
		"north":
			return Rect2(body.position, Vector2(body.size.x, depth))
		"west":
			return Rect2(body.position, Vector2(depth, body.size.y))
		"east":
			return Rect2(Vector2(body.end.x - depth, body.position.y), Vector2(depth, body.size.y))
	return Rect2(Vector2(body.position.x, body.end.y - depth), Vector2(body.size.x, depth))


func _northgate_roof_rect(body: Rect2, side: String, depth: float) -> Rect2:
	match side:
		"north":
			return Rect2(body.position + Vector2(0.0, depth), Vector2(body.size.x, body.size.y - depth))
		"west":
			return Rect2(body.position + Vector2(depth, 0.0), Vector2(body.size.x - depth, body.size.y))
		"east":
			return Rect2(body.position, Vector2(body.size.x - depth, body.size.y))
	return Rect2(body.position, Vector2(body.size.x, body.size.y - depth))


func _northgate_roof_ridge(roof: Rect2, side: String, variant: int) -> void:
	var ridge := Color(0.08, 0.04, 0.022, 0.62)
	var offset := (float(variant) - 1.0) * 2.0
	if side in ["north", "south"]:
		var y := roof.position.y + roof.size.y * 0.48 + offset
		draw_line(Vector2(roof.position.x + 6.0, y), Vector2(roof.end.x - 6.0, y), ridge, 1.4)
	else:
		var x := roof.position.x + roof.size.x * 0.48 + offset
		draw_line(Vector2(x, roof.position.y + 6.0), Vector2(x, roof.end.y - 6.0), ridge, 1.4)


func _northgate_wall_beams(wall: Rect2, side: String, timber: Color) -> void:
	if side in ["north", "south"]:
		for x in range(12, int(wall.size.x) - 5, 24):
			draw_line(wall.position + Vector2(float(x), 1.0), wall.position + Vector2(float(x), wall.size.y - 1.0), timber, 1.2)
	else:
		for y in range(12, int(wall.size.y) - 5, 24):
			draw_line(wall.position + Vector2(1.0, float(y)), wall.position + Vector2(wall.size.x - 1.0, float(y)), timber, 1.2)


func _northgate_entry_step(entry: Rect2, side: String) -> void:
	var step := entry.grow(2.0)
	match side:
		"north": step = Rect2(Vector2(entry.position.x - 2.0, entry.position.y - 4.0), Vector2(entry.size.x + 4.0, 4.0))
		"south": step = Rect2(Vector2(entry.position.x - 2.0, entry.end.y), Vector2(entry.size.x + 4.0, 4.0))
		"west": step = Rect2(Vector2(entry.position.x - 4.0, entry.position.y - 2.0), Vector2(4.0, entry.size.y + 4.0))
		"east": step = Rect2(Vector2(entry.end.x, entry.position.y - 2.0), Vector2(4.0, entry.size.y + 4.0))
	draw_rect(step, Color(0.31, 0.29, 0.24), true)
	draw_rect(step, Color(0.10, 0.08, 0.055), false, 1.0)


func _northgate_landmark_details(
	body: Rect2,
	roof: Rect2,
	entry: Rect2,
	side: String,
	visual_style: String,
	structure_id: String,
	variant: int
) -> void:
	if visual_style.contains("coaching_inn"):
		var chimney := Rect2(roof.position + Vector2(roof.size.x * 0.72, roof.size.y * 0.22), Vector2(9.0, 13.0))
		draw_rect(chimney, Color(0.25, 0.24, 0.21), true)
		draw_rect(chimney, Color(0.07, 0.055, 0.04), false, 1.0)
		_northgate_hanging_sign(entry, side, Color(0.72, 0.48, 0.18))
	elif visual_style.contains("shop"):
		_northgate_hanging_sign(entry, side, Color(0.58, 0.39, 0.16))
	elif visual_style.contains("smithy"):
		var chimney := Rect2(roof.position + Vector2(roof.size.x * 0.24, roof.size.y * 0.28), Vector2(11.0, 14.0))
		draw_rect(chimney, Color(0.22, 0.22, 0.20), true)
		draw_rect(chimney, Color(0.06, 0.05, 0.04), false, 1.0)
		draw_circle(chimney.get_center(), 2.2, Color(0.03, 0.025, 0.02))
	elif visual_style.contains("hall"):
		var cupola := Rect2(roof.get_center() - Vector2(10.0, 9.0), Vector2(20.0, 18.0))
		draw_rect(cupola, Color(0.34, 0.20, 0.10), true)
		draw_rect(cupola, Color(0.12, 0.06, 0.025), false, 1.0)
		draw_polygon(PackedVector2Array([cupola.position + Vector2(-3, 3), cupola.position + Vector2(10, -6), cupola.position + Vector2(23, 3)]), PackedColorArray([Color(0.20, 0.095, 0.05)]))
	elif visual_style.contains("guard"):
		var deck := Rect2(roof.get_center() - Vector2(15.0, 12.0), Vector2(30.0, 24.0))
		draw_rect(deck, Color(0.26, 0.14, 0.06), false, 3.0)
		for corner in [deck.position, Vector2(deck.end.x, deck.position.y), Vector2(deck.position.x, deck.end.y), deck.end]:
			draw_circle(corner, 2.3, Color(0.42, 0.25, 0.10))
	elif visual_style.contains("shrine"):
		var cap := roof.get_center()
		draw_circle(cap, 7.0, Color(0.30, 0.31, 0.28))
		draw_circle(cap, 3.0, Color(0.88, 0.57, 0.19))
	elif visual_style.contains("stable"):
		# Open stalls make the stable read differently from a warehouse without
		# using a modern glass frontage.
		for index in 3:
			var stall := Rect2(
				body.position + Vector2(8.0 + float(index) * 25.0, body.size.y - 17.0),
				Vector2(18.0, 12.0)
			)
			draw_rect(stall, Color(0.12, 0.065, 0.03), true)
			draw_rect(stall, Color(0.48, 0.30, 0.13), false, 1.2)
	elif visual_style.contains("storehouse"):
		for index in 3:
			var vent := roof.position + Vector2(roof.size.x * 0.28 + float(index) * 18.0, roof.size.y * 0.52)
			draw_line(vent - Vector2(4, 0), vent + Vector2(4, 0), Color(0.10, 0.055, 0.025), 2.0)
	elif is_home_marker(structure_id):
		var hearth := roof.position + Vector2(roof.size.x * (0.68 if variant == 1 else 0.28), roof.size.y * 0.30)
		draw_rect(Rect2(hearth, Vector2(7.0, 9.0)), Color(0.29, 0.28, 0.25), true)


func is_home_marker(structure_id: String) -> bool:
	return structure_id.contains("_home_plot")


func _northgate_hanging_sign(entry: Rect2, side: String, color: Color) -> void:
	var center := entry.get_center()
	var offset := Vector2(18.0, -8.0) if side in ["north", "south"] else Vector2(8.0, 18.0)
	var post_end := center + offset
	draw_line(center, post_end, Color(0.13, 0.07, 0.03), 2.0)
	draw_rect(Rect2(post_end - Vector2(6.0, 4.0), Vector2(12.0, 8.0)), color.darkened(0.45), true)
	draw_rect(Rect2(post_end - Vector2(6.0, 4.0), Vector2(12.0, 8.0)), color, false, 1.0)


func _entry_side(entry_anchor: Vector2i, size_tiles: Vector2i) -> String:
	if entry_anchor.y <= 0:
		return "north"
	if entry_anchor.y >= size_tiles.y - 1:
		return "south"
	if entry_anchor.x <= 0:
		return "west"
	if entry_anchor.x >= size_tiles.x - 1:
		return "east"
	return "south"


func _exterior_entry_rect(
	facade: Rect2, entry_anchor: Vector2i, size_tiles: Vector2i, span: float
) -> Rect2:
	var side := _entry_side(entry_anchor, size_tiles)
	var x_ratio := (float(entry_anchor.x) + 0.5) / float(maxi(size_tiles.x, 1))
	var y_ratio := (float(entry_anchor.y) + 0.5) / float(maxi(size_tiles.y, 1))
	var point := facade.position + Vector2(facade.size.x * x_ratio, facade.size.y * y_ratio)
	if side == "north":
		return Rect2(Vector2(point.x - span * 0.5, facade.position.y), Vector2(span, 10.0))
	if side == "south":
		return Rect2(Vector2(point.x - span * 0.5, facade.end.y - 10.0), Vector2(span, 10.0))
	if side == "west":
		return Rect2(Vector2(facade.position.x, point.y - span * 0.5), Vector2(10.0, span))
	return Rect2(Vector2(facade.end.x - 10.0, point.y - span * 0.5), Vector2(10.0, span))


func _draw_home_windows(
	facade: Rect2, wall_strip: Rect2, entry: Rect2, side: String, trim: Color
) -> void:
	var centers: Array[Vector2] = []
	if side in ["north", "south"]:
		centers = [
			Vector2(facade.position.x + facade.size.x * 0.24, wall_strip.get_center().y),
			Vector2(facade.position.x + facade.size.x * 0.76, wall_strip.get_center().y)
		]
	else:
		centers = [
			Vector2(wall_strip.get_center().x, facade.position.y + facade.size.y * 0.27),
			Vector2(wall_strip.get_center().x, facade.position.y + facade.size.y * 0.73)
		]
	for center in centers:
		if entry.grow(3.0).has_point(center):
			continue
		var window_size := Vector2(8.0, 6.0) if side in ["north", "south"] else Vector2(6.0, 8.0)
		var window := Rect2(center - window_size * 0.5, window_size)
		draw_rect(window, Color(0.28, 0.18, 0.08), true)
		draw_rect(window, Color(0.74, 0.50, 0.20, 0.78), false, 1.0)
		if side in ["north", "south"]:
			draw_rect(Rect2(window.position - Vector2(3, 0), Vector2(2, window.size.y)), Color(0.16, 0.075, 0.03), true)
			draw_rect(Rect2(Vector2(window.end.x + 1, window.position.y), Vector2(2, window.size.y)), Color(0.16, 0.075, 0.03), true)
		else:
			draw_rect(Rect2(window.position - Vector2(0, 3), Vector2(window.size.x, 2)), Color(0.16, 0.075, 0.03), true)
			draw_rect(Rect2(Vector2(window.position.x, window.end.y + 1), Vector2(window.size.x, 2)), Color(0.16, 0.075, 0.03), true)
		draw_circle(window.get_center(), 0.8, trim)


func _draw_briarwatch_home_exterior(rect: Rect2, structure_id: String, variant: int) -> void:
	var tile := float(GridMath.TILE_SIZE)
	var facade_size := Vector2(minf(rect.size.x - tile, tile * 6.0), tile * 3.0)
	var facade_position := rect.position + Vector2(
		(rect.size.x - facade_size.x) * 0.5, rect.size.y - facade_size.y - tile
	)
	if structure_id.contains("west_home"):
		facade_position = Vector2(rect.end.x - facade_size.x - 2.0, rect.position.y + (rect.size.y - facade_size.y) * 0.5)
	elif structure_id.contains("east_home"):
		facade_position = Vector2(rect.position.x + 2.0, rect.position.y + (rect.size.y - facade_size.y) * 0.5)

	var facade := Rect2(facade_position, facade_size)
	draw_rect(facade.grow(4.0), Color(0.03, 0.025, 0.018, 0.28), true)
	var wall := Rect2(facade.position + Vector2(0.0, tile * 1.35), Vector2(facade.size.x, tile * 1.65))
	var wall_colors := [Color(0.45, 0.29, 0.16), Color(0.39, 0.25, 0.14), Color(0.50, 0.31, 0.16)]
	var roof_colors := [Color(0.30, 0.13, 0.065), Color(0.24, 0.105, 0.055), Color(0.35, 0.16, 0.08)]
	draw_rect(wall, wall_colors[variant], true)
	draw_rect(wall, Color(0.08, 0.045, 0.025, 0.62), false, 1.0)
	var beam_color := Color(0.15, 0.075, 0.03, 0.72)
	draw_line(
		wall.position + Vector2(0.0, wall.size.y * 0.52),
		wall.position + Vector2(wall.size.x, wall.size.y * 0.52),
		beam_color, 2.0
	)
	for x in [tile, tile * 2.0, tile * 4.0, tile * 5.0]:
		draw_line(
			wall.position + Vector2(x, 2.0),
			wall.position + Vector2(x + 2.0, wall.size.y - 3.0),
			Color(0.18, 0.09, 0.035, 0.34), 1.0
		)
	for corner_x in [3.0, wall.size.x - 3.0]:
		var direction := 1.0 if corner_x < wall.size.x * 0.5 else -1.0
		draw_line(
			wall.position + Vector2(corner_x, wall.size.y - 3.0),
			wall.position + Vector2(corner_x + direction * 13.0, wall.size.y * 0.52),
			beam_color, 2.0
		)
	for stone_x in range(2, int(wall.size.x) - 5, 11):
		draw_rect(
			Rect2(wall.position + Vector2(float(stone_x), wall.size.y - 4.0), Vector2(9.0, 4.0)),
			Color(0.33, 0.33, 0.29), true
		)
	var roof := Rect2(facade.position + Vector2(-5.0, -7.0), Vector2(facade.size.x + 10.0, 34.0))
	draw_polygon(
		PackedVector2Array([
			roof.position + Vector2(0.0, 8.0),
			roof.position + Vector2(roof.size.x * (0.46 + variant * 0.04), 0.0),
			roof.position + Vector2(roof.size.x, 8.0),
			roof.position + Vector2(roof.size.x, roof.size.y),
			roof.position + Vector2(0.0, roof.size.y)
		]),
		PackedColorArray([roof_colors[variant]])
	)
	draw_line(roof.position + Vector2(5.0, 26.0), roof.end - Vector2(4.0, 5.0), Color(0.05, 0.02, 0.01, 0.42), 2.0)
	draw_line(
		roof.position + Vector2(2.0, roof.size.y - 4.0),
		roof.position + Vector2(roof.size.x - 2.0, roof.size.y - 4.0),
		Color(0.78, 0.48, 0.21, 0.34), 2.0
	)
	for offset in [11.0, 27.0, 43.0, 59.0, 75.0]:
		draw_line(
			roof.position + Vector2(offset, 9.0),
			roof.position + Vector2(offset + 3.0, roof.size.y - 4.0),
			Color(0.56, 0.30, 0.14, 0.24), 1.0
		)
	var entry := Rect2(facade.position + Vector2(facade.size.x * 0.5 - 10.0, tile * 2.0), Vector2(20.0, tile))
	draw_rect(entry.grow(-2.0), Color(0.08, 0.045, 0.025, 0.9), true)
	draw_rect(entry.grow(-1.0), Color(0.78, 0.56, 0.25, 0.32), false, 1.0)
	draw_circle(entry.position + Vector2(14.0, 8.0), 1.3, Color(0.84, 0.64, 0.26))
	draw_rect(Rect2(entry.position + Vector2(-7.0, 10.0), Vector2(34.0, 5.0)), Color(0.24, 0.13, 0.06), true)
	for x in [12.0, facade.size.x - 28.0]:
		var window := Rect2(facade.position + Vector2(x, tile * 1.65), Vector2(16.0, 12.0))
		draw_rect(window, Color(0.20, 0.31, 0.29), true)
		draw_rect(window, Color(0.82, 0.62, 0.29, 0.8), false, 1.0)
		draw_line(window.get_center() - Vector2(0.0, 6.0), window.get_center() + Vector2(0.0, 6.0), Color(0.82, 0.62, 0.29, 0.75), 1.0)
	if structure_id.contains("west_home"):
		var craft_board := Rect2(facade.position + Vector2(4.0, tile * 2.35), Vector2(22.0, 6.0))
		draw_rect(craft_board, Color(0.26, 0.13, 0.055), true)
		for x in [6.0, 11.0, 16.0]:
			draw_line(craft_board.position + Vector2(x, 1.0), craft_board.position + Vector2(x + 2.0, 5.0), Color(0.76, 0.58, 0.30), 1.0)
	elif structure_id.contains("south_home"):
		var flower_box := Rect2(facade.position + Vector2(8.0, tile * 2.42), Vector2(26.0, 5.0))
		draw_rect(flower_box, Color(0.28, 0.15, 0.06), true)
		for x in [5.0, 12.0, 19.0]:
			draw_circle(flower_box.position + Vector2(x, -2.0), 2.0, Color(0.69, 0.25 + x * 0.005, 0.20))
	elif structure_id.contains("east_home") and not structure_id.contains("southeast") and not structure_id.contains("far_east"):
		var route_mark := facade.position + Vector2(facade.size.x * 0.5, tile * 1.58)
		draw_polyline(PackedVector2Array([route_mark + Vector2(-5, 0), route_mark + Vector2(0, -4), route_mark + Vector2(5, 0)]), Color(0.38, 0.66, 0.70), 2.0)
	elif structure_id.contains("southeast_home"):
		for y in range(0, 20, 5):
			draw_circle(facade.position + Vector2(5.0 + float(y % 3), tile * 1.45 + float(y)), 2.4, Color(0.25, 0.48, 0.19))
	elif structure_id.contains("far_east_home"):
		var lodging_sign := Rect2(facade.end - Vector2(22.0, tile * 1.25), Vector2(16.0, 10.0))
		draw_line(lodging_sign.position + Vector2(8.0, -5.0), lodging_sign.position + Vector2(8.0, 0.0), beam_color, 1.5)
		draw_rect(lodging_sign, Color(0.30, 0.16, 0.07), true)
		draw_circle(lodging_sign.get_center(), 2.5, Color(0.88, 0.68, 0.27))
	if variant == 1:
		var chimney := Rect2(facade.position + Vector2(facade.size.x * 0.72, -9.0), Vector2(8.0, 17.0))
		draw_rect(chimney, Color(0.25, 0.23, 0.20), true)
		draw_rect(chimney, Color(0.06, 0.045, 0.03), false, 1.0)


func _draw_compact_northgate_exterior(
	rect: Rect2,
	visual_style: String,
	structure_id: String,
	variant: int,
	entry_anchor: Vector2i
) -> void:
	_draw_northgate_topdown_exterior(
		rect, visual_style, structure_id, variant, entry_anchor
	)
	return
	var tile := float(GridMath.TILE_SIZE)
	var size_tiles := Vector2i(
		maxi(1, roundi(rect.size.x / tile)), maxi(1, roundi(rect.size.y / tile))
	)
	var facade := rect.grow(-2.0)
	draw_rect(facade.grow(5.0), Color(0.03, 0.025, 0.018, 0.28), true)
	var wall_height := clampf(facade.size.y * 0.38, 34.0, 64.0)
	if visual_style.contains("stable") or visual_style.contains("storehouse"):
		wall_height = clampf(facade.size.y * 0.46, 40.0, 82.0)
	var wall := Rect2(
		Vector2(facade.position.x, facade.end.y - wall_height),
		Vector2(facade.size.x, wall_height)
	)
	var wall_color := Color(0.42, 0.27, 0.15)
	var roof_color := Color(0.28, 0.12, 0.06)
	var trim_color := Color(0.48, 0.32, 0.15)
	if visual_style.contains("coaching_inn"):
		wall_color = Color(0.47, 0.29, 0.15)
		roof_color = Color(0.32, 0.13, 0.065)
		trim_color = Color(0.62, 0.42, 0.20)
	elif visual_style.contains("shrine"):
		wall_color = Color(0.38, 0.39, 0.34)
		roof_color = Color(0.17, 0.19, 0.17)
		trim_color = Color(0.58, 0.52, 0.32)
	elif visual_style.contains("smithy"):
		wall_color = Color(0.33, 0.24, 0.16)
		roof_color = Color(0.19, 0.12, 0.075)
		trim_color = Color(0.58, 0.31, 0.14)
	elif visual_style.contains("shop"):
		wall_color = Color(0.42, 0.31, 0.17)
		roof_color = Color(0.23, 0.15, 0.09)
		trim_color = Color(0.56, 0.42, 0.20)
	draw_rect(wall, wall_color, true)
	draw_rect(wall, Color(0.08, 0.045, 0.025, 0.62), false, 1.0)
	var roof_key := "utility"
	if visual_style.contains("coaching_inn"):
		roof_key = "inn"
	elif visual_style.contains("smithy"):
		roof_key = "smithy"
	elif visual_style.contains("hall") or visual_style.contains("shrine"):
		roof_key = "civic"
	var facade_texture: Texture2D = NORTHGATE_SERVICE_FACADES[roof_key]
	if visual_style.contains("shop"):
		facade_texture = NORTHGATE_COTTAGE_FACADES[2]
	elif visual_style.contains("guard"):
		facade_texture = NORTHGATE_COTTAGE_FACADES[0]
	draw_texture_rect(facade_texture, wall, false)
	var roof_texture: Texture2D = NORTHGATE_SERVICE_ROOFS[roof_key]
	var roof := Rect2(
		facade.position + Vector2(-5.0, -2.0),
		Vector2(facade.size.x + 10.0, wall.position.y - facade.position.y + 12.0)
	)
	draw_texture_rect(roof_texture, roof, false)
	var entry := _exterior_entry_rect(facade, entry_anchor, size_tiles, 16.0)
	draw_rect(entry.grow(-2.0), Color(0.08, 0.045, 0.025, 0.9), true)
	draw_rect(entry.grow(-1.0), trim_color, false, 1.0)
	draw_circle(entry.get_center() + Vector2(2.0, 0.0), 1.3, Color(0.86, 0.66, 0.28))
	# Painted facade modules now carry windows, bays, shutters, plaster, stone,
	# and work character. Keep only landmark silhouettes that are not part of the
	# facade source; legacy porch/sign/display overlays made the art look like UI.
	if visual_style.contains("hall"):
		var cupola := Rect2(Vector2(facade.get_center().x - 13.0, roof.position.y - 23.0), Vector2(26.0, 24.0))
		draw_rect(cupola, Color(0.36, 0.21, 0.11), true)
		draw_rect(cupola, trim_color, false, 1.0)
		draw_polygon(
			PackedVector2Array([cupola.position + Vector2(-4, 1), cupola.position + Vector2(13, -10), cupola.position + Vector2(30, 1)]),
			PackedColorArray([roof_color])
		)
		draw_circle(cupola.get_center() + Vector2(0, 2), 5.0, Color(0.56, 0.42, 0.20))
	elif visual_style.contains("guard"):
		var watch_deck := Rect2(facade.position + Vector2(facade.size.x - 54.0, -18.0), Vector2(44.0, 12.0))
		draw_rect(watch_deck, Color(0.27, 0.15, 0.07), true)
		draw_line(watch_deck.position, watch_deck.position + Vector2(0, 24), trim_color, 2.0)
		draw_line(watch_deck.end - Vector2(0, watch_deck.size.y), watch_deck.end + Vector2(0, 12), trim_color, 2.0)
	elif visual_style.contains("shrine"):
		var arch_center := entry.get_center() - Vector2(0, 2)
		draw_arc(arch_center, 16.0, PI, TAU, 18, Color(0.68, 0.69, 0.61), 4.0)
		draw_line(arch_center + Vector2(-16, 0), arch_center + Vector2(-16, 18), Color(0.56, 0.57, 0.52), 4.0)
		draw_line(arch_center + Vector2(16, 0), arch_center + Vector2(16, 18), Color(0.56, 0.57, 0.52), 4.0)
	return
	if visual_style.contains("coaching_inn") or visual_style.contains("shop"):
		var sign_rect := Rect2(wall.get_center() + Vector2(-24.0, -wall.size.y * 0.18), Vector2(48.0, 12.0))
		draw_rect(sign_rect, Color(0.13, 0.075, 0.035), true)
		draw_rect(sign_rect, trim_color, false, 1.0)
		draw_circle(sign_rect.get_center(), 3.0, Color(0.94, 0.68, 0.22))
	if visual_style.contains("coaching_inn") or visual_style.contains("smithy"):
		var chimney := Rect2(facade.position + Vector2(facade.size.x * 0.72, -10.0), Vector2(9.0, 19.0))
		draw_rect(chimney, Color(0.24, 0.22, 0.19), true)
		draw_rect(chimney, Color(0.06, 0.045, 0.03), false, 1.0)
	if visual_style.contains("stable"):
		for x in range(14, int(facade.size.x) - 10, 24):
			draw_line(wall.position + Vector2(x, 2.0), wall.position + Vector2(x, wall.size.y - 3.0), Color(0.18, 0.09, 0.035, 0.56), 2.0)
		draw_circle(wall.position + Vector2(facade.size.x - 18.0, wall.size.y - 8.0), 6.0, Color(0.76, 0.54, 0.23))
	if visual_style.contains("smithy"):
		draw_circle(wall.position + Vector2(wall.size.x * 0.28, wall.size.y * 0.56), 10.0, Color(0.98, 0.39, 0.10, 0.24))
		draw_rect(Rect2(wall.position + Vector2(wall.size.x * 0.22, wall.size.y * 0.52), Vector2(28.0, 9.0)), Color(0.15, 0.16, 0.15), true)
	if visual_style.contains("shrine"):
		draw_circle(wall.get_center() + Vector2(0.0, -4.0), 5.0, Color(0.96, 0.58, 0.18, 0.82))
	if visual_style.contains("hall"):
		draw_rect(Rect2(wall.position + Vector2(8.0, 5.0), Vector2(wall.size.x - 16.0, 9.0)), Color(0.14, 0.075, 0.035), true)
		draw_rect(Rect2(wall.position + Vector2(10.0, 7.0), Vector2(wall.size.x - 20.0, 5.0)), trim_color, false, 1.0)
	if visual_style.contains("coaching_inn"):
		var porch := Rect2(facade.position + Vector2(facade.size.x * 0.12, facade.size.y - tile * 0.7), Vector2(facade.size.x * 0.52, tile * 0.72))
		draw_rect(porch, Color(0.24, 0.12, 0.055), true)
		draw_rect(porch, trim_color, false, 1.0)
		for post_x in [porch.position.x + 8.0, porch.end.x - 8.0]:
			draw_line(Vector2(post_x, porch.position.y), Vector2(post_x, porch.end.y + 8.0), trim_color, 2.0)
		for barrel_x in [facade.position.x + facade.size.x - 18.0, facade.position.x + facade.size.x - 8.0]:
			draw_circle(Vector2(barrel_x, facade.end.y - 8.0), 5.0, Color(0.35, 0.19, 0.08))
			draw_line(Vector2(barrel_x - 4.0, facade.end.y - 8.0), Vector2(barrel_x + 4.0, facade.end.y - 8.0), Color(0.74, 0.48, 0.22), 1.0)
	elif visual_style.contains("shop"):
		var awning := Rect2(wall.position + Vector2(8.0, wall.size.y * 0.48), Vector2(wall.size.x - 16.0, 10.0))
		draw_rect(awning, Color(0.44, 0.25, 0.10), true)
		for stripe_x in range(4, int(awning.size.x) - 2, 12):
			draw_line(awning.position + Vector2(stripe_x, 1.0), awning.position + Vector2(stripe_x + 4.0, 9.0), trim_color, 1.0)
		draw_rect(Rect2(facade.position + Vector2(8.0, facade.size.y - 8.0), Vector2(30.0, 6.0)), Color(0.30, 0.17, 0.07), true)
	elif visual_style.contains("storehouse"):
		for crate_offset in [Vector2(8.0, facade.size.y - 10.0), Vector2(20.0, facade.size.y - 7.0), Vector2(32.0, facade.size.y - 10.0)]:
			draw_rect(Rect2(facade.position + crate_offset, Vector2(10.0, 8.0)), Color(0.50, 0.30, 0.12), true)
			draw_line(facade.position + crate_offset + Vector2(1.0, 1.0), facade.position + crate_offset + Vector2(9.0, 7.0), Color(0.20, 0.10, 0.04), 1.0)
	elif visual_style.contains("guard"):
		var rail_y := wall.position.y + 8.0
		draw_line(Vector2(facade.position.x + 6.0, rail_y), Vector2(facade.end.x - 6.0, rail_y), trim_color, 2.0)
		for post_x in range(8, int(facade.size.x) - 6, 16):
			draw_line(facade.position + Vector2(post_x, 4.0), facade.position + Vector2(post_x, 18.0), trim_color, 1.5)
	elif visual_style.contains("shrine"):
		for stone_x in [-14.0, 0.0, 14.0]:
			draw_circle(facade.position + Vector2(facade.size.x * 0.5 + stone_x, facade.size.y - 5.0), 4.0, Color(0.42, 0.43, 0.38))

	# Landmarks must remain identifiable without a label or interaction prompt.
	if visual_style.contains("hall"):
		var cupola := Rect2(Vector2(facade.get_center().x - 13.0, roof.position.y - 23.0), Vector2(26.0, 24.0))
		draw_rect(cupola, Color(0.36, 0.21, 0.11), true)
		draw_rect(cupola, trim_color, false, 1.5)
		draw_polygon(PackedVector2Array([cupola.position + Vector2(-4, 1), cupola.position + Vector2(13, -10), cupola.position + Vector2(30, 1)]), PackedColorArray([roof_color]))
		draw_circle(cupola.get_center() + Vector2(0, 2), 5.0, Color(0.76, 0.57, 0.24))
		draw_line(cupola.position + Vector2(13, 0), cupola.position + Vector2(13, 23), Color(0.17, 0.08, 0.03), 1.5)
	elif visual_style.contains("guard"):
		var watch_deck := Rect2(facade.position + Vector2(facade.size.x - 54.0, -18.0), Vector2(44.0, 12.0))
		draw_rect(watch_deck, Color(0.27, 0.15, 0.07), true)
		draw_line(watch_deck.position, watch_deck.position + Vector2(0, 24), trim_color, 2.0)
		draw_line(watch_deck.end - Vector2(0, watch_deck.size.y), watch_deck.end + Vector2(0, 12), trim_color, 2.0)
		for rail_x in range(5, 42, 9):
			draw_line(watch_deck.position + Vector2(rail_x, -5), watch_deck.position + Vector2(rail_x, 3), trim_color, 1.0)
	elif visual_style.contains("shrine"):
		var arch_center := entry.get_center() - Vector2(0, 2)
		draw_arc(arch_center, 16.0, PI, TAU, 18, Color(0.68, 0.69, 0.61), 4.0)
		draw_line(arch_center + Vector2(-16, 0), arch_center + Vector2(-16, 18), Color(0.56, 0.57, 0.52), 4.0)
		draw_line(arch_center + Vector2(16, 0), arch_center + Vector2(16, 18), Color(0.56, 0.57, 0.52), 4.0)
	elif visual_style.contains("stable"):
		var loft := Rect2(wall.position + Vector2(wall.size.x * 0.5 - 20.0, 4.0), Vector2(40.0, 18.0))
		draw_rect(loft, Color(0.16, 0.08, 0.035), true)
		draw_line(loft.position, loft.end, trim_color, 1.0)
		draw_line(Vector2(loft.end.x, loft.position.y), Vector2(loft.position.x, loft.end.y), trim_color, 1.0)
		for stall_x in [wall.position.x + 14.0, wall.get_center().x, wall.end.x - 14.0]:
			draw_arc(Vector2(stall_x, wall.end.y - 3.0), 9.0, PI, TAU, 10, Color(0.12, 0.065, 0.03), 3.0)
	elif visual_style.contains("storehouse"):
		for pier_x in [facade.position.x + 18.0, facade.get_center().x, facade.end.x - 18.0]:
			draw_rect(Rect2(Vector2(pier_x - 3.0, facade.end.y - 2.0), Vector2(6.0, 11.0)), Color(0.20, 0.13, 0.08), true)
		var ramp := PackedVector2Array([facade.end - Vector2(42, 3), facade.end - Vector2(12, 3), facade.end + Vector2(-4, 16), facade.end + Vector2(-50, 16)])
		draw_polygon(ramp, PackedColorArray([Color(0.35, 0.23, 0.12)]))
		for ramp_line in range(0, 38, 9):
			draw_line(ramp[0] + Vector2(ramp_line, 1), ramp[3] + Vector2(ramp_line, -1), Color(0.62, 0.43, 0.22), 1.0)
	elif visual_style.contains("smithy"):
		var open_bay := Rect2(wall.position + Vector2(8.0, wall.size.y * 0.34), Vector2(wall.size.x * 0.44, wall.size.y * 0.62))
		draw_rect(open_bay, Color(0.07, 0.055, 0.045), true)
		draw_rect(open_bay, trim_color, false, 1.5)
		draw_circle(open_bay.get_center() + Vector2(-8, 2), 7.0, Color(0.96, 0.34, 0.09, 0.76))
		draw_polygon(PackedVector2Array([open_bay.get_center() + Vector2(3,-3), open_bay.get_center() + Vector2(17,-3), open_bay.get_center() + Vector2(13,3), open_bay.get_center() + Vector2(5,3)]), PackedColorArray([Color(0.34, 0.36, 0.37)]))
	elif visual_style.contains("coaching_inn"):
		for dormer_x in [facade.position.x + facade.size.x * 0.28, facade.position.x + facade.size.x * 0.68]:
			var dormer := Rect2(Vector2(dormer_x - 11.0, roof.position.y + 8.0), Vector2(22.0, 18.0))
			draw_rect(dormer, Color(0.38, 0.22, 0.12), true)
			draw_polygon(PackedVector2Array([dormer.position + Vector2(-3, 1), dormer.position + Vector2(11, -8), dormer.position + Vector2(25, 1)]), PackedColorArray([roof_color]))
			var dormer_window := dormer.grow(-6.0)
			draw_rect(dormer_window, Color(0.24, 0.14, 0.055), true)
			draw_rect(dormer_window, Color(0.70, 0.47, 0.18), false, 1.0)
	elif visual_style.contains("shop"):
		for display_x in [wall.position.x + 18.0, wall.end.x - 42.0]:
			var display := Rect2(Vector2(display_x, wall.position.y + 8.0), Vector2(24.0, 18.0))
			draw_rect(display, Color(0.27, 0.16, 0.065), true)
			draw_rect(display, trim_color, false, 1.5)
			draw_line(display.get_center() - Vector2(12, 0), display.get_center() + Vector2(12, 0), trim_color, 1.0)


func _draw_northgate_interior(rect: Rect2, visual_style: String, variant: int) -> void:
	if visual_style.contains("coaching_inn"):
		draw_texture_rect(NORTHGATE_INN_INTERIOR_SHELL, rect, false)
		return
	var tile := float(GridMath.TILE_SIZE)
	draw_rect(rect.grow(4.0), Color(0.015, 0.012, 0.009, 0.34), true)
	var floor_color := Color(0.55, 0.38, 0.20, 0.18)
	if visual_style.contains("shrine"):
		floor_color = Color(0.42, 0.45, 0.39, 0.22)
	elif visual_style.contains("smithy"):
		floor_color = Color(0.28, 0.25, 0.20, 0.24)
	draw_rect(rect.grow(-tile), floor_color, true)
	for x in range(1, int(rect.size.x / tile) - 1, 3):
		draw_line(rect.position + Vector2(float(x) * tile, tile), rect.position + Vector2(float(x) * tile, rect.size.y - tile), Color(0.18, 0.09, 0.04, 0.16), 1.0)
	_draw_northgate_interior_floor_accents(rect, visual_style, variant)
	# Furniture and service identity are authoritative fixture entities. The old
	# renderer duplicated them as large diagrammatic rectangles beneath the
	# fixture art, creating visible ghost frames and misleading empty collision.
	return
	var rug_color := Color(0.44, 0.14, 0.11, 0.56)
	if visual_style.contains("shrine"):
		rug_color = Color(0.44, 0.38, 0.16, 0.48)
	elif visual_style.contains("home"):
		if visual_style.contains("quiet_craft"):
			rug_color = Color(0.34, 0.28, 0.17, 0.62)
		elif visual_style.contains("multigenerational"):
			rug_color = Color(0.48, 0.22, 0.13, 0.64)
		elif visual_style.contains("courier"):
			rug_color = Color(0.38, 0.24, 0.12, 0.64)
		elif visual_style.contains("kitchen_garden"):
			rug_color = Color(0.27, 0.39, 0.19, 0.62)
		elif visual_style.contains("lodger"):
			rug_color = Color(0.42, 0.28, 0.15, 0.62)
		else:
			rug_color = Color(0.39, 0.27, 0.43, 0.60)
	var rug := Rect2(
		rect.position + Vector2(tile * 2.0 + float(variant) * 4.0, tile * 3.0),
		Vector2(minf(rect.size.x - tile * 4.0, 96.0), 22.0)
	)
	if visual_style.contains("home"):
		if visual_style.contains("quiet_craft"):
			rug = Rect2(rect.position + Vector2(tile * 2.2, tile * 3.5), Vector2(tile * 3.0, tile * 1.5))
		elif visual_style.contains("multigenerational"):
			rug = Rect2(rect.position + Vector2(tile * 2.1, tile * 3.0), Vector2(tile * 5.0, tile * 1.8))
		elif visual_style.contains("courier"):
			rug = Rect2(rect.position + Vector2(tile * 4.45, tile * 2.0), Vector2(tile * 1.1, tile * 4.2))
		elif visual_style.contains("kitchen_garden"):
			rug = Rect2(rect.position + Vector2(tile * 2.8, tile * 3.7), Vector2(tile * 3.2, tile * 1.45))
		elif visual_style.contains("lodger"):
			rug = Rect2(rect.position + Vector2(tile * 2.0, tile * 3.2), Vector2(tile * 2.8, tile * 1.5))
	draw_rect(rug, rug_color, true)
	draw_rect(rug.grow(-3.0), Color(0.82, 0.63, 0.29, 0.46), false, 1.0)
	if visual_style.contains("home"):
		if visual_style.contains("courier"):
			for stripe_y in range(8, int(rug.size.y) - 4, 12):
				draw_line(
					rug.position + Vector2(3.0, float(stripe_y)),
					rug.position + Vector2(rug.size.x - 3.0, float(stripe_y)),
					Color(0.90, 0.72, 0.38, 0.24), 1.0
				)
		else:
			for stripe_x in range(6, int(rug.size.x) - 4, 10):
				draw_line(
					rug.position + Vector2(float(stripe_x), 3.0),
					rug.position + Vector2(float(stripe_x), rug.size.y - 3.0),
					Color(0.90, 0.72, 0.38, 0.24), 1.0
				)
		if visual_style.contains("lodger"):
			var lodger_rug := Rect2(
				rect.position + Vector2(tile * 6.6, tile * 4.5),
				Vector2(tile * 1.6, tile * 1.25)
			)
			draw_rect(lodger_rug, rug_color.lightened(0.08), true)
			draw_rect(lodger_rug.grow(-3.0), Color(0.82, 0.63, 0.29, 0.40), false, 1.0)
		var beam_color := Color(0.18, 0.09, 0.04, 0.38)
		draw_line(
			rect.position + Vector2(tile, tile * 1.15),
			rect.position + Vector2(rect.size.x - tile, tile * 1.15),
			beam_color, 2.0
		)
		for beam_x in range(2, int(rect.size.x / tile) - 1, 2):
			draw_line(
				rect.position + Vector2(float(beam_x) * tile, tile),
				rect.position + Vector2(float(beam_x) * tile, tile * 1.45),
				beam_color, 1.5
			)
		if visual_style.contains("courier"):
			var route_start := rect.position + Vector2(tile * 2.3, tile * 1.3)
			draw_polyline(
				PackedVector2Array([route_start, route_start + Vector2(18, 4), route_start + Vector2(35, -2), route_start + Vector2(54, 5)]),
				Color(0.70, 0.62, 0.43, 0.68), 1.5
			)
		elif visual_style.contains("kitchen_garden"):
			for x in [tile * 2.0, tile * 2.5, tile * 3.0]:
				draw_line(rect.position + Vector2(x, tile * 1.3), rect.position + Vector2(x - 2, tile * 1.75), Color(0.30, 0.57, 0.24), 2.0)
		elif visual_style.contains("lodger"):
			draw_line(
				rect.position + Vector2(tile * 6.0, tile * 2.0),
				rect.position + Vector2(tile * 6.0, tile * 5.8),
				Color(0.62, 0.42, 0.22, 0.40), 2.0
			)
		_draw_northgate_home_detail(rect, visual_style)
	elif visual_style.contains("shrine"):
		var aisle := Rect2(rect.position + Vector2(rect.size.x * 0.5 - tile * 0.7, tile), Vector2(tile * 1.4, rect.size.y - tile * 2.0))
		draw_rect(aisle, Color(0.46, 0.35, 0.14, 0.42), true)
		for y in range(int(tile * 1.5), int(rect.size.y - tile * 1.5), int(tile)):
			draw_circle(rect.position + Vector2(rect.size.x * 0.5, float(y)), 2.2, Color(0.93, 0.66, 0.20, 0.78))
		_draw_northgate_shrine_detail(rect)
	elif visual_style.contains("guard"):
		draw_line(rect.position + Vector2(tile * 6.0, tile), rect.position + Vector2(tile * 6.0, rect.size.y - tile), Color(0.25, 0.13, 0.06, 0.38), 3.0)
		draw_rect(Rect2(rect.position + Vector2(tile, tile * 4.3), Vector2(tile * 4.6, tile * 1.7)), Color(0.24, 0.18, 0.12, 0.20), true)
		_draw_northgate_guard_detail(rect)
	elif visual_style.contains("hall"):
		var hall_runner := Rect2(rect.position + Vector2(rect.size.x * 0.5 - tile, tile), Vector2(tile * 2.0, rect.size.y - tile * 2.0))
		draw_rect(hall_runner, Color(0.38, 0.12, 0.10, 0.42), true)
		draw_rect(hall_runner.grow(-4.0), Color(0.78, 0.58, 0.27, 0.36), false, 1.5)
		draw_line(rect.position + Vector2(tile * 8.0, tile), rect.position + Vector2(tile * 8.0, rect.size.y - tile), Color(0.27, 0.14, 0.06, 0.34), 2.0)
		_draw_northgate_hall_detail(rect)
	elif visual_style.contains("inn"):
		var service_floor := Rect2(rect.position + Vector2(tile, tile), Vector2(tile * 5.5, tile * 3.2))
		draw_rect(service_floor, Color(0.31, 0.18, 0.08, 0.22), true)
		var common_floor := Rect2(rect.position + Vector2(tile * 6.5, tile * 3.5), Vector2(tile * 7.5, tile * 5.8))
		draw_rect(common_floor, Color(0.42, 0.18, 0.10, 0.18), true)
		draw_line(rect.position + Vector2(tile * 14.0, tile), rect.position + Vector2(tile * 14.0, rect.size.y - tile), Color(0.24, 0.12, 0.05, 0.30), 2.0)
		_draw_northgate_inn_detail(rect)
	elif visual_style.contains("stable"):
		for stall_x in [tile * 1.5, tile * 4.5, tile * 7.5]:
			var stall_rect := Rect2(rect.position + Vector2(stall_x, tile), Vector2(tile * 2.4, tile * 4.2))
			draw_rect(stall_rect, Color(0.29, 0.20, 0.11, 0.24), true)
			draw_rect(stall_rect, Color(0.52, 0.35, 0.17, 0.42), false, 2.0)
		draw_rect(Rect2(rect.position + Vector2(tile, tile * 6.0), Vector2(rect.size.x - tile * 2.0, tile * 2.6)), Color(0.52, 0.39, 0.16, 0.12), true)
		_draw_northgate_stable_detail(rect)
	elif visual_style.contains("shop"):
		draw_line(rect.position + Vector2(tile, tile * 4.2), rect.position + Vector2(rect.size.x - tile, tile * 4.2), Color(0.26, 0.14, 0.06, 0.38), 3.0)
		for shelf_y in [tile * 1.35, tile * 2.0]:
			draw_line(rect.position + Vector2(tile * 1.3, shelf_y), rect.position + Vector2(rect.size.x - tile * 1.3, shelf_y), Color(0.69, 0.49, 0.23, 0.25), 1.5)
		_draw_northgate_shop_detail(rect)
	elif visual_style.contains("storehouse"):
		for bay_x in [tile * 1.2, tile * 4.2, tile * 7.2]:
			draw_rect(Rect2(rect.position + Vector2(bay_x, tile * 1.2), Vector2(tile * 2.2, tile * 5.4)), Color(0.28, 0.18, 0.09, 0.20), false, 2.0)
		_draw_northgate_storehouse_detail(rect)
	elif visual_style.contains("smithy"):
		draw_rect(Rect2(rect.position + Vector2(tile * 6.0, tile), Vector2(rect.size.x - tile * 7.0, tile * 5.6)), Color(0.19, 0.17, 0.15, 0.30), true)
		for scorch in [Vector2(tile * 8.4, tile * 2.3), Vector2(tile * 9.8, tile * 4.8), Vector2(tile * 7.0, tile * 5.7)]:
			draw_circle(rect.position + scorch, 9.0, Color(0.08, 0.055, 0.04, 0.18))
		_draw_northgate_smithy_detail(rect)
	if visual_style.contains("inn") or visual_style.contains("smithy"):
		var hearth := rect.position + Vector2(rect.size.x - tile * 2.3, tile * 2.0)
		draw_circle(hearth, 18.0, Color(0.94, 0.32, 0.08, 0.10))
		draw_circle(hearth, 7.0, Color(1.0, 0.58, 0.16, 0.72))
	if visual_style.contains("hall") or visual_style.contains("storehouse"):
		for y in [tile * 2.0, tile * 4.0, tile * 6.0]:
			draw_line(rect.position + Vector2(tile, y), rect.position + Vector2(tile * 2.5, y), Color(0.73, 0.54, 0.28, 0.46), 2.0)


func _draw_northgate_interior_floor_accents(
	rect: Rect2, visual_style: String, variant: int
) -> void:
	var tile := float(GridMath.TILE_SIZE)
	if visual_style.contains("smithy"):
		for offset in [Vector2(0.68, 0.28), Vector2(0.78, 0.54), Vector2(0.61, 0.66)]:
			draw_circle(rect.position + rect.size * offset, 8.0 + float(variant), Color(0.07, 0.05, 0.035, 0.16))
		return
	if visual_style.contains("stable"):
		for index in 9:
			var start := rect.position + Vector2(tile * (1.4 + float(index % 3) * 3.0), tile * (2.0 + float(index / 3) * 2.2))
			draw_line(start, start + Vector2(9.0, -3.0), Color(0.67, 0.50, 0.18, 0.22), 1.2)
		return
	if visual_style.contains("shrine"):
		var center := rect.get_center()
		draw_circle(center, tile * 1.25, Color(0.34, 0.30, 0.18, 0.18))
		draw_arc(center, tile * 1.25, 0.0, TAU, 24, Color(0.62, 0.52, 0.26, 0.28), 1.0)
		return
	var rug_size := Vector2(tile * (2.5 + float(variant) * 0.3), tile * 1.25)
	if visual_style.contains("hall"):
		rug_size = Vector2(tile * 1.45, minf(rect.size.y - tile * 2.5, tile * 5.0))
	elif visual_style.contains("inn"):
		rug_size = Vector2(tile * 3.2, tile * 1.5)
	elif visual_style.contains("storehouse") or visual_style.contains("shop"):
		rug_size = Vector2(tile * 2.2, tile * 1.1)
	var rug := Rect2(rect.get_center() - rug_size * 0.5 + Vector2(float(variant - 1) * 4.0, 3.0), rug_size)
	var rug_color := Color(0.38, 0.17, 0.10, 0.30)
	if visual_style.contains("kitchen_garden"):
		rug_color = Color(0.25, 0.36, 0.18, 0.30)
	elif visual_style.contains("quiet_craft"):
		rug_color = Color(0.33, 0.27, 0.16, 0.30)
	draw_rect(rug, rug_color, true)
	for stripe in range(5, int(rug.size.x) - 3, 9):
		draw_line(rug.position + Vector2(float(stripe), 2.0), rug.position + Vector2(float(stripe), rug.size.y - 2.0), Color(0.70, 0.49, 0.22, 0.18), 1.0)


func _draw_northgate_inn_architecture(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	var inner := rect.grow(-tile)
	var dark_wood := Color(0.16, 0.075, 0.03, 0.66)
	var worn_wood := Color(0.48, 0.29, 0.12, 0.34)

	# A continuous service wall and long bar make the northwest corner read as
	# an operating inn rather than a collection of unrelated furniture sprites.
	var service_zone := Rect2(inner.position + Vector2(8.0, 7.0), Vector2(tile * 6.1, tile * 2.7))
	draw_rect(service_zone, Color(0.13, 0.065, 0.028, 0.34), true)
	draw_line(service_zone.position, Vector2(service_zone.end.x, service_zone.position.y), worn_wood, 3.0)
	for shelf_y in [service_zone.position.y + 14.0, service_zone.position.y + 29.0]:
		draw_line(Vector2(service_zone.position.x + 8.0, shelf_y), Vector2(service_zone.end.x - 8.0, shelf_y), dark_wood, 3.0)
	for bottle_x in range(16, int(service_zone.size.x) - 8, 18):
		var bottle := service_zone.position + Vector2(float(bottle_x), 20.0 + float((bottle_x / 18) % 2) * 14.0)
		draw_rect(Rect2(bottle, Vector2(4.0, 8.0)), Color(0.28, 0.46, 0.31, 0.72), true)

	# Partition the guest bed from the common room. This stays architectural and
	# does not duplicate the authoritative bed/rest interaction.
	var guest_partition_x := inner.end.x - tile * 3.7
	draw_line(Vector2(guest_partition_x, inner.position.y + tile * 5.1), Vector2(guest_partition_x, inner.end.y - 8.0), dark_wood, 5.0)
	draw_line(Vector2(guest_partition_x, inner.position.y + tile * 5.1), Vector2(inner.end.x, inner.position.y + tile * 5.1), dark_wood, 5.0)
	for post_y in range(int(inner.position.y + tile * 5.7), int(inner.end.y - 5.0), 22):
		draw_circle(Vector2(guest_partition_x, float(post_y)), 2.0, Color(0.61, 0.39, 0.17, 0.75))

	# Worn circulation joins door, bar, tables, hearth, and guest nook. It is
	# deliberately irregular so the floor stops reading as a clean debug grid.
	var door_center := Vector2(rect.get_center().x, inner.end.y)
	var common_center := rect.get_center() + Vector2(8.0, 4.0)
	draw_line(door_center, common_center, Color(0.24, 0.13, 0.065, 0.24), tile * 1.15)
	draw_line(common_center, service_zone.get_center() + Vector2(0.0, tile), Color(0.24, 0.13, 0.065, 0.18), tile * 0.82)
	for offset in [Vector2(-8, -4), Vector2(10, 5), Vector2(25, -8), Vector2(-23, 11)]:
		draw_circle(common_center + offset, 7.0, Color(0.16, 0.09, 0.05, 0.12))

	# Small wall windows add depth and a readable inhabited edge.
	for ratio: float in [0.48, 0.68, 0.84]:
		var window_x: float = rect.size.x * ratio
		var window := Rect2(rect.position + Vector2(window_x - 8.0, tile + 3.0), Vector2(16.0, 7.0))
		draw_rect(window, Color(0.78, 0.42, 0.12, 0.58), true)
		draw_rect(window, dark_wood, false, 1.5)


func _draw_northgate_home_detail(rect: Rect2, visual_style: String) -> void:
	var tile := float(GridMath.TILE_SIZE)
	var timber := Color(0.24, 0.12, 0.055, 0.52)
	var brass := Color(0.82, 0.61, 0.27, 0.48)
	# Small windows, wall pegs, and worn threshold keep the room from reading as
	# a bare box even when interactive fixture markers are hidden for capture.
	for window_x in [rect.position.x + tile * 2.0, rect.end.x - tile * 2.0]:
		var window := Rect2(Vector2(window_x - 7.0, rect.position.y + tile + 3.0), Vector2(14.0, 6.0))
		draw_rect(window, Color(0.46, 0.28, 0.10, 0.54), true)
		draw_rect(window, timber, false, 1.0)
	draw_line(rect.position + Vector2(tile * 1.4, rect.size.y - tile * 1.15), rect.position + Vector2(rect.size.x - tile * 1.4, rect.size.y - tile * 1.15), Color(0.73, 0.46, 0.19, 0.16), 3.0)
	if visual_style.contains("quiet_craft"):
		var work_zone := Rect2(rect.position + Vector2(tile * 1.35, tile * 3.0), Vector2(tile * 3.6, tile * 2.8))
		draw_rect(work_zone, Color(0.27, 0.19, 0.10, 0.18), true)
		draw_rect(work_zone, Color(0.58, 0.41, 0.19, 0.34), false, 1.0)
		for spool_x in [tile * 1.7, tile * 2.15, tile * 2.6]:
			draw_circle(rect.position + Vector2(spool_x, tile * 2.1), 2.2, brass)
	elif visual_style.contains("multigenerational"):
		for alcove_x in [tile * 1.2, tile * 6.0]:
			var alcove := Rect2(rect.position + Vector2(alcove_x, tile * 1.35), Vector2(tile * 2.7, tile * 2.0))
			draw_rect(alcove, Color(0.43, 0.18, 0.11, 0.13), true)
			draw_line(alcove.position, alcove.position + Vector2(alcove.size.x, 0), timber, 2.0)
		for peg_x in [tile * 4.5, tile * 5.0, tile * 5.5]:
			draw_circle(rect.position + Vector2(peg_x, tile * 1.35), 1.8, brass)
	elif visual_style.contains("courier"):
		var drying_zone := Rect2(rect.position + Vector2(tile * 6.8, tile * 1.25), Vector2(tile * 1.8, tile * 3.0))
		draw_rect(drying_zone, Color(0.28, 0.20, 0.12, 0.18), true)
		for paper_x in [tile * 2.0, tile * 2.55, tile * 3.1]:
			draw_rect(Rect2(rect.position + Vector2(paper_x, tile * 1.55), Vector2(6, 5)), Color(0.78, 0.69, 0.48, 0.72), true)
		for boot_x in [tile * 1.8, tile * 2.45, tile * 3.1]:
			draw_rect(Rect2(rect.position + Vector2(boot_x, tile * 6.2), Vector2(5, 8)), Color(0.13, 0.09, 0.06, 0.72), true)
	elif visual_style.contains("kitchen_garden"):
		var pantry := Rect2(rect.position + Vector2(tile * 6.2, tile * 1.25), Vector2(tile * 2.4, tile * 4.5))
		draw_rect(pantry, Color(0.20, 0.34, 0.14, 0.13), true)
		for jar_x in [tile * 6.55, tile * 7.15, tile * 7.75, tile * 8.35]:
			draw_circle(rect.position + Vector2(jar_x, tile * 1.55), 2.4, Color(0.72, 0.43, 0.18, 0.68))
		for leaf_x in [tile * 2.0, tile * 2.55, tile * 3.1, tile * 3.65]:
			draw_line(rect.position + Vector2(leaf_x, tile * 1.2), rect.position + Vector2(leaf_x - 2, tile * 1.75), Color(0.30, 0.58, 0.24, 0.78), 2.0)
	elif visual_style.contains("lodger"):
		var private_zone := Rect2(rect.position + Vector2(tile * 6.1, tile * 1.25), Vector2(tile * 2.6, tile * 5.5))
		draw_rect(private_zone, Color(0.33, 0.24, 0.15, 0.16), true)
		draw_rect(private_zone, Color(0.55, 0.39, 0.20, 0.32), false, 1.0)
		for hook_y in [tile * 1.7, tile * 2.25, tile * 2.8]:
			draw_circle(rect.position + Vector2(tile * 5.7, hook_y), 1.7, brass)


func _draw_northgate_shrine_detail(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	var center := rect.position + Vector2(rect.size.x * 0.5, tile * 2.0)
	for radius in [20.0, 14.0, 8.0]:
		draw_arc(center, radius, PI, TAU, 20, Color(0.75, 0.65, 0.38, 0.28), 1.2)
	for side in [-1.0, 1.0]:
		for y in [tile * 4.2, tile * 5.2]:
			draw_line(rect.position + Vector2(rect.size.x * 0.5 + side * tile * 1.25, y), rect.position + Vector2(rect.size.x * 0.5 + side * tile * 2.4, y), Color(0.54, 0.47, 0.31, 0.34), 3.0)


func _draw_northgate_guard_detail(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	for bunk_x in [tile * 1.25, tile * 7.1]:
		var bunk_zone := Rect2(rect.position + Vector2(bunk_x, tile * 4.5), Vector2(tile * 2.6, tile * 1.7))
		draw_rect(bunk_zone, Color(0.28, 0.22, 0.15, 0.18), true)
		draw_rect(bunk_zone, Color(0.54, 0.35, 0.16, 0.30), false, 1.0)
	for rack_y in [tile * 1.7, tile * 2.25, tile * 2.8]:
		draw_line(rect.position + Vector2(tile * 8.0, rack_y), rect.position + Vector2(tile * 9.4, rack_y), Color(0.45, 0.48, 0.48, 0.45), 1.5)
	for mark_x in [tile * 2.2, tile * 2.7, tile * 3.2]:
		draw_circle(rect.position + Vector2(mark_x, tile * 1.55), 2.0, Color(0.74, 0.58, 0.29, 0.54))


func _draw_northgate_hall_detail(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	var dais := Rect2(rect.position + Vector2(tile * 8.7, tile * 1.25), Vector2(tile * 3.9, tile * 2.7))
	draw_rect(dais, Color(0.31, 0.12, 0.08, 0.24), true)
	draw_rect(dais, Color(0.71, 0.48, 0.22, 0.34), false, 1.5)
	for panel_x in [tile * 2.0, tile * 4.0, tile * 10.0, tile * 12.0]:
		var panel := Rect2(rect.position + Vector2(panel_x - 6.0, tile * 1.2), Vector2(12, 8))
		draw_rect(panel, Color(0.76, 0.67, 0.45, 0.38), true)
		draw_rect(panel, Color(0.34, 0.20, 0.09, 0.62), false, 1.0)


func _draw_northgate_inn_detail(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	var wood := Color(0.54, 0.32, 0.13, 0.45)
	var bar_back := Rect2(rect.position + Vector2(tile * 1.25, tile * 1.25), Vector2(tile * 4.8, tile * 2.2))
	draw_rect(bar_back, Color(0.22, 0.12, 0.06, 0.30), true)
	draw_rect(bar_back, wood, false, 1.5)
	for bottle_x in [tile * 1.7, tile * 2.35, tile * 3.0, tile * 3.65, tile * 4.3, tile * 4.95]:
		draw_rect(Rect2(rect.position + Vector2(bottle_x, tile * 1.55), Vector2(3, 7)), Color(0.37, 0.55, 0.38, 0.72), true)
	var guest_nook := Rect2(rect.position + Vector2(tile * 14.25, tile * 6.9), Vector2(tile * 2.5, tile * 3.0))
	draw_rect(guest_nook, Color(0.28, 0.19, 0.16, 0.22), true)
	draw_rect(guest_nook, Color(0.61, 0.40, 0.24, 0.34), false, 1.0)
	for lamp in [Vector2(tile * 8.5, tile * 2.0), Vector2(tile * 11.5, tile * 2.0)]:
		draw_circle(rect.position + lamp, 10.0, Color(1.0, 0.57, 0.16, 0.07))
		draw_circle(rect.position + lamp, 2.5, Color(1.0, 0.69, 0.25, 0.78))


func _draw_northgate_stable_detail(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	for stall_x in [tile * 1.5, tile * 4.5, tile * 7.5]:
		for bar_x in [0.7, 1.2, 1.7]:
			draw_line(rect.position + Vector2(stall_x + tile * bar_x, tile * 1.2), rect.position + Vector2(stall_x + tile * bar_x, tile * 4.8), Color(0.55, 0.35, 0.15, 0.42), 1.5)
		for straw_index in 7:
			var straw := rect.position + Vector2(stall_x + 5.0 + float((straw_index * 11) % 31), tile * 4.45 + float((straw_index * 5) % 13))
			draw_line(straw, straw + Vector2(6, -2), Color(0.77, 0.59, 0.24, 0.42), 1.0)
	var aisle_x := rect.position.x + tile * 10.8
	for y in range(int(tile * 2.0), int(rect.size.y - tile * 1.3), int(tile * 1.1)):
		draw_arc(Vector2(aisle_x, rect.position.y + float(y)), 5.0, 0, PI, 8, Color(0.17, 0.12, 0.08, 0.45), 1.3)
	for hook_y in [tile * 1.7, tile * 2.4, tile * 3.1]:
		draw_circle(rect.position + Vector2(tile * 11.2, hook_y), 5.0, Color(0.28, 0.17, 0.09, 0.68), false, 1.5)


func _draw_northgate_shop_detail(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	var shelf_wood := Color(0.57, 0.36, 0.15, 0.48)
	for shelf_x in [tile * 1.45, tile * 10.45]:
		var shelf := Rect2(rect.position + Vector2(shelf_x - 7.0, tile * 1.25), Vector2(14.0, tile * 5.7))
		draw_rect(shelf, Color(0.22, 0.13, 0.06, 0.22), true)
		draw_rect(shelf, shelf_wood, false, 1.2)
		for shelf_y in [tile * 2.0, tile * 3.25, tile * 4.5, tile * 5.75]:
			draw_line(rect.position + Vector2(shelf_x - 6, shelf_y), rect.position + Vector2(shelf_x + 6, shelf_y), shelf_wood, 1.4)
	for goods in [Vector2(tile * 2.3, tile * 2.6), Vector2(tile * 3.0, tile * 2.6), Vector2(tile * 9.0, tile * 2.6), Vector2(tile * 9.7, tile * 2.6)]:
		draw_circle(rect.position + goods, 3.0, Color(0.65, 0.39, 0.17, 0.68))
	var display := Rect2(rect.position + Vector2(tile * 4.2, tile * 5.2), Vector2(tile * 3.6, tile * 1.8))
	draw_rect(display, Color(0.31, 0.18, 0.08, 0.28), true)
	draw_rect(display, shelf_wood, false, 1.2)
	# Hanging scale over the counter.
	var scale_center := rect.position + Vector2(tile * 6.0, tile * 2.4)
	draw_line(scale_center - Vector2(0, 10), scale_center + Vector2(0, 5), Color(0.64, 0.57, 0.40, 0.60), 1.2)
	draw_line(scale_center + Vector2(-9, 0), scale_center + Vector2(9, 0), Color(0.64, 0.57, 0.40, 0.60), 1.2)
	draw_arc(scale_center + Vector2(-9, 5), 5.0, 0, PI, 8, Color(0.64, 0.57, 0.40, 0.60), 1.0)
	draw_arc(scale_center + Vector2(9, 5), 5.0, 0, PI, 8, Color(0.64, 0.57, 0.40, 0.60), 1.0)


func _draw_northgate_storehouse_detail(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	for bay_x in [tile * 1.2, tile * 4.2, tile * 7.2]:
		for plank_y in [tile * 2.1, tile * 3.6, tile * 5.1]:
			draw_line(rect.position + Vector2(bay_x + 3, plank_y), rect.position + Vector2(bay_x + tile * 2.0 - 3, plank_y), Color(0.58, 0.38, 0.17, 0.40), 2.0)
	for sack_center in [Vector2(tile * 2.2, tile * 5.7), Vector2(tile * 3.0, tile * 5.9), Vector2(tile * 5.2, tile * 6.0), Vector2(tile * 8.4, tile * 5.8)]:
		draw_circle(rect.position + sack_center, 7.0, Color(0.55, 0.44, 0.25, 0.45))
		draw_line(rect.position + sack_center - Vector2(3, 3), rect.position + sack_center + Vector2(3, 3), Color(0.30, 0.22, 0.12, 0.45), 1.0)
	for chalk_y in [tile * 1.7, tile * 2.25, tile * 2.8]:
		draw_line(rect.position + Vector2(tile * 9.9, chalk_y), rect.position + Vector2(tile * 10.8, chalk_y), Color(0.80, 0.73, 0.58, 0.38), 1.2)
	var hoist := rect.position + Vector2(tile * 10.3, tile * 5.0)
	draw_circle(hoist, 7.0, Color(0.24, 0.15, 0.08, 0.65), false, 2.0)
	draw_line(hoist + Vector2(0, 7), hoist + Vector2(0, 28), Color(0.53, 0.38, 0.20, 0.55), 1.4)


func _draw_northgate_smithy_detail(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	var forge_zone := Rect2(rect.position + Vector2(tile * 8.8, tile * 1.25), Vector2(tile * 2.6, tile * 3.2))
	draw_rect(forge_zone, Color(0.12, 0.10, 0.085, 0.36), true)
	draw_rect(forge_zone, Color(0.47, 0.42, 0.34, 0.30), false, 1.2)
	for ember in [Vector2(tile * 9.4, tile * 2.0), Vector2(tile * 10.1, tile * 2.4), Vector2(tile * 10.7, tile * 1.9)]:
		draw_circle(rect.position + ember, 2.4, Color(1.0, 0.45, 0.10, 0.70))
	var quench_stain := rect.position + Vector2(tile * 8.8, tile * 6.2)
	draw_circle(quench_stain, 15.0, Color(0.10, 0.24, 0.27, 0.13))
	for spark in [Vector2(9, -12), Vector2(14, -4), Vector2(-10, -8), Vector2(-13, 3)]:
		draw_line(forge_zone.get_center(), forge_zone.get_center() + spark, Color(1.0, 0.60, 0.18, 0.35), 1.0)


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


func _draw_town_hall_exterior(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	draw_rect(rect.grow(3.0), Color(0.02, 0.018, 0.012, 0.22), true)
	var body := Rect2(rect.position + Vector2(4.0, 18.0), Vector2(rect.size.x - 8.0, 43.0))
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
	var door := Rect2(
		rect.position + Vector2(tile * 4.0, 42.0), Vector2(tile, 20.0)
	)
	draw_rect(door, Color(0.12, 0.07, 0.035), true)
	draw_line(
		door.position + Vector2(8.0, 2.0),
		door.position + Vector2(8.0, 18.0),
		Color(0.44, 0.28, 0.11),
		1.0
	)
	draw_circle(door.position + Vector2(5.0, 11.0), 1.2, Color(0.82, 0.62, 0.22))
	var step := Rect2(door.position + Vector2(-5.0, 18.0), Vector2(26.0, 8.0))
	draw_rect(step, Color(0.39, 0.38, 0.34), true)
	draw_rect(step, Color(0.10, 0.10, 0.09, 0.40), false, 1.0)


func _draw_town_hall_interior(rect: Rect2) -> void:
	var tile := float(GridMath.TILE_SIZE)
	draw_rect(rect.grow(4.0), Color(0.0, 0.0, 0.0, 0.30), true)
	draw_rect(rect.grow(-tile), Color(0.68, 0.43, 0.21, 0.08), true)
	var exit := Rect2(rect.position + Vector2(tile * 5.0, tile * 7.0), Vector2(tile, tile))
	draw_rect(exit.grow(-2.0), Color(0.08, 0.045, 0.025, 0.70), true)
	draw_rect(exit.grow(-1.0), Color(0.92, 0.68, 0.25, 0.28), false, 1.0)
	var clerk_desk := Rect2(rect.position + Vector2(tile * 4.0, tile * 2.0), Vector2(tile * 4.0, tile))
	draw_rect(clerk_desk, Color(0.29, 0.17, 0.08), true)
	draw_rect(clerk_desk, Color(0.09, 0.055, 0.025), false, 1.0)
	draw_line(
		clerk_desk.position + Vector2(8.0, 4.0),
		clerk_desk.position + Vector2(clerk_desk.size.x - 8.0, 4.0),
		Color(0.72, 0.59, 0.32, 0.50),
		1.0
	)
	var record_shelf := Rect2(rect.position + Vector2(tile * 8.8, tile * 1.7), Vector2(18.0, 52.0))
	draw_rect(record_shelf, Color(0.22, 0.13, 0.06), true)
	draw_rect(record_shelf, Color(0.08, 0.045, 0.02), false, 1.0)
	for y in [8.0, 20.0, 32.0, 44.0]:
		draw_line(
			record_shelf.position + Vector2(2.0, y),
			record_shelf.position + Vector2(16.0, y),
			Color(0.66, 0.51, 0.27, 0.55),
			1.0
		)
	var notice_board := Rect2(rect.position + Vector2(tile * 1.5, tile * 1.8), Vector2(24.0, 20.0))
	draw_rect(notice_board, Color(0.48, 0.34, 0.16), true)
	draw_rect(notice_board, Color(0.12, 0.075, 0.035), false, 1.0)
	for y in [5.0, 10.0, 15.0]:
		draw_line(
			notice_board.position + Vector2(4.0, y),
			notice_board.position + Vector2(20.0, y),
			Color(0.86, 0.76, 0.51, 0.75),
			1.0
		)
	var rug := Rect2(rect.position + Vector2(tile * 3.0, tile * 4.6), Vector2(tile * 4.0, tile * 1.5))
	draw_rect(rug, Color(0.37, 0.13, 0.10, 0.70), true)
	draw_rect(rug.grow(-3.0), Color(0.70, 0.49, 0.22, 0.48), false, 1.0)
	var cabinet := Rect2(rect.position + Vector2(tile * 8.3, tile * 5.0), Vector2(24.0, 18.0))
	draw_rect(cabinet, Color(0.20, 0.12, 0.055), true)
	draw_rect(cabinet, Color(0.08, 0.045, 0.02), false, 1.0)
	draw_line(
		cabinet.position + Vector2(12.0, 2.0),
		cabinet.position + Vector2(12.0, 16.0),
		Color(0.54, 0.34, 0.13),
		1.0
	)


func _hash_detail(tile: Vector2i) -> int:
	return absi((tile.x * 17 + tile.y * 31 + tile.x * tile.y * 7) % 10)
