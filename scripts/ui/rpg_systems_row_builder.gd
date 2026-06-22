class_name RpgSystemsRowBuilder
extends RefCounted


static func rows(
	state: Dictionary, tab_id: String, message_log: Array[String]
) -> Array[Dictionary]:
	match tab_id:
		"character":
			return _character_rows(state)
		"quests":
			return _quest_rows(state)
		"map":
			return _map_rows(state)
		"journal":
			return _journal_rows(state, message_log)
		"trade":
			return _trade_rows(state)
		_:
			return _inventory_rows(state)


static func category_labels(tab_id: String) -> Array[String]:
	var labels: Array = {
		"inventory": ["All", "Gear", "Use", "Quest"],
		"character": ["Overview", "Training", "Gear", "Effects"],
		"quests": ["Active", "Routes", "Rewards"],
		"map": ["Known", "Routes", "Nearby"],
		"journal": ["Recent", "Factions", "Time"],
		"trade": ["Stock", "Buy", "Sell"]
	}.get(tab_id, ["Overview"])
	var result: Array[String] = []
	for label in labels:
		result.append(String(label))
	return result


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


static func _inventory_rows(state: Dictionary) -> Array[Dictionary]:
	var details_by_name := _detail_lines_by_name(String(state.get("inventory_details", "")))
	var rows_data: Array[Dictionary] = []
	for entry in _summary_entries(String(state.get("inventory", "empty"))):
		var title := String(entry.get("title", "Item"))
		var detail := String(details_by_name.get(title, "No item details available."))
		rows_data.append({
			"id": "inventory_%d" % rows_data.size(),
			"title": title,
			"subtitle": String(entry.get("meta", "Carried item")),
			"meta": "Inventory",
			"detail": "%s\n\n%s" % [String(entry.get("summary", title)), detail]
		})
	if rows_data.is_empty():
		rows_data.append({
			"id": "inventory_empty",
			"title": "Empty Pack",
			"subtitle": "No carried items.",
			"meta": "Inventory",
			"detail": "You are not carrying any loose items."
		})
	return rows_data


static func _character_rows(state: Dictionary) -> Array[Dictionary]:
	return [
		{
			"id": "character_health",
			"title": "Health",
			"subtitle": String(state.get("player_health", "Health unknown")),
			"meta": "Vitals",
			"detail": String(state.get("player_health", "Health unknown"))
		},
		{
			"id": "character_progression",
			"title": "Training",
			"subtitle": String(state.get("progression", "Level 1")),
			"meta": "Progression",
			"detail": _first_non_empty(
				String(state.get("progression_details", "")),
				String(state.get("progression", "Level 1"))
			)
		},
		{
			"id": "character_equipment",
			"title": "Equipment",
			"subtitle": _first_line(String(state.get("equipment", "Weapon: empty"))),
			"meta": "Gear",
			"detail": String(state.get("equipment", "Weapon: empty\nOffhand: empty\nBody: empty"))
		},
		{
			"id": "character_effects",
			"title": "Active Effects",
			"subtitle": String(state.get("statuses", "none")),
			"meta": "Status",
			"detail": _first_non_empty(String(state.get("status_details", "")), "Active effects: none")
		}
	]


static func _quest_rows(state: Dictionary) -> Array[Dictionary]:
	var rows_data: Array[Dictionary] = []
	for quest in _array_field(state.get("quests", [])):
		var text := String(quest)
		rows_data.append({
			"id": "quest_%d" % rows_data.size(),
			"title": _title_before_colon(text),
			"subtitle": _text_after_colon(text, "Active quest"),
			"meta": "Quest",
			"detail": _quest_detail_for_text(state, text)
		})
	if rows_data.is_empty():
		rows_data.append({
			"id": "quests_empty",
			"title": "No Active Quests",
			"subtitle": "Briarwatch is quiet for now.",
			"meta": "Quest",
			"detail": "No active quests."
		})
	return rows_data


static func _map_rows(state: Dictionary) -> Array[Dictionary]:
	var rows_data: Array[Dictionary] = []
	for location in _comma_entries(String(state.get("locations", "none"))):
		rows_data.append({
			"id": "map_location_%d" % rows_data.size(),
			"title": location,
			"subtitle": "Known place",
			"meta": "Map",
			"detail": _first_non_empty(String(state.get("location_details", "")), location)
		})
	var quest_directions := String(state.get("quest_directions", "none"))
	if not quest_directions.is_empty() and quest_directions != "none":
		for line in quest_directions.split("\n", false):
			rows_data.append({
				"id": "map_route_%d" % rows_data.size(),
				"title": _title_before_colon(line),
				"subtitle": _text_after_colon(line, "Quest route"),
				"meta": "Route",
				"detail": line
			})
	if rows_data.is_empty():
		rows_data.append({
			"id": "map_empty",
			"title": "No Known Places",
			"subtitle": "Explore to discover landmarks.",
			"meta": "Map",
			"detail": "No known places."
		})
	return rows_data


