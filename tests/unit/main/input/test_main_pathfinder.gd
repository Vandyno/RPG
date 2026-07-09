extends GutTest

const GridMath = preload("res://scripts/core/grid_math.gd")
const MainPathfinder = preload("res://scripts/main/input/main_pathfinder.gd")
const PlayerController = preload("res://scripts/player/player_controller.gd")


class BlockingChunks:
	var blocked_tiles: Dictionary = {}

	func block(tile: Vector2i) -> void:
		blocked_tiles["%d:%d" % [tile.x, tile.y]] = true

	func is_walkable(tile: Vector2i) -> bool:
		return not blocked_tiles.has("%d:%d" % [tile.x, tile.y])


func test_pathfinder_routes_smooth_waypoints_around_blocked_tiles() -> void:
	var chunks := BlockingChunks.new()
	chunks.block(Vector2i(2, 0))
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, chunks, Vector2i.ZERO)
	var destination := GridMath.tile_to_world(Vector2i(4, 0)) + Vector2(8.0, 8.0)

	var path := MainPathfinder.path_to(
		Callable(player, "_can_stand_at"), player.global_position, destination
	)

	assert_false(path.is_empty())
	assert_eq(path[path.size() - 1], destination)
	for point in path:
		assert_true(player._can_stand_at(point))
	assert_gt(path[0].y, player.global_position.y)


func test_pathfinder_rejects_blocked_destination() -> void:
	var chunks := BlockingChunks.new()
	chunks.block(Vector2i(4, 0))
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, chunks, Vector2i.ZERO)
	var destination := GridMath.tile_to_world(Vector2i(4, 0)) + Vector2(8.0, 8.0)

	assert_true(
		MainPathfinder.path_to(Callable(player, "_can_stand_at"), player.global_position, destination)
		.is_empty()
	)


func test_pathfinder_can_approach_blocked_target_within_interaction_range() -> void:
	var chunks := BlockingChunks.new()
	chunks.block(Vector2i(4, 0))
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, chunks, Vector2i.ZERO)
	var target := GridMath.tile_to_world(Vector2i(4, 0)) + Vector2(8.0, 8.0)

	var path := MainPathfinder.approach_path_to(
		Callable(player, "_can_stand_at"), player.global_position, target, 72.0
	)

	assert_false(path.is_empty())
	assert_lte(path[path.size() - 1].distance_to(target), 72.0)
	for point in path:
		assert_true(player._can_stand_at(point))
