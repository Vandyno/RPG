class_name RpgSystemsCharacterRows
extends RefCounted


static func category_labels() -> Array:
	return ["Overview", "Training", "Gear", "Effects"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	return RpgSystemsRowBuilder._category_filtered_rows(
		RpgSystemsRowBuilder._character_rows(state), category
	)
