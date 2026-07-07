extends GutTest

const GridMath = preload("res://scripts/core/grid_math.gd")
const Main = preload("res://scripts/main/main.gd")
const HostileActorBrain = preload("res://scripts/main/runtime/hostile_actor_brain.gd")
const MainSystemsActions = preload("res://scripts/main/actions/main_systems_actions.gd")
const PlayerController = preload("res://scripts/player/player_controller.gd")
const WorldEntity = preload("res://scripts/world/world_entity.gd")


class BlockingChunks:
	var blocked_tiles: Dictionary = {}

	func block(tile: Vector2i) -> void:
		blocked_tiles["%d:%d" % [tile.x, tile.y]] = true

	func is_walkable(tile: Vector2i) -> bool:
		return not blocked_tiles.has("%d:%d" % [tile.x, tile.y])


class ContentStub:
	func get_item(item_id: String) -> Dictionary:
		if item_id != "item_training_sword":
			return {}
		return {
			"id": "item_training_sword",
			"name": "Training Sword",
			"weapon_attack":
			{
				"shape": "swing",
				"range_pixels": 50,
				"width_pixels": 38,
				"arc_degrees": 125,
				"damage": 5,
				"attack_interval_seconds": 0.55,
				"visual": "swing"
			}
		}

	func get_spell(_spell_id: String) -> Dictionary:
		return {}


class EntitiesStub:
	var entities_by_id: Dictionary = {}


class BrainMainStub:
	extends Node
	var player
	var entities
	var content
	var chunks
	var event_bus = null


func test_hostile_actor_brain_moves_actor_toward_player() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.set_process(false)
	var actor = _place_player_by_actor(main, "npc_people_test_human", Vector2(96.0, 0.0))
	_keep_only_brain(main, "npc_people_test_human")
	var start_position: Vector2 = actor.global_position
	var start_distance := start_position.distance_to(main.player.global_position)

	HostileActorBrain.update(main, 0.25)

	assert_gt(actor.global_position.x, start_position.x)
	assert_lt(actor.global_position.distance_to(main.player.global_position), start_distance)
	assert_eq(actor.data["behavior_state"], "chasing")


func test_hostile_actor_brain_attacks_with_equipped_weapon_shape() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.set_process(false)
	var actor = _place_player_by_actor(main, "npc_people_test_human", Vector2(40.0, 0.0))
	_keep_only_brain(main, "npc_people_test_human")
	main.player.set_health(main.player.max_health)

	HostileActorBrain.update(main, 0.1)
	var health_after_first_attack: int = main.player.health
	HostileActorBrain.update(main, 0.1)

	assert_eq(health_after_first_attack, 95)
	assert_eq(main.player.health, health_after_first_attack)
	assert_eq(actor.data["behavior_state"], "attacking")
	assert_true(main.hud.log_label.text.contains("hits you with Training Sword for 5"))


func test_ravenfolk_test_actor_can_cast_fire_spell() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.set_process(false)
	var actor = _place_player_by_actor(main, "npc_people_test_ravenfolk", Vector2(80.0, 0.0))
	_keep_only_brain(main, "npc_people_test_ravenfolk")
	assert_true(bool(actor.data.get("use_spells", false)))
	assert_eq(actor.data["loadout_slots"]["ability_1"], "spell_fire_blast")
	main.player.set_health(main.player.max_health)

	HostileActorBrain.update(main, 1.0)

	assert_eq(main.player.health, 92)
	assert_eq(actor.data["behavior_state"], "attacking")
	assert_true(main.hud.log_label.text.contains("channels Fire Blast for 8"))


func test_regular_npc_without_brain_does_not_attack() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.set_process(false)
	var harrow = main.entities.get_entity("npc_harrow_venn_world")
	assert_not_null(harrow)
	main.player.set_world_position(harrow.global_position + Vector2(24.0, 0.0))
	main.player.set_health(main.player.max_health)

	HostileActorBrain.update(main, 1.0)

	assert_eq(main.player.health, main.player.max_health)
	assert_false(harrow.data.has("behavior_state"))


