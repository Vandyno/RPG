extends GutTest

const EntityManager = preload("res://scripts/managers/world/entity_manager.gd")
const ChunkManager = preload("res://scripts/managers/world/chunk_manager.gd")
const ContentDatabase = preload("res://scripts/data/content_database.gd")


func test_world_tap_hit_test_uses_action_hint_offset() -> void:
	var manager := _manager_with_npc()
	var entity = manager.get_entity("npc")
	var base_label_point: Vector2 = entity.global_position + Vector2(40.0, -35.0)
	var shifted_label_point: Vector2 = entity.global_position + Vector2(40.0, -22.0)

	manager.set_action_hints({"npc": {"text": "Talk Guide", "selected": false, "offset_y": 12.0}})

	assert_true(entity.action_hint_visible)
	assert_eq(entity.action_hint_offset_y, 12.0)
	assert_null(manager.get_interactable_at_world(base_label_point))
	assert_eq(manager.get_interactable_at_world(shifted_label_point).get_entity_id(), "npc")


func test_selected_action_hint_ignores_offset_to_keep_target_stable() -> void:
	var manager := _manager_with_npc()
	var entity = manager.get_entity("npc")
	var selected_label_point: Vector2 = entity.global_position + Vector2(40.0, -35.0)

	manager.set_action_hints({"npc": {"text": "Talk Guide", "selected": true, "offset_y": 12.0}})

	assert_true(entity.action_hint_selected)
	assert_eq(entity.action_hint_offset_y, 0.0)
	assert_eq(manager.get_interactable_at_world(selected_label_point).get_entity_id(), "npc")


func _manager_with_npc() -> EntityManager:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.world_objects = [{"id": "npc", "name": "Guide", "kind": "npc", "global_tile": [2, 0]}]
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	var manager := EntityManager.new()
	add_child_autofree(manager)
	manager.setup(null, content, chunks)
	manager.spawn_all()
	return manager
