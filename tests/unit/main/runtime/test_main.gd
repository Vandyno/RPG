extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_main_bootstrap_wires_core_runtime_dependencies() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_not_null(main.content)
	assert_not_null(main.player)
	assert_not_null(main.hud)
	assert_not_null(main.hud_queries)
	assert_not_null(main.entities)
	assert_true(main.is_processing())


func test_hud_state_exposes_player_and_system_summaries() -> void:
	var main := Main.new()
	add_child_autofree(main)

	var state := main.get_hud_state()

	assert_true(state.has("player_health"))
	assert_true(state.has("inventory"))
	assert_true(state.has("nearby_targets"))
	assert_true(state.has("primary_action"))
	assert_true(String(state["primary_action"]).length() > 0)
