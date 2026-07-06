# gdlint:disable=max-returns
extends SceneTree

const Main = preload("res://scripts/main/main.gd")


func _initialize() -> void:
	_verify.call_deferred()


func _verify() -> void:
	root.size = Vector2i(1152, 648)
	var main := Main.new()
	root.add_child(main)
	await _settle(main)

	if not await _verify_top_nav(main):
		return
	if not await _verify_inventory_categories_and_item_rows(main):
		return
	if not await _verify_shop_rows(main):
		return
	if not await _verify_content_choice_rows(main):
		return
	if not await _verify_sneak_button(main):
		return

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
	await _push_click(button.get_global_rect().get_center())
	await process_frame
	await process_frame


func _push_click(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion)
	await process_frame

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	root.push_input(press)
	await process_frame

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	root.push_input(release)
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


func _fail(message: String) -> bool:
	printerr(message)
	quit(1)
	return false
