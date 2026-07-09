class_name RpgSystemsRowData
extends RefCounted

const ARMOUR_EQUIPMENT_SLOTS := [
	"left_hand",
	"chest",
	"head",
	"legs",
	"gloves",
	"boots",
	"back",
	"necklace",
	"ring_1",
	"ring_2"
]
const ROW_CATEGORY_TERMS := {
	"training": ["training", "progression"],
	"gear": ["gear", "equipment"],
	"effects": ["effect", "status"],
	"factions": ["faction", "reputation"],
	"time": ["time", "wait", "day"],
	"recent": ["recent", "log", "wait", "save", "load"],
	"system": ["system", "save", "load"]
}


static func category_filtered_rows(
	rows_data: Array[Dictionary], category: String
) -> Array[Dictionary]:
	return category_filtered_rows_by_terms(
		rows_data, category, ["all", "overview", "active", "known"], ROW_CATEGORY_TERMS
	)


static func category_filtered_rows_by_terms(
	rows_data: Array[Dictionary],
	category: String,
	passthrough: Array[String],
	category_terms: Dictionary
) -> Array[Dictionary]:
	if category.is_empty() or passthrough.has(category):
		return rows_data
	var filtered: Array[Dictionary] = []
	for row in rows_data:
		if row_matches_category_terms(row_search_text(row), category, category_terms):
			filtered.append(row)
	if not filtered.is_empty():
		return filtered
	return [empty_category_row(category)]


static func row_matches_category(row_text: String, category: String) -> bool:
	return row_matches_category_terms(row_text, category, ROW_CATEGORY_TERMS)


static func row_matches_category_terms(
	row_text: String, category: String, category_terms: Dictionary
) -> bool:
	if category_terms.has(category):
		for term in category_terms[category]:
			if row_text.contains(String(term)):
				return true
		return false
	return row_text.contains(category)


static func row_search_text(row: Dictionary) -> String:
	return ("%s %s %s %s" % [
		String(row.get("id", "")),
		String(row.get("title", "")),
		String(row.get("subtitle", "")),
		String(row.get("meta", ""))
	]).to_lower()


static func empty_category_row(category: String) -> Dictionary:
	var label := category.capitalize()
	return {
		"id": "systems_empty_%s" % category,
		"title": "No %s" % label,
		"subtitle": "Nothing in this section.",
		"meta": label,
		"detail": "No %s entries available." % label.to_lower()
	}


static func title_before_colon(value: String) -> String:
	var separator := value.find(":")
	if separator <= 0:
		return value
	return value.substr(0, separator).strip_edges()


static func text_after_colon(value: String, fallback: String) -> String:
	var separator := value.find(":")
	if separator < 0 or separator + 1 >= value.length():
		return fallback
	return value.substr(separator + 1).strip_edges()


static func first_line(value: String) -> String:
	var lines := value.split("\n", false)
	if lines.is_empty():
		return value
	return lines[0].strip_edges()


static func first_non_empty(value: String, fallback: String) -> String:
	var stripped := value.strip_edges()
	if stripped.is_empty() or stripped == "none":
		return fallback
	return stripped


static func format_weight(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.1f" % value


static func format_float(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.1f" % value


static func inventory_category(item: Dictionary) -> String:
	var item_type := String(item.get("type", "")).to_lower()
	var slot := String(item.get("equipment_slot", "")).to_lower()
	var tags := lower_array(item.get("tags", []))
	if item_type == "weapon" or slot == "right_hand" or tags.has("weapon"):
		return "weapons"
	if ["armor", "armour", "shield"].has(item_type) or ARMOUR_EQUIPMENT_SLOTS.has(slot):
		return "armour"
	if tags.has("armor") or tags.has("armour") or tags.has("shield"):
		return "armour"
	if item_type == "ingredient" or tags.has("ingredient"):
		return "ingredients"
	if item_type == "quest_item" or tags.has("quest"):
		return "quest"
	return "misc"


static func inventory_category_label(category: String) -> String:
	return {
		"weapons": "Weapons",
		"armour": "Armour",
		"ingredients": "Ingredients",
		"quest": "Quest",
		"misc": "Misc"
	}.get(category, "Inventory")


static func lower_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for entry in array_field(value):
		result.append(String(entry).to_lower())
	return result


static func array_field(value: Variant) -> Array:
	return value if value is Array else []
