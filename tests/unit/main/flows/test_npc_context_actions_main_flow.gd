extends GutTest

const Main = preload("res://scripts/main/main.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")
const MainInputRouter = preload("res://scripts/main/input/main_input_router.gd")
const MainFlowInputHelper = preload("res://tests/unit/main/flows/main_flow_input_helper.gd")


func test_effectful_npc_choice_can_be_used_from_context_action() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_true(await MainFlowInputHelper.enter_forge(main, get_tree()))
	assert_true(await MainFlowInputHelper.target_entity(main, "npc_harrow_venn_world", get_tree()))
	assert_eq(main.get_debug_state()["primary_action"], "Talk")
	var accept := MainFlowInputHelper.button_containing(
		main.hud.content_choice_list, "I'll find it."
	)
	assert_not_null(accept)

	await MainFlowInputHelper.click(accept, get_tree())

	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "active")
	assert_true(main.hud.log_label.text.contains("Good. Look for the brass latch"))
	assert_true(main.hud.log_label.text.contains("Quest started: The Missing Tools."))
	assert_true(await MainFlowInputHelper.exit_forge(main, get_tree()))
	assert_true(main.entities.get_entity("pickup_old_toolbox").quest_marker_visible)


func test_effectful_npc_line_promotes_to_primary_without_redundant_context_action() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_true(await MainFlowInputHelper.enter_forge(main, get_tree()))
	_select_entity(main, "npc_harrow_venn_world")
	await MainFlowInputHelper.click(
		_button_containing(main.hud.context_action_buttons, "I'll find it."), get_tree()
	)
	assert_true(await MainFlowInputHelper.exit_forge(main, get_tree()))
	_select_entity(main, "pickup_old_toolbox")
	MainFlowInputHelper.interact_action(main)
	assert_true(await MainFlowInputHelper.enter_forge(main, get_tree()))
	_select_entity(main, "npc_harrow_venn_world")

	var turn_in_button := _button_containing(main.hud.context_action_buttons, "Turn In")
	assert_null(turn_in_button)
	assert_eq(main.get_debug_state()["primary_action"], "Turn In")
	MainFlowInputHelper.interact_action(main)

	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "completed")
	assert_false(main.inventory.has_item("item_old_toolbox"))
	assert_eq(main.inventory.get_count("item_gold_coin"), 25)
	assert_true(main.world_state.has_flag("flag_blacksmith_tools_returned"))
	assert_false(main.hud.is_content_card_visible())
	assert_true(main.hud.log_label.text.contains("Quest complete: The Missing Tools."))
	assert_true(main.hud.log_label.text.contains("That's mine. Good work."))


func test_world_hint_promotes_ready_npc_turn_in_action() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_true(await MainFlowInputHelper.enter_forge(main, get_tree()))
	_select_entity(main, "npc_harrow_venn_world")
	await MainFlowInputHelper.click(
		_button_containing(main.hud.context_action_buttons, "I'll find it."), get_tree()
	)
	assert_true(await MainFlowInputHelper.exit_forge(main, get_tree()))
	_select_entity(main, "pickup_old_toolbox")
	MainFlowInputHelper.interact_action(main)
	assert_true(await MainFlowInputHelper.enter_forge(main, get_tree()))
	_select_entity(main, "npc_harrow_venn_world")
	main._update_nearby()
	var harrow = main.entities.get_entity("npc_harrow_venn_world")

	assert_eq(main.get_debug_state()["primary_action"], "Turn In")
	assert_true(harrow.action_hint_visible)
	assert_true(harrow.action_hint_selected)
	assert_eq(harrow.action_hint_text, "Turn In Harrow Venn")

	var label_world: Vector2 = harrow.global_position + Vector2(0.0, -35.0)
	assert_true(MainInputRouter.target_world(main, label_world))

	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "completed")
	assert_false(main.inventory.has_item("item_old_toolbox"))


