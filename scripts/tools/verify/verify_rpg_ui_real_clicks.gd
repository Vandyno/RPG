# gdlint:disable=max-returns
extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const VerifyInputHelper = preload("res://scripts/tools/verify/verify_input_helper.gd")
const VERIFY_SAVE_PATH := "user://verify_rpg_ui_real_clicks.json"
const HARROW_FORGE_LAYER := "interior:structure_briarwatch_harrow_forge"


func _initialize() -> void:
	_verify.call_deferred()


func _verify() -> void:
	root.size = Vector2i(1152, 648)
	_remove_verify_save()
	var main := Main.new()
	root.add_child(main)
	await _settle(main)
	main.save_manager.save_path = VERIFY_SAVE_PATH
	if not await VerifyInputHelper.start_new_game(self, root, main):
		return _fail("New Game real click did not begin play.")

	if not await _verify_top_nav(main):
		return
	if not await _verify_system_action_rows(main):
		return
	if not await _verify_character_appearance(main):
		return
	if not await _verify_inventory_categories_and_item_rows(main):
		return
	if not await _verify_shop_rows(main):
		return
	if not await _verify_content_choice_rows(main):
		return
	if not await _verify_pickpocket_context_row(main):
		return
	if not await _verify_sneak_button(main):
		return

	_remove_verify_save()
	print("RPG UI real clicks verified.")
	quit()


func _verify_top_nav(main) -> bool:
	var quests := VerifyInputHelper.button_containing(main.hud.top_nav_buttons, "Quests")
	if not quests:
		return _fail("Quests top-nav button missing.")
	await _click(quests)
	if not main.hud.is_systems_panel_visible() or main.hud.get_systems_tab() != "quests":
		return _fail("Quests top-nav real click did not open the quests tab.")

	var close := main.hud.systems_panel.find_child("SystemsCloseButton", true, false) as Button
	if not close:
		return _fail("Systems close button missing.")
	await _click(close)
	if main.hud.is_systems_panel_visible():
		return _fail("Systems close real click did not close the panel.")
	return true


func _verify_inventory_categories_and_item_rows(main) -> bool:
	main.inventory.add_item("item_road_hatchet", 1)
	main.hud.show_systems_panel("inventory")
	await _settle(main)

	var weapons := VerifyInputHelper.button_containing(main.hud.systems_category_row, "Weapons")
	if not weapons:
		return _fail("Weapons category button missing.")
	await _click(weapons)
	if main.hud.systems_active_category != "weapons":
		return _fail("Weapons category real click did not select weapons.")

	var hatchet := VerifyInputHelper.button_containing(main.hud.systems_item_list, "Road Hatchet")
	if not hatchet:
		return _fail("Road Hatchet inventory row missing.")
	await _click(hatchet)
	if main.equipment.get_equipped_item("right_hand") != "item_road_hatchet":
		return _fail("Road Hatchet real click did not equip right hand.")

	var all := VerifyInputHelper.button_containing(main.hud.systems_category_row, "All")
	if not all:
		return _fail("All category button missing.")
	await _click(all)
	if main.hud.systems_active_category != "all":
		return _fail("All category real click did not select all inventory.")

	return true


func _verify_shop_rows(main) -> bool:
	main.hud.hide_systems_panel()
	await _settle(main)
	if not await _ensure_surface(main):
		return _fail("Could not return to surface before Maera trade check.")
	main.inventory.add_item("item_gold_coin", 20)
	_select_entity(main, "npc_maera_pike_world")
	main.hud.show_systems_panel("trade")
	await _settle(main)

	var buy := VerifyInputHelper.button_containing(main.hud.systems_item_list, "Traveler Buckler")
	if not buy:
		return _fail("Trade buy row missing.")
	var before_gold: int = main.inventory.get_count("item_gold_coin")
	var before_buckler: int = main.inventory.get_count("item_traveler_buckler")
	await _click(buy)
	if main.inventory.get_count("item_traveler_buckler") != before_buckler + 1:
		return _fail("Trade buy row real click did not add a buckler.")
	if main.inventory.get_count("item_gold_coin") >= before_gold:
		return _fail("Trade buy row real click did not spend gold.")

	var sell_category := VerifyInputHelper.button_containing(main.hud.systems_category_row, "Sell")
	if not sell_category:
		return _fail("Trade Sell category missing.")
	await _click(sell_category)
	var sell := VerifyInputHelper.button_containing(main.hud.systems_item_list, "Traveler Buckler")
	if not sell:
		return _fail("Trade sell row missing.")
	before_gold = main.inventory.get_count("item_gold_coin")
	before_buckler = main.inventory.get_count("item_traveler_buckler")
	await _click(sell)
	if main.inventory.get_count("item_traveler_buckler") != before_buckler - 1:
		return _fail("Trade sell row real click did not remove a buckler.")
	if main.inventory.get_count("item_gold_coin") <= before_gold:
		return _fail("Trade sell row real click did not add gold.")
	return true


