class_name RpgSystemsTradeRows
extends RefCounted

const SystemsTabState = preload("res://scripts/ui/systems/systems_tab_state.gd")
const RpgSystemsRowData = preload("res://scripts/ui/systems/rows/rpg_systems_row_data.gd")
const SystemsActionIds = preload("res://scripts/main/actions/systems_action_ids.gd")


static func category_labels() -> Array:
	return ["Stock", "Buy", "Sell"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	var tab := SystemsTabState.trade(state)
	var actions := RpgSystemsRowData.array_field(tab.get("actions", []))
	var stock_rows := RpgSystemsRowData.array_field(tab.get("stock_rows", []))
	var rows_data: Array[Dictionary] = []
	for stock in stock_rows:
		if not stock is Dictionary:
			continue
		var item_name := String(stock.get("name", stock.get("item_id", "Item")))
		var merchant_name := String(stock.get("merchant_name", "Merchant"))
		var price := "%dg" % int(stock.get("price", 0))
		var available := bool(stock.get("available", false))
		rows_data.append({
			"id": "trade_stock_%s" % String(stock.get("item_id", rows_data.size())),
			"action_id": String(stock.get("action_id", "")),
			"title": item_name,
			"subtitle":
			(
				"Buy %s from %s" % [item_name, merchant_name]
				if available
				else "%s is closed" % merchant_name
			),
			"meta": price if available else "Closed",
			"detail":
			(
				_trade_item_detail(item_name, merchant_name, price, true)
				if available
				else "%s\n\n%s is closed now." % [item_name, merchant_name]
			)
		})
	var sell_actions := _sell_actions(actions)
	if not stock_rows.is_empty() and sell_actions.is_empty():
		rows_data.append({
			"id": "trade_sell_empty",
			"title": "Nothing to Sell",
			"subtitle": "No sellable goods in your pack.",
			"meta": "Sell",
			"detail": "No sellable items in your pack."
		})
	for action in sell_actions:
		var text := String(action.get("text", ""))
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

	var trade_text := String(tab.get("summary", "No trader selected."))
	var lines := _non_empty_lines(trade_text)
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


static func _sell_actions(actions: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action in actions:
		if not action is Dictionary:
			continue
		if SystemsActionIds.is_action(String(action.get("id", "")), SystemsActionIds.ACTION_SELL):
			result.append(action)
	return result


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


static func _non_empty_lines(value: String) -> Array[String]:
	var result: Array[String] = []
	for raw_line in value.split("\n", false):
		var line := raw_line.strip_edges()
		if not line.is_empty():
			result.append(line)
	return result
