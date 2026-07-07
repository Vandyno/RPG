extends GutTest

const RpgSystemsTradeRows = preload("res://scripts/ui/systems/rows/rpg_systems_trade_rows.gd")
const SystemsActionIds = preload("res://scripts/ui/systems/systems_action_ids.gd")


func test_systems_action_ids_build_and_parse_slot_actions() -> void:
	var action_id := SystemsActionIds.equip_slot("item_road_hatchet", "right_hand")

	assert_eq(action_id, "equip_slot:item_road_hatchet:right_hand")
	assert_eq(
		SystemsActionIds.parse(action_id),
		{"action": "equip_slot", "target_id": "item_road_hatchet", "slot_id": "right_hand"}
	)


func test_trade_sell_rows_filter_by_action_id() -> void:
	var state := {
		"system_tabs": {
			"trade": {
				"actions": [
					{"id": SystemsActionIds.sell_item("item_road_hatchet"), "text": "Peddle Hatchet"},
					{"id": SystemsActionIds.buy_item("item_roadside_draught"), "text": "Sell-looking label"}
				],
				"stock_rows": [
					{
						"item_id": "item_roadside_draught",
						"name": "Roadside Draught",
						"price": 8,
						"available": true
					}
				]
			}
		}
	}

	var rows := RpgSystemsTradeRows.rows(state, "sell")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["action_id"], "sell:item_road_hatchet")
