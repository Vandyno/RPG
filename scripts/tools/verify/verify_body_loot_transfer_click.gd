# gdlint:disable=max-returns
extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const MainSystemsActions = preload("res://scripts/main/actions/main_systems_actions.gd")
const VerifyInputHelper = preload("res://scripts/tools/verify/verify_input_helper.gd")

const VERIFY_SIZE := Vector2i(1152, 648)
const TRANSFER_OFFSET := Vector2(-8.0, 0.0)
const ROAD_THUG_ID := "npc_road_thug"
const ROAD_THUG_BODY_ID := "body_npc_road_thug"
const ROAD_CACHE_ID := "object_road_cache"
const PEOPLE_TEST_ID := "npc_people_test_human"
const PEOPLE_TEST_BODY_ID := "body_npc_people_test_human"
const TAKE_BOW_BUTTON := "TransferTake_ItemHuntingBow"
const PUT_BOW_BUTTON := "TransferPut_ItemHuntingBow"
const TAKE_GOLD_BUTTON := "TransferTake_ItemGoldCoin"
const PUT_GOLD_BUTTON := "TransferPut_ItemGoldCoin"
const TAKE_SWORD_BUTTON := "TransferTake_ItemTrainingSword"


func _initialize() -> void:
	_verify.call_deferred()


func _verify() -> void:
	root.size = VERIFY_SIZE
	var main := Main.new()
	root.add_child(main)
	await _settle(main)
	main.inventory.add_item("item_hunting_bow", 1)
	main.inventory.add_item("item_training_sword", 1)

	_open_body_transfer(main)
	await _settle(main)

	var body_pane: Node = main.hud.systems_item_list.find_child(
		"TransferTargetInventory", true, false
	)
	var take_bow := VerifyInputHelper.find_button(body_pane, TAKE_BOW_BUTTON)
	if not take_bow:
		printerr("Hunting Bow transfer button missing.")
		quit(1)
		return
	await VerifyInputHelper.real_click_button(self, root, take_bow)
	await process_frame

	if main.inventory.get_count("item_hunting_bow") != 2:
		printerr("Clicked Hunting Bow did not move to player inventory.")
		quit(1)
		return
	if main.inventory.get_count_for_owner("char_road_thug", "item_hunting_bow") != 0:
		printerr("Clicked Hunting Bow did not leave body inventory.")
		quit(1)
		return

	var pack_pane: Node = main.hud.systems_item_list.find_child(
		"TransferPlayerInventory", true, false
	)
	var put_bow := VerifyInputHelper.find_button(pack_pane, PUT_BOW_BUTTON)
	if not put_bow:
		printerr("Hunting Bow put-back button missing.")
		quit(1)
		return
	await VerifyInputHelper.real_click_button(self, root, put_bow)
	await process_frame
	if main.inventory.get_count("item_hunting_bow") != 1:
		printerr("Clicked Hunting Bow did not move back to body inventory.")
		quit(1)
		return

	main.hud.hide_systems_panel()
	await _settle(main)
	if not main.active_transfer_owner_id.is_empty():
		printerr("Closing transfer did not clear active transfer owner.")
		quit(1)
		return

	_open_cache_transfer(main)
	await _settle(main)
	var cache_pane: Node = main.hud.systems_item_list.find_child(
		"TransferTargetInventory", true, false
	)
	var take_gold := VerifyInputHelper.find_button(cache_pane, TAKE_GOLD_BUTTON)
	if not take_gold:
		printerr("Gold Coin take button missing.")
		quit(1)
		return
	await VerifyInputHelper.real_click_button(self, root, take_gold)
	await process_frame
	if main.inventory.get_count("item_gold_coin") != 4:
		printerr("Clicked Gold Coin did not move to player inventory.")
		quit(1)
		return
	if main.inventory.get_count_for_owner("loot:object_road_cache", "item_gold_coin") != 1:
		printerr("Clicked Gold Coin did not leave cache inventory.")
		quit(1)
		return

	var cache_pack_pane: Node = main.hud.systems_item_list.find_child(
		"TransferPlayerInventory", true, false
	)
	var put_gold := VerifyInputHelper.find_button(cache_pack_pane, PUT_GOLD_BUTTON)
	if not put_gold:
		printerr("Gold Coin put-back button missing.")
		quit(1)
		return
	await VerifyInputHelper.real_click_button(self, root, put_gold)
	await process_frame
	if main.inventory.get_count("item_gold_coin") != 3:
		printerr("Clicked Gold Coin did not move back to cache inventory.")
		quit(1)
		return
	if main.inventory.get_count_for_owner("loot:object_road_cache", "item_gold_coin") != 2:
		printerr("Clicked Gold Coin did not return to cache inventory.")
		quit(1)
		return

	main.hud.hide_systems_panel()
	await _settle(main)
	_open_people_body_transfer(main)
	await _settle(main)
	var people_body_pane: Node = main.hud.systems_item_list.find_child(
		"TransferTargetInventory", true, false
	)
	var take_people_gold := VerifyInputHelper.find_button(
		people_body_pane,
		TAKE_GOLD_BUTTON
	)
	if not take_people_gold:
		printerr("People body Gold Coin take button missing.")
		quit(1)
		return
	await VerifyInputHelper.real_click_button(self, root, take_people_gold)
	await process_frame
	if main.inventory.get_count("item_gold_coin") != 4:
		printerr("Clicked people body Gold Coin did not move to player inventory.")
		quit(1)
		return
	if main.inventory.get_count_for_owner("char_people_test_human", "item_gold_coin") != 0:
		printerr("Clicked people body Gold Coin did not leave body inventory.")
		quit(1)
		return

	var people_pack_pane: Node = main.hud.systems_item_list.find_child(
		"TransferPlayerInventory", true, false
	)
	var put_people_gold := VerifyInputHelper.find_button(
		people_pack_pane,
		PUT_GOLD_BUTTON
	)
	if not put_people_gold:
		printerr("People body Gold Coin put button missing.")
		quit(1)
		return
	await VerifyInputHelper.real_click_button(self, root, put_people_gold)
	await process_frame
	if main.inventory.get_count("item_gold_coin") != 3:
		printerr("Clicked people body Gold Coin did not move back to body inventory.")
		quit(1)
		return
	if main.inventory.get_count_for_owner("char_people_test_human", "item_gold_coin") != 1:
		printerr("Clicked people body Gold Coin did not return to body inventory.")
		quit(1)
		return

	people_body_pane = main.hud.systems_item_list.find_child(
		"TransferTargetInventory", true, false
	)
	var take_people_sword := VerifyInputHelper.find_button(
		people_body_pane,
		TAKE_SWORD_BUTTON
	)
	if not take_people_sword:
		printerr("People body Training Sword take button missing.")
		quit(1)
		return
	await VerifyInputHelper.real_click_button(self, root, take_people_sword)
	await process_frame
	if main.inventory.get_count("item_training_sword") != 2:
		printerr("Clicked people body Training Sword did not move to player inventory.")
		quit(1)
		return
	if main.inventory.get_count_for_owner("char_people_test_human", "item_training_sword") != 0:
		printerr("Clicked people body Training Sword did not leave body inventory.")
		quit(1)
		return

	print("Body and chest transfer clicks verified.")
	quit()


