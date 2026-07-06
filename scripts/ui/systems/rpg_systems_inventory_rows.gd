class_name RpgSystemsInventoryRows
extends RefCounted


static func category_labels() -> Array:
	return ["All", "Weapons", "Armour", "Ingredients", "Misc", "Quest"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	return RpgSystemsRowBuilder._inventory_rows(state, category)
