extends GutTest

const DirectionalAttack = preload("res://scripts/core/directional_attack.gd")


func test_thrust_hits_narrow_forward_line() -> void:
	var attack := {"shape": "thrust", "range_pixels": 80.0, "width_pixels": 18.0}

	assert_true(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(70, 0), attack)
	)
	assert_true(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(35, 8), attack)
	)
	assert_false(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(35, 14), attack)
	)
	assert_false(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(-12, 0), attack)
	)


func test_swing_hits_front_arc_and_misses_behind() -> void:
	var attack := {
		"shape": "swing",
		"range_pixels": 52.0,
		"width_pixels": 38.0,
		"arc_degrees": 120.0
	}

	assert_true(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(38, 18), attack)
	)
	assert_true(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(38, -18), attack)
	)
	assert_false(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(-12, 0), attack)
	)
	assert_false(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(60, 0), attack)
	)


func test_stream_widens_over_range() -> void:
	var attack := {"shape": "stream", "range_pixels": 96.0, "width_pixels": 50.0}

	assert_true(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(12, 2), attack)
	)
	assert_false(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(12, 12), attack)
	)
	assert_true(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(90, 20), attack)
	)
	assert_false(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(104, 0), attack)
	)


func test_projectile_uses_bow_line_shape() -> void:
	var attack := {"shape": "projectile", "range_pixels": 150.0, "width_pixels": 14.0}

	assert_true(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(145, 6), attack)
	)
	assert_false(
		DirectionalAttack.contains_point(Vector2.ZERO, Vector2.RIGHT, Vector2(145, 12), attack)
	)
