class_name RpgSystemsTradeRows
extends RefCounted


static func category_labels() -> Array:
	return ["Stock", "Buy", "Sell"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	var rows_data: Array[Dictionary] = []
	var trade_text := String(state.get("trade", "No trader selected."))
	var lines := RpgSystemsRowBuilder.non_empty_lines(trade_text)
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
				sell_text = RpgSystemsRowBuilder.text_after_colon(line, "none").strip_edges()
				in_sell_section = true
			elif line.begins_with("- "):
				if in_sell_section:
					continue
				if closed:
					continue
				var stock_text := line.substr(2).strip_edges()
				var item_name := RpgSystemsRowBuilder.title_before_colon(stock_text)
				var price := RpgSystemsRowBuilder.text_after_colon(stock_text, "").strip_edges()
				var action_id := RpgSystemsRowBuilder.action_id_for_text(
					RpgSystemsRowBuilder.array_field(state.get("trade_actions", [])),
					"Buy %s" % item_name
				)
				rows_data.append({
					"id": "trade_stock_%d" % rows_data.size(),
					"action_id": action_id,
					"title": item_name,
					"subtitle": "Buy %s from %s" % [item_name, merchant_name],
					"meta": price,
					"detail": RpgSystemsRowBuilder.trade_item_detail(
						item_name, merchant_name, price, true
					)
				})
		if sell_text == "none":
			rows_data.append({
				"id": "trade_sell_empty",
				"title": "Nothing to Sell",
				"subtitle": "No sellable goods in your pack.",
				"meta": "Sell",
				"detail": "No sellable items in your pack."
			})
		for action in RpgSystemsRowBuilder.array_field(state.get("trade_actions", [])):
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
			return RpgSystemsRowBuilder.category_filtered_rows(rows_data, category)
	for line in lines:
		rows_data.append({
			"id": "trade_%d" % rows_data.size(),
			"title": RpgSystemsRowBuilder.title_before_colon(line),
			"subtitle": RpgSystemsRowBuilder.text_after_colon(line, "Trade"),
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
