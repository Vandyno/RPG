extends GutTest

const HostileActorBrain = preload("res://scripts/main/runtime/hostile_actor_brain.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")


class ActorStub:
	var data: Dictionary

	func _init(actor_data: Dictionary) -> void:
		data = actor_data


func test_basic_brain_requires_hostile_living_actor_contract() -> void:
	var actor := ActorStub.new(
		{
			"brain_id": HostileActorBrain.BASIC_BRAIN_ID,
			"kind": "npc",
			"hostility": "hostile",
			"character_profile_id": "char_bandit",
			"state": "alive"
		}
	)
	var passive := ActorStub.new(actor.data.duplicate())
	passive.data["hostility"] = "neutral"

	assert_true(HostileActorBrain._uses_basic_brain(actor))
	assert_false(HostileActorBrain._uses_basic_brain(passive))


func test_home_position_prefers_authored_home_then_spawn_then_global_tile() -> void:
	var authored := {"home_position": [12, 34], "global_tile": [5, 5]}
	var spawn := {"_spawn_global_tile": [2, 3], "global_tile": [5, 5]}
	var global := {"global_tile": [4, 1]}

	assert_eq(HostileActorBrain._home_position(authored), Vector2(12, 34))
	assert_eq(HostileActorBrain._home_position(spawn), _tile_center(Vector2i(2, 3)))
	assert_eq(HostileActorBrain._home_position(global), _tile_center(Vector2i(4, 1)))


func test_cooldowns_and_path_fields_sanitize_malformed_runtime_data() -> void:
	var data := {
		"_brain_attack_cooldown": 1.0,
		"_brain_path_cooldown": "bad",
		"_brain_spell_effect_cooldown": 0.05,
		"_brain_path": [Vector2(1, 2), "bad"],
		"_brain_path_index": 4,
		"_brain_path_destination": ["x", 9]
	}

	HostileActorBrain._tick_cooldown(data, 0.25)

	assert_almost_eq(float(data["_brain_attack_cooldown"]), 0.75, 0.001)
	assert_eq(float(data["_brain_path_cooldown"]), 0.0)
	assert_eq(float(data["_brain_spell_effect_cooldown"]), 0.0)
	assert_eq(HostileActorBrain._current_path(data), [Vector2(1, 2)])
	assert_eq(
		VariantFields.vector2_from_pair(data["_brain_path_destination"], Vector2(7, 8)),
		Vector2(7, 8)
	)


func test_spell_damage_uses_interval_for_channeled_damage() -> void:
	var spell := {"mana_cost": 4}
	var direct_attack := {"damage": 7}
	var stream_attack := {"damage_per_second": 3.0}

	assert_eq(HostileActorBrain._spell_damage_for_interval(spell, direct_attack, 0.2), 7)
	assert_eq(HostileActorBrain._spell_damage_for_interval(spell, stream_attack, 0.5), 2)


func _tile_center(tile: Vector2i) -> Vector2:
	return GridMath.tile_to_world(tile) + Vector2(GridMath.TILE_SIZE, GridMath.TILE_SIZE) * 0.5
