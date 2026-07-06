class_name InventoryManager
extends Node

const PLAYER_OWNER_ID := "char_player"

var event_bus: EventBus
var content: ContentDatabase
var items: Dictionary = {}
var owner_items: Dictionary = {}


func setup(bus: EventBus, content_database: ContentDatabase = null) -> void:
	event_bus = bus
	content = content_database
	owner_items[PLAYER_OWNER_ID] = items


func add_item(item_id: String, count: int = 1) -> bool:
	return add_item_to_owner(PLAYER_OWNER_ID, item_id, count)


func remove_item(item_id: String, count: int = 1) -> bool:
	return remove_item_from_owner(PLAYER_OWNER_ID, item_id, count)


func has_item(item_id: String, count: int = 1) -> bool:
	return has_item_for_owner(PLAYER_OWNER_ID, item_id, count)


func get_count(item_id: String) -> int:
	return get_count_for_owner(PLAYER_OWNER_ID, item_id)


func add_item_to_owner(owner_id: String, item_id: String, count: int = 1) -> bool:
	var normalized_owner := _owner_id(owner_id)
	if item_id.is_empty() or count <= 0 or not _is_known_item(item_id):
		return false
	var owner_inventory := _items_for_owner(normalized_owner)
	var current_count := _count_from_value(owner_inventory.get(item_id, 0))
	var next_count := mini(current_count + count, _max_count_for_item(item_id))
	if next_count <= current_count:
		return false
	owner_inventory[item_id] = next_count
	_emit_owner_change(normalized_owner, item_id)
	return true


func remove_item_from_owner(owner_id: String, item_id: String, count: int = 1) -> bool:
	var normalized_owner := _owner_id(owner_id)
	if item_id.is_empty():
		return false
	if count <= 0:
		return true
	var owner_inventory := _items_for_owner(normalized_owner)
	var current := _count_from_value(owner_inventory.get(item_id, 0))
	if current < count:
		return false
	var next_count := current - count
	if next_count <= 0:
		owner_inventory.erase(item_id)
	else:
		owner_inventory[item_id] = next_count
	_emit_owner_change(normalized_owner, item_id)
	return true


func has_item_for_owner(owner_id: String, item_id: String, count: int = 1) -> bool:
	return get_count_for_owner(owner_id, item_id) >= count


func get_count_for_owner(owner_id: String, item_id: String) -> int:
	return _count_from_value(_items_for_owner_or_empty(_owner_id(owner_id)).get(item_id, 0))


func get_items_for_owner(owner_id: String) -> Dictionary:
	return _items_for_owner_or_empty(_owner_id(owner_id)).duplicate(true)


func has_inventory_for_owner(owner_id: String) -> bool:
	var normalized_owner := _owner_id(owner_id)
	if normalized_owner == PLAYER_OWNER_ID:
		return true
	return owner_items.has(normalized_owner) and owner_items[normalized_owner] is Dictionary


func transfer_item(
	from_owner_id: String, to_owner_id: String, item_id: String, count: int = 1
) -> bool:
	var from_owner := _owner_id(from_owner_id)
	var to_owner := _owner_id(to_owner_id)
	if item_id.is_empty() or count <= 0 or not has_item_for_owner(from_owner, item_id, count):
		return false
	if not _can_add_item(to_owner, item_id, count):
		return false
	if not remove_item_from_owner(from_owner, item_id, count):
		return false
	if add_item_to_owner(to_owner, item_id, count):
		return true
	add_item_to_owner(from_owner, item_id, count)
	return false


func can_add_item_to_owner(owner_id: String, item_id: String, count: int = 1) -> bool:
	return _can_add_item(owner_id, item_id, count)


func get_save_data() -> Dictionary:
	var list: Array[Dictionary] = []
	for item_id in items:
		var key := String(item_id)
		var count := get_count(key)
		if key.is_empty() or count <= 0:
			continue
		list.append({"item_id": key, "count": count})
	var owners: Array[Dictionary] = []
	for owner_id in owner_items:
		var normalized_owner := String(owner_id)
		if normalized_owner == PLAYER_OWNER_ID:
			continue
		var owner_list := _save_list_for_items(_items_for_owner(normalized_owner))
		if owner_list.is_empty():
			continue
		owners.append({"owner_id": normalized_owner, "items": owner_list})
	var data := {"items": list}
	if not owners.is_empty():
		data["owner_inventories"] = owners
	return data


func load_save_data(data: Dictionary) -> void:
	items.clear()
	owner_items.clear()
	owner_items[PLAYER_OWNER_ID] = items
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
	for owner_entry in _array_field(data.get("owner_inventories", [])):
		if not owner_entry is Dictionary:
			continue
		var owner_id := _owner_id(String(owner_entry.get("owner_id", "")))
		if owner_id == PLAYER_OWNER_ID:
			continue
		var owner_inventory := _items_for_owner(owner_id)
		for entry in _array_field(owner_entry.get("items", [])):
			if not entry is Dictionary:
				continue
			var item_id := String(entry.get("item_id", ""))
			var count_value: Variant = entry.get("count", 0)
			if (
				not item_id.is_empty()
				and _is_number(count_value)
				and int(count_value) > 0
				and _is_known_item(item_id)
			):
				owner_inventory[item_id] = mini(int(count_value), _max_count_for_item(item_id))


func _save_list_for_items(source: Dictionary) -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for item_id in source:
		var key := String(item_id)
		var count := _count_from_value(source.get(item_id, 0))
		if key.is_empty() or count <= 0:
			continue
		list.append({"item_id": key, "count": count})
	return list


func _items_for_owner(owner_id: String) -> Dictionary:
	var normalized_owner := _owner_id(owner_id)
	if normalized_owner == PLAYER_OWNER_ID:
		owner_items[PLAYER_OWNER_ID] = items
		return items
	if not owner_items.has(normalized_owner) or not owner_items[normalized_owner] is Dictionary:
		owner_items[normalized_owner] = {}
	return owner_items[normalized_owner]


func _items_for_owner_or_empty(owner_id: String) -> Dictionary:
	var normalized_owner := _owner_id(owner_id)
	if normalized_owner == PLAYER_OWNER_ID:
		return items
	var owner_inventory: Variant = owner_items.get(normalized_owner, {})
	return owner_inventory if owner_inventory is Dictionary else {}


func _owner_id(owner_id: String) -> String:
	return PLAYER_OWNER_ID if owner_id.is_empty() else owner_id


func _can_add_item(owner_id: String, item_id: String, count: int) -> bool:
	if item_id.is_empty() or count <= 0 or not _is_known_item(item_id):
		return false
	var current_count := get_count_for_owner(owner_id, item_id)
	return current_count + count <= _max_count_for_item(item_id)


func _emit_owner_change(owner_id: String, item_id: String) -> void:
	if event_bus and owner_id == PLAYER_OWNER_ID:
		event_bus.item_count_changed.emit(item_id, get_count(item_id))


func _is_known_item(item_id: String) -> bool:
	return not content or not content.get_item(item_id).is_empty()


func _max_count_for_item(item_id: String) -> int:
	if not content:
		return 2147483647
	var item: Dictionary = content.get_item(item_id)
	if item.is_empty():
		return 0
	if not bool(item.get("stackable", true)):
		var tags := _array_field(item.get("tags", []))
		if String(item.get("type", "")) == "quest_item" or tags.has("quest"):
			return 1
		return 2147483647
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
