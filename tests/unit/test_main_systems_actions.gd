extends GutTest

const MainSystemsActions = preload("res://scripts/main/main_systems_actions.gd")


func test_parse_action_id_defaults_to_inventory_use() -> void:
	assert_eq(
		MainSystemsActions.parse_action_id("item_roadside_draught"),
		{"action": "use", "target_id": "item_roadside_draught"}
	)
	assert_eq(
		MainSystemsActions.parse_action_id("equip:item_road_hatchet"),
		{"action": "equip", "target_id": "item_road_hatchet"}
	)


func test_handle_routes_system_actions_to_main_methods() -> void:
	var main := MainStub.new()

	for action_id in [
		"equip:item_hatchet",
		"unequip:weapon",
		"train:might",
		"buy:item_draught",
		"sell:item_hatchet",
		"wait:8",
		"save:game",
		"load:game",
		"ui:back",
		"item_draught"
	]:
		MainSystemsActions.handle(main, action_id)

	assert_eq(
		main.calls,
		[
			"equip:item_hatchet",
			"unequip:weapon",
			"train:might",
			"buy:item_draught",
			"sell:item_hatchet",
			"wait:8",
			"save",
			"load",
			"hide_systems",
			"use:item_draught"
		]
	)


class MainStub:
	extends RefCounted

	var calls: Array[String] = []
	var hud := HudStub.new(calls)

	func _handle_equip_item(item_id: String) -> void:
		calls.append("equip:%s" % item_id)

	func _handle_unequip_slot(slot_id: String) -> void:
		calls.append("unequip:%s" % slot_id)

	func _handle_train_stat(stat_id: String) -> void:
		calls.append("train:%s" % stat_id)

	func _handle_buy_item(item_id: String) -> void:
		calls.append("buy:%s" % item_id)

	func _handle_sell_item(item_id: String) -> void:
		calls.append("sell:%s" % item_id)

	func _handle_wait_action(hours: int) -> void:
		calls.append("wait:%d" % hours)

	func _handle_save_requested() -> void:
		calls.append("save")

	func _handle_load_requested() -> void:
		calls.append("load")

	func _use_inventory_item(item_id: String) -> void:
		calls.append("use:%s" % item_id)


class HudStub:
	extends RefCounted

	var calls: Array[String]

	func _init(call_log: Array[String]) -> void:
		calls = call_log

	func hide_systems_panel() -> void:
		calls.append("hide_systems")
