extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_next_target_uses_facing_rank_in_crowded_spawn() -> void:
	var main := Main.new()
	add_child_autofree(main)

	main.player.set_facing_direction(Vector2.RIGHT)
	assert_eq(main._get_nearby_entity().get_entity_id(), "npc_harrow_venn_world")

	main._handle_cycle_target_requested()

	assert_eq(main.selected_target_id, "object_sealed_strongbox")
	assert_true(main.manual_target_locked)
	assert_true(main.hud.log_label.text.contains("Targeting Sealed Strongbox."))


func test_next_target_can_cycle_through_every_nearby_spawn_target() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var expected_ids := {}
	for entity in main._get_nearby_entities():
		expected_ids[entity.get_entity_id()] = true

	var visited_ids := {}
	for _i in range(expected_ids.size() + 1):
		var entity = main._get_nearby_entity()
		assert_not_null(entity)
		visited_ids[entity.get_entity_id()] = true
		main._handle_cycle_target_requested()

	for entity_id in expected_ids:
		assert_true(visited_ids.has(entity_id), "Cycle missed %s" % entity_id)


func test_target_picker_data_uses_same_intent_rank_as_next_target() -> void:
	var main := Main.new()
	add_child_autofree(main)

	main.player.set_facing_direction(Vector2.RIGHT)
	var targets: Array = main.get_debug_state()["nearby_targets"]

	assert_gt(targets.size(), 2)
	assert_eq(targets[0]["id"], "npc_harrow_venn_world")
	assert_eq(targets[1]["id"], "object_sealed_strongbox")
	assert_true(bool(targets[0]["selected"]))
