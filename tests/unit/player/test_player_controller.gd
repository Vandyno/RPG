extends GutTest

const PlayerController = preload("res://scripts/player/player_controller.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")
const FacingBuckets = preload("res://scripts/core/facing_buckets.gd")


class BlockingChunks:
	var blocked_tiles: Dictionary = {}

	func block(tile: Vector2i) -> void:
		blocked_tiles["%d:%d" % [tile.x, tile.y]] = true

	func is_walkable(tile: Vector2i) -> bool:
		return not blocked_tiles.has("%d:%d" % [tile.x, tile.y])


func test_world_position_can_move_inside_tile_without_snapping() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i.ZERO)

	player.set_world_position(Vector2(12.0, 12.0))

	assert_eq(player.position, Vector2(12.0, 12.0))
	assert_eq(player.global_tile, Vector2i(0, 0))


func test_global_tile_updates_when_world_position_crosses_tile_boundary() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i.ZERO)

	player.set_world_position(Vector2(40.0, 70.0))

	assert_eq(player.position, Vector2(40.0, 70.0))
	assert_eq(player.global_tile, Vector2i(2, 4))


func test_try_move_uses_continuous_motion() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i.ZERO)

	player.try_move(Vector2.RIGHT, 0.1)

	assert_almost_eq(player.position.x, 30.0, 0.001)
	assert_eq(player.position.y, 8.0)
	assert_eq(player.global_tile, Vector2i(1, 0))
	assert_eq(player.get_facing_direction(), Vector2.RIGHT)


func test_toggle_sneaking_flips_state() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i.ZERO)

	assert_false(player.is_sneaking)
	assert_true(player.toggle_sneaking())
	assert_true(player.is_sneaking)
	assert_true(player.humanoid_avatar.is_sneaking)
	assert_false(player.toggle_sneaking())
	assert_false(player.is_sneaking)


func test_sneak_movement_is_slower_than_walk() -> void:
	var walking := PlayerController.new()
	add_child_autofree(walking)
	walking.setup(null, null, Vector2i.ZERO)

	var sneaking := PlayerController.new()
	add_child_autofree(sneaking)
	sneaking.setup(null, null, Vector2i.ZERO)
	sneaking.set_sneaking(true)

	walking.try_move(Vector2.RIGHT, 0.1)
	sneaking.try_move(Vector2.RIGHT, 0.1)

	assert_gt(walking.position.x, sneaking.position.x)
	assert_almost_eq(sneaking.position.x, 17.9, 0.001)


func test_facing_direction_can_be_set_without_moving() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i.ZERO)

	player.set_facing_direction(Vector2.LEFT)
	player.set_facing_direction(Vector2.ZERO)

	assert_lt(player.get_facing_direction().distance_to(Vector2.LEFT), 0.001)


func test_facing_direction_snaps_to_visual_bucket_without_snapping_movement() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i.ZERO)
	var raw_direction := Vector2(1.0, 0.31)
	var snapped := FacingBuckets.snap_direction(raw_direction)

	player.try_move(raw_direction, 0.1)

	assert_eq(player.get_facing_direction(), snapped)
	assert_eq(player.humanoid_avatar.facing_direction, snapped)
	assert_gt(player.position.x, 8.0)
	assert_gt(player.position.y, 8.0)


func test_external_move_vector_drives_continuous_motion() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i.ZERO)

	player.set_external_move_vector(Vector2.RIGHT)

	assert_eq(player.get_move_input_vector(), Vector2.RIGHT)
	player._process(0.1)

	assert_almost_eq(player.position.x, 30.0, 0.001)
	assert_eq(player.position.y, 8.0)


func test_external_move_vector_is_clamped() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i.ZERO)

	player.set_external_move_vector(Vector2(3.0, 4.0))

	assert_almost_eq(player.external_move_vector.length(), 1.0, 0.001)


func test_blocked_motion_stops_before_radius_hits_blocked_tile() -> void:
	var chunks := BlockingChunks.new()
	chunks.block(Vector2i(2, 0))
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, chunks, Vector2i.ZERO)

	player.try_move(Vector2.RIGHT, 0.1)

	assert_eq(player.position, Vector2(16.0, 8.0))
	assert_eq(player.global_tile, Vector2i(1, 0))
	assert_lte(
		player.position.x + PlayerController.COLLISION_RADIUS,
		GridMath.tile_to_world(Vector2i(2, 0)).x
	)


