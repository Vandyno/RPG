class_name MainPathfinder
extends RefCounted

const WorldPathfinder = preload("res://scripts/core/world_pathfinder.gd")


static func path_to(main, from_world: Vector2, to_world: Vector2) -> Array[Vector2]:
	if not main or not main.player:
		return []
	return WorldPathfinder.path_to(_path_query(main), from_world, to_world)


static func approach_path_to(
	main, from_world: Vector2, target_world: Vector2, stop_distance: float
) -> Array[Vector2]:
	if not main or not main.player or stop_distance <= 0.0:
		return []
	return WorldPathfinder.approach_path_to(
		_path_query(main), from_world, target_world, stop_distance
	)


static func _path_query(main) -> Dictionary:
	return {"can_stand_at": Callable(main.player, "_can_stand_at")}
