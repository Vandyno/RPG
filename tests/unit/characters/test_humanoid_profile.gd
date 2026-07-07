extends GutTest

const HumanoidProfile = preload("res://scripts/characters/humanoid_profile.gd")


func test_profile_defaults_keep_required_owner_shape() -> void:
	var profile := HumanoidProfile.from_data({"character_id": "char_test"})

	assert_eq(profile["character_id"], "char_test")
	assert_eq(profile["people_id"], "people_human")
	assert_eq(profile["state"], "alive")
	assert_eq(profile["handedness"], "right")
	assert_eq(profile["inventory_owner_id"], "char_test")
	assert_eq(profile["equipment_owner_id"], "char_test")
	assert_eq(profile["spellbook_owner_id"], "char_test")
	assert_eq(profile["stats"], {})
	assert_eq(profile["derived_bonuses"], {})
	assert_eq(profile["appearance"]["body_plan_id"], "body_humanoid_average")
	assert_eq(profile["appearance"]["base_clothing_id"], "")
	assert_eq(profile["appearance"]["feature_ids"], [])
	assert_eq(profile["appearance"]["visual_model_id"], "")
	assert_eq(profile["appearance"]["proportions"]["body_height"], 1.0)
	assert_eq(profile["appearance"]["proportions"]["shoulder_width"], 1.0)
	assert_eq(profile["appearance"]["proportions"]["hand_size"], 1.0)


func test_profile_sanitizes_malformed_optional_fields() -> void:
	var profile := HumanoidProfile.from_data(
		{
			"character_id": "char_bad",
			"people_id": "",
			"state": "sleeping",
			"handedness": "middle",
			"level": 0,
			"stats": {"resolve": "high", "stamina": 2},
			"derived_bonuses": "bad",
			"appearance":
			{
				"feature_ids": ["feature_a", "", "feature_a", 12],
				"visual_model_id": "model_test",
				"proportions": {"shoulder_width": 100.0, "hand_size": "large"}
			}
		}
	)

	assert_eq(profile["people_id"], "people_human")
	assert_eq(profile["state"], "alive")
	assert_eq(profile["handedness"], "right")
	assert_eq(profile["level"], 1)
	assert_eq(profile["stats"], {"stamina": 2})
	assert_eq(profile["derived_bonuses"], {})
	assert_eq(profile["appearance"]["people_id"], "people_human")
	assert_eq(profile["appearance"]["feature_ids"], ["feature_a", "12"])
	assert_eq(profile["appearance"]["visual_model_id"], "model_test")
	assert_eq(profile["appearance"]["proportions"]["shoulder_width"], 1.45)
	assert_eq(profile["appearance"]["proportions"]["hand_size"], 1.0)


func test_profile_validation_reports_malformed_required_shape() -> void:
	var errors := HumanoidProfile.validate(
		{
			"character_id": "",
			"people_id": "",
			"state": "lost",
			"handedness": "middle",
			"stats": "bad",
			"derived_bonuses": {"": 1, "resolve": "high"},
			"appearance":
			{
				"people_id": "",
				"body_plan_id": "",
				"head_id": "",
				"palette_id": "",
				"base_clothing_id": "",
				"proportions": {"shoulder_width": "wide", "hand_size": 2.0}
			}
		},
		"Character profile test"
	)
	var joined := "\n".join(errors)

	assert_true(joined.contains("missing character_id"))
	assert_true(joined.contains("missing people_id"))
	assert_true(joined.contains("invalid state"))
	assert_true(joined.contains("invalid handedness"))
	assert_true(joined.contains("missing inventory_owner_id"))
	assert_true(joined.contains("stats must be a dictionary"))
	assert_true(joined.contains("derived_bonuses has blank id"))
	assert_true(joined.contains("derived_bonuses resolve must be numeric"))
	assert_true(joined.contains("appearance is missing body_plan_id"))
	assert_true(joined.contains("proportions shoulder_width must be numeric"))
	assert_true(joined.contains("proportions hand_size must be between"))


func test_profile_preserves_left_handedness() -> void:
	var profile := HumanoidProfile.from_data({"character_id": "char_left", "handedness": "left"})

	assert_eq(profile["handedness"], "left")
