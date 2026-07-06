class_name RpgSystemsRowBuilder
extends RefCounted

const RpgNavigationTextBuilder = preload("res://scripts/ui/rpg_navigation_text_builder.gd")
const RpgSystemsInventoryRows = preload("res://scripts/ui/rpg_systems_inventory_rows.gd")
const RpgSystemsSpellRows = preload("res://scripts/ui/rpg_systems_spell_rows.gd")
const RpgSystemsCharacterRows = preload("res://scripts/ui/rpg_systems_character_rows.gd")
const RpgSystemsQuestRows = preload("res://scripts/ui/rpg_systems_quest_rows.gd")
const RpgSystemsJournalRows = preload("res://scripts/ui/rpg_systems_journal_rows.gd")
const RpgSystemsTradeRows = preload("res://scripts/ui/rpg_systems_trade_rows.gd")


static func rows(
	state: Dictionary, tab_id: String, message_log: Array[String], category: String = "all"
) -> Array[Dictionary]:
	match tab_id:
		"spells":
			return RpgSystemsSpellRows.rows(state, category)
		"character":
			return RpgSystemsCharacterRows.rows(state, category)
		"quests":
			return RpgSystemsQuestRows.rows(state, category)
		"journal":
			return RpgSystemsJournalRows.rows(state, message_log, category)
		"trade":
			return RpgSystemsTradeRows.rows(state, category)
		_:
			return RpgSystemsInventoryRows.rows(state, category)


static func category_labels(tab_id: String) -> Array[String]:
	var labels: Array = _category_labels_for_tab(tab_id)
	var result: Array[String] = []
	for label in labels:
		result.append(String(label))
	return result


static func _category_labels_for_tab(tab_id: String) -> Array:
	match tab_id:
		"inventory":
			return RpgSystemsInventoryRows.category_labels()
		"spells":
			return RpgSystemsSpellRows.category_labels()
		"character":
			return RpgSystemsCharacterRows.category_labels()
		"quests":
			return RpgSystemsQuestRows.category_labels()
		"journal":
			return RpgSystemsJournalRows.category_labels()
		"trade":
			return RpgSystemsTradeRows.category_labels()
		_:
			return ["Overview"]


static func clear_non_button_children(container: Node) -> void:
	for index in range(container.get_child_count() - 1, -1, -1):
		var child := container.get_child(index)
		if child is Button:
			continue
		container.remove_child(child)
		child.free()


static func w(label: String, fallback: float, compact: bool) -> float:
	if compact:
		return fallback
	var widths := {
		"All": 52,
		"Weapons": 72,
		"Armour": 72,
		"Ingredients": 88,
		"Misc": 58,
		"Quest": 58
	}
	return float(widths.get(label, int(fallback)))


static func button_text(row: Dictionary) -> String:
	var title := String(row.get("title", "Entry"))
	var subtitle := String(row.get("subtitle", ""))
	var meta := String(row.get("meta", ""))
	if subtitle.is_empty() and meta.is_empty():
		return title
	if subtitle.is_empty():
		return "%s\n%s" % [title, meta]
	if meta.is_empty():
		return "%s\n%s" % [title, subtitle]
	return "%s\n%s - %s" % [title, meta, subtitle]


static func selected_row(rows_data: Array[Dictionary], selected_row_id: String) -> Dictionary:
	for row in rows_data:
		if String(row.get("id", "")) == selected_row_id:
			return row
	return rows_data[0] if not rows_data.is_empty() else {}


static func has_id(rows_data: Array[Dictionary], row_id: String) -> bool:
	if row_id.is_empty():
		return false
	for row in rows_data:
		if String(row.get("id", "")) == row_id:
			return true
	return false


static func hidden_text(rows_data: Array[Dictionary]) -> String:
	var lines: Array[String] = []
	for row in rows_data:
		lines.append(String(row.get("title", "")))
		var subtitle := String(row.get("subtitle", ""))
		if not subtitle.is_empty():
			lines.append(subtitle)
	return "\n".join(lines)


static func _inventory_rows(state: Dictionary, category: String) -> Array[Dictionary]:
	if bool(state.get("transfer_open", false)):
		return _transfer_rows(state, category)
	var typed_rows := _typed_inventory_rows(state, category)
	if not typed_rows.is_empty():
		return typed_rows
	var details_by_name := _detail_lines_by_name(String(state.get("inventory_details", "")))
	var rows_data: Array[Dictionary] = []
	for entry in _summary_entries(String(state.get("inventory", "empty"))):
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


