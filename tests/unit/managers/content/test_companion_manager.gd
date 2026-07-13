extends GutTest

const CompanionManager = preload("res://scripts/managers/content/companion_manager.gd")
const EntityManager = preload("res://scripts/managers/world/entity_manager.gd")
const ChunkManager = preload("res://scripts/managers/world/chunk_manager.gd")
const ContentDatabase = preload("res://scripts/data/content_database.gd")
const CombatManager = preload("res://scripts/managers/actors/combat_manager.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")


class PlayerStub extends Node2D:
	var global_tile := Vector2i.ZERO
	var world_layer := "surface"

	func get_facing_direction() -> Vector2:
		return Vector2.DOWN


func test_resurrection_keeps_the_same_actor_and_inventory_owner_as_a_thrall() -> void:
	var entities := _entities()
	var actor = entities.get_entity("resident_world")
	entities.transition_actor_to_dead(actor)
	var manager := CompanionManager.new()
	add_child_autofree(manager)
	manager.setup(null, entities, _chunks(), null)
	var player := PlayerStub.new()
	add_child_autofree(player)
	manager.set_player(player)

	var result := manager.resurrect_as_thrall("resident_world")

	assert_true(result["ok"])
	assert_eq(entities.get_entity("resident_world"), actor)
	assert_eq(actor.data.get("state"), "alive")
	assert_eq(actor.data.get("inventory_owner_id"), "char_resident")
	assert_eq(actor.data.get("allegiance"), "thrall")
	assert_eq(actor.data.get("allegiance_owner_id"), "player")
	assert_eq(actor.data.get("brain_id"), "companion")
	assert_true(actor.humanoid_avatar.thrall_eyes)
	var saved: Dictionary = entities.get_save_data()["actor_life_states"]
	assert_eq(saved["resident_world"].get("allegiance"), "thrall")


func test_thrall_commands_and_save_data_persist() -> void:
	var entities := _entities()
	var actor = entities.get_entity("resident_world")
	entities.transition_actor_to_dead(actor)
	var manager := CompanionManager.new()
	add_child_autofree(manager)
	manager.setup(null, entities, _chunks(), null)
	var player := PlayerStub.new()
	add_child_autofree(player)
	manager.set_player(player)
	manager.resurrect_as_thrall("resident_world")

	var hold := manager.command("resident_world", "hold")
	var restored := CompanionManager.new()
	add_child_autofree(restored)
	restored.load_save_data(manager.get_save_data())

	assert_true(hold["ok"])
	assert_eq(actor.data.get("companion_command"), "hold")
	assert_true(restored.get_save_data()["companions_by_entity_id"].has("resident_world"))
	assert_false(manager.dismiss("resident_world")["ok"])


func test_thrall_catches_up_across_layers() -> void:
	var entities := _entities()
	var actor = entities.get_entity("resident_world")
	entities.transition_actor_to_dead(actor)
	var manager := CompanionManager.new()
	add_child_autofree(manager)
	manager.setup(null, entities, _chunks(), null)
	var player := PlayerStub.new()
	player.global_tile = Vector2i(12, 8)
	player.world_layer = "interior:test_portal"
	add_child_autofree(player)
	manager.set_player(player)
	manager.resurrect_as_thrall("resident_world")

	manager.update(0.1)

	assert_eq(actor.world_layer, "interior:test_portal")
	assert_lte(actor.global_tile.distance_to(player.global_tile), 3.0)


func test_thrall_assists_against_nearby_hostiles() -> void:
	var entities := _entities()
	var actor = entities.get_entity("resident_world")
	entities.transition_actor_to_dead(actor)
	var hostile = entities.add_runtime_entity({
		"id": "hostile_world",
		"name": "Hostile",
		"kind": "npc",
		"world_layer": "surface",
		"global_tile": [2, 2],
		"hostility": "hostile",
		"hostile_to_player": true,
		"combat_enabled": true,
		"max_health": 3,
		"character_profile": {
			"character_id": "char_hostile",
			"people_id": "human",
			"state": "alive",
			"appearance": {"palette_id": "palette_human_warm_brown"}
		}
	})
	var combat := CombatManager.new()
	add_child_autofree(combat)
	var manager := CompanionManager.new()
	add_child_autofree(manager)
	manager.setup(null, entities, _chunks(), combat)
	var player := PlayerStub.new()
	add_child_autofree(player)
	manager.set_player(player)
	manager.resurrect_as_thrall("resident_world")

	manager.update(0.1)

	assert_eq(hostile.data.get("state"), "dead")


func test_thrall_prioritizes_a_hostile_attacking_player_outside_its_old_assist_radius() -> void:
	var entities := _entities()
	var actor = entities.get_entity("resident_world")
	entities.transition_actor_to_dead(actor)
	var hostile = entities.add_runtime_entity({
		"id": "player_threat_world", "name": "Player Threat", "kind": "npc",
		"world_layer": "surface", "global_tile": [14, 2], "hostility": "hostile",
		"hostile_to_player": true, "combat_enabled": true, "max_health": 10,
		"character_profile": {
			"character_id": "char_player_threat", "people_id": "human", "state": "alive",
			"appearance": {"palette_id": "palette_human_warm_brown"}
		}
	})
	var manager := CompanionManager.new()
	add_child_autofree(manager)
	manager.setup(null, entities, _chunks(), null)
	var player := PlayerStub.new()
	player.global_tile = Vector2i(14, 2)
	player.global_position = hostile.global_position + Vector2(-8.0, 0.0)
	add_child_autofree(player)
	manager.set_player(player)
	manager.resurrect_as_thrall("resident_world")

	manager.update(0.1)

	assert_eq(actor.data.get("behavior_state"), "assisting")
	assert_gt(actor.global_position.x, 40.0)


func test_dead_thrall_loses_companion_state_and_never_catches_up_as_a_corpse() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var entities := _entities(bus)
	var actor = entities.get_entity("resident_world")
	entities.transition_actor_to_dead(actor)
	var manager := CompanionManager.new()
	add_child_autofree(manager)
	manager.setup(bus, entities, _chunks(), null)
	var player := PlayerStub.new()
	add_child_autofree(player)
	manager.set_player(player)
	manager.resurrect_as_thrall("resident_world")
	var corpse_layer: String = String(actor.world_layer)
	var corpse_tile: Vector2i = actor.global_tile

	entities.transition_actor_to_dead(actor)
	player.world_layer = "interior:test_portal"
	player.global_tile = Vector2i(12, 8)
	manager.update(0.1)

	assert_false(manager.is_player_owned(actor))
	assert_false(manager.get_save_data()["companions_by_entity_id"].has("resident_world"))
	assert_false(actor.data.has("allegiance_owner_id"))
	assert_eq(actor.world_layer, corpse_layer)
	assert_eq(actor.global_tile, corpse_tile)


func _entities(bus = null) -> EntityManager:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.world_objects = [{
		"id": "resident_world",
		"npc_id": "npc_resident",
		"name": "Resident",
		"kind": "npc",
		"world_layer": "surface",
		"global_tile": [2, 2],
		"inventory_owner_id": "char_resident",
		"character_profile": {
			"character_id": "char_resident",
			"people_id": "human",
			"state": "alive",
			"appearance": {"palette_id": "palette_human_warm_brown"}
		}
	}]
	var manager := EntityManager.new()
	add_child_autofree(manager)
	manager.setup(bus, content, _chunks())
	manager.spawn_all()
	return manager


func _chunks() -> ChunkManager:
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	return chunks
