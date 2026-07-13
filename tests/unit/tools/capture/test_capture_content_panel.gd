extends GutTest

const CaptureContentPanel = preload("res://scripts/tools/capture/capture_content_panel.gd")


class HudStub:
	extends RefCounted

	var layout_sizes: Array[Vector2] = []
	var cards: Array[Dictionary] = []

	func _apply_layout_for_size(size: Vector2) -> void:
		layout_sizes.append(size)

	func show_content_card(title: String, body: String, choices: Array, kind: String) -> void:
		cards.append(
			{
				"title": title,
				"body": body,
				"choices": choices.duplicate(true),
				"kind": kind
			}
		)


class MainStub:
	extends RefCounted

	var hud := HudStub.new()


func test_capture_config_uses_defaults_for_missing_args() -> void:
	assert_eq(
		CaptureContentPanel.capture_config([]),
		{
			"width": CaptureContentPanel.DEFAULT_WIDTH,
			"height": CaptureContentPanel.DEFAULT_HEIGHT,
			"output_path": CaptureContentPanel.DEFAULT_OUTPUT_PATH,
			"mode": CaptureContentPanel.DEFAULT_MODE
		}
	)


func test_capture_config_reads_size_output_and_mode_args() -> void:
	assert_eq(
		CaptureContentPanel.capture_config(
			["900", "500", "res://reports/custom_content.png", "place"]
		),
		{
			"width": 900,
			"height": 500,
			"output_path": "res://reports/custom_content.png",
			"mode": "place"
		}
	)


func test_prepare_main_for_capture_applies_layout_and_dialogue_fixture() -> void:
	var main := MainStub.new()

	CaptureContentPanel.prepare_main_for_capture(main, 960, 540, "dialogue")

	assert_eq(main.hud.layout_sizes, [Vector2(960, 540)])
	assert_eq(main.hud.cards.size(), 1)
	assert_eq(main.hud.cards[0]["title"], "Harrow Venn")
	assert_eq(main.hud.cards[0]["kind"], "dialogue")
	assert_eq(Array(main.hud.cards[0]["choices"]).size(), 3)


func test_show_fixture_supports_readable_place_result_and_default_dialogue() -> void:
	var main := MainStub.new()

	CaptureContentPanel.show_fixture(main, "readable")
	CaptureContentPanel.show_fixture(main, "place")
	CaptureContentPanel.show_fixture(main, "result")
	CaptureContentPanel.show_fixture(main, "unknown")

	assert_eq(main.hud.cards[0]["title"], "Road Notice")
	assert_eq(main.hud.cards[0]["kind"], "readable")
	assert_true(Array(main.hud.cards[0]["choices"]).is_empty())
	assert_eq(main.hud.cards[1]["title"], "Briarwatch Square")
	assert_eq(main.hud.cards[1]["kind"], "place")
	assert_eq(Array(main.hud.cards[1]["choices"]).size(), 2)
	assert_eq(main.hud.cards[2]["title"], "Road Patrol Complete")
	assert_eq(main.hud.cards[2]["kind"], "response")
	assert_true(Array(main.hud.cards[2]["choices"]).is_empty())
	assert_eq(main.hud.cards[3]["title"], "Harrow Venn")
	assert_eq(main.hud.cards[3]["kind"], "dialogue")
