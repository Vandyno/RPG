extends GutTest

const CombatActionEffect = preload("res://scripts/world/combat_action_effect.gd")


func test_setup_normalizes_direction_and_copies_attack_data() -> void:
	var effect := CombatActionEffect.new()
	add_child_autofree(effect)
	var attack := {"range_pixels": 80.0, "nested": {"damage": 3}}

	effect.setup("projectile", Vector2(24.0, 40.0), Vector2(3.0, 4.0), attack)
	attack["nested"]["damage"] = 9

	assert_eq(effect.effect_kind, "projectile")
	assert_eq(effect.global_position, Vector2(24.0, 40.0))
	assert_true(effect.direction.is_equal_approx(Vector2(0.6, 0.8)))
	assert_eq(effect.attack["nested"]["damage"], 3)
	assert_eq(effect.z_index, 80)
	assert_eq(effect.ttl, 0.22)


func test_setup_uses_right_direction_fallback_and_fire_ttl() -> void:
	var effect := CombatActionEffect.new()
	add_child_autofree(effect)

	effect.setup("fire_stream", Vector2.ZERO, Vector2.ZERO, {})

	assert_eq(effect.direction, Vector2.RIGHT)
	assert_eq(effect.ttl, 0.10)


func test_charge_and_thrall_effects_use_their_short_cast_ttls() -> void:
	var charge := CombatActionEffect.new()
	var raise := CombatActionEffect.new()
	add_child_autofree(charge)
	add_child_autofree(raise)

	charge.setup("charge_cast", Vector2.ZERO, Vector2.RIGHT, {"visual_tint": [0.72, 0.24, 1.0]})
	raise.setup("raise_thrall", Vector2.ZERO, Vector2.RIGHT, {"visual_tint": [0.72, 0.24, 1.0]})

	assert_eq(charge.ttl, 0.16)
	assert_eq(raise.ttl, 0.48)


func test_process_queues_effect_after_ttl() -> void:
	var effect := CombatActionEffect.new()
	add_child_autofree(effect)
	effect.setup("swing", Vector2.ZERO, Vector2.RIGHT, {})

	effect._process(effect.ttl + 0.01)

	assert_true(effect.is_queued_for_deletion())