static func _journal_rows(state: Dictionary, message_log: Array[String]) -> Array[Dictionary]:
	var recent := "none"
	if not message_log.is_empty():
		recent = "\n".join(message_log.slice(maxi(0, message_log.size() - 6)))
	return [
		{
			"id": "journal_time",
			"title": "Time",
			"subtitle": String(state.get("time", "Day 1, 08:00")),
			"meta": "Journal",
			"detail": String(state.get("time_details", state.get("time", "")))
		},
		{
			"id": "journal_reputation",
			"title": "Reputation",
			"subtitle": String(state.get("factions", "none")),
			"meta": "Factions",
			"detail": String(state.get("factions", "none"))
		},
		{
			"id": "journal_events",
			"title": "Recent Events",
			"subtitle": _first_line(recent),
			"meta": "Log",
			"detail": recent
		}
	]


static func _trade_rows(state: Dictionary) -> Array[Dictionary]:
	var rows_data: Array[Dictionary] = []
	var trade_text := String(state.get("trade", "No trader selected."))
	var lines := _non_empty_lines(trade_text)
	if not lines.is_empty() and not lines[0].contains(":") and not lines[0].begins_with("-"):
		var merchant_name := lines[0]
		var hours := ""
		var gold := ""
		var closed := false
		var sell_text := ""
		rows_data.append({
			"id": "trade_merchant",
			"title": merchant_name,
			"subtitle": "Selected merchant",
			"meta": "Merchant",
			"detail": trade_text
		})
		for index in range(1, lines.size()):
			var line := lines[index]
			if line.begins_with("Hours:"):
				hours = _text_after_colon(line, "").strip_edges()
			elif line == "Closed now.":
				closed = true
			elif line.begins_with("Gold:"):
				gold = _text_after_colon(line, "").strip_edges()
			elif line.begins_with("Sell:"):
				sell_text = _text_after_colon(line, "none").strip_edges()
			elif line.begins_with("- "):
				var stock_text := line.substr(2).strip_edges()
				var item_name := _title_before_colon(stock_text)
				var price := _text_after_colon(stock_text, "").strip_edges()
				rows_data.append({
					"id": "trade_stock_%d" % rows_data.size(),
					"title": item_name,
					"subtitle": "Available to buy",
					"meta": price,
					"detail": "%s\nPrice: %s\n\n%s" % [item_name, price, merchant_name]
				})
		var merchant_subtitle := _trade_merchant_subtitle(hours, gold, closed)
		if not merchant_subtitle.is_empty():
			rows_data[0]["subtitle"] = merchant_subtitle
		if sell_text == "none":
			rows_data.append({
				"id": "trade_sell_empty",
				"title": "Nothing to Sell",
				"subtitle": "No carried goods the merchant wants.",
				"meta": "Sell",
				"detail": "No sellable carried items."
			})
		if rows_data.size() > 1:
			return rows_data
	for line in lines:
		rows_data.append({
			"id": "trade_%d" % rows_data.size(),
			"title": _title_before_colon(line),
			"subtitle": _text_after_colon(line, "Trade"),
			"meta": "Trade",
			"detail": line
		})
	if rows_data.is_empty():
		rows_data.append({
			"id": "trade_empty",
			"title": "No Trader Selected",
			"subtitle": "Talk to a merchant or use a shop.",
			"meta": "Trade",
			"detail": "No trader selected."
		})
	return rows_data


static func _trade_merchant_subtitle(hours: String, gold: String, closed: bool) -> String:
	var parts: Array[String] = []
	if not hours.is_empty():
		parts.append("Open %s" % hours)
	if not gold.is_empty():
		parts.append("Gold %s" % gold)
	if closed:
		parts.append("Closed now")
	return " - ".join(parts)


static func _non_empty_lines(value: String) -> Array[String]:
	var result: Array[String] = []
	for raw_line in value.split("\n", false):
		var line := raw_line.strip_edges()
		if not line.is_empty():
			result.append(line)
	return result


static func _summary_entries(summary: String) -> Array[Dictionary]:
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


static func _detail_lines_by_name(details: String) -> Dictionary:
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


static func _quest_detail_for_text(state: Dictionary, quest_text: String) -> String:
	var lines: Array[String] = [quest_text]
	var directions := String(state.get("quest_directions", "none"))
	if not directions.is_empty() and directions != "none":
		lines.append("")
		lines.append(directions)
	return "\n".join(lines)


static func _comma_entries(value: String) -> Array[String]:
	var entries: Array[String] = []
	if value.is_empty() or value == "none":
		return entries
	for part in value.split(",", false):
		var stripped := part.strip_edges()
		if not stripped.is_empty():
			entries.append(stripped)
	return entries


static func _title_before_colon(value: String) -> String:
	var separator := value.find(":")
	if separator <= 0:
		return value
	return value.substr(0, separator).strip_edges()


static func _text_after_colon(value: String, fallback: String) -> String:
	var separator := value.find(":")
	if separator < 0 or separator + 1 >= value.length():
		return fallback
	return value.substr(separator + 1).strip_edges()


static func _first_line(value: String) -> String:
	var lines := value.split("\n", false)
	if lines.is_empty():
		return value
	return lines[0].strip_edges()


static func _first_non_empty(value: String, fallback: String) -> String:
	var stripped := value.strip_edges()
	if stripped.is_empty() or stripped == "none":
		return fallback
	return stripped


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
