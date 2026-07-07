extends GutTest

const ActorRules = preload("res://scripts/core/actor_rules.gd")


class MethodCombatEntity:
	var target := false

	func _init(is_target: bool) -> void:
		target = is_target

	func is_combat_target() -> bool:
		return target


class DataCombatEntity:
	var data := {}

	func _init(entity_data: Dictionary) -> void:
		data = entity_data


func test_actor_rules_resolves_player_and_npc_profile_contracts() -> void:
	var player_profile := {
		"character_id": "char_player",
		"people_id": "people_human",
		"state": "alive",
		"inventory_owner_id": "char_player",
		"equipment_owner_id": "char_player",
		"spellbook_owner_id": "char_player",
		"stats": {"one_handed": 15},
		"derived_bonuses": {"resolve": 1}
	}
	var npc_actor := {
		"id": "npc_actor",
		"kind": "npc",
		"character_profile_id": "char_harrow_venn",
		"character_profile": player_profile
	}

	assert_true(ActorRules.is_actor_data(player_profile))
	assert_true(ActorRules.is_humanoid_actor_data(player_profile))
	assert_eq(ActorRules.character_id(player_profile), "char_player")
	assert_eq(ActorRules.character_id(npc_actor), "char_player")
	assert_eq(ActorRules.inventory_owner_id(npc_actor), "char_player")
	assert_eq(ActorRules.equipment_owner_id(npc_actor), "char_player")
	assert_eq(ActorRules.spellbook_owner_id(npc_actor), "char_player")
	assert_eq(ActorRules.stats(npc_actor), {"one_handed": 15})
	assert_eq(ActorRules.derived_bonuses(npc_actor), {"resolve": 1})


func test_actor_rules_hostility_state_drives_combat_targeting() -> void:
	var hostile_actor := {
		"kind": "npc",
		"actor_category": "humanoid",
		"hostility": "hostile",
		"combat_enabled": true,
		"character_profile_id": "char_bandit"
	}
	var neutral_actor := hostile_actor.duplicate(true)
	neutral_actor["hostility"] = "neutral"
	neutral_actor["combat_enabled"] = false
	var body_actor := hostile_actor.duplicate(true)
	body_actor["kind"] = "body"
	var legacy_enemy_kind := {"kind": "enemy", "hostility": "hostile", "combat_enabled": true}

	assert_true(ActorRules.is_combat_target_data(hostile_actor))
	assert_false(ActorRules.is_combat_target_data(neutral_actor))
	assert_false(ActorRules.is_combat_target_data(body_actor))
	assert_false(ActorRules.is_combat_target_data(legacy_enemy_kind))


func test_actor_rules_reads_combat_target_from_entities() -> void:
	var hostile_actor := {
		"kind": "npc",
		"actor_category": "humanoid",
		"hostility": "hostile",
		"combat_enabled": true,
		"character_profile_id": "char_bandit"
	}

	assert_true(ActorRules.is_combat_target_entity(MethodCombatEntity.new(true)))
	assert_false(ActorRules.is_combat_target_entity(MethodCombatEntity.new(false)))
	assert_true(ActorRules.is_combat_target_entity(DataCombatEntity.new(hostile_actor)))
	assert_true(ActorRules.is_combat_target_entity({"data": hostile_actor}))
	assert_false(ActorRules.is_combat_target_entity(null))


func test_actor_rules_pickpocket_uses_living_humanoid_inventory_owner() -> void:
	var humanoid := {
		"kind": "npc",
		"character_profile": {
			"character_id": "char_maera_pike",
			"people_id": "people_human",
			"state": "alive",
			"inventory_owner_id": "char_maera_pike"
		}
	}
	var body := humanoid.duplicate(true)
	body["kind"] = "body"
	var creature := {
		"kind": "npc",
		"actor_category": "creature",
		"character_profile_id": "char_wolf",
		"inventory_owner_id": "loot:wolf"
	}

	assert_true(ActorRules.can_pickpocket_data(humanoid))
	assert_false(ActorRules.can_pickpocket_data(body))
	assert_false(ActorRules.can_pickpocket_data(creature))
