extends GutTest

const ButtonTextFormatter = preload("res://scripts/ui/text/button_text_formatter.gd")


func test_primary_action_label_keeps_single_short_words() -> void:
	assert_eq(ButtonTextFormatter.primary_action_label("Talk"), "Talk")
	assert_eq(ButtonTextFormatter.primary_action_label("Pickpocket"), "Pickpocket")


func test_primary_action_label_wraps_multi_word_actions_to_two_lines() -> void:
	assert_eq(
		ButtonTextFormatter.primary_action_label("Sharpen Road Hatchet (2g)"),
		"Sharpen Road\nHatchet (2g)"
	)
	assert_eq(
		ButtonTextFormatter.primary_action_label("Report Road Patrol Complete"),
		"Report Road\nPatrol"
	)


func test_primary_action_label_ellipsizes_long_single_words() -> void:
	assert_eq(ButtonTextFormatter.primary_action_label("Supercalifragilistic"), "Supercalif...")


func test_compact_primary_action_label_names_short_action_targets() -> void:
	assert_eq(
		ButtonTextFormatter.compact_primary_action_label("Rest", "Bridge Campfire"),
		"Rest\nCampfire"
	)
	assert_eq(
		ButtonTextFormatter.compact_primary_action_label("Open", "Warden's Strongbox"),
		"Open\nStrongbox"
	)


func test_compact_primary_action_label_uses_action_only_for_non_target_modes() -> void:
	assert_eq(ButtonTextFormatter.compact_primary_action_label("Close", "Harrow Venn"), "Close")
	assert_eq(ButtonTextFormatter.compact_primary_action_label("Explore", "Road Notice"), "Explore")
	assert_eq(ButtonTextFormatter.compact_primary_action_label("Stop", "Maera"), "Stop")
	assert_eq(ButtonTextFormatter.compact_primary_action_label("Talk", ""), "Talk")
	assert_eq(ButtonTextFormatter.compact_primary_action_label("Talk", "none"), "Talk")


func test_compact_primary_action_label_keeps_wrapped_long_actions() -> void:
	assert_eq(
		ButtonTextFormatter.compact_primary_action_label("Sharpen Road Hatchet (2g)", "Forge"),
		"Sharpen Road\nHatchet (2g)"
	)


func test_compact_target_label_prefers_last_word_or_ellipsis() -> void:
	assert_eq(ButtonTextFormatter.compact_target_label("Harrow Venn"), "Harrow Venn")
	assert_eq(ButtonTextFormatter.compact_target_label("Old Warden's Strongbox"), "Strongbox")
	assert_eq(ButtonTextFormatter.compact_target_label("UnbrokenLongTargetName"), "UnbrokenLo...")
