extends GutTest

const CheckWorldAtlas = preload("res://scripts/tools/world/check_world_atlas.gd")


func test_check_config_uses_approved_gate_defaults() -> void:
	assert_eq(
		CheckWorldAtlas.check_config([]),
		{
			"atlas_path": CheckWorldAtlas.DEFAULT_ATLAS_PATH,
			"review_path": CheckWorldAtlas.DEFAULT_REVIEW_PATH,
			"report_path": CheckWorldAtlas.DEFAULT_REPORT_PATH,
			"require_approved": false
		}
	)
	assert_true(CheckWorldAtlas.check_config(["a", "r", "o", "--require-approved"])["require_approved"])
