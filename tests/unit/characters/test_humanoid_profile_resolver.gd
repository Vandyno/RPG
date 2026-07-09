extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const HumanoidProfileResolver = preload("res://scripts/characters/humanoid_profile_resolver.gd")


func test_resolved_character_profile_generates_appearance_and_people_defaults() -> void:
	var content := _content()

	var profile := HumanoidProfileResolver.resolved_character_profile(content, "char_generated")
	var appearance: Dictionary = profile["appearance"]
	var proportions: Dictionary = appearance["proportions"]

	assert_eq(profile["character_id"], "char_generated")
	assert_eq(profile["derived_bonuses"], {"resolve": 2})
	assert_eq(appearance["people_id"], "people_test")
	assert_eq(appearance["visual_model_id"], "variant_a")
	assert_eq(appearance["palette_id"], "palette_override")
	assert_eq(appearance["feature_ids"], ["feature_a"])
	assert_almost_eq(float(proportions["body_height"]), 1.3, 0.001)
	assert_almost_eq(float(proportions["hand_size"]), 0.9, 0.001)


func test_people_visual_variant_returns_deep_copy() -> void:
	var content := _content()

	var first := HumanoidProfileResolver.people_visual_variant(content, "people_test", "variant_a")
	first["feature_ids"].append("mutated")
	var second := HumanoidProfileResolver.people_visual_variant(content, "people_test", "variant_a")

	assert_eq(second["feature_ids"], ["feature_a"])
	assert_eq(HumanoidProfileResolver.people_visual_variant(content, "people_test", "missing"), {})


func test_generated_people_profile_uses_character_id_for_owner_ids() -> void:
	var profile := HumanoidProfileResolver.generated_people_profile(
		_content(), "people_test", "char_preview", "variant_a", {"variant_id": "variant_a"}
	)

	assert_eq(profile["character_id"], "char_preview")
	assert_eq(profile["inventory_owner_id"], "char_preview")
	assert_eq(profile["equipment_owner_id"], "char_preview")
	assert_eq(profile["spellbook_owner_id"], "char_preview")


func test_safe_appearance_generation_options_filters_malformed_values() -> void:
	var options := HumanoidProfileResolver.safe_appearance_generation_options(
		{
			"variant_id": "variant_a",
			"proportion_jitter": true,
			"jitter_strength": 0.03,
			"marking_chance": "often",
			"appearance_overrides": {"palette_id": "palette_override"}
		}
	)

	assert_eq(options["variant_id"], "variant_a")
	assert_true(options["proportion_jitter"])
	assert_eq(options["jitter_strength"], 0.03)
	assert_false(options.has("marking_chance"))
	assert_eq(options["appearance_overrides"], {"palette_id": "palette_override"})


func _content() -> ContentDatabase:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.people = {
		"people_test":
		{
			"bonuses": {"resolve": 2, "bad": "x"},
			"body_plans": ["body_test"],
			"default_proportions": {"body_height": 1.2, "hand_size": 1.1}
		}
	}
	content.people_visual_models = {
		"people_test":
		{
			"variants":
			[
				{
					"id": "variant_a",
					"head_id": "head_a",
					"palette_id": "palette_a",
					"feature_ids": ["feature_a"],
					"proportion_deltas": {"body_height": 0.1}
				}
			]
		}
	}
	content.character_profiles = {
		"char_generated":
		{
			"character_id": "char_generated",
			"people_id": "people_test",
			"appearance_generation": {"variant_id": "variant_a", "proportion_jitter": false},
			"appearance":
			{
				"palette_id": "palette_override",
				"proportions": {"hand_size": 0.9}
			}
		}
	}
	return content