func test_hostile_actor_returns_home_after_leash_breaks() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.set_process(false)
	var actor = _place_player_by_actor(main, "npc_people_test_human", Vector2(96.0, 0.0))
	_keep_only_brain(main, "npc_people_test_human")
	actor.data["leash_radius"] = 80
	actor.data["disengage_radius"] = 120
	var home_position: Vector2 = actor.global_position

	HostileActorBrain.update(main, 0.5)
	actor = main.entities.get_entity("npc_people_test_human")
	assert_gt(actor.global_position.distance_to(home_position), 1.0)
	var distance_after_chase: float = actor.global_position.distance_to(home_position)

	main.player.set_world_position(home_position + Vector2(220.0, 0.0))
	actor = main.entities.get_entity("npc_people_test_human")
	_keep_only_brain(main, "npc_people_test_human")
	actor.data["leash_radius"] = 80
	actor.data["disengage_radius"] = 120

	HostileActorBrain.update(main, 0.5)

	assert_eq(actor.data["behavior_state"], "returning")
	assert_lt(actor.global_position.distance_to(home_position), distance_after_chase)


func test_hostile_actor_brain_uses_path_around_blocked_tile() -> void:
	var chunks := BlockingChunks.new()
	chunks.block(Vector2i(1, 0))
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, chunks, Vector2i(5, 0))
	var actor := WorldEntity.new()
	add_child_autofree(actor)
	actor.setup(
		{
			"id": "npc_path_test",
			"name": "Path Test Actor",
			"kind": "npc",
			"actor_category": "humanoid",
			"hostility": "hostile",
			"combat_enabled": true,
			"brain_id": "hostile_basic",
			"global_tile": [0, 0],
			"home_tile": [0, 0],
			"aggro_radius": 180,
			"move_speed": 80,
			"equipped_items": {"right_hand": "item_training_sword"}
		},
		null
	)
	var main := BrainMainStub.new()
	add_child_autofree(main)
	main.player = player
	main.chunks = chunks
	main.content = ContentStub.new()
	main.entities = EntitiesStub.new()
	main.entities.entities_by_id[actor.get_entity_id()] = actor
	var start_position: Vector2 = actor.global_position

	HostileActorBrain.update(main, 0.25)

	assert_gt(actor.global_position.y, start_position.y)
	assert_gt(actor.global_position.distance_to(start_position), 1.0)


func test_moved_hostile_actor_keeps_position_after_entity_refresh() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.set_process(false)
	var actor = _place_player_by_actor(main, "npc_people_test_human", Vector2(96.0, 0.0))
	_keep_only_brain(main, "npc_people_test_human")
	var spawn_position: Vector2 = actor.global_position

	HostileActorBrain.update(main, 0.5)
	actor = main.entities.get_entity("npc_people_test_human")
	var moved_position: Vector2 = actor.global_position
	assert_gt(moved_position.distance_to(spawn_position), 1.0)

	main.entities.spawn_all()
	actor = main.entities.get_entity("npc_people_test_human")

	assert_not_null(actor)
	assert_lt(actor.global_position.distance_to(moved_position), 0.01)


func test_moved_hostile_actor_defeat_stays_removed_from_authored_spawn() -> void:
	var main := Main.new()
	add_child_autofree(main)
	main.set_process(false)
	var actor = _place_player_by_actor(main, "npc_people_test_human", Vector2(96.0, 0.0))
	_keep_only_brain(main, "npc_people_test_human")
	var spawn_tile: Vector2i = actor.global_tile

	HostileActorBrain.update(main, 0.5)
	actor = main.entities.get_entity("npc_people_test_human")
	assert_ne(actor.global_tile, spawn_tile)

	_attack_actor_until_defeated(main, "npc_people_test_human")

	assert_null(main.entities.get_entity("npc_people_test_human"))
	assert_true(main.chunks.is_entity_removed("npc_people_test_human", spawn_tile))
	main.entities.spawn_all()
	assert_null(main.entities.get_entity("npc_people_test_human"))


func _place_player_by_actor(main, entity_id: String, offset: Vector2):
	var actor = main.entities.get_entity(entity_id)
	assert_not_null(actor)
	var player_position: Vector2 = actor.global_position + offset
	main.player.set_world_position(player_position)
	actor = main.entities.get_entity(entity_id)
	assert_not_null(actor)
	return actor


func _keep_only_brain(main, kept_entity_id: String) -> void:
	for entity in main.entities.entities_by_id.values():
		if not entity or not (entity.data is Dictionary):
			continue
		if entity.get_entity_id() != kept_entity_id and entity.data.has("brain_id"):
			entity.data["brain_id"] = ""


func _attack_actor_until_defeated(main, entity_id: String) -> void:
	for _i in range(8):
		var actor = main.entities.get_entity(entity_id)
		if not actor:
			return
		main.player.set_world_position(actor.global_position + Vector2(-8.0, 0.0))
		main.player.set_facing_direction(Vector2.RIGHT)
		MainSystemsActions.handle_aim(
			MainSystemsActions.aim_context(main),
			"attack",
			actor.global_position - main.player.global_position
		)
