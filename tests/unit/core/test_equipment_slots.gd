extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const EquipmentManager = preload("res://scripts/managers/equipment_manager.gd")
const InventoryManager = preload("res://scripts/managers/inventory_manager.gd")


func test_equipment_supports_full_character_slot_contract() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.items = {
		"ring_a": {"id": "ring_a", "name": "Ring A", "equipment_slot": "ring"},
		"ring_b": {"id": "ring_b", "name": "Ring B", "equipment_slot": "ring"},
		"helmet": {"id": "helmet", "name": "Helmet", "equipment_slot": "head"}
	}
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.setup(null, content)
	inventory.add_item("ring_a", 1)
	inventory.add_item("ring_b", 1)
	inventory.add_item("helmet", 1)
	var equipment := EquipmentManager.new()
	add_child_autofree(equipment)
	equipment.setup(null, content, inventory)

	assert_true(equipment.equip_item_to_slot("ring_a", "ring_2"))
	assert_true(equipment.equip_item("ring_b"))
	assert_true(equipment.equip_item_to_slot("helmet", "head"))
	assert_eq(equipment.get_equipped_item("ring_2"), "ring_a")
	assert_eq(equipment.get_equipped_item("ring_1"), "ring_b")
	assert_eq(equipment.get_equipped_item("head"), "helmet")
