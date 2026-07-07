class_name RpgSystemsRowBuilder
extends RefCounted

const RpgSystemsInventoryRows = preload(
	"res://scripts/ui/systems/rows/rpg_systems_inventory_rows.gd"
)
const RpgSystemsSpellRows = preload("res://scripts/ui/systems/rows/rpg_systems_spell_rows.gd")
const RpgSystemsCharacterRows = preload(
	"res://scripts/ui/systems/rows/rpg_systems_character_rows.gd"
)
const RpgSystemsQuestRows = preload("res://scripts/ui/systems/rows/rpg_systems_quest_rows.gd")
const RpgSystemsJournalRows = preload("res://scripts/ui/systems/rows/rpg_systems_journal_rows.gd")
const RpgSystemsTradeRows = preload("res://scripts/ui/systems/rows/rpg_systems_trade_rows.gd")


static func rows(
	state: Dictionary, tab_id: String, message_log: Array[String], category: String = "all"
) -> Array[Dictionary]:
	match tab_id:
		"spells":
			return RpgSystemsSpellRows.rows(state, category)
		"character":
			return RpgSystemsCharacterRows.rows(state, category)
		"quests":
			return RpgSystemsQuestRows.rows(state, category)
		"journal":
			return RpgSystemsJournalRows.rows(state, message_log, category)
		"trade":
			return RpgSystemsTradeRows.rows(state, category)
		_:
			return RpgSystemsInventoryRows.rows(state, category)


static func category_labels(tab_id: String) -> Array[String]:
	var labels: Array = _category_labels_for_tab(tab_id)
	var result: Array[String] = []
	for label in labels:
		result.append(String(label))
	return result


static func _category_labels_for_tab(tab_id: String) -> Array:
	match tab_id:
		"inventory":
			return RpgSystemsInventoryRows.category_labels()
		"spells":
			return RpgSystemsSpellRows.category_labels()
		"character":
			return RpgSystemsCharacterRows.category_labels()
		"quests":
			return RpgSystemsQuestRows.category_labels()
		"journal":
			return RpgSystemsJournalRows.category_labels()
		"trade":
			return RpgSystemsTradeRows.category_labels()
		_:
			return ["Overview"]
