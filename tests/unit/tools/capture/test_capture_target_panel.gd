extends GutTest

const CaptureTargetPanel = preload("res://scripts/tools/capture/capture_target_panel.gd")


class HudStub:
	extends RefCounted

	var layout_sizes: Array[Vector2] = []
	var toggle_calls := 0

	func _apply_layout_for_size(size: Vector2) -> void:
		layout_sizes.append(size)

	func toggle_target_picker() -> void:
		toggle_calls += 1


class MainStub:
	extends RefCounted

	var hud := HudStub.new()


func test_capture_config_uses_defaults_for_missing_args() -> void:
	assert_eq(
		CaptureTargetPanel.capture_config([]),
		{
			"width": CaptureTargetPanel.DEFAULT_WIDTH,
			"height": CaptureTargetPanel.DEFAULT_HEIGHT,
			"output_path": CaptureTargetPanel.DEFAULT_OUTPUT_PATH
		}
	)


func test_capture_config_clamps_positive_size_args() -> void:
	assert_eq(
		CaptureTargetPanel.capture_config(["0", "-1", ""]),
		{"width": 1, "height": 1, "output_path": CaptureTargetPanel.DEFAULT_OUTPUT_PATH}
	)


func test_capture_config_reads_size_and_output_path_from_args() -> void:
	assert_eq(
		CaptureTargetPanel.capture_config(["800", "450", "res://reports/custom.png"]),
		{"width": 800, "height": 450, "output_path": "res://reports/custom.png"}
	)


func test_prepare_main_for_capture_applies_layout_and_opens_target_picker() -> void:
	var main := MainStub.new()

	CaptureTargetPanel.prepare_main_for_capture(main, 960, 540)

	assert_eq(main.hud.layout_sizes, [Vector2(960, 540)])
	assert_eq(main.hud.toggle_calls, 1)
