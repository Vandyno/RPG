# gdlint:disable=max-returns
extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const VERIFY_SAVE_PATH := "user://verify_rpg_ui_real_clicks.json"


func _initialize() -> void:
	_verify.call_deferred()


func _verify() -> void:
	root.size = Vector2i(1152, 648)
	_remove_verify_save()
	var main := Main.new()
	root.add_child(main)
	await _settle(main)
	main.save_manager.save_path = VERIFY_SAVE_PATH

	if not await _verify_top_nav(main):
		return
	if not await _verify_system_action_rows(main):
		return
	if not await _verify_inventory_categories_and_item_rows(main):
		return
	if not await _verify_shop_rows(main):
		return
	if not await _verify_content_choice_rows(main):
		return
	if not await _verify_context_action_rows(main):
		return
	if not await _verify_pickpocket_context_row(main):
		return
	if not await _verify_sneak_button(main):
		return

	_remove_verify_save()
	print("RPG UI real clicks verified.")
	quit()


func _verify_top_nav(main) -> bool:
	var quests := _button_containing(main.hud.top_nav_buttons, "Quests")
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
	main.inventory.add_item("item_roadside_draught", 2)
	main.player.apply_damage(40)
	main.hud.show_systems_panel("inventory")
	await _settle(main)

	var weapons := _button_containing(main.hud.systems_category_row, "Weapons")
	if not weapons:
		return _fail("Weapons category button missing.")
	await _click(weapons)
	if main.hud.systems_active_category != "weapons":
		return _fail("Weapons category real click did not select weapons.")

	var hatchet := _button_containing(main.hud.systems_item_list, "Road Hatchet")
	if not hatchet:
		return _fail("Road Hatchet inventory row missing.")
	await _click(hatchet)
	if main.equipment.get_equipped_item("right_hand") != "item_road_hatchet":
		return _fail("Road Hatchet real click did not equip right hand.")

	var all := _button_containing(main.hud.systems_category_row, "All")
	if not all:
		return _fail("All category button missing.")
	await _click(all)
	if main.hud.systems_active_category != "all":
		return _fail("All category real click did not select all inventory.")

	var before_count: int = main.inventory.get_count("item_roadside_draught")
	var before_health: int = main.player.health
	var draught := _button_containing(main.hud.systems_item_list, "Roadside Draught")
	if not draught:
		return _fail("Roadside Draught inventory row missing.")
	await _click(draught)
	if main.inventory.get_count("item_roadside_draught") != before_count - 1:
		return _fail("Roadside Draught real click did not consume one item.")
	if main.player.health <= before_health:
		return _fail("Roadside Draught real click did not heal the player.")
	return true


func _verify_shop_rows(main) -> bool:
	main.hud.hide_systems_panel()
	await _settle(main)
	main.inventory.add_item("item_gold_coin", 20)
	_select_entity(main, "npc_maera_pike_world")
	main.hud.show_systems_panel("trade")
	await _settle(main)

	var buy := _button_containing(main.hud.systems_item_list, "Roadside Draught")
	if not buy:
		return _fail("Trade buy row missing.")
	var before_gold: int = main.inventory.get_count("item_gold_coin")
	var before_draught: int = main.inventory.get_count("item_roadside_draught")
	await _click(buy)
	if main.inventory.get_count("item_roadside_draught") != before_draught + 1:
		return _fail("Trade buy row real click did not add a draught.")
	if main.inventory.get_count("item_gold_coin") >= before_gold:
		return _fail("Trade buy row real click did not spend gold.")

	var sell_category := _button_containing(main.hud.systems_category_row, "Sell")
	if not sell_category:
		return _fail("Trade Sell category missing.")
	await _click(sell_category)
	var sell := _button_containing(main.hud.systems_item_list, "Roadside Draught")
	if not sell:
		return _fail("Trade sell row missing.")
	before_gold = main.inventory.get_count("item_gold_coin")
	before_draught = main.inventory.get_count("item_roadside_draught")
	await _click(sell)
	if main.inventory.get_count("item_roadside_draught") != before_draught - 1:
		return _fail("Trade sell row real click did not remove a draught.")
	if main.inventory.get_count("item_gold_coin") <= before_gold:
		return _fail("Trade sell row real click did not add gold.")
	return true


