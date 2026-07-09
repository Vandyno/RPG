class_name RpgSystemsJournalRows
extends RefCounted

const RpgSystemsRowData = preload("res://scripts/ui/systems/rows/rpg_systems_row_data.gd")
const SystemsActionIds = preload("res://scripts/main/actions/systems_action_ids.gd")


static func category_labels() -> Array:
	return ["Recent", "Factions", "Time", "System"]


static func rows(
	state: Dictionary, message_log: Array[String], category: String
) -> Array[Dictionary]:
	return RpgSystemsRowData.category_filtered_rows(_journal_rows(state, message_log), category)


static func _journal_rows(state: Dictionary, message_log: Array[String]) -> Array[Dictionary]:
	var recent := "none"
	if not message_log.is_empty():
		recent = "\n".join(message_log.slice(maxi(0, message_log.size() - 6)))
	return [
		{
			"id": "journal_events",
			"title": "Recent Events",
			"subtitle": RpgSystemsRowData.first_line(recent),
			"meta": "Log",
			"detail": recent
		},
		{
			"id": "journal_time",
			"title": "Time",
			"subtitle": String(state.get("time", "Day 1, 08:00")),
			"meta": "Journal",
			"detail": String(state.get("time_details", state.get("time", "")))
		},
		{
			"id": "journal_wait",
			"action_id": SystemsActionIds.wait_hours(1),
			"title": "Wait 1h",
			"subtitle": "Pass one hour.",
			"meta": "Time",
			"detail": "Wait for one hour."
		},
		{
			"id": "journal_reputation",
			"title": "Reputation",
			"subtitle": String(state.get("factions", "none")),
			"meta": "Factions",
			"detail": String(state.get("factions", "none"))
		},
		{
			"id": "journal_save",
			"action_id": "save:game",
			"title": "Save Game",
			"subtitle": "Write current progress.",
			"meta": "System",
			"detail": "Save current progress."
		},
		{
			"id": "journal_load",
			"action_id": "load:game",
			"title": "Load Game",
			"subtitle": "Restore saved progress.",
			"meta": "System",
			"detail": "Load saved progress."
		}
	]
