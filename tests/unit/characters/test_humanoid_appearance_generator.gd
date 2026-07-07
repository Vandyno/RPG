extends GutTest


func test_generate_appearance_returns_defaults_for_missing_inputs() -> void:
	var appearance := HumanoidAppearanceGenerator.generate_appearance("", {}, {})

	assert_eq(appearance["people_id"], HumanoidProfile.DEFAULT_PEOPLE_ID)
	assert_eq(appearance["body_plan_id"], HumanoidProfile.DEFAULT_BODY_PLAN_ID)
	assert_eq(appearance["visual_model_id"], "")


func test_generate_appearance_applies_variant_deltas_markings_and_overrides() -> void:
	var appearance := HumanoidAppearanceGenerator.generate_appearance(
		"people_test",
		_definition(),
		_visual_model(),
		"road_seed",
		{
			"variant_id": "variant_a",
			"marking_chance": 1.0,
			"appearance_overrides":
			{
				"hair_id": "hair_override",
				"feature_ids": ["feature_override"],
				"proportions": {"head_size": 1.2, "not_real": 9.0}
			}
		}
	)

	assert_eq(appearance["people_id"], "people_test")
	assert_eq(appearance["visual_model_id"], "variant_a")
	assert_eq(appearance["body_plan_id"], "body_tall")
	assert_eq(appearance["head_id"], "head_a")
	assert_eq(appearance["hair_id"], "hair_override")
	assert_eq(appearance["feature_ids"], ["feature_override"])
	assert_true(["marking_a", "marking_b"].has(appearance["marking_id"]))
	assert_almost_eq(float(appearance["proportions"]["body_height"]), 1.1, 0.001)
	assert_almost_eq(float(appearance["proportions"]["head_size"]), 1.2, 0.001)
	assert_false(appearance["proportions"].has("not_real"))


func test_generate_appearance_is_deterministic_with_jitter() -> void:
	var first := HumanoidAppearanceGenerator.generate_appearance(
		"people_test",
		_definition(),
		_visual_model(),
		"same_seed",
		{"proportion_jitter": true, "jitter_strength": 0.08}
	)
	var second := HumanoidAppearanceGenerator.generate_appearance(
		"people_test",
		_definition(),
		_visual_model(),
		"same_seed",
		{"proportion_jitter": true, "jitter_strength": 0.08}
	)

	assert_eq(first, second)
	for value in first["proportions"].values():
		assert_gte(float(value), HumanoidProfile.MIN_PROPORTION)
		assert_lte(float(value), HumanoidProfile.MAX_PROPORTION)


func test_apply_appearance_overrides_keeps_people_id_and_sanitizes_fields() -> void:
	var base := HumanoidProfile.appearance_from_data(
		{"people_id": "old_people", "feature_ids": ["old"], "proportions": {"hand_size": 1.0}}
	)

	var appearance := HumanoidAppearanceGenerator.apply_appearance_overrides(
		base,
		{
			"palette_id": "palette_override",
			"feature_ids": ["new", 123],
			"proportions": {"hand_size": 1.3, "bad": 4.0}
		},
		"people_new"
	)

	assert_eq(appearance["people_id"], "people_new")
	assert_eq(appearance["palette_id"], "palette_override")
	assert_eq(appearance["feature_ids"], ["new", "123"])
	assert_almost_eq(float(appearance["proportions"]["hand_size"]), 1.3, 0.001)
	assert_false(appearance["proportions"].has("bad"))


func _definition() -> Dictionary:
	return {
		"body_plans": ["body_tall"],
		"default_proportions": {"body_height": 1.0, "head_size": 1.0}
	}


func _visual_model() -> Dictionary:
	return {
		"variants":
		[
			{
				"id": "variant_a",
				"head_id": "head_a",
				"palette_id": "palette_a",
				"hair_id": "hair_a",
				"hair_color_id": "hair_color_a",
				"feature_ids": ["feature_a"],
				"proportion_deltas": {"body_height": 0.1},
				"optional_marking_ids": ["marking_a", "marking_b"]
			},
			{
				"id": "variant_b",
				"head_id": "head_b",
				"palette_id": "palette_b",
				"hair_id": "hair_b"
			}
		]
	}
