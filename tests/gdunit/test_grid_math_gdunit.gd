extends GdUnitTestSuite

const GridMath = preload("res://scripts/core/grid_math.gd")


func test_tile_world_round_trip() -> void:
	var tile := Vector2i(2, 3)
	assert_vector(GridMath.tile_to_world(tile)).is_equal(Vector2(32, 48))
	assert_that(GridMath.world_to_tile(Vector2(32, 48))).is_equal(tile)
