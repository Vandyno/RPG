extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainSystemsActions = preload("res://scripts/main/main_systems_actions.gd")
const TEST_SAVE_PATH := "user://test_main_flow.json"


func before_each() -> void:
	_remove_test_save()


func after_each() -> void:
	_remove_test_save()


func test_sneak_button_does_not_open_or_cycle_targets() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var enemy = main.entities.get_entity("enemy_road_thug")
	main.player.set_world_position(enemy.global_position + Vector2(8.0, 0.0))
	main.player.set_facing_direction(Vector2.LEFT)
	main._update_nearby()

	var first = main._get_nearby_entity()
	assert_not_null(first)
	var first_id: String = first.get_entity_id()

	var next_button: Button = main.hud.target_action_button
	assert_not_null(next_button)
	next_button.pressed.emit()
	var second = main._get_nearby_entity()
	assert_not_null(second)

	assert_eq(second.get_entity_id(), first_id)
	assert_false(main.hud.is_target_picker_visible())

	main.hud.toggle_target_picker()
	assert_false(main.hud.is_target_picker_visible())


func test_selected_target_remains_stable_when_nearby_order_changes() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_kind(main, "pickup")
	var selected = main._get_nearby_entity()
	assert_not_null(selected)
	var selected_id: String = selected.get_entity_id()
	main._handle_target_selected(selected_id)

	main.player.set_world_position(selected.global_position + Vector2(4.0, 0.0))
	var still_selected = main._get_nearby_entity()

	assert_not_null(still_selected)
	assert_eq(still_selected.get_entity_id(), selected_id)
	assert_true(main.get_debug_state()["nearby_all"].contains("*%s*" % selected.get_display_name()))


func test_selected_target_recovers_after_selected_entity_is_removed() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_kind(main, "pickup")
	var selected = main._get_nearby_entity()
	assert_not_null(selected)
	var removed_id: String = selected.get_entity_id()
	assert_eq(main.selected_target_id, removed_id)

	main._handle_interact_requested()
	assert_null(main.entities.get_entity(removed_id))

	var fallback = main._get_nearby_entity()
	assert_not_null(fallback)
	assert_ne(main.selected_target_id, removed_id)
	assert_eq(main.selected_target_id, fallback.get_entity_id())


func test_rest_interaction_heals_player() -> void:
	var main := Main.new()
	add_child_autofree(main)
	assert_eq(main.time.get_summary(), "Day 1, 08:00 (Morning)")
	main.player.apply_damage(40)
	assert_eq(main.player.health, 60)

	_select_kind(main, "rest")

	var rest = main._get_nearby_entity()
	assert_not_null(rest)
	assert_eq(rest.get_kind(), "rest")
	assert_eq(main.get_debug_state()["target_detail"], "Rest: heals 100, advances 8h")

	main._handle_interact_requested()

	assert_eq(main.player.health, main.player.max_health)
	assert_eq(main.time.get_summary(), "Day 1, 16:00 (Afternoon)")
	assert_true(main.hud.log_label.text.contains("until Day 1, 16:00"))
	assert_true(main.get_debug_state()["time_details"].contains("Phase: Afternoon"))
	main.hud.toggle_systems()
	main.hud.set_systems_tab("journal")
	var wait_button := _button_containing(main.hud.systems_action_list, "Wait 1h")
	assert_not_null(wait_button)
	wait_button.pressed.emit()
	assert_eq(main.time.get_summary(), "Day 1, 17:00 (Evening)")
	assert_true(main.hud.log_label.text.contains("Waited 1h."))


func test_mobile_touch_move_vector_reaches_player_controller() -> void:
	var main := Main.new()
	add_child_autofree(main)

	main.hud.set_touch_move_vector(Vector2.RIGHT)
	assert_eq(main.player.external_move_vector, Vector2.RIGHT)

	main.hud.set_touch_move_vector(Vector2.ZERO)
	assert_eq(main.player.external_move_vector, Vector2.ZERO)


func test_spawn_location_discovery_is_nearby_visible_and_persistent() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.save_manager.save_path = TEST_SAVE_PATH

	assert_false(main.world_state.discovered_locations.has("location_briarwatch_crossroads"))
	main._update_location_discoveries()

	assert_true(main.world_state.discovered_locations.has("location_briarwatch_crossroads"))
	assert_true(main.hud.log_label.text.contains("Discovered Briarwatch Crossroads."))
	assert_true(main.get_debug_state()["locations"].contains("Briarwatch Crossroads"))
	assert_false(main.get_debug_state()["nearby_all"].contains("Briarwatch Crossroads"))

	assert_true(main.save_manager.save_game())
	main.world_state.discovered_locations.clear()
	assert_true(main.save_manager.load_game())

	assert_true(main.world_state.discovered_locations.has("location_briarwatch_crossroads"))


