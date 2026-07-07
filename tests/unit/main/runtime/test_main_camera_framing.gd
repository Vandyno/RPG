extends GutTest


func test_uses_compact_framing_for_small_viewports() -> void:
	assert_false(MainCameraFraming.uses_compact_framing(Vector2(1280, 720)))
	assert_true(MainCameraFraming.uses_compact_framing(Vector2(800, 720)))
	assert_true(MainCameraFraming.uses_compact_framing(Vector2(1280, 480)))


func test_position_for_player_keeps_player_centered_when_focus_is_clear() -> void:
	var player := Vector2(100, 100)

	assert_eq(
		MainCameraFraming.position_for_player(
			player, Vector2(100, 120), Vector2(640, 360), Vector2.ONE
		),
		player
	)
	assert_eq(
		MainCameraFraming.position_for_player(
			player, Vector2(100, 220), Vector2(640, 360), Vector2(1, 0)
		),
		player
	)


func test_position_for_player_offsets_compact_camera_to_clear_bottom_hud() -> void:
	var player := Vector2(100, 100)
	var result := MainCameraFraming.position_for_player(
		player, Vector2(100, 260), Vector2(640, 360), Vector2.ONE
	)

	assert_eq(result.x, player.x)
	assert_gt(result.y, player.y)
	assert_lte(result.y - player.y, MainCameraFraming.COMPACT_MAX_VERTICAL_OFFSET)
