extends GutTest

const RpgDetailLabel = preload("res://scripts/ui/controls/display/rpg_detail_label.gd")
const RpgTextFit = preload("res://scripts/ui/text/rpg_text_fit.gd")


func test_ready_enables_wrapping_and_hides_native_font_color() -> void:
	var label := RpgDetailLabel.new()
	add_child_autofree(label)

	assert_eq(label.autowrap_mode, TextServer.AUTOWRAP_WORD_SMART)
	assert_eq(label.get_theme_color("font_color"), Color.TRANSPARENT)


func test_visible_lines_trims_each_line_and_keeps_content_order() -> void:
	var label := RpgDetailLabel.new()
	add_child_autofree(label)

	assert_eq(
		label._visible_lines("  Road Hatchet  \n Weight: 5 \n\nA sturdy tool. "),
		["Road Hatchet", "Weight: 5", "A sturdy tool."]
	)


func test_is_stat_line_detects_colon_damage_and_weight_lines() -> void:
	var label := RpgDetailLabel.new()
	add_child_autofree(label)

	assert_true(label._is_stat_line("Weight: 5"))
	assert_true(label._is_stat_line("Damage 2-4"))
	assert_true(label._is_stat_line("Weight 5"))
	assert_false(label._is_stat_line("A sturdy trail tool."))


func test_ellipsize_keeps_short_text_and_truncates_long_text_to_width() -> void:
	var label := RpgDetailLabel.new()
	add_child_autofree(label)
	var font := label.get_theme_default_font()
	var font_size := 14
	var full_width: float = RpgTextFit.line_width("Road Hatchet", font, font_size)

	assert_eq(RpgTextFit.ellipsize("Road Hatchet", font, font_size, full_width), "Road Hatchet")
	var shortened: String = RpgTextFit.ellipsize(
		"Road Hatchet", font, font_size, full_width * 0.55
	)
	assert_true(shortened.ends_with("..."))
	assert_lt(RpgTextFit.line_width(shortened, font, font_size), full_width)
	assert_eq(RpgTextFit.ellipsize("Road Hatchet", font, font_size, 1.0), "...")


func test_fit_wrapped_lines_wraps_and_ellipsizes_to_max_lines() -> void:
	var label := RpgDetailLabel.new()
	add_child_autofree(label)
	var font := label.get_theme_default_font()

	var lines := label._fit_wrapped_lines(
		"Road Hatchet With Long Handle", font, 14, 50.0, 2
	)

	assert_eq(lines.size(), 2)
	assert_eq(lines[0], "Road")
	assert_false(lines[1].is_empty())


func test_fit_wrapped_lines_returns_empty_for_blank_text() -> void:
	var label := RpgDetailLabel.new()
	add_child_autofree(label)
	var font := label.get_theme_default_font()

	assert_eq(label._fit_wrapped_lines("", font, 14, 100.0, 2), [])
