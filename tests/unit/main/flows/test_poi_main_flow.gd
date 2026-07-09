extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainSystemsActions = preload("res://scripts/main/actions/main_systems_actions.gd")
const MainFlowInputHelper = preload("res://tests/unit/main/flows/main_flow_input_helper.gd")


func test_town_hall_job_board_shows_place_card() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_true(
		await MainFlowInputHelper.target_entity(
			main, "poi_briarwatch_square", get_tree(), false
		)
	)
	assert_eq(
		main.get_debug_state()["target_detail"],
		"Town Hall: jobs, notices, and town records"
	)
	assert_true(await MainFlowInputHelper.target_entity(main, "poi_briarwatch_square", get_tree()))

	assert_eq(main.hud.content_kind_label.text, "Place")
	assert_true(main.hud.content_title_label.text.contains("Warden's Job Board"))
	assert_true(main.hud.content_body_label.text.contains("town hall"))
	assert_not_null(
		MainFlowInputHelper.button_containing(main.hud.content_choice_list, "Take Road Patrol Job")
	)
	assert_true(main.hud.log_label.text.contains("Visited Warden's Job Board"))


func test_available_town_square_job_can_be_started_from_context_action() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_true(await MainFlowInputHelper.enter_forge(main, get_tree()))
	assert_true(await MainFlowInputHelper.target_entity(main, "npc_harrow_venn_world", get_tree()))
	await MainFlowInputHelper.click(
		MainFlowInputHelper.button_containing(main.hud.content_choice_list, "I'll find it."),
		get_tree()
	)
	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "active")
	assert_true(await MainFlowInputHelper.exit_forge(main, get_tree()))

	assert_true(
		await MainFlowInputHelper.target_entity(
			main, "poi_briarwatch_square", get_tree(), false
		)
	)
	assert_eq(main.get_debug_state()["primary_action"], "Use")
	assert_true(await MainFlowInputHelper.target_entity(main, "poi_briarwatch_square", get_tree()))
	assert_true(main.hud.content_body_label.text.contains("official notices"))
	main.hud.hide_content_card()
	assert_true(
		await MainFlowInputHelper.target_entity(
			main, "poi_briarwatch_square", get_tree(), false
		)
	)
	var job_button := MainFlowInputHelper.button_containing(
		main.hud.context_action_buttons, "Take Road Patrol Job"
	)
	assert_not_null(job_button)
	assert_not_null(
		MainFlowInputHelper.button_containing(main.hud.context_action_buttons, "Inspect")
	)
	assert_eq(main.get_debug_state()["primary_action"], "Use")
	await MainFlowInputHelper.click(job_button, get_tree())

	assert_eq(main.quests.get_quest_state("quest_briarwatch_road_patrol"), "active")
	assert_false(main.hud.is_content_card_visible())
	assert_true(main.hud.log_label.text.contains("road thug west of Briarwatch"))
	assert_false(main.hud.status_label.text.contains("Quest:"))


func test_maera_stall_terminal_is_not_spawned() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_null(main.entities.get_entity("poi_maera_stall"))


func test_forge_poi_offers_paid_sharpening_service_when_requirements_are_met() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_true(await MainFlowInputHelper.enter_forge(main, get_tree()))
	_select_entity(main, "poi_harrow_forge")
	main._handle_interact_requested()
	assert_eq(main.hud.content_kind_label.text, "Place")
	assert_true(main.hud.content_body_label.text.contains("repair, crafting, upgrade"))
	assert_null(_button_containing(main.hud.content_choice_list, "Sharpen Road Hatchet"))
	main.hud.hide_content_card()

	assert_true(await MainFlowInputHelper.exit_forge(main, get_tree()))
	_select_entity(main, "pickup_road_hatchet")
	main._handle_interact_requested()
	_select_entity(main, "object_road_cache")
	main._handle_interact_requested()
	main._handle_inventory_item_selected("take:item_gold_coin")
	main._handle_inventory_item_selected("take:item_gold_coin")
	main.hud.hide_systems_panel()
	assert_eq(main.inventory.get_count("item_gold_coin"), 2)

	assert_true(await MainFlowInputHelper.enter_forge(main, get_tree()))
	_select_entity(main, "poi_harrow_forge")
	assert_eq(main.get_debug_state()["primary_action"], "Sharpen Road Hatchet (2g)")
	assert_not_null(_button_containing(main.hud.context_action_buttons, "Inspect"))
	var sharpen_context_button := _button_containing(
		main.hud.context_action_buttons, "Sharpen Road Hatchet"
	)
	assert_true(sharpen_context_button == null or not sharpen_context_button.visible)
	main._handle_interact_requested()

	assert_eq(main.inventory.get_count("item_gold_coin"), 0)
	assert_eq(main.statuses.get_remaining_charges("status_road_focus"), 3)
	assert_false(main.hud.is_content_card_visible())
	assert_true(main.hud.log_label.text.contains("hatchet edge"))


