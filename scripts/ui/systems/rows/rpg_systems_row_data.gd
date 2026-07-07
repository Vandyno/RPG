class_name RpgSystemsRowData
extends RefCounted


static func category_filtered_rows(
	rows_data: Array[Dictionary], category: String
) -> Array[Dictionary]:
	var passthrough := ["all", "overview", "active", "known"]
	if category.is_empty() or passthrough.has(category):
		return rows_data
	var filtered: Array[Dictionary] = []
	for row in rows_data:
		var row_text := "%s %s %s %s" % [
			String(row.get("id", "")),
			String(row.get("title", "")),
			String(row.get("subtitle", "")),
			String(row.get("meta", ""))
		]
		if row_matches_category(row_text.to_lower(), category):
			filtered.append(row)
	if not filtered.is_empty():
		return filtered
	return [empty_category_row(category)]


static func row_matches_category(row_text: String, category: String) -> bool:
	match category:
		"training":
			return row_text.contains("training") or row_text.contains("progression")
		"gear":
			return row_text.contains("gear") or row_text.contains("equipment")
		"effects":
			return row_text.contains("effect") or row_text.contains("status")
		"factions":
			return row_text.contains("faction") or row_text.contains("reputation")
		"time":
			return row_text.contains("time") or row_text.contains("wait") or row_text.contains("day")
		"recent":
			return (
				row_text.contains("recent")
				or row_text.contains("log")
				or row_text.contains("wait")
				or row_text.contains("save")
				or row_text.contains("load")
			)
		"system":
			return (
				row_text.contains("system")
				or row_text.contains("save")
				or row_text.contains("load")
			)
	return row_text.contains(category)


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


static func lower_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for entry in array_field(value):
		result.append(String(entry).to_lower())
	return result


static func array_field(value: Variant) -> Array:
	return value if value is Array else []