static func _transfer_rows(state: Dictionary, category: String) -> Array[Dictionary]:
	var rows_data: Array[Dictionary] = []
	var target_value: Variant = state.get("transfer_target", {})
	var target: Dictionary = target_value if target_value is Dictionary else {}
	var target_name := String(target.get("name", "Container"))
	_append_transfer_side_rows(
		rows_data, _array_field(state.get("transfer_player_items", [])),
		"player", "Player Pack", "put", category
	)
	_append_transfer_side_rows(
		rows_data, _array_field(state.get("transfer_target_items", [])),
		"target", target_name, "take", category
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


static func _typed_inventory_rows(state: Dictionary, category: String) -> Array[Dictionary]:
	var rows_data: Array[Dictionary] = []
	for item in _array_field(state.get("inventory_items", [])):
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
			_array_field(state.get("inventory_actions", [])), String(item.get("item_id", ""))
		)
		var action_id := String(action.get("id", _inventory_action_id_for_item(item)))
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
			meta_parts.append("%s wt" % _format_weight(weight * count))
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
	var tags := _lower_array(item.get("tags", []))
	if item_type == "weapon" or slot == "weapon" or tags.has("weapon"):
		return "weapons"
	if ["armor", "armour", "shield"].has(item_type) or ["offhand", "body"].has(slot):
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
		lines.append("Weight: %s" % _format_weight(weight * count))
	if value > 0:
		lines.append("Value: %dg" % value)
	lines.append("")
	lines.append(description)
	return "\n".join(lines)


static func _spell_rows(state: Dictionary, category: String) -> Array[Dictionary]:
	var rows_data: Array[Dictionary] = []
	for spell in _array_field(state.get("spells", [])):
		if not spell is Dictionary:
			continue
		var school := String(spell.get("school", "Utility"))
		if category != "all" and category != school.to_lower():
			continue
		var name := String(spell.get("name", "Spell"))
		var spell_id := String(spell.get("spell_id", ""))
		var assigned := String(spell.get("assigned_label", ""))
		var assignment := "Unassigned" if assigned.is_empty() else "Assigned: %s" % assigned
		var mana := int(spell.get("mana_cost", 0))
		var drain := float(spell.get("mana_drain_per_second", mana))
		rows_data.append({
			"id": "spell_%s" % spell_id,
			"spell_id": spell_id,
			"title": name,
			"subtitle": "%s school - %s" % [school, assignment],
			"meta": "%s MP/s" % _format_float(drain),
			"detail": _spell_detail(spell)
		})
	if rows_data.is_empty():
		rows_data.append({
			"id": "spells_empty_%s" % category,
			"title": "No Spells",
			"subtitle": "No known magic here.",
			"meta": "Spells",
			"detail": "No spells available."
		})
	return rows_data


static func _spell_detail(spell: Dictionary) -> String:
	var assigned := String(spell.get("assigned_label", ""))
	var drain := float(spell.get("mana_drain_per_second", spell.get("mana_cost", 0)))
	return "\n".join([
		String(spell.get("name", "Spell")),
		"School: %s" % String(spell.get("school", "Utility")),
		"Mana cost/drain: %s per second" % _format_float(drain),
		"Range: %s" % String(spell.get("range", "")),
		"Behavior: %s" % String(spell.get("behavior", "")),
		"Assigned slot: %s" % ("None" if assigned.is_empty() else assigned)
	])


static func _character_rows(state: Dictionary) -> Array[Dictionary]:
	var health := String(state.get("player_health", "Health unknown"))
	var mana := String(state.get("player_mana", "Mana unknown"))
	var progression := String(state.get("progression", "Level 1"))
	var equipment := String(state.get("equipment", "Weapon: empty\nOffhand: empty\nBody: empty"))
	var statuses := String(state.get("statuses", "none"))
	var rows_data: Array[Dictionary] = [
		{
			"id": "character_health",
			"title": "Vitals",
			"subtitle": "Health %s - Mana %s" % [health, mana],
			"meta": "Vitals",
			"detail": "Vitals\nCurrent Health: %s\nCurrent Mana: %s\nCondition: Stable" % [
				health, mana
			]
		},
		{
			"id": "character_progression",
			"title": "Training",
			"subtitle": progression,
			"meta": "Progression",
			"detail": _first_non_empty(
				String(state.get("progression_details", "")),
				progression
			)
		},
		{
			"id": "character_equipment",
			"title": "Equipment",
			"subtitle": _first_line(equipment),
			"meta": "Gear",
			"detail": "Equipped Gear\n%s\n\nDrag gear onto body slots to equip." % equipment
		},
		{
			"id": "character_effects",
			"title": "Active Effects",
			"subtitle": "None" if statuses == "none" else statuses,
			"meta": "Status",
			"detail": _first_non_empty(
				String(state.get("status_details", "")),
				"No active effects."
			)
		}
	]
	var actions := _array_field(state.get("progression_actions", []))
	if not actions.is_empty() and actions[0] is Dictionary:
		rows_data[1]["title"] = String(actions[0].get("text", "Training"))
		rows_data[1]["action_id"] = String(actions[0].get("id", ""))
	return rows_data


