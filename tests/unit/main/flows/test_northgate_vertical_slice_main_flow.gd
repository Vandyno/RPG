extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainFlowInputHelper = preload("res://tests/unit/main/flows/main_flow_input_helper.gd")

const SURFACE_ENTRY_IDS := [
	"portal_structure_northgate_shrine_plot_entry",
	"portal_structure_northgate_guard_plot_entry",
	"portal_structure_northgate_hall_plot_entry",
	"portal_structure_northgate_inn_plot_entry",
	"portal_structure_northgate_stable_plot_entry",
	"portal_structure_northgate_shop_plot_entry",
	"portal_structure_northgate_store_plot_entry",
	"portal_structure_northgate_west_home_plot_entry",
	"portal_structure_northgate_south_home_plot_entry",
	"portal_structure_northgate_smith_plot_entry",
	"portal_structure_northgate_east_home_plot_entry",
	"portal_structure_northgate_southeast_home_plot_entry",
	"portal_structure_northgate_far_east_home_plot_entry"
]
const TEST_SAVE_PATH := "user://northgate_vertical_slice_test.json"


func before_each() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))


func after_each() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))


func test_pointer_coach_arrival_and_all_thirteen_building_portals() -> void:
	var main := Main.new()
	add_child_autofree(main)
	await MainFlowInputHelper.settle(main, get_tree())

	assert_true(await _pointer_use(main, "object_briarwatch_northgate_coach"))
	assert_eq(main.player.world_layer, "surface")
	assert_lt(main.player.global_tile.distance_to(Vector2i(-3237, -3940)), 4.0)

	for entry_id in SURFACE_ENTRY_IDS:
		assert_true(await _pointer_use(main, entry_id), entry_id)
		assert_ne(main.player.world_layer, "surface", entry_id)
		var exit_id: String = String(entry_id).trim_suffix("_entry") + "_exit"
		assert_true(await _pointer_use(main, exit_id), exit_id)
		assert_eq(main.player.world_layer, "surface", exit_id)
	assert_true(await _pointer_use(main, "object_northgate_briarwatch_coach"))
	assert_lt(main.player.global_tile.distance_to(Vector2i(10, 8)), 3.0)

	assert_true(await _pointer_use(main, "object_northgate_briarwatch_coach"))
	assert_lt(main.player.global_tile.distance_to(Vector2i(10, 8)), 3.0)


func test_pointer_inn_trade_repair_and_persistent_storage_services() -> void:
	var main := Main.new()
	add_child_autofree(main)
	await MainFlowInputHelper.settle(main, get_tree())
	assert_true(await _pointer_use(main, "object_briarwatch_northgate_coach"))

	assert_eq(main._current_location_name(), "Northgate")
	assert_true(await _pointer_use(main, "portal_structure_northgate_inn_plot_entry"))
	main.player.health = 2
	var start_minute: int = main.time.minute_of_day
	assert_true(await _pointer_use(main, "object_northgate_inn_bed"))
	assert_eq(main.player.health, main.player.max_health)
	assert_ne(main.time.minute_of_day, start_minute)
	assert_true(await _pointer_use(main, "portal_structure_northgate_inn_plot_exit"))

	main.time.minute_of_day = 8 * 60
	main.time._emit_changed()
	assert_true(await _pointer_use(main, "portal_structure_northgate_shop_plot_entry"))
	assert_true(await _pointer_use(main, "npc_northgate_shopkeeper_world"))
	var trade_button := MainFlowInputHelper.button_containing(main.hud.content_choice_list, "Trade")
	assert_not_null(trade_button)
	await MainFlowInputHelper.click(trade_button, get_tree())
	assert_true(main.hud.is_systems_panel_visible())
	main.inventory.add_item("item_gold_coin", 40)
	main.hud.refresh()
	var buy_button := MainFlowInputHelper.button_containing(main.hud, "Buy Leather Boots")
	assert_not_null(buy_button)
	await MainFlowInputHelper.click(buy_button, get_tree())
	assert_eq(main.inventory.get_count("item_leather_boots"), 1)
	main.hud.hide_systems_panel()
	assert_true(await _pointer_use(main, "portal_structure_northgate_shop_plot_exit"))

	main.inventory.add_item("item_road_hatchet", 1)
	assert_true(main.equipment.equip_item_to_slot("item_road_hatchet", "right_hand"))
	assert_eq(main.equipment.damage_equipped(25), 1)
	var gold_before: int = main.inventory.get_count("item_gold_coin")
	assert_true(await _pointer_use(main, "portal_structure_northgate_smith_plot_entry"))
	assert_true(await _pointer_use(main, "npc_northgate_smith_world"))
	var smith_button := MainFlowInputHelper.button_containing(
		main.hud.content_choice_list, "Browse smithing stock"
	)
	assert_not_null(smith_button)
	if smith_button:
		await MainFlowInputHelper.click(smith_button, get_tree())
		assert_true(main.hud.is_systems_panel_visible())
		main.hud.hide_systems_panel()
	assert_true(await _pointer_use(main, "poi_northgate_repair_bench"))
	var repair_button := MainFlowInputHelper.button_containing(
		main.hud.content_choice_list, "Repair Equipped Gear"
	)
	if main.equipment.get_condition("item_road_hatchet") < 100:
		assert_not_null(repair_button)
		await MainFlowInputHelper.click(repair_button, get_tree())
	assert_eq(main.equipment.get_condition("item_road_hatchet"), 100)
	assert_eq(main.inventory.get_count("item_gold_coin"), gold_before - 5)
	assert_true(await _pointer_use(main, "portal_structure_northgate_smith_plot_exit"))

	assert_true(main.equipment.unequip_slot("right_hand"))
	assert_true(await _pointer_use(main, "portal_structure_northgate_store_plot_entry"))
	assert_true(await _pointer_use(main, "object_northgate_player_storage"))
	var put_button := main.hud.systems_item_list.find_child(
		"TransferPut_ItemGoldCoin", true, false
	) as Button
	assert_not_null(put_button)
	await MainFlowInputHelper.click(put_button, get_tree())
	assert_eq(
		main.inventory.get_count_for_owner("storage_northgate_player", "item_gold_coin"),
		1
	)
	var saved_layer: String = main.player.world_layer
	var saved_tile: Vector2i = main.player.global_tile
	main.save_manager.save_path = TEST_SAVE_PATH
	assert_true(main.save_manager.save_game().ok)
	main.inventory.transfer_item(
		"storage_northgate_player", "char_player", "item_gold_coin", 1
	)
	main.player.set_world_layer("surface")
	main.player.set_global_tile(Vector2i.ZERO)
	assert_true(main.save_manager.load_game().ok)
	assert_eq(
		main.inventory.get_count_for_owner("storage_northgate_player", "item_gold_coin"),
		1
	)
	assert_eq(main.player.world_layer, saved_layer)
	assert_eq(main.player.global_tile, saved_tile)
	assert_eq(main.equipment.get_condition("item_road_hatchet"), 100)
	assert_true(main.world_state.has_flag("flag_northgate_storage_used"))


