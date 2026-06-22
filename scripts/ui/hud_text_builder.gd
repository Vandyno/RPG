class_name HudTextBuilder
extends RefCounted


static func status_text(state: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Velcor  %s" % state.get("time", "Day 1, 08:00"))
	lines.append("Tile %s  %s" % [state.get("player_tile", ""), state.get("terrain", "unknown")])
	var inventory := String(state.get("inventory", "empty"))
	if inventory != "empty":
		lines.append("Inventory: %s" % inventory)
	var statuses := String(state.get("statuses", "none"))
	if statuses != "none":
		lines.append("Effects: %s" % statuses)
	var quests := _array_field(state.get("quests", []))
	if not quests.is_empty():
		lines.append("Quest: %s" % _quest_title_with_count(quests))
		var objective := _quest_objective(quests[0])
		if not objective.is_empty():
			lines.append("Goal: %s" % _ellipsized(objective, 48))
	var next_target := _first_quest_target_direction(state)
	if not next_target.is_empty():
		lines.append("Next: %s" % next_target)
	return "\n".join(lines)


static func prompt_text(state: Dictionary) -> String:
	var selected := String(state.get("nearby", "none"))
	if selected == "none":
		return "Explore"
	var action := String(state.get("primary_action", "Interact"))
	var detail := String(state.get("target_detail", ""))
	return (
		"%s\n%s" % [action, selected]
		if detail.is_empty()
		else "%s\n%s\n%s" % [action, selected, detail]
	)


static func message_text(message_log: Array[String], compact: bool = false) -> String:
	if message_log.is_empty():
		return "Ready."
	var line_count := 1 if compact else 3
	var text := "\n".join(message_log.slice(maxi(0, message_log.size() - line_count)))
	return _ellipsized(text, 42) if compact else text


static func debug_text(state: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Debug")
	lines.append("Move: WASD/Arrows or touch pad")
	lines.append("Interact: E/Enter/Button  Next: T  Systems: J  Save: F5  Load: F9  Debug: F3")
	lines.append("")
	lines.append("World: %s" % state.get("player_world", ""))
	lines.append("Health: %s" % state.get("player_health", "unknown"))
	lines.append(
		"Tile: %s  Chunk: %s" % [state.get("player_tile", ""), state.get("player_chunk", "")]
	)
	lines.append("Loaded chunks: %d" % _non_negative_int_field(state, "loaded_chunk_count", 0))
	lines.append("Progression: %s" % state.get("progression", "Level 1"))
	lines.append("Selected: %s" % state.get("nearby", "none"))
	lines.append("Nearby: %s" % state.get("nearby_all", "none"))
	lines.append("Flags: %s" % state.get("flags", "none"))
	lines.append("Locations: %s" % state.get("locations", "none"))
	lines.append("Factions:")
	lines.append(String(state.get("factions", "none")))
	return "\n".join(lines)


static func systems_text(
	state: Dictionary, active_tab: String, message_log: Array[String]
) -> String:
	match active_tab:
		"character":
			return _systems_character_text(state)
		"trade":
			return _systems_trade_text(state)
		"quests":
			return _systems_quests_text(state)
		"world":
			return _systems_world_text(state)
		"log":
			return _systems_log_text(message_log)
		_:
			return _systems_inventory_text(state)


static func _systems_inventory_text(state: Dictionary) -> String:
	var lines: Array[String] = ["Inventory"]
	lines.append("Health: %s" % state.get("player_health", "unknown"))
	lines.append("Inventory: %s" % state.get("inventory", "empty"))
	lines.append("Equipped:")
	lines.append(String(state.get("equipment", "Weapon: empty\nOffhand: empty\nBody: empty")))
	var inventory_details := String(state.get("inventory_details", ""))
	if not inventory_details.is_empty():
		lines.append("")
		lines.append("Items:")
		lines.append(inventory_details)
	else:
		lines.append("")
		lines.append("Items: none")
	return "\n".join(lines)


static func _systems_character_text(state: Dictionary) -> String:
	var lines: Array[String] = ["Character"]
	lines.append("Health: %s" % state.get("player_health", "unknown"))
	lines.append("Progression:")
	lines.append(String(state.get("progression_details", state.get("progression", "Level 1"))))
	lines.append("")
	lines.append(String(state.get("status_details", "Active effects: none")))
	lines.append("")
	lines.append("Equipment:")
	lines.append(String(state.get("equipment", "Weapon: empty\nOffhand: empty\nBody: empty")))
	return "\n".join(lines)


static func _systems_trade_text(state: Dictionary) -> String:
	return "Trade\n%s" % String(state.get("trade", "No trader selected."))


static func _systems_quests_text(state: Dictionary) -> String:
	var lines: Array[String] = ["Quests"]
	var quests := _array_field(state.get("quests", []))
	if quests.is_empty():
		lines.append("Quest: none")
	else:
		lines.append("Quest:")
		for quest in quests:
			lines.append("- %s" % String(quest))
	var quest_directions := String(state.get("quest_directions", "none"))
	if quest_directions != "none":
		lines.append("")
		lines.append("Quest Targets:")
		lines.append(quest_directions)
	lines.append("")
	lines.append("Target: %s" % state.get("nearby", "none"))
	var detail := String(state.get("target_detail", ""))
	if not detail.is_empty():
		lines.append("Detail: %s" % detail)
	lines.append("Nearby: %s" % state.get("nearby_all", "none"))
	lines.append("Directions:")
	lines.append(String(state.get("navigation", "none")))
	return "\n".join(lines)


static func _systems_world_text(state: Dictionary) -> String:
	var lines: Array[String] = ["World"]
	lines.append(String(state.get("time_details", state.get("time", ""))))
	lines.append("Position: %s" % state.get("player_world", ""))
	lines.append(
		"Tile: %s  Chunk: %s" % [state.get("player_tile", ""), state.get("player_chunk", "")]
	)
	lines.append("Terrain: %s" % state.get("terrain", "unknown"))
	lines.append("Loaded chunks: %d" % _non_negative_int_field(state, "loaded_chunk_count", 0))
	lines.append("Progression: %s" % state.get("progression", "Level 1"))
	lines.append("")
	lines.append("Directions:")
	lines.append(String(state.get("navigation", "none")))
	lines.append("")
	lines.append("Flags: %s" % state.get("flags", "none"))
	lines.append("Locations: %s" % state.get("locations", "none"))
	var location_details := String(state.get("location_details", ""))
	if not location_details.is_empty() and location_details != "none":
		lines.append("Location Details:")
		lines.append(location_details)
	lines.append("Factions:")
	lines.append(String(state.get("factions", "none")))
	return "\n".join(lines)


static func _systems_log_text(message_log: Array[String]) -> String:
	var lines: Array[String] = ["Log"]
	if message_log.is_empty():
		lines.append("Recent: none")
	else:
		for message in message_log:
			lines.append("- %s" % message)
	return "\n".join(lines)


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []


static func _quest_title(value: Variant) -> String:
	var text := String(value)
	var separator := text.find(":")
	if separator <= 0:
		return text
	return text.substr(0, separator)


static func _quest_title_with_count(quests: Array) -> String:
	var title := _quest_title(quests[0])
	if quests.size() <= 1:
		return title
	return "%s (+%d)" % [title, quests.size() - 1]


static func _quest_objective(value: Variant) -> String:
	var text := String(value)
	var separator := text.find(":")
	if separator < 0 or separator + 1 >= text.length():
		return ""
	return text.substr(separator + 1).strip_edges()


static func _first_quest_target_direction(state: Dictionary) -> String:
	var directions := String(state.get("quest_directions", "none"))
	if directions.is_empty() or directions == "none":
		return ""
	var direction_lines := directions.split("\n", false)
	if direction_lines.is_empty():
		return ""
	var first_line := direction_lines[0]
	var separator := first_line.find(":")
	if separator < 0:
		return _with_extra_count(first_line, direction_lines.size())
	return _with_extra_count(first_line.substr(separator + 1).strip_edges(), direction_lines.size())


static func _with_extra_count(text: String, count: int) -> String:
	if count <= 1:
		return text
	return "%s (+%d)" % [text, count - 1]


static func _ellipsized(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	if max_chars <= 1:
		return value.substr(0, max_chars)
	return "%s..." % value.substr(0, max_chars - 3)


static func _non_negative_int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	var value: Variant = source.get(field_id, fallback)
	if not _is_number(value):
		return maxi(0, fallback)
	return maxi(0, int(value))


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
