extends GutTest

const GridMath = preload("res://scripts/core/grid_math.gd")
const WorldEntityMovement = preload("res://scripts/world/world_entity_movement.gd")


class EntityStub:
	extends RefCounted

	var position := Vector2.ZERO
	var world_positions: Array[Vector2] = []
	var facing_values: Array[Vector2] = []
	var locomotion_values: Array[Dictionary] = []

	func set_world_position(world_position: Vector2) -> void:
		position = world_position
		world_positions.append(world_position)

	func set_facing_direction(direction: Vector2) -> void:
		facing_values.append(direction)

	func set_locomotion(is_moving: bool, delta: float) -> void:
		locomotion_values.append({"moving": is_moving, "delta": delta})


class ChunkStub:
	extends RefCounted

	var blocked := {}
	var checked_tiles: Array[Vector2i] = []

	func is_walkable(tile: Vector2i) -> bool:
		checked_tiles.append(tile)
		return not blocked.has("%s,%s" % [tile.x, tile.y])


class LayeredEntityStub:
	extends EntityStub

	var world_layer := "interior:structure_test"

	func get_world_layer() -> String:
		return world_layer


class LayerQueryStub:
	extends RefCounted

	var checked_layers: Array[String] = []

	func can_stand_at(_world_position: Vector2, layer: String) -> bool:
		checked_layers.append(layer)
		return layer.begins_with("interior:")


func test_try_move_rejects_zero_or_invalid_motion_and_stops_locomotion() -> void:
	var entity := EntityStub.new()

	assert_false(WorldEntityMovement.try_move(entity, Vector2.ZERO, 1.0))
	assert_false(WorldEntityMovement.try_move(entity, Vector2.RIGHT, 0.0))
	assert_false(WorldEntityMovement.try_move(entity, Vector2.RIGHT, 1.0, null, 0.0))

	assert_true(entity.facing_values.is_empty())
	assert_eq(entity.world_positions, [])
	assert_eq(
		entity.locomotion_values,
		[
			{"moving": false, "delta": 1.0},
			{"moving": false, "delta": 0.0},
			{"moving": false, "delta": 1.0}
		]
	)


func test_try_move_normalizes_direction_splits_steps_and_sets_locomotion() -> void:
	var entity := EntityStub.new()

	assert_true(WorldEntityMovement.try_move(entity, Vector2.RIGHT * 5.0, 1.0, null, 20.0))

	assert_eq(entity.facing_values, [Vector2.RIGHT])
	assert_eq(entity.world_positions, [Vector2(8, 0), Vector2(16, 0), Vector2(20, 0)])
	assert_eq(entity.locomotion_values, [{"moving": true, "delta": 1.0}])


func test_try_move_step_slides_horizontally_when_diagonal_target_is_blocked() -> void:
	var entity := EntityStub.new()
	entity.position = _tile_center(Vector2i(0, 0))
	var chunk := ChunkStub.new()
	chunk.blocked = {"2,2": true}

	assert_true(WorldEntityMovement._try_move_step(entity, Vector2(32, 32), chunk))

	assert_eq(entity.position, _tile_center(Vector2i(2, 0)))
	assert_eq(entity.world_positions, [_tile_center(Vector2i(2, 0))])


func test_try_move_step_returns_false_when_full_and_axis_steps_are_blocked() -> void:
	var entity := EntityStub.new()
	entity.position = _tile_center(Vector2i(0, 0))
	var chunk := ChunkStub.new()
	chunk.blocked = {"2,2": true, "2,0": true, "0,2": true}

	assert_false(WorldEntityMovement._try_move_step(entity, Vector2(32, 32), chunk))
	assert_eq(entity.world_positions, [])


func test_try_move_step_uses_the_entity_world_layer_for_collision() -> void:
	var entity := LayeredEntityStub.new()
	var query := LayerQueryStub.new()

	assert_true(WorldEntityMovement._try_move_step(entity, Vector2.RIGHT * 4.0, query))
	assert_eq(query.checked_layers, ["interior:structure_test"])


func test_can_stand_at_samples_collision_radius_against_chunk_walkability() -> void:
	var open_chunk := ChunkStub.new()
	var blocked_chunk := ChunkStub.new()
	blocked_chunk.blocked = {"0,0": true}

	assert_true(WorldEntityMovement.can_stand_at(Vector2.ZERO))
	assert_true(WorldEntityMovement.can_stand_at(_tile_center(Vector2i(0, 0)), open_chunk))
	assert_eq(open_chunk.checked_tiles.size(), 9)
	assert_false(WorldEntityMovement.can_stand_at(_tile_center(Vector2i(0, 0)), blocked_chunk))


func _tile_center(tile: Vector2i) -> Vector2:
	return GridMath.tile_to_world(tile) + Vector2(GridMath.TILE_SIZE, GridMath.TILE_SIZE) * 0.5
