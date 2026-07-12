class_name ShopManager
extends Node

const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")

const CURRENCY_ITEM_ID := "item_gold_coin"

var event_bus: EventBus
var content: ContentDatabase
var inventory: InventoryManager
var equipment: EquipmentManager
var time: TimeManager
var schedule_manager


func setup(
	bus: EventBus,
	content_database: ContentDatabase,
	inventory_manager: InventoryManager,
	equipment_manager: EquipmentManager = null,
	time_manager: TimeManager = null
) -> void:
	event_bus = bus
	content = content_database
	inventory = inventory_manager
	equipment = equipment_manager
	time = time_manager


func set_schedule_manager(manager) -> void:
	schedule_manager = manager


func buy_item(shop_id: String, item_id: String) -> bool:
	var price := buy_price(shop_id, item_id)
	if (
		not is_shop_open(shop_id)
		or price <= 0
		or not inventory
		or not inventory.has_item(CURRENCY_ITEM_ID, price)
	):
		return false
	if not inventory.add_item(item_id, 1):
		return false
	if inventory.remove_item(CURRENCY_ITEM_ID, price):
		return true
	inventory.remove_item(item_id, 1)
	return false


func sell_item(shop_id: String, item_id: String) -> bool:
	var price := sell_price(shop_id, item_id)
	if not is_shop_open(shop_id):
		return false
	if price <= 0 or not inventory or not inventory.has_item(item_id, 1) or _is_equipped(item_id):
		return false
	if not inventory.remove_item(item_id, 1):
		return false
	if inventory.add_item(CURRENCY_ITEM_ID, price):
		return true
	inventory.add_item(item_id, 1)
	return false


func buy_result(shop_id: String, item_id: String) -> Dictionary:
	var item := _item(item_id)
	var price := buy_price(shop_id, item_id)
	if shop_id.is_empty() or item.is_empty() or not buy_item(shop_id, item_id):
		return {"ok": false, "message": "Could not buy that.", "refresh": "hud"}
	return {
		"ok": true,
		"message": "Bought %s. Spent %dg. Gold: %d." % [
			String(item.get("name", item_id)),
			price,
			inventory.get_count(CURRENCY_ITEM_ID)
		],
		"refresh": "nearby"
	}


func sell_result(shop_id: String, item_id: String) -> Dictionary:
	var item := _item(item_id)
	var price := sell_price(shop_id, item_id)
	if item.is_empty() or not sell_item(shop_id, item_id):
		return {"ok": false, "message": "Could not sell that.", "refresh": "hud"}
	return {
		"ok": true,
		"message": "Sold %s. Gained %dg. Gold: %d." % [
			String(item.get("name", item_id)),
			price,
			inventory.get_count(CURRENCY_ITEM_ID)
		],
		"refresh": "nearby"
	}


func buy_price(shop_id: String, item_id: String) -> int:
	for stock_entry in _shop_stock(shop_id):
		if String(stock_entry.get("item_id", "")) == item_id:
			return _positive_int_value(stock_entry.get("price", _item_value(item_id)), 0)
	return 0


func sell_price(shop_id: String, item_id: String) -> int:
	if not is_shop_open(shop_id):
		return 0
	return base_sell_price(item_id)


func base_sell_price(item_id: String) -> int:
	if item_id == CURRENCY_ITEM_ID or _is_equipped(item_id):
		return 0
	var item := _item(item_id)
	if item.is_empty() or bool(item.get("unsellable", false)):
		return 0
	if _array_field(item.get("tags", [])).has("quest"):
		return 0
	var value := _item_value(item_id)
	if value <= 0:
		return 0
	return maxi(1, int(floor(float(value) * 0.5)))


func get_shop_name(shop_id: String) -> String:
	var shop := _shop(shop_id)
	if shop.is_empty():
		return ""
	return String(shop.get("name", shop_id))


func get_shop_hours(shop_id: String) -> Dictionary:
	var shop := _shop(shop_id)
	if not shop.has("open_hour") or not shop.has("close_hour"):
		return {}
	return {
		"open_hour": int(shop.get("open_hour", 0)),
		"close_hour": int(shop.get("close_hour", 0))
	}


