class_name RpgSystemsQuestRows
extends RefCounted


static func category_labels() -> Array:
	return ["Active", "Routes", "Rewards"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	return RpgSystemsRowBuilder._quest_rows(state, category)
