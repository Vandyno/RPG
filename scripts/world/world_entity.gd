class_name WorldEntity
extends Node2D

const GridMath = preload("res://scripts/core/grid_math.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")
const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")
const FacingBuckets = preload("res://scripts/core/facing_buckets.gd")

const COLLISION_RADIUS := 10.0
const MAX_COLLISION_STEP := 8.0
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

var data: Dictionary
var global_tile := Vector2i.ZERO
var highlighted := false
var action_hint_visible := false
var action_hint_text := ""
var action_hint_selected := false
var action_hint_offset_y := 0.0
var quest_marker_visible := false
var quest_marker_text := ""
var humanoid_avatar: HumanoidAvatar2D
var facing_direction := Vector2.DOWN


func setup(entity_data: Dictionary, content = null) -> void:
	data = entity_data.duplicate(true)
	global_tile = _tile_from_data(data.get("global_tile", [0, 0]))
	if not data.has("_spawn_global_tile"):
		data["_spawn_global_tile"] = [global_tile.x, global_tile.y]
	facing_direction = _direction_from_data(data.get("facing_direction", [0, 1]))
	position = _world_position_from_data(data.get("world_position", []), _center_of_tile(global_tile))
	global_tile = GridMath.world_to_tile(position)
	data["global_tile"] = [global_tile.x, global_tile.y]
	name = String(data.get("id", "entity"))
	_setup_humanoid_avatar(content)
	queue_redraw()


func get_entity_id() -> String:
	return String(data.get("id", ""))


func get_display_name() -> String:
	return String(data.get("name", get_entity_id()))


func get_kind() -> String:
	return String(data.get("kind", "object"))


func is_actor() -> bool:
	return ActorRules.is_actor_data(data)


func is_hostile_to_player() -> bool:
	return ActorRules.is_hostile_to_player_data(data)


func has_combat_behavior() -> bool:
	return ActorRules.has_combat_behavior_data(data)


func is_combat_target() -> bool:
	return ActorRules.is_combat_target_data(data)


func set_global_tile(tile: Vector2i) -> void:
	set_world_position(_center_of_tile(tile))


func set_world_position(world_position: Vector2) -> void:
	position = world_position
	global_tile = GridMath.world_to_tile(position)
	data["global_tile"] = [global_tile.x, global_tile.y]
	data["world_position"] = [position.x, position.y]
	data["_runtime_moved"] = true
	queue_redraw()


func set_facing_direction(value: Vector2) -> void:
	if value.length() <= 0.01:
		return
	facing_direction = FacingBuckets.snap_direction(value, facing_direction)
	data["facing_direction"] = [facing_direction.x, facing_direction.y]
	if humanoid_avatar:
		humanoid_avatar.set_facing_direction(facing_direction)


func get_facing_direction() -> Vector2:
	return facing_direction


func set_locomotion(is_moving: bool, delta: float) -> void:
	if humanoid_avatar:
		humanoid_avatar.set_locomotion(is_moving, false, delta)


func try_move(
	direction: Vector2,
	delta: float = 1.0,
	chunk_manager = null,
	speed_pixels_per_second: float = 80.0
) -> bool:
	var normalized_direction := direction.normalized()
	if normalized_direction == Vector2.ZERO or delta <= 0.0 or speed_pixels_per_second <= 0.0:
		set_locomotion(false, delta)
		return false
	set_facing_direction(normalized_direction)
	var remaining_distance := speed_pixels_per_second * delta
	var moved := false
	while remaining_distance > 0.0:
		var step_distance := minf(remaining_distance, MAX_COLLISION_STEP)
		var motion := normalized_direction * step_distance
		if not _try_move_step(motion, chunk_manager):
			break
		moved = true
		remaining_distance -= step_distance
	set_locomotion(moved, delta)
	return moved


func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()


