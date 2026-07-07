class_name WorldEntityMarkerRenderer
extends RefCounted

const ACTION_HINT_FONT_SIZE := 11
const ACTION_HINT_HEIGHT := 22.0
const ACTION_HINT_MAX_CHARS := 22
const ACTION_HINT_MIN_WIDTH := 48.0
const ACTION_HINT_MAX_WIDTH := 148.0
const SELECTED_ACTION_HINT_PICK_DISTANCE := -2.0
const ACTION_HINT_PICK_DISTANCE := -1.0
const DEFAULT_MARKER_PICK_RADIUS := 40.0
const LARGE_MARKER_PICK_RADIUS := 46.0
const LARGE_MARKER_KINDS := ["container", "door", "poi", "rest"]


static func ellipsized(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	if max_chars <= 1:
		return value.substr(0, max_chars)
	return "%s..." % value.substr(0, max_chars - 3)


static func draw_quest_marker(
	canvas: CanvasItem, text: String, action_hint_visible: bool, action_hint_offset_y: float
) -> void:
	var center := quest_marker_center(action_hint_visible, action_hint_offset_y)
	var points := PackedVector2Array(
		[
			center + Vector2(0, -7),
			center + Vector2(24, 0),
			center + Vector2(0, 7),
			center + Vector2(-24, 0)
		]
	)
	canvas.draw_polygon(points, PackedColorArray([Color(0.95, 0.72, 0.20, 0.95)]))
	var outline := PackedVector2Array([points[0], points[1], points[2], points[3], points[0]])
	canvas.draw_polyline(outline, Color(0.15, 0.10, 0.03), 1.5)
	var font: Font = ThemeDB.fallback_font
	if font:
		canvas.draw_string(
			font,
			center + Vector2(-16.0, 4.0),
			text,
			HORIZONTAL_ALIGNMENT_CENTER,
			32.0,
			9,
			Color(0.08, 0.05, 0.01)
		)


static func quest_marker_center(action_hint_visible: bool, action_hint_offset_y: float) -> Vector2:
	return Vector2(0.0, (-58.0 + action_hint_offset_y) if action_hint_visible else -36.0)


static func quest_marker_rect(action_hint_visible: bool, action_hint_offset_y: float) -> Rect2:
	var center := quest_marker_center(action_hint_visible, action_hint_offset_y)
	return Rect2(center - Vector2(26.0, 10.0), Vector2(52.0, 20.0))


static func draw_action_hint(
	canvas: CanvasItem, text: String, selected: bool, offset_y: float
) -> void:
	var rect := action_hint_rect(text, offset_y)
	var bg_color := Color(0.05, 0.07, 0.06, 0.82)
	var border_color := Color(0.86, 0.78, 0.58, 0.50)
	var text_color := Color(0.96, 0.94, 0.82)
	if selected:
		bg_color = Color(0.20, 0.16, 0.07, 0.92)
		border_color = Color(1.0, 0.88, 0.32, 0.90)
		text_color = Color(1.0, 0.95, 0.66)
	canvas.draw_rect(rect, bg_color, true)
	canvas.draw_rect(rect, border_color, false, 1.0)
	var font: Font = ThemeDB.fallback_font
	if font:
		canvas.draw_string(
			font,
			rect.position + Vector2(8.0, 15.5),
			text,
			HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 16.0,
			ACTION_HINT_FONT_SIZE,
			text_color
		)


static func action_hint_rect(text: String, offset_y: float) -> Rect2:
	var width := clampf(
		float(text.length()) * 6.6 + 18.0, ACTION_HINT_MIN_WIDTH, ACTION_HINT_MAX_WIDTH
	)
	var position := Vector2(-width * 0.5, -45.0 + offset_y)
	return Rect2(position, Vector2(width, ACTION_HINT_HEIGHT))


static func marker_pick_radius(kind: String, requested_radius: float) -> float:
	var base_radius := maxf(requested_radius, DEFAULT_MARKER_PICK_RADIUS)
	if LARGE_MARKER_KINDS.has(kind):
		return maxf(base_radius, LARGE_MARKER_PICK_RADIUS)
	return base_radius
