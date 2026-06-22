extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_container_open_conditions_gate_loot_until_unlocked() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "object_sealed_strongbox")
	assert_eq(main.get_debug_state()["target_detail"], "Container: locked")
	assert_eq(main.get_debug_state()["primary_action"], "Locked")
	main._handle_interact_requested()
	assert_eq(main.inventory.get_count("item_gold_coin"), 0)
	assert_false(main.chunks.is_object_opened("object_sealed_strongbox", Vector2i(7, 0)))
	assert_true(main.hud.log_label.text.contains("strongbox seal matches"))

	_select_entity(main, "object_road_notice")
	main._handle_interact_requested()
	main.hud.hide_content_card()
	_select_entity(main, "object_sealed_strongbox")
	assert_eq(main.get_debug_state()["target_detail"], "Container: closed")
	assert_eq(main.get_debug_state()["primary_action"], "Open")
	main._handle_interact_requested()

	assert_eq(main.inventory.get_count("item_gold_coin"), 4)
	assert_true(main.chunks.is_object_opened("object_sealed_strongbox", Vector2i(7, 0)))
	assert_eq(main.get_debug_state()["target_detail"], "Container: opened")
	assert_eq(main.get_debug_state()["primary_action"], "Opened")


func _select_entity(main, entity_id: String) -> void:
	for _i in range(24):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)
