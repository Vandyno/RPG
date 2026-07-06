extends SceneTree

const Main = preload("res://scripts/main/main.gd")


func _initialize() -> void:
	_setup_pose.call_deferred()


func _setup_pose() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := _arg(args, 0, "walk")
	var direction_name := _arg(args, 1, "down")
	var direction := _direction_vector(direction_name)
	var sneaking := mode == "sneak"

	var main := Main.new()
	root.add_child(main)
	await process_frame
	await process_frame

	main.set_process(false)
	main.player.set_process(false)
	main.hud.visible = false
	main.camera.zoom = Vector2(4.0, 4.0)
	main.camera.position = main.player.position

	main.player.set_sneaking(sneaking)
	main.player.set_facing_direction(direction)
	main.player.humanoid_avatar.locomotion_state = (
		HumanoidAvatar2D.LOCOMOTION_SNEAK if sneaking else HumanoidAvatar2D.LOCOMOTION_WALK
	)
	main.player.humanoid_avatar.is_sneaking = sneaking
	main.player.humanoid_avatar.move_intensity = 1.0
	main.player.humanoid_avatar.animation_time = PI * 0.5
	main.player.humanoid_avatar.queue_redraw()


func _direction_vector(direction_name: String) -> Vector2:
	match direction_name:
		"up":
			return Vector2.UP
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
	return Vector2.DOWN


func _arg(args: PackedStringArray, index: int, fallback: String) -> String:
	if index >= args.size() or args[index].is_empty():
		return fallback
	return args[index]
