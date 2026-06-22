class_name RpgStatusTextBuilder
extends RefCounted


static func lines(state: Dictionary, progression_text: String) -> Array[String]:
	var result: Array[String] = ["Adventurer", progression_text]
	var statuses := String(state.get("statuses", "none"))
	if statuses != "none":
		result.append("Effects: %s" % statuses)
	var quests := _array_field(state.get("quests", []))
	if not quests.is_empty():
		result.append("Quest: %s" % _quest_title_with_count(quests))
		var objective := _quest_objective_with_count(quests)
		if not objective.is_empty():
			result.append(objective)
		var target := _first_quest_target_with_count(state, quests)
		if not target.is_empty() and not objective.contains(target):
			result.append(target)
	return result


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []


static func _quest_title(value: Variant) -> String:
	var text := String(value)
	var separator := text.find(":")
	if separator <= 0:
		return text
	return text.substr(0, separator).strip_edges()


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


static func _quest_objective_with_count(quests: Array) -> String:
	var objective := _quest_objective(quests[0])
	if objective.is_empty() or quests.size() <= 1:
		return objective
	return "%s (+%d)" % [objective, quests.size() - 1]


static func _first_quest_target_with_count(state: Dictionary, quests: Array) -> String:
	var directions := String(state.get("quest_directions", "none"))
	if directions.is_empty() or directions == "none":
		return ""
	var first_line := directions.split("\n", false)[0]
	var separator := first_line.find(":")
	if separator < 0 or separator + 1 >= first_line.length():
		return ""
	var route := first_line.substr(separator + 1).strip_edges()
	var parts := route.split(" ", false)
	if parts.size() <= 2:
		return ""
	var target := " ".join(parts.slice(2))
	if quests.size() <= 1:
		return target
	return "%s (+%d)" % [target, quests.size() - 1]
