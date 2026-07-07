# gdlint:disable=max-public-methods
extends GutTest

const EntityManager = preload("res://scripts/managers/world/entity_manager.gd")
const ChunkManager = preload("res://scripts/managers/world/chunk_manager.gd")
const ContentDatabase = preload("res://scripts/data/content_database.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const WorldEntity = preload("res://scripts/world/world_entity.gd")


func _content() -> ContentDatabase:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	return content


func _chunks() -> ChunkManager:
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	return chunks


func _setup_unfiltered(
	manager: EntityManager,
	content: ContentDatabase,
	chunks: ChunkManager,
	conditions: ConditionEvaluator = null
) -> void:
	manager.setup(null, content, chunks, conditions)
	manager.spawn_all()


class ConditionStub extends ConditionEvaluator:
	var passed := false

	func evaluate_all(_conditions: Array) -> bool:
		return passed


func test_world_distance_interaction_finds_nearest_entity_inside_range() -> void:
	var content := _content()
	content.world_objects = [
		{"id": "near", "name": "Near", "kind": "readable", "global_tile": [1, 0]},
		{"id": "far", "name": "Far", "kind": "readable", "global_tile": [4, 0]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())

	var entity = manager.get_nearest_interactable_world(Vector2(30.0, 16.0), 42.0)

	assert_not_null(entity)
	assert_eq(entity.get_entity_id(), "near")


func test_world_tap_hit_test_uses_marker_distance_not_interaction_radius() -> void:
	var content := _content()
	content.world_objects = [
		{
			"id": "broad",
			"name": "Broad",
			"kind": "poi",
			"global_tile": [0, 0],
			"interaction_radius": 256
		},
		{"id": "tapped", "name": "Tapped", "kind": "pickup", "global_tile": [3, 0]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())

	var broad = manager.get_entity("broad")
	var tapped = manager.get_entity("tapped")
	var broad_reach_point: Vector2 = broad.global_position + Vector2(120.0, 0.0)

	assert_true(manager.get_interactables_world(broad_reach_point, 32.0).is_empty())
	assert_null(manager.get_interactable_at_world(broad_reach_point))
	assert_eq(manager.get_interactable_at_world(tapped.global_position).get_entity_id(), "tapped")
	assert_eq(manager.get_interactable_at_world(broad.global_position).get_entity_id(), "broad")


func test_world_tap_hit_test_includes_visible_action_hint() -> void:
	var content := _content()
	content.world_objects = [{"id": "npc", "name": "Guide", "kind": "npc", "global_tile": [2, 0]}]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())
	var entity = manager.get_entity("npc")
	var label_point: Vector2 = entity.global_position + Vector2(40.0, -35.0)

	assert_null(manager.get_interactable_at_world(label_point))

	manager.set_action_hints({"npc": {"text": "Talk Guide", "selected": true}})

	assert_true(entity.action_hint_visible)
	assert_eq(entity.action_hint_text, "Talk Guide")
	assert_true(entity.action_hint_selected)
	assert_eq(manager.get_interactable_at_world(label_point).get_entity_id(), "npc")

	manager.set_action_hints({})

	assert_false(entity.action_hint_visible)
	assert_null(manager.get_interactable_at_world(label_point))


func test_world_tap_hit_test_prioritizes_visible_action_hint_over_nearby_marker() -> void:
	var content := _content()
	content.world_objects = [
		{"id": "npc", "name": "Guide", "kind": "npc", "global_tile": [2, 2]},
		{"id": "marker", "name": "Marker", "kind": "readable", "global_tile": [2, 0]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())
	var entity = manager.get_entity("npc")
	var label_point: Vector2 = entity.global_position + Vector2(40.0, -35.0)

	manager.set_action_hints({"npc": {"text": "Talk Guide", "selected": true}})

	assert_eq(manager.get_interactable_at_world(label_point).get_entity_id(), "npc")


func test_world_tap_hit_test_prioritizes_selected_action_hint_when_labels_overlap() -> void:
	var content := _content()
	content.world_objects = [
		{"id": "unselected", "name": "Alpha", "kind": "readable", "global_tile": [2, 2]},
		{"id": "selected", "name": "Zulu", "kind": "npc", "global_tile": [2, 2]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())
	var selected = manager.get_entity("selected")
	var label_point: Vector2 = selected.global_position + Vector2(0.0, -35.0)

	manager.set_action_hints(
		{
			"unselected": {"text": "Read Alpha", "selected": false},
			"selected": {"text": "Talk Zulu", "selected": true}
		}
	)

	assert_eq(manager.get_interactable_at_world(label_point).get_entity_id(), "selected")
	assert_gt(selected.z_index, manager.get_entity("unselected").z_index)


func test_highlight_switches_between_entities() -> void:
	var content := _content()
	content.world_objects = [
		{"id": "first", "name": "First", "kind": "readable", "global_tile": [1, 0]},
		{"id": "second", "name": "Second", "kind": "readable", "global_tile": [2, 0]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())

	manager.set_highlighted_entity("first")
	manager.set_highlighted_entity("second")

	assert_false(manager.get_entity("first").highlighted)
	assert_true(manager.get_entity("second").highlighted)


func test_quest_markers_toggle_independently_from_action_hints() -> void:
	var content := _content()
	content.world_objects = [
		{"id": "quest_target", "name": "Quest Target", "kind": "pickup", "global_tile": [1, 0]},
		{"id": "plain", "name": "Plain", "kind": "npc", "global_tile": [2, 0]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())

	manager.set_action_hints({"quest_target": {"text": "Pick Up", "selected": true}})
	manager.set_quest_markers({"quest_target": {"text": "Quest"}})

	assert_true(manager.get_entity("quest_target").action_hint_visible)
	assert_true(manager.get_entity("quest_target").quest_marker_visible)
	assert_eq(manager.get_entity("quest_target").quest_marker_text, "Quest")
	assert_false(manager.get_entity("plain").quest_marker_visible)
	assert_eq(
		manager.get_interactable_at_world(
			manager.get_entity("quest_target").global_position + Vector2(0.0, -58.0), 4.0
		),
		manager.get_entity("quest_target")
	)

	manager.set_action_hints({})

	assert_false(manager.get_entity("quest_target").action_hint_visible)
	assert_true(manager.get_entity("quest_target").quest_marker_visible)
	assert_eq(
		manager.get_interactable_at_world(
			manager.get_entity("quest_target").global_position + Vector2(0.0, -36.0), 4.0
		),
		manager.get_entity("quest_target")
	)

	manager.set_quest_markers({})

	assert_false(manager.get_entity("quest_target").quest_marker_visible)


func test_world_distance_interaction_list_is_sorted_by_distance() -> void:
	var content := _content()
	content.world_objects = [
		{"id": "far", "name": "Far", "kind": "readable", "global_tile": [3, 0]},
		{"id": "near", "name": "Near", "kind": "readable", "global_tile": [1, 0]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())

	var interactables := manager.get_interactables_world(Vector2(8.0, 8.0), 48.0)
	var navigation := manager.get_navigation_summary(Vector2(8.0, 8.0), 48.0)

	assert_eq(interactables.size(), 2)
	assert_eq(interactables[0].get_entity_id(), "near")
	assert_eq(interactables[1].get_entity_id(), "far")
	assert_true(navigation.contains("E 1.0t Near"))
	assert_true(navigation.contains("E 3.0t Far"))
	assert_eq(manager.get_navigation_hint(Vector2(8.0, 8.0), interactables[0]), "E 1.0t")


func test_interaction_lists_use_stable_name_tie_breaks() -> void:
	var content := _content()
	content.world_objects = [
		{"id": "zeta", "name": "Zeta", "kind": "readable", "global_tile": [1, 0]},
		{"id": "alpha", "name": "Alpha", "kind": "pickup", "global_tile": [1, 0]},
		{"id": "beta", "name": "Beta", "kind": "npc", "global_tile": [-1, 0]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())

	var interactables := manager.get_interactables_world(Vector2(8.0, 8.0), 32.0)
	var nearest = manager.get_nearest_interactable_world(Vector2(8.0, 8.0), 32.0)
	var nearest_tile = manager.get_nearest_interactable(Vector2i.ZERO, 1)

	assert_eq(interactables.size(), 3)
	assert_eq(interactables[0].get_entity_id(), "alpha")
	assert_eq(interactables[1].get_entity_id(), "beta")
	assert_eq(interactables[2].get_entity_id(), "zeta")
	assert_eq(nearest.get_entity_id(), "alpha")
	assert_eq(nearest_tile.get_entity_id(), "alpha")


func test_world_distance_caps_authored_interaction_radius_to_requested_range() -> void:
	var content := _content()
	content.world_objects = [
		{
			"id": "extended",
			"name": "Extended",
			"kind": "container",
			"global_tile": [7, 0],
			"interaction_radius": 128
		},
		{"id": "default", "name": "Default", "kind": "container", "global_tile": [7, 1]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())

	var interactables := manager.get_interactables_world(Vector2(8.0, 8.0))

	assert_true(interactables.is_empty())
	interactables = manager.get_interactables_world(Vector2(8.0, 8.0), 128.0)
	assert_eq(interactables.size(), 2)
	assert_eq(interactables[0].get_entity_id(), "extended")
	assert_true(
		manager.get_navigation_summary(Vector2(8.0, 8.0), 128.0).contains("E 7.0t Extended")
	)


func test_hostile_npc_actors_are_combat_entities_not_interactables() -> void:
	var content := _content()
	content.world_objects = [
		{
			"id": "hostile_npc",
			"name": "Hostile NPC",
			"kind": "npc",
			"hostility": "hostile",
			"combat_enabled": true,
			"global_tile": [-1, 2]
		}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())

	var entity = manager.get_nearest_interactable_world(Vector2(8.0, 8.0), 42.0)
	var combat_entities := manager.get_entities_world(Vector2(8.0, 8.0), 42.0, "hostile")

	assert_null(entity)
	assert_eq(combat_entities.size(), 1)
	assert_eq(combat_entities[0].get_kind(), "npc")
	assert_true(combat_entities[0].is_combat_target())


func test_spawn_all_replaces_entities_immediately_and_clears_highlight() -> void:
	var content := _content()
	content.world_objects = [
		{"id": "first", "name": "First", "kind": "readable", "global_tile": [1, 0]},
		{"id": "second", "name": "Second", "kind": "pickup", "global_tile": [2, 0]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())
	manager.set_highlighted_entity("first")

	content.world_objects = [{"id": "third", "name": "Third", "kind": "npc", "global_tile": [3, 0]}]
	manager.spawn_all()

	assert_eq(manager.get_child_count(), 1)
	assert_null(manager.get_entity("first"))
	assert_null(manager.get_entity("second"))
	assert_not_null(manager.get_entity("third"))
	assert_eq(manager.highlighted_entity_id, "")


func test_remove_entity_immediately_removes_child_and_clears_highlight() -> void:
	var content := _content()
	content.world_objects = [
		{"id": "first", "name": "First", "kind": "readable", "global_tile": [1, 0]},
		{"id": "second", "name": "Second", "kind": "pickup", "global_tile": [2, 0]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())
	manager.set_highlighted_entity("first")

	manager.remove_entity("first")

	assert_eq(manager.get_child_count(), 1)
	assert_null(manager.get_entity("first"))
	assert_not_null(manager.get_entity("second"))
	assert_eq(manager.highlighted_entity_id, "")


func test_spawn_all_skips_blank_duplicate_and_malformed_entities() -> void:
	var content := _content()
	content.world_objects = [
		{"id": "", "name": "Blank", "kind": "readable", "global_tile": [0, 0]},
		{"id": "dup", "name": "First Duplicate", "kind": "readable", "global_tile": [1, 0]},
		{"id": "dup", "name": "Second Duplicate", "kind": "pickup", "global_tile": [2, 0]},
		{"id": "bad_tile", "name": "Bad Tile", "kind": "npc", "global_tile": "bad"},
		{"id": "text_tile", "name": "Text Tile", "kind": "npc", "global_tile": ["x", 0]},
		{"id": "valid", "name": "Valid", "kind": "rest", "global_tile": [3, 0]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())

	assert_eq(manager.get_child_count(), 2)
	assert_not_null(manager.get_entity("dup"))
	assert_eq(manager.get_entity("dup").get_display_name(), "First Duplicate")
	assert_not_null(manager.get_entity("valid"))
	assert_null(manager.get_entity(""))
	assert_null(manager.get_entity("bad_tile"))
	assert_null(manager.get_entity("text_tile"))


func test_world_entity_setup_uses_valid_tile_position() -> void:
	var entity := WorldEntity.new()
	add_child_autofree(entity)
	entity.setup({"id": "entity_valid", "name": "Valid", "kind": "npc", "global_tile": [2, -1]})

	assert_eq(entity.global_tile, Vector2i(2, -1))
	assert_eq(
		entity.position,
		GridMath.tile_to_world(Vector2i(2, -1)) + Vector2.ONE * GridMath.TILE_SIZE * 0.5
	)


func test_profile_backed_npc_gets_humanoid_avatar_and_stays_interactable() -> void:
	var content := _content()
	content.world_objects = [
		{
			"id": "npc_world",
			"name": "Harrow",
			"kind": "npc",
			"global_tile": [1, 0],
			"npc_id": "npc_harrow"
		}
	]
	content.npcs = {"npc_harrow": {"id": "npc_harrow", "character_profile_id": "char_harrow"}}
	content.character_profiles = {
		"char_harrow":
		{
			"character_id": "char_harrow",
			"people_id": "people_human",
			"state": "alive",
			"inventory_owner_id": "char_harrow",
			"equipment_owner_id": "char_harrow",
			"spellbook_owner_id": "char_harrow",
			"appearance": {"base_clothing_id": "clothing_smith_apron"}
		}
	}
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())

	var entity = manager.get_entity("npc_world")

	assert_not_null(entity)
	assert_not_null(entity.humanoid_avatar)
	assert_eq(entity.data["character_profile_id"], "char_harrow")
	assert_eq(
		manager.get_nearest_interactable_world(Vector2(8.0, 8.0), 32.0).get_entity_id(),
		"npc_world"
	)


func test_world_entity_setup_falls_back_for_malformed_tile() -> void:
	for tile_value in ["bad", [0], ["x", 0], [1, "y"]]:
		var entity := WorldEntity.new()
		add_child_autofree(entity)
		entity.setup({"id": "entity_bad", "name": "Bad", "kind": "npc", "global_tile": tile_value})

		assert_eq(entity.global_tile, Vector2i.ZERO)
		assert_eq(entity.position, Vector2.ONE * GridMath.TILE_SIZE * 0.5)


func test_location_markers_are_discoverable_but_not_interactable() -> void:
	var content := _content()
	content.world_objects = [
		{
			"id": "location_marker",
			"name": "Test Crossroads",
			"kind": "location",
			"global_tile": [0, 0],
			"location_id": "location_test"
		},
		{
			"id": "readable_marker",
			"name": "Readable Marker",
			"kind": "readable",
			"global_tile": [0, 0]
		}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	_setup_unfiltered(manager, content, _chunks())
	var spawn_world := (
		GridMath.tile_to_world(Vector2i.ZERO) + Vector2.ONE * GridMath.TILE_SIZE * 0.5
	)

	var interactables := manager.get_interactables_world(spawn_world)
	var locations := manager.get_entities_world(spawn_world, 42.0, "location")

	assert_eq(interactables.size(), 1)
	assert_eq(interactables[0].get_entity_id(), "readable_marker")
	assert_eq(locations.size(), 1)
	assert_eq(locations[0].get_entity_id(), "location_marker")


func test_chunk_window_filters_live_entities_after_streaming_updates() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var content := _content()
	content.world_objects = [
		{"id": "near", "name": "Near", "kind": "readable", "global_tile": [1, 0]},
		{"id": "far", "name": "Far", "kind": "npc", "global_tile": [40, 0]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	manager.setup(bus, content, _chunks())

	assert_eq(manager.get_child_count(), 0)

	bus.chunks_changed.emit([GridMath.chunk_key(Vector2i.ZERO)])

	assert_not_null(manager.get_entity("near"))
	assert_null(manager.get_entity("far"))

	bus.chunks_changed.emit([GridMath.chunk_key(Vector2i(2, 0))])

	assert_null(manager.get_entity("near"))
	assert_not_null(manager.get_entity("far"))


func test_chunk_window_respawn_preserves_removed_entity_state() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var chunks := _chunks()
	var content := _content()
	content.world_objects = [
		{"id": "pickup", "name": "Pickup", "kind": "pickup", "global_tile": [1, 0]}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	manager.setup(bus, content, chunks)
	bus.chunks_changed.emit([GridMath.chunk_key(Vector2i.ZERO)])

	assert_not_null(manager.get_entity("pickup"))
	manager.remove_entity("pickup")
	assert_null(manager.get_entity("pickup"))

	bus.chunks_changed.emit([GridMath.chunk_key(Vector2i(2, 0))])
	bus.chunks_changed.emit([GridMath.chunk_key(Vector2i.ZERO)])

	assert_null(manager.get_entity("pickup"))


func test_conditioned_entities_spawn_after_state_change_signal() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var conditions := ConditionStub.new()
	var content := _content()
	content.world_objects = [
		{
			"id": "conditional",
			"name": "Conditional",
			"kind": "container",
			"global_tile": [1, 0],
			"conditions": [{"type": "has_flag", "flag_id": "flag_ready"}]
		}
	]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	manager.setup(bus, content, _chunks(), conditions)
	bus.chunks_changed.emit([GridMath.chunk_key(Vector2i.ZERO)])

	assert_null(manager.get_entity("conditional"))

	conditions.passed = true
	bus.world_flag_changed.emit("flag_ready", true)
	await wait_process_frames(1)

	assert_not_null(manager.get_entity("conditional"))