func test_npc_completion_requires_authored_conditions() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "npc_harrow_venn_world")
	main._handle_interact_requested()
	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "inactive")
	assert_false(main.active_content_choices.is_empty())
	main.hud.hide_content_card()
	assert_true(main.active_content_choices.is_empty())
	main._handle_content_choice_selected("accept_missing_tools")
	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "inactive")
	assert_true(main.hud.log_label.text.contains("That choice is no longer available."))

	main._handle_interact_requested()
	_choose_content(main, "Not right now.")
	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "inactive")
	assert_true(main.hud.content_body_label.text.contains("steady hands later"))

	main.hud.hide_content_card()
	main._handle_interact_requested()
	assert_false(main.active_content_choices.is_empty())
	main.hud.show_systems_panel("inventory")
	assert_true(main.active_content_choices.is_empty())
	assert_false(main.hud.is_content_card_visible())
	assert_true(main.hud.is_systems_panel_visible())

	main.hud.hide_systems_panel()
	main._handle_interact_requested()
	_choose_content(main, "I'll find it.")
	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "active")
	assert_true(main.hud.content_body_label.text.contains("brass latch"))
	assert_true(main.get_debug_state()["quest_directions"].contains("Old Toolbox"))
	assert_true(main.entities.get_entity("pickup_old_toolbox").quest_marker_visible)
	assert_false(main.entities.get_entity("npc_harrow_venn_world").quest_marker_visible)

	main.hud.hide_content_card()
	main._handle_interact_requested()

	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "active")
	assert_false(main.world_state.has_flag("flag_blacksmith_tools_returned"))
	assert_false(main.inventory.has_item("item_gold_coin"))
	assert_true(main.hud.content_body_label.text.contains("The toolbox should be nearby."))


func test_open_systems_panel_consumes_interact_and_target_actions() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var notice = main.entities.get_entity("object_road_notice")
	main.player.set_world_position(notice.global_position + Vector2(-8.0, 0.0))
	main._update_nearby()
	var first = main._get_nearby_entity()
	assert_not_null(first)
	var first_id: String = first.get_entity_id()

	main.hud.toggle_systems()
	main._handle_interact_requested()

	assert_false(main.hud.is_systems_panel_visible())
	assert_false(main.readables.has_read("readable_briarwatch_notice"))

	main.hud.toggle_systems()
	main._handle_cycle_target_requested()

	assert_false(main.hud.is_systems_panel_visible())
	assert_eq(main._get_nearby_entity().get_entity_id(), first_id)

	main.hud.toggle_target_picker()
	main._handle_interact_requested()

	assert_false(main.hud.is_target_picker_visible())
	assert_false(main.readables.has_read("readable_briarwatch_notice"))


func test_keyboard_action_echo_does_not_repeat_one_shot_actions() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var press := InputEventKey.new()
	press.keycode = KEY_J
	press.pressed = true
	var echo := InputEventKey.new()
	echo.keycode = KEY_J
	echo.pressed = true
	echo.echo = true

	main._unhandled_input(press)
	assert_true(main.hud.is_systems_panel_visible())

	main._unhandled_input(echo)
	assert_true(main.hud.is_systems_panel_visible())


func test_save_and_load_hide_open_systems_panel_while_running() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.save_manager.save_path = TEST_SAVE_PATH

	main.hud.toggle_systems()
	main._handle_save_requested()

	assert_false(main.hud.is_systems_panel_visible())
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH))

	main.hud.toggle_systems()
	main.player.set_health(7)
	main._handle_load_requested()

	assert_false(main.hud.is_systems_panel_visible())
	assert_eq(main.player.health, main.player.max_health)

	main.hud.show_systems_panel("journal")
	var save_button := _button_containing(main.hud.systems_action_list, "Save Game")
	assert_not_null(save_button)
	save_button.pressed.emit()

	assert_false(main.hud.is_systems_panel_visible())
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH))

	main.player.set_health(5)
	main.hud.show_systems_panel("journal")
	var load_button := _button_containing(main.hud.systems_action_list, "Load Game")
	assert_not_null(load_button)
	load_button.pressed.emit()

	assert_false(main.hud.is_systems_panel_visible())
	assert_eq(main.player.health, main.player.max_health)


