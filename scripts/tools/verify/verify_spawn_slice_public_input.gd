# gdlint:disable=max-returns
extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const VerifyInputHelper = preload("res://scripts/tools/verify/verify_input_helper.gd")


func _initialize() -> void:
	_verify.call_deferred()


func _verify() -> void:
	root.size = Vector2i(1152, 648)
	var main := Main.new()
	root.add_child(main)
	await _settle(main)

	_move_near(main, "npc_harrow_venn_world")
	await _settle(main)
	await _world_click_entity(main, "npc_harrow_venn_world")
	await _settle(main)
	if not main.hud.is_content_card_visible():
		_fail("World click on Harrow did not open dialogue.")
		return
	var accept := _button_containing(main.hud.content_choice_list, "I'll find it.")
	if not accept:
		_fail("Missing Harrow quest accept choice.")
		return
	await _click(accept)
	await _settle(main)
	if main.quests.get_quest_state("quest_missing_tools") != "active":
		_fail("Dialogue choice click did not start Missing Tools.")
		return

	await _close_content(main)
	_move_near(main, "poi_briarwatch_square")
	await _settle(main)
	await _world_click_entity(main, "poi_briarwatch_square")
	await _settle(main)
	if not main.hud.is_content_card_visible():
		_fail("World click on town square POI did not open place card.")
		return
	if not main.hud.content_title_label.text.contains("Warden's Job Board"):
		_fail("Town square POI did not show the job-board HUD card.")
		return
	var job := _button_containing(main.hud.content_choice_list, "Take Road Patrol Job")
	if not job:
		_fail("Missing road patrol job choice.")
		return
	await _click(job)
	await _settle(main)
	if main.quests.get_quest_state("quest_briarwatch_road_patrol") != "active":
		_fail("POI choice click did not start Road Patrol.")
		return

	_move_near(main, "object_road_cache")
	await _settle(main)
	await _world_click_entity(main, "object_road_cache")
	await _settle(main)
	if not main.hud.is_systems_panel_visible() or not main.get_hud_state()["transfer_open"]:
		_fail("World click on road cache did not open transfer HUD.")
		return
	var take_gold := main.hud.systems_item_list.find_child(
		"TransferTake_ItemGoldCoin", true, false
	) as Button
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


func _move_near(main, entity_id: String) -> void:
	var entity = main.entities.get_entity(entity_id)
	if not entity:
		return
	main.player.set_world_position(entity.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)


func _world_click_entity(main, entity_id: String) -> void:
	var entity = main.entities.get_entity(entity_id)
	if not entity:
		return
	var screen_position: Vector2 = main.get_viewport().get_canvas_transform() * entity.global_position
	var motion := InputEventMouseMotion.new()
	motion.position = screen_position
	motion.global_position = screen_position
	main._unhandled_input(motion)
	await process_frame

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = screen_position
	press.global_position = screen_position
	main._unhandled_input(press)
	await process_frame

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.button_mask = 0
	release.pressed = false
	release.position = screen_position
	release.global_position = screen_position
	main._unhandled_input(release)
	await process_frame


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


func _fail(message: String) -> void:
	printerr(message)
	quit(1)
