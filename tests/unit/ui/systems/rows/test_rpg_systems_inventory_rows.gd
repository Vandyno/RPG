extends GutTest

const RpgSystemsInventoryRows = preload(
	"res://scripts/ui/systems/rows/rpg_systems_inventory_rows.gd"
)


func test_category_labels_match_inventory_sections() -> void:
	assert_eq(
		RpgSystemsInventoryRows.category_labels(),
		["All", "Weapons", "Armour", "Ingredients", "Misc", "Quest"]
	)


func test_typed_inventory_rows_include_actions_meta_and_detail() -> void:
	var rows := RpgSystemsInventoryRows.rows(_inventory_state(), "all")

	assert_eq(rows.size(), 2)
	assert_eq(rows[0]["id"], "inventory_item_sword")
	assert_eq(rows[0]["item_id"], "item_sword")
	assert_eq(rows[0]["action_id"], "equip:item_sword")
	assert_eq(rows[0]["equipment_slot"], "right_hand")
	assert_eq(rows[0]["title"], "Road Sword")
	assert_eq(rows[0]["subtitle"], "Count 2 - Equip - 2.5 wt - 10g")
	assert_eq(rows[0]["meta"], "Weapons")
	assert_string_contains(rows[0]["detail"], "Road Sword x2")
	assert_string_contains(rows[0]["detail"], "Weight: 2.5")
	assert_string_contains(rows[0]["detail"], "Value: 10g")
	assert_string_contains(rows[0]["detail"], "A battered blade.")
	assert_eq(rows[1]["title"], "Mint")
	assert_eq(rows[1]["meta"], "Ingredients")


func test_typed_inventory_rows_filter_by_inventory_category() -> void:
	var rows := RpgSystemsInventoryRows.rows(_inventory_state(), "ingredients")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["item_id"], "item_mint")
	assert_eq(rows[0]["subtitle"], "Count 3")


func test_transfer_rows_build_put_and_take_actions() -> void:
	var rows := RpgSystemsInventoryRows.rows(_transfer_state(), "all")

	assert_eq(rows.size(), 3)
	assert_eq(rows[0]["id"], "transfer_player_item_apple")
	assert_eq(rows[0]["action_id"], "put:item_apple")
	assert_eq(rows[0]["title"], "Apple")
	assert_eq(rows[0]["subtitle"], "Player Pack - Count 2 - Put")
	assert_eq(rows[0]["meta"], "Put")
	assert_string_contains(rows[0]["detail"], "Player Pack")
	assert_string_contains(rows[0]["detail"], "Apple x2")
	assert_eq(rows[2]["id"], "transfer_target_item_gold_coin")
	assert_eq(rows[2]["action_id"], "take:item_gold_coin")
	assert_eq(rows[2]["subtitle"], "Chest - Count 4 - Take")
	assert_eq(rows[2]["meta"], "Take")


func test_transfer_rows_filter_by_side_or_item_category() -> void:
	var player_rows := RpgSystemsInventoryRows.rows(_transfer_state(), "player")
	var target_rows := RpgSystemsInventoryRows.rows(_transfer_state(), "target")
	var weapon_rows := RpgSystemsInventoryRows.rows(_transfer_state(), "weapons")

	assert_eq(player_rows.size(), 2)
	assert_eq(player_rows[0]["meta"], "Put")
	assert_eq(target_rows.size(), 1)
	assert_eq(target_rows[0]["meta"], "Take")
	assert_eq(weapon_rows.size(), 1)
	assert_eq(weapon_rows[0]["item_id"], "item_sword")


func test_transfer_rows_return_empty_state_without_valid_items() -> void:
	var rows := RpgSystemsInventoryRows.rows({
		"transfer_open": true,
		"transfer_target": {"name": "Chest"},
		"transfer_player_items": [{"item_id": "", "count": 1}],
		"transfer_target_items": [{"item_id": "item_coin", "count": 0}]
	}, "all")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["id"], "transfer_empty")
	assert_eq(rows[0]["title"], "No Transfer Items")
	assert_eq(rows[0]["subtitle"], "Both inventories are empty.")
	assert_eq(rows[0]["meta"], "Transfer")
	assert_eq(rows[0]["detail"], "No items available to move.")


func test_summary_inventory_rows_use_detail_lines_by_name() -> void:
	var rows := RpgSystemsInventoryRows.rows({
		"inventory": "Apple x2, Coin,",
		"inventory_details": "Apple x2: Fresh fruit\nCoin: Old silver"
	}, "all")

	assert_eq(rows.size(), 2)
	assert_eq(rows[0]["id"], "inventory_0")
	assert_eq(rows[0]["title"], "Apple")
	assert_eq(rows[0]["subtitle"], "Count 2")
	assert_eq(rows[0]["meta"], "Inventory")
	assert_eq(rows[0]["detail"], "Apple x2\n\nFresh fruit")
	assert_eq(rows[1]["title"], "Coin")
	assert_eq(rows[1]["subtitle"], "Carried item")
	assert_eq(rows[1]["detail"], "Coin\n\nOld silver")


func test_summary_and_action_helpers_cover_empty_and_invalid_values() -> void:
	assert_true(RpgSystemsInventoryRows._summary_entries("empty").is_empty())
	assert_true(RpgSystemsInventoryRows._summary_entries("none").is_empty())
	assert_true(RpgSystemsInventoryRows._summary_entries("").is_empty())
	assert_eq(RpgSystemsInventoryRows._detail_lines_by_name("bad line"), {})
	assert_eq(
		RpgSystemsInventoryRows._action_for_item_id(
			[{"item_id": "item_mint", "id": "use:item_mint"}, "bad"],
			"item_mint"
		),
		{"item_id": "item_mint", "id": "use:item_mint"}
	)
	assert_eq(RpgSystemsInventoryRows._action_for_item_id([], ""), {})


func _inventory_state() -> Dictionary:
	return {
		"system_tabs": {
			"inventory": {
				"items": [
					{
						"item_id": "item_sword",
						"name": "Road Sword",
						"count": 2,
						"type": "weapon",
						"equipment_slot": "right_hand",
						"description": "A battered blade.",
						"weight": 1.25,
						"value": 10
					},
					{
						"item_id": "item_mint",
						"name": "Mint",
						"count": 3,
						"type": "ingredient"
					},
					{"item_id": "item_empty", "name": "Empty", "count": 0},
					"not an item"
				],
				"actions": [{"item_id": "item_sword", "id": "equip:item_sword", "text": "Equip"}]
			}
		}
	}


func _transfer_state() -> Dictionary:
	return {
		"transfer_open": true,
		"transfer_target": {"name": "Chest"},
		"transfer_player_items": [
			{
				"item_id": "item_apple",
				"name": "Apple",
				"count": 2,
				"type": "ingredient",
				"description": "Crisp.",
				"weight": 0.2,
				"value": 1
			},
			{
				"item_id": "item_sword",
				"name": "Sword",
				"count": 1,
				"type": "weapon"
			}
		],
		"transfer_target_items": [
			{"item_id": "item_gold_coin", "name": "Gold Coin", "count": 4, "value": 4},
			"not an item"
		]
	}
