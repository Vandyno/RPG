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
		"swap_mainhand:weapon",
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
			"swap_mainhand",
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


func test_handle_aim_hold_channels_assigned_spell_against_aimed_enemy() -> void:
	var main := AimMainStub.new()

	MainSystemsActions.handle_aim_held(main, "ability_1", Vector2.RIGHT, 1.0)

	assert_eq(main.player.mana, 92.0)
	assert_eq(
		main.calls,
		[
			"damage:enemy_east:1",
			"message:Fire Blast hits Road Thug for 1.",
			"refresh"
		]
	)


func test_handle_aim_release_does_not_recast_channeled_spell() -> void:
	var main := AimMainStub.new()

	MainSystemsActions.handle_aim(main, "ability_1", Vector2.RIGHT)

	assert_eq(main.calls, ["refresh"])


func test_handle_aim_uses_attack_joystick_against_aimed_enemy() -> void:
	var main := AimMainStub.new()

	MainSystemsActions.handle_aim(main, "attack", Vector2.LEFT)

	assert_eq(
		main.calls,
		[
			"damage:enemy_west:2",
			"message:Unarmed hits River Ruffian for 2.",
			"refresh"
		]
	)


func test_handle_held_melee_repeats_on_weapon_interval() -> void:
	var main := AimMainStub.new()
	main.equipment.equipped_item_id = "item_training_sword"

	MainSystemsActions.handle_aim_held(main, "attack", Vector2.LEFT, 1.0)
	MainSystemsActions.handle_aim(main, "attack", Vector2.LEFT)

	assert_eq(
		main.calls,
		[
			"damage:enemy_west:3",
			"message:Training Sword hits River Ruffian for 3.",
			"damage:enemy_west:3",
			"message:Training Sword hits River Ruffian for 3.",
			"damage:enemy_west:3",
			"message:Training Sword hits River Ruffian for 3.",
			"refresh",
			"refresh"
		]
	)


func test_handle_held_bow_waits_for_release() -> void:
	var main := AimMainStub.new()
	main.equipment.equipped_item_id = "item_hunting_bow"

	MainSystemsActions.handle_aim_held(main, "attack", Vector2.LEFT, 1.0)
	MainSystemsActions.handle_aim(main, "attack", Vector2.LEFT)

	assert_eq(
		main.calls,
		[
			"damage:enemy_west:4",
			"message:Hunting Bow hits River Ruffian for 4.",
			"refresh"
		]
	)


func test_handle_aim_attack_swings_without_target() -> void:
	var main := AimMainStub.new()
	main.enemies.clear()
	main.entities.entities_by_id.clear()

	MainSystemsActions.handle_aim(main, "attack", Vector2.RIGHT)

	assert_eq(main.player.facing_direction, Vector2.RIGHT)
	assert_eq(main.calls, ["message:Attacked east.", "refresh"])


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

	func _handle_swap_mainhand_weapon() -> void:
		calls.append("swap_mainhand")

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
	var equipment := AimEquipmentStub.new()
	var combat := AimCombatStub.new(calls)
	var effect_runner := AimEffectRunnerStub.new()
	var channeled_spell_damage_bank: Dictionary = {}
	var channeled_spell_empty_reported: Dictionary = {}
	var held_weapon_attack_elapsed: Dictionary = {}
	var enemies := [
		AimEntityStub.new("enemy_west", "River Ruffian", Vector2.LEFT * 28.0),
		AimEntityStub.new("enemy_east", "Road Thug", Vector2.RIGHT * 28.0)
	]
	var entities := AimEntitiesStub.new(enemies)

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

	func apply_effect(_effect: Dictionary, _refresh: bool = true) -> void:
		calls.append("effect")


class AimSpellsStub:
	extends RefCounted

	func get_assigned_spell(slot_id: String) -> String:
		return "spell_fire_blast" if slot_id == "ability_1" else ""


class AimContentStub:
	extends RefCounted

	func get_spell(spell_id: String) -> Dictionary:
		if spell_id == "spell_fire_blast":
			return {
				"id": spell_id,
				"name": "Fire Blast",
				"mana_cost": 5,
				"mana_drain_per_second": 8,
				"channel": true,
				"attack":
				{
					"shape": "stream",
					"range_pixels": 96,
					"width_pixels": 50,
					"damage_per_second": 1,
					"visual": "fire_stream"
				}
			}
		return {}

	func get_item(_item_id: String) -> Dictionary:
		if _item_id == "item_training_sword":
			return {
				"id": _item_id,
				"name": "Training Sword",
				"weapon_attack":
				{
					"shape": "swing",
					"range_pixels": 34,
					"width_pixels": 30,
					"arc_degrees": 110,
					"damage": 3,
					"attack_interval_seconds": 0.5,
					"visual": "swing"
				}
			}
		if _item_id == "item_hunting_bow":
			return {
				"id": _item_id,
				"name": "Hunting Bow",
				"weapon_attack":
				{
					"shape": "projectile",
					"range_pixels": 96,
					"width_pixels": 14,
					"damage": 4,
					"attack_interval_seconds": 0.8,
					"visual": "projectile"
				}
			}
		return {}


class AimEquipmentStub:
	extends RefCounted

	var equipped_item_id := ""

	func get_equipped_item(_slot: String) -> String:
		return equipped_item_id


class AimCombatStub:
	extends RefCounted

	var calls: Array[String]

	func _init(call_log: Array[String]) -> void:
		calls = call_log

	func damage_entity(entity, damage: int, _counter_enabled: bool = false) -> Dictionary:
		calls.append("damage:%s:%d" % [entity.get_entity_id(), damage])
		return {"name": entity.get_display_name(), "defeated": false}

	func clear_entity(_entity_id: String) -> void:
		pass


class AimEffectRunnerStub:
	extends RefCounted

	func describe_effects(_effects: Array) -> String:
		return ""


class AimEntitiesStub:
	extends RefCounted

	var entities_by_id: Dictionary = {}

	func _init(enemies: Array) -> void:
		for enemy in enemies:
			entities_by_id[enemy.get_entity_id()] = enemy

	func remove_entity(entity_id: String) -> void:
		entities_by_id.erase(entity_id)


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
	var facing_direction := Vector2.DOWN
	var mana := 100.0

	func set_facing_direction(value: Vector2) -> void:
		facing_direction = value.normalized()

	func spend_mana(amount: float) -> float:
		var spent := minf(amount, mana)
		mana -= spent
		return spent


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
