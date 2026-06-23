class_name EquipmentSlots
extends RefCounted

const SLOTS := [
	"head",
	"left_hand",
	"right_hand",
	"chest",
	"legs",
	"gloves",
	"boots",
	"back",
	"necklace",
	"ring_1",
	"ring_2"
]

const LEGACY_ALIASES := {
	"weapon": "right_hand",
	"offhand": "left_hand",
	"body": "chest"
}

const LEGACY_SAVE_ALIASES := {
	"right_hand": "weapon",
	"left_hand": "offhand",
	"chest": "body"
}


static func normalize(slot_id: String) -> String:
	var slot := slot_id.to_lower()
	if LEGACY_ALIASES.has(slot):
		return String(LEGACY_ALIASES[slot])
	if slot == "ring":
		return "ring_1"
	return slot


static func is_supported(slot_id: String) -> bool:
	return SLOTS.has(normalize(slot_id))


static func accepts(target_slot: String, item_slot: String) -> bool:
	var target := normalize(target_slot)
	var item := normalize(item_slot)
	if target.begins_with("ring_") and item.begins_with("ring_"):
		return true
	return target == item


static func first_slot_for_item_slot(item_slot: String, equipped: Dictionary) -> String:
	var normalized := normalize(item_slot)
	if normalized.begins_with("ring_"):
		for slot in ["ring_1", "ring_2"]:
			if String(equipped.get(slot, "")).is_empty():
				return slot
		return "ring_1"
	return normalized


static func save_slot(slot_id: String) -> String:
	var slot := normalize(slot_id)
	return String(LEGACY_SAVE_ALIASES.get(slot, slot))


static func label(slot_id: String) -> String:
	match normalize(slot_id):
		"head":
			return "Head"
		"left_hand":
			return "Left Hand"
		"right_hand":
			return "Right Hand"
		"chest":
			return "Chest"
		"legs":
			return "Legs"
		"gloves":
			return "Gloves"
		"boots":
			return "Boots"
		"back":
			return "Cloak"
		"necklace":
			return "Necklace"
		"ring_1":
			return "Ring 1"
		"ring_2":
			return "Ring 2"
	return slot_id.capitalize()
