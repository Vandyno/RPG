extends GutTest

const Main = preload("res://scripts/main/main.gd")
const TEST_SAVE_PATH := "user://test_equipment_main_flow.json"


func before_each() -> void:
	_remove_test_save()


func after_each() -> void:
	_remove_test_save()


func test_main_save_load_preserves_equipment() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.save_manager.save_path = TEST_SAVE_PATH

	_select_entity(main, "pickup_road_hatchet")
	main._handle_interact_requested()
	_select_entity(main, "pickup_traveler_buckler")
	main._handle_interact_requested()
	assert_true(main.equipment.equip_item("item_road_hatchet"))
	assert_true(main.equipment.equip_item("item_traveler_buckler"))

	assert_true(main.save_manager.save_game())

	main.equipment.unequip_slot("weapon")
	main.equipment.unequip_slot("offhand")
	assert_true(main.save_manager.load_game())

	assert_eq(main.equipment.get_equipped_item("weapon"), "item_road_hatchet")
	assert_eq(main.equipment.get_equipped_item("offhand"), "item_traveler_buckler")
	assert_true(main.get_debug_state()["equipment"].contains("Road Hatchet"))


func _select_entity(main, entity_id: String) -> void:
	var target = main.entities.get_entity(entity_id)
	if target:
		main.player.set_world_position(target.global_position + Vector2(-8.0, 0.0))
		main.player.set_facing_direction(Vector2.RIGHT)
		main._update_nearby()
	for _i in range(16):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
