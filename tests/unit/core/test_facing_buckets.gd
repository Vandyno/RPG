extends GutTest


func test_bucket_index_and_id_snap_cardinal_directions() -> void:
	assert_eq(FacingBuckets.bucket_index(Vector2.RIGHT), 0)
	assert_eq(FacingBuckets.bucket_id(Vector2.RIGHT), "east")
	assert_eq(FacingBuckets.bucket_index(Vector2.DOWN), 4)
	assert_eq(FacingBuckets.bucket_id(Vector2.DOWN), "south")
	assert_eq(FacingBuckets.bucket_index(Vector2.LEFT), 8)
	assert_eq(FacingBuckets.bucket_id(Vector2.LEFT), "west")
	assert_eq(FacingBuckets.bucket_index(Vector2.UP), 12)
	assert_eq(FacingBuckets.bucket_id(Vector2.UP), "north")


func test_snap_direction_uses_fallback_for_empty_vectors() -> void:
	var snapped := FacingBuckets.snap_direction(Vector2.ZERO, Vector2.LEFT)

	assert_true(snapped.is_equal_approx(Vector2.LEFT))
	assert_true(FacingBuckets.snap_direction(Vector2.ZERO, Vector2.ZERO).is_equal_approx(Vector2.DOWN))


func test_snap_direction_quantizes_to_sixteen_buckets() -> void:
	var raw := Vector2.RIGHT.rotated((TAU / float(FacingBuckets.COUNT)) * 2.1)
	var snapped := FacingBuckets.snap_direction(raw)

	assert_eq(FacingBuckets.bucket_id(snapped), "southeast")
	assert_true(snapped.is_normalized())
