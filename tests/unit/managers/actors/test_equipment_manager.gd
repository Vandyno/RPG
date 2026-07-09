extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const EquipmentManager = preload("res://scripts/managers/actors/equipment_manager.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const InventoryManager = preload("res://scripts/managers/actors/inventory_manager.gd")


func test_equip_item_routes_to_supported_slot_swaps_mainhand_and_emits_changes() -> void:
	var systems := _systems(["item_road_hatchet", "item_training_sword", "item_traveler_buckler"])
	var equipment: EquipmentManager = systems["equipment"]
	var bus: EventBus = systems["bus"]
	var changes: Array[Dictionary] = []
	bus.equipment_changed.connect(func(equipped: Dictionary) -> void: changes.append(equipped))

	assert_true(equipment.equip_item("item_road_hatchet"))
	assert_true(equipment.equip_item("item_training_sword"))
	assert_true(equipment.equip_item("item_traveler_buckler"))

	assert_eq(equipment.get_equipped_item("right_hand"), "item_training_sword")
	assert_eq(equipment.get_equipped_item("left_hand"), "item_traveler_buckler")
	assert_eq(equipment.last_mainhand_weapon_id, "item_road_hatchet")
	assert_eq(changes.size(), 3)
	assert_eq(changes[-1]["left_hand"], "item_traveler_buckler")


func test_equip_item_to_slot_rejects_missing_unowned_wrong_slot_and_duplicate_items() -> void:
	var systems := _systems(["item_road_hatchet"])
	var equipment: EquipmentManager = systems["equipment"]

	assert_false(equipment.equip_item_to_slot("item_missing", "right_hand"))
	assert_false(equipment.equip_item_to_slot("item_training_sword", "right_hand"))
	assert_false(equipment.equip_item_to_slot("item_road_hatchet", "left_hand"))
	assert_true(equipment.equip_item_to_slot("item_road_hatchet", "right_hand"))
	assert_false(equipment.equip_item_to_slot("item_road_hatchet", "right_hand"))


func test_equip_last_mainhand_weapon_uses_remembered_or_fallback_weapon() -> void:
	var systems := _systems(["item_road_hatchet", "item_training_sword"])
	var equipment: EquipmentManager = systems["equipment"]

	assert_true(equipment.equip_item("item_road_hatchet"))
	assert_true(equipment.equip_last_mainhand_weapon())
	assert_eq(equipment.get_equipped_item("right_hand"), "item_training_sword")
	assert_eq(equipment.last_mainhand_weapon_id, "item_road_hatchet")
	equipment.last_mainhand_weapon_id = "item_training_sword"
	assert_true(equipment.equip_last_mainhand_weapon())
	assert_eq(equipment.get_equipped_item("right_hand"), "item_road_hatchet")


func test_summary_damage_guard_and_save_data_use_only_valid_equipped_items() -> void:
	var systems := _systems(["item_road_hatchet", "item_traveler_buckler"])
	var equipment: EquipmentManager = systems["equipment"]

	assert_true(equipment.equip_item("item_road_hatchet"))
	assert_true(equipment.equip_item("item_traveler_buckler"))

	assert_eq(equipment.get_player_damage_bonus(), 4)
	assert_eq(equipment.guarded_counter_multiplier(0.5), 0.25)
	assert_true(equipment.get_summary().contains("Weapon: Road Hatchet"))
	assert_eq(
		equipment.get_save_data(),
		{
			"equipped":
			{
				"right_hand": "item_road_hatchet",
				"left_hand": "item_traveler_buckler",
			}
		}
	)


func test_load_save_data_accepts_legacy_slots_and_ignores_invalid_items() -> void:
	var systems := _systems(["item_road_hatchet", "item_traveler_buckler"])
	var equipment: EquipmentManager = systems["equipment"]

	equipment.load_save_data(
		{
			"equipped":
			{
				"weapon": "item_road_hatchet",
				"offhand": "item_traveler_buckler",
				"body": "item_gold_coin",
				"bad_slot": "item_road_hatchet",
			},
			"last_mainhand_weapon": "item_training_sword"
		}
	)

	assert_eq(equipment.get_equipped_item("right_hand"), "item_road_hatchet")
	assert_eq(equipment.get_equipped_item("left_hand"), "item_traveler_buckler")
	assert_eq(equipment.get_equipped_item("chest"), "")
	assert_eq(equipment.last_mainhand_weapon_id, "")


func test_item_count_removed_unequips_item_and_clears_last_mainhand_weapon() -> void:
	var systems := _systems(["item_road_hatchet", "item_training_sword"])
	var equipment: EquipmentManager = systems["equipment"]
	var inventory: InventoryManager = systems["inventory"]
	var bus: EventBus = systems["bus"]
	var changes: Array[Dictionary] = []
	bus.equipment_changed.connect(func(equipped: Dictionary) -> void: changes.append(equipped))
	assert_true(equipment.equip_item("item_road_hatchet"))
	assert_true(equipment.equip_item("item_training_sword"))
	assert_eq(equipment.last_mainhand_weapon_id, "item_road_hatchet")

	inventory.remove_item("item_training_sword", 1)

	assert_eq(equipment.get_equipped_item("right_hand"), "")
	assert_eq(equipment.last_mainhand_weapon_id, "")
	assert_true(changes[-1].is_empty())

	inventory.remove_item("item_road_hatchet", 1)
	assert_eq(equipment.last_mainhand_weapon_id, "")


func _systems(item_ids: Array[String]) -> Dictionary:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.setup(bus, content)
	for item_id in item_ids:
		inventory.add_item(item_id, 1)
	var equipment := EquipmentManager.new()
	add_child_autofree(equipment)
	equipment.setup(bus, content, inventory)
	return {"bus": bus, "content": content, "inventory": inventory, "equipment": equipment}
