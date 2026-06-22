class_name InventoryManager
extends Node

var event_bus
var content
var items: Dictionary = {}


func setup(bus, content_database = null) -> void:
	event_bus = bus
	content = content_database


func add_item(item_id: String, count: int = 1) -> bool:
	if item_id.is_empty() or count <= 0 or not _is_known_item(item_id):
		return false
	var current_count := get_count(item_id)
	var next_count := mini(current_count + count, _max_count_for_item(item_id))
	if next_count <= current_count:
		return false
	items[item_id] = next_count
	if event_bus:
		event_bus.item_count_changed.emit(item_id, get_count(item_id))
	return true


func remove_item(item_id: String, count: int = 1) -> bool:
	if item_id.is_empty():
		return false
	if count <= 0:
		return true
	var current := get_count(item_id)
	if current < count:
		return false
	var next_count := current - count
	if next_count <= 0:
		items.erase(item_id)
	else:
		items[item_id] = next_count
	if event_bus:
		event_bus.item_count_changed.emit(item_id, get_count(item_id))
	return true


func has_item(item_id: String, count: int = 1) -> bool:
	return get_count(item_id) >= count


func get_count(item_id: String) -> int:
	return _count_from_value(items.get(item_id, 0))


func get_save_data() -> Dictionary:
	var list: Array[Dictionary] = []
	for item_id in items:
		var key := String(item_id)
		var count := get_count(key)
		if key.is_empty() or count <= 0:
			continue
		list.append({"item_id": key, "count": count})
	return {"items": list}


func load_save_data(data: Dictionary) -> void:
	items.clear()
	for entry in _array_field(data.get("items", [])):
		if entry is Dictionary:
			var item_id := String(entry.get("item_id", ""))
			var count_value: Variant = entry.get("count", 0)
			if (
				not item_id.is_empty()
				and _is_number(count_value)
				and int(count_value) > 0
				and _is_known_item(item_id)
			):
				items[item_id] = mini(int(count_value), _max_count_for_item(item_id))


func _is_known_item(item_id: String) -> bool:
	return not content or not content.get_item(item_id).is_empty()


func _max_count_for_item(item_id: String) -> int:
	if not content:
		return 2147483647
	var item: Dictionary = content.get_item(item_id)
	if item.is_empty():
		return 0
	if not bool(item.get("stackable", true)):
		return 1
	return _positive_int_value(item.get("max_stack", 1), 1)


func _count_from_value(value: Variant) -> int:
	if not _is_number(value):
		return 0
	return maxi(0, int(value))


func _positive_int_value(value: Variant, fallback: int) -> int:
	if not _is_number(value):
		return maxi(1, fallback)
	return maxi(1, int(value))


func _array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []


func _is_number(value: Variant) -> bool:
	return value is int or value is float
