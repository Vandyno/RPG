extends SceneTree

const Main = preload("res://scripts/main/main.gd")

const DEFAULT_MODE := "walk"
const DEFAULT_DIRECTION := "down"
const CAMERA_ZOOM := Vector2(4.0, 4.0)
const ANIMATION_TIME := PI * 0.5


func _initialize() -> void:
	_setup_pose.call_deferred()


func _setup_pose() -> void:
	var config := pose_config(OS.get_cmdline_user_args())
	var mode := String(config["mode"])
	var direction: Vector2 = config["direction"]

	var main := Main.new()
	root.add_child(main)
	await process_frame
	await process_frame

	apply_pose(main, mode, direction)


static func pose_config(args: PackedStringArray) -> Dictionary:
	var direction_name := arg(args, 1, DEFAULT_DIRECTION)
	return {
		"mode": arg(args, 0, DEFAULT_MODE),
		"direction_name": direction_name,
		"direction": direction_vector(direction_name)
	}


static func apply_pose(main, mode: String, direction: Vector2) -> void:
	var sneaking := mode == "sneak"
	main.set_process(false)
	main.player.set_process(false)
	main.hud.visible = false
	main.camera.zoom = CAMERA_ZOOM
	main.camera.position = main.player.position

	main.player.set_sneaking(sneaking)
	main.player.set_facing_direction(direction)
	main.player.humanoid_avatar.locomotion_state = (
		HumanoidAvatar2D.LOCOMOTION_SNEAK if sneaking else HumanoidAvatar2D.LOCOMOTION_WALK
	)
	main.player.humanoid_avatar.is_sneaking = sneaking
	main.player.humanoid_avatar.move_intensity = 1.0
	main.player.humanoid_avatar.animation_time = ANIMATION_TIME
	main.player.humanoid_avatar.queue_redraw()


static func direction_vector(direction_name: String) -> Vector2:
	match direction_name:
		"up":
			return Vector2.UP
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
	return Vector2.DOWN


static func arg(args: PackedStringArray, index: int, fallback: String) -> String:
	if index >= args.size() or args[index].is_empty():
		return fallback
	return args[index]
