extends GutTest

const StableHash = preload("res://scripts/core/stable_hash.gd")


func test_index_is_deterministic_and_bounded() -> void:
	var first := StableHash.index("people_tuskfolk:variant", 17)
	var second := StableHash.index("people_tuskfolk:variant", 17)

	assert_eq(first, second)
	assert_gte(first, 0)
	assert_lt(first, 17)
	assert_eq(StableHash.index("anything", 0), 0)


func test_unit_maps_to_zero_one_range() -> void:
	var value := StableHash.unit("marking-roll")

	assert_gte(value, 0.0)
	assert_lte(value, 1.0)
	assert_eq(value, float(StableHash.index("marking-roll", 1001)) / 1000.0)
