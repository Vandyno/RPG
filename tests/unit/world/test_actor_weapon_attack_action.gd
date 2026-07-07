extends GutTest

const ActorWeaponAttackAction = preload("res://scripts/world/actor_weapon_attack_action.gd")


func test_weapon_action_delays_hit_until_active_swing_window() -> void:
	var calls: Array[String] = []
	var action := ActorWeaponAttackAction.new()
	add_child_autofree(action)
	var target := WeaponTargetStub.new("target", Vector2(40.0, 0.0))
	var targets_provider := func() -> Array: return [target]
	var hit_callback := func(hit_target, damage: int, source_name: String) -> void:
		calls.append("%s:%s:%d" % [source_name, hit_target.get_entity_id(), damage])
	action.setup(
		{
			"direction": Vector2.RIGHT,
			"attack":
			{
				"shape": "swing",
				"range_pixels": 52.0,
				"width_pixels": 18.0,
				"arc_degrees": 120.0,
				"hit_start_seconds": 0.08,
				"hit_end_seconds": 0.18,
				"action_duration_seconds": 0.22
			},
			"damage": 7,
			"source_name": "Training Sword",
			"targets_provider": targets_provider,
			"hit_callback": hit_callback,
			"resolve_immediately": false
		}
	)

	action._process(0.07)
	assert_eq(calls, [])

	action._process(0.06)
	assert_eq(calls, ["Training Sword:target:7"])


func test_weapon_action_origin_follows_source_weapon_hand_anchor() -> void:
	var source := WeaponSourceStub.new()
	add_child_autofree(source)
	source.global_position = Vector2(100.0, 50.0)
	var action := ActorWeaponAttackAction.new()
	add_child_autofree(action)

	action.setup(
		{
			"source_actor": source,
			"direction": Vector2.RIGHT,
			"attack": {"shape": "swing", "range_pixels": 52.0},
			"resolve_immediately": false
		}
	)

	assert_eq(action.global_position, Vector2(86.0, 45.0))


func test_melee_weapon_action_is_invisible_and_drives_source_attack_pose() -> void:
	var source := WeaponPoseSourceStub.new()
	add_child_autofree(source)
	var action := ActorWeaponAttackAction.new()
	add_child_autofree(action)

	action.setup(
		{
			"source_actor": source,
			"direction": Vector2.RIGHT,
			"attack": {"shape": "punch", "action_duration_seconds": 0.10},
			"resolve_immediately": false
		}
	)

	assert_false(action.visible)
	assert_eq(source.pose_shape, "punch")
	action._process(0.05)
	assert_gt(source.pose_progress, 0.0)
	action._process(0.10)
	assert_true(source.pose_cleared)


func test_projectile_action_is_visible_and_starts_at_bow_hand_anchor() -> void:
	var source := WeaponSourceStub.new()
	add_child_autofree(source)
	source.global_position = Vector2(100.0, 50.0)
	var action := ActorWeaponAttackAction.new()
	add_child_autofree(action)

	action.setup(
		{
			"source_actor": source,
			"direction": Vector2.RIGHT,
			"attack": {"shape": "projectile", "range_pixels": 120.0},
			"resolve_immediately": false
		}
	)

	assert_true(action.visible)
	assert_eq(action.global_position, Vector2(120.0, 52.0))


class WeaponSourceStub:
	extends Node2D

	func get_body_part_anchors() -> Dictionary:
		return {
			"right_hand": Vector2(12.0, -4.0),
			"left_hand": Vector2(-10.0, -3.0),
			"weapon_hand": Vector2(-14.0, -5.0),
			"bow_hand": Vector2(14.0, 2.0)
		}


class WeaponPoseSourceStub:
	extends Node2D

	var pose_shape := ""
	var pose_progress := -1.0
	var pose_cleared := false

	func get_body_part_anchors() -> Dictionary:
		return {"right_hand": Vector2(8.0, 0.0), "left_hand": Vector2(-8.0, 0.0)}

	func set_attack_pose(attack_data: Dictionary, _direction: Vector2, progress: float) -> void:
		pose_shape = String(attack_data.get("shape", ""))
		pose_progress = progress
		pose_cleared = false

	func clear_attack_pose() -> void:
		pose_cleared = true


class WeaponTargetStub:
	extends RefCounted

	var id: String
	var global_position: Vector2

	func _init(target_id: String, position: Vector2) -> void:
		id = target_id
		global_position = position

	func get_entity_id() -> String:
		return id
