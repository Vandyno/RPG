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
	await _click(button)
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

	await _click(button)
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


func _click(button: Button) -> void:
	if not button.visible or not button.is_visible_in_tree():
		return
	await _push_click(button.get_viewport(), button.get_global_rect().get_center())
	await process_frame
	await process_frame


func _push_click(viewport: Viewport, position: Vector2) -> void:
	await _push_motion(viewport, position)

	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	viewport.push_input(press, true)
	await process_frame

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.button_mask = 0
	release.pressed = false
	release.position = position
	release.global_position = position
	viewport.push_input(release, true)
	await process_frame


func _push_motion(viewport: Viewport, position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	motion.button_mask = 0
	viewport.push_input(motion, true)
	await process_frame
