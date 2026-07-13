# gdlint:disable=max-public-methods
class_name PlayerController
extends Node2D

const GridMath = preload("res://scripts/core/grid_math.gd")
const HumanoidProfile = preload("res://scripts/characters/humanoid_profile.gd")
const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")
const FacingBuckets = preload("res://scripts/core/facing_buckets.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")
const WorldEntityMovement = preload("res://scripts/world/world_entity_movement.gd")

const COLLISION_RADIUS := WorldEntityMovement.COLLISION_RADIUS
const MAX_COLLISION_STEP := WorldEntityMovement.MAX_COLLISION_STEP
const BLOCKED_MESSAGE_INTERVAL := 0.35
const DEFAULT_MAX_HEALTH := 100
const DEFAULT_MAX_MANA := 100.0
const SNEAK_SPEED_MULTIPLIER := 0.45
const MOVE_INPUT_THRESHOLD := 0.01
const FOOTSTEP_INTERVAL_SECONDS := 0.42
const SNEAK_FOOTSTEP_INTERVAL_SECONDS := 0.70
const FOOTSTEP_NOISE_RADIUS := 88.0
const SNEAK_FOOTSTEP_NOISE_RADIUS := 30.0

var event_bus: EventBus
var chunk_manager
var world_layer := "surface"
var global_tile := Vector2i.ZERO
var move_speed := 220.0
var blocked_message_cooldown := 0.0
var max_health := DEFAULT_MAX_HEALTH
var health := DEFAULT_MAX_HEALTH
var max_mana := DEFAULT_MAX_MANA
var mana := DEFAULT_MAX_MANA
var external_move_vector := Vector2.ZERO
var facing_direction := Vector2.DOWN
var humanoid_profile: Dictionary = HumanoidProfile.from_data({"character_id": "char_player"})
var humanoid_avatar: HumanoidAvatar2D
var is_sneaking := false
var footstep_cooldown := 0.0


func setup(bus: EventBus, chunks, start_tile: Vector2i = Vector2i.ZERO) -> void:
	event_bus = bus
	chunk_manager = chunks
	_apply_query_layer()
	_ensure_humanoid_avatar()
	set_global_tile(start_tile)


func _process(delta: float) -> void:
	blocked_message_cooldown = maxf(0.0, blocked_message_cooldown - delta)
	var direction := get_move_input_vector()
	var is_moving := direction.length() > MOVE_INPUT_THRESHOLD
	if humanoid_avatar:
		humanoid_avatar.set_locomotion(is_moving, is_sneaking, delta)
	if is_moving:
		try_move(direction, delta)
		_tick_footstep_noise(delta)
	else:
		footstep_cooldown = 0.0


func try_move(direction: Vector2, delta: float = 1.0) -> void:
	var normalized_direction := direction.normalized()
	if normalized_direction == Vector2.ZERO or delta <= 0.0:
		return
	facing_direction = FacingBuckets.snap_direction(normalized_direction, facing_direction)
	if humanoid_avatar:
		humanoid_avatar.set_facing_direction(facing_direction)
	var speed := move_speed * (SNEAK_SPEED_MULTIPLIER if is_sneaking else 1.0)
	var remaining_distance := speed * delta
	while remaining_distance > 0.0:
		var step_distance := minf(remaining_distance, MAX_COLLISION_STEP)
		var motion := normalized_direction * step_distance
		if not _try_move_step(motion):
			_post_blocked_message()
			return
		remaining_distance -= step_distance


func _try_move_step(motion: Vector2) -> bool:
	return WorldEntityMovement._try_move_step(self, motion, chunk_manager)


func set_global_tile(tile: Vector2i) -> void:
	set_world_position(_center_of_tile(tile))


func set_world_position(world_position: Vector2) -> void:
	position = world_position
	var new_tile := GridMath.world_to_tile(position)
	var tile_changed := new_tile != global_tile
	global_tile = new_tile
	if tile_changed and event_bus:
		event_bus.player_tile_changed.emit(global_tile, GridMath.tile_to_chunk(global_tile))
	queue_redraw()


func set_world_layer(layer: String) -> void:
	var next_layer := "surface" if layer.is_empty() else layer
	if world_layer == next_layer:
		_apply_query_layer()
		return
	world_layer = next_layer
	_apply_query_layer()
	if event_bus:
		event_bus.player_tile_changed.emit(global_tile, GridMath.tile_to_chunk(global_tile))


func get_world_layer() -> String:
	return world_layer


func get_save_data() -> Dictionary:
	return {
		"global_tile": [global_tile.x, global_tile.y],
		"world_position": [position.x, position.y],
		"chunk_coord":
		[GridMath.tile_to_chunk(global_tile).x, GridMath.tile_to_chunk(global_tile).y],
		"world_layer": world_layer,
		"stats": {},
		"health": health,
		"max_health": max_health,
		"mana": mana,
		"max_mana": max_mana,
		"humanoid_profile": humanoid_profile.duplicate(true)
	}