func test_pointer_notice_board_completes_local_manifest_quest() -> void:
	var main := Main.new()
	add_child_autofree(main)
	await MainFlowInputHelper.settle(main, get_tree())
	assert_true(await _pointer_use(main, "object_briarwatch_northgate_coach"))
	assert_true(await _pointer_use(main, "portal_structure_northgate_hall_plot_entry"))
	assert_true(await _pointer_use(main, "poi_northgate_notice_board"))
	if main.quests.get_quest_state("quest_northgate_missing_manifest") == "inactive":
		var take_button := MainFlowInputHelper.button_containing(
			main.hud.content_choice_list, "Take Missing Manifest Job"
		)
		assert_not_null(take_button)
		await MainFlowInputHelper.click(take_button, get_tree())
	assert_eq(main.quests.get_quest_state("quest_northgate_missing_manifest"), "active")
	assert_true(await _pointer_use(main, "portal_structure_northgate_hall_plot_exit"))

	assert_true(await _pointer_use(main, "portal_structure_northgate_store_plot_entry"))
	assert_true(await _pointer_use(main, "pickup_northgate_missing_manifest"))
	assert_true(main.inventory.has_item("item_northgate_trade_manifest"))
	assert_eq(main.quests.quests["quest_northgate_missing_manifest"]["stage"], "found")
	assert_true(await _pointer_use(main, "portal_structure_northgate_store_plot_exit"))

	assert_true(await _pointer_use(main, "portal_structure_northgate_hall_plot_entry"))
	assert_true(await _pointer_use(main, "poi_northgate_notice_board"))
	if main.quests.get_quest_state("quest_northgate_missing_manifest") != "completed":
		var return_button := MainFlowInputHelper.button_containing(
			main.hud.content_choice_list, "Return Trade Manifest"
		)
		assert_not_null(return_button)
		await MainFlowInputHelper.click(return_button, get_tree())
	assert_eq(main.quests.get_quest_state("quest_northgate_missing_manifest"), "completed")
	assert_false(main.inventory.has_item("item_northgate_trade_manifest"))
	assert_true(await _pointer_use(main, "object_northgate_road_notice"))
	assert_true(main.readables.has_read("readable_northgate_road_notice"))
	main.save_manager.save_path = TEST_SAVE_PATH
	assert_true(main.save_manager.save_game().ok)
	main.quests.load_save_data({})
	main.readables.load_save_data({})
	assert_eq(main.quests.get_quest_state("quest_northgate_missing_manifest"), "inactive")
	assert_false(main.readables.has_read("readable_northgate_road_notice"))
	assert_true(main.save_manager.load_game().ok)
	assert_eq(main.quests.get_quest_state("quest_northgate_missing_manifest"), "completed")
	assert_true(main.readables.has_read("readable_northgate_road_notice"))


func _pointer_use(main, entity_id: String) -> bool:
	var source: Dictionary = _content_entry(main, entity_id)
	if source.is_empty():
		return false
	var source_layer := String(source.get("world_layer", "surface"))
	if main.player.world_layer != source_layer:
		main.player.set_world_layer(source_layer)
		main.world_query.set_layer(source_layer)
	var tile := Vector2i(int(source["global_tile"][0]), int(source["global_tile"][1]))
	main.player.set_global_tile(tile + Vector2i.LEFT)
	main.streamer.update_center(main.player.global_tile, main.player.world_layer)
	await MainFlowInputHelper.settle(main, get_tree())
	var entity = main.entities.get_entity(entity_id)
	if not entity:
		return false
	if entity.global_tile != tile:
		main.player.set_global_tile(entity.global_tile + Vector2i.LEFT)
		main.streamer.update_center(main.player.global_tile, main.player.world_layer)
		await MainFlowInputHelper.settle(main, get_tree())
		entity = main.entities.get_entity(entity_id)
		if not entity:
			return false
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
