class_name RpgSystemsRowBuilder
extends RefCounted

const RpgNavigationTextBuilder = preload("res://scripts/ui/text/rpg_navigation_text_builder.gd")
const RpgSystemsInventoryRows = preload("res://scripts/ui/systems/rpg_systems_inventory_rows.gd")
const RpgSystemsSpellRows = preload("res://scripts/ui/systems/rpg_systems_spell_rows.gd")
const RpgSystemsCharacterRows = preload("res://scripts/ui/systems/rpg_systems_character_rows.gd")
const RpgSystemsQuestRows = preload("res://scripts/ui/systems/rpg_systems_quest_rows.gd")
const RpgSystemsJournalRows = preload("res://scripts/ui/systems/rpg_systems_journal_rows.gd")
const RpgSystemsTradeRows = preload("res://scripts/ui/systems/rpg_systems_trade_rows.gd")


static func rows(
	state: Dictionary, tab_id: String, message_log: Array[String], category: String = "all"
) -> Array[Dictionary]:
	match tab_id:
		"spells":
			return RpgSystemsSpellRows.rows(state, category)
		"character":
			return RpgSystemsCharacterRows.rows(state, category)
		"quests":
			return RpgSystemsQuestRows.rows(state, category)
		"journal":
			return RpgSystemsJournalRows.rows(state, message_log, category)
		"trade":
			return RpgSystemsTradeRows.rows(state, category)
		_:
			return RpgSystemsInventoryRows.rows(state, category)


static func category_labels(tab_id: String) -> Array[String]:
	var labels: Array = _category_labels_for_tab(tab_id)
	var result: Array[String] = []
	for label in labels:
		result.append(String(label))
	return result


static func _category_labels_for_tab(tab_id: String) -> Array:
	match tab_id:
		"inventory":
			return RpgSystemsInventoryRows.category_labels()
		"spells":
			return RpgSystemsSpellRows.category_labels()
		"character":
			return RpgSystemsCharacterRows.category_labels()
		"quests":
			return RpgSystemsQuestRows.category_labels()
		"journal":
			return RpgSystemsJournalRows.category_labels()
		"trade":
			return RpgSystemsTradeRows.category_labels()
		_:
			return ["Overview"]


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
		"stock":
			return (
				row_text.contains("trade_stock")
				or row_text.contains("buy ")
				or row_text.contains("available")
			)
		"buy":
			return (
				row_text.contains("trade_stock")
				or row_text.contains("buy ")
				or row_text.contains("available")
			)
		"sell":
			return row_text.contains("sell")
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


static func trade_item_detail(
	item_name: String, merchant_name: String, price: String, buying: bool
) -> String:
	var verb := "Buy" if buying else "Sell"
	return "\n".join([
		item_name,
		"%s offer" % verb,
		"Price: %s" % price,
		"Merchant: %s" % merchant_name,
		"",
		"Tap this row to %s." % verb.to_lower()
	])


static func inventory_action_id_for_item(item: Dictionary) -> String:
	var item_id := String(item.get("item_id", ""))
	if item_id.is_empty():
		return ""
	var slot := String(item.get("equipment_slot", ""))
	if not slot.is_empty():
		return "equip:%s" % item_id
	if String(item.get("type", "")).to_lower() == "consumable":
		return "use:%s" % item_id
	return ""


static func action_id_for_text(actions: Array, prefix: String) -> String:
	for action in actions:
		if not action is Dictionary:
			continue
		if String(action.get("text", "")).begins_with(prefix):
			return String(action.get("id", ""))
	return ""


static func action_for_item_id(actions: Array, item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}
	for action in actions:
		if not action is Dictionary:
			continue
		var action_id := String(action.get("id", ""))
		if action_id.ends_with(":%s" % item_id):
			return action
	return {}


static func non_empty_lines(value: String) -> Array[String]:
	var result: Array[String] = []
	for raw_line in value.split("\n", false):
		var line := raw_line.strip_edges()
		if not line.is_empty():
			result.append(line)
	return result


static func summary_entries(summary: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if summary.is_empty() or summary == "empty" or summary == "none":
		return entries
	for part in summary.split(",", false):
		var stripped := part.strip_edges()
		if stripped.is_empty():
			continue
		var title := stripped
		var meta := "Carried item"
		var marker := stripped.rfind(" x")
		if marker > 0:
			title = stripped.substr(0, marker)
			meta = "Count %s" % stripped.substr(marker + 2)
		entries.append({"title": title, "summary": stripped, "meta": meta})
	return entries


static func detail_lines_by_name(details: String) -> Dictionary:
	var result := {}
	for raw_line in details.split("\n", false):
		var line := raw_line.strip_edges()
		if line.is_empty():
			continue
		var separator := line.find(":")
		if separator <= 0:
			continue
		var key := line.substr(0, separator).strip_edges()
		result[key] = line.substr(separator + 1).strip_edges()
		var count_marker := key.rfind(" x")
		if count_marker > 0:
			result[key.substr(0, count_marker).strip_edges()] = result[key]
	return result


static func quest_detail_for_text(state: Dictionary, quest_text: String) -> String:
	var lines: Array[String] = [quest_text]
	var directions := String(state.get("quest_directions", "none"))
	if not directions.is_empty() and directions != "none":
		lines.append("")
		lines.append(RpgNavigationTextBuilder.friendly_route_lines(directions))
	return "\n".join(lines)


static func comma_entries(value: String) -> Array[String]:
	var entries: Array[String] = []
	if value.is_empty() or value == "none":
		return entries
	for part in value.split(",", false):
		var stripped := part.strip_edges()
		if not stripped.is_empty():
			entries.append(stripped)
	return entries


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


static func route_after_colon(value: String, fallback: String) -> String:
	var route := text_after_colon(value, fallback)
	return RpgNavigationTextBuilder.friendly_navigation(route)


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
