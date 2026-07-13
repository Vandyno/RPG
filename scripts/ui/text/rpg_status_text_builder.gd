class_name RpgStatusTextBuilder
extends RefCounted


static func lines(_state: Dictionary, progression_text: String, compact := false) -> Array[String]:
	if compact:
		return _compact_lines(_state, progression_text)
	var result: Array[String] = ["Adventurer", progression_text]
	var statuses := String(_state.get("statuses", "none"))
	if statuses != "none":
		result.append("Effects: %s" % statuses)
	var stealth := String(_state.get("stealth_state", ""))
	if not stealth.is_empty():
		result.append("Stealth: %s" % stealth)
	var bounty := maxi(0, int(_state.get("bounty", 0)))
	if bounty > 0:
		result.append("Wanted: %dg" % bounty)
	if bool(_state.get("jailed", false)):
		result.append("Jailed: %dh" % maxi(0, int(_state.get("sentence_hours", 0))))
	return result


static func _compact_lines(_state: Dictionary, progression_text: String) -> Array[String]:
	var parts := progression_text.split(" ", false)
	if parts.size() < 4:
		return _compact_with_legal(_state, ["Adventurer", progression_text.replace("Level", "Lv")])
	var result: Array[String] = ["Adventurer"]
	result.append("Lv %s  %s %s" % [String(parts[1]), String(parts[2]), String(parts[3])])
	return _compact_with_legal(_state, result)


static func _compact_with_legal(state: Dictionary, lines: Array[String]) -> Array[String]:
	var stealth := String(state.get("stealth_state", ""))
	var bounty := maxi(0, int(state.get("bounty", 0)))
	var legal := ""
	if bool(state.get("jailed", false)):
		legal = "Jail %dh" % maxi(0, int(state.get("sentence_hours", 0)))
	elif bounty > 0:
		legal = "Wanted %dg" % bounty
	if not stealth.is_empty() or not legal.is_empty():
		lines.append("  ".join([stealth, legal].filter(func(value: String): return not value.is_empty())))
	return lines