func set_action_hint(
	visible: bool, text: String = "", selected: bool = false, offset_y: float = 0.0
) -> void:
	var next_text := _ellipsized(text, ACTION_HINT_MAX_CHARS)
	var next_offset_y := 0.0
	if visible and not selected:
		next_offset_y = offset_y
	if (
		action_hint_visible == visible
		and action_hint_text == next_text
		and action_hint_selected == selected
		and is_equal_approx(action_hint_offset_y, next_offset_y)
	):
		return
	action_hint_visible = visible
	action_hint_text = next_text
	action_hint_selected = selected
	action_hint_offset_y = next_offset_y
	z_index = 20 if action_hint_selected else 0
	queue_redraw()


func set_quest_marker(visible: bool, text: String = "Quest") -> void:
	var next_text := _ellipsized(text, 12)
	if quest_marker_visible == visible and quest_marker_text == next_text:
		return
	quest_marker_visible = visible
	quest_marker_text = next_text
	queue_redraw()


func get_pick_distance(world_position: Vector2, pick_radius_pixels: float) -> float:
	var local_position := to_local(world_position)
	if action_hint_visible and _action_hint_rect().has_point(local_position):
		return (
			SELECTED_ACTION_HINT_PICK_DISTANCE
			if action_hint_selected
			else ACTION_HINT_PICK_DISTANCE
		)
	if quest_marker_visible and _quest_marker_rect().has_point(local_position):
		return 0.5
	var marker_radius := _marker_pick_radius(pick_radius_pixels)
	if local_position.length() <= marker_radius:
		return local_position.length()
	return INF


func _draw() -> void:
	var color := Color(0.75, 0.20, 0.16) if is_combat_target() else _color_for_kind(get_kind())
	if quest_marker_visible:
		_draw_quest_marker()
	if action_hint_visible:
		_draw_action_hint()
	if highlighted:
		draw_circle(Vector2.ZERO, 15.0, Color(1.0, 0.88, 0.32, 0.28))
		draw_circle(Vector2.ZERO, 15.0, Color(1.0, 0.88, 0.32), false, 2.0)
	if humanoid_avatar:
		return
	draw_circle(Vector2.ZERO, 10.0, color)
	draw_circle(Vector2.ZERO, 10.0, Color(0.04, 0.04, 0.04), false, 2.0)
	if is_combat_target():
		draw_line(Vector2(-5, -5), Vector2(5, 5), Color(0.12, 0.02, 0.02), 2.0)
		draw_line(Vector2(5, -5), Vector2(-5, 5), Color(0.12, 0.02, 0.02), 2.0)
	elif get_kind() == "npc":
		draw_circle(Vector2(0, -2), 3.0, Color(0.96, 0.88, 0.62))
	elif get_kind() == "pickup":
		draw_rect(Rect2(Vector2(-5, -5), Vector2(10, 10)), Color(0.93, 0.76, 0.25), true)
	elif get_kind() == "container":
		draw_rect(Rect2(Vector2(-7, -5), Vector2(14, 10)), Color(0.55, 0.34, 0.14), true)
		draw_line(Vector2(-7, -1), Vector2(7, -1), Color(0.92, 0.76, 0.42), 1.5)
	elif get_kind() == "door":
		draw_rect(Rect2(Vector2(-4, -9), Vector2(8, 18)), Color(0.44, 0.28, 0.16), true)
		draw_circle(Vector2(2, 0), 1.5, Color(0.96, 0.78, 0.34))
	elif get_kind() == "readable":
		draw_rect(Rect2(Vector2(-6, -8), Vector2(12, 16)), Color(0.93, 0.88, 0.67), true)
	elif get_kind() == "body":
		draw_ellipse(Vector2(0.0, 2.0), 11.0, 6.0, Color(0.36, 0.25, 0.17))
		draw_ellipse(Vector2(0.0, 2.0), 11.0, 6.0, Color(0.05, 0.04, 0.03), false, 1.5)
	elif get_kind() == "rest":
		draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.45, 0.16))
		draw_line(Vector2(-6, 6), Vector2(6, 6), Color(0.25, 0.12, 0.05), 2.0)
	elif get_kind() == "poi":
		draw_rect(Rect2(Vector2(-9, -3), Vector2(18, 12)), Color(0.46, 0.36, 0.22), true)
		var roof := PackedVector2Array([Vector2(-11, -3), Vector2(0, -11), Vector2(11, -3)])
		draw_polygon(roof, PackedColorArray([Color(0.58, 0.18, 0.14)]))
		draw_rect(Rect2(Vector2(-2, 2), Vector2(4, 7)), Color(0.18, 0.11, 0.07), true)
	elif get_kind() == "location":
		var points := PackedVector2Array(
			[Vector2(0, -8), Vector2(8, 0), Vector2(0, 8), Vector2(-8, 0)]
		)
		draw_polygon(points, PackedColorArray([Color(0.42, 0.68, 0.92)]))


