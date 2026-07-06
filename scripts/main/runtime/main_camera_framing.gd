class_name MainCameraFraming
extends RefCounted

const COMPACT_CAMERA_WIDTH := 980.0
const COMPACT_CAMERA_HEIGHT := 540.0
const BOTTOM_HUD_CLEARANCE := 84.0
const FOCUS_MARGIN := 18.0
const COMPACT_MAX_VERTICAL_OFFSET := 64.0


static func position_for_player(
	player_position: Vector2,
	focus_position: Vector2,
	viewport_size: Vector2,
	zoom: Vector2
) -> Vector2:
	if not uses_compact_framing(viewport_size) or zoom.y <= 0.0:
		return player_position
	var bottom_safe_y := viewport_size.y - BOTTOM_HUD_CLEARANCE - FOCUS_MARGIN
	var projected_focus_y := viewport_size.y * 0.5 + (focus_position.y - player_position.y) * zoom.y
	if projected_focus_y <= bottom_safe_y:
		return player_position
	var offset_y := minf(COMPACT_MAX_VERTICAL_OFFSET, (projected_focus_y - bottom_safe_y) / zoom.y)
	return player_position + Vector2(0.0, offset_y)


static func uses_compact_framing(viewport_size: Vector2) -> bool:
	return viewport_size.x < COMPACT_CAMERA_WIDTH or viewport_size.y < COMPACT_CAMERA_HEIGHT
