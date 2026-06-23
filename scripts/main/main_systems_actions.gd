class_name MainSystemsActions
extends RefCounted

const MainInputRouter = preload("res://scripts/main/main_input_router.gd")


static func handle(main, action_id: String) -> void:
	var parsed := parse_action_id(action_id)
	var action := String(parsed.get("action", "use"))
	var target_id := String(parsed.get("target_id", action_id))
	match action:
		"equip":
			main._handle_equip_item(target_id)
		"equip_slot":
			_handle_equip_item_to_slot(main, target_id, String(parsed.get("slot_id", "")))
		"unequip":
			main._handle_unequip_slot(target_id)
		"train":
			main._handle_train_stat(target_id)
		"buy":
			main._handle_buy_item(target_id)
		"sell":
			main._handle_sell_item(target_id)
		"wait":
			main._handle_wait_action(target_id.to_int())
		"target":
			MainInputRouter.target_entity(main, target_id)
		"save":
			main._handle_save_requested()
		"load":
			main._handle_load_requested()
		"ui":
			if target_id == "back" and main.hud:
				main.hud.hide_systems_panel()
		_:
			main._use_inventory_item(target_id)


static func parse_action_id(action_id: String) -> Dictionary:
	var parts := action_id.split(":", false)
	if parts.size() >= 3 and parts[0] == "equip_slot":
		return {"action": parts[0], "target_id": parts[1], "slot_id": parts[2]}
	if parts.size() >= 2:
		return {"action": parts[0], "target_id": parts[1]}
	return {"action": "use", "target_id": action_id}


static func _handle_equip_item_to_slot(main, item_id: String, slot_id: String) -> void:
	if main.has_method("_handle_equip_item_to_slot"):
		main._handle_equip_item_to_slot(item_id, slot_id)
		return
	var item: Dictionary = main.content.get_item(item_id)
	if (
		item.is_empty()
		or not main.inventory.has_item(item_id)
		or not main.equipment.equip_item_to_slot(item_id, slot_id)
	):
		main.event_bus.post_message("Could not equip that item there.")
		main._refresh_hud()
		return
	main.event_bus.post_message("Equipped %s." % String(item.get("name", item_id)))
	main._refresh_hud()
