# gdlint:disable=max-file-lines,max-public-methods
class_name ContentDatabase
extends Node

const HumanoidProfileResolver = preload("res://scripts/characters/humanoid_profile_resolver.gd")
const ContentItemValidator = preload("res://scripts/data/content_item_validator.gd")
const ContentPeopleValidator = preload("res://scripts/data/content_people_validator.gd")
const ContentQuestValidator = preload("res://scripts/data/content_quest_validator.gd")
const ContentWorldValidator = preload("res://scripts/data/content_world_validator.gd")
const SPELL_LOADOUT_SLOTS := ["ability_1", "ability_2", "ability_3"]

var items: Dictionary = {}
var readables: Dictionary = {}
var quests: Dictionary = {}
var npcs: Dictionary = {}
var character_profiles: Dictionary = {}
var people: Dictionary = {}
var people_visual_models: Dictionary = {}
var dialogues: Dictionary = {}
var locations: Dictionary = {}
var factions: Dictionary = {}
var shops: Dictionary = {}
var status_effects: Dictionary = {}
var spells: Dictionary = {}
var world_objects: Array[Dictionary] = []
var world_terrain: Dictionary = {}
var load_errors: Array[String] = []


func load_all() -> Array[String]:
	load_errors.clear()
	items = _load_dictionary("res://data/items.json")
	readables = _load_dictionary("res://data/readables.json")
	quests = _load_dictionary("res://data/quests.json")
	npcs = _load_dictionary("res://data/npcs.json")
	character_profiles = _load_dictionary("res://data/character_profiles.json")
	people = _load_dictionary("res://data/people.json")
	people_visual_models = _load_dictionary("res://data/people_visual_models.json")
	dialogues = _load_dictionary("res://data/dialogues.json")
	locations = _load_dictionary("res://data/locations.json")
	factions = _load_dictionary("res://data/factions.json")
	shops = _load_dictionary("res://data/shops.json")
	status_effects = _load_dictionary("res://data/status_effects.json")
	spells = _load_dictionary("res://data/spells.json")
	world_objects = _load_array("res://data/world_objects.json")
	world_terrain = _load_dictionary("res://data/world_terrain.json")
	return load_errors.duplicate()


func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func get_readable(readable_id: String) -> Dictionary:
	return readables.get(readable_id, {})


func get_quest(quest_id: String) -> Dictionary:
	return quests.get(quest_id, {})


func get_npc(npc_id: String) -> Dictionary:
	return npcs.get(npc_id, {})


func get_character_profile(profile_id: String) -> Dictionary:
	return HumanoidProfileResolver.character_profile(self, profile_id)


func get_character_profile_data(profile_id: String) -> Dictionary:
	return _dictionary_field(character_profiles.get(profile_id, {})).duplicate(true)


func get_people(people_id: String) -> Dictionary:
	return people.get(people_id, {})


func get_people_bonuses(people_id: String) -> Dictionary:
	return HumanoidProfileResolver.people_bonuses(self, people_id)


func get_people_visual_model(people_id: String) -> Dictionary:
	return people_visual_models.get(people_id, {})


func get_people_visual_variant(people_id: String, variant_id: String) -> Dictionary:
	return HumanoidProfileResolver.people_visual_variant(self, people_id, variant_id)


func get_people_visual_variant_profile(
	people_id: String, variant_id: String, character_id: String = ""
) -> Dictionary:
	return HumanoidProfileResolver.people_visual_variant_profile(
		self, people_id, variant_id, character_id
	)


func get_generated_people_appearance(
	people_id: String, seed_key: String = "", options: Dictionary = {}
) -> Dictionary:
	return HumanoidProfileResolver.generated_people_appearance(self, people_id, seed_key, options)


func get_generated_people_profile(
	people_id: String, character_id: String, seed_key: String = "", options: Dictionary = {}
) -> Dictionary:
	return HumanoidProfileResolver.generated_people_profile(
		self, people_id, character_id, seed_key, options
	)


