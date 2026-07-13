extends GutTest

const RpgSystemsSpellRows = preload(
	"res://scripts/ui/systems/rows/rpg_systems_spell_rows.gd"
)


func test_category_labels_match_known_spell_filters() -> void:
	assert_eq(
		RpgSystemsSpellRows.category_labels(),
		["All", "Fire", "Frost", "Storm", "Restore", "Necromancy", "Utility"]
	)


func test_rows_build_assigned_spell_data_and_ignore_invalid_entries() -> void:
	var rows := RpgSystemsSpellRows.rows({
		"system_tabs": {
			"spells": {
				"spells": [
					{
						"spell_id": "ember",
						"name": "Ember",
						"school": "Fire",
						"assigned_label": "Left Mouse",
						"mana_cost": 4,
						"mana_drain_per_second": 2.5,
						"range": "12m",
						"behavior": "projectile"
					},
					"not a spell"
				]
			}
		}
	}, "all")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["id"], "spell_ember")
	assert_eq(rows[0]["spell_id"], "ember")
	assert_eq(rows[0]["title"], "Ember")
	assert_eq(rows[0]["subtitle"], "Fire school - Assigned: Left Mouse")
	assert_eq(rows[0]["meta"], "2.5 MP/s")
	assert_string_contains(rows[0]["detail"], "Mana cost/drain: 2.5 per second")
	assert_string_contains(rows[0]["detail"], "Range: 12m")
	assert_string_contains(rows[0]["detail"], "Assigned slot: Left Mouse")


func test_rows_filter_by_school_category() -> void:
	var rows := RpgSystemsSpellRows.rows({
		"spells": [
			{"spell_id": "spark", "name": "Spark", "school": "Storm"},
			{"spell_id": "mend", "name": "Mend", "school": "Restore"}
		]
	}, "restore")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["spell_id"], "mend")
	assert_eq(rows[0]["subtitle"], "Restore school - Unassigned")


func test_rows_return_category_empty_state_when_filter_has_no_matches() -> void:
	var rows := RpgSystemsSpellRows.rows({
		"spells": [
			{"spell_id": "spark", "name": "Spark", "school": "Storm"}
		]
	}, "frost")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["id"], "spells_empty_frost")
	assert_eq(rows[0]["title"], "No Spells")
	assert_eq(rows[0]["subtitle"], "No known magic here.")
	assert_eq(rows[0]["meta"], "Spells")
	assert_eq(rows[0]["detail"], "No spells available.")


func test_rows_use_defaults_for_sparse_spell_data() -> void:
	var rows := RpgSystemsSpellRows.rows({"spells": [{}]}, "utility")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["id"], "spell_")
	assert_eq(rows[0]["spell_id"], "")
	assert_eq(rows[0]["title"], "Spell")
	assert_eq(rows[0]["subtitle"], "Utility school - Unassigned")
	assert_eq(rows[0]["meta"], "0 MP/s")
	assert_string_contains(rows[0]["detail"], "School: Utility")
	assert_string_contains(rows[0]["detail"], "Behavior: ")
	assert_string_contains(rows[0]["detail"], "Assigned slot: None")
