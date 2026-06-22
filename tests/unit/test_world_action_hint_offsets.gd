extends GutTest

const EntityManager = preload("res://scripts/managers/entity_manager.gd")


class ContentStub:
	var world_objects: Array[Dictionary] = []


class ChunkStub:
	func is_entity_removed(_entity_id: String, _tile: Vector2i) -> bool:
		return false

	func mark_entity_removed(_entity_id: String, _tile: Vector2i) -> void:
		pass


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
	var content := ContentStub.new()
	content.world_objects = [{"id": "npc", "name": "Guide", "kind": "npc", "global_tile": [2, 0]}]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	manager.setup(null, content, ChunkStub.new())
	return manager
