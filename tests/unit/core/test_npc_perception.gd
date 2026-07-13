extends GutTest

const NpcPerception = preload("res://scripts/core/npc_perception.gd")
const WorldEntity = preload("res://scripts/world/world_entity.gd")


class QueryStub:
	var blocked: Dictionary = {}

	func is_walkable(tile: Vector2i, _layer: String) -> bool:
		return not blocked.has(tile)


func test_vision_uses_distance_cone_layer_and_wall_occlusion() -> void:
	var observer := _observer()
	var query := QueryStub.new()

	assert_true(NpcPerception.can_see_position(observer, Vector2(96, 16), "surface", query))
	assert_false(NpcPerception.can_see_position(observer, Vector2(-64, 16), "surface", query))
	assert_false(NpcPerception.can_see_position(observer, Vector2(240, 16), "surface", query))
	assert_false(NpcPerception.can_see_position(observer, Vector2(96, 16), "interior:test", query))

	query.blocked[Vector2i(1, 0)] = true
	assert_false(NpcPerception.can_see_position(observer, Vector2(96, 16), "surface", query))


func test_sneaking_and_darkness_reduce_effective_vision_distance() -> void:
	var observer := _observer()
	var target := Vector2(112, 16)

	assert_true(NpcPerception.can_see_position(observer, target, "surface"))
	assert_false(
		NpcPerception.can_see_position(
			observer, target, "surface", null, {"target_sneaking": true, "light_level": 0.35}
		)
	)


func test_hearing_uses_observer_radius_event_loudness_and_wall_reduction() -> void:
	var observer := _observer()
	var query := QueryStub.new()
	var origin := Vector2(112, 16)

	assert_true(NpcPerception.can_hear(observer, origin, "surface", 120.0, query))
	assert_false(
		NpcPerception.can_hear(observer, origin, "surface", 120.0, query, {"loudness": 0.4})
	)
	query.blocked[Vector2i(1, 0)] = true
	assert_false(NpcPerception.can_hear(observer, origin, "surface", 120.0, query))
	assert_true(
		NpcPerception.can_hear(observer, origin, "surface", 240.0, query, {"loudness": 2.0})
	)


func _observer() -> WorldEntity:
	var observer := WorldEntity.new()
	add_child_autofree(observer)
	observer.setup(
		{
			"id": "observer",
			"npc_id": "observer",
			"kind": "npc",
			"global_tile": [0, 0],
			"facing_direction": [1, 0],
			"vision_distance": 192,
			"vision_degrees": 90,
			"hearing_radius": 144
		}
	)
	return observer