func get_people_default_proportions(people_id: String) -> Dictionary:
	return HumanoidProfileResolver.people_default_proportions(self, people_id)


func get_dialogue(dialogue_id: String) -> Dictionary:
	return dialogues.get(dialogue_id, {})


func get_location(location_id: String) -> Dictionary:
	return locations.get(location_id, {})


func get_faction(faction_id: String) -> Dictionary:
	return factions.get(faction_id, {})


func get_shop(shop_id: String) -> Dictionary:
	return shops.get(shop_id, {})


func get_status_effect(status_id: String) -> Dictionary:
	return status_effects.get(status_id, {})


func get_spell(spell_id: String) -> Dictionary:
	return spells.get(spell_id, {})


func validate_all() -> Array[String]:
	var errors: Array[String] = []
	ContentItemValidator.validate(self, errors)
	ContentQuestValidator.validate(self, errors)
	ContentPeopleValidator.validate(self, errors)
	ContentWorldValidator.validate(self, errors)
	return errors


func _load_dictionary(path: String) -> Dictionary:
	var parsed: Variant = _load_json(path)
	if parsed is Dictionary:
		return parsed
	_record_load_error("Expected dictionary JSON at %s" % path)
	return {}


func _load_array(path: String) -> Array[Dictionary]:
	var parsed: Variant = _load_json(path)
	var result: Array[Dictionary] = []
	if parsed is Array:
		for entry in parsed:
			if entry is Dictionary:
				result.append(entry)
		return result
	_record_load_error("Expected array JSON at %s" % path)
	return result


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		_record_load_error("Missing content file: %s" % path)
		return null
	var raw := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(raw)
	if parsed == null:
		_record_load_error("Invalid JSON: %s" % path)
	return parsed


func _record_load_error(message: String) -> void:
	load_errors.append(message)
	push_warning(message)


