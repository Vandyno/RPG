extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainFlowInputHelper = preload("res://tests/unit/main/flows/main_flow_input_helper.gd")


func test_real_pointer_can_arrive_enter_hall_and_complete_local_quest() -> void:
	var main := Main.new()
	add_child_autofree(main)
	await MainFlowInputHelper.settle(main, get_tree())
	assert_true(await _click_entity(main, "object_briarwatch_northgate_coach"))
	assert_eq(main.player.world_layer, "surface")
	assert_true(main.player.global_tile.distance_to(Vector2i(-3252, -3932)) < 3.0)

	assert_true(await _click_entity(main, "portal_structure_northgate_hall_plot_entry"))
	assert_eq(main.player.world_layer, "interior:structure_northgate_hall_plot")
	assert_true(await _click_entity(main, "poi_northgate_notice_board"))
	if main.quests.get_quest_state("quest_northgate_missing_manifest") == "inactive":
		var take_button := MainFlowInputHelper.button_containing(
			main.hud.content_choice_list, "Take Missing Manifest Job"
		)
		assert_not_null(take_button)
		await MainFlowInputHelper.click(take_button, get_tree())
	assert_eq(main.quests.get_quest_state("quest_northgate_missing_manifest"), "active")
	var searching_storekeeper: Dictionary = main.civilian_schedules.get_schedule_debug("npc_northgate_storekeeper")
	assert_eq(searching_storekeeper["activity"], "quest")
	assert_eq(searching_storekeeper["destination_id"], "northgate_store_ledger_runtime")
	assert_eq(searching_storekeeper["activity_action"], "search the ledger desk")

	assert_true(await _click_entity(main, "portal_structure_northgate_hall_plot_exit"))
	assert_true(await _click_entity(main, "portal_structure_northgate_store_plot_entry"))
	assert_true(await _click_entity(main, "pickup_northgate_missing_manifest"))
	assert_true(main.inventory.has_item("item_northgate_trade_manifest"))
	assert_eq(main.quests.quests["quest_northgate_missing_manifest"]["stage"], "found")

	assert_true(await _click_entity(main, "portal_structure_northgate_store_plot_exit"))
	assert_true(await _click_entity(main, "portal_structure_northgate_hall_plot_entry"))
	assert_true(await _click_entity(main, "poi_northgate_notice_board"))
	if main.quests.get_quest_state("quest_northgate_missing_manifest") != "completed":
		var return_button := MainFlowInputHelper.button_containing(
			main.hud.content_choice_list, "Return Trade Manifest"
		)
		assert_not_null(return_button)
		await MainFlowInputHelper.click(return_button, get_tree())
	assert_eq(main.quests.get_quest_state("quest_northgate_missing_manifest"), "completed")
	assert_false(main.inventory.has_item("item_northgate_trade_manifest"))
	assert_eq(main.inventory.get_count("item_gold_coin"), 12)
	var resumed_storekeeper: Dictionary = main.civilian_schedules.get_schedule_debug("npc_northgate_storekeeper")
	assert_false(resumed_storekeeper.has("quest_routine"))
	assert_false(resumed_storekeeper.has("interruption"))


func test_real_pointer_reaches_inn_trade_smith_repair_notice_and_storage() -> void:
	var main := Main.new()
	add_child_autofree(main)
	await MainFlowInputHelper.settle(main, get_tree())
	assert_true(await _click_entity(main, "object_briarwatch_northgate_coach"))

	assert_true(await _click_entity(main, "portal_structure_northgate_inn_plot_entry"))
	main.player.apply_damage(30)
	var before_time := main.time.minute_of_day
	assert_true(await _click_entity(main, "object_northgate_inn_bed"))
	assert_eq(main.player.health, main.player.max_health)
	assert_ne(main.time.minute_of_day, before_time)
	assert_true(await _click_entity(main, "portal_structure_northgate_inn_plot_exit"))

	main.time.minute_of_day = 8 * 60
	assert_true(await _click_entity(main, "portal_structure_northgate_shop_plot_entry"))
	assert_true(await _click_entity(main, "npc_northgate_shopkeeper_world"))
	var trade_button := MainFlowInputHelper.button_containing(main.hud.content_choice_list, "Trade")
	assert_not_null(trade_button)
	await MainFlowInputHelper.click(trade_button, get_tree())
	assert_true(main.hud.is_systems_panel_visible())
	assert_eq(main.hud.get_systems_tab(), "trade")
	main.hud.hide_systems_panel()
	assert_true(await _click_entity(main, "portal_structure_northgate_shop_plot_exit"))

	assert_true(await _click_entity(main, "portal_structure_northgate_smith_plot_entry"))
	assert_true(await _click_entity(main, "npc_northgate_smith_world"))
	var smith_button := MainFlowInputHelper.button_containing(
		main.hud.content_choice_list, "Browse smithing stock"
	)
	assert_not_null(smith_button)
	await MainFlowInputHelper.click(smith_button, get_tree())
	assert_eq(main.hud.get_systems_tab(), "trade")
	main.hud.hide_systems_panel()
	if not main.inventory.has_item("item_training_sword"):
		assert_true(main.inventory.add_item("item_training_sword", 1))
	if main.equipment.get_equipped_item("right_hand") != "item_training_sword":
		assert_true(main.equipment.equip_item_to_slot("item_training_sword", "right_hand"))
	assert_eq(main.equipment.damage_equipped(35), 1)
	assert_eq(main.equipment.get_condition("item_training_sword"), 65)
	main.inventory.add_item("item_gold_coin", 5)
	var gold_before_repair := main.inventory.get_count("item_gold_coin")
	assert_true(await _click_entity(main, "poi_northgate_repair_bench"))
	var repair_button := MainFlowInputHelper.button_containing(
		main.hud.content_choice_list, "Repair Equipped Gear"
	)
	if main.equipment.get_condition("item_training_sword") < 100:
		assert_not_null(repair_button)
		await MainFlowInputHelper.click(repair_button, get_tree())
	assert_eq(main.equipment.get_condition("item_training_sword"), 100)
	assert_eq(main.inventory.get_count("item_gold_coin"), gold_before_repair - 5)
	assert_true(await _click_entity(main, "portal_structure_northgate_smith_plot_exit"))

	assert_true(await _click_entity(main, "portal_structure_northgate_hall_plot_entry"))
	assert_true(await _click_entity(main, "object_northgate_road_notice"))
	assert_true(main.readables.has_read("readable_northgate_road_notice"))
	assert_true(await _click_entity(main, "portal_structure_northgate_hall_plot_exit"))

	main.inventory.add_item("item_gold_coin", 1)
	assert_true(await _click_entity(main, "portal_structure_northgate_store_plot_entry"))
	assert_true(await _click_entity(main, "object_northgate_player_storage"))
	var put_coin := main.hud.systems_item_list.find_child("TransferPut_ItemGoldCoin", true, false) as Button
	assert_not_null(put_coin)
	await MainFlowInputHelper.click(put_coin, get_tree())
	assert_eq(main.inventory.get_count_for_owner("storage_northgate_player", "item_gold_coin"), 1)


