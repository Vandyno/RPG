extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainWorldGuidance = preload("res://scripts/main/ui/main_world_guidance.gd")


func test_unselected_world_hints_name_short_targets_when_they_fit() -> void:
	assert_eq(
		MainWorldGuidance._hint_text_for_width("Read", "Road Notice", false, 1152.0),
		"Read Road Notice"
	)
