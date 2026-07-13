class_name WorldEntity
extends Node2D

const GridMath = preload("res://scripts/core/grid_math.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")
const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")
const FacingBuckets = preload("res://scripts/core/facing_buckets.gd")
const ItemVisual2D = preload("res://scripts/items/item_visual_2d.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")
const WorldEntityFallbackRenderer = preload("res://scripts/world/world_entity_fallback_renderer.gd")
const WorldEntityMarkerRenderer = preload("res://scripts/world/world_entity_marker_renderer.gd")
const WorldEntityMovement = preload("res://scripts/world/world_entity_movement.gd")

var data: Dictionary
var world_layer := "surface"
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
var content_database


func setup(entity_data: Dictionary, content = null) -> void:
	data = entity_data.duplicate(true)
	content_database = content
	world_layer = String(data.get("world_layer", "surface"))
	if world_layer.is_empty():
		world_layer = "surface"
	data["world_layer"] = world_layer
	global_tile = _tile_from_data(data.get("global_tile", [0, 0]))
	if not data.has("_spawn_global_tile"):
		data["_spawn_global_tile"] = [global_tile.x, global_tile.y]
	facing_direction = _direction_from_data(data.get("facing_direction", [0, 1]))
	position = VariantFields.vector2_from_pair(
		data.get("world_position", []), _center_of_tile(global_tile)
	)
	global_tile = GridMath.world_to_tile(position)
	data["global_tile"] = [global_tile.x, global_tile.y]
	name = String(data.get("id", "entity"))
	_setup_humanoid_avatar(content)
	_apply_actor_state_visual()
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


func set_actor_state(state: String) -> void:
	data["state"] = state
	_apply_actor_state_visual()
	queue_redraw()


func set_global_tile(tile: Vector2i) -> void:
	set_world_position(_center_of_tile(tile))


func set_world_layer(layer: String) -> void:
	world_layer = "surface" if layer.is_empty() else layer
	data["world_layer"] = world_layer
	queue_redraw()


func get_world_layer() -> String:
	return world_layer


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
	return WorldEntityMovement.try_move(
		self, direction, delta, chunk_manager, speed_pixels_per_second
	)


func set_highlighted(value: bool) -> void:
	if highlighted == value:
		return
	highlighted = value
	queue_redraw()


func set_action_hint(
	visible: bool, text: String = "", selected: bool = false, offset_y: float = 0.0
) -> void:
	var next_text := WorldEntityMarkerRenderer.ellipsized(
		text, WorldEntityMarkerRenderer.ACTION_HINT_MAX_CHARS
	)
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
	var next_text := WorldEntityMarkerRenderer.ellipsized(text, 12)
	if quest_marker_visible == visible and quest_marker_text == next_text:
		return
	quest_marker_visible = visible
	quest_marker_text = next_text
	queue_redraw()


func get_pick_distance(world_position: Vector2, pick_radius_pixels: float) -> float:
	var local_position := to_local(world_position)
	if action_hint_visible and _action_hint_rect().has_point(local_position):
		return (
			WorldEntityMarkerRenderer.SELECTED_ACTION_HINT_PICK_DISTANCE
			if action_hint_selected
			else WorldEntityMarkerRenderer.ACTION_HINT_PICK_DISTANCE
		)
	if quest_marker_visible and _quest_marker_rect().has_point(local_position):
		return 0.5
	var marker_radius := _marker_pick_radius(pick_radius_pixels)
	if local_position.length() <= marker_radius:
		return local_position.length()
	return INF


func get_pick_match(world_position: Vector2, pick_radius_pixels: float) -> Dictionary:
	var local_position := to_local(world_position)
	if action_hint_visible and _action_hint_rect().has_point(local_position):
		return {
			"distance": 0.0,
			"kind": "hint",
			"selected": action_hint_selected
		}
	if quest_marker_visible and _quest_marker_rect().has_point(local_position):
		return {"distance": 0.0, "kind": "quest", "selected": false}
	var marker_radius := _marker_pick_radius(pick_radius_pixels)
	if local_position.length() <= marker_radius:
		return {"distance": local_position.length(), "kind": "body", "selected": false}
	return {"distance": INF, "kind": "none", "selected": false}


func _draw() -> void:
	_draw_perception_debug()
	_draw_awareness_marker()
	if quest_marker_visible:
		_draw_quest_marker()
	if action_hint_visible:
		_draw_action_hint()
	if highlighted:
		var highlight := PackedVector2Array(
			[
				Vector2(-13.0, 0.0),
				Vector2(0.0, -8.0),
				Vector2(13.0, 0.0),
				Vector2(0.0, 8.0),
				Vector2(-13.0, 0.0)
			]
		)
		draw_polyline(highlight, Color(1.0, 0.88, 0.32, 0.92), 1.5)
	if humanoid_avatar:
		return
	WorldEntityFallbackRenderer.draw_entity(
		self,
		get_kind(),
		is_combat_target(),
		get_pickup_item_visual_state(),
		String(data.get("visual_style", "")),
		data
	)


