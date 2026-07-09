extends GutTest

const CaptureQuickActions = preload("res://scripts/tools/capture/capture_quick_actions.gd")


class HudStub:
	extends RefCounted

	var layout_sizes: Array[Vector2] = []
	var context_states: Array[Dictionary] = []

	func _apply_layout_for_size(size: Vector2) -> void:
		layout_sizes.append(size)

	func _refresh_context_actions(state: Dictionary) -> void:
		context_states.append(state.duplicate(true))


class MainStub:
	extends RefCounted

	var hud := HudStub.new()
	var process_values: Array[bool] = []

	func set_process(value: bool) -> void:
		process_values.append(value)


func test_capture_config_uses_defaults_and_reads_args() -> void:
	assert_eq(
		CaptureQuickActions.capture_config([]),
		{
			"width": CaptureQuickActions.DEFAULT_WIDTH,
			"height": CaptureQuickActions.DEFAULT_HEIGHT,
			"output_path": CaptureQuickActions.DEFAULT_OUTPUT_PATH
		}
	)
	assert_eq(
		CaptureQuickActions.capture_config(["900", "500", "res://reports/quick.png"]),
		{"width": 900, "height": 500, "output_path": "res://reports/quick.png"}
	)


func test_quick_actions_fixture_describes_rest_target_and_three_actions() -> void:
	var fixture := CaptureQuickActions.quick_actions_fixture()

	assert_eq(fixture["nearby"], "Rest Bridge Campfire")
	assert_eq(Array(fixture["nearby_targets"]).size(), 1)
	assert_eq(Array(fixture["nearby_targets"])[0]["kind"], "rest")
	assert_eq(Array(fixture["context_actions"]).size(), 3)
	assert_eq(Array(fixture["context_actions"])[0]["text"], "I'll find it.")
	assert_eq(Array(fixture["context_actions"])[1]["text"], "Sharpen Road Hatchet")
	assert_eq(Array(fixture["context_actions"])[2]["text"], "Trade")


func test_prepare_main_for_capture_stops_processing_applies_layout_and_refreshes_actions() -> void:
	var main := MainStub.new()

	CaptureQuickActions.prepare_main_for_capture(main, 960, 540)

	assert_eq(main.process_values, [false])
	assert_eq(main.hud.layout_sizes, [Vector2(960, 540)])
	assert_eq(main.hud.context_states, [CaptureQuickActions.quick_actions_fixture()])
