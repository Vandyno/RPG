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
		_:
			main._use_inventory_item(target_id)


static func parse_action_id(action_id: String) -> Dictionary:
	var parts := action_id.split(":", false, 1)
	if parts.size() == 2:
		return {"action": parts[0], "target_id": parts[1]}
	return {"action": "use", "target_id": action_id}
