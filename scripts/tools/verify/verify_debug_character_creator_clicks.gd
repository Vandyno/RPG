# gdlint:disable=max-returns
extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const VerifyInputHelper = preload("res://scripts/tools/verify/verify_input_helper.gd")


func _initialize() -> void:
	_verify.call_deferred()


func _verify() -> void:
	root.size = Vector2i(1152, 648)
	var main := Main.new()
	root.add_child(main)
	await _settle(main)

	await _push_key(KEY_P)
	await _settle(main)
	if not main.debug_character_creator.is_open():
		return _fail("P key did not open the debug character creator.")

	var next_people := VerifyInputHelper.find_button(
		main.debug_character_creator.root,
		"CreatorNextPeopleButton"
	)
	if not next_people:
		return _fail("Creator next-people button missing.")
	await _click(next_people)
	if main.debug_character_creator.get_current_people_id() != "people_tanglekin":
		return _fail("Creator next-people real click did not cycle to Tanglekin.")

	var next_variant := VerifyInputHelper.find_button(
		main.debug_character_creator.root,
		"CreatorNextVariantButton"
	)
	if not next_variant:
		return _fail("Creator next-variant button missing.")
	await _click(next_variant)
	if main.debug_character_creator.get_current_variant_id().is_empty():
		return _fail("Creator next-variant real click did not select a variant.")

	var next_gear := VerifyInputHelper.find_button(
		main.debug_character_creator.root,
		"CreatorNextGearButton"
	)
	if not next_gear:
		return _fail("Creator next-gear button missing.")
	await _click(next_gear)
	if main.debug_character_creator.get_current_gear_id() == "none":
		return _fail("Creator next-gear real click did not select preview gear.")

	var apply := VerifyInputHelper.find_button(main.debug_character_creator.root, "CreatorApplyButton")
	if not apply:
		return _fail("Creator apply button missing.")
	await _click(apply)
	if main.player.humanoid_profile.get("people_id") != "people_tanglekin":
		return _fail("Creator apply real click did not update player appearance.")
	if Dictionary(main.player.humanoid_profile.get("appearance", {})).get("visual_model_id", "") == "":
		return _fail("Creator apply did not keep a visual model id.")

	var close := VerifyInputHelper.find_button(main.debug_character_creator.root, "CreatorCloseButton")
	if not close:
		return _fail("Creator close button missing.")
	await _click(close)
	if main.debug_character_creator.is_open():
		return _fail("Creator close real click did not close the panel.")

	print("Debug character creator key and clicks verified.")
	quit()


func _click(button: Button) -> void:
	await VerifyInputHelper.real_click_button(self, root, button)


func _push_key(keycode: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.pressed = true
	root.push_input(press)
	await process_frame

	var release := InputEventKey.new()
	release.keycode = keycode
	release.pressed = false
	root.push_input(release)
	await process_frame


func _settle(main) -> void:
	await VerifyInputHelper.settle_main(self, main, root.size)


func _fail(message: String) -> bool:
	printerr(message)
	quit(1)
	return false
