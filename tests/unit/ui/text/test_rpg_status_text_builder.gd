extends GutTest

const RpgStatusTextBuilder = preload("res://scripts/ui/text/rpg_status_text_builder.gd")


func test_lines_show_adventurer_progression_and_active_effects() -> void:
	assert_eq(
		RpgStatusTextBuilder.lines({"statuses": "Blessed, Wet"}, "Level 2 25 XP"),
		["Adventurer", "Level 2 25 XP", "Effects: Blessed, Wet"]
	)


func test_lines_omit_effects_when_statuses_are_none_or_missing() -> void:
	assert_eq(
		RpgStatusTextBuilder.lines({"statuses": "none"}, "Level 1 0 XP"),
		["Adventurer", "Level 1 0 XP"]
	)
	assert_eq(RpgStatusTextBuilder.lines({}, "Level 1 0 XP"), ["Adventurer", "Level 1 0 XP"])


func test_compact_lines_abbreviate_short_progression_text() -> void:
	assert_eq(
		RpgStatusTextBuilder.lines({}, "Level 1", true),
		["Adventurer", "Lv 1"]
	)


func test_compact_lines_condense_level_xp_progression() -> void:
	assert_eq(
		RpgStatusTextBuilder.lines({}, "Level 4 120 XP", true),
		["Adventurer", "Lv 4  120 XP"]
	)


func test_status_lines_expose_stealth_bounty_and_jail_sentence() -> void:
	assert_eq(
		RpgStatusTextBuilder.lines(
			{"stealth_state": "Suspicious", "bounty": 25, "jailed": true, "sentence_hours": 8},
			"Level 2 25 XP"
		),
		["Adventurer", "Level 2 25 XP", "Stealth: Suspicious", "Wanted: 25g", "Jailed: 8h"]
	)
	assert_eq(
		RpgStatusTextBuilder.lines(
			{"stealth_state": "Hidden", "bounty": 10}, "Level 1", true
		),
		["Adventurer", "Lv 1", "Hidden  Wanted 10g"]
	)
