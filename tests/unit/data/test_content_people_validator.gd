extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const ContentPeopleValidator = preload("res://scripts/data/content_people_validator.gd")

var content: ContentDatabase


func before_each() -> void:
	content = ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()


func test_rejects_broken_visual_models_and_generated_profiles() -> void:
	var errors: Array[String] = []
	content.people["people_validator_bad"] = {
		"id": "people_validator_bad",
		"display_name": "Validator Bad",
		"body_plans": ["body_humanoid_average"],
		"heads": ["head_human_round"],
		"palettes": ["palette_human_warm"],
		"features": ["feature_test"],
		"bonuses": {"": "strong"},
		"default_proportions": {"body_height": 4.0}
	}
	content.people_visual_models["people_validator_bad"] = {
		"people_id": "people_validator_bad",
		"variants":
		[
			{
				"id": "same",
				"display_name": "",
				"palette_id": "missing_palette",
				"head_id": "missing_head",
				"feature_ids": ["missing_feature"],
				"notes": "",
				"proportion_deltas": {"body_height": 2.0, "unknown": 0.1}
			},
			{"id": "same", "proportion_deltas": "bad"}
		]
	}
	content.character_profiles["char_validator_bad"] = {
		"character_id": "char_validator_bad",
		"people_id": "people_validator_bad",
		"state": "alive",
		"appearance_generation":
		{
			"seed": 7,
			"variant_id": "missing_variant",
			"proportion_jitter": "yes",
			"jitter_strength": 2.0,
			"marking_chance": 2.0,
			"appearance_overrides": {"proportions": {"body_height": 4.0}}
		},
		"inventory_owner_id": "char_validator_bad",
		"equipment_owner_id": "char_validator_bad",
		"spellbook_owner_id": "char_validator_bad"
	}

	ContentPeopleValidator.validate(content, errors)
	var joined := "\n".join(errors)

	assert_true(joined.contains("has blank bonus id"))
	assert_true(joined.contains("bonus  must be numeric"))
	assert_true(joined.contains("default_proportions proportions body_height must be between"))
	assert_true(joined.contains("must define at least four variants"))
	assert_true(joined.contains("variant same is missing display_name"))
	assert_true(joined.contains("references unsupported palette missing_palette"))
	assert_true(joined.contains("references unsupported head missing_head"))
	assert_true(joined.contains("references unsupported feature missing_feature"))
	assert_true(joined.contains("duplicate variant same"))
	assert_true(joined.contains("proportion_deltas must be a dictionary"))
	assert_true(joined.contains("has unsupported proportion delta unknown"))
	assert_true(joined.contains("proportion delta body_height must be between"))
	assert_true(joined.contains("seed must be a string"))
	assert_true(joined.contains("references missing variant missing_variant"))
	assert_true(joined.contains("proportion_jitter must be a boolean"))
	assert_true(joined.contains("jitter_strength must be between"))
	assert_true(joined.contains("marking_chance must be between"))
