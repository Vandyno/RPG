extends GutTest

const VerifyDebugCharacterCreatorClicks = preload(
	"res://scripts/tools/verify/verify_debug_character_creator_clicks.gd"
)


func test_debug_creator_verifier_keeps_viewport_people_and_button_contract() -> void:
	assert_eq(VerifyDebugCharacterCreatorClicks.VERIFY_SIZE, Vector2i(1152, 648))
	assert_eq(VerifyDebugCharacterCreatorClicks.EXPECTED_NEXT_PEOPLE_ID, "people_tanglekin")
	assert_eq(
		VerifyDebugCharacterCreatorClicks.required_button_names(),
		[
			"CreatorNextPeopleButton",
			"CreatorNextVariantButton",
			"CreatorNextGearButton",
			"CreatorApplyButton",
			"CreatorCloseButton",
		]
	)


func test_applied_profile_has_visual_model_requires_dictionary_appearance_and_model_id() -> void:
	assert_true(
		VerifyDebugCharacterCreatorClicks.applied_profile_has_visual_model(
			{"appearance": {"visual_model_id": "people_tanglekin_default"}}
		)
	)
	assert_false(
		VerifyDebugCharacterCreatorClicks.applied_profile_has_visual_model(
			{"appearance": {"visual_model_id": ""}}
		)
	)
	assert_false(
		VerifyDebugCharacterCreatorClicks.applied_profile_has_visual_model({"appearance": "bad"})
	)
	assert_false(VerifyDebugCharacterCreatorClicks.applied_profile_has_visual_model({}))
