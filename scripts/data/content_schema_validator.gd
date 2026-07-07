class_name ContentSchemaValidator
extends RefCounted

const SpellSlots = preload("res://scripts/core/spell_slots.gd")


static func validate_effect_list(
	content: ContentDatabase, entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	var effects: Variant = entry.get(field_id, [])
	if not effects is Array:
		errors.append("%s %s must be an array." % [owner, field_id])
		return
	for effect in effects:
		var effect_owner := "%s %s" % [owner, field_id]
		if effect is Dictionary:
			validate_effect(content, effect, effect_owner, errors)
		else:
			errors.append("%s has malformed effect." % effect_owner)


static func validate_condition_list(
	content: ContentDatabase, entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	var conditions: Variant = entry.get(field_id, [])
	if not conditions is Array:
		errors.append("%s %s must be an array." % [owner, field_id])
		return
	for condition in conditions:
		var condition_owner := "%s %s" % [owner, field_id]
		if condition is Dictionary:
			validate_condition(content, condition, condition_owner, errors)
		else:
			errors.append("%s has malformed condition." % condition_owner)


static func validate_action_list(
	content: ContentDatabase, entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	var actions: Variant = entry.get(field_id, [])
	if not actions is Array:
		errors.append("%s %s must be an array." % [owner, field_id])
		return
	var seen_ids: Dictionary = {}
	for action in actions:
		if not action is Dictionary:
			errors.append("%s %s has malformed action." % [owner, field_id])
			continue
		var action_id := String(action.get("id", ""))
		var action_owner := "%s %s action %s" % [owner, field_id, action_id]
		if action_id.is_empty():
			errors.append("%s %s has action with missing id." % [owner, field_id])
		elif seen_ids.has(action_id):
			errors.append("%s %s has duplicate action id %s." % [owner, field_id, action_id])
		seen_ids[action_id] = true
		if String(action.get("text", "")).is_empty():
			errors.append("%s is missing text." % action_owner)
		if (
			String(action.get("response", "")).is_empty()
			and array_field(action.get("effects", [])).is_empty()
		):
			errors.append("%s must have effects or response." % action_owner)
		validate_condition_list(content, action, "conditions", action_owner, errors)
		validate_effect_list(content, action, "effects", action_owner, errors)


static func validate_effect(
	content: ContentDatabase, effect: Dictionary, owner: String, errors: Array[String]
) -> void:
	var effect_type := String(effect.get("type", ""))
	match effect_type:
		"set_flag":
			if String(effect.get("flag_id", "")).is_empty():
				errors.append("%s has set_flag with missing flag_id." % owner)
		"discover_location":
			var location_id := String(effect.get("location_id", ""))
			if not content.has_location(location_id):
				errors.append("%s references missing location %s." % [owner, location_id])
		"start_quest", "complete_quest", "fail_quest":
			var quest_id := String(effect.get("quest_id", ""))
			if not content.has_quest(quest_id):
				errors.append("%s references missing quest %s." % [owner, quest_id])
		"set_quest_stage":
			var quest_id := String(effect.get("quest_id", ""))
			var stage_id := String(effect.get("stage", ""))
			var quest: Dictionary = content.get_quest(quest_id)
			var stages: Dictionary = quest.get("stages", {})
			if quest.is_empty():
				errors.append("%s references missing quest %s." % [owner, quest_id])
			elif not stages.has(stage_id):
				errors.append(
					"%s references missing quest stage %s:%s." % [owner, quest_id, stage_id]
				)
		"add_item", "remove_item":
			var item_id := String(effect.get("item_id", ""))
			if not content.has_item(item_id):
				errors.append("%s references missing item %s." % [owner, item_id])
			validate_optional_positive_number(
				effect, "count", "%s %s" % [owner, effect_type], errors
			)
		"heal_player":
			validate_required_positive_number(effect, "amount", "%s heal_player" % owner, errors)
		"change_reputation":
			var faction_id := String(effect.get("faction_id", ""))
			if not content.has_faction(faction_id):
				errors.append("%s references missing faction %s." % [owner, faction_id])
			validate_required_number(effect, "amount", "%s change_reputation" % owner, errors)
		"add_experience":
			validate_required_positive_number(
				effect, "amount", "%s add_experience" % owner, errors
			)
		"advance_time":
			if not effect.has("minutes") and not effect.has("hours"):
				errors.append("%s advance_time requires minutes or hours." % owner)
			validate_optional_positive_number(effect, "minutes", "%s advance_time" % owner, errors)
			validate_optional_positive_number(effect, "hours", "%s advance_time" % owner, errors)
		"apply_status":
			var status_id := String(effect.get("status_id", ""))
			if not content.has_status_effect(status_id):
				errors.append("%s references missing status %s." % [owner, status_id])
			validate_optional_positive_number(effect, "charges", "%s apply_status" % owner, errors)
		_:
			errors.append("%s has unsupported effect type %s." % [owner, effect_type])


static func validate_spell_loadout_fields(
	content: ContentDatabase, entry: Dictionary, owner: String, errors: Array[String]
) -> void:
	for spell_id in array_field(entry.get("spell_ids", [])):
		if not content.has_spell(String(spell_id)):
			errors.append("%s references missing spell %s." % [owner, String(spell_id)])
	var slots_value: Variant = entry.get("loadout_slots", {})
	if not entry.has("loadout_slots"):
		return
	if not slots_value is Dictionary:
		errors.append("%s loadout_slots must be a dictionary." % owner)
		return
	var slots: Dictionary = slots_value
	for slot_id in slots:
		var slot := String(slot_id)
		var spell_id := String(slots[slot_id])
		if not SpellSlots.is_supported(slot):
			errors.append("%s has unsupported loadout slot %s." % [owner, slot])
		if not content.has_spell(spell_id):
			errors.append("%s loadout slot %s references missing spell %s." % [owner, slot, spell_id])


static func validate_condition(
	content: ContentDatabase, condition: Dictionary, owner: String, errors: Array[String]
) -> void:
	var condition_type := String(condition.get("type", ""))
	match condition_type:
		"has_flag", "not_flag":
			if String(condition.get("flag_id", "")).is_empty():
				errors.append("%s has %s with missing flag_id." % [owner, condition_type])
		"has_item":
			var item_id := String(condition.get("item_id", ""))
			if not content.has_item(item_id):
				errors.append("%s references missing item %s." % [owner, item_id])
			validate_optional_positive_number(condition, "count", "%s has_item" % owner, errors)
		"quest_state":
			var quest_id := String(condition.get("quest_id", ""))
			var state := String(condition.get("state", ""))
			if not content.has_quest(quest_id):
				errors.append("%s references missing quest %s." % [owner, quest_id])
			if not ["inactive", "active", "completed", "failed"].has(state):
				errors.append("%s has quest_state with invalid state %s." % [owner, state])
		"quest_stage":
			var quest_id := String(condition.get("quest_id", ""))
			var stage := String(condition.get("stage", ""))
			var quest: Dictionary = content.get_quest(quest_id)
			var stages: Dictionary = quest.get("stages", {})
			if quest.is_empty():
				errors.append("%s references missing quest %s." % [owner, quest_id])
			elif not stages.has(stage):
				errors.append("%s references missing quest stage %s:%s." % [owner, quest_id, stage])
		"read_readable":
			var readable_id := String(condition.get("readable_id", ""))
			if not content.has_readable(readable_id):
				errors.append("%s references missing readable %s." % [owner, readable_id])
		"location_discovered":
			var location_id := String(condition.get("location_id", ""))
			if not content.has_location(location_id):
				errors.append("%s references missing location %s." % [owner, location_id])
		"faction_reputation_at_least":
			var faction_id := String(condition.get("faction_id", ""))
			if not content.has_faction(faction_id):
				errors.append("%s references missing faction %s." % [owner, faction_id])
			validate_required_number(condition, "reputation", owner, errors)
		"player_level_at_least":
			validate_required_positive_number(condition, "level", owner, errors)
		"time_phase":
			var phase := String(condition.get("phase", ""))
			if not ["Morning", "Afternoon", "Evening", "Night"].has(phase):
				errors.append("%s has time_phase with invalid phase %s." % [owner, phase])
		"time_hour_between":
			validate_required_bounded_number(condition, "start_hour", owner, 0.0, 23.0, errors)
			validate_required_bounded_number(condition, "end_hour", owner, 0.0, 23.0, errors)
		_:
			errors.append("%s has unsupported condition type %s." % [owner, condition_type])


static func validate_keyed_id(
	entry: Dictionary, key: String, label: String, errors: Array[String]
) -> void:
	var declared_id := String(entry.get("id", ""))
	if declared_id.is_empty():
		errors.append("%s %s is missing id." % [label, key])
	elif declared_id != key:
		errors.append("%s %s has mismatched id %s." % [label, key, declared_id])


static func validate_global_tile(entry: Dictionary, owner: String, errors: Array[String]) -> void:
	var tile: Variant = entry.get("global_tile", [])
	validate_numeric_pair(tile, "%s global_tile" % owner, errors)


static func validate_numeric_pair(value: Variant, owner: String, errors: Array[String]) -> void:
	if not (value is Array) or value.size() < 2:
		errors.append("%s must be [x, y]." % owner)
		return
	if not is_number(value[0]) or not is_number(value[1]):
		errors.append("%s values must be numeric." % owner)


static func validate_positive_pair(value: Variant, owner: String, errors: Array[String]) -> void:
	if not (value is Array) or value.size() < 2:
		errors.append("%s must be [width, height]." % owner)
		return
	if not is_number(value[0]) or not is_number(value[1]):
		errors.append("%s values must be numeric." % owner)
		return
	if float(value[0]) <= 0.0 or float(value[1]) <= 0.0:
		errors.append("%s values must be positive." % owner)


static func validate_required_positive_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id) or not is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	if float(entry[field_id]) <= 0.0:
		errors.append("%s must have positive %s." % [owner, field_id])


static func validate_optional_positive_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	if not is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	if float(entry[field_id]) <= 0.0:
		errors.append("%s has non-positive %s." % [owner, field_id])


static func validate_required_non_negative_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id) or not is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	if float(entry[field_id]) < 0.0:
		errors.append("%s must have non-negative %s." % [owner, field_id])


static func validate_required_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id) or not is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])


