extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const EquipmentManager = preload("res://scripts/managers/actors/equipment_manager.gd")
const InventoryManager = preload("res://scripts/managers/actors/inventory_manager.gd")
const MainHudQueries = preload("res://scripts/main/ui/main_hud_queries.gd")
const ShopManager = preload("res://scripts/managers/content/shop_manager.gd")
const TimeManager = preload("res://scripts/managers/content/time_manager.gd")


func test_shop_buys_and_sells_with_gold_and_item_caps() -> void:
	var systems := _make_systems()
	var inventory: InventoryManager = systems["inventory"]
	var shops: ShopManager = systems["shops"]

	inventory.add_item("item_gold_coin", 25)

	assert_true(shops.buy_item("shop_crossroads_peddler", "item_roadside_draught"))
	assert_eq(inventory.get_count("item_gold_coin"), 17)
	assert_eq(inventory.get_count("item_roadside_draught"), 1)

	assert_true(shops.sell_item("shop_crossroads_peddler", "item_roadside_draught"))
	assert_eq(inventory.get_count("item_gold_coin"), 23)
	assert_false(inventory.has_item("item_roadside_draught"))

	assert_false(shops.buy_item("shop_crossroads_peddler", "missing_item"))
	assert_false(shops.buy_item("missing_shop", "item_roadside_draught"))
	assert_false(shops.sell_item("shop_crossroads_peddler", "item_gold_coin"))
	assert_false(shops.sell_item("shop_crossroads_peddler", "item_old_toolbox"))


func test_shop_blocks_selling_equipped_items_and_reports_actions() -> void:
	var systems := _make_systems()
	var inventory: InventoryManager = systems["inventory"]
	var equipment: EquipmentManager = systems["equipment"]
	var shops: ShopManager = systems["shops"]

	inventory.add_item("item_gold_coin", 25)
	inventory.add_item("item_road_hatchet", 1)
	assert_true(equipment.equip_item("item_road_hatchet"))

	assert_eq(shops.sell_price("shop_crossroads_peddler", "item_road_hatchet"), 0)
	assert_false(shops.sell_item("shop_crossroads_peddler", "item_road_hatchet"))
	assert_true(inventory.has_item("item_road_hatchet"))

	assert_true(equipment.unequip_slot("right_hand"))
	assert_eq(shops.sell_price("shop_crossroads_peddler", "item_road_hatchet"), 9)
	assert_eq(shops.get_shop_name("shop_crossroads_peddler"), "Crossroads Peddler")
	assert_eq(shops.get_shop_hours("shop_crossroads_peddler"), {"open_hour": 8, "close_hour": 18})
	assert_eq(
		shops.get_stock_entries("shop_crossroads_peddler")[0],
		{
			"item_id": "item_roadside_draught",
			"name": "Roadside Draught",
			"price": 8,
			"merchant_name": "Crossroads Peddler"
		}
	)
	assert_eq(shops.get_sellable_entries("shop_crossroads_peddler")[0]["item_id"], "item_road_hatchet")


func test_shop_hours_gate_buy_sell_actions() -> void:
	var systems := _make_systems()
	var inventory: InventoryManager = systems["inventory"]
	var shops: ShopManager = systems["shops"]
	var time: TimeManager = systems["time"]

	inventory.add_item("item_gold_coin", 25)
	inventory.add_item("item_road_hatchet", 1)

	assert_true(shops.is_shop_open("shop_crossroads_peddler"))
	assert_true(shops.buy_item("shop_crossroads_peddler", "item_roadside_draught"))
	assert_false(shops.get_stock_entries("shop_crossroads_peddler").is_empty())
	assert_false(shops.get_sellable_entries("shop_crossroads_peddler").is_empty())

	assert_true(time.advance_hours(12))
	assert_false(shops.is_shop_open("shop_crossroads_peddler"))
	assert_false(shops.buy_item("shop_crossroads_peddler", "item_roadside_draught"))
	assert_false(shops.sell_item("shop_crossroads_peddler", "item_road_hatchet"))
	assert_false(shops.get_stock_entries("shop_crossroads_peddler").is_empty())
	assert_true(shops.get_sellable_entries("shop_crossroads_peddler").is_empty())


func test_hud_queries_build_shop_presentation_rows_and_actions() -> void:
	var systems := _make_systems()
	var inventory: InventoryManager = systems["inventory"]
	var shops: ShopManager = systems["shops"]
	var queries := MainHudQueries.new()
	queries.setup(
		MainHudQueries.Dependencies.new(
			{
				"content": systems["content"],
				"equipment": systems["equipment"],
				"inventory": inventory,
				"shops": shops
			}
		)
	)

	inventory.add_item("item_gold_coin", 25)
	inventory.add_item("item_road_hatchet", 1)

	assert_true(queries.trade_text("shop_crossroads_peddler").contains("Roadside Draught: 8g"))
	assert_true(queries.trade_text("shop_crossroads_peddler").contains("Sell Road Hatchet"))
	assert_eq(
		queries.trade_actions_data("shop_crossroads_peddler")[0],
		{
			"id": "buy:item_roadside_draught",
			"item_id": "item_roadside_draught",
			"text": "Buy Roadside Draught (8g)"
		}
	)
	assert_eq(
		queries.trade_stock_rows_data("shop_crossroads_peddler")[0],
		{
			"item_id": "item_roadside_draught",
			"name": "Roadside Draught",
			"price": 8,
			"action_id": "buy:item_roadside_draught",
			"available": true,
			"merchant_name": "Crossroads Peddler"
		}
	)


func _make_systems() -> Dictionary:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.setup(bus, content)
	var equipment := EquipmentManager.new()
	add_child_autofree(equipment)
	equipment.setup(bus, content, inventory)
	var time := TimeManager.new()
	add_child_autofree(time)
	time.setup(bus)
	var shops := ShopManager.new()
	add_child_autofree(shops)
	shops.setup(bus, content, inventory, equipment, time)
	return {
		"content": content,
		"inventory": inventory,
		"equipment": equipment,
		"shops": shops,
		"time": time
	}
