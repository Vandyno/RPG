extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const InventoryManager = preload("res://scripts/managers/actors/inventory_manager.gd")

var content: ContentDatabase
var event_bus: EventBus
var inventory: InventoryManager
var changed_items: Array[String]


func before_each() -> void:
	content = ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	event_bus = EventBus.new()
	add_child_autofree(event_bus)
	changed_items = []
	event_bus.item_count_changed.connect(
		func(item_id: String, _count: int) -> void: changed_items.append(item_id)
	)
	inventory = InventoryManager.new()
	add_child_autofree(inventory)
	inventory.setup(event_bus, content)


func test_player_inventory_clamps_known_stack_sizes_and_emits_changes() -> void:
	assert_false(inventory.add_item("missing_item", 1))
	assert_true(inventory.add_item("item_gold_coin", 1200))
	assert_eq(inventory.get_count("item_gold_coin"), 999)
	assert_false(inventory.add_item("item_gold_coin", 1))
	assert_true(inventory.remove_item("item_gold_coin", 12))
	assert_eq(inventory.get_count("item_gold_coin"), 987)
	assert_eq(changed_items, ["item_gold_coin", "item_gold_coin"])


func test_owner_transfer_rolls_back_when_destination_cannot_accept() -> void:
	assert_true(inventory.add_item_to_owner("char_bandit", "item_old_toolbox", 1))
	assert_true(inventory.add_item("item_old_toolbox", 1))

	assert_false(
		inventory.transfer_item("char_bandit", InventoryManager.PLAYER_OWNER_ID, "item_old_toolbox", 1)
	)
	assert_eq(inventory.get_count_for_owner("char_bandit", "item_old_toolbox"), 1)
	assert_eq(inventory.get_count("item_old_toolbox"), 1)


func test_load_save_data_sanitizes_player_and_owner_inventories() -> void:
	inventory.load_save_data(
		{
			"items":
			[
				{"item_id": "missing_item", "count": 5},
				{"item_id": "item_gold_coin", "count": 1200},
				{"item_id": "item_river_mint", "count": "many"}
			],
			"owner_inventories":
			[
				{"owner_id": "", "items": [{"item_id": "item_gold_coin", "count": 1}]},
				{"owner_id": "char_bandit", "items": [{"item_id": "item_road_hatchet", "count": 2}]},
				{"owner_id": "char_bad", "items": "bad"}
			]
		}
	)

	assert_eq(inventory.get_count("item_gold_coin"), 999)
	assert_eq(inventory.get_count("item_river_mint"), 0)
	assert_eq(inventory.get_count_for_owner("char_bandit", "item_road_hatchet"), 2)
	assert_true(inventory.has_inventory_for_owner("char_bad"))
	assert_eq(inventory.get_items_for_owner("char_bad"), {})
	assert_eq(
		inventory.get_save_data(),
		{
			"items": [{"item_id": "item_gold_coin", "count": 999}],
			"owner_inventories":
			[
				{"owner_id": "char_bandit", "items": [{"item_id": "item_road_hatchet", "count": 2}]}
			]
		}
	)
