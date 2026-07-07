extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainInputRouter = preload("res://scripts/main/input/main_input_router.gd")


func test_effectful_npc_choice_can_be_used_from_context_action() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "npc_harrow_venn_world")
	assert_eq(main.get_debug_state()["primary_action"], "Talk")
	assert_not_null(_button_containing(main.hud.context_action_buttons, "I'll find it."))
	assert_null(_button_containing(main.hud.context_action_buttons, "Not right now."))

	_button_containing(main.hud.context_action_buttons, "I'll find it.").pressed.emit()

	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "active")
	assert_false(main.hud.is_content_card_visible())
	assert_true(main.hud.log_label.text.contains("Good. Look for the brass latch"))
	assert_true(main.hud.log_label.text.contains("Quest started: The Missing Tools."))
	assert_true(main.entities.get_entity("pickup_old_toolbox").quest_marker_visible)


func test_effectful_npc_line_promotes_to_primary_without_redundant_context_action() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "npc_harrow_venn_world")
	_button_containing(main.hud.context_action_buttons, "I'll find it.").pressed.emit()
	_select_entity(main, "pickup_old_toolbox")
	main._handle_interact_requested()
	_select_entity(main, "npc_harrow_venn_world")

	var turn_in_button := _button_containing(main.hud.context_action_buttons, "Turn In")
	assert_null(turn_in_button)
	assert_eq(main.get_debug_state()["primary_action"], "Turn In")
	main._handle_interact_requested()

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

	_select_entity(main, "npc_harrow_venn_world")
	_button_containing(main.hud.context_action_buttons, "I'll find it.").pressed.emit()
	_select_entity(main, "pickup_old_toolbox")
	main._handle_interact_requested()
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


func test_npc_trade_is_primary_and_talk_remains_secondary() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "npc_maera_pike_world")
	assert_eq(main.get_debug_state()["target_detail"], "Road peddler, Marches of Velcor +0, trader")
	assert_false(main.get_debug_state()["target_detail"].contains("quest inactive"))
	assert_eq(main.get_debug_state()["primary_action"], "Trade")
	assert_null(_button_containing(main.hud.context_action_buttons, "Trade"))
	var talk_button := _button_containing(main.hud.context_action_buttons, "Talk")
	assert_not_null(talk_button)
	var maera = main.entities.get_entity("npc_maera_pike_world")
	assert_true(maera.action_hint_visible)
	assert_true(maera.action_hint_selected)
	assert_eq(maera.action_hint_text, "Trade Maera Pike")
	talk_button.pressed.emit()

	assert_true(main.hud.is_content_card_visible())
	assert_true(main.hud.content_body_label.text.contains("Road goods"))
	main.hud.hide_content_card()
	main._handle_interact_requested()

	assert_true(main.hud.is_systems_panel_visible())
	assert_eq(main.hud.get_systems_tab(), "trade")
	assert_false(main.hud.is_content_card_visible())
	assert_true(main.hud.systems_body_label.text.contains("Crossroads Peddler"))
	assert_not_null(_button_containing(main.hud.systems_action_list, "Buy Roadside Draught"))


func test_trade_feedback_reports_price_and_remaining_gold() -> void:
	var main := Main.new()
	add_child_autofree(main)
	assert_true(main.inventory.add_item("item_gold_coin", 8))

	_select_entity(main, "npc_maera_pike_world")
	main._handle_interact_requested()
	_button_containing(main.hud.systems_action_list, "Buy Roadside Draught").pressed.emit()

	assert_eq(main.inventory.get_count("item_gold_coin"), 0)
	assert_eq(main.inventory.get_count("item_roadside_draught"), 1)
	assert_true(main.hud.log_label.text.contains("Bought Roadside Draught. Spent 8g. Gold: 0."))

	main.hud._select_systems_category("sell")
	_button_containing(main.hud.systems_action_list, "Sell Roadside Draught").pressed.emit()

	assert_eq(main.inventory.get_count("item_gold_coin"), 6)
	assert_eq(main.inventory.get_count("item_roadside_draught"), 0)
	assert_true(main.hud.log_label.text.contains("Sold Roadside Draught. Gained 6g. Gold: 6."))


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


func _button_containing(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text.contains(text):
			return child
	return null
