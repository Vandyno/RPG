extends GutTest

const GridMath = preload("res://scripts/core/grid_math.gd")


func test_tile_world_round_trip() -> void:
	var tile := Vector2i(5, -3)
	var world := GridMath.tile_to_world(tile)
	assert_eq(world, Vector2(80, -48))
	assert_eq(GridMath.world_to_tile(world), tile)


func test_chunk_math_handles_negative_tiles() -> void:
	assert_eq(GridMath.tile_to_chunk(Vector2i(0, 0)), Vector2i(0, 0))
	assert_eq(GridMath.tile_to_chunk(Vector2i(15, 15)), Vector2i(0, 0))
	assert_eq(GridMath.tile_to_chunk(Vector2i(16, 16)), Vector2i(1, 1))
	assert_eq(GridMath.tile_to_chunk(Vector2i(-1, -1)), Vector2i(-1, -1))
	assert_eq(GridMath.tile_to_chunk(Vector2i(-16, -16)), Vector2i(-1, -1))
	assert_eq(GridMath.tile_to_chunk(Vector2i(-17, -17)), Vector2i(-2, -2))


func test_keys_are_stable() -> void:
	assert_eq(GridMath.chunk_key(Vector2i(2, -4)), "surface:2:-4")
	assert_eq(GridMath.tile_key(Vector2i(10, 12), "underground"), "underground:10:12")