static func validate_required_bounded_number(
	entry: Dictionary,
	field_id: String,
	owner: String,
	min_value: float,
	max_value: float,
	errors: Array[String]
) -> void:
	if not entry.has(field_id) or not is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	var value := float(entry[field_id])
	if value < min_value or value > max_value:
		errors.append(
			"%s %s must be between %.0f and %.0f." % [owner, field_id, min_value, max_value]
		)


static func validate_optional_non_negative_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	if not is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	if float(entry[field_id]) < 0.0:
		errors.append("%s must have non-negative %s." % [owner, field_id])


static func validate_optional_bounded_number(
	entry: Dictionary,
	field_id: String,
	owner: String,
	min_value: float,
	max_value: float,
	errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	if not is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	var value := float(entry[field_id])
	if value < min_value or value > max_value:
		errors.append(
			"%s %s must be between %.0f and %.0f." % [owner, field_id, min_value, max_value]
		)


static func array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []


static func dictionary_field(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


static func objective_text(value: Variant) -> String:
	if value is Dictionary:
		return String(value.get("text", ""))
	return String(value)


static func objective_target_id(value: Variant) -> String:
	if value is Dictionary:
		return String(value.get("target_id", ""))
	return ""


static func world_object_id_exists(content: ContentDatabase, object_id: String) -> bool:
	if object_id.is_empty():
		return false
	for entry in content.world_object_entries():
		if String(entry.get("id", "")) == object_id:
			return true
	return false


static func supported_system_tabs() -> Array[String]:
	return ["inventory", "character", "trade", "quests", "journal", "log"]


static func supported_terrain_kinds() -> Array[String]:
	return [
		"grass",
		"water",
		"bridge",
		"stone_wall",
		"wood_wall",
		"wood_floor",
		"forest",
		"hill",
		"road"
	]


static func is_number(value: Variant) -> bool:
	return value is int or value is float
