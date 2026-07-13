extends GutTest

const VerifySneakButtonClick = preload("res://scripts/tools/verify/verify_sneak_button_click.gd")


class AvatarStub:
	extends RefCounted

	var is_sneaking := false


class PlayerStub:
	extends RefCounted

	var is_sneaking := false
	var humanoid_avatar := AvatarStub.new()


class HudStub:
	extends RefCounted

	var message_log: Array[String] = []


class MainStub:
	extends RefCounted

	var player := PlayerStub.new()
	var hud := HudStub.new()


func test_sneak_verifier_keeps_viewport_and_message_contract() -> void:
	assert_eq(VerifySneakButtonClick.VERIFY_SIZE, Vector2i(1152, 648))
	assert_eq(VerifySneakButtonClick.SNEAK_ON_MESSAGE, "Sneaking.")
	assert_eq(VerifySneakButtonClick.SNEAK_OFF_MESSAGE, "Standing.")


func test_player_and_avatar_are_sneaking_requires_both_flags() -> void:
	var main := MainStub.new()

	assert_false(VerifySneakButtonClick.player_and_avatar_are_sneaking(main))
	main.player.is_sneaking = true
	assert_false(VerifySneakButtonClick.player_and_avatar_are_sneaking(main))
	main.player.humanoid_avatar.is_sneaking = true
	assert_true(VerifySneakButtonClick.player_and_avatar_are_sneaking(main))


func test_player_and_avatar_are_standing_requires_both_flags_off() -> void:
	var main := MainStub.new()

	assert_true(VerifySneakButtonClick.player_and_avatar_are_standing(main))
	main.player.humanoid_avatar.is_sneaking = true
	assert_false(VerifySneakButtonClick.player_and_avatar_are_standing(main))


func test_message_log_has_checks_verifier_messages() -> void:
	var main := MainStub.new()
	main.hud.message_log = ["Sneaking."]

	assert_true(VerifySneakButtonClick.message_log_has(main, "Sneaking."))
	assert_false(VerifySneakButtonClick.message_log_has(main, "Standing."))
