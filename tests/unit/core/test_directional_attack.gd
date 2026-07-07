extends GutTest

const DirectionalAttack = preload("res://scripts/core/directional_attack.gd")


func _attack_query(attack: Dictionary, direction: Vector2 = Vector2.RIGHT) -> Dictionary:
	return {"origin": Vector2.ZERO, "direction": direction, "attack": attack}


func _sweep_query(attack: Dictionary, progress_from: float, progress_to: float) -> Dictionary:
	return {
		"origin": Vector2.ZERO,
		"direction": Vector2.RIGHT,
		"attack": attack,
		"progress_from": progress_from,
		"progress_to": progress_to
	}


func test_empty_hand_attack_is_punch_not_weapon_swing() -> void:
	var attack := DirectionalAttack.weapon_attack_from_item({})

	assert_eq(attack["name"], "Unarmed")
	assert_eq(attack["shape"], "punch")
	assert_eq(attack["range_pixels"], 34.0)
	assert_eq(attack["width_pixels"], 26.0)
	assert_eq(attack["visual"], "punch")
	assert_false(attack.has("item_id"))


func test_thrust_hits_narrow_forward_line() -> void:
	var attack := {"shape": "thrust", "range_pixels": 80.0, "width_pixels": 18.0}

	assert_true(DirectionalAttack.contains_point(Vector2(70, 0), _attack_query(attack)))
	assert_true(DirectionalAttack.contains_point(Vector2(35, 8), _attack_query(attack)))
	assert_false(DirectionalAttack.contains_point(Vector2(35, 14), _attack_query(attack)))
	assert_false(DirectionalAttack.contains_point(Vector2(-12, 0), _attack_query(attack)))


func test_swing_hits_front_arc_and_misses_behind() -> void:
	var attack := {
		"shape": "swing", "range_pixels": 52.0, "width_pixels": 38.0, "arc_degrees": 120.0
	}

	assert_true(DirectionalAttack.contains_point(Vector2(38, 18), _attack_query(attack)))
	assert_true(DirectionalAttack.contains_point(Vector2(38, -18), _attack_query(attack)))
	assert_false(DirectionalAttack.contains_point(Vector2(-12, 0), _attack_query(attack)))
	assert_false(DirectionalAttack.contains_point(Vector2(60, 0), _attack_query(attack)))


func test_weapon_swing_sweep_hits_when_blade_reaches_target_angle() -> void:
	var attack := {
		"shape": "swing", "range_pixels": 52.0, "width_pixels": 18.0, "arc_degrees": 120.0
	}
	var target := Vector2(40.0, 0.0)

	assert_false(
		DirectionalAttack.weapon_sweep_contains_point(target, _sweep_query(attack, 0.0, 0.2))
	)
	assert_true(
		DirectionalAttack.weapon_sweep_contains_point(target, _sweep_query(attack, 0.4, 0.6))
	)


func test_stream_widens_over_range() -> void:
	var attack := {"shape": "stream", "range_pixels": 96.0, "width_pixels": 50.0}

	assert_true(DirectionalAttack.contains_point(Vector2(12, 2), _attack_query(attack)))
	assert_false(DirectionalAttack.contains_point(Vector2(12, 12), _attack_query(attack)))
	assert_true(DirectionalAttack.contains_point(Vector2(90, 20), _attack_query(attack)))
	assert_false(DirectionalAttack.contains_point(Vector2(104, 0), _attack_query(attack)))


func test_projectile_uses_bow_line_shape() -> void:
	var attack := {"shape": "projectile", "range_pixels": 150.0, "width_pixels": 14.0}

	assert_true(DirectionalAttack.contains_point(Vector2(145, 6), _attack_query(attack)))
	assert_false(DirectionalAttack.contains_point(Vector2(145, 12), _attack_query(attack)))


func test_targets_in_shape_uses_continuous_aim_not_visual_bucket() -> void:
	var attack := {"shape": "projectile", "range_pixels": 96.0, "width_pixels": 10.0}
	var raw_direction := Vector2(1.0, 0.31).normalized()
	var bucket_direction := Vector2(cos(PI / 8.0), sin(PI / 8.0)).normalized()
	var raw_target := AttackEntityStub.new("raw_target", raw_direction * 88.0)
	var bucket_target := AttackEntityStub.new("bucket_target", bucket_direction * 88.0)

	var targets := DirectionalAttack.targets_in_shape(
		[raw_target, bucket_target], _attack_query(attack, raw_direction)
	)

	assert_eq(targets, [raw_target])


class AttackEntityStub:
	extends RefCounted

	var id: String
	var global_position: Vector2

	func _init(entity_id: String, position: Vector2) -> void:
		id = entity_id
		global_position = position

	func get_entity_id() -> String:
		return id

	func get_kind() -> String:
		return "npc"

	func is_combat_target() -> bool:
		return true
