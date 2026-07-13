# gdlint:disable=max-returns
extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const VerifyInputHelper = preload("res://scripts/tools/verify/verify_input_helper.gd")

const VERIFY_SIZE := Vector2i(1152, 648)
const FORGE_DOOR_ID := "object_harrow_forge_door"
const FORGE_EXIT_ID := "object_harrow_forge_exit"
const FORGE_LAYER := "interior:structure_briarwatch_harrow_forge"
const HARROW_ID := "npc_harrow_venn_world"
const HARROW_ACCEPT_TEXT := "I'll find it."
const MISSING_TOOLS_QUEST_ID := "quest_missing_tools"
const TOWN_SQUARE_ID := "poi_briarwatch_square"
const JOB_BOARD_TITLE := "Warden's Job Board"
const ROAD_PATROL_JOB_TEXT := "Take Road Patrol Job"
const ROAD_PATROL_QUEST_ID := "quest_briarwatch_road_patrol"
const ROAD_CACHE_ID := "object_road_cache"
const ROAD_CACHE_GOLD_BUTTON := "TransferTake_ItemGoldCoin"


func _initialize() -> void:
	_verify.call_deferred()


func _verify() -> void:
	root.size = VERIFY_SIZE
	var main := Main.new()
	root.add_child(main)
	await _settle(main)
	if not await VerifyInputHelper.start_new_game(self, root, main):
		_fail("New Game real click did not begin play.")
		return

	if not await _enter_forge(main):
		_fail("World click on Harrow's forge door did not enter the forge.")
		return
	move_near(main, HARROW_ID)
	await _settle(main)
	await VerifyInputHelper.world_click_entity(self, main, HARROW_ID)
	await _settle(main)
	if not main.hud.is_content_card_visible():
		_fail("World click on Harrow did not open dialogue.")
		return
	var accept := VerifyInputHelper.button_containing(main.hud.content_choice_list, HARROW_ACCEPT_TEXT)
	if not accept:
		_fail("Missing Harrow quest accept choice.")
		return
	await _click(accept)
	await _settle(main)
	if main.quests.get_quest_state(MISSING_TOOLS_QUEST_ID) != "active":
		_fail("Dialogue choice click did not start Missing Tools.")
		return

	await _close_content(main)
	if not await _exit_forge(main):
		_fail("World click on Harrow's forge exit did not return to town.")
		return
	move_near(main, TOWN_SQUARE_ID)
	await _settle(main)
	await VerifyInputHelper.world_click_entity(self, main, TOWN_SQUARE_ID)
	await _settle(main)
	if not main.hud.is_content_card_visible():
		_fail("World click on town square POI did not open place card.")
		return
	if not main.hud.content_title_label.text.contains(JOB_BOARD_TITLE):
		_fail("Town square POI did not show the job-board HUD card.")
		return
	var job := VerifyInputHelper.button_containing(
		main.hud.content_choice_list, ROAD_PATROL_JOB_TEXT
	)
	if not job:
		_fail("Missing road patrol job choice.")
		return
	await _click(job)
	await _settle(main)
	if main.quests.get_quest_state(ROAD_PATROL_QUEST_ID) != "active":
		_fail("POI choice click did not start Road Patrol.")
		return

	move_near(main, ROAD_CACHE_ID)
	await _settle(main)
	await VerifyInputHelper.world_click_entity(self, main, ROAD_CACHE_ID)
	await _settle(main)
	if not transfer_inventory_is_open(main):
		_fail("World click on road cache did not open transfer HUD.")
		return
	var take_gold := (
		main.hud.systems_item_list.find_child(ROAD_CACHE_GOLD_BUTTON, true, false) as Button
	)
	if not take_gold:
		_fail("Missing road cache gold transfer button.")
		return
	var before_gold: int = main.inventory.get_count("item_gold_coin")
	await _click(take_gold)
	await _settle(main)
	if main.inventory.get_count("item_gold_coin") != before_gold + 1:
		_fail("Transfer row real click did not move road cache gold.")
		return
	if not main.hud.is_systems_panel_visible() or main.hud.get_systems_tab() != "inventory":
		_fail("Transfer click did not leave the inventory HUD open.")
		return

	print("Spawn slice public input verified.")
	quit()


static func move_near(main, entity_id: String) -> bool:
	var entity = main.entities.get_entity(entity_id)
	if not entity:
		return false
	main.player.set_world_position(entity.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	return true


func _enter_forge(main) -> bool:
	move_near(main, FORGE_DOOR_ID)
	await _settle(main)
	await VerifyInputHelper.world_click_entity(self, main, FORGE_DOOR_ID)
	await _settle(main)
	return player_is_in_layer(main, FORGE_LAYER)


func _exit_forge(main) -> bool:
	move_near(main, FORGE_EXIT_ID)
	await _settle(main)
	await VerifyInputHelper.world_click_entity(self, main, FORGE_EXIT_ID)
	await _settle(main)
	return player_is_in_layer(main, "surface")


static func player_is_in_layer(main, layer_id: String) -> bool:
	return String(main.player.world_layer) == layer_id


static func transfer_inventory_is_open(main) -> bool:
	return (
		main.hud.is_systems_panel_visible()
		and bool(main.get_hud_state().get("transfer_open", false))
	)


func _close_content(main) -> void:
	if not main.hud.is_content_card_visible():
		return
	var close: Button = main.hud.content_close_button
	if close and close.visible:
		await _click(close)
		await _settle(main)


func _click(button: Button) -> void:
	await VerifyInputHelper.real_click_button(self, root, button)


func _settle(main) -> void:
	await VerifyInputHelper.settle_main(self, main, root.size)


func _fail(message: String) -> void:
	printerr(message)
	quit(1)
