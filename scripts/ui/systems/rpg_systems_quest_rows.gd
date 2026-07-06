class_name RpgSystemsQuestRows
extends RefCounted

const RpgNavigationTextBuilder = preload("res://scripts/ui/text/rpg_navigation_text_builder.gd")


static func category_labels() -> Array:
	return ["Active", "Routes", "Rewards"]


static func rows(state: Dictionary, category: String) -> Array[Dictionary]:
	if category == "routes":
		return _quest_route_rows(state)
	if category == "rewards":
		return _quest_reward_rows(state)
	var rows_data: Array[Dictionary] = []
	for quest in RpgSystemsRowBuilder.array_field(state.get("quests", [])):
		var text := String(quest)
		rows_data.append({
			"id": "quest_%d" % rows_data.size(),
			"title": RpgSystemsRowBuilder.title_before_colon(text),
			"subtitle": RpgSystemsRowBuilder.text_after_colon(text, "Active quest"),
			"meta": "Quest",
			"detail": RpgSystemsRowBuilder.quest_detail_for_text(state, text)
		})
	for action in RpgSystemsRowBuilder.array_field(state.get("quest_target_actions", [])):
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
				"title": RpgSystemsRowBuilder.title_before_colon(stripped),
				"subtitle": RpgSystemsRowBuilder.route_after_colon(stripped, "Route"),
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
	var actions := RpgSystemsRowBuilder.array_field(state.get("quest_target_actions", []))
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
