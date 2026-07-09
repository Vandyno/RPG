extends GutTest

const RpgSystemsTradeRows = preload(
	"res://scripts/ui/systems/rows/rpg_systems_trade_rows.gd"
)


func test_category_labels_match_trade_sections() -> void:
	assert_eq(RpgSystemsTradeRows.category_labels(), ["Stock", "Buy", "Sell"])


func test_rows_build_available_closed_stock_and_sell_actions() -> void:
	var rows := RpgSystemsTradeRows.rows(_trade_state(), "all")

	assert_eq(rows.size(), 3)
	assert_eq(rows[0]["id"], "trade_stock_item_draught")
	assert_eq(rows[0]["action_id"], "buy:item_draught")
	assert_eq(rows[0]["title"], "Roadside Draught")
	assert_eq(rows[0]["subtitle"], "Buy Roadside Draught from Mara")
	assert_eq(rows[0]["meta"], "8g")
	assert_string_contains(rows[0]["detail"], "Buy offer")
	assert_string_contains(rows[0]["detail"], "Merchant: Mara")
	assert_eq(rows[1]["id"], "trade_stock_item_lantern")
	assert_eq(rows[1]["subtitle"], "Mara is closed")
	assert_eq(rows[1]["meta"], "Closed")
	assert_eq(rows[1]["detail"], "Lantern\n\nMara is closed now.")
	assert_eq(rows[2]["id"], "trade_sell_2")
	assert_eq(rows[2]["action_id"], "sell:item_hatchet")
	assert_eq(rows[2]["title"], "Hatchet")
	assert_eq(rows[2]["subtitle"], "Sell Hatchet from pack")
	assert_eq(rows[2]["meta"], "Sell")
	assert_eq(rows[2]["detail"], "Sell Hatchet\n\nTap this row to sell.")


func test_category_filter_returns_stock_buy_and_sell_rows() -> void:
	var stock_rows := RpgSystemsTradeRows.rows(_trade_state(), "stock")
	var buy_rows := RpgSystemsTradeRows.rows(_trade_state(), "buy")
	var sell_rows := RpgSystemsTradeRows.rows(_trade_state(), "sell")

	assert_eq(stock_rows.size(), 2)
	assert_eq(stock_rows[0]["id"], "trade_stock_item_draught")
	assert_eq(buy_rows.size(), 2)
	assert_eq(buy_rows[1]["id"], "trade_stock_item_lantern")
	assert_eq(sell_rows.size(), 1)
	assert_eq(sell_rows[0]["id"], "trade_sell_2")


func test_rows_add_sell_empty_when_stock_exists_without_sell_actions() -> void:
	var rows := RpgSystemsTradeRows.rows({
		"trade_stock_rows": [
			{"item_id": "item_draught", "name": "Draught", "price": 8, "available": true}
		],
		"trade_actions": [{"id": "buy:item_draught", "text": "Buy Draught"}]
	}, "sell")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["id"], "trade_sell_empty")
	assert_eq(rows[0]["title"], "Nothing to Sell")
	assert_eq(rows[0]["subtitle"], "No sellable goods in your pack.")
	assert_eq(rows[0]["meta"], "Sell")
	assert_eq(rows[0]["detail"], "No sellable items in your pack.")


func test_category_filter_returns_empty_category_row_when_nothing_matches() -> void:
	var rows := RpgSystemsTradeRows.rows(_trade_state(), "services")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["id"], "systems_empty_services")
	assert_eq(rows[0]["title"], "No Services")
	assert_eq(rows[0]["meta"], "Services")


func test_fallback_trade_rows_parse_summary_lines() -> void:
	var rows := RpgSystemsTradeRows.rows({
		"trade": "Peddler: Browse wares\n\nBarter: Try a better price"
	}, "all")

	assert_eq(rows.size(), 2)
	assert_eq(rows[0]["id"], "trade_0")
	assert_eq(rows[0]["title"], "Peddler")
	assert_eq(rows[0]["subtitle"], "Browse wares")
	assert_eq(rows[0]["meta"], "Trade")
	assert_eq(rows[0]["detail"], "Peddler: Browse wares")
	assert_eq(rows[1]["title"], "Barter")
	assert_eq(rows[1]["subtitle"], "Try a better price")


func test_fallback_trade_rows_return_empty_state_without_summary() -> void:
	var rows := RpgSystemsTradeRows.rows({"trade": ""}, "all")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["id"], "trade_empty")
	assert_eq(rows[0]["title"], "No Trader Selected")
	assert_eq(rows[0]["subtitle"], "Talk to a merchant or use a shop.")
	assert_eq(rows[0]["meta"], "Trade")
	assert_eq(rows[0]["detail"], "No trader selected.")


func test_helpers_filter_sell_actions_and_format_sell_detail() -> void:
	assert_eq(
		RpgSystemsTradeRows._sell_actions([
			{"id": "sell:item_hatchet", "text": "Sell Hatchet"},
			{"id": "buy:item_draught", "text": "Buy Draught"},
			"not an action"
		]),
		[{"id": "sell:item_hatchet", "text": "Sell Hatchet"}]
	)
	assert_eq(RpgSystemsTradeRows._non_empty_lines(" one \n\n two "), ["one", "two"])
	assert_eq(
		RpgSystemsTradeRows._trade_item_detail("Hatchet", "Mara", "5g", false),
		"Hatchet\nSell offer\nPrice: 5g\nMerchant: Mara\n\nTap this row to sell."
	)


func _trade_state() -> Dictionary:
	return {
		"system_tabs": {
			"trade": {
				"stock_rows": [
					{
						"item_id": "item_draught",
						"action_id": "buy:item_draught",
						"name": "Roadside Draught",
						"merchant_name": "Mara",
						"price": 8,
						"available": true
					},
					{
						"item_id": "item_lantern",
						"name": "Lantern",
						"merchant_name": "Mara",
						"price": 14,
						"available": false
					},
					"not stock"
				],
				"actions": [
					{"id": "sell:item_hatchet", "text": "Sell Hatchet"},
					{"id": "buy:item_draught", "text": "Buy Draught"}
				]
			}
		}
	}
