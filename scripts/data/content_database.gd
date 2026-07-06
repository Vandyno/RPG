# gdlint:disable=max-file-lines,max-public-methods
class_name ContentDatabase
extends Node

const HumanoidProfileResolver = preload("res://scripts/characters/humanoid_profile_resolver.gd")
const ContentSchemaValidator = preload("res://scripts/data/content_schema_validator.gd")
const ContentItemValidator = preload("res://scripts/data/content_item_validator.gd")
const ContentPeopleValidator = preload("res://scripts/data/content_people_validator.gd")
const ContentQuestValidator = preload("res://scripts/data/content_quest_validator.gd")
const ContentWorldValidator = preload("res://scripts/data/content_world_validator.gd")

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
	return ContentSchemaValidator.dictionary_field(
		character_profiles.get(profile_id, {})
	).duplicate(true)


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
