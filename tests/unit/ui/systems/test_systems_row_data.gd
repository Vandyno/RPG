extends GutTest

const RpgSystemsInventoryRows = preload(
	"res://scripts/ui/systems/rows/rpg_systems_inventory_rows.gd"
)
const RpgSystemsRowData = preload("res://scripts/ui/systems/rows/rpg_systems_row_data.gd")
const RpgTransferPaneBuilder = preload(
	"res://scripts/ui/systems/panes/rpg_transfer_pane_builder.gd"
)


func test_inventory_category_classifies_equipment_and_shields_consistently() -> void:
	assert_eq(
		RpgSystemsRowData.inventory_category({"name": "Buckler", "type": "shield"}),
		"armour"
	)
	assert_eq(
		RpgSystemsRowData.inventory_category({"name": "Gloves", "equipment_slot": "gloves"}),
		"armour"
	)
	assert_eq(
		RpgSystemsRowData.inventory_category({"name": "Hatchet", "equipment_slot": "right_hand"}),
		"weapons"
	)


func test_transfer_rows_and_pane_filter_use_shared_inventory_category() -> void:
	var shield := {
		"item_id": "item_buckler",
		"name": "Buckler",
		"count": 1,
		"type": "shield",
		"equipment_slot": "left_hand"
	}
	var state := {
		"system_tabs": {
			"inventory": {
				"transfer":
				{
					"open": true,
					"target": {"name": "Chest"},
					"player_items": [],
					"target_items": [shield]
				}
			}
		}
	}

	var rows := RpgSystemsInventoryRows.rows(state, "armour")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["title"], "Buckler")
	assert_true(RpgTransferPaneBuilder._matches_category(shield, "armour"))
	assert_false(RpgTransferPaneBuilder._matches_category(shield, "misc"))
