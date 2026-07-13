extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const VerifyInputHelper = preload("res://scripts/tools/verify/verify_input_helper.gd")

const VERIFY_SIZE := Vector2i(1152, 648)
const SNEAK_ON_MESSAGE := "Sneaking."
const SNEAK_OFF_MESSAGE := "Standing."


func _initialize() -> void:
	_verify.call_deferred()


func _verify() -> void:
	root.size = VERIFY_SIZE
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

	if not player_and_avatar_are_sneaking(main):
		printerr("Sneak button GUI click did not toggle player sneak.")
		quit(1)
		return
	if not message_log_has(main, SNEAK_ON_MESSAGE):
		printerr("Sneak button click did not post Sneaking message.")
		quit(1)
		return

	await _click(button)
	await process_frame
	await process_frame
	if not player_and_avatar_are_standing(main):
		printerr("Second sneak button click did not return player to standing.")
		quit(1)
		return
	if not message_log_has(main, SNEAK_OFF_MESSAGE):
		printerr("Second sneak button click did not post Standing message.")
		quit(1)
		return

	print("Sneak HUD click verified.")
	quit()


func _click(button: Button) -> void:
	await VerifyInputHelper.real_click_button(self, root, button)


static func player_and_avatar_are_sneaking(main) -> bool:
	return bool(main.player.is_sneaking) and bool(main.player.humanoid_avatar.is_sneaking)


static func player_and_avatar_are_standing(main) -> bool:
	return not bool(main.player.is_sneaking) and not bool(main.player.humanoid_avatar.is_sneaking)


static func message_log_has(main, message: String) -> bool:
	return main.hud.message_log.has(message)
