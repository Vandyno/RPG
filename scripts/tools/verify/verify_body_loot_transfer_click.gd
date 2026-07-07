# gdlint:disable=max-returns
extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const MainSystemsActions = preload("res://scripts/main/actions/main_systems_actions.gd")


func _initialize() -> void:
	_verify.call_deferred()


func _verify() -> void:
	root.size = Vector2i(1152, 648)
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
	var take_bow := _button_named(body_pane, "TransferTake_ItemHuntingBow")
	if not take_bow:
		printerr("Hunting Bow transfer button missing.")
		quit(1)
		return
	await _push_button_click(take_bow)
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
	var put_bow := _button_named(pack_pane, "TransferPut_ItemHuntingBow")
	if not put_bow:
		printerr("Hunting Bow put-back button missing.")
		quit(1)
		return
	await _push_button_click(put_bow)
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
	var take_gold := _button_named(cache_pane, "TransferTake_ItemGoldCoin")
	if not take_gold:
		printerr("Gold Coin take button missing.")
		quit(1)
		return
	await _push_button_click(take_gold)
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
	var put_gold := _button_named(cache_pack_pane, "TransferPut_ItemGoldCoin")
	if not put_gold:
		printerr("Gold Coin put-back button missing.")
		quit(1)
		return
	await _push_button_click(put_gold)
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
	var take_people_gold := _button_named(people_body_pane, "TransferTake_ItemGoldCoin")
	if not take_people_gold:
		printerr("People body Gold Coin take button missing.")
		quit(1)
		return
	await _push_button_click(take_people_gold)
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
	var put_people_gold := _button_named(people_pack_pane, "TransferPut_ItemGoldCoin")
	if not put_people_gold:
		printerr("People body Gold Coin put button missing.")
		quit(1)
		return
	await _push_button_click(put_people_gold)
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
	var take_people_sword := _button_named(people_body_pane, "TransferTake_ItemTrainingSword")
	if not take_people_sword:
		printerr("People body Training Sword take button missing.")
		quit(1)
		return
	await _push_button_click(take_people_sword)
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
	var enemy = main.entities.get_entity("npc_road_thug")
	main.player.set_world_position(enemy.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	for _index in range(8):
		if not main.entities.get_entity("npc_road_thug"):
			break
		MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.RIGHT)
	var body = main.entities.get_entity("body_npc_road_thug")
	main.player.set_world_position(body.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	main.selected_target_id = body.get_entity_id()
	main.manual_target_locked = true
	main._update_nearby()
	main._handle_interact_requested()
	main.hud._apply_layout_for_size(Vector2(root.size))
	main.hud.set_systems_tab("inventory")


func _open_cache_transfer(main) -> void:
	var cache = main.entities.get_entity("object_road_cache")
	main.player.set_world_position(cache.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	main.selected_target_id = cache.get_entity_id()
	main.manual_target_locked = true
	main._update_nearby()
	main._handle_interact_requested()
	main.hud._apply_layout_for_size(Vector2(root.size))
	main.hud.set_systems_tab("inventory")


func _open_people_body_transfer(main) -> void:
	var enemy = main.entities.get_entity("npc_people_test_human")
	main.player.set_world_position(enemy.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	for _index in range(8):
		if not main.entities.get_entity("npc_people_test_human"):
			break
		MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.RIGHT)
	var body = main.entities.get_entity("body_npc_people_test_human")
	main.player.set_world_position(body.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	main.selected_target_id = body.get_entity_id()
	main.manual_target_locked = true
	main._update_nearby()
	main._handle_interact_requested()
	main.hud._apply_layout_for_size(Vector2(root.size))
	main.hud.set_systems_tab("inventory")


func _button_named(parent: Node, button_name: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.visible and child.name == button_name:
			return child
		var descendant := _button_named(child, button_name)
		if descendant:
			return descendant
	return null


func _settle(main) -> void:
	if main.hud:
		main.hud._apply_layout_for_size(Vector2(root.size))
		main.hud.refresh()
	await process_frame
	await process_frame


func _push_button_click(button: Button) -> void:
	var button_name := String(button.name)
	await _reveal_button(button)
	button = _button_named(root, button_name)
	if not button:
		return
	var viewport: Viewport = button.get_viewport()
	var position := button.get_global_rect().get_center()
	await _push_motion(viewport, position)
	button = _button_named(root, button_name)
	if button:
		viewport = button.get_viewport()
		position = button.get_global_rect().get_center()

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
	viewport.push_input(motion)
	await process_frame


func _reveal_button(button: Button) -> void:
	var parent := button.get_parent()
	while parent:
		if parent is ScrollContainer:
			parent.ensure_control_visible(button)
			await process_frame
			await process_frame
			return
		parent = parent.get_parent()