func _draw_quest_marker() -> void:
	var center := _quest_marker_center()
	var points := PackedVector2Array(
		[
			center + Vector2(0, -7),
			center + Vector2(24, 0),
			center + Vector2(0, 7),
			center + Vector2(-24, 0)
		]
	)
	draw_polygon(points, PackedColorArray([Color(0.95, 0.72, 0.20, 0.95)]))
	var outline := PackedVector2Array([points[0], points[1], points[2], points[3], points[0]])
	draw_polyline(outline, Color(0.15, 0.10, 0.03), 1.5)
	var font: Font = ThemeDB.fallback_font
	if font:
		draw_string(
			font,
			center + Vector2(-16.0, 4.0),
			quest_marker_text,
			HORIZONTAL_ALIGNMENT_CENTER,
			32.0,
			9,
			Color(0.08, 0.05, 0.01)
		)


func _quest_marker_center() -> Vector2:
	return Vector2(0.0, (-58.0 + action_hint_offset_y) if action_hint_visible else -36.0)


func _quest_marker_rect() -> Rect2:
	var center := _quest_marker_center()
	return Rect2(center - Vector2(26.0, 10.0), Vector2(52.0, 20.0))


func _draw_action_hint() -> void:
	var rect := _action_hint_rect()
	var bg_color := Color(0.05, 0.07, 0.06, 0.82)
	var border_color := Color(0.86, 0.78, 0.58, 0.50)
	var text_color := Color(0.96, 0.94, 0.82)
	if action_hint_selected:
		bg_color = Color(0.20, 0.16, 0.07, 0.92)
		border_color = Color(1.0, 0.88, 0.32, 0.90)
		text_color = Color(1.0, 0.95, 0.66)
	draw_rect(rect, bg_color, true)
	draw_rect(rect, border_color, false, 1.0)
	var font: Font = ThemeDB.fallback_font
	if font:
		draw_string(
			font,
			rect.position + Vector2(8.0, 15.5),
			action_hint_text,
			HORIZONTAL_ALIGNMENT_LEFT,
			rect.size.x - 16.0,
			ACTION_HINT_FONT_SIZE,
			text_color
		)


func _action_hint_rect() -> Rect2:
	var width := clampf(
		float(action_hint_text.length()) * 6.6 + 18.0, ACTION_HINT_MIN_WIDTH, ACTION_HINT_MAX_WIDTH
	)
	var position := Vector2(-width * 0.5, -45.0 + action_hint_offset_y)
	return Rect2(position, Vector2(width, ACTION_HINT_HEIGHT))


func _marker_pick_radius(requested_radius: float) -> float:
	var base_radius := maxf(requested_radius, DEFAULT_MARKER_PICK_RADIUS)
	if LARGE_MARKER_KINDS.has(get_kind()):
		return maxf(base_radius, LARGE_MARKER_PICK_RADIUS)
	return base_radius


