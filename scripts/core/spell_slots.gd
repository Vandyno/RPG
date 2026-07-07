class_name SpellSlots
extends RefCounted

const SLOTS := ["ability_1", "ability_2", "ability_3"]
const DEFAULT_SLOT := "ability_1"
const LABELS := {
	"ability_1": "Ability I",
	"ability_2": "Ability II",
	"ability_3": "Ability III"
}
const SHORT_LABELS := {
	"ability_1": "I",
	"ability_2": "II",
	"ability_3": "III"
}


static func is_supported(slot_id: String) -> bool:
	return SLOTS.has(slot_id)


static func label(slot_id: String) -> String:
	return String(LABELS.get(slot_id, ""))


static func short_label(slot_id: String) -> String:
	return String(SHORT_LABELS.get(slot_id, ""))