func _validate_effect_list(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
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
			_validate_effect(effect, effect_owner, errors)
		else:
			errors.append("%s has malformed effect." % effect_owner)


func _validate_condition_list(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
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
			_validate_condition(condition, condition_owner, errors)
		else:
			errors.append("%s has malformed condition." % condition_owner)


func _validate_action_list(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
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
			and _array_field(action.get("effects", [])).is_empty()
		):
			errors.append("%s must have effects or response." % action_owner)
		_validate_condition_list(action, "conditions", action_owner, errors)
		_validate_effect_list(action, "effects", action_owner, errors)


func _validate_effect(effect: Dictionary, owner: String, errors: Array[String]) -> void:
	var effect_type := String(effect.get("type", ""))
	match effect_type:
		"set_flag":
			if String(effect.get("flag_id", "")).is_empty():
				errors.append("%s has set_flag with missing flag_id." % owner)
		"discover_location":
			var location_id := String(effect.get("location_id", ""))
			if not locations.has(location_id):
				errors.append("%s references missing location %s." % [owner, location_id])
		"start_quest", "complete_quest", "fail_quest":
			var quest_id := String(effect.get("quest_id", ""))
			if not quests.has(quest_id):
				errors.append("%s references missing quest %s." % [owner, quest_id])
		"set_quest_stage":
			var quest_id := String(effect.get("quest_id", ""))
			var stage_id := String(effect.get("stage", ""))
			var quest: Dictionary = quests.get(quest_id, {})
			var stages: Dictionary = quest.get("stages", {})
			if quest.is_empty():
				errors.append("%s references missing quest %s." % [owner, quest_id])
			elif not stages.has(stage_id):
				errors.append(
					"%s references missing quest stage %s:%s." % [owner, quest_id, stage_id]
				)
		"add_item", "remove_item":
			var item_id := String(effect.get("item_id", ""))
			if not items.has(item_id):
				errors.append("%s references missing item %s." % [owner, item_id])
			_validate_optional_positive_number(
				effect, "count", "%s %s" % [owner, effect_type], errors
			)
		"heal_player":
			_validate_required_positive_number(effect, "amount", "%s heal_player" % owner, errors)
		"change_reputation":
			var faction_id := String(effect.get("faction_id", ""))
			if not factions.has(faction_id):
				errors.append("%s references missing faction %s." % [owner, faction_id])
			_validate_required_number(effect, "amount", "%s change_reputation" % owner, errors)
		"add_experience":
			_validate_required_positive_number(
				effect, "amount", "%s add_experience" % owner, errors
			)
		"advance_time":
			if not effect.has("minutes") and not effect.has("hours"):
				errors.append("%s advance_time requires minutes or hours." % owner)
			_validate_optional_positive_number(effect, "minutes", "%s advance_time" % owner, errors)
			_validate_optional_positive_number(effect, "hours", "%s advance_time" % owner, errors)
		"apply_status":
			var status_id := String(effect.get("status_id", ""))
			if not status_effects.has(status_id):
				errors.append("%s references missing status %s." % [owner, status_id])
			_validate_optional_positive_number(effect, "charges", "%s apply_status" % owner, errors)
		_:
			errors.append("%s has unsupported effect type %s." % [owner, effect_type])


func _validate_spell_loadout_fields(
	entry: Dictionary, owner: String, errors: Array[String]
) -> void:
	for spell_id in _array_field(entry.get("spell_ids", [])):
		if not spells.has(String(spell_id)):
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
		if not SPELL_LOADOUT_SLOTS.has(slot):
			errors.append("%s has unsupported loadout slot %s." % [owner, slot])
		if not spells.has(spell_id):
			errors.append("%s loadout slot %s references missing spell %s." % [owner, slot, spell_id])


func _validate_condition(condition: Dictionary, owner: String, errors: Array[String]) -> void:
	var condition_type := String(condition.get("type", ""))
	match condition_type:
		"has_flag", "not_flag":
			if String(condition.get("flag_id", "")).is_empty():
				errors.append("%s has %s with missing flag_id." % [owner, condition_type])
		"has_item":
			var item_id := String(condition.get("item_id", ""))
			if not items.has(item_id):
				errors.append("%s references missing item %s." % [owner, item_id])
			_validate_optional_positive_number(condition, "count", "%s has_item" % owner, errors)
		"quest_state":
			var quest_id := String(condition.get("quest_id", ""))
			var state := String(condition.get("state", ""))
			if not quests.has(quest_id):
				errors.append("%s references missing quest %s." % [owner, quest_id])
			if not ["inactive", "active", "completed", "failed"].has(state):
				errors.append("%s has quest_state with invalid state %s." % [owner, state])
		"quest_stage":
			var quest_id := String(condition.get("quest_id", ""))
			var stage := String(condition.get("stage", ""))
			var quest: Dictionary = quests.get(quest_id, {})
			var stages: Dictionary = quest.get("stages", {})
			if quest.is_empty():
				errors.append("%s references missing quest %s." % [owner, quest_id])
			elif not stages.has(stage):
				errors.append("%s references missing quest stage %s:%s." % [owner, quest_id, stage])
		"read_readable":
			var readable_id := String(condition.get("readable_id", ""))
			if not readables.has(readable_id):
				errors.append("%s references missing readable %s." % [owner, readable_id])
		"location_discovered":
			var location_id := String(condition.get("location_id", ""))
			if not locations.has(location_id):
				errors.append("%s references missing location %s." % [owner, location_id])
		"faction_reputation_at_least":
			var faction_id := String(condition.get("faction_id", ""))
			if not factions.has(faction_id):
				errors.append("%s references missing faction %s." % [owner, faction_id])
			_validate_required_number(condition, "reputation", owner, errors)
		"player_level_at_least":
			_validate_required_positive_number(condition, "level", owner, errors)
		"time_phase":
			var phase := String(condition.get("phase", ""))
			if not ["Morning", "Afternoon", "Evening", "Night"].has(phase):
				errors.append("%s has time_phase with invalid phase %s." % [owner, phase])
		"time_hour_between":
			_validate_required_bounded_number(condition, "start_hour", owner, 0.0, 23.0, errors)
			_validate_required_bounded_number(condition, "end_hour", owner, 0.0, 23.0, errors)
		_:
			errors.append("%s has unsupported condition type %s." % [owner, condition_type])


func _validate_keyed_id(
	entry: Dictionary, key: String, label: String, errors: Array[String]
) -> void:
	var declared_id := String(entry.get("id", ""))
	if declared_id.is_empty():
		errors.append("%s %s is missing id." % [label, key])
	elif declared_id != key:
		errors.append("%s %s has mismatched id %s." % [label, key, declared_id])


func _validate_global_tile(entry: Dictionary, owner: String, errors: Array[String]) -> void:
	var tile: Variant = entry.get("global_tile", [])
	_validate_numeric_pair(tile, "%s global_tile" % owner, errors)


func _validate_numeric_pair(value: Variant, owner: String, errors: Array[String]) -> void:
	if not (value is Array) or value.size() < 2:
		errors.append("%s must be [x, y]." % owner)
		return
	if not _is_number(value[0]) or not _is_number(value[1]):
		errors.append("%s values must be numeric." % owner)


func _validate_positive_pair(value: Variant, owner: String, errors: Array[String]) -> void:
	if not (value is Array) or value.size() < 2:
		errors.append("%s must be [width, height]." % owner)
		return
	if not _is_number(value[0]) or not _is_number(value[1]):
		errors.append("%s values must be numeric." % owner)
		return
	if float(value[0]) <= 0.0 or float(value[1]) <= 0.0:
		errors.append("%s values must be positive." % owner)


func _validate_required_positive_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id) or not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	if float(entry[field_id]) <= 0.0:
		errors.append("%s must have positive %s." % [owner, field_id])


func _validate_optional_positive_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	if not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	if float(entry[field_id]) <= 0.0:
		errors.append("%s has non-positive %s." % [owner, field_id])


func _validate_required_non_negative_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id) or not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	if float(entry[field_id]) < 0.0:
		errors.append("%s must have non-negative %s." % [owner, field_id])