func test_large_motion_does_not_tunnel_through_blocked_tile() -> void:
	var chunks := BlockingChunks.new()
	chunks.block(Vector2i(2, 0))
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, chunks, Vector2i.ZERO)

	player.try_move(Vector2.RIGHT, 1.0)

	assert_eq(player.position, Vector2(16.0, 8.0))
	assert_eq(player.global_tile, Vector2i(1, 0))


func test_diagonal_blocked_motion_slides_along_open_axis() -> void:
	var chunks := BlockingChunks.new()
	chunks.block(Vector2i(2, 0))
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, chunks, Vector2i.ZERO)

	player.try_move(Vector2(1.0, 1.0), 0.1)

	assert_gt(player.position.x, 8.0)
	assert_gt(player.position.y, 8.0)
	assert_lte(
		player.position.x + PlayerController.COLLISION_RADIUS,
		GridMath.tile_to_world(Vector2i(2, 0)).x
	)


func test_player_body_is_larger_than_a_world_tile() -> void:
	assert_gt(PlayerController.COLLISION_RADIUS * 2.0, float(GridMath.TILE_SIZE))


func test_player_health_damage_heal_and_save_load() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i.ZERO)

	player.apply_damage(35)
	assert_eq(player.health, 65)
	player.heal(10)
	assert_eq(player.health, 75)
	player.spend_mana(12.5)
	assert_almost_eq(player.mana, 87.5, 0.001)

	var loaded := PlayerController.new()
	add_child_autofree(loaded)
	loaded.setup(null, null, Vector2i.ZERO)
	loaded.load_save_data(player.get_save_data())

	assert_eq(loaded.health, 75)
	assert_eq(loaded.max_health, 100)
	assert_almost_eq(loaded.mana, 87.5, 0.001)
	assert_almost_eq(loaded.max_mana, 100.0, 0.001)


func test_save_load_preserves_humanoid_appearance_profile() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i.ZERO)
	player.set_humanoid_profile(
		{
			"character_id": "char_player",
			"people_id": "people_mirefolk",
			"appearance": {
				"eye_id": "eyes_mirefolk_narrow",
				"mouth_id": "mouth_mirefolk_short",
				"visual_model_id": "people_mirefolk_default"
			}
		}
	)

	var loaded := PlayerController.new()
	add_child_autofree(loaded)
	loaded.setup(null, null, Vector2i.ZERO)
	loaded.load_save_data(player.get_save_data())

	assert_eq(loaded.humanoid_profile["people_id"], "people_mirefolk")
	assert_eq(loaded.humanoid_profile["appearance"]["eye_id"], "eyes_mirefolk_narrow")
	assert_eq(loaded.humanoid_profile["appearance"]["mouth_id"], "mouth_mirefolk_short")


func test_load_malformed_world_position_falls_back_to_global_tile() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i.ZERO)

	player.load_save_data({"world_position": ["bad", 0], "global_tile": [3, -2], "health": 40})

	assert_eq(player.global_tile, Vector2i(3, -2))
	assert_eq(player.position, GridMath.tile_to_world(Vector2i(3, -2)) + Vector2(8.0, 8.0))
	assert_eq(player.health, 40)


func test_load_malformed_position_and_tile_falls_back_to_spawn() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i(5, 5))

	player.load_save_data({"world_position": "bad", "global_tile": ["also bad", 2], "health": 33})

	assert_eq(player.global_tile, Vector2i.ZERO)
	assert_eq(player.position, Vector2(8.0, 8.0))
	assert_eq(player.health, 33)


func test_load_blocked_world_position_falls_back_to_valid_global_tile() -> void:
	var chunks := BlockingChunks.new()
	chunks.block(Vector2i(5, 0))
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, chunks, Vector2i.ZERO)

	player.load_save_data({"world_position": [88.0, 8.0], "global_tile": [3, 0], "health": 44})

	assert_eq(player.global_tile, Vector2i(3, 0))
	assert_eq(player.position, GridMath.tile_to_world(Vector2i(3, 0)) + Vector2(8.0, 8.0))
	assert_eq(player.health, 44)


func test_load_blocked_position_and_tile_falls_back_to_spawn() -> void:
	var chunks := BlockingChunks.new()
	chunks.block(Vector2i(5, 0))
	chunks.block(Vector2i(6, 0))
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, chunks, Vector2i(3, 0))

	player.load_save_data({"world_position": [88.0, 8.0], "global_tile": [6, 0], "health": 22})

	assert_eq(player.global_tile, Vector2i.ZERO)
	assert_eq(player.position, Vector2(8.0, 8.0))
	assert_eq(player.health, 22)
