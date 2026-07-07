extends GutTest

const VerifyRpgUiRealClicks = preload("res://scripts/tools/verify/verify_rpg_ui_real_clicks.gd")


func test_real_click_verifier_keeps_dedicated_save_path_contract() -> void:
	assert_eq(VerifyRpgUiRealClicks.VERIFY_SAVE_PATH, "user://verify_rpg_ui_real_clicks.json")