func test_full_spawn_yard_system_loop() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_kind(main, "readable")
	main._handle_interact_requested()
	await wait_process_frames(1)
	assert_true(main.readables.has_read("readable_briarwatch_notice"))
	assert_true(main.world_state.has_flag("flag_briarwatch_notice_read"))
	assert_not_null(main.entities.get_entity("object_warden_cache"))
	assert_true(main.hud.is_content_card_visible())
	assert_eq(main.hud.content_kind_label.text, "Readable")
	main.hud.hide_content_card()

	_select_entity(main, "npc_harrow_venn_world")
	main._handle_interact_requested()
	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "inactive")
	assert_eq(main.hud.content_kind_label.text, "Dialogue")
	assert_true(main.hud.content_body_label.text.contains("need my old toolbox"))
	_choose_content(main, "I'll find it.")
	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "active")
	assert_true(main.hud.is_content_card_visible())
	assert_eq(main.hud.content_kind_label.text, "Result")
	main.hud.hide_content_card()

	_select_entity(main, "pickup_old_toolbox")
	main._handle_interact_requested()
	assert_true(main.inventory.has_item("item_old_toolbox"))
	assert_true(main.get_debug_state()["inventory_details"].contains("A heavy wooden toolbox"))
	assert_eq(main.quests.quests["quest_missing_tools"]["stage"], "found_toolbox")
	assert_null(main.entities.get_entity("pickup_old_toolbox"))

	_select_entity(main, "pickup_roadside_draught")
	main._handle_interact_requested()
	assert_true(main.inventory.has_item("item_roadside_draught"))
	assert_null(main.entities.get_entity("pickup_roadside_draught"))

	_select_entity(main, "pickup_road_hatchet")
	main._handle_interact_requested()
	assert_true(main.inventory.has_item("item_road_hatchet"))
	_select_entity(main, "pickup_traveler_buckler")
	main._handle_interact_requested()
	assert_true(main.inventory.has_item("item_traveler_buckler"))

	_select_entity(main, "npc_harrow_venn_world")
	main._handle_interact_requested()
	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "completed")
	assert_false(main.inventory.has_item("item_old_toolbox"))
	assert_eq(main.inventory.get_count("item_gold_coin"), 25)
	assert_true(main.world_state.has_flag("flag_blacksmith_tools_returned"))
	assert_eq(main.factions.get_reputation("faction_marches_of_velcor"), 5)
	assert_eq(main.progression.level, 2)
	assert_eq(main.progression.experience, 0)
	assert_eq(main.progression.skill_points, 1)
	assert_true(main.get_debug_state()["factions"].contains("Marches of Velcor +5"))
	assert_true(main.get_debug_state()["progression"].contains("Level 2"))
	main.hud.toggle_systems()
	assert_true(main.hud.systems_body_label.text.contains("Gold Coin x25"))
	assert_true(main.hud.systems_body_label.text.contains("A stamped trade coin"))
	var hatchet_button := _button_containing(main.hud.systems_action_list, "Equip Road Hatchet")
	assert_not_null(hatchet_button)
	hatchet_button.pressed.emit()
	var buckler_button := _button_containing(main.hud.systems_action_list, "Equip Traveler Buckler")
	assert_not_null(buckler_button)
	buckler_button.pressed.emit()
	assert_eq(main.equipment.get_equipped_item("weapon"), "item_road_hatchet")
	assert_eq(main.equipment.get_equipped_item("offhand"), "item_traveler_buckler")
	assert_true(main.hud.systems_body_label.text.contains("Weapon: Road Hatchet"))
	assert_true(main.hud.systems_body_label.text.contains("Offhand: Traveler Buckler"))
	main.hud.set_systems_tab("character")
	assert_true(main.hud.systems_body_label.text.contains("Unspent points: 1"))
	var train_might_button := _button_containing(main.hud.systems_action_list, "Train Might")
	assert_not_null(train_might_button)
	train_might_button.pressed.emit()
	assert_eq(main.progression.skill_points, 0)
	assert_eq(main.progression.get_stat_rank("might"), 1)
	assert_true(main.hud.log_label.text.contains("Trained Might."))
	assert_true(main.hud.systems_body_label.text.contains("Might 1"))
	main.hud.set_systems_tab("quests")
	assert_true(main.hud.systems_body_label.text.contains("The Missing Tools: complete"))
	main.hud.set_systems_tab("journal")
	assert_true(main.hud.systems_body_label.text.contains("Marches of Velcor +5"))
	main.hud.set_systems_tab("character")
	assert_true(main.hud.systems_body_label.text.contains("Level: 2"))

	_select_entity(main, "npc_maera_pike_world")
	assert_true(main.get_debug_state()["target_detail"].contains("trader"))
	assert_eq(main.get_debug_state()["primary_action"], "Trade")
	var maera_talk_button := _button_containing(main.hud.context_action_buttons, "Talk")
	assert_not_null(maera_talk_button)
	maera_talk_button.pressed.emit()
	assert_true(main.hud.content_body_label.text.contains("warden's notice"))
	assert_true(main.hud.content_body_label.text.contains("trade tab"))
	main.hud.hide_content_card()
	main._handle_interact_requested()
	assert_true(main.hud.systems_body_label.text.contains("Crossroads Peddler"))
	assert_true(main.hud.systems_body_label.text.contains("Hours: 08:00-18:00"))
	assert_false(main.hud.systems_body_label.text.contains("Closed now."))
	var buy_draught_button := _button_containing(
		main.hud.systems_action_list, "Buy Roadside Draught"
	)
	assert_not_null(buy_draught_button)
	buy_draught_button.pressed.emit()
	assert_eq(main.inventory.get_count("item_gold_coin"), 17)
	assert_eq(main.inventory.get_count("item_roadside_draught"), 2)
	assert_true(main.hud.log_label.text.contains("Bought Roadside Draught."))
	assert_true(main.time.advance_hours(12))
	main.hud.hide_systems_panel()
	main.hud.refresh()
	main._handle_interact_requested()
	assert_true(main.hud.systems_body_label.text.contains("Closed now."))
	var closed_buy_button := _button_containing(
		main.hud.systems_action_list, "Buy Roadside Draught"
	)
	assert_true(closed_buy_button == null or not closed_buy_button.visible)
	main.hud.hide_systems_panel()
	assert_false(main.hud.is_systems_panel_visible())
	assert_true(main.time.advance_hours(12))
	main.hud.refresh()

	_stand_by_enemy(main, "enemy_road_thug")
	assert_false(main.hud.context_action_panel.visible)
	var guard_button := _button_containing(main.hud.context_action_buttons, "Guard")
	assert_null(guard_button)
	var attack_button := _button_containing(main.hud.context_action_buttons, "Attack")
	assert_true(attack_button == null or not attack_button.visible)
	assert_ne(main.get_debug_state()["primary_action"], "Attack")
	_attack_enemy_once(main, "enemy_road_thug")
	assert_eq(main.player.health, 100)
	assert_eq(int(main.hud.health_bar.value), 100)
	assert_eq(main.hud.health_label.text, "HP 100/100  MP 100/100")
	assert_eq(main.hud.health_bar.tooltip_text, "Health: 100/100")
	assert_true(main.hud.log_label.text.contains("hits Road Thug"))
	_attack_enemy_once(main, "enemy_road_thug")
	assert_true(main.hud.log_label.text.contains("Defeated Road Thug."))
	assert_null(main.entities.get_entity("enemy_road_thug"))
	main.hud.toggle_systems()
	main.hud.set_systems_tab("inventory")
	main.player.apply_damage(25)
	var draught_button := _button_containing(main.hud.systems_action_list, "Use Roadside Draught")
	assert_not_null(draught_button)
	draught_button.pressed.emit()
	assert_eq(main.player.health, main.player.max_health)
	assert_eq(main.inventory.get_count("item_roadside_draught"), 1)
	assert_true(main.hud.log_label.text.contains("Used Roadside Draught."))
	main.hud.toggle_systems()
	assert_true(main.world_state.has_flag("flag_spawn_enemy_defeated"))
	assert_eq(main.factions.get_reputation("faction_road_bandits"), -5)
	assert_eq(main.inventory.get_count("item_gold_coin"), 20)
	assert_eq(main.progression.level, 2)
	assert_eq(main.progression.experience, 10)
	assert_true(main.get_debug_state()["inventory"].contains("Gold Coin x20"))
	_select_entity(main, "object_road_cache")
	assert_true(main.get_debug_state()["target_detail"].contains("Container: closed"))
	main._handle_interact_requested()
	assert_eq(main.inventory.get_count("item_gold_coin"), 22)
	assert_eq(main.progression.experience, 12)
	assert_true(main.chunks.is_object_opened("object_road_cache", Vector2i(-7, 2)))
	assert_true(main.hud.log_label.text.contains("Opened Roadside Cache."))
	assert_true(main.get_debug_state()["target_detail"].contains("Container: opened"))
	main._handle_interact_requested()
	assert_eq(main.inventory.get_count("item_gold_coin"), 22)
	assert_true(main.hud.log_label.text.contains("Roadside Cache is already open."))
	_select_entity(main, "object_warden_cache")
	assert_true(main.get_debug_state()["target_detail"].contains("Container: closed"))
	main._handle_interact_requested()
	assert_eq(main.inventory.get_count("item_gold_coin"), 23)
	assert_true(main.get_debug_state()["target_detail"].contains("Container: opened"))
	main.hud.toggle_systems()
	main.hud.set_systems_tab("inventory")
	assert_true(main.hud.systems_body_label.text.contains("Gold Coin x23"))
	main.hud.set_systems_tab("character")
	assert_true(main.hud.systems_body_label.text.contains("XP: 12/40"))
	main.hud.toggle_systems()

	_select_kind(main, "rest")
	main._handle_interact_requested()
	assert_eq(main.player.health, main.player.max_health)
	assert_eq(main.time.get_summary(), "Day 2, 16:00 (Afternoon)")


