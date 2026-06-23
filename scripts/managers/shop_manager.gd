class_name ShopManager
extends Node

const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")

const CURRENCY_ITEM_ID := "item_gold_coin"

var event_bus
var content
var inventory
var equipment
var time


func setup(
	bus, content_database, inventory_manager, equipment_manager = null, time_manager = null
) -> void:
	event_bus = bus
	content = content_database
	inventory = inventory_manager
	equipment = equipment_manager
	time = time_manager


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


func sell_item(item_id: String, shop_id: String = "") -> bool:
	var price := sell_price(item_id)
	if not shop_id.is_empty() and not is_shop_open(shop_id):
		return false
	if price <= 0 or not inventory or not inventory.has_item(item_id, 1) or _is_equipped(item_id):
		return false
	if not inventory.remove_item(item_id, 1):
		return false
	if inventory.add_item(CURRENCY_ITEM_ID, price):
		return true
	inventory.add_item(item_id, 1)
	return false


func buy_price(shop_id: String, item_id: String) -> int:
	for stock_entry in _shop_stock(shop_id):
		if String(stock_entry.get("item_id", "")) == item_id:
			return _positive_int_value(stock_entry.get("price", _item_value(item_id)), 0)
	return 0


func sell_price(item_id: String) -> int:
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


func get_shop_summary(shop_id: String) -> String:
	var shop := _shop(shop_id)
	if shop.is_empty():
		return "No shop available."
	var lines: Array[String] = [String(shop.get("name", shop_id))]
	lines.append(_hours_text(shop_id))
	if not is_shop_open(shop_id):
		lines.append("Closed now.")
	lines.append("Gold: %d" % inventory.get_count(CURRENCY_ITEM_ID) if inventory else "Gold: 0")
	lines.append("")
	lines.append("Stock:")
	for stock_entry in _shop_stock(shop_id):
		var item_id := String(stock_entry.get("item_id", ""))
		var item := _item(item_id)
		lines.append("- %s: %dg" % [String(item.get("name", item_id)), buy_price(shop_id, item_id)])
	var sellable := get_sell_actions(shop_id)
	lines.append("")
	if sellable.is_empty():
		lines.append("Sell: none")
	else:
		lines.append("Sell:")
		for action in sellable:
			lines.append("- %s" % String(action.get("text", "")))
	return "\n".join(lines)


func get_buy_actions(shop_id: String) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if not is_shop_open(shop_id):
		return actions
	for stock_entry in _shop_stock(shop_id):
		var item_id := String(stock_entry.get("item_id", ""))
		var price := buy_price(shop_id, item_id)
		var item := _item(item_id)
		if item.is_empty() or price <= 0:
			continue
		actions.append(
			{
				"id": "buy:%s" % item_id,
				"text": "Buy %s (%dg)" % [String(item.get("name", item_id)), price]
			}
		)
	return actions


func get_sell_actions(shop_id: String = "") -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if not shop_id.is_empty() and not is_shop_open(shop_id):
		return actions
	if not inventory:
		return actions
	var item_ids: Array[String] = []
	for item_id in inventory.items:
		item_ids.append(String(item_id))
	item_ids.sort()
	for item_id in item_ids:
		var price := sell_price(item_id)
		var item := _item(item_id)
		if price <= 0 or item.is_empty():
			continue
		actions.append(
			{
				"id": "sell:%s" % item_id,
				"text": "Sell %s (+%dg)" % [String(item.get("name", item_id)), price]
			}
		)
	return actions


func is_shop_open(shop_id: String) -> bool:
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


func _hours_text(shop_id: String) -> String:
	var shop := _shop(shop_id)
	if not shop.has("open_hour") or not shop.has("close_hour"):
		return "Hours: always open"
	return (
		"Hours: %02d:00-%02d:00" % [int(shop.get("open_hour", 0)), int(shop.get("close_hour", 0))]
	)


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
