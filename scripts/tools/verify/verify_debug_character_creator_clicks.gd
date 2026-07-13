# gdlint:disable=max-returns
extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const VerifyInputHelper = preload("res://scripts/tools/verify/verify_input_helper.gd")

const VERIFY_SIZE := Vector2i(1152, 648)
const NEXT_PEOPLE_BUTTON := "CreatorNextPeopleButton"
const NEXT_VARIANT_BUTTON := "CreatorNextVariantButton"
const NEXT_EYES_BUTTON := "CreatorNextEyesButton"
const NEXT_FACE_VALUE_BUTTON := "CreatorNextFaceValueButton"
const NEXT_GEAR_BUTTON := "CreatorNextGearButton"
const APPLY_BUTTON := "CreatorApplyButton"
const CLOSE_BUTTON := "CreatorCloseButton"
const EXPECTED_NEXT_PEOPLE_ID := "people_tanglekin"


func _initialize() -> void:
	_verify.call_deferred()


func _verify() -> void:
	root.size = VERIFY_SIZE
	var main := Main.new()
	root.add_child(main)
	await VerifyInputHelper.settle_main(self, main, root.size)
	if not await VerifyInputHelper.start_new_game(self, root, main):
		return _fail("New Game real click did not begin play.")

	await VerifyInputHelper.push_key(self, root, KEY_P)
	await VerifyInputHelper.settle_main(self, main, root.size)
	if not main.debug_character_creator.is_open():
		return _fail("P key did not open the debug character creator.")

	var next_eyes := VerifyInputHelper.find_button(
		main.debug_character_creator.root,
		NEXT_EYES_BUTTON
	)
	if not next_eyes:
		return _fail("Creator next-eyes button missing.")
	await VerifyInputHelper.real_click_button(self, root, next_eyes)
	if main.debug_character_creator.get_current_eye_id() != "eyes_human_soft":
		return _fail("Creator next-eyes real click did not select soft eyes.")

	var next_face_value := VerifyInputHelper.find_button(
		main.debug_character_creator.root,
		NEXT_FACE_VALUE_BUTTON
	)
	if not next_face_value:
		return _fail("Creator next-face-value button missing.")
	await VerifyInputHelper.real_click_button(self, root, next_face_value)
	if main.debug_character_creator.get_current_face_value_id() != "brows_human_arched":
		return _fail("Creator next-face-value real click did not select arched brows.")

	var next_people := VerifyInputHelper.find_button(
		main.debug_character_creator.root,
		NEXT_PEOPLE_BUTTON
	)
	if not next_people:
		return _fail("Creator next-people button missing.")
	await VerifyInputHelper.real_click_button(self, root, next_people)
	if main.debug_character_creator.get_current_people_id() != EXPECTED_NEXT_PEOPLE_ID:
		return _fail("Creator next-people real click did not cycle to Tanglekin.")

	var next_variant := VerifyInputHelper.find_button(
		main.debug_character_creator.root,
		NEXT_VARIANT_BUTTON
	)
	if not next_variant:
		return _fail("Creator next-variant button missing.")
	await VerifyInputHelper.real_click_button(self, root, next_variant)
	if main.debug_character_creator.get_current_variant_id().is_empty():
		return _fail("Creator next-variant real click did not select a variant.")

	var next_gear := VerifyInputHelper.find_button(
		main.debug_character_creator.root,
		NEXT_GEAR_BUTTON
	)
	if not next_gear:
		return _fail("Creator next-gear button missing.")
	await VerifyInputHelper.real_click_button(self, root, next_gear)
	if main.debug_character_creator.get_current_gear_id() == "none":
		return _fail("Creator next-gear real click did not select preview gear.")

	var apply := VerifyInputHelper.find_button(
		main.debug_character_creator.root,
		APPLY_BUTTON
	)
	if not apply:
		return _fail("Creator apply button missing.")
	await VerifyInputHelper.real_click_button(self, root, apply)
	if main.player.humanoid_profile.get("people_id") != EXPECTED_NEXT_PEOPLE_ID:
		return _fail("Creator apply real click did not update player appearance.")
	if not applied_profile_has_visual_model(main.player.humanoid_profile):
		return _fail("Creator apply did not keep a visual model id.")

	var close := VerifyInputHelper.find_button(
		main.debug_character_creator.root,
		CLOSE_BUTTON
	)
	if not close:
		return _fail("Creator close button missing.")
	await VerifyInputHelper.real_click_button(self, root, close)
	if main.debug_character_creator.is_open():
		return _fail("Creator close real click did not close the panel.")

	print("Debug character creator key and clicks verified.")
	quit()


func _fail(message: String) -> bool:
	printerr(message)
	quit(1)
	return false


static func required_button_names() -> Array[String]:
	return [
		NEXT_PEOPLE_BUTTON,
		NEXT_VARIANT_BUTTON,
		NEXT_EYES_BUTTON,
		NEXT_FACE_VALUE_BUTTON,
		NEXT_GEAR_BUTTON,
		APPLY_BUTTON,
		CLOSE_BUTTON
	]


static func applied_profile_has_visual_model(profile: Dictionary) -> bool:
	var appearance_value: Variant = profile.get("appearance", {})
	if not appearance_value is Dictionary:
		return false
	var appearance: Dictionary = appearance_value
	return not String(appearance.get("visual_model_id", "")).is_empty()
