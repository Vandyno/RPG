extends GutTest

const RpgSystemsCharacterRows = preload(
	"res://scripts/ui/systems/rows/rpg_systems_character_rows.gd"
)


func test_category_labels_match_character_sections() -> void:
	assert_eq(
		RpgSystemsCharacterRows.category_labels(),
		["Overview", "Training", "Gear", "Effects"]
	)


func test_rows_build_vitals_training_equipment_and_effects() -> void:
	var rows := RpgSystemsCharacterRows.rows(_character_state(), "overview")

	assert_eq(rows.size(), 4)
	assert_eq(rows[0]["id"], "character_health")
	assert_eq(rows[0]["title"], "Vitals")
	assert_eq(rows[0]["subtitle"], "Health Health 80/100 - Mana Mana 20/40")
	assert_eq(rows[0]["meta"], "Vitals")
	assert_string_contains(rows[0]["detail"], "Current Health: Health 80/100")
	assert_eq(rows[1]["id"], "character_progression")
	assert_eq(rows[1]["title"], "Train Strength")
	assert_eq(rows[1]["action_id"], "train:strength")
	assert_eq(rows[1]["subtitle"], "Level 2")
	assert_eq(rows[1]["meta"], "Progression")
	assert_eq(rows[1]["detail"], "Practice sword forms.")
	assert_eq(rows[2]["id"], "character_equipment")
	assert_eq(rows[2]["subtitle"], "Weapon: Road Sword")
	assert_eq(rows[2]["meta"], "Gear")
	assert_string_contains(rows[2]["detail"], "Drag gear onto body slots to equip.")
	assert_eq(rows[3]["id"], "character_effects")
	assert_eq(rows[3]["subtitle"], "Bleeding")
	assert_eq(rows[3]["meta"], "Status")
	assert_eq(rows[3]["detail"], "Bleeding: losing health.")


func test_rows_use_defaults_and_fallback_details() -> void:
	var rows := RpgSystemsCharacterRows.rows({}, "overview")

	assert_eq(rows.size(), 4)
	assert_eq(rows[0]["subtitle"], "Health Health unknown - Mana Mana unknown")
	assert_string_contains(rows[0]["detail"], "Condition: Stable")
	assert_eq(rows[1]["subtitle"], "Level 1")
	assert_eq(rows[1]["detail"], "Level 1")
	assert_eq(rows[2]["subtitle"], "Weapon: empty")
	assert_eq(rows[3]["subtitle"], "None")
	assert_eq(rows[3]["detail"], "No active effects.")


func test_category_filter_returns_matching_character_rows() -> void:
	var training_rows := RpgSystemsCharacterRows.rows(_character_state(), "training")
	var gear_rows := RpgSystemsCharacterRows.rows(_character_state(), "gear")
	var effect_rows := RpgSystemsCharacterRows.rows(_character_state(), "effects")

	assert_eq(training_rows.size(), 1)
	assert_eq(training_rows[0]["id"], "character_progression")
	assert_eq(gear_rows.size(), 1)
	assert_eq(gear_rows[0]["id"], "character_equipment")
	assert_eq(effect_rows.size(), 1)
	assert_eq(effect_rows[0]["id"], "character_effects")


func test_category_filter_returns_empty_category_row_when_nothing_matches() -> void:
	var rows := RpgSystemsCharacterRows.rows(_character_state(), "crafting")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["id"], "systems_empty_crafting")
	assert_eq(rows[0]["title"], "No Crafting")
	assert_eq(rows[0]["meta"], "Crafting")


func test_actions_must_be_dictionary_to_replace_training_row() -> void:
	var rows := RpgSystemsCharacterRows.rows({
		"progression": "Level 5",
		"progression_actions": ["not an action"]
	}, "overview")

	assert_eq(rows[1]["title"], "Training")
	assert_false(rows[1].has("action_id"))


func _character_state() -> Dictionary:
	return {
		"player_health": "Health 80/100",
		"player_mana": "Mana 20/40",
		"progression": "Level 2",
		"progression_details": "Practice sword forms.",
		"progression_actions": [{"id": "train:strength", "text": "Train Strength"}],
		"equipment": "Weapon: Road Sword\nBody: Travel Coat",
		"statuses": "Bleeding",
		"status_details": "Bleeding: losing health."
	}