static func _quest_rows(state: Dictionary, category: String) -> Array[Dictionary]:
	if category == "routes":
		return _quest_route_rows(state)
	if category == "rewards":
		return _quest_reward_rows(state)
	var rows_data: Array[Dictionary] = []
	for quest in _array_field(state.get("quests", [])):
		var text := String(quest)
		rows_data.append({
			"id": "quest_%d" % rows_data.size(),
			"title": _title_before_colon(text),
			"subtitle": _text_after_colon(text, "Active quest"),
			"meta": "Quest",
			"detail": _quest_detail_for_text(state, text)
		})
	for action in _array_field(state.get("quest_target_actions", [])):
		if not action is Dictionary:
			continue
		var text := String(action.get("text", ""))
		if text.is_empty():
			continue
		rows_data.append({
			"id": "quest_action_%d" % rows_data.size(),
			"action_id": String(action.get("id", "")),
			"title": text,
			"subtitle": "Set active target",
			"meta": "Route",
			"detail": text
		})
	return rows_data


static func _quest_route_rows(state: Dictionary) -> Array[Dictionary]:
	var rows_data: Array[Dictionary] = []
	var directions := String(state.get("quest_directions", "none"))
	if not directions.is_empty() and directions != "none":
		for line in directions.split("\n", false):
			var stripped := line.strip_edges()
			if stripped.is_empty():
				continue
			rows_data.append({
				"id": "quest_route_%d" % rows_data.size(),
				"title": _title_before_colon(stripped),
				"subtitle": _route_after_colon(stripped, "Route"),
				"meta": "Route",
				"detail": RpgNavigationTextBuilder.friendly_route_line(stripped)
			})
	if rows_data.is_empty():
		rows_data.append({
			"id": "quest_routes_empty",
			"title": "No Routes",
			"subtitle": "No active quest target selected.",
			"meta": "Route",
			"detail": "No quest routes available."
		})
	return rows_data


static func _quest_reward_rows(state: Dictionary) -> Array[Dictionary]:
	var actions := _array_field(state.get("quest_target_actions", []))
	var rows_data: Array[Dictionary] = []
	for action in actions:
		if not action is Dictionary:
			continue
		var text := String(action.get("text", "Quest Reward"))
		rows_data.append({
			"id": "quest_reward_%d" % rows_data.size(),
			"action_id": String(action.get("id", "")),
			"title": text,
			"subtitle": "Quest action",
			"meta": "Reward",
			"detail": text
		})
	if rows_data.is_empty():
		rows_data.append({
			"id": "quest_rewards_empty",
			"title": "No Rewards Ready",
			"subtitle": "Finish objectives to reveal rewards.",
			"meta": "Reward",
			"detail": "No quest rewards are ready."
		})
	return rows_data


static func _journal_rows(state: Dictionary, message_log: Array[String]) -> Array[Dictionary]:
	var recent := "none"
	if not message_log.is_empty():
		recent = "\n".join(message_log.slice(maxi(0, message_log.size() - 6)))
	return [
		{
			"id": "journal_events",
			"title": "Recent Events",
			"subtitle": _first_line(recent),
			"meta": "Log",
			"detail": recent
		},
		{
			"id": "journal_time",
			"title": "Time",
			"subtitle": String(state.get("time", "Day 1, 08:00")),
			"meta": "Journal",
			"detail": String(state.get("time_details", state.get("time", "")))
		},
		{
			"id": "journal_wait",
			"action_id": "wait:1",
			"title": "Wait 1h",
			"subtitle": "Pass one hour.",
			"meta": "Time",
			"detail": "Wait for one hour."
		},
		{
			"id": "journal_reputation",
			"title": "Reputation",
			"subtitle": String(state.get("factions", "none")),
			"meta": "Factions",
			"detail": String(state.get("factions", "none"))
		},
		{
			"id": "journal_save",
			"action_id": "save:game",
			"title": "Save Game",
			"subtitle": "Write current progress.",
			"meta": "System",
			"detail": "Save current progress."
		},
		{
			"id": "journal_load",
			"action_id": "load:game",
			"title": "Load Game",
			"subtitle": "Restore saved progress.",
			"meta": "System",
			"detail": "Load saved progress."
		}
	]