func _verify_content_choice_rows(main) -> bool:
	main.hud.hide_systems_panel()
	main.hud.hide_content_card()
	await _settle(main)

	_select_entity(main, "npc_harrow_venn_world")
	main._handle_interact_requested()
	await _settle(main)
	var accept := _button_containing(main.hud.content_choice_list, "I'll find it.")
	if not accept:
		return _fail("Harrow dialogue accept choice missing.")
	await _click(accept)
	if main.quests.get_quest_state("quest_missing_tools") != "active":
		return _fail("Harrow dialogue real click did not start Missing Tools.")

	main.hud.hide_content_card()
	await _settle(main)
	_select_entity(main, "poi_briarwatch_square")
	main._handle_interact_requested()
	await _settle(main)
	var job := _button_containing(main.hud.content_choice_list, "Take Road Patrol Job")
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
	var target := _button_with_action_prefix(main.hud.systems_action_list, "target:")
	if not target:
		return _fail("Quest target systems row missing.")
	await _reveal_systems_button(main, target)

	main.player.set_health(42)
	main.hud.show_systems_panel("journal")
	await _settle(main)
	var save := _button_containing(main.hud.systems_action_list, "Save Game")
	if not save:
		return _fail("Save Game systems row missing.")
	await _reveal_systems_button(main, save)
	await _click(save)
	if main.hud.is_systems_panel_visible():
		return _fail("Save Game real click did not close systems panel.")
	if not FileAccess.file_exists(VERIFY_SAVE_PATH):
		return _fail("Save Game real click did not write a save file.")

	main.player.set_health(5)
	main.hud.show_systems_panel("journal")
	await _settle(main)
	var load := _button_containing(main.hud.systems_action_list, "Load Game")
	if not load:
		return _fail("Load Game systems row missing.")
	await _reveal_systems_button(main, load)
	await _click(load)
	if main.hud.is_systems_panel_visible():
		return _fail("Load Game real click did not close systems panel.")
	if main.player.health != 42:
		return _fail("Load Game real click did not restore saved player health.")
	main.quests.quests.clear()
	main.selected_target_id = ""
	main.manual_target_locked = false
	main.hud.hide_systems_panel()
	_remove_verify_save()
	await _settle(main)
	return true


func _verify_context_action_rows(main) -> bool:
	main.hud.hide_systems_panel()
	main.hud.hide_content_card()
	main.inventory.add_item("item_gold_coin", max(0, 2 - main.inventory.get_count("item_gold_coin")))
	if not main.inventory.has_item("item_road_hatchet"):
		main.inventory.add_item("item_road_hatchet", 1)
	_select_entity(main, "poi_harrow_forge")
	await _settle(main)

	var sharpen := _button_containing(main.hud.context_action_buttons, "Sharpen Road Hatchet")
	if not sharpen:
		return _fail("Forge service context row missing.")
	var before_gold: int = main.inventory.get_count("item_gold_coin")
	await _click(sharpen)
	if main.inventory.get_count("item_gold_coin") != before_gold - 2:
		return _fail("Forge service context real click did not spend gold.")
	if main.statuses.get_remaining_charges("status_road_focus") != 3:
		return _fail("Forge service context real click did not apply road focus.")
	return true


func _verify_pickpocket_context_row(main) -> bool:
	main.hud.hide_systems_panel()
	main.hud.hide_content_card()
	_select_entity(main, "npc_harrow_venn_world")
	main.player.set_sneaking(true)
	await _settle(main)
	var pickpocket := _button_containing(main.hud.context_action_buttons, "Pickpocket")
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


func _click(button: Button) -> void:
	if not button.visible or not button.is_visible_in_tree():
		return
	await _push_click(button.get_viewport(), button.get_global_rect().get_center())
	await process_frame
	await process_frame


func _reveal_systems_button(main, button: Button) -> void:
	if main.hud.systems_scroll:
		main.hud.systems_scroll.scroll_vertical = maxi(0, int(button.position.y) - 12)
		main.hud.systems_scroll.ensure_control_visible(button)
		await process_frame
		await process_frame


func _push_click(viewport: Viewport, position: Vector2) -> void:
	await _push_motion(viewport, position)

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	viewport.push_input(press, true)
	await process_frame

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.button_mask = 0
	release.pressed = false
	release.position = position
	release.global_position = position
	viewport.push_input(release, true)
	await process_frame


func _push_motion(viewport: Viewport, position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	motion.button_mask = 0
	viewport.push_input(motion, true)
	await process_frame


func _settle(main) -> void:
	if main.hud:
		main.hud._apply_layout_for_size(Vector2(root.size))
		main.hud.refresh()
	await process_frame
	await process_frame


func _button_containing(parent: Node, text: String) -> Button:
	if not parent:
		return null
	for child in parent.get_children():
		if child is Button and child.visible and String(child.text).contains(text):
			return child
		var descendant := _button_containing(child, text)
		if descendant:
			return descendant
	return null


func _button_with_action_prefix(parent: Node, action_prefix: String) -> Button:
	if not parent:
		return null
	for child in parent.get_children():
		if (
			child is Button
			and child.visible
			and String(child.get_meta("action_id", "")).begins_with(action_prefix)
		):
			return child
		var descendant := _button_with_action_prefix(child, action_prefix)
		if descendant:
			return descendant
	return null


func _fail(message: String) -> bool:
	printerr(message)
	_remove_verify_save()
	quit(1)
	return false


func _remove_verify_save() -> void:
	if FileAccess.file_exists(VERIFY_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(VERIFY_SAVE_PATH))
