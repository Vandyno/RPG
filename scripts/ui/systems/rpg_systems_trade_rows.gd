class_name RpgSystemsTradeRows
extends RefCounted


static func category_labels() -> Array:
	return ["Stock", "Buy", "Sell"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	return RpgSystemsRowBuilder._trade_rows(state, category)