func get_stock_entries(shop_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var shop := _shop(shop_id)
	if shop.is_empty():
		return entries
	for stock_entry in _shop_stock(shop_id):
		var item_id := String(stock_entry.get("item_id", ""))
		var item := _item(item_id)
		var price := buy_price(shop_id, item_id)
		if item.is_empty() or price <= 0:
			continue
		entries.append(
			{
				"item_id": item_id,
				"name": String(item.get("name", item_id)),
				"price": price,
				"merchant_name": String(shop.get("name", shop_id))
			}
		)
	return entries


func get_sellable_entries(shop_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not is_shop_open(shop_id):
		return entries
	if not inventory:
		return entries
	var item_ids: Array[String] = []
	for item_id in inventory.items:
		item_ids.append(String(item_id))
	item_ids.sort()
	for item_id in item_ids:
		var price := sell_price(shop_id, item_id)
		var item := _item(item_id)
		if price <= 0 or item.is_empty():
			continue
		entries.append(
			{
				"item_id": item_id,
				"name": String(item.get("name", item_id)),
				"price": price
			}
		)
	return entries


func is_shop_open(shop_id: String) -> bool:
	var shop := _shop(shop_id)
	if shop.is_empty() or not shop.has("open_hour") or not shop.has("close_hour") or not time:
		return true
	var service_id := String(shop.get("service_id", shop_id))
	var open_minute := _hour_to_minute(shop.get("open_hour", 0))
	var close_minute := _hour_to_minute(shop.get("close_hour", 0))
	var current_minute: int = time.minute_of_day
	if open_minute == close_minute:
		return true
	if open_minute < close_minute:
		if not (current_minute >= open_minute and current_minute < close_minute):
			return false
	else:
		if not (current_minute >= open_minute or current_minute < close_minute):
			return false
	if shop.has("worker_npc_id") and schedule_manager and not schedule_manager.is_service_available(service_id):
		return false
	return true


func shop_unavailable_reason(shop_id: String) -> String:
	var shop := _shop(shop_id)
	if shop.is_empty():
		return "Shop does not exist."
	var service_id := String(shop.get("service_id", shop_id))
	if shop.has("worker_npc_id") and schedule_manager and not schedule_manager.is_service_available(service_id):
		return schedule_manager.service_unavailable_reason(service_id)
	if not is_shop_open_by_hours(shop_id):
		return "Shop is closed."
	return ""


func is_shop_open_by_hours(shop_id: String) -> bool:
	var shop := _shop(shop_id)
	if shop.is_empty() or not shop.has("open_hour") or not shop.has("close_hour") or not time:
		return true
	var open_minute := _hour_to_minute(shop.get("open_hour", 0))
	var close_minute := _hour_to_minute(shop.get("close_hour", 0))
	var current_minute: int = time.minute_of_day
	if open_minute == close_minute:
		return true
	if open_minute < close_minute:
		return current_minute >= open_minute and current_minute < close_minute
	return current_minute >= open_minute or current_minute < close_minute


func _shop(shop_id: String) -> Dictionary:
	if shop_id.is_empty() or not content:
		return {}
	return content.get_shop(shop_id)


func _shop_stock(shop_id: String) -> Array:
	return _array_field(_shop(shop_id).get("stock", []))


func _item(item_id: String) -> Dictionary:
	if item_id.is_empty() or not content:
		return {}
	return content.get_item(item_id)


func _item_value(item_id: String) -> int:
	return _non_negative_int_value(_item(item_id).get("value", 0), 0)


func _hour_to_minute(value: Variant) -> int:
	return clampi(_non_negative_int_value(value, 0), 0, 23) * 60


func _is_equipped(item_id: String) -> bool:
	if not equipment:
		return false
	for slot in EquipmentSlots.SLOTS:
		if equipment.get_equipped_item(slot) == item_id:
			return true
	return false


func _array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []


func _positive_int_value(value: Variant, fallback: int) -> int:
	if not _is_number(value):
		return maxi(0, fallback)
	return maxi(1, int(value))


func _non_negative_int_value(value: Variant, fallback: int) -> int:
	if not _is_number(value):
		return maxi(0, fallback)
	return maxi(0, int(value))


func _is_number(value: Variant) -> bool:
	return value is int or value is float
