class_name MainPathfinder
extends RefCounted

const WorldPathfinder = preload("res://scripts/world/world_pathfinder.gd")


static func path_to(
	can_stand_at: Callable, from_world: Vector2, to_world: Vector2
) -> Array[Vector2]:
	if not can_stand_at.is_valid():
		return []
	return WorldPathfinder.path_to(can_stand_at, from_world, to_world)


static func approach_path_to(
	can_stand_at: Callable, from_world: Vector2, target_world: Vector2, stop_distance: float
) -> Array[Vector2]:
	if not can_stand_at.is_valid() or stop_distance <= 0.0:
		return []
	return WorldPathfinder.approach_path_to(can_stand_at, from_world, target_world, stop_distance)
