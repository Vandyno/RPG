extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainSystemsActions = preload("res://scripts/main/actions/main_systems_actions.gd")


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


func test_hostile_actor_defeat_does_not_leave_selected_interaction_target() -> void:
	var main := Main.new()
	add_child_autofree(main)
	_equip_hatchet(main)
	var enemy = main.entities.get_entity("npc_road_thug")
	assert_not_null(enemy)
	main.player.set_world_position(enemy.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)

	MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.RIGHT)
	MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.RIGHT)

	assert_null(main.entities.get_entity("npc_road_thug"))
	assert_ne(main.selected_target_id, "npc_road_thug")
	assert_true(main.hud.log_label.text.contains("Defeated Road Thug."))


func _select_entity(main, entity_id: String) -> void:
	var target = main.entities.get_entity(entity_id)
	if target:
		main.player.set_world_position(target.global_position + Vector2(-8.0, 0.0))
		main.player.set_facing_direction(Vector2.RIGHT)
		main._update_nearby()
	for _i in range(24):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			main._update_nearby()
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)


func _equip_hatchet(main) -> void:
	if not main.inventory.has_item("item_road_hatchet"):
		main.inventory.add_item("item_road_hatchet", 1)
	main.equipment.equip_item_to_slot("item_road_hatchet", "right_hand")