func test_main_sanitizes_malformed_runtime_pickup_fields() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "pickup_old_toolbox")
	var pickup = main._get_nearby_entity()
	pickup.data["count"] = "many"
	pickup.data["effects_on_pickup"] = "bad"

	main._handle_interact_requested()

	assert_eq(main.inventory.get_count("item_old_toolbox"), 1)
	assert_eq(main.quests.get_quest_state("quest_missing_tools"), "inactive")
	assert_null(main.entities.get_entity("pickup_old_toolbox"))


func test_main_sanitizes_malformed_runtime_enemy_numbers() -> void:
	var main := Main.new()
	add_child_autofree(main)

	var enemy = main.entities.get_entity("enemy_road_thug")
	assert_not_null(enemy)
	enemy.data["max_health"] = "twelve"
	enemy.data["damage_taken_per_hit"] = "six"
	enemy.data["attack_damage"] = "four"

	assert_eq(main._target_detail_text(enemy), "Enemy HP 12/12, counter 4")

	_attack_enemy_once(main, "enemy_road_thug")

	assert_eq(main.player.health, 100)
	assert_eq(main.combat.health_by_entity_id["enemy_road_thug"], 10)


func test_main_sanitizes_malformed_runtime_rest_amount() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.player.apply_damage(40)

	_select_kind(main, "rest")
	var rest = main._get_nearby_entity()
	rest.data["heal_amount"] = "full"

	assert_eq(main.get_debug_state()["target_detail"], "Rest: heals 100, advances 8h")

	main._handle_interact_requested()

	assert_eq(main.player.health, main.player.max_health)
	assert_eq(main.time.get_summary(), "Day 1, 16:00 (Afternoon)")


