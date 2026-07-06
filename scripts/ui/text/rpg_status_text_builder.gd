class_name RpgStatusTextBuilder
extends RefCounted


static func lines(_state: Dictionary, progression_text: String, compact := false) -> Array[String]:
	if compact:
		return _compact_lines(progression_text)
	var result: Array[String] = ["Adventurer", progression_text]
	var statuses := String(_state.get("statuses", "none"))
	if statuses != "none":
		result.append("Effects: %s" % statuses)
	return result


static func _compact_lines(progression_text: String) -> Array[String]:
	var parts := progression_text.split(" ", false)
	if parts.size() < 4:
		return ["Adventurer", progression_text.replace("Level", "Lv")]
	var result: Array[String] = ["Adventurer"]
	result.append("Lv %s  %s %s" % [String(parts[1]), String(parts[2]), String(parts[3])])
	return result
