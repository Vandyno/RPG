class_name WorldEntityMovement
extends RefCounted

const GridMath = preload("res://scripts/core/grid_math.gd")

const COLLISION_RADIUS := 10.0
const MAX_COLLISION_STEP := 8.0
const MAX_MOVE_STEPS_PER_CALL := 16


static func try_move(
	entity,
	direction: Vector2,
	delta: float = 1.0,
	chunk_manager = null,
	speed_pixels_per_second: float = 80.0
) -> bool:
	var normalized_direction := direction.normalized()
	if normalized_direction == Vector2.ZERO or delta <= 0.0 or speed_pixels_per_second <= 0.0:
		entity.set_locomotion(false, delta)
		return false
	entity.set_facing_direction(normalized_direction)
	var remaining_distance := speed_pixels_per_second * delta
	var moved := false
	var step_count := 0
	while remaining_distance > 0.0 and step_count < MAX_MOVE_STEPS_PER_CALL:
		var step_distance := minf(remaining_distance, MAX_COLLISION_STEP)
		var motion := normalized_direction * step_distance
		if not _try_move_step(entity, motion, chunk_manager):
			break
		moved = true
		remaining_distance -= step_distance
		step_count += 1
	entity.set_locomotion(moved, delta)
	return moved


static func _try_move_step(entity, motion: Vector2, chunk_manager = null) -> bool:
	var next_position: Vector2 = entity.position + motion
	var layer := "surface"
	if entity and entity.has_method("get_world_layer"):
		layer = String(entity.get_world_layer())
	elif entity and entity.has_method("get_entity_id") and entity.data is Dictionary:
		layer = String(entity.data.get("world_layer", "surface"))
	if can_stand_at(next_position, chunk_manager, layer):
		entity.set_world_position(next_position)
		return true

	var horizontal_position: Vector2 = entity.position + Vector2(motion.x, 0.0)
	if not is_zero_approx(motion.x) and can_stand_at(horizontal_position, chunk_manager, layer):
		entity.set_world_position(horizontal_position)
		return true

	var vertical_position: Vector2 = entity.position + Vector2(0.0, motion.y)
	if not is_zero_approx(motion.y) and can_stand_at(vertical_position, chunk_manager, layer):
		entity.set_world_position(vertical_position)
		return true

	return false


static func can_stand_at(world_position: Vector2, chunk_manager = null, layer: String = "surface") -> bool:
	if not chunk_manager:
		return true
	if chunk_manager.has_method("can_stand_at"):
		return bool(chunk_manager.can_stand_at(world_position, layer))
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
		if chunk_manager.has_method("is_walkable_for_layer"):
			if not chunk_manager.is_walkable_for_layer(sampled_tile, layer):
				return false
		elif chunk_manager.has_method("is_walkable") and not chunk_manager.is_walkable(sampled_tile):
			return false
	return true
