class_name RpgSystemsTextBuilder
extends RefCounted

const RpgNavigationTextBuilder = preload("res://scripts/ui/text/rpg_navigation_text_builder.gd")
const SystemsTabState = preload("res://scripts/ui/systems/systems_tab_state.gd")


static func title(tab_id: String) -> String:
	return {
		"inventory": "Inventory",
		"spells": "Spells",
		"character": "Character",
		"quests": "Quests",
		"journal": "Journal",
		"trade": "Trade"
	}.get(tab_id, "Menu")


static func subtitle(tab_id: String) -> String:
	return {
		"inventory": "Gear, supplies, and valuables.",
		"spells": "Known magic and assigned abilities.",
		"character": "Training, health, equipment, and effects.",
		"quests": "Active work and nearby objectives.",
		"journal": "Time, reputation, and recent events.",
		"trade": "Buy and sell with the selected merchant."
	}.get(tab_id, "Briarwatch")


static func resource_text(state: Dictionary) -> String:
	var inventory_tab := SystemsTabState.inventory(state)
	var journal_tab := SystemsTabState.journal(state)
	var inventory := String(inventory_tab.get("summary", "empty"))
	var gold := _count_named_entry(inventory, "Gold Coin")
	var time := String(journal_tab.get("time", "Day 1, 08:00"))
	var carry := _carry_weight(_array_field(inventory_tab.get("items", [])))
	var capacity := maxf(1.0, float(state.get("carry_capacity", 90.0)))
	var mana := String(state.get("player_mana", "0/0"))
	return "Gold %d     MP %s     Carry %s/%s     %s" % [
		gold, mana, _format_weight(carry), _format_weight(capacity), _short_time(time)
	]


static func detail_text(state: Dictionary, tab_id: String) -> String:
	match tab_id:
		"inventory":
			var inventory_tab := SystemsTabState.inventory(state)
			return _first_non_empty(
				String(inventory_tab.get("details", "")),
				"Select an item to see details."
			)
		"spells":
			return "Drag known spells into Ability I, II, or III."
		"character":
			var character_tab := SystemsTabState.character(state)
			return _first_non_empty(
				String(character_tab.get("progression_details", "")),
				String(character_tab.get("progression", "Level 1"))
			)
		"quests":
			return _quest_detail_text(state)
		"journal":
			var journal_tab := SystemsTabState.journal(state)
			return _first_non_empty(String(journal_tab.get("factions", "")), "No reputation notes.")
		"trade":
			var trade_tab := SystemsTabState.trade(state)
			return _first_non_empty(String(trade_tab.get("summary", "")), "No trader selected.")
	return ""


static func character_text(state: Dictionary) -> String:
	var tab := SystemsTabState.character(state)
	var lines: Array[String] = []
	lines.append("Health %s" % String(tab.get("health", "unknown")))
	lines.append("Mana %s" % String(tab.get("mana", "unknown")))
	lines.append(String(tab.get("progression", "Level 1")))
	lines.append("")
	lines.append(String(tab.get("equipment", "Weapon: empty\nOffhand: empty\nBody: empty")))
	var statuses := String(tab.get("statuses", "none"))
	if statuses != "none":
		lines.append("")
		lines.append("Effects: %s" % statuses)
	return "\n".join(lines)


static func character_rows(state: Dictionary) -> Array[Dictionary]:
	var tab := SystemsTabState.character(state)
	var equipment := String(tab.get("equipment", "Weapon: empty\nOffhand: empty\nBody: empty"))
	var statuses := String(tab.get("statuses", "none"))
	var health := String(tab.get("health", "unknown"))
	var mana := String(tab.get("mana", "unknown"))
	return [
		{
			"title": "Vitals",
			"value": "Health %s\nMana %s" % [health, mana]
		},
		{
			"title": "Training",
			"value": String(tab.get("progression", "Level 1"))
		},
		{
			"title": "Equipment",
			"value": equipment
		},
		{
			"title": "Effects",
			"value": "None" if statuses == "none" else statuses
		}
	]


static func level_from_progression(text: String) -> int:
	var expression := RegEx.new()
	if expression.compile("Level\\s+(\\d+)") != OK:
		return 1
	var result := expression.search(text)
	if not result:
		return 1
	return maxi(1, int(result.get_string(1)))


static func _quest_detail_text(state: Dictionary) -> String:
	var tab := SystemsTabState.quests(state)
	var quests := _array_field(tab.get("quests", []))
	if quests.is_empty():
		return "No active quests."
	var lines: Array[String] = []
	for quest in quests:
		lines.append(String(quest))
	var directions := String(tab.get("directions", "none"))
	if directions != "none" and not directions.is_empty():
		lines.append("")
		lines.append(RpgNavigationTextBuilder.friendly_route_lines(directions))
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


static func _carry_weight(items: Array) -> float:
	var total := 0.0
	for item in items:
		if not item is Dictionary:
			continue
		total += maxf(0.0, float(item.get("weight", 0.0))) * maxi(0, int(item.get("count", 0)))
	return total


static func _format_weight(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return "%.1f" % value


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
