extends GutTest

const RpgSystemsJournalRows = preload(
	"res://scripts/ui/systems/rows/rpg_systems_journal_rows.gd"
)


func test_category_labels_match_journal_sections() -> void:
	assert_eq(RpgSystemsJournalRows.category_labels(), ["Recent", "Factions", "Time", "System"])


func test_rows_build_recent_time_wait_reputation_and_system_actions() -> void:
	var rows := RpgSystemsJournalRows.rows(
		_journal_state(),
		["m1", "m2", "m3", "m4", "m5", "m6", "m7", "m8"],
		""
	)

	assert_eq(rows.size(), 6)
	assert_eq(rows[0]["id"], "journal_events")
	assert_eq(rows[0]["title"], "Recent Events")
	assert_eq(rows[0]["subtitle"], "m3")
	assert_eq(rows[0]["meta"], "Log")
	assert_eq(rows[0]["detail"], "m3\nm4\nm5\nm6\nm7\nm8")
	assert_eq(rows[1]["id"], "journal_time")
	assert_eq(rows[1]["subtitle"], "Day 2, 09:30")
	assert_eq(rows[1]["detail"], "Cool morning")
	assert_eq(rows[2]["id"], "journal_wait")
	assert_eq(rows[2]["action_id"], "wait:1")
	assert_eq(rows[3]["title"], "Reputation")
	assert_eq(rows[3]["subtitle"], "Road Wardens: wary")
	assert_eq(rows[4]["action_id"], "save:game")
	assert_eq(rows[5]["action_id"], "load:game")


func test_rows_use_none_for_empty_message_log_and_time_detail_fallback() -> void:
	var rows := RpgSystemsJournalRows.rows({"time": "Day 1, 08:00"}, [], "")

	assert_eq(rows[0]["subtitle"], "none")
	assert_eq(rows[0]["detail"], "none")
	assert_eq(rows[1]["subtitle"], "Day 1, 08:00")
	assert_eq(rows[1]["detail"], "Day 1, 08:00")
	assert_eq(rows[3]["subtitle"], "none")


func test_category_filter_returns_matching_journal_rows() -> void:
	var message_log: Array[String] = ["Met Mara", "Opened chest"]
	var state := _journal_state()

	var faction_rows := RpgSystemsJournalRows.rows(state, message_log, "factions")
	var time_rows := RpgSystemsJournalRows.rows(state, message_log, "time")
	var system_rows := RpgSystemsJournalRows.rows(state, message_log, "system")

	assert_eq(faction_rows.size(), 1)
	assert_eq(faction_rows[0]["id"], "journal_reputation")
	assert_eq(time_rows.size(), 2)
	assert_eq(time_rows[0]["id"], "journal_time")
	assert_eq(time_rows[1]["id"], "journal_wait")
	assert_eq(system_rows.size(), 2)
	assert_eq(system_rows[0]["id"], "journal_save")
	assert_eq(system_rows[1]["id"], "journal_load")


func test_category_filter_returns_empty_category_row_when_nothing_matches() -> void:
	var rows := RpgSystemsJournalRows.rows(_journal_state(), [], "crafting")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["id"], "systems_empty_crafting")
	assert_eq(rows[0]["title"], "No Crafting")
	assert_eq(rows[0]["subtitle"], "Nothing in this section.")
	assert_eq(rows[0]["meta"], "Crafting")
	assert_eq(rows[0]["detail"], "No crafting entries available.")


func _journal_state() -> Dictionary:
	return {
		"time": "Day 2, 09:30",
		"time_details": "Cool morning",
		"factions": "Road Wardens: wary"
	}
