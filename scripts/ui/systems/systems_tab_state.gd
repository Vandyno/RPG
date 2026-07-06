class_name SystemsTabState
extends RefCounted

const TABS_KEY := "system_tabs"


static func inventory(state: Dictionary) -> Dictionary:
	return _tab_with_fallback(state, "inventory", {
		"summary": state.get("inventory", "empty"),
		"items": state.get("inventory_items", []),
		"details": state.get("inventory_details", ""),
		"actions": state.get("inventory_actions", []),
		"transfer": {
			"open": state.get("transfer_open", false),
			"target": state.get("transfer_target", {}),
			"player_items": state.get("transfer_player_items", []),
			"target_items": state.get("transfer_target_items", [])
		}
	})


static func character(state: Dictionary) -> Dictionary:
	return _tab_with_fallback(state, "character", {
		"health": state.get("player_health", "Health unknown"),
		"mana": state.get("player_mana", "Mana unknown"),
		"progression": state.get("progression", "Level 1"),
		"progression_details": state.get("progression_details", ""),
		"equipment": state.get("equipment", "Weapon: empty\nOffhand: empty\nBody: empty"),
		"statuses": state.get("statuses", "none"),
		"status_details": state.get("status_details", ""),
		"actions": state.get("progression_actions", [])
	})


static func trade(state: Dictionary) -> Dictionary:
	return _tab_with_fallback(state, "trade", {
		"summary": state.get("trade", "No trader selected."),
		"actions": state.get("trade_actions", [])
	})


static func quests(state: Dictionary) -> Dictionary:
	return _tab_with_fallback(state, "quests", {
		"quests": state.get("quests", []),
		"directions": state.get("quest_directions", "none"),
		"actions": state.get("quest_target_actions", [])
	})


static func journal(state: Dictionary) -> Dictionary:
	return _tab_with_fallback(state, "journal", {
		"time": state.get("time", "Day 1, 08:00"),
		"factions": state.get("factions", ""),
		"locations": state.get("locations", ""),
		"location_details": state.get("location_details", ""),
		"actions": state.get("time_actions", [])
	})


static func actions_for_tab(state: Dictionary, tab_id: String) -> Array:
	match tab_id:
		"inventory":
			return _array_field(inventory(state).get("actions", []))
		"character":
			return _array_field(character(state).get("actions", []))
		"trade":
			return _array_field(trade(state).get("actions", []))
		"quests":
			return _array_field(quests(state).get("actions", []))
		"journal", "log":
			return _array_field(journal(state).get("actions", []))
		_:
			return []


static func _tab_with_fallback(
	state: Dictionary, tab_id: String, fallback: Dictionary
) -> Dictionary:
	var tabs_value: Variant = state.get(TABS_KEY, {})
	if tabs_value is Dictionary:
		var tab_value: Variant = (tabs_value as Dictionary).get(tab_id, {})
		if tab_value is Dictionary:
			var tab: Dictionary = tab_value
			return tab if not tab.is_empty() else fallback
	return fallback


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
