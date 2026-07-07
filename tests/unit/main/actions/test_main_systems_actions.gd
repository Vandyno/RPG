extends GutTest

const MainSystemsActions = preload("res://scripts/main/actions/main_systems_actions.gd")
const FacingBuckets = preload("res://scripts/core/facing_buckets.gd")


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


func test_handle_routes_service_owned_system_actions() -> void:
	var main := AssignSpellMainStub.new()

	MainSystemsActions.handle(
		MainSystemsActions.systems_context(main), "assign_spell:spell_fire_blast:ability_1"
	)

	assert_eq(
		main.calls,
		[
			"assign:spell_fire_blast:ability_1",
			"message:Assigned Fire Blast to ability 1.",
			"refresh"
		]
	)


func test_handle_routes_target_action_through_main_intent() -> void:
	var main := AssignSpellMainStub.new()

	MainSystemsActions.handle(MainSystemsActions.systems_context(main), "target:npc_harrow")

	assert_eq(main.calls, ["target:npc_harrow"])


func test_handle_aim_hold_channels_assigned_spell_against_aimed_enemy() -> void:
	var main := AimMainStub.new()

	MainSystemsActions.handle_aim_held(
		MainSystemsActions.aim_context(main), "ability_1", Vector2.RIGHT, 1.0
	)

	assert_eq(main.player.mana, 92.0)
	assert_eq(
		main.calls, ["damage:actor_east:1", "message:Fire Blast hits Road Thug for 1.", "refresh"]
	)


func test_handle_aim_release_does_not_recast_channeled_spell() -> void:
	var main := AimMainStub.new()

	MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "ability_1", Vector2.RIGHT)

	assert_eq(main.calls, ["refresh"])


func test_handle_aim_uses_attack_joystick_against_aimed_enemy() -> void:
	var main := AimMainStub.new()

	MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.LEFT)

	assert_eq(
		main.calls, ["damage:actor_west:2", "message:Unarmed hits River Ruffian for 2.", "refresh"]
	)


func test_handle_held_melee_repeats_on_weapon_interval() -> void:
	var main := AimMainStub.new()
	main.equipment.equipped_item_id = "item_training_sword"

	MainSystemsActions.handle_aim_held(
		MainSystemsActions.aim_context(main), "attack", Vector2.LEFT, 1.0
	)
	MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.LEFT)

	assert_eq(
		main.calls,
		[
			"damage:actor_west:3",
			"message:Training Sword hits River Ruffian for 3.",
			"damage:actor_west:3",
			"message:Training Sword hits River Ruffian for 3.",
			"damage:actor_west:3",
			"message:Training Sword hits River Ruffian for 3.",
			"refresh",
			"refresh"
		]
	)


func test_handle_held_bow_half_charge_releases_weaker_shot() -> void:
	var main := AimMainStub.new()
	main.equipment.equipped_item_id = "item_hunting_bow"

	MainSystemsActions.handle_aim_held(
		MainSystemsActions.aim_context(main), "attack", Vector2.LEFT, 1.0
	)
	MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.LEFT)

	assert_eq(
		main.calls,
		["damage:actor_west:2", "message:Hunting Bow hits River Ruffian for 2.", "refresh"]
	)


func test_handle_held_bow_full_charge_releases_full_damage() -> void:
	var main := AimMainStub.new()
	main.equipment.equipped_item_id = "item_hunting_bow"

	MainSystemsActions.handle_aim_held(
		MainSystemsActions.aim_context(main), "attack", Vector2.LEFT, 2.0
	)
	MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.LEFT)

	assert_eq(
		main.calls,
		["damage:actor_west:4", "message:Hunting Bow hits River Ruffian for 4.", "refresh"]
	)


func test_handle_tapped_bow_releases_minimum_damage_shot() -> void:
	var main := AimMainStub.new()
	main.equipment.equipped_item_id = "item_hunting_bow"

	MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.LEFT)

	assert_eq(
		main.calls,
		["damage:actor_west:1", "message:Hunting Bow hits River Ruffian for 1.", "refresh"]
	)


