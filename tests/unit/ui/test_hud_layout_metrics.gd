extends GutTest

const HudLayoutMetrics = preload("res://scripts/ui/shell/hud_layout_metrics.gd")


func test_status_panel_metrics_keep_compact_empty_state_short() -> void:
	var metrics := HudLayoutMetrics.status_panel(Vector2(640, 360), 2, 12.0, true)

	assert_eq(int(metrics["status_font_size"]), 12)
	assert_false(bool(metrics["show_health_label"]))
	assert_lte(float(metrics["height"]), 70.0)


func test_status_panel_metrics_allow_active_quest_lines_without_bloating_desktop() -> void:
	var compact := HudLayoutMetrics.status_panel(Vector2(640, 360), 6, 12.0, true)
	var desktop := HudLayoutMetrics.status_panel(Vector2(1152, 648), 6, 12.0, false)

	assert_lte(float(compact["height"]), 100.0)
	assert_true(bool(desktop["show_health_label"]))
	assert_eq(int(desktop["status_font_size"]), 15)
	assert_eq(float(desktop["width"]), 318.0)


func test_button_row_width_uses_button_minimum_sizes_and_separation() -> void:
	var row := HBoxContainer.new()
	add_child_autofree(row)
	for width in [92.0, 66.0, 76.0]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(width, 52.0)
		row.add_child(button)

	assert_eq(HudLayoutMetrics.button_row_width(row, 5.0), 244.0)
