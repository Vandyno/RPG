class_name RpgSystemsQuestRows
extends RefCounted

const RpgNavigationTextBuilder = preload("res://scripts/ui/text/rpg_navigation_text_builder.gd")
const SystemsTabState = preload("res://scripts/ui/systems/systems_tab_state.gd")
const RpgSystemsRowData = preload("res://scripts/ui/systems/rows/rpg_systems_row_data.gd")


static func category_labels() -> Array:
	return ["Active", "Routes", "Rewards"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	if category == "routes":
		return _quest_route_rows(state)
	if category == "rewards":
		return _quest_reward_rows(state)
	var tab := SystemsTabState.quests(state)
	var rows_data: Array[Dictionary] = []
	for quest in RpgSystemsRowData.array_field(tab.get("quests", [])):
		var text := String(quest)
		rows_data.append({
			"id": "quest_%d" % rows_data.size(),
			"title": RpgSystemsRowData.title_before_colon(text),
			"subtitle": RpgSystemsRowData.text_after_colon(text, "Active quest"),
			"meta": "Quest",
			"detail": _quest_detail_for_text(state, text)
		})
	for action in RpgSystemsRowData.array_field(tab.get("actions", [])):
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
	var tab := SystemsTabState.quests(state)
	var rows_data: Array[Dictionary] = []
	var directions := String(tab.get("directions", "none"))
	if not directions.is_empty() and directions != "none":
		for line in directions.split("\n", false):
			var stripped := line.strip_edges()
			if stripped.is_empty():
				continue
			rows_data.append({
				"id": "quest_route_%d" % rows_data.size(),
				"title": RpgSystemsRowData.title_before_colon(stripped),
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
	var tab := SystemsTabState.quests(state)
	var actions := RpgSystemsRowData.array_field(tab.get("actions", []))
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


static func _quest_detail_for_text(state: Dictionary, quest_text: String) -> String:
	var lines: Array[String] = [quest_text]
	var quest_tab := SystemsTabState.quests(state)
	var directions := String(quest_tab.get("directions", "none"))
	if not directions.is_empty() and directions != "none":
		lines.append("")
		lines.append(RpgNavigationTextBuilder.friendly_route_lines(directions))
	return "\n".join(lines)


static func _route_after_colon(value: String, fallback: String) -> String:
	var route := RpgSystemsRowData.text_after_colon(value, fallback)
	return RpgNavigationTextBuilder.friendly_navigation(route)
