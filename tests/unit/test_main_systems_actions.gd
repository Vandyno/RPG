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
	assert_eq(
		MainSystemsActions.parse_action_id("equip_slot:item_road_hatchet:right_hand"),
		{"action": "equip_slot", "target_id": "item_road_hatchet", "slot_id": "right_hand"}
	)


func test_handle_routes_system_actions_to_main_methods() -> void:
	var main := MainStub.new()

	for action_id in [
		"equip:item_hatchet",
		"equip_slot:item_hatchet:right_hand",
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
			"equip_slot:item_hatchet:right_hand",
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


func test_handle_aim_uses_assigned_spell_against_aimed_enemy() -> void:
	var main := AimMainStub.new()

	MainSystemsActions.handle_aim(main, "ability_1", Vector2.RIGHT)

	assert_eq(main.selected_id, "enemy_east")
	assert_eq(main.calls, ["message:Fire Blast at Road Thug.", "hit:enemy_east", "refresh"])


func test_handle_aim_uses_attack_joystick_against_aimed_enemy() -> void:
	var main := AimMainStub.new()

	MainSystemsActions.handle_aim(main, "attack", Vector2.LEFT)

	assert_eq(main.selected_id, "enemy_west")
	assert_eq(main.calls, ["hit:enemy_west", "refresh"])


class MainStub:
	extends RefCounted

	var calls: Array[String] = []
	var hud := HudStub.new(calls)

	func _handle_equip_item(item_id: String) -> void:
		calls.append("equip:%s" % item_id)

	func _handle_equip_item_to_slot(item_id: String, slot_id: String) -> void:
		calls.append("equip_slot:%s:%s" % [item_id, slot_id])

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


class AimMainStub:
	extends RefCounted

	var calls: Array[String] = []
	var selected_id := ""
	var spells := AimSpellsStub.new()
	var content := AimContentStub.new()
	var event_bus := AimBusStub.new(calls)
	var player := AimPlayerStub.new()
	var enemies := [
		AimEntityStub.new("enemy_west", "River Ruffian", Vector2.LEFT * 48.0),
		AimEntityStub.new("enemy_east", "Road Thug", Vector2.RIGHT * 48.0)
	]

	func _get_nearby_entity():
		return enemies[0]

	func _get_nearby_entities() -> Array:
		return enemies

	func _select_nearby_target(entity_id: String, _post_targeting_message: bool) -> bool:
		selected_id = entity_id
		return true

	func _interact_enemy(entity) -> void:
		calls.append("hit:%s" % entity.get_entity_id())

	func _refresh_hud() -> void:
		calls.append("refresh")


class AimSpellsStub:
	extends RefCounted

	func get_assigned_spell(slot_id: String) -> String:
		return "spell_fire_blast" if slot_id == "ability_1" else ""


class AimContentStub:
	extends RefCounted

	func get_spell(spell_id: String) -> Dictionary:
		if spell_id == "spell_fire_blast":
			return {"id": spell_id, "name": "Fire Blast"}
		return {}


class AimBusStub:
	extends RefCounted

	var calls: Array[String]

	func _init(call_log: Array[String]) -> void:
		calls = call_log

	func post_message(message: String) -> void:
		calls.append("message:%s" % message)


class AimPlayerStub:
	extends RefCounted

	var global_position := Vector2.ZERO


class AimEntityStub:
	extends RefCounted

	var id: String
	var display_name: String
	var global_position: Vector2

	func _init(entity_id: String, name: String, position: Vector2) -> void:
		id = entity_id
		display_name = name
		global_position = position

	func get_entity_id() -> String:
		return id

	func get_display_name() -> String:
		return display_name

	func get_kind() -> String:
		return "enemy"