static func _trade_rows(state: Dictionary, category: String) -> Array[Dictionary]:
	var rows_data: Array[Dictionary] = []
	var trade_text := String(state.get("trade", "No trader selected."))
	var lines := _non_empty_lines(trade_text)
	if not lines.is_empty() and not lines[0].contains(":") and not lines[0].begins_with("-"):
		var merchant_name := lines[0]
		var closed := false
		var sell_text := ""
		var in_sell_section := false
		for index in range(1, lines.size()):
			var line := lines[index]
			if line == "Closed now.":
				closed = true
			elif line.begins_with("Sell:"):
				sell_text = _text_after_colon(line, "none").strip_edges()
				in_sell_section = true
			elif line.begins_with("- "):
				if in_sell_section:
					continue
				if closed:
					continue
				var stock_text := line.substr(2).strip_edges()
				var item_name := _title_before_colon(stock_text)
				var price := _text_after_colon(stock_text, "").strip_edges()
				var action_id := _action_id_for_text(
					_array_field(state.get("trade_actions", [])), "Buy %s" % item_name
				)
				rows_data.append({
					"id": "trade_stock_%d" % rows_data.size(),
					"action_id": action_id,
					"title": item_name,
					"subtitle": "Buy %s from %s" % [item_name, merchant_name],
					"meta": price,
					"detail": _trade_item_detail(item_name, merchant_name, price, true)
				})
		if sell_text == "none":
			rows_data.append({
				"id": "trade_sell_empty",
				"title": "Nothing to Sell",
				"subtitle": "No sellable goods in your pack.",
				"meta": "Sell",
				"detail": "No sellable items in your pack."
			})
		for action in _array_field(state.get("trade_actions", [])):
			if not action is Dictionary:
				continue
			var text := String(action.get("text", ""))
			if not text.begins_with("Sell "):
				continue
			rows_data.append({
				"id": "trade_sell_%d" % rows_data.size(),
				"action_id": String(action.get("id", "")),
				"title": text.trim_prefix("Sell "),
				"subtitle": "%s from pack" % text,
				"meta": "Sell",
				"detail": "%s\n\nTap this row to sell." % text
			})
		if not rows_data.is_empty():
			return _category_filtered_rows(rows_data, category)
	for line in lines:
		rows_data.append({
			"id": "trade_%d" % rows_data.size(),
			"title": _title_before_colon(line),
			"subtitle": _text_after_colon(line, "Trade"),
			"meta": "Trade",
			"detail": line
		})
	if rows_data.is_empty():
		rows_data.append({
			"id": "trade_empty",
			"title": "No Trader Selected",
			"subtitle": "Talk to a merchant or use a shop.",
			"meta": "Trade",
			"detail": "No trader selected."
		})
	return rows_data


static func _category_filtered_rows(
	rows_data: Array[Dictionary], category: String
) -> Array[Dictionary]:
	var passthrough := ["all", "overview", "active", "known"]
	if category.is_empty() or passthrough.has(category):
		return rows_data
	var filtered: Array[Dictionary] = []
	for row in rows_data:
		var row_text := "%s %s %s %s" % [
			String(row.get("id", "")),
			String(row.get("title", "")),
			String(row.get("subtitle", "")),
			String(row.get("meta", ""))
		]
		if _row_matches_category(row_text.to_lower(), category):
			filtered.append(row)
	if not filtered.is_empty():
		return filtered
	return [_empty_category_row(category)]


