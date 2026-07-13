class_name HudTextBuilder
extends RefCounted

const TextUtil = preload("res://scripts/core/text_util.gd")


static func status_text(state: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("%s  %s" % [_primary_location_name(state), state.get("time", "Day 1, 08:00")])
	var statuses := String(state.get("statuses", "none"))
	if statuses != "none":
		lines.append("Effects: %s" % statuses)
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
	return TextUtil.ellipsized(text, 42) if compact else text


static func debug_text(state: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("Debug")
	lines.append("Move: WASD/Arrows or touch pad")
	lines.append("Interact: E/Enter/Button  Next: T  Menu: J  Save: F5  Load: F9  Debug: F3")
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
	lines.append("Stealth: %s" % state.get("stealth_state", "unknown"))
	lines.append("Legal: %s, bounty %dg" % [state.get("legal_area", "unknown"), int(state.get("bounty", 0))])
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
		"journal", "log":
			return _systems_journal_text(state, message_log)
		"inventory":
			return _systems_inventory_text(state)
		_:
			return ""


static func _systems_inventory_text(state: Dictionary) -> String:
	var lines := _screen_header("Inventory", "Gear, supplies, and valuables.")
	lines.append("Health: %s" % state.get("player_health", "unknown"))
	lines.append("Carried: %s" % state.get("inventory", "empty"))
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
	var lines := _screen_header("Character", "Health, training, effects, and equipment.")
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
	var lines := _screen_header("Trade", "Buy and sell with the selected merchant.")
	lines.append(String(state.get("trade", "No trader selected.")))
	return "\n".join(lines)


static func _systems_quests_text(state: Dictionary) -> String:
	var lines := _screen_header("Quests", "Active work and nearby objectives.")
	var quests := _array_field(state.get("quests", []))
	if quests.is_empty():
		lines.append("No active quests.")
	else:
		lines.append("Active:")
		for quest in quests:
			lines.append("- %s" % String(quest))
	var quest_directions := String(state.get("quest_directions", "none"))
	if quest_directions != "none":
		lines.append("")
		lines.append("Routes:")
		lines.append(quest_directions)
	return "\n".join(lines)


static func _systems_journal_text(state: Dictionary, message_log: Array[String]) -> String:
	var lines := _screen_header("Journal", "Time, reputation, and recent events.")
	lines.append(String(state.get("time_details", state.get("time", ""))))
	var factions := String(state.get("factions", "none"))
	if factions != "none":
		lines.append("")
		lines.append("Reputation:")
		lines.append(factions)
	lines.append("")
	lines.append("Recent Events:")
	if message_log.is_empty():
		lines.append("none")
	else:
		for message in message_log:
			lines.append("- %s" % message)
	return "\n".join(lines)


static func _screen_header(title: String, subtitle: String) -> Array[String]:
	return [title, subtitle, ""]


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []


static func _primary_location_name(state: Dictionary) -> String:
	var locations := String(state.get("locations", ""))
	if locations.is_empty() or locations == "none":
		return "Velcor"
	var names := locations.split(",", false)
	if names.is_empty():
		return locations
	return names[0].strip_edges()


static func _non_negative_int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	var value: Variant = source.get(field_id, fallback)
	if not _is_number(value):
		return maxi(0, fallback)
	return maxi(0, int(value))


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