func _draw_perception_debug() -> void:
	if not bool(data.get("debug_perception_visible", false)) or not ActorRules.is_actor_data(data):
		return
	if ActorRules.is_dead_actor_data(data):
		return
	var distance := maxf(8.0, float(data.get("vision_distance", 192.0)))
	var degrees := clampf(float(data.get("vision_degrees", 120.0)), 1.0, 360.0)
	var points := PackedVector2Array([Vector2.ZERO])
	var half_angle := deg_to_rad(degrees * 0.5)
	var start_angle := facing_direction.angle() - half_angle
	for index in range(17):
		var angle := start_angle + (half_angle * 2.0 * float(index) / 16.0)
		points.append(Vector2.RIGHT.rotated(angle) * distance)
	draw_colored_polygon(points, Color(0.95, 0.78, 0.18, 0.12))
	draw_polyline(points, Color(0.98, 0.82, 0.24, 0.45), 1.0)
	draw_circle(Vector2.ZERO, maxf(8.0, float(data.get("hearing_radius", 144.0))), Color(0.2, 0.65, 1.0, 0.05))


func _draw_awareness_marker() -> void:
	var state := String(data.get("perception_awareness_state", ""))
	if state.is_empty() or ActorRules.is_dead_actor_data(data):
		return
	var color := Color(1.0, 0.76, 0.18, 0.96) if state == "suspicious" else Color(0.95, 0.18, 0.16, 0.98)
	var center := Vector2(0.0, -27.0)
	draw_circle(center, 7.0, color)
	draw_string(
		ThemeDB.fallback_font,
		center + Vector2(-2.5, 4.0),
		"?" if state == "suspicious" else "!",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1.0,
		11,
		Color(0.08, 0.06, 0.04)
	)


func _draw_quest_marker() -> void:
	WorldEntityMarkerRenderer.draw_quest_marker(
		self, quest_marker_text, action_hint_visible, action_hint_offset_y
	)


func _quest_marker_center() -> Vector2:
	return WorldEntityMarkerRenderer.quest_marker_center(
		action_hint_visible, action_hint_offset_y
	)


func _quest_marker_rect() -> Rect2:
	return WorldEntityMarkerRenderer.quest_marker_rect(action_hint_visible, action_hint_offset_y)


func _draw_action_hint() -> void:
	WorldEntityMarkerRenderer.draw_action_hint(
		self, action_hint_text, action_hint_selected, action_hint_offset_y
	)


func _action_hint_rect() -> Rect2:
	return WorldEntityMarkerRenderer.action_hint_rect(action_hint_text, action_hint_offset_y)


func _marker_pick_radius(requested_radius: float) -> float:
	var authored_radius: Variant = data.get("pick_radius", null)
	if VariantFields.is_number(authored_radius) and float(authored_radius) > 0.0:
		return minf(requested_radius, float(authored_radius))
	return WorldEntityMarkerRenderer.marker_pick_radius(get_kind(), requested_radius)


func get_pickup_item_visual_state() -> Dictionary:
	if get_kind() != "pickup" or not content_database:
		return {}
	var item_id := String(data.get("item_id", ""))
	if item_id.is_empty() or not content_database.has_method("get_item"):
		return {}
	var item: Dictionary = content_database.get_item(item_id)
	var visual_id := ItemVisual2D.visual_id_from_item(item)
	if not ItemVisual2D.is_item_visual(visual_id):
		return {}
	var direction := _ground_item_direction()
	var state := {"color": ItemVisual2D.default_color(visual_id), "ground": true}
	return ItemVisual2D.model(visual_id, Vector2.ZERO, direction, state)


func _ground_item_direction() -> Vector2:
	var pair := VariantFields.numeric_pair(data.get("item_direction", []))
	if not pair.is_empty():
		var authored_direction := Vector2(float(pair[0]), float(pair[1]))
		if authored_direction.length() > 0.01:
			return authored_direction.normalized()
	var seed := String(data.get("id", data.get("item_id", "")))
	var hash_value: int = abs(seed.hash())
	var angle := float(hash_value % 360) * PI / 180.0
	return Vector2.RIGHT.rotated(angle)


func _tile_from_data(value: Variant) -> Vector2i:
	return VariantFields.vector2i_from_pair(value, Vector2i.ZERO)


func _try_move_step(motion: Vector2, chunk_manager = null) -> bool:
	return WorldEntityMovement._try_move_step(self, motion, chunk_manager)


func _can_stand_at(world_position: Vector2, chunk_manager = null) -> bool:
	return WorldEntityMovement.can_stand_at(world_position, chunk_manager)


func _direction_from_data(value: Variant) -> Vector2:
	var direction := VariantFields.vector2_from_pair(value, Vector2.DOWN)
	if direction.length() <= 0.01:
		return Vector2.DOWN
	return FacingBuckets.snap_direction(direction, Vector2.DOWN)


func _center_of_tile(tile: Vector2i) -> Vector2:
	return GridMath.tile_to_world(tile) + Vector2(GridMath.TILE_SIZE, GridMath.TILE_SIZE) * 0.5


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


func _apply_actor_state_visual() -> void:
	if not humanoid_avatar:
		return
	if ActorRules.is_dead_actor_data(data) or get_kind() == "body":
		humanoid_avatar.rotation = PI * 0.5
		humanoid_avatar.position = Vector2(2.0, 4.0)
		humanoid_avatar.scale = Vector2(0.88, 0.88)
		return
	humanoid_avatar.rotation = 0.0
	humanoid_avatar.position = Vector2.ZERO
	humanoid_avatar.scale = Vector2.ONE