func test_handle_aim_attack_swings_without_target() -> void:
	var main := AimMainStub.new()
	main.enemies.clear()
	main.entities.entities_by_id.clear()

	MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.RIGHT)

	assert_eq(main.player.facing_direction, Vector2.RIGHT)
	assert_eq(main.calls, ["message:Punched east.", "refresh"])


func test_handle_aim_attack_uses_continuous_direction_for_hits() -> void:
	var main := AimMainStub.new()
	main.equipment.equipped_item_id = "item_hunting_bow"
	var raw_direction := Vector2(1.0, 0.31).normalized()
	var snapped := FacingBuckets.snap_direction(raw_direction)
	main.enemies = [
		AimEntityStub.new("actor_raw", "Raw Dummy", raw_direction * 88.0),
		AimEntityStub.new("actor_bucket", "Bucket Dummy", snapped * 88.0)
	]
	main.entities = AimEntitiesStub.new(main.enemies)

	MainSystemsActions.handle_aim_held(
		MainSystemsActions.aim_context(main), "attack", raw_direction, 2.0
	)
	MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", raw_direction)

	assert_eq(main.player.facing_direction, snapped)
	assert_eq(
		main.calls, ["damage:actor_raw:4", "message:Hunting Bow hits Raw Dummy for 4.", "refresh"]
	)


func test_spell_effect_uses_continuous_aim_direction() -> void:
	var main := AimMainStub.new()
	main.enemies.clear()
	main.entities.entities_by_id.clear()
	var raw_direction := Vector2(1.0, 0.31).normalized()

	MainSystemsActions.handle_aim_held(
		MainSystemsActions.aim_context(main), "ability_1", raw_direction, 0.25
	)

	assert_eq(main.effects.size(), 1)
	var effect_direction: Vector2 = main.effects[0]["direction"]
	assert_almost_eq(effect_direction.x, raw_direction.x, 0.001)
	assert_almost_eq(effect_direction.y, raw_direction.y, 0.001)
	assert_eq(main.calls, ["refresh"])


class AssignSpellMainStub:
	extends RefCounted

	var calls: Array[String] = []
	var content := AssignSpellContentStub.new()
	var event_bus := AimBusStub.new(calls)
	var spells := AssignSpellSlotsStub.new(calls)

	func _refresh_hud() -> void:
		calls.append("refresh")

	func _handle_target_entity_intent(entity_id: String) -> void:
		calls.append("target:%s" % entity_id)


class AssignSpellContentStub:
	extends RefCounted

	func get_spell(spell_id: String) -> Dictionary:
		if spell_id == "spell_fire_blast":
			return {"id": spell_id, "name": "Fire Blast"}
		return {}


class AssignSpellSlotsStub:
	extends RefCounted

	var calls: Array[String]

	func _init(call_log: Array[String]) -> void:
		calls = call_log

	func assign_spell_to_slot(spell_id: String, slot_id: String) -> bool:
		calls.append("assign:%s:%s" % [spell_id, slot_id])
		return true


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
	var effects: Array[Dictionary] = []
	var enemies := [
		AimEntityStub.new("actor_west", "River Ruffian", Vector2.LEFT * 28.0),
		AimEntityStub.new("actor_east", "Road Thug", Vector2.RIGHT * 28.0)
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

	func add_child(effect: Node) -> void:
		var effect_record := {
			"type": effect.get_class(),
			"direction":
			effect.get("direction") if effect.get("direction") is Vector2 else Vector2.ZERO
		}
		effects.append(effect_record)
		effect.free()


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
					"charge_seconds": 2.0,
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
		facing_direction = FacingBuckets.snap_direction(value)

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
		return "npc"

	func is_combat_target() -> bool:
		return true