func _validate_required_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id) or not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])


func _validate_required_bounded_number(
	entry: Dictionary,
	field_id: String,
	owner: String,
	min_value: float,
	max_value: float,
	errors: Array[String]
) -> void:
	if not entry.has(field_id) or not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	var value := float(entry[field_id])
	if value < min_value or value > max_value:
		errors.append(
			"%s %s must be between %.0f and %.0f." % [owner, field_id, min_value, max_value]
		)


func _validate_optional_non_negative_number(
	entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	if not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	if float(entry[field_id]) < 0.0:
		errors.append("%s must have non-negative %s." % [owner, field_id])


func _validate_optional_bounded_number(
	entry: Dictionary,
	field_id: String,
	owner: String,
	min_value: float,
	max_value: float,
	errors: Array[String]
) -> void:
	if not entry.has(field_id):
		return
	if not _is_number(entry[field_id]):
		errors.append("%s %s must be numeric." % [owner, field_id])
		return
	var value := float(entry[field_id])
	if value < min_value or value > max_value:
		errors.append(
			"%s %s must be between %.0f and %.0f." % [owner, field_id, min_value, max_value]
		)


func _array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []


func _dictionary_field(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _objective_text(value: Variant) -> String:
	if value is Dictionary:
		return String(value.get("text", ""))
	return String(value)


func _objective_target_id(value: Variant) -> String:
	if value is Dictionary:
		return String(value.get("target_id", ""))
	return ""


func _world_object_id_exists(object_id: String) -> bool:
	if object_id.is_empty():
		return false
	for entry in world_objects:
		if String(entry.get("id", "")) == object_id:
			return true
	return false


func _supported_system_tabs() -> Array[String]:
	return ["inventory", "character", "trade", "quests", "journal", "log"]


func _supported_terrain_kinds() -> Array[String]:
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


func _is_number(value: Variant) -> bool:
	return value is int or value is float
