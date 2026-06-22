extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_container_world_hint_updates_after_opening() -> void:
	var main := Main.new()
	add_child_autofree(main)
	_select_entity(main, "object_road_cache")
	var cache = main.entities.get_entity("object_road_cache")

	assert_not_null(cache)
	assert_eq(cache.action_hint_text, "Open Roadside Cache")

	main._handle_interact_requested()

	assert_true(cache.action_hint_visible)
	assert_true(cache.action_hint_selected)
	assert_eq(cache.action_hint_text, "Opened Roadside Cache")
	assert_true(main.get_debug_state()["target_detail"].contains("Container: opened"))


func test_selected_target_recovers_immediately_after_enemy_defeat() -> void:
	var main := Main.new()
	add_child_autofree(main)
	_select_entity(main, "enemy_road_thug")
	assert_eq(main.selected_target_id, "enemy_road_thug")

	main._handle_interact_requested()
	main._handle_interact_requested()

	assert_null(main.entities.get_entity("enemy_road_thug"))
	assert_ne(main.selected_target_id, "enemy_road_thug")
	assert_not_null(main._get_nearby_entity())
	assert_true(main.hud.log_label.text.contains("Defeated Road Thug."))


func _select_entity(main, entity_id: String) -> void:
	for _i in range(24):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			main._update_nearby()
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)
