extends SceneTree

const Main = preload("res://scripts/main/main.gd")


func _initialize() -> void:
	_verify.call_deferred()


func _verify() -> void:
	root.size = Vector2i(1152, 648)
	var main := Main.new()
	root.add_child(main)
	await process_frame
	await process_frame

	main.hud._apply_layout_for_size(Vector2(root.size))
	main.hud.refresh()
	await process_frame

	var button: Button = main.hud.target_action_button
	if not button:
		printerr("Sneak button missing.")
		quit(1)
		return
	var click_position: Vector2 = button.get_global_rect().get_center()
	_push_click(click_position)
	await process_frame
	await process_frame

	if not main.player.is_sneaking:
		printerr("Sneak button GUI click did not toggle player sneak.")
		quit(1)
		return
	if not main.player.humanoid_avatar.is_sneaking:
		printerr("Sneak button click did not update avatar sneak.")
		quit(1)
		return
	if not main.hud.message_log.has("Sneaking."):
		printerr("Sneak button click did not post Sneaking message.")
		quit(1)
		return

	_push_click(click_position)
	await process_frame
	await process_frame
	if main.player.is_sneaking:
		printerr("Second sneak button click did not return player to standing.")
		quit(1)
		return
	if not main.hud.message_log.has("Standing."):
		printerr("Second sneak button click did not post Standing message.")
		quit(1)
		return

	print("Sneak HUD click verified.")
	quit()


func _push_click(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	root.push_input(motion)

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	root.push_input(press)

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = position
	release.global_position = position
	root.push_input(release)
