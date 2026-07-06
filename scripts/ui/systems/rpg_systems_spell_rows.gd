class_name RpgSystemsSpellRows
extends RefCounted


static func category_labels() -> Array:
	return ["All", "Fire", "Frost", "Storm", "Restore", "Utility"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	return RpgSystemsRowBuilder._spell_rows(state, category)