func test_forge_service_can_be_used_from_context_action_when_requirements_are_met() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "pickup_road_hatchet")
	main._handle_interact_requested()
	_select_entity(main, "object_road_cache")
	main._handle_interact_requested()
	main._handle_inventory_item_selected("take:item_gold_coin")
	main._handle_inventory_item_selected("take:item_gold_coin")
	main.hud.hide_systems_panel()
	assert_eq(main.inventory.get_count("item_gold_coin"), 2)

	assert_true(await MainFlowInputHelper.enter_forge(main, get_tree()))
	_select_entity(main, "poi_harrow_forge")
	var sharpen_button := _button_containing(
		main.hud.context_action_buttons, "Sharpen Road Hatchet"
	)
	assert_not_null(sharpen_button)
	assert_eq(main.get_debug_state()["primary_action"], "Use")
	sharpen_button.pressed.emit()

	assert_eq(main.inventory.get_count("item_gold_coin"), 0)
	assert_eq(main.statuses.get_remaining_charges("status_road_focus"), 3)
	assert_false(main.hud.is_content_card_visible())
	assert_true(main.hud.log_label.text.contains("hatchet edge"))


func test_town_square_job_board_starts_and_completes_patrol_quest() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "poi_briarwatch_square")
	main._handle_interact_requested()
	var take_job_button := _button_containing(main.hud.content_choice_list, "Take Road Patrol Job")
	assert_not_null(take_job_button)
	take_job_button.pressed.emit()

	assert_eq(main.quests.get_quest_state("quest_briarwatch_road_patrol"), "active")
	assert_eq(main.hud.content_kind_label.text, "Result")
	assert_true(main.hud.content_body_label.text.contains("road thug west of Briarwatch"))
	main.hud.hide_content_card()

	_attack_hostile_actor_until_defeated(main, "npc_road_thug")
	assert_true(main.world_state.has_flag("flag_spawn_road_thug_defeated"))

	_select_entity(main, "poi_briarwatch_square")
	main._handle_interact_requested()
	var report_button := _button_containing(
		main.hud.content_choice_list, "Report Road Patrol Complete"
	)
	assert_not_null(report_button)
	report_button.pressed.emit()

	assert_eq(main.quests.get_quest_state("quest_briarwatch_road_patrol"), "completed")
	assert_eq(main.inventory.get_count("item_gold_coin"), 11)
	assert_eq(main.factions.get_reputation("faction_marches_of_velcor"), 2)
	assert_eq(main.progression.experience, 18)
	assert_true(main.hud.is_content_card_visible())
	assert_eq(main.hud.content_kind_label.text, "Result")
	assert_true(main.hud.content_body_label.text.contains("road clear"))
	assert_true(main.hud.log_label.text.contains("road clear"))


func _select_entity(main, entity_id: String) -> void:
	var target = main.entities.get_entity(entity_id)
	if target:
		main.player.set_world_position(target.global_position + Vector2(-8.0, 0.0))
		main.player.set_facing_direction(Vector2.RIGHT)
		main._update_nearby()
	for _i in range(40):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			main._update_nearby()
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)


func _attack_hostile_actor_until_defeated(main, entity_id: String) -> void:
	_equip_hatchet(main)
	var enemy = main.entities.get_entity(entity_id)
	assert_not_null(enemy)
	main.player.set_world_position(enemy.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	for _i in range(8):
		MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.RIGHT)
		if not main.entities.get_entity(entity_id):
			return
	fail_test("Hostile actor was not defeated: %s" % entity_id)


func _equip_hatchet(main) -> void:
	if not main.inventory.has_item("item_road_hatchet"):
		main.inventory.add_item("item_road_hatchet", 1)
	main.equipment.equip_item_to_slot("item_road_hatchet", "right_hand")


func _button_containing(container: Node, text: String) -> Button:
	for child in container.get_children():
		if child is Button and child.text.contains(text):
			return child
	return null