func test_main_inventory_text_skips_malformed_live_counts() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.inventory.items = {"item_gold_coin": 3, "item_old_toolbox": "many", "item_negative": -4}

	var state := main.get_debug_state()

	assert_eq(state["inventory"], "Gold Coin x3")
	assert_true(state["inventory_details"].contains("Gold Coin x3:"))
	assert_false(state["inventory_details"].contains("Old Toolbox"))
	assert_false(state["inventory_details"].contains("item_negative"))


func test_player_defeat_recovers_at_spawn() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var defeat_sources: Array[String] = []
	main.event_bus.player_defeated.connect(
		func(source: String) -> void: defeat_sources.append(source)
	)

	main.player.set_world_position(Vector2(-24.0, 24.0))
	main.player.set_health(2)

	main._handle_player_defeated("Road Thug")

	assert_eq(defeat_sources, ["Road Thug"])
	assert_eq(main.player.health, main.player.max_health)
	assert_eq(main.player.global_tile, Vector2i.ZERO)
	assert_not_null(main.entities.get_entity("enemy_road_thug"))


func test_main_save_load_restores_spawn_yard_system_state() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.save_manager.save_path = TEST_SAVE_PATH

	_select_entity(main, "pickup_old_toolbox")
	main._handle_interact_requested()
	_attack_enemy_once(main, "enemy_road_thug")
	_select_entity(main, "object_road_cache")
	main._handle_interact_requested()
	assert_true(main.time.advance_hours(6))

	assert_true(main.save_manager.save_game())
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH))

	main.inventory.remove_item("item_old_toolbox", 1)
	main.equipment.equipped_by_slot = {"weapon": "item_road_hatchet"}
	main.player.set_health(7)
	main.combat.clear_entity("enemy_road_thug")
	main.time.load_save_data({})
	main.chunks.mark_entity_removed("enemy_road_thug", Vector2i(-4, 2))
	main.entities.spawn_all()
	assert_null(main.entities.get_entity("enemy_road_thug"))

	assert_true(main.save_manager.load_game())

	assert_eq(main.player.health, 100)
	assert_eq(main.equipment.get_equipped_item("weapon"), "")
	assert_true(main.inventory.has_item("item_old_toolbox"))
	assert_eq(main.quests.quests["quest_missing_tools"]["stage"], "found_toolbox")
	assert_eq(main.combat.health_by_entity_id["enemy_road_thug"], 10)
	assert_true(main.chunks.is_object_opened("object_road_cache", Vector2i(-7, 2)))
	assert_eq(main.inventory.get_count("item_gold_coin"), 2)
	assert_eq(main.progression.level, 1)
	assert_eq(main.progression.experience, 2)
	assert_eq(main.time.get_summary(), "Day 1, 14:00 (Afternoon)")
	assert_not_null(main.entities.get_entity("enemy_road_thug"))


