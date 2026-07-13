extends GutTest

const GridMath = preload("res://scripts/core/grid_math.gd")
const StructureManager = preload("res://scripts/managers/world/structure_manager.gd")
const WorldQuery = preload("res://scripts/world/world_query.gd")


class ChunkStub:
	extends RefCounted

	var tile_kinds := {}
	var walkable := {}

	func get_tile_kind(tile: Vector2i) -> String:
		return String(tile_kinds.get("%s,%s" % [tile.x, tile.y], "grass"))

	func is_walkable(tile: Vector2i) -> bool:
		return bool(walkable.get("%s,%s" % [tile.x, tile.y], true))


class StructureStub:
	extends StructureManager

	var overrides := {}
	var walkable_overrides := {}
	var chunk_structures: Array[Dictionary] = []

	func has_tile_override(tile: Vector2i, layer: String = "surface") -> bool:
		return overrides.has(_key(tile, layer))

	func get_tile_kind(tile: Vector2i, layer: String = "surface") -> String:
		return String(overrides.get(_key(tile, layer), ""))

	func is_walkable_tile(tile: Vector2i, layer: String = "surface") -> bool:
		return bool(walkable_overrides.get(_key(tile, layer), false))

	func get_structures_for_chunk(
		_chunk_coord: Vector2i, _layer: String = "surface"
	) -> Array[Dictionary]:
		return chunk_structures

	func _key(tile: Vector2i, layer: String) -> String:
		return "%s:%s,%s" % [layer, tile.x, tile.y]


func test_layer_normalization_and_current_layer() -> void:
	var query := WorldQuery.new()

	assert_eq(query.get_current_layer(), "surface")
	query.set_layer("")
	assert_eq(query.get_current_layer(), "surface")
	query.set_layer("interior:test")
	assert_eq(query.get_current_layer(), "interior:test")
	assert_eq(query._resolved_layer(""), "interior:test")
	assert_eq(query._resolved_layer("surface"), "surface")


func test_tile_kind_and_walkability_prefer_structure_then_layer_then_chunk() -> void:
	var chunks := ChunkStub.new()
	chunks.tile_kinds = {"1,1": "water", "2,2": "grass"}
	chunks.walkable = {"1,1": false, "2,2": true}
	var structures := StructureStub.new()
	add_child_autofree(structures)
	structures.overrides = {"surface:3,3": "wood_floor"}
	structures.walkable_overrides = {"surface:3,3": true}
	var query := WorldQuery.new()
	query.setup(chunks, structures)

	assert_eq(query.get_tile_kind(Vector2i(3, 3), "surface"), "wood_floor")
	assert_true(query.is_walkable(Vector2i(3, 3), "surface"))
	assert_eq(query.get_tile_kind(Vector2i(1, 1), "surface"), "water")
	assert_false(query.is_walkable(Vector2i(1, 1), "surface"))
	assert_eq(query.get_tile_kind(Vector2i(9, 9), "interior:test"), "stone_wall")
	assert_false(query.is_walkable(Vector2i(9, 9), "interior:test"))


func test_query_without_managers_uses_grass_surface_and_blocked_interior() -> void:
	var query := WorldQuery.new()

	assert_eq(query.get_tile_kind(Vector2i.ZERO, "surface"), "grass")
	assert_true(query.is_walkable(Vector2i.ZERO, "surface"))
	assert_eq(query.get_tile_kind(Vector2i.ZERO, "interior:test"), "stone_wall")
	assert_false(query.is_walkable(Vector2i.ZERO, "interior:test"))


func test_get_chunk_data_includes_tiles_explicit_flags_and_structures() -> void:
	var structures := StructureStub.new()
	add_child_autofree(structures)
	var origin := GridMath.chunk_origin_tile(Vector2i.ZERO)
	structures.overrides = {"surface:%s,%s" % [origin.x, origin.y]: "wood_floor"}
	structures.walkable_overrides = {"surface:%s,%s" % [origin.x, origin.y]: true}
	structures.chunk_structures = [{"id": "structure_house"}]
	var query := WorldQuery.new()
	query.setup(null, structures)

	var chunk := query.get_chunk_data(Vector2i.ZERO, "surface")

	assert_eq(chunk["id"], "surface:0:0")
	assert_eq(chunk["layer"], "surface")
	assert_eq(chunk["chunk_coord"], [0, 0])
	assert_eq(chunk["chunk_size"], GridMath.CHUNK_SIZE)
	assert_eq((chunk["tiles"] as Array).size(), GridMath.CHUNK_SIZE * GridMath.CHUNK_SIZE)
	assert_true((chunk["tiles"] as Array)[0]["explicit"])
	assert_eq((chunk["tiles"] as Array)[0]["kind"], "wood_floor")
	assert_eq(chunk["structures"], [{"id": "structure_house"}])