func test_npc_trade_is_reached_through_dialogue_choice() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_true(await MainFlowInputHelper.target_entity(main, "npc_maera_pike_world", get_tree()))
	assert_eq(main.get_debug_state()["target_detail"], "Road peddler, Marches of Velcor +0, trader")
	assert_false(main.get_debug_state()["target_detail"].contains("quest inactive"))
	assert_eq(main.get_debug_state()["primary_action"], "Talk")
	assert_null(MainFlowInputHelper.button_containing(main.hud.context_action_buttons, "Trade"))
	var maera = main.entities.get_entity("npc_maera_pike_world")
	assert_true(maera.action_hint_visible)
	assert_true(maera.action_hint_selected)
	assert_eq(maera.action_hint_text, "Talk Maera Pike")
	assert_true(main.hud.is_content_card_visible())
	assert_true(main.hud.content_body_label.text.contains("Road goods"))
	var trade_button := MainFlowInputHelper.button_containing(main.hud.content_choice_list, "Trade")
	assert_not_null(trade_button)
	await MainFlowInputHelper.click(trade_button, get_tree())

	assert_true(main.hud.is_systems_panel_visible())
	assert_eq(main.hud.get_systems_tab(), "trade")
	assert_false(main.hud.is_content_card_visible())
	assert_true(main.hud.systems_body_label.text.contains("Crossroads Peddler"))
	assert_not_null(_button_containing(main.hud.systems_action_list, "Buy Traveler Buckler"))


func test_trade_feedback_reports_price_and_remaining_gold() -> void:
	var main := Main.new()
	add_child_autofree(main)
	assert_true(main.inventory.add_item("item_gold_coin", 18))

	assert_true(await MainFlowInputHelper.target_entity(main, "npc_maera_pike_world", get_tree()))
	await MainFlowInputHelper.click(
		MainFlowInputHelper.button_containing(main.hud.content_choice_list, "Trade"), get_tree()
	)
	await MainFlowInputHelper.click(
		MainFlowInputHelper.button_containing(main.hud.systems_action_list, "Buy Traveler Buckler"),
		get_tree()
	)

	assert_eq(main.inventory.get_count("item_gold_coin"), 0)
	assert_eq(main.inventory.get_count("item_traveler_buckler"), 1)
	assert_true(main.hud.log_label.text.contains("Bought Traveler Buckler. Spent 18g. Gold: 0."))

	await MainFlowInputHelper.click(
		MainFlowInputHelper.button_containing(main.hud.systems_category_row, "Sell"), get_tree()
	)
	await MainFlowInputHelper.click(
		MainFlowInputHelper.button_containing(
			main.hud.systems_action_list, "Sell Traveler Buckler"
		),
		get_tree()
	)

	assert_eq(main.inventory.get_count("item_gold_coin"), 8)
	assert_eq(main.inventory.get_count("item_traveler_buckler"), 0)
	assert_true(main.hud.log_label.text.contains("Sold Traveler Buckler. Gained 8g. Gold: 8."))


func test_real_aim_attack_harms_neutral_npc_and_removes_normal_interaction() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var maera = main.entities.get_entity("npc_maera_pike_world")
	assert_not_null(maera)
	assert_true(ActorRules.is_damageable_actor_entity(maera))
	assert_false(maera.is_combat_target())
	var start_health := main.combat.get_entity_health(maera)
	main.player.set_world_position(maera.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	main._update_nearby()
	await MainFlowInputHelper.settle(main, get_tree())
	var attack_control := main.hud.primary_action_button
	assert_not_null(attack_control)
	assert_eq(String(attack_control.get_meta("action_kind", "")), "attack")

	await MainFlowInputHelper.drag(attack_control, Vector2(56.0, 0.0), get_tree())
	maera = main.entities.get_entity("npc_maera_pike_world")

	assert_not_null(maera)
	assert_lt(main.combat.get_entity_health(maera), start_health)
	assert_true(maera.is_combat_target())
	assert_eq(maera.data["hostility"], "hostile")
	assert_eq(maera.data.get("_brain_mode", ""), "engaged")
	assert_true(["chasing", "attacking"].has(String(maera.data.get("behavior_state", ""))))
	main._update_nearby()
	for candidate in main.entities.get_interactables_world(main.player.global_position):
		assert_ne(candidate.get_entity_id(), "npc_maera_pike_world")
	var nearby = main._get_nearby_entity()
	assert_true(nearby == null or nearby.get_entity_id() != "npc_maera_pike_world")
	assert_false(main.hud.is_content_card_visible())


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
		MainFlowInputHelper.cycle_target_action(main)
	fail_test("Could not select nearby entity: %s" % entity_id)


func _button_containing(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text.contains(text):
			return child
	return null
