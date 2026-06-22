extends GutTest

const MainCameraFraming = preload("res://scripts/main/main_camera_framing.gd")


func test_default_landscape_camera_stays_centered_on_player() -> void:
	var player_position := Vector2(8.0, 8.0)
	var focus_position := Vector2(8.0, 88.0)

	assert_eq(
		MainCameraFraming.position_for_player(
			player_position, focus_position, Vector2(1152.0, 648.0), Vector2(2.0, 2.0)
		),
		player_position
	)


func test_compact_landscape_camera_keeps_selected_target_above_bottom_controls() -> void:
	var player_position := Vector2(8.0, 8.0)
	var focus_position := Vector2(8.0, 88.0)
	var viewport_size := Vector2(640.0, 360.0)
	var zoom := Vector2(2.0, 2.0)

	var camera_position := MainCameraFraming.position_for_player(
		player_position, focus_position, viewport_size, zoom
	)
	var projected_focus_y := viewport_size.y * 0.5 + (focus_position.y - camera_position.y) * zoom.y
	var bottom_safe_y := (
		viewport_size.y - MainCameraFraming.BOTTOM_HUD_CLEARANCE - MainCameraFraming.FOCUS_MARGIN
	)

	assert_gt(camera_position.y, player_position.y)
	assert_lte(projected_focus_y, bottom_safe_y)


func test_compact_camera_does_not_shift_when_focus_already_clear() -> void:
	var player_position := Vector2(8.0, 8.0)
	var focus_position := Vector2(8.0, 24.0)

	assert_eq(
		MainCameraFraming.position_for_player(
			player_position, focus_position, Vector2(640.0, 360.0), Vector2(2.0, 2.0)
		),
		player_position
	)


func test_compact_camera_vertical_shift_is_capped() -> void:
	var player_position := Vector2(8.0, 8.0)
	var far_focus_position := Vector2(8.0, 320.0)

	assert_eq(
		MainCameraFraming.position_for_player(
			player_position, far_focus_position, Vector2(640.0, 360.0), Vector2(2.0, 2.0)
		).y,
		player_position.y + MainCameraFraming.COMPACT_MAX_VERTICAL_OFFSET
	)