func load_save_data(data: Dictionary) -> void:
	var saved_profile: Variant = data.get("humanoid_profile", {})
	if saved_profile is Dictionary and not saved_profile.is_empty():
		set_humanoid_profile(saved_profile)
	set_world_layer(String(data.get("world_layer", "surface")))
	max_health = maxi(1, int(data.get("max_health", DEFAULT_MAX_HEALTH)))
	set_health(int(data.get("health", max_health)))
	max_mana = maxf(1.0, float(data.get("max_mana", DEFAULT_MAX_MANA)))
	set_mana(float(data.get("mana", max_mana)))
	var world_position := VariantFields.numeric_pair(data.get("world_position", []))
	if not world_position.is_empty():
		var loaded_position := Vector2(float(world_position[0]), float(world_position[1]))
		if _can_stand_at(loaded_position):
			set_world_position(loaded_position)
			return
	var tile_array := VariantFields.numeric_pair(data.get("global_tile", [0, 0]))
	if tile_array.is_empty():
		tile_array = [0, 0]
	var loaded_tile := Vector2i(int(tile_array[0]), int(tile_array[1]))
	var loaded_tile_position := _center_of_tile(loaded_tile)
	if _can_stand_at(loaded_tile_position):
		set_world_position(loaded_tile_position)
	else:
		set_world_position(_center_of_tile(Vector2i.ZERO))


func apply_damage(amount: int) -> int:
	if amount <= 0:
		return health
	set_health(health - amount)
	return health


func heal(amount: int) -> int:
	if amount <= 0:
		return health
	set_health(health + amount)
	return health


func spend_mana(amount: float) -> float:
	if amount <= 0.0 or mana <= 0.0:
		return 0.0
	var spent := minf(amount, mana)
	set_mana(mana - spent)
	return spent


func restore_mana(amount: float) -> float:
	if amount <= 0.0:
		return mana
	set_mana(mana + amount)
	return mana


func set_health(value: int) -> void:
	var next_health := clampi(value, 0, max_health)
	if health == next_health:
		return
	health = next_health
	if event_bus:
		event_bus.player_health_changed.emit(health, max_health)


func set_mana(value: float) -> void:
	var next_mana := clampf(value, 0.0, max_mana)
	if is_equal_approx(mana, next_mana):
		return
	mana = next_mana
	if event_bus and event_bus.has_signal("player_mana_changed"):
		event_bus.player_mana_changed.emit(mana, max_mana)


func set_external_move_vector(value: Vector2) -> void:
	external_move_vector = value.limit_length(1.0)


func get_move_input_vector() -> Vector2:
	var direction := external_move_vector
	if Input.is_action_pressed("move_up"):
		direction.y -= 1.0
	if Input.is_action_pressed("move_down"):
		direction.y += 1.0
	if Input.is_action_pressed("move_left"):
		direction.x -= 1.0
	if Input.is_action_pressed("move_right"):
		direction.x += 1.0
	return direction.limit_length(1.0)


func toggle_sneaking() -> bool:
	return set_sneaking(not is_sneaking)


func set_sneaking(value: bool) -> bool:
	is_sneaking = value
	if humanoid_avatar:
		humanoid_avatar.set_sneaking(is_sneaking)
	return is_sneaking


func _tick_footstep_noise(delta: float) -> void:
	footstep_cooldown -= delta
	if footstep_cooldown > 0.0:
		return
	footstep_cooldown = (
		SNEAK_FOOTSTEP_INTERVAL_SECONDS if is_sneaking else FOOTSTEP_INTERVAL_SECONDS
	)
	if not event_bus or not event_bus.has_signal("noise_emitted"):
		return
	event_bus.noise_emitted.emit(
		{
			"kind": "footstep",
			"source_id": "player",
			"world_position": [global_position.x, global_position.y],
			"world_layer": world_layer,
			"noise_radius": (
				SNEAK_FOOTSTEP_NOISE_RADIUS if is_sneaking else FOOTSTEP_NOISE_RADIUS
			),
			"loudness": "quiet" if is_sneaking else "normal",
			"visible": false,
			"target_sneaking": is_sneaking
		}
	)


func set_facing_direction(value: Vector2) -> void:
	if value.length() > 0.01:
		facing_direction = FacingBuckets.snap_direction(value, facing_direction)
		if humanoid_avatar:
			humanoid_avatar.set_facing_direction(facing_direction)


func get_facing_direction() -> Vector2:
	return facing_direction


func set_humanoid_profile(profile_data: Dictionary) -> void:
	humanoid_profile = HumanoidProfile.from_data(profile_data)
	_ensure_humanoid_avatar()
	humanoid_avatar.set_profile(humanoid_profile)


func set_equipped_items(equipped_by_slot: Dictionary, content: ContentDatabase = null) -> void:
	_ensure_humanoid_avatar()
	humanoid_avatar.set_equipped_items(equipped_by_slot, content)


func _can_stand_at(world_position: Vector2) -> bool:
	return WorldEntityMovement.can_stand_at(world_position, chunk_manager)


func _apply_query_layer() -> void:
	if chunk_manager and chunk_manager.has_method("set_layer"):
		chunk_manager.set_layer(world_layer)


func _post_blocked_message() -> void:
	if blocked_message_cooldown > 0.0:
		return
	blocked_message_cooldown = BLOCKED_MESSAGE_INTERVAL
	if event_bus:
		event_bus.post_message("The path is blocked.")


func _center_of_tile(tile: Vector2i) -> Vector2:
	return GridMath.tile_to_world(tile) + Vector2(GridMath.TILE_SIZE, GridMath.TILE_SIZE) * 0.5


func _ensure_humanoid_avatar() -> void:
	if humanoid_avatar:
		return
	humanoid_avatar = HumanoidAvatar2D.new()
	humanoid_avatar.name = "HumanoidAvatar2D"
	add_child(humanoid_avatar)
	humanoid_avatar.setup(humanoid_profile)
	humanoid_avatar.set_facing_direction(facing_direction)
