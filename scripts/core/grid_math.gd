class_name GridMath
extends RefCounted

const TILE_SIZE := 16
const CHUNK_SIZE := 16


static func tile_to_world(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * TILE_SIZE, tile.y * TILE_SIZE)


static func world_to_tile(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / TILE_SIZE), floori(world_position.y / TILE_SIZE))


static func tile_to_chunk(tile: Vector2i) -> Vector2i:
	return Vector2i(floori(float(tile.x) / CHUNK_SIZE), floori(float(tile.y) / CHUNK_SIZE))


static func chunk_origin_tile(chunk_coord: Vector2i) -> Vector2i:
	return chunk_coord * CHUNK_SIZE


static func chunk_key(chunk_coord: Vector2i, layer: String = "surface") -> String:
	return "%s:%d:%d" % [layer, chunk_coord.x, chunk_coord.y]


static func tile_key(tile: Vector2i, layer: String = "surface") -> String:
	return "%s:%d:%d" % [layer, tile.x, tile.y]


static func manhattan_distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