func _verify_content_choice_rows(main) -> bool:
	main.hud.hide_systems_panel()
	main.hud.hide_content_card()
	await _settle(main)

	if not await _ensure_forge(main):
		return _fail("Could not enter Harrow's forge before dialogue check.")
	_select_entity(main, "npc_harrow_venn_world")
	main._handle_interact_requested()
	await _settle(main)
	var accept := VerifyInputHelper.button_containing(main.hud.content_choice_list, "I'll find it.")
	if not accept:
		return _fail("Harrow dialogue accept choice missing.")
	await _click(accept)
	if main.quests.get_quest_state("quest_missing_tools") != "active":
		return _fail("Harrow dialogue real click did not start Missing Tools.")

	main.hud.hide_content_card()
	await _settle(main)
	if not await _ensure_surface(main):
		return _fail("Could not return to surface before job-board check.")
	_select_entity(main, "poi_briarwatch_square")
	main._handle_interact_requested()
	await _settle(main)
	var job := VerifyInputHelper.button_containing(
		main.hud.content_choice_list, "Take Road Patrol Job"
	)
	if not job:
		return _fail("Job-board take choice missing.")
	await _click(job)
	if main.quests.get_quest_state("quest_briarwatch_road_patrol") != "active":
		return _fail("Job-board real click did not start Road Patrol.")
	return true


func _verify_system_action_rows(main) -> bool:
	if not main.quests.start_quest("quest_missing_tools"):
		return _fail("Could not prepare quest target systems row.")

	main.hud.show_systems_panel("quests")
	await _settle(main)
	var target := VerifyInputHelper.button_with_action_prefix(
		main.hud.systems_action_list, "target:"
	)
	if not target:
		return _fail("Quest target systems row missing.")
	await _reveal_systems_button(main, target)

	main.player.set_health(42)
	main.hud.show_systems_panel("journal")
	await _settle(main)
	var save := VerifyInputHelper.button_containing(main.hud.systems_action_list, "Save Game")
	if not save:
		return _fail("Save Game systems row missing.")
	await _reveal_systems_button(main, save)
	await _click(save)
	if main.hud.is_systems_panel_visible():
		return _fail("Save Game real click did not close systems panel.")
	if not FileAccess.file_exists(VERIFY_SAVE_PATH):
		return _fail("Save Game real click did not write a save file.")
	var saved_health := _saved_player_health()
	if saved_health < 0:
		return _fail("Save Game real click wrote unreadable player health.")

	main.player.set_health(5)
	main.hud.show_systems_panel("journal")
	await _settle(main)
	var load := VerifyInputHelper.button_containing(main.hud.systems_action_list, "Load Game")
	if not load:
		return _fail("Load Game systems row missing.")
	await _reveal_systems_button(main, load)
	await _click(load)
	if main.hud.is_systems_panel_visible():
		return _fail("Load Game real click did not close systems panel.")
	if main.player.health != saved_health:
		return _fail(
			(
				"Load Game real click did not restore saved player health. Expected %d, got %d."
				% [saved_health, main.player.health]
			)
		)
	main._show_start_menu()
	await _settle(main)
	var continue_button := VerifyInputHelper.find_button(root, "TitleContinueButton")
	if not continue_button or continue_button.disabled:
		return _fail("Continue title button missing or disabled after saving.")
	await _click(continue_button)
	if not main.game_started or main.start_menu.root.visible:
		return _fail("Continue real click did not return to play.")
	main.quests.quests.clear()
	main.selected_target_id = ""
	main.manual_target_locked = false
	main.hud.hide_systems_panel()
	_remove_verify_save()
	await _settle(main)
	return true


