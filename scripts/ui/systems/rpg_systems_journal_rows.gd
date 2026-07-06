class_name RpgSystemsJournalRows
extends RefCounted


static func category_labels() -> Array:
	return ["Recent", "Factions", "Time", "System"]


static func rows(
	state: Dictionary, message_log: Array[String], category: String
) -> Array[Dictionary]:
	return RpgSystemsRowBuilder._category_filtered_rows(
		RpgSystemsRowBuilder._journal_rows(state, message_log), category
	)
