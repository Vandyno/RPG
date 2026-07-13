extends GutTest

const PrimaryActionTextBuilder = preload("res://scripts/ui/text/primary_action_text_builder.gd")


func test_for_kind_maps_world_entity_kinds_to_player_actions() -> void:
	assert_eq(PrimaryActionTextBuilder.for_kind("readable"), "Read")
	assert_eq(PrimaryActionTextBuilder.for_kind("npc"), "Talk")
	assert_eq(PrimaryActionTextBuilder.for_kind("pickup"), "Pick Up")
	assert_eq(PrimaryActionTextBuilder.for_kind("container"), "Open")
	assert_eq(PrimaryActionTextBuilder.for_kind("door"), "Open")
	assert_eq(PrimaryActionTextBuilder.for_kind("rest"), "Rest")
	assert_eq(PrimaryActionTextBuilder.for_kind("poi"), "Use")


func test_for_kind_falls_back_to_interact() -> void:
	assert_eq(PrimaryActionTextBuilder.for_kind(""), "Interact")
	assert_eq(PrimaryActionTextBuilder.for_kind("unknown"), "Interact")