func _ellipsized(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	if max_chars <= 1:
		return value.substr(0, max_chars)
	return "%s..." % value.substr(0, max_chars - 3)


func _color_for_kind(kind: String) -> Color:
	var color := Color(0.60, 0.60, 0.60)
	match kind:
		"npc":
			color = Color(0.61, 0.43, 0.24)
		"pickup":
			color = Color(0.78, 0.58, 0.12)
		"container":
			color = Color(0.50, 0.32, 0.16)
		"door":
			color = Color(0.38, 0.25, 0.16)
		"readable":
			color = Color(0.84, 0.80, 0.58)
		"rest":
			color = Color(0.94, 0.45, 0.18)
		"poi":
			color = Color(0.48, 0.38, 0.24)
		"location":
			color = Color(0.18, 0.38, 0.56)
	return color


func _tile_from_data(value: Variant) -> Vector2i:
	if not value is Array:
		return Vector2i.ZERO
	if value.size() < 2:
		return Vector2i.ZERO
	if not _is_number(value[0]) or not _is_number(value[1]):
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))


func _try_move_step(motion: Vector2, chunk_manager = null) -> bool:
	var next_position := position + motion
	if _can_stand_at(next_position, chunk_manager):
		set_world_position(next_position)
		return true

	var horizontal_position := position + Vector2(motion.x, 0.0)
	if not is_zero_approx(motion.x) and _can_stand_at(horizontal_position, chunk_manager):
		set_world_position(horizontal_position)
		return true

	var vertical_position := position + Vector2(0.0, motion.y)
	if not is_zero_approx(motion.y) and _can_stand_at(vertical_position, chunk_manager):
		set_world_position(vertical_position)
		return true

	return false


func _can_stand_at(world_position: Vector2, chunk_manager = null) -> bool:
	if not chunk_manager:
		return true
	var samples := [
		Vector2.ZERO,
		Vector2(COLLISION_RADIUS, 0.0),
		Vector2(-COLLISION_RADIUS, 0.0),
		Vector2(0.0, COLLISION_RADIUS),
		Vector2(0.0, -COLLISION_RADIUS),
		Vector2(COLLISION_RADIUS, COLLISION_RADIUS),
		Vector2(COLLISION_RADIUS, -COLLISION_RADIUS),
		Vector2(-COLLISION_RADIUS, COLLISION_RADIUS),
		Vector2(-COLLISION_RADIUS, -COLLISION_RADIUS)
	]
	for sample_offset in samples:
		var sampled_tile := GridMath.world_to_tile(world_position + sample_offset)
		if not chunk_manager.is_walkable(sampled_tile):
			return false
	return true


func _direction_from_data(value: Variant) -> Vector2:
	if not value is Array or value.size() < 2:
		return Vector2.DOWN
	if not _is_number(value[0]) or not _is_number(value[1]):
		return Vector2.DOWN
	var direction := Vector2(float(value[0]), float(value[1]))
	if direction.length() <= 0.01:
		return Vector2.DOWN
	return FacingBuckets.snap_direction(direction, Vector2.DOWN)


func _world_position_from_data(value: Variant, fallback: Vector2) -> Vector2:
	if not value is Array or value.size() < 2:
		return fallback
	if not _is_number(value[0]) or not _is_number(value[1]):
		return fallback
	return Vector2(float(value[0]), float(value[1]))


func _center_of_tile(tile: Vector2i) -> Vector2:
	return GridMath.tile_to_world(tile) + Vector2(GridMath.TILE_SIZE, GridMath.TILE_SIZE) * 0.5


func _is_number(value: Variant) -> bool:
	return value is int or value is float


func _setup_humanoid_avatar(content = null) -> void:
	if not ["npc", "body"].has(get_kind()):
		return
	if not (data.get("character_profile", {}) is Dictionary):
		return
	humanoid_avatar = HumanoidAvatar2D.new()
	humanoid_avatar.name = "HumanoidAvatar2D"
	add_child(humanoid_avatar)
	var equipped: Dictionary = {}
	if data.get("equipped_items", {}) is Dictionary:
		equipped = data.get("equipped_items", {})
	humanoid_avatar.setup(data.get("character_profile", {}), equipped, content)
	humanoid_avatar.set_facing_direction(facing_direction)
	if get_kind() == "body":
		humanoid_avatar.rotation = PI * 0.5
		humanoid_avatar.position = Vector2(2.0, 4.0)
		humanoid_avatar.scale = Vector2(0.88, 0.88)
