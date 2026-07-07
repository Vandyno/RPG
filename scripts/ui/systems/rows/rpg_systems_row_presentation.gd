class_name RpgSystemsRowPresentation
extends RefCounted


static func clear_non_button_children(container: Node) -> void:
	for index in range(container.get_child_count() - 1, -1, -1):
		var child := container.get_child(index)
		if child is Button:
			continue
		container.remove_child(child)
		child.free()


static func tab_label_width(label: String, fallback: float, compact: bool) -> float:
	if compact:
		return fallback
	var widths := {
		"All": 52,
		"Weapons": 72,
		"Armour": 72,
		"Ingredients": 88,
		"Misc": 58,
		"Quest": 58
	}
	return float(widths.get(label, int(fallback)))


static func button_text(row: Dictionary) -> String:
	var title := String(row.get("title", "Entry"))
	var subtitle := String(row.get("subtitle", ""))
	var meta := String(row.get("meta", ""))
	if subtitle.is_empty() and meta.is_empty():
		return title
	if subtitle.is_empty():
		return "%s\n%s" % [title, meta]
	if meta.is_empty():
		return "%s\n%s" % [title, subtitle]
	return "%s\n%s - %s" % [title, meta, subtitle]


static func selected_row(rows_data: Array[Dictionary], selected_row_id: String) -> Dictionary:
	for row in rows_data:
		if String(row.get("id", "")) == selected_row_id:
			return row
	return rows_data[0] if not rows_data.is_empty() else {}


static func has_id(rows_data: Array[Dictionary], row_id: String) -> bool:
	if row_id.is_empty():
		return false
	for row in rows_data:
		if String(row.get("id", "")) == row_id:
			return true
	return false


static func hidden_text(rows_data: Array[Dictionary]) -> String:
	var lines: Array[String] = []
	for row in rows_data:
		lines.append(String(row.get("title", "")))
		var subtitle := String(row.get("subtitle", ""))
		if not subtitle.is_empty():
			lines.append(subtitle)
	return "\n".join(lines)
