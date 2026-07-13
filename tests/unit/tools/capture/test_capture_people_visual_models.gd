extends GutTest

const CapturePeopleVisualModels = preload(
	"res://scripts/tools/capture/capture_people_visual_models.gd"
)


func test_capture_config_uses_defaults_and_reads_output_size_args() -> void:
	assert_eq(
		CapturePeopleVisualModels.capture_config([]),
		{
			"output_dir": CapturePeopleVisualModels.DEFAULT_OUTPUT_DIR,
			"width": CapturePeopleVisualModels.DEFAULT_WIDTH,
			"height": CapturePeopleVisualModels.DEFAULT_HEIGHT
		}
	)
	assert_eq(
		CapturePeopleVisualModels.capture_config(["res://reports/people", "900", "500"]),
		{"output_dir": "res://reports/people", "width": 900, "height": 500}
	)


func test_round_output_path_uses_one_based_round_number() -> void:
	assert_eq(
		CapturePeopleVisualModels.round_output_path("res://reports/people", 0),
		"res://reports/people/round_01.png"
	)
	assert_eq(
		CapturePeopleVisualModels.round_output_path("res://reports/people", 7),
		"res://reports/people/round_08.png"
	)


func test_chosen_variant_clamps_to_available_dictionary_variants() -> void:
	var variants := [{"id": "first"}, {"id": "second"}]

	assert_eq(CapturePeopleVisualModels.chosen_variant(variants, -1), {"id": "first"})
	assert_eq(CapturePeopleVisualModels.chosen_variant(variants, 1), {"id": "second"})
	assert_eq(CapturePeopleVisualModels.chosen_variant(variants, 9), {"id": "second"})
	assert_eq(CapturePeopleVisualModels.chosen_variant([], 0), {})
	assert_eq(CapturePeopleVisualModels.chosen_variant(["bad"], 0), {})


func test_feature_text_formats_feature_arrays_and_empty_values() -> void:
	assert_eq(CapturePeopleVisualModels.feature_text(["beak", "cloak"]), "beak, cloak")
	assert_eq(CapturePeopleVisualModels.feature_text([]), "none")
	assert_eq(CapturePeopleVisualModels.feature_text("bad"), "none")


func test_people_visual_model_sheet_contract_covers_all_current_people_and_rounds() -> void:
	assert_eq(CapturePeopleVisualModels.PEOPLE_ORDER[0], "people_human")
	assert_eq(CapturePeopleVisualModels.PEOPLE_ORDER[-1], "people_rootborn")
	assert_eq(CapturePeopleVisualModels.PEOPLE_ORDER.size(), 6)
	assert_eq(CapturePeopleVisualModels.ROUND_DEFS.size(), 8)
	assert_eq(CapturePeopleVisualModels.ROUND_DEFS[0]["variant_index"], 0)
	assert_eq(CapturePeopleVisualModels.ROUND_DEFS[-1]["variant_index"], 7)
	assert_eq(CapturePeopleVisualModels.ROUND_DEFS[0]["direction"], Vector2.DOWN)