func _verify_character_appearance(main) -> bool:
	main.hud.show_systems_panel("character")
	await _settle(main)
	var appearance := VerifyInputHelper.button_containing(main.hud.systems_action_list, "Appearance")
	if not appearance:
		return _fail("Character Appearance row missing.")
	await _reveal_systems_button(main, appearance)
	await _click(appearance)
	if not main.debug_character_creator.is_open():
		return _fail("Character Appearance real click did not open appearance panel.")
	if main.hud.is_systems_panel_visible():
		return _fail("Character Appearance real click did not close systems panel.")
	var next_body_value := VerifyInputHelper.find_button(
		main.debug_character_creator.root, "CreatorNextBodyValueButton"
	)
	if not next_body_value:
		return _fail("Character Appearance body-value button missing.")
	await _click(next_body_value)
	var next_style := VerifyInputHelper.find_button(
		main.debug_character_creator.root, "CreatorNextStyleButton"
	)
	if not next_style:
		return _fail("Character Appearance style button missing.")
	await _click(next_style)
	var apply := VerifyInputHelper.find_button(main.debug_character_creator.root, "CreatorApplyButton")
	if not apply:
		return _fail("Character Appearance apply button missing.")
	await _click(apply)
	var player_appearance: Dictionary = main.player.humanoid_profile.get("appearance", {})
	if float(player_appearance.get("proportions", {}).get("body_height", 0.0)) != 1.1:
		return _fail("Character Appearance body-value real click did not apply height.")
	if String(player_appearance.get("hair_id", "")) != "hair_close_crop":
		return _fail("Character Appearance style real click did not apply human hair.")
	var close := main.debug_character_creator.root.find_child(
		"CreatorCloseButton", true, false
	) as Button
	if not close:
		return _fail("Character Appearance close button missing.")
	await _click(close)
	if main.debug_character_creator.is_open():
		return _fail("Character Appearance close real click did not close appearance panel.")
	return true


func _verify_pickpocket_context_row(main) -> bool:
	main.hud.hide_systems_panel()
	main.hud.hide_content_card()
	if not await _ensure_forge(main):
		return _fail("Could not enter Harrow's forge before pickpocket check.")
	_select_entity(main, "npc_harrow_venn_world")
	main.player.set_sneaking(true)
	await _settle(main)
	var pickpocket := VerifyInputHelper.button_containing(
		main.hud.context_action_buttons, "Pickpocket"
	)
	if not pickpocket:
		return _fail("Pickpocket context row missing.")
	await _click(pickpocket)
	if not main.hud.is_systems_panel_visible():
		return _fail("Pickpocket context real click did not open systems panel.")
	if main.active_transfer_owner_id != "char_harrow_venn":
		return _fail("Pickpocket context real click did not open Harrow transfer inventory.")
	if not bool(main.get_hud_state().get("transfer_open", false)):
		return _fail("Pickpocket context real click did not mark transfer state open.")
	main.hud.hide_systems_panel()
	main.player.set_sneaking(false)
	await _settle(main)
	return true


func _verify_sneak_button(main) -> bool:
	main.hud.hide_systems_panel()
	main.hud.hide_content_card()
	await _settle(main)
	var sneak: Button = main.hud.target_action_button
	if not sneak:
		return _fail("Sneak button missing.")
	await _click(sneak)
	if not main.player.is_sneaking:
		return _fail("Sneak real click did not toggle sneaking on.")
	await _click(sneak)
	if main.player.is_sneaking:
		return _fail("Sneak real click did not toggle sneaking off.")
	return true


func _select_entity(main, entity_id: String) -> void:
	var entity = main.entities.get_entity(entity_id)
	if not entity:
		return
	main.player.set_world_position(entity.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	main.selected_target_id = entity_id
	main.manual_target_locked = true
	main._update_nearby()
	main._refresh_hud()


func _ensure_forge(main) -> bool:
	if String(main.player.world_layer) == HARROW_FORGE_LAYER:
		return true
	if not await _ensure_surface(main):
		return false
	await VerifyInputHelper.world_click_entity(self, main, "object_harrow_forge_door")
	await _settle(main)
	return String(main.player.world_layer) == HARROW_FORGE_LAYER


func _ensure_surface(main) -> bool:
	if String(main.player.world_layer) == "surface":
		return true
	await VerifyInputHelper.world_click_entity(self, main, "object_harrow_forge_exit")
	await _settle(main)
	return String(main.player.world_layer) == "surface"


func _click(button: Button) -> void:
	await VerifyInputHelper.real_click_button(self, root, button)


func _reveal_systems_button(main, button: Button) -> void:
	if main.hud.systems_scroll:
		main.hud.systems_scroll.scroll_vertical = maxi(0, int(button.position.y) - 12)
		main.hud.systems_scroll.ensure_control_visible(button)
		await process_frame
		await process_frame


func _settle(main) -> void:
	await VerifyInputHelper.settle_main(self, main, root.size)


func _fail(message: String) -> bool:
	printerr(message)
	_remove_verify_save()
	quit(1)
	return false


func _remove_verify_save() -> void:
	if FileAccess.file_exists(VERIFY_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(VERIFY_SAVE_PATH))


func _saved_player_health() -> int:
	if not FileAccess.file_exists(VERIFY_SAVE_PATH):
		return -1
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(VERIFY_SAVE_PATH))
	if not parsed is Dictionary:
		return -1
	var player_data: Variant = (parsed as Dictionary).get("player", {})
	if not player_data is Dictionary:
		return -1
	if not (player_data as Dictionary).has("health"):
		return -1
	return int((player_data as Dictionary).get("health", -1))