func _open_body_transfer(main) -> void:
	var enemy = main.entities.get_entity(ROAD_THUG_ID)
	main.player.set_world_position(enemy.global_position + TRANSFER_OFFSET)
	main.player.set_facing_direction(Vector2.RIGHT)
	for _index in range(8):
		if not main.entities.get_entity(ROAD_THUG_ID):
			break
		MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.RIGHT)
	_open_transfer_target(main, main.entities.get_entity(ROAD_THUG_BODY_ID), root.size)


func _open_cache_transfer(main) -> void:
	_open_transfer_target(main, main.entities.get_entity(ROAD_CACHE_ID), root.size)


func _open_people_body_transfer(main) -> void:
	var enemy = main.entities.get_entity(PEOPLE_TEST_ID)
	main.player.set_world_position(enemy.global_position + TRANSFER_OFFSET)
	main.player.set_facing_direction(Vector2.RIGHT)
	for _index in range(8):
		if not main.entities.get_entity(PEOPLE_TEST_ID):
			break
		MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.RIGHT)
	_open_transfer_target(main, main.entities.get_entity(PEOPLE_TEST_BODY_ID), root.size)


static func expected_transfer_button_names() -> Array[String]:
	return [
		TAKE_BOW_BUTTON,
		PUT_BOW_BUTTON,
		TAKE_GOLD_BUTTON,
		PUT_GOLD_BUTTON,
		TAKE_SWORD_BUTTON
	]


static func _open_transfer_target(main, entity, viewport_size: Vector2i) -> void:
	main.player.set_world_position(entity.global_position + TRANSFER_OFFSET)
	main.player.set_facing_direction(Vector2.RIGHT)
	main.selected_target_id = entity.get_entity_id()
	main.manual_target_locked = true
	main._update_nearby()
	main._handle_interact_requested()
	main.hud._apply_layout_for_size(Vector2(viewport_size))
	main.hud.set_systems_tab("inventory")


func _settle(main) -> void:
	await VerifyInputHelper.settle_main(self, main, root.size)
