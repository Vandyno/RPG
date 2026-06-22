class_name RpgSystemsTextBuilder
extends RefCounted


static func title(tab_id: String) -> String:
	return {
		"inventory": "Inventory",
		"character": "Character",
		"quests": "Quests",
		"map": "Map",
		"journal": "Journal",
		"trade": "Trade"
	}.get(tab_id, "Menu")


static func subtitle(tab_id: String) -> String:
	return {
		"inventory": "Gear, supplies, and valuables.",
		"character": "Training, health, equipment, and effects.",
		"quests": "Active work and nearby objectives.",
		"map": "Known places, routes, and nearby leads.",
		"journal": "Time, reputation, and recent events.",
		"trade": "Buy and sell with the selected merchant."
	}.get(tab_id, "Briarwatch")


static func resource_text(state: Dictionary) -> String:
	var inventory := String(state.get("inventory", "empty"))
	var gold := _count_named_entry(inventory, "Gold Coin")
	var time := String(state.get("time", "Day 1, 08:00"))
	return "Gold %d     %s" % [gold, _short_time(time)]


static func detail_text(state: Dictionary, tab_id: String) -> String:
	match tab_id:
		"inventory":
			return _first_non_empty(
				String(state.get("inventory_details", "")),
				"No carried item details yet."
			)
		"character":
			return _first_non_empty(
				String(state.get("progression_details", "")),
				String(state.get("progression", "Level 1"))
			)
		"quests":
			return _quest_detail_text(state)
		"map":
			return _first_non_empty(
				String(state.get("location_details", "")),
				String(state.get("locations", "No known places."))
			)
		"journal":
			return _first_non_empty(String(state.get("factions", "")), "No reputation notes.")
		"trade":
			return _first_non_empty(String(state.get("trade", "")), "No trader selected.")
	return ""


static func character_text(state: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append(String(state.get("player_health", "Health unknown")))
	lines.append(String(state.get("progression", "Level 1")))
	lines.append("")
	lines.append(String(state.get("equipment", "Weapon: empty\nOffhand: empty\nBody: empty")))
	var statuses := String(state.get("statuses", "none"))
	if statuses != "none":
		lines.append("")
		lines.append("Effects: %s" % statuses)
	return "\n".join(lines)


static func level_from_progression(text: String) -> int:
	var expression := RegEx.new()
	if expression.compile("Level\\s+(\\d+)") != OK:
		return 1
	var result := expression.search(text)
	if not result:
		return 1
	return maxi(1, int(result.get_string(1)))


static func _quest_detail_text(state: Dictionary) -> String:
	var quests := _array_field(state.get("quests", []))
	if quests.is_empty():
		return "No active quests."
	var lines: Array[String] = []
	for quest in quests:
		lines.append(String(quest))
	var directions := String(state.get("quest_directions", "none"))
	if directions != "none" and not directions.is_empty():
		lines.append("")
		lines.append(directions)
	return "\n".join(lines)


static func _first_non_empty(value: String, fallback: String) -> String:
	var stripped := value.strip_edges()
	if stripped.is_empty() or stripped == "none":
		return fallback
	return stripped


static func _short_time(time: String) -> String:
	var phase_start := time.find(" (")
	if phase_start >= 0:
		time = time.substr(0, phase_start)
	return time.replace("Day ", "D")


static func _count_named_entry(summary: String, item_name: String) -> int:
	for raw_part in summary.split(",", false):
		var part := raw_part.strip_edges()
		if not part.begins_with(item_name):
			continue
		var marker := part.rfind("x")
		if marker >= 0 and marker + 1 < part.length():
			return maxi(0, int(part.substr(marker + 1)))
	return 0


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
