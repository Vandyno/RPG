extends GutTest

const CombatManager = preload("res://scripts/managers/combat_manager.gd")


class EnemyStub:
	var data := {"max_health": 12, "damage_taken_per_hit": 6, "attack_damage": 4}

	func get_entity_id() -> String:
		return "enemy_test"

	func get_display_name() -> String:
		return "Enemy Test"


class DurableEnemyStub:
	var data := {"max_health": 40, "damage_taken_per_hit": 6, "attack_damage": 4}

	func get_entity_id() -> String:
		return "durable_enemy_test"

	func get_display_name() -> String:
		return "Durable Enemy"


class MalformedEnemyStub:
	var data := {"max_health": 0, "damage_taken_per_hit": -3, "attack_damage": -4}

	func get_entity_id() -> String:
		return "malformed_enemy_test"

	func get_display_name() -> String:
		return "Malformed Enemy"


class TextEnemyStub:
	var data := {"max_health": "twelve", "damage_taken_per_hit": "six", "attack_damage": "four"}

	func get_entity_id() -> String:
		return "text_enemy_test"

	func get_display_name() -> String:
		return "Text Enemy"


class EquipmentStub:
	func get_player_damage_bonus() -> int:
		return 4

	func guarded_counter_multiplier(_base_multiplier: float) -> float:
		return 0.25


class ProgressionStub:
	func get_player_damage_bonus() -> int:
		return 2


class StatusStub:
	var charges := 2

	func get_player_damage_bonus() -> int:
		return 3 if charges > 0 else 0

	func consume_attack_charge() -> void:
		charges = maxi(0, charges - 1)

	func guarded_counter_multiplier(base_multiplier: float) -> float:
		return base_multiplier


func test_combat_damage_defeat_and_save_load() -> void:
	var combat := CombatManager.new()
	add_child_autofree(combat)
	combat.setup(null)
	var enemy := EnemyStub.new()

	var first_hit := combat.attack_entity(enemy)
	assert_false(first_hit["defeated"])
	assert_eq(first_hit["health"], 6)
	assert_eq(first_hit["counter_damage"], 4)
	assert_false(first_hit["guarded"])
	assert_eq(combat.get_entity_health(enemy), 6)

	var loaded := CombatManager.new()
	add_child_autofree(loaded)
	loaded.load_save_data(combat.get_save_data())
	assert_eq(loaded.get_entity_health(enemy), 6)

	var second_hit := loaded.attack_entity(enemy)
	assert_true(second_hit["defeated"])
	assert_eq(second_hit["counter_damage"], 0)
	assert_eq(loaded.get_entity_health(enemy), 12)


func test_combat_guard_reduces_counter_damage_without_blocking_defeat() -> void:
	var combat := CombatManager.new()
	add_child_autofree(combat)
	combat.setup(null)
	var enemy := EnemyStub.new()

	var guarded_hit := combat.attack_entity(enemy, true)

	assert_false(guarded_hit["defeated"])
	assert_true(guarded_hit["guarded"])
	assert_eq(guarded_hit["raw_counter_damage"], 4)
	assert_eq(guarded_hit["counter_damage"], 2)

	var defeated_hit := combat.attack_entity(enemy, true)

	assert_true(defeated_hit["defeated"])
	assert_false(defeated_hit["guarded"])
	assert_eq(defeated_hit["counter_damage"], 0)


func test_combat_uses_equipment_damage_and_guard_modifiers() -> void:
	var combat := CombatManager.new()
	add_child_autofree(combat)
	combat.setup(null, EquipmentStub.new(), ProgressionStub.new())
	var enemy := EnemyStub.new()

	var hit := combat.attack_entity(enemy, true)

	assert_true(hit["defeated"])
	assert_eq(hit["damage"], 12)
	assert_eq(hit["health"], 0)
	assert_eq(hit["raw_counter_damage"], 0)
	assert_eq(hit["counter_damage"], 0)


func test_combat_uses_and_consumes_status_damage_bonus() -> void:
	var statuses := StatusStub.new()
	var combat := CombatManager.new()
	add_child_autofree(combat)
	combat.setup(null, EquipmentStub.new(), ProgressionStub.new(), statuses)
	var enemy := DurableEnemyStub.new()

	var first_hit := combat.attack_entity(enemy)
	assert_eq(first_hit["damage"], 15)
	assert_eq(first_hit["health"], 25)
	assert_eq(statuses.charges, 1)

	var second_hit := combat.attack_entity(enemy)
	assert_eq(second_hit["damage"], 15)
	assert_eq(second_hit["health"], 10)
	assert_eq(statuses.charges, 0)

	var third_hit := combat.attack_entity(enemy)
	assert_eq(third_hit["damage"], 12)
	assert_true(third_hit["defeated"])


func test_combat_load_ignores_invalid_health_entries() -> void:
	var combat := CombatManager.new()
	add_child_autofree(combat)

	combat.load_save_data({"health_by_entity_id": {"": 4, "dead": 0, "text": "5", "wounded": 5}})

	assert_eq(combat.health_by_entity_id, {"wounded": 5})


func test_combat_load_ignores_malformed_health_field() -> void:
	var combat := CombatManager.new()
	add_child_autofree(combat)
	combat.load_save_data({"health_by_entity_id": {"wounded": 5}})

	combat.load_save_data({"health_by_entity_id": "bad"})

	assert_eq(combat.health_by_entity_id, {})


func test_combat_clamps_loaded_health_to_entity_max() -> void:
	var combat := CombatManager.new()
	add_child_autofree(combat)
	combat.load_save_data({"health_by_entity_id": {"enemy_test": 999}})
	var enemy := EnemyStub.new()

	assert_eq(combat.get_entity_health(enemy), 12)

	var hit := combat.attack_entity(enemy)

	assert_eq(hit["health"], 6)
	assert_false(hit["defeated"])


func test_combat_treats_malformed_live_health_as_full_health() -> void:
	var combat := CombatManager.new()
	add_child_autofree(combat)
	combat.health_by_entity_id["enemy_test"] = "bad"
	var enemy := EnemyStub.new()

	assert_eq(combat.get_entity_health(enemy), 12)

	var hit := combat.attack_entity(enemy)

	assert_eq(hit["health"], 6)
	assert_false(hit["defeated"])


func test_combat_clamps_malformed_live_enemy_numbers() -> void:
	var combat := CombatManager.new()
	add_child_autofree(combat)
	combat.setup(null)
	var enemy := MalformedEnemyStub.new()

	assert_eq(combat.get_entity_health(enemy), 1)

	var hit := combat.attack_entity(enemy)

	assert_eq(hit["max_health"], 1)
	assert_eq(hit["damage"], 1)
	assert_eq(hit["counter_damage"], 0)
	assert_true(hit["defeated"])


func test_combat_defaults_non_numeric_live_enemy_numbers() -> void:
	var combat := CombatManager.new()
	add_child_autofree(combat)
	combat.setup(null)
	var enemy := TextEnemyStub.new()

	assert_eq(combat.get_entity_health(enemy), 12)

	var hit := combat.attack_entity(enemy)

	assert_eq(hit["max_health"], 12)
	assert_eq(hit["damage"], 6)
	assert_eq(hit["counter_damage"], 4)
	assert_eq(hit["health"], 6)
