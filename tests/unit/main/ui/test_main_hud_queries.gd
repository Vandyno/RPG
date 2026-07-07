extends GutTest

const MainHudQueries = preload("res://scripts/main/ui/main_hud_queries.gd")


class InventoryStub:
	var items := {"item_apple": 2, "item_sword": 1}

	func get_count(item_id: String) -> int:
		return int(items.get(item_id, 0))


class ContentStub:
	func get_item(item_id: String) -> Dictionary:
		match item_id:
			"item_apple":
				return {
					"name": "Apple",
					"description": "Crisp.",
					"effects_on_use": [{"kind": "heal"}]
				}
			"item_sword":
				return {"name": "Sword", "equipment_slot": "right_hand"}
		return {}


class EquipmentStub:
	func get_equipped_item(slot_id: String) -> String:
		return "item_sword" if slot_id == "right_hand" else ""


func test_inventory_text_details_and_actions_are_sorted_and_player_ready() -> void:
	var queries := MainHudQueries.new()
	queries.setup(
		MainHudQueries.Dependencies.new(
			{
				"content": ContentStub.new(),
				"equipment": EquipmentStub.new(),
				"inventory": InventoryStub.new()
			}
		)
	)

	assert_eq(queries.inventory_text(), "Apple x2, Sword x1")
	assert_true(queries.inventory_details_text().contains("Apple x2: Crisp."))
	assert_eq(
		queries.inventory_actions_data(),
		[
			{"id": "use:item_apple", "item_id": "item_apple", "text": "Use Apple", "count": 2},
			{"id": "unequip:right_hand", "item_id": "item_sword", "text": "Unequip Sword"}
		]
	)
