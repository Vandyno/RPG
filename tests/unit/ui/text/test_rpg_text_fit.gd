extends GutTest

const RpgTextFit = preload("res://scripts/ui/text/rpg_text_fit.gd")


func test_ellipsize_keeps_or_shortens_text_to_fit() -> void:
	var label := Label.new()
	add_child_autofree(label)
	var font := label.get_theme_default_font()
	var width := 74.0

	assert_eq(RpgTextFit.ellipsize("Trade", font, 12, 500.0), "Trade")
	var fitted := RpgTextFit.ellipsize("Craft, repair, and improve gear.", font, 11, width)
	assert_true(fitted.ends_with("..."))
	assert_lte(RpgTextFit.line_width(fitted, font, 11), width)


func test_ellipsize_returns_suffix_when_suffix_alone_is_too_wide() -> void:
	var label := Label.new()
	add_child_autofree(label)
	var font := label.get_theme_default_font()
	var suffix_width := RpgTextFit.line_width("...", font, 11)

	assert_eq(RpgTextFit.ellipsize("Road Notice", font, 11, suffix_width - 1.0), "...")
