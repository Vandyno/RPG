extends GutTest

const EntityManager = preload("res://scripts/managers/entity_manager.gd")
const ChunkManager = preload("res://scripts/managers/chunk_manager.gd")
const ContentDatabase = preload("res://scripts/data/content_database.gd")


func test_marker_tap_uses_world_entity_minimum_assist_radius() -> void:
	var manager := _manager_with_objects(
		[{"id": "pickup", "name": "Pickup", "kind": "pickup", "global_tile": [2, 0]}]
	)
	var pickup = manager.get_entity("pickup")
	var assisted_point: Vector2 = pickup.global_position + Vector2(39.0, 0.0)
	var missed_point: Vector2 = pickup.global_position + Vector2(41.0, 0.0)

	assert_eq(manager.get_interactable_at_world(assisted_point, 28.0).get_entity_id(), "pickup")
	assert_null(manager.get_interactable_at_world(missed_point, 28.0))


func test_large_markers_get_extra_touch_assist_without_using_interaction_radius() -> void:
	var manager := _manager_with_objects(
		[
			{
				"id": "square",
				"name": "Square",
				"kind": "poi",
				"global_tile": [2, 0],
				"interaction_radius": 128
			}
		]
	)
	var square = manager.get_entity("square")
	var assisted_point: Vector2 = square.global_position + Vector2(45.0, 0.0)
	var broad_reach_point: Vector2 = square.global_position + Vector2(90.0, 0.0)

	assert_eq(manager.get_interactable_at_world(assisted_point, 28.0).get_entity_id(), "square")
	assert_null(manager.get_interactable_at_world(broad_reach_point, 28.0))


func _manager_with_objects(world_objects: Array[Dictionary]) -> EntityManager:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.world_objects = world_objects
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	var manager := EntityManager.new()
	add_child_autofree(manager)
	manager.setup(null, content, chunks)
	return manager
