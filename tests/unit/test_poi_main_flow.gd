extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_town_hall_job_board_shows_place_card() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "poi_briarwatch_square")
	assert_eq(
		main.get_debug_state()["target_detail"],
		"Town Hall: jobs, notices, and town records"
	)
	main._handle_interact_requested()

	assert_eq(main.hud.content_kind_label.text, "Place")
	assert_true(main.hud.content_title_label.text.contains("Warden's Job Board"))
	assert_true(main.hud.content_body_label.text.contains("town hall"))
	assert_not_null(_button_containing(main.hud.content_choice_list, "Take Road Patrol Job"))
	assert_true(main.hud.log_label.text.contains("Visited Warden's Job Board"))


func test_available_town_square_job_can_be_started_from_context_action() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "npc_harrow_venn_world")
	_button_containing(main.hud.context_action_buttons, "I'll find it.").pressed.emit()
	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "active")

	_select_entity(main, "poi_briarwatch_square")
	assert_eq(main.get_debug_state()["primary_action"], "Use")
	main._handle_interact_requested()
	assert_true(main.hud.content_body_label.text.contains("official notices"))
	main.hud.hide_content_card()
	main._update_nearby()
	var job_button := _button_containing(main.hud.context_action_buttons, "Take Road Patrol Job")
	assert_not_null(job_button)
	assert_not_null(_button_containing(main.hud.context_action_buttons, "Inspect"))
	assert_eq(main.get_debug_state()["primary_action"], "Use")
	job_button.pressed.emit()

	assert_eq(main.quests.get_quest_state("quest_briarwatch_road_patrol"), "active")
	assert_false(main.hud.is_content_card_visible())
	assert_true(main.hud.log_label.text.contains("road thug west of Briarwatch"))
	assert_true(main.hud.status_label.text.contains("Quest: The Missing Tools (+1)"))
	assert_true(main.hud.status_label.text.contains("Old Toolbox (+1)"))


func test_shop_poi_opens_trade_panel_directly() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "poi_maera_stall")
	assert_eq(main.get_debug_state()["target_detail"], "Market Stall: trade and rumor hook")
	assert_eq(main.get_debug_state()["primary_action"], "Trade")
	var inspect_button := _button_containing(main.hud.context_action_buttons, "Inspect")
	assert_not_null(inspect_button)
	var stall = main.entities.get_entity("poi_maera_stall")
	assert_true(stall.action_hint_visible)
	assert_true(stall.action_hint_selected)
	assert_eq(stall.action_hint_text, "Trade Maera's Stall")
	inspect_button.pressed.emit()

	assert_true(main.world_state.discovered_locations.has("location_maera_stall"))
	assert_true(main.hud.is_content_card_visible())
	assert_eq(main.hud.content_kind_label.text, "Place")
	assert_true(main.hud.content_body_label.text.contains("wooden shop"))
	assert_false(main.hud.is_systems_panel_visible())
	main.hud.hide_content_card()
	main._handle_interact_requested()

	assert_true(main.world_state.discovered_locations.has("location_maera_stall"))
	assert_true(main.hud.is_systems_panel_visible())
	assert_eq(main.hud.get_systems_tab(), "trade")
	assert_true(main.hud.systems_body_label.text.contains("Crossroads Peddler"))
	assert_not_null(_button_containing(main.hud.systems_action_list, "Buy Roadside Draught"))
	assert_true(main.hud.log_label.text.contains("Discovered Maera's Stall"))


func test_shop_poi_shop_id_opens_trade_without_system_tab() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var stall = main.entities.get_entity("poi_maera_stall")

	assert_not_null(stall)
	stall.data.erase("system_tab")
	_select_entity(main, "poi_maera_stall")
	assert_eq(main.get_debug_state()["primary_action"], "Trade")
	main._handle_interact_requested()

	assert_true(main.hud.is_systems_panel_visible())
	assert_eq(main.hud.get_systems_tab(), "trade")
	assert_true(main.hud.systems_body_label.text.contains("Crossroads Peddler"))
	assert_not_null(_button_containing(main.hud.systems_action_list, "Buy Roadside Draught"))


func test_forge_poi_offers_paid_sharpening_service_when_requirements_are_met() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "poi_harrow_forge")
	main._handle_interact_requested()
	assert_eq(main.hud.content_kind_label.text, "Place")
	assert_true(main.hud.content_body_label.text.contains("repair, crafting, upgrade"))
	assert_null(_button_containing(main.hud.content_choice_list, "Sharpen Road Hatchet"))
	main.hud.hide_content_card()

	_select_entity(main, "pickup_road_hatchet")
	main._handle_interact_requested()
	_select_entity(main, "object_road_cache")
	main._handle_interact_requested()
	assert_eq(main.inventory.get_count("item_gold_coin"), 2)

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
	assert_eq(main.inventory.get_count("item_gold_coin"), 2)

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

	_select_entity(main, "enemy_road_thug")
	main._handle_interact_requested()
	main._handle_interact_requested()
	assert_true(main.world_state.has_flag("flag_spawn_enemy_defeated"))

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
	for _i in range(40):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			main._update_nearby()
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)


func _button_containing(container: Node, text: String) -> Button:
	for child in container.get_children():
		if child is Button and child.text.contains(text):
			return child
	return null
