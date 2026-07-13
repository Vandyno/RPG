extends GutTest

const HumanoidPoseMovie = preload("res://scripts/tools/visuals/humanoid_pose_movie.gd")
const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")


class AvatarStub:
	extends RefCounted

	var locomotion_state := ""
	var is_sneaking := false
	var move_intensity := 0.0
	var animation_time := 0.0
	var redraw_calls := 0

	func queue_redraw() -> void:
		redraw_calls += 1


class PlayerStub:
	extends RefCounted

	var humanoid_avatar := AvatarStub.new()
	var process_values: Array[bool] = []
	var sneaking_values: Array[bool] = []
	var facing_values: Array[Vector2] = []
	var position := Vector2(12, 34)

	func set_process(value: bool) -> void:
		process_values.append(value)

	func set_sneaking(value: bool) -> void:
		sneaking_values.append(value)

	func set_facing_direction(value: Vector2) -> void:
		facing_values.append(value)


class HudStub:
	extends RefCounted

	var visible := true


class CameraStub:
	extends RefCounted

	var zoom := Vector2.ONE
	var position := Vector2.ZERO


class MainStub:
	extends RefCounted

	var player := PlayerStub.new()
	var hud := HudStub.new()
	var camera := CameraStub.new()
	var process_values: Array[bool] = []

	func set_process(value: bool) -> void:
		process_values.append(value)


func test_pose_config_uses_defaults_and_reads_mode_direction() -> void:
	assert_eq(
		HumanoidPoseMovie.pose_config(PackedStringArray()),
		{"mode": "walk", "direction_name": "down", "direction": Vector2.DOWN}
	)
	assert_eq(
		HumanoidPoseMovie.pose_config(PackedStringArray(["sneak", "left"])),
		{"mode": "sneak", "direction_name": "left", "direction": Vector2.LEFT}
	)


func test_direction_vector_maps_cardinal_names_with_down_fallback() -> void:
	assert_eq(HumanoidPoseMovie.direction_vector("up"), Vector2.UP)
	assert_eq(HumanoidPoseMovie.direction_vector("left"), Vector2.LEFT)
	assert_eq(HumanoidPoseMovie.direction_vector("right"), Vector2.RIGHT)
	assert_eq(HumanoidPoseMovie.direction_vector("down"), Vector2.DOWN)
	assert_eq(HumanoidPoseMovie.direction_vector("bad"), Vector2.DOWN)


func test_arg_returns_fallback_for_missing_or_blank_values() -> void:
	assert_eq(HumanoidPoseMovie.arg(PackedStringArray(), 0, "walk"), "walk")
	assert_eq(HumanoidPoseMovie.arg(PackedStringArray([""]), 0, "walk"), "walk")
	assert_eq(HumanoidPoseMovie.arg(PackedStringArray(["sneak"]), 0, "walk"), "sneak")


func test_apply_pose_freezes_scene_and_sets_walk_avatar_state() -> void:
	var main := MainStub.new()

	HumanoidPoseMovie.apply_pose(main, "walk", Vector2.RIGHT)

	assert_eq(main.process_values, [false])
	assert_eq(main.player.process_values, [false])
	assert_false(main.hud.visible)
	assert_eq(main.camera.zoom, HumanoidPoseMovie.CAMERA_ZOOM)
	assert_eq(main.camera.position, main.player.position)
	assert_eq(main.player.sneaking_values, [false])
	assert_eq(main.player.facing_values, [Vector2.RIGHT])
	assert_eq(main.player.humanoid_avatar.locomotion_state, HumanoidAvatar2D.LOCOMOTION_WALK)
	assert_false(main.player.humanoid_avatar.is_sneaking)
	assert_eq(main.player.humanoid_avatar.move_intensity, 1.0)
	assert_eq(main.player.humanoid_avatar.animation_time, HumanoidPoseMovie.ANIMATION_TIME)
	assert_eq(main.player.humanoid_avatar.redraw_calls, 1)


func test_apply_pose_sets_sneak_avatar_state() -> void:
	var main := MainStub.new()

	HumanoidPoseMovie.apply_pose(main, "sneak", Vector2.UP)

	assert_eq(main.player.sneaking_values, [true])
	assert_eq(main.player.humanoid_avatar.locomotion_state, HumanoidAvatar2D.LOCOMOTION_SNEAK)
	assert_true(main.player.humanoid_avatar.is_sneaking)
