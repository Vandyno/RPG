class_name RpgSystemsTradeRows
extends RefCounted

const SystemsTabState = preload("res://scripts/ui/systems/systems_tab_state.gd")
const RpgSystemsRowData = preload("res://scripts/ui/systems/rows/rpg_systems_row_data.gd")


static func category_labels() -> Array:
	return ["Stock", "Buy", "Sell"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	var tab := SystemsTabState.trade(state)
	var actions := RpgSystemsRowData.array_field(tab.get("actions", []))
	var rows_data: Array[Dictionary] = []
	var trade_text := String(tab.get("summary", "No trader selected."))
	var lines := _non_empty_lines(trade_text)
	if not lines.is_empty() and not lines[0].contains(":") and not lines[0].begins_with("-"):
		var merchant_name := lines[0]
		var closed := false
		var sell_text := ""
		var in_sell_section := false
		for index in range(1, lines.size()):
			var line := lines[index]
			if line == "Closed now.":
				closed = true
			elif line.begins_with("Sell:"):
				sell_text = RpgSystemsRowData.text_after_colon(line, "none").strip_edges()
				in_sell_section = true
			elif line.begins_with("- "):
				if in_sell_section:
					continue
				if closed:
					continue
				var stock_text := line.substr(2).strip_edges()
				var item_name := RpgSystemsRowData.title_before_colon(stock_text)
				var price := RpgSystemsRowData.text_after_colon(stock_text, "").strip_edges()
				var action_id := _action_id_for_text(actions, "Buy %s" % item_name)
				rows_data.append({
					"id": "trade_stock_%d" % rows_data.size(),
					"action_id": action_id,
					"title": item_name,
					"subtitle": "Buy %s from %s" % [item_name, merchant_name],
					"meta": price,
					"detail": _trade_item_detail(item_name, merchant_name, price, true)
				})
		if sell_text == "none":
			rows_data.append({
				"id": "trade_sell_empty",
				"title": "Nothing to Sell",
				"subtitle": "No sellable goods in your pack.",
				"meta": "Sell",
				"detail": "No sellable items in your pack."
			})
		for action in actions:
			if not action is Dictionary:
				continue
			var text := String(action.get("text", ""))
			if not text.begins_with("Sell "):
				continue
			rows_data.append({
				"id": "trade_sell_%d" % rows_data.size(),
				"action_id": String(action.get("id", "")),
				"title": text.trim_prefix("Sell "),
				"subtitle": "%s from pack" % text,
				"meta": "Sell",
				"detail": "%s\n\nTap this row to sell." % text
			})
		if not rows_data.is_empty():
			return _category_filtered_rows(rows_data, category)
	for line in lines:
		rows_data.append({
			"id": "trade_%d" % rows_data.size(),
			"title": RpgSystemsRowData.title_before_colon(line),
			"subtitle": RpgSystemsRowData.text_after_colon(line, "Trade"),
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


static func _category_filtered_rows(
	rows_data: Array[Dictionary], category: String
) -> Array[Dictionary]:
	if category.is_empty() or category == "all":
		return rows_data
	var filtered: Array[Dictionary] = []
	for row in rows_data:
		var row_text := "%s %s %s %s" % [
			String(row.get("id", "")),
			String(row.get("title", "")),
			String(row.get("subtitle", "")),
			String(row.get("meta", ""))
		]
		if _row_matches_category(row_text.to_lower(), category):
			filtered.append(row)
	if not filtered.is_empty():
		return filtered
	return [RpgSystemsRowData.empty_category_row(category)]


static func _row_matches_category(row_text: String, category: String) -> bool:
	match category:
		"stock", "buy":
			return (
				row_text.contains("trade_stock")
				or row_text.contains("buy ")
				or row_text.contains("available")
			)
		"sell":
			return row_text.contains("sell")
	return row_text.contains(category)


static func _trade_item_detail(
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


static func _action_id_for_text(actions: Array, prefix: String) -> String:
	for action in actions:
		if not action is Dictionary:
			continue
		if String(action.get("text", "")).begins_with(prefix):
			return String(action.get("id", ""))
	return ""


static func _non_empty_lines(value: String) -> Array[String]:
	var result: Array[String] = []
	for raw_line in value.split("\n", false):
		var line := raw_line.strip_edges()
		if not line.is_empty():
			result.append(line)
	return result
