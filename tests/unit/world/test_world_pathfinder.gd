extends GutTest

const GridMath = preload("res://scripts/core/grid_math.gd")
const WorldPathfinder = preload("res://scripts/world/world_pathfinder.gd")

var blocked_tiles: Dictionary = {}


func test_path_to_returns_direct_goal_when_segment_is_clear() -> void:
	var start := _center(Vector2i(0, 0))
	var goal := _center(Vector2i(3, 0))

	var path := WorldPathfinder.path_to(_query({}), start, goal)

	assert_eq(path, [goal])


func test_path_to_rejects_blocked_destination() -> void:
	var start := _center(Vector2i(0, 0))
	var goal_tile := Vector2i(2, 0)

	var path := WorldPathfinder.path_to(_query({_key(goal_tile): true}), start, _center(goal_tile))

	assert_eq(path, [])


func test_path_to_routes_around_blocked_segment() -> void:
	var start := _center(Vector2i(0, 0))
	var goal := _center(Vector2i(2, 0))

	var path := WorldPathfinder.path_to(_query({_key(Vector2i(1, 0)): true}), start, goal)

	assert_gt(path.size(), 1)
	assert_eq(path[path.size() - 1], goal)
	for point in path:
		assert_true(_can_stand_at(point))


func test_path_to_returns_empty_when_goal_is_unreachable() -> void:
	var wall := {}
	for y in range(-WorldPathfinder.MAX_SEARCH_RADIUS, WorldPathfinder.MAX_SEARCH_RADIUS + 1):
		wall[_key(Vector2i(1, y))] = true

	var path := WorldPathfinder.path_to(
		_query(wall),
		_center(Vector2i(0, 0)),
		_center(Vector2i(2, 0))
	)

	assert_eq(path, [])


func test_approach_path_returns_current_position_when_already_in_range() -> void:
	var start := _center(Vector2i(0, 0))
	var target := _center(Vector2i(1, 0))

	var path := WorldPathfinder.approach_path_to(_query({}), start, target, 24.0)

	assert_eq(path, [start])


func test_approach_path_stops_near_blocked_target() -> void:
	var start := _center(Vector2i(0, 0))
	var target_tile := Vector2i(3, 0)
	var target := _center(target_tile)

	var path := WorldPathfinder.approach_path_to(
		_query({_key(target_tile): true}),
		start,
		target,
		24.0
	)

	assert_false(path.is_empty())
	assert_ne(path[path.size() - 1], target)
	assert_lte(path[path.size() - 1].distance_to(target), 24.0)


func _query(blocked: Dictionary) -> Dictionary:
	blocked_tiles = blocked
	return {"can_stand_at": Callable(self, "_can_stand_at")}


func _can_stand_at(world_position: Vector2) -> bool:
	return not blocked_tiles.has(_key(GridMath.world_to_tile(world_position)))


func _center(tile: Vector2i) -> Vector2:
	return GridMath.tile_to_world(tile) + Vector2(GridMath.TILE_SIZE, GridMath.TILE_SIZE) * 0.5


func _key(tile: Vector2i) -> String:
	return "%d:%d" % [tile.x, tile.y]