func test_wounded_shopkeeper_flees_home_and_recovers_before_routine_resume() -> void:
	var main := Main.new()
	add_child_autofree(main)
	await MainFlowInputHelper.settle(main, get_tree())
	assert_true(await _click_entity(main, "object_briarwatch_northgate_coach"))
	assert_true(await _click_entity(main, "portal_structure_northgate_shop_plot_entry"))

	var shopkeeper = main.entities.get_entity("npc_northgate_shopkeeper_world")
	assert_not_null(shopkeeper)
	main.player.set_world_position(shopkeeper.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	main._update_nearby()
	await MainFlowInputHelper.settle(main, get_tree())
	var attack_control := main.hud.primary_action_button
	assert_eq(String(attack_control.get_meta("action_kind", "")), "attack")

	await MainFlowInputHelper.drag(attack_control, Vector2(56.0, 0.0), get_tree())
	shopkeeper = main.entities.get_entity("npc_northgate_shopkeeper_world")
	main.player.set_world_position(shopkeeper.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	main._update_nearby()
	await MainFlowInputHelper.settle(main, get_tree())
	attack_control = main.hud.primary_action_button
	await MainFlowInputHelper.drag(attack_control, Vector2(56.0, 0.0), get_tree())
	# The pointer attacks prove the live combat path; finish the wounded state
	# deterministically so this test isolates civilian danger response.
	main.combat.health_by_entity_id[shopkeeper.get_entity_id()] = 3
	main.set_process(false)
	shopkeeper = main.entities.get_entity("npc_northgate_shopkeeper_world")
	assert_not_null(shopkeeper)
	assert_eq(main.combat.get_entity_health(shopkeeper), 3)

	main.civilian_schedules.update(0.1)
	var fleeing: Dictionary = main.civilian_schedules.get_schedule_debug("npc_northgate_shopkeeper")
	assert_eq(fleeing["activity"], "flee")
	assert_eq(fleeing["interruption"]["reason"], "flee")

	shopkeeper.set_world_layer(String(fleeing["destination_layer"]))
	var home_tile: Array = fleeing["destination_tile"]
	shopkeeper.set_global_tile(Vector2i(int(home_tile[0]), int(home_tile[1])))
	main.civilian_schedules.update(0.1)
	var recovering: Dictionary = main.civilian_schedules.get_schedule_debug("npc_northgate_shopkeeper")
	assert_eq(recovering["activity"], "recover")
	assert_eq(recovering["interruption"]["reason"], "recovering")

	main.time.advance_minutes(60)
	main.civilian_schedules.update(0.1)
	var resumed: Dictionary = main.civilian_schedules.get_schedule_debug("npc_northgate_shopkeeper")
	assert_false(resumed.has("interruption"))
	assert_eq(resumed["activity"], "work")
	assert_eq(main.combat.get_entity_health(shopkeeper), int(shopkeeper.data["max_health"]))


func _click_entity(main, entity_id: String) -> bool:
	var source := _content_entry(main, entity_id)
	if source.is_empty():
		return false
	var source_layer := String(source.get("world_layer", "surface"))
	if main.player.world_layer != source_layer:
		main.player.set_world_layer(source_layer)
		main.world_query.set_layer(source_layer)
	var tile_data: Array = source.get("global_tile", [])
	if tile_data.size() < 2:
		return false
	var tile := Vector2i(int(tile_data[0]), int(tile_data[1]))
	main.player.set_global_tile(tile + Vector2i.LEFT)
	main.streamer.update_center(main.player.global_tile, main.player.world_layer)
	await MainFlowInputHelper.settle(main, get_tree())
	var entity = main.entities.get_entity(entity_id)
	if not is_instance_valid(entity):
		return false
	main.player.set_facing_direction(Vector2.RIGHT)
	await MainFlowInputHelper.world_click(main, entity.global_position, get_tree())
	if (
		["poi", "npc"].has(String(source.get("kind", "")))
		and not main.hud.is_content_card_visible()
		and not main.hud.is_systems_panel_visible()
	):
		entity = main.entities.get_entity(entity_id)
		if is_instance_valid(entity):
			await MainFlowInputHelper.world_click(main, entity.global_position, get_tree())
	return true


func _content_entry(main, entity_id: String) -> Dictionary:
	for entry in main.content.world_object_entries():
		if String(entry.get("id", "")) == entity_id:
			return entry
	return {}
