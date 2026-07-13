class_name ScheduleResolver
extends RefCounted

const MINUTES_PER_DAY := 1440


static func resolve(
	profile: Dictionary,
	minute_of_day: int,
	day: int = 1,
	overrides: Array = [],
	npc_id: String = "",
	weather: String = ""
) -> Dictionary:
	var blocks := _ordered_blocks(profile, overrides, day, weather)
	if blocks.is_empty():
		return {}
	var minute := posmod(minute_of_day, MINUTES_PER_DAY)
	var selected := blocks[blocks.size() - 1].duplicate(true)
	var selected_index := blocks.size() - 1
	for index in range(blocks.size()):
		var block: Dictionary = blocks[index]
		if int(block["start_minute"]) <= minute:
			selected = block
			selected_index = index
		else:
			break
	var next_index := (selected_index + 1) % blocks.size()
	var next_block: Dictionary = blocks[next_index]
	var next_minute := int(next_block["start_minute"])
	var minutes_until := next_minute - minute
	if minutes_until <= 0:
		minutes_until += MINUTES_PER_DAY
	var action := String(selected.get("action", ""))
	var action_pool: Variant = selected.get("action_pool", [])
	if action.is_empty() and action_pool is Array and not action_pool.is_empty():
		action = String(choose_deterministic(action_pool, npc_id, day, selected_index))
	if action.is_empty():
		action = _default_action(String(selected.get("activity", "sandbox")))
	return {
		"index": selected_index,
		"block_id": String(selected.get("id", "%s:%d" % [String(profile.get("id", "")), selected_index])),
		"activity": String(selected.get("activity", "sandbox")),
		"destination": String(selected.get("destination", "")),
		"destination_pool": String(selected.get("destination_pool", "")),
		"action": action,
		"action_pool": selected.get("action_pool", []),
		"start_minute": int(selected["start_minute"]),
		"next_index": next_index,
		"next_transition_minute": next_minute,
		"minutes_until_transition": minutes_until,
		"weather": weather,
		"day": day
	}


static func next_transition_absolute(
	profile: Dictionary, absolute_minute: int, overrides: Array = [], weather: String = ""
) -> int:
	var current := resolve(
		profile,
		posmod(absolute_minute, MINUTES_PER_DAY),
		floori(float(absolute_minute) / MINUTES_PER_DAY),
		overrides,
	"",
	weather
	)
	if current.is_empty():
		return absolute_minute
	return absolute_minute + int(current.get("minutes_until_transition", 0))


static func validate_full_day(profile: Dictionary, day: int = 1) -> Array[String]:
	var errors: Array[String] = []
	var blocks := _ordered_blocks(profile, [], day)
	if blocks.is_empty():
		errors.append("Schedule profile %s has no blocks." % String(profile.get("id", "")))
		return errors
	var covered := 0
	var seen_starts: Dictionary = {}
	for index in range(blocks.size()):
		var start := int(blocks[index]["start_minute"])
		if seen_starts.has(start):
			errors.append("Schedule profile %s has duplicate start time %d." % [String(profile.get("id", "")), start])
		seen_starts[start] = true
		var next_start := int(blocks[(index + 1) % blocks.size()]["start_minute"])
		var duration := next_start - start
		if duration <= 0:
			duration += MINUTES_PER_DAY
		covered += duration
	if covered != MINUTES_PER_DAY:
		errors.append("Schedule profile %s does not cover exactly one day." % String(profile.get("id", "")))
	return errors


static func choose_deterministic(values: Array, npc_id: String, day: int, block_index: int) -> Variant:
	if values.is_empty():
		return null
	var key := "%s:%d:%d" % [npc_id, day, block_index]
	return values[absi(key.hash()) % values.size()]


static func _ordered_blocks(
	profile: Dictionary, overrides: Array = [], day: int = 1, weather: String = ""
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var source: Variant = profile.get("weekday_blocks", profile.get("blocks", []))
	var weekend: Variant = profile.get("weekend_blocks", [])
	var day_of_week := posmod(day - 1, 7)
	if day_of_week >= 5 and weekend is Array and not weekend.is_empty():
		source = weekend
	if not source is Array:
		return result
	for value in source:
		if not value is Dictionary:
			continue
		var block: Dictionary = value.duplicate(true)
		var parsed := parse_time(String(block.get("start", "00:00")))
		if parsed < 0:
			continue
		block["start_minute"] = parsed
		result.append(block)
	var all_overrides: Array = []
	var weather_overrides: Variant = profile.get("weather_overrides", {})
	if not weather.is_empty() and weather_overrides is Dictionary:
		var selected_weather: Variant = (weather_overrides as Dictionary).get(weather, [])
		if selected_weather is Array:
			all_overrides.append_array(selected_weather)
	all_overrides.append_array(overrides)
	for override_value in all_overrides:
		if not override_value is Dictionary:
			continue
		var override: Dictionary = override_value
		var match_index := -1
		for index in range(result.size()):
			if (
				String(override.get("block_id", "")) == String(result[index].get("id", ""))
				or int(override.get("index", -1)) == index
			):
				match_index = index
				break
		if match_index < 0:
			continue
		if bool(override.get("suppress", false)):
			result.remove_at(match_index)
			continue
		for field in ["activity", "destination", "destination_pool", "action", "action_pool", "id"]:
			if override.has(field):
				result[match_index][field] = override[field]
		if override.has("action") and not override.has("action_pool"):
			result[match_index].erase("action_pool")
		if override.has("start"):
			var override_start := parse_time(String(override.get("start", "")))
			if override_start >= 0:
				result[match_index]["start_minute"] = override_start
	result.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["start_minute"]) < int(b["start_minute"])
	)
	return result


static func _default_action(activity: String) -> String:
	match activity:
		"sleep": return "sleep"
		"wake": return "wake"
		"work": return "work"
		"eat": return "eat"
		"relax": return "socialize"
		"travel": return "travel"
		_: return "idle"


static func parse_time(value: String) -> int:
	var parts := value.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return -1
	var hour := int(parts[0])
	var minute := int(parts[1])
	if hour < 0 or hour > 23 or minute < 0 or minute > 59:
		return -1
	return hour * 60 + minute