func test_main_save_load_preserves_defeated_enemy_and_loot() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.save_manager.save_path = TEST_SAVE_PATH

	_attack_enemy_until_defeated(main, "enemy_road_thug")

	assert_null(main.entities.get_entity("enemy_road_thug"))
	assert_true(main.world_state.has_flag("flag_spawn_enemy_defeated"))
	assert_eq(main.inventory.get_count("item_gold_coin"), 3)
	assert_eq(main.factions.get_reputation("faction_road_bandits"), -5)
	assert_eq(main.progression.experience, 10)
	assert_false(main.combat.health_by_entity_id.has("enemy_road_thug"))

	assert_true(main.save_manager.save_game())

	main.inventory.remove_item("item_gold_coin", 3)
	main.factions.reputation_by_faction_id.clear()
	main.progression.load_save_data({})
	main.world_state.flags.clear()
	main.chunks.modified_chunks.clear()
	main.entities.spawn_all()
	assert_not_null(main.entities.get_entity("enemy_road_thug"))

	assert_true(main.save_manager.load_game())

	assert_null(main.entities.get_entity("enemy_road_thug"))
	assert_true(main.world_state.has_flag("flag_spawn_enemy_defeated"))
	assert_eq(main.inventory.get_count("item_gold_coin"), 3)
	assert_eq(main.factions.get_reputation("faction_road_bandits"), -5)
	assert_eq(main.progression.experience, 10)
	assert_false(main.combat.health_by_entity_id.has("enemy_road_thug"))


func _select_kind(main, kind: String) -> void:
	for candidate in main.entities.entities_by_id.values():
		if candidate and candidate.get_kind() == kind:
			main.player.set_world_position(candidate.global_position + Vector2(-8.0, 0.0))
			main.player.set_facing_direction(Vector2.RIGHT)
			main._update_nearby()
			break
	for _i in range(24):
		var entity = main._get_nearby_entity()
		if entity and entity.get_kind() == kind:
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby kind: %s" % kind)


func _stand_by_enemy(main, entity_id: String) -> void:
	var enemy = main.entities.get_entity(entity_id)
	assert_not_null(enemy)
	main.player.set_world_position(enemy.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	main._update_nearby()


func _attack_enemy_once(main, entity_id: String) -> void:
	_stand_by_enemy(main, entity_id)
	MainSystemsActions.handle_aim(main, "attack", Vector2.RIGHT)


func _attack_enemy_until_defeated(main, entity_id: String) -> void:
	for _i in range(8):
		if not main.entities.get_entity(entity_id):
			return
		_attack_enemy_once(main, entity_id)
	assert_null(main.entities.get_entity(entity_id))


func _select_entity(main, entity_id: String) -> void:
	var target = main.entities.get_entity(entity_id)
	if target:
		main.player.set_world_position(target.global_position + Vector2(-8.0, 0.0))
		main.player.set_facing_direction(Vector2.RIGHT)
		main._update_nearby()
	for _i in range(24):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)


func _button_containing(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text.contains(text):
			return child
	return null


func _choose_content(main, text: String) -> void:
	var button := _button_containing(main.hud.content_choice_list, text)
	assert_not_null(button)
	button.pressed.emit()


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
