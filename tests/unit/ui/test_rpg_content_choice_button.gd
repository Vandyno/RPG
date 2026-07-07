extends GutTest


func test_choice_card_updates_render_state_and_hides_native_text() -> void:
	var button := RpgContentChoiceButton.new()
	add_child_autofree(button)

	button.set_choice_card("quest", "Find the tools", "Missing Tools", true)

	assert_eq(button.choice_icon, "quest")
	assert_eq(button.choice_title, "Find the tools")
	assert_eq(button.choice_subtitle, "Missing Tools")
	assert_true(button.centered)
	assert_eq(button.get_theme_color("font_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_hover_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_pressed_color"), Color.TRANSPARENT)
	assert_eq(button.get_theme_color("font_focus_color"), Color.TRANSPARENT)


func test_fit_line_keeps_text_when_width_is_available() -> void:
	var button := RpgContentChoiceButton.new()
	add_child_autofree(button)
	var font := button.get_theme_default_font()

	assert_eq(button._fit_line("Trade", 500.0, font, 12), "Trade")


func test_fit_line_ellipsizes_without_exceeding_width() -> void:
	var button := RpgContentChoiceButton.new()
	add_child_autofree(button)
	var font := button.get_theme_default_font()
	var width := 74.0

	var fitted := button._fit_line("Craft, repair, and improve gear.", width, font, 11)

	assert_true(fitted.ends_with("..."))
	assert_lte(button._line_width(fitted, font, 11), width)


func test_fit_line_returns_suffix_when_only_suffix_fits() -> void:
	var button := RpgContentChoiceButton.new()
	add_child_autofree(button)
	var font := button.get_theme_default_font()
	var suffix_width := button._line_width("...", font, 11)

	assert_eq(button._fit_line("Road Notice", suffix_width - 1.0, font, 11), "...")
