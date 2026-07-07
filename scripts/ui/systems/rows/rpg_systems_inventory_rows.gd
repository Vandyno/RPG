class_name RpgSystemsInventoryRows
extends RefCounted

const SystemsTabState = preload("res://scripts/ui/systems/systems_tab_state.gd")
const RpgSystemsRowData = preload("res://scripts/ui/systems/rows/rpg_systems_row_data.gd")

const ARMOUR_EQUIPMENT_SLOTS := [
	"left_hand",
	"chest",
	"head",
	"legs",
	"gloves",
	"boots",
	"back",
	"necklace",
	"ring_1",
	"ring_2"
]


static func category_labels() -> Array:
	return ["All", "Weapons", "Armour", "Ingredients", "Misc", "Quest"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	var tab := SystemsTabState.inventory(state)
	var transfer: Dictionary = tab.get("transfer", {})
	if bool(transfer.get("open", false)):
		return _transfer_rows(tab, category)
	var typed_rows := _typed_inventory_rows(tab, category)
	if not typed_rows.is_empty():
		return typed_rows
	var details_by_name := _detail_lines_by_name(
		String(tab.get("details", ""))
	)
	var rows_data: Array[Dictionary] = []
	for entry in _summary_entries(String(tab.get("summary", "empty"))):
		var title := String(entry.get("title", "Item"))
		var detail := String(details_by_name.get(title, "No item details available."))
		rows_data.append({
			"id": "inventory_%d" % rows_data.size(),
			"title": title,
			"subtitle": String(entry.get("meta", "Carried item")),
			"meta": "Inventory",
			"detail": "%s\n\n%s" % [String(entry.get("summary", title)), detail]
		})
	return rows_data


static func _transfer_rows(tab: Dictionary, category: String) -> Array[Dictionary]:
	var rows_data: Array[Dictionary] = []
	var transfer: Dictionary = tab.get("transfer", {})
	var target_value: Variant = transfer.get("target", {})
	var target: Dictionary = target_value if target_value is Dictionary else {}
	var target_name := String(target.get("name", "Container"))
	_append_transfer_side_rows(
		rows_data,
		RpgSystemsRowData.array_field(transfer.get("player_items", [])),
		"player",
		"Player Pack",
		"put",
		category
	)
	_append_transfer_side_rows(
		rows_data,
		RpgSystemsRowData.array_field(transfer.get("target_items", [])),
		"target",
		target_name,
		"take",
		category
	)
	if rows_data.is_empty():
		rows_data.append({
			"id": "transfer_empty",
			"title": "No Transfer Items",
			"subtitle": "Both inventories are empty.",
			"meta": "Transfer",
			"detail": "No items available to move."
		})
	return rows_data


static func _append_transfer_side_rows(
	rows_data: Array[Dictionary],
	items: Array,
	side: String,
	side_name: String,
	action: String,
	category: String
) -> void:
	for item in items:
		if not item is Dictionary:
			continue
		var item_category := _inventory_category(item)
		if not _transfer_category_matches(category, side, item_category):
			continue
		var item_id := String(item.get("item_id", ""))
		var name := String(item.get("name", item_id))
		var count := maxi(0, int(item.get("count", 0)))
		if item_id.is_empty() or name.is_empty() or count <= 0:
			continue
		var action_text := "Take" if action == "take" else "Put"
		var description := String(item.get("description", "No item details available."))
		var value := maxi(0, int(item.get("value", 0)))
		var weight := maxf(0.0, float(item.get("weight", 0.0)))
		rows_data.append({
			"id": "transfer_%s_%s" % [side, item_id],
			"item_id": item_id,
			"action_id": "%s:%s" % [action, item_id],
			"title": name,
			"subtitle": "%s - Count %d - %s" % [side_name, count, action_text],
			"meta": action_text,
			"detail": "%s\n%s x%d\n\n%s" % [
				side_name,
				name,
				count,
				_inventory_item_detail(name, count, description, value, weight)
			]
		})


static func _transfer_category_matches(
	category: String, side: String, item_category: String
) -> bool:
	if category.is_empty() or category == "all":
		return true
	if category == "player" or category == "target":
		return category == side
	return category == item_category


static func _typed_inventory_rows(tab: Dictionary, category: String) -> Array[Dictionary]:
	var rows_data: Array[Dictionary] = []
	for item in RpgSystemsRowData.array_field(tab.get("items", [])):
		if not item is Dictionary:
			continue
		var item_category := _inventory_category(item)
		if category != "all" and category != item_category:
			continue
		var name := String(item.get("name", item.get("item_id", "Item")))
		var count := maxi(0, int(item.get("count", 0)))
		if name.is_empty() or count <= 0:
			continue
		var action := _action_for_item_id(
			RpgSystemsRowData.array_field(tab.get("actions", [])),
			String(item.get("item_id", ""))
		)
		var action_id := String(action.get("id", ""))
		var action_text := String(action.get("text", ""))
		var item_type := _inventory_category_label(item_category)
		var description := String(item.get("description", "No item details available."))
		var count_text := "Count %d" % count
		var value := maxi(0, int(item.get("value", 0)))
		var weight := maxf(0.0, float(item.get("weight", 0.0)))
		var meta_parts: Array[String] = [count_text]
		if not action_text.is_empty():
			meta_parts.append(action_text)
		if weight > 0.0:
			meta_parts.append("%s wt" % RpgSystemsRowData.format_weight(weight * count))
		if value > 0:
			meta_parts.append("%dg" % value)
		rows_data.append({
			"id": "inventory_%s" % String(item.get("item_id", rows_data.size())),
			"item_id": String(item.get("item_id", "")),
			"action_id": action_id,
			"equipment_slot": String(item.get("equipment_slot", "")),
			"title": name,
			"subtitle": " - ".join(meta_parts),
			"meta": item_type,
			"detail": _inventory_item_detail(name, count, description, value, weight)
		})
	return rows_data


static func _inventory_category(item: Dictionary) -> String:
	var item_type := String(item.get("type", "")).to_lower()
	var slot := String(item.get("equipment_slot", "")).to_lower()
	var tags := RpgSystemsRowData.lower_array(item.get("tags", []))
	if item_type == "weapon" or slot == "right_hand" or tags.has("weapon"):
		return "weapons"
	if ["armor", "armour", "shield"].has(item_type) or ARMOUR_EQUIPMENT_SLOTS.has(slot):
		return "armour"
	if tags.has("armor") or tags.has("armour") or tags.has("shield"):
		return "armour"
	if item_type == "ingredient" or tags.has("ingredient"):
		return "ingredients"
	if item_type == "quest_item" or tags.has("quest"):
		return "quest"
	return "misc"


static func _inventory_category_label(category: String) -> String:
	return {
		"weapons": "Weapons",
		"armour": "Armour",
		"ingredients": "Ingredients",
		"quest": "Quest",
		"misc": "Misc"
	}.get(category, "Inventory")


static func _inventory_item_detail(
	name: String, count: int, description: String, value: int, weight: float
) -> String:
	var lines: Array[String] = ["%s x%d" % [name, count]]
	if weight > 0.0:
		lines.append("Weight: %s" % RpgSystemsRowData.format_weight(weight * count))
	if value > 0:
		lines.append("Value: %dg" % value)
	lines.append("")
	lines.append(description)
	return "\n".join(lines)


static func _action_for_item_id(actions: Array, item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}
	for action in actions:
		if not action is Dictionary:
			continue
		if String(action.get("item_id", "")) == item_id:
			return action
	return {}


static func _summary_entries(summary: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if summary.is_empty() or summary == "empty" or summary == "none":
		return entries
	for part in summary.split(",", false):
		var stripped := part.strip_edges()
		if stripped.is_empty():
			continue
		var title := stripped
		var meta := "Carried item"
		var marker := stripped.rfind(" x")
		if marker > 0:
			title = stripped.substr(0, marker)
			meta = "Count %s" % stripped.substr(marker + 2)
		entries.append({"title": title, "summary": stripped, "meta": meta})
	return entries


static func _detail_lines_by_name(details: String) -> Dictionary:
	var result := {}
	for raw_line in details.split("\n", false):
		var line := raw_line.strip_edges()
		if line.is_empty():
			continue
		var separator := line.find(":")
		if separator <= 0:
			continue
		var key := line.substr(0, separator).strip_edges()
		result[key] = line.substr(separator + 1).strip_edges()
		var count_marker := key.rfind(" x")
		if count_marker > 0:
			result[key.substr(0, count_marker).strip_edges()] = result[key]
	return result