static func _row_matches_category(row_text: String, category: String) -> bool:
	match category:
		"training":
			return row_text.contains("training") or row_text.contains("progression")
		"gear":
			return row_text.contains("gear") or row_text.contains("equipment")
		"effects":
			return row_text.contains("effect") or row_text.contains("status")
		"factions":
			return row_text.contains("faction") or row_text.contains("reputation")
		"time":
			return row_text.contains("time") or row_text.contains("wait") or row_text.contains("day")
		"recent":
			return (
				row_text.contains("recent")
				or row_text.contains("log")
				or row_text.contains("wait")
				or row_text.contains("save")
				or row_text.contains("load")
			)
		"system":
			return (
				row_text.contains("system")
				or row_text.contains("save")
				or row_text.contains("load")
			)
		"stock":
			return (
				row_text.contains("trade_stock")
				or row_text.contains("buy ")
				or row_text.contains("available")
			)
		"buy":
			return (
				row_text.contains("trade_stock")
				or row_text.contains("buy ")
				or row_text.contains("available")
			)
		"sell":
			return row_text.contains("sell")
	return row_text.contains(category)


static func _empty_category_row(category: String) -> Dictionary:
	var label := category.capitalize()
	return {
		"id": "systems_empty_%s" % category,
		"title": "No %s" % label,
		"subtitle": "Nothing in this section.",
		"meta": label,
		"detail": "No %s entries available." % label.to_lower()
	}


static func _trade_item_detail(
	item_name: String, merchant_name: String, price: String, buying: bool
) -> String:
	var verb := "Buy" if buying else "Sell"
	return "\n".join([
		item_name,
		"%s offer" % verb,
		"Price: %s" % price,
		"Merchant: %s" % merchant_name,
		"",
		"Tap this row to %s." % verb.to_lower()
	])


static func _inventory_action_id_for_item(item: Dictionary) -> String:
	var item_id := String(item.get("item_id", ""))
	if item_id.is_empty():
		return ""
	var slot := String(item.get("equipment_slot", ""))
	if not slot.is_empty():
		return "equip:%s" % item_id
	if String(item.get("type", "")).to_lower() == "consumable":
		return "use:%s" % item_id
	return ""


static func _action_id_for_text(actions: Array, prefix: String) -> String:
	for action in actions:
		if not action is Dictionary:
			continue
		if String(action.get("text", "")).begins_with(prefix):
			return String(action.get("id", ""))
	return ""


static func _action_for_item_id(actions: Array, item_id: String) -> Dictionary:
	if item_id.is_empty():
		return {}
	for action in actions:
		if not action is Dictionary:
			continue
		var action_id := String(action.get("id", ""))
		if action_id.ends_with(":%s" % item_id):
			return action
	return {}


static func _non_empty_lines(value: String) -> Array[String]:
	var result: Array[String] = []
	for raw_line in value.split("\n", false):
		var line := raw_line.strip_edges()
		if not line.is_empty():
			result.append(line)
	return result


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


static func _quest_detail_for_text(state: Dictionary, quest_text: String) -> String:
	var lines: Array[String] = [quest_text]
	var directions := String(state.get("quest_directions", "none"))
	if not directions.is_empty() and directions != "none":
		lines.append("")
		lines.append(RpgNavigationTextBuilder.friendly_route_lines(directions))
	return "\n".join(lines)


static func _comma_entries(value: String) -> Array[String]:
	var entries: Array[String] = []
	if value.is_empty() or value == "none":
		return entries
	for part in value.split(",", false):
		var stripped := part.strip_edges()
		if not stripped.is_empty():
			entries.append(stripped)
	return entries


static func _title_before_colon(value: String) -> String:
	var separator := value.find(":")
	if separator <= 0:
		return value
	return value.substr(0, separator).strip_edges()


static func _text_after_colon(value: String, fallback: String) -> String:
	var separator := value.find(":")
	if separator < 0 or separator + 1 >= value.length():
		return fallback
	return value.substr(separator + 1).strip_edges()


static func _route_after_colon(value: String, fallback: String) -> String:
	var route := _text_after_colon(value, fallback)
	return RpgNavigationTextBuilder.friendly_navigation(route)


static func _first_line(value: String) -> String:
	var lines := value.split("\n", false)
	if lines.is_empty():
		return value
	return lines[0].strip_edges()


static func _first_non_empty(value: String, fallback: String) -> String:
	var stripped := value.strip_edges()
	if stripped.is_empty() or stripped == "none":
		return fallback
	return stripped


static func _format_weight(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.1f" % value


static func _format_float(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.1f" % value


static func _lower_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	for entry in _array_field(value):
		result.append(String(entry).to_lower())
	return result


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
