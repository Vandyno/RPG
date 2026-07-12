# gdlint:disable=max-file-lines,max-public-methods
class_name ContentDatabase
extends Node

const HumanoidProfileResolver = preload("res://scripts/characters/humanoid_profile_resolver.gd")
const ContentSchemaValidator = preload("res://scripts/data/content_schema_validator.gd")
const ContentItemValidator = preload("res://scripts/data/content_item_validator.gd")
const ContentHumanoidFaceValidator = preload(
	"res://scripts/data/content_humanoid_face_validator.gd"
)
const ContentPeopleValidator = preload("res://scripts/data/content_people_validator.gd")
const ContentQuestValidator = preload("res://scripts/data/content_quest_validator.gd")
const ContentWorldValidator = preload("res://scripts/data/content_world_validator.gd")
const ContentScheduleValidator = preload("res://scripts/data/content_schedule_validator.gd")

var items: Dictionary = {}
var readables: Dictionary = {}
var quests: Dictionary = {}
var npcs: Dictionary = {}
var character_profiles: Dictionary = {}
var people: Dictionary = {}
var people_visual_models: Dictionary = {}
var humanoid_face_parts: Dictionary = {}
var dialogues: Dictionary = {}
var locations: Dictionary = {}
var factions: Dictionary = {}
var shops: Dictionary = {}
var schedule_profiles: Dictionary = {}
var schedule_bindings: Dictionary = {}
var schedule_destinations: Dictionary = {}
var status_effects: Dictionary = {}
var spells: Dictionary = {}
var world_objects: Array[Dictionary] = []
var world_terrain: Dictionary = {}
var structure_archetypes: Dictionary = {}
var world_structures: Array[Dictionary] = []
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
	humanoid_face_parts = _load_dictionary("res://data/humanoid_face_parts.json")
	dialogues = _load_dictionary("res://data/dialogues.json")
	locations = _load_dictionary("res://data/locations.json")
	factions = _load_dictionary("res://data/factions.json")
	shops = _load_dictionary("res://data/shops.json")
	schedule_profiles = _load_dictionary("res://data/schedule_profiles.json")
	schedule_bindings = _load_dictionary("res://data/schedule_bindings.json")
	schedule_destinations = _load_dictionary("res://data/schedule_destinations.json")
	status_effects = _load_dictionary("res://data/status_effects.json")
	spells = _load_dictionary("res://data/spells.json")
	world_objects = _load_array("res://data/world_objects.json")
	world_terrain = _load_dictionary("res://data/world_terrain.json")
	structure_archetypes = _load_dictionary("res://data/structure_archetypes.json")
	world_structures = _load_array("res://data/world_structures.json")
	for runtime_dictionary in [
		[items, "res://data/runtime/northgate_items.json"],
		[readables, "res://data/runtime/northgate_readables.json"],
		[quests, "res://data/runtime/northgate_quests.json"],
		[npcs, "res://data/runtime/northgate_npcs.json"],
		[character_profiles, "res://data/runtime/northgate_character_profiles.json"],
		[dialogues, "res://data/runtime/northgate_dialogues.json"],
		[shops, "res://data/runtime/northgate_shops.json"]
	]:
		_merge_runtime_dictionary(runtime_dictionary[0], _load_dictionary(runtime_dictionary[1]))
	_merge_runtime_dictionary(
		structure_archetypes,
		_load_dictionary("res://data/runtime/northgate_structure_archetypes.json")
	)
	_merge_runtime_dictionary(
		character_profiles,
		_load_dictionary("res://data/runtime/northgate_schedule_character_profiles.json")
	)
	_merge_runtime_dictionary(
		schedule_bindings,
		_load_dictionary("res://data/runtime/northgate_schedule_bindings.json")
	)
	_merge_runtime_dictionary(
		schedule_destinations,
		_load_dictionary("res://data/runtime/northgate_schedule_destinations.json")
	)
	_merge_runtime_dictionary(
		npcs,
		_load_dictionary("res://data/runtime/northgate_schedule_npcs.json")
	)
	world_structures.append_array(
		_load_array("res://data/runtime/northgate_structures.json")
	)
	world_objects.append_array(_load_array("res://data/runtime/northgate_objects.json"))
	world_objects.append_array(_load_array("res://data/runtime/northgate_schedule_actors.json"))
	var northgate_terrain := _load_dictionary("res://data/runtime/northgate_terrain.json")
	if not world_terrain.has("areas") or not world_terrain["areas"] is Array:
		world_terrain["areas"] = []
	world_terrain["areas"].append_array(
		ContentSchemaValidator.array_field(northgate_terrain.get("areas", []))
	)
	return load_errors.duplicate()


func get_item(item_id: String) -> Dictionary:
	return _dictionary_copy(items.get(item_id, {}))


func has_item(item_id: String) -> bool:
	return items.has(item_id)


func item_ids() -> Array[String]:
	return _dictionary_keys(items)


func get_readable(readable_id: String) -> Dictionary:
	return _dictionary_copy(readables.get(readable_id, {}))


func has_readable(readable_id: String) -> bool:
	return readables.has(readable_id)


func readable_ids() -> Array[String]:
	return _dictionary_keys(readables)


func get_quest(quest_id: String) -> Dictionary:
	return _dictionary_copy(quests.get(quest_id, {}))


func has_quest(quest_id: String) -> bool:
	return quests.has(quest_id)


func quest_ids() -> Array[String]:
	return _dictionary_keys(quests)


func get_npc(npc_id: String) -> Dictionary:
	return _dictionary_copy(npcs.get(npc_id, {}))


func has_npc(npc_id: String) -> bool:
	return npcs.has(npc_id)


func npc_ids() -> Array[String]:
	return _dictionary_keys(npcs)


func get_resolved_character_profile(profile_id: String) -> Dictionary:
	return _dictionary_copy(HumanoidProfileResolver.resolved_character_profile(self, profile_id))


func get_authored_character_profile(profile_id: String) -> Dictionary:
	return _dictionary_copy(character_profiles.get(profile_id, {}))


func has_character_profile(profile_id: String) -> bool:
	return character_profiles.has(profile_id)


func character_profile_ids() -> Array[String]:
	return _dictionary_keys(character_profiles)


func get_people(people_id: String) -> Dictionary:
	return _dictionary_copy(people.get(people_id, {}))


func has_people(people_id: String) -> bool:
	return people.has(people_id)


func people_ids() -> Array[String]:
	return _dictionary_keys(people)


func get_people_bonuses(people_id: String) -> Dictionary:
	return _dictionary_copy(HumanoidProfileResolver.people_bonuses(self, people_id))


func get_people_visual_model(people_id: String) -> Dictionary:
	return _dictionary_copy(people_visual_models.get(people_id, {}))


func get_humanoid_face_catalog() -> Dictionary:
	return humanoid_face_parts.duplicate(true)


func has_people_visual_model(people_id: String) -> bool:
	return people_visual_models.has(people_id)


func people_visual_model_ids() -> Array[String]:
	return _dictionary_keys(people_visual_models)


func get_people_visual_variant(people_id: String, variant_id: String) -> Dictionary:
	return _dictionary_copy(HumanoidProfileResolver.people_visual_variant(self, people_id, variant_id))


func get_people_visual_variant_profile(
	people_id: String, variant_id: String, character_id: String = ""
) -> Dictionary:
	return _dictionary_copy(
		HumanoidProfileResolver.people_visual_variant_profile(
			self, people_id, variant_id, character_id
		)
	)


func get_generated_people_appearance(
	people_id: String, seed_key: String = "", options: Dictionary = {}
) -> Dictionary:
	return _dictionary_copy(
		HumanoidProfileResolver.generated_people_appearance(self, people_id, seed_key, options)
	)


func get_generated_people_profile(
	people_id: String, character_id: String, seed_key: String = "", options: Dictionary = {}
) -> Dictionary:
	return _dictionary_copy(
		HumanoidProfileResolver.generated_people_profile(
			self, people_id, character_id, seed_key, options
		)
	)


func get_people_default_proportions(people_id: String) -> Dictionary:
	return _dictionary_copy(HumanoidProfileResolver.people_default_proportions(self, people_id))


func get_dialogue(dialogue_id: String) -> Dictionary:
	return _dictionary_copy(dialogues.get(dialogue_id, {}))


func has_dialogue(dialogue_id: String) -> bool:
	return dialogues.has(dialogue_id)


func dialogue_ids() -> Array[String]:
	return _dictionary_keys(dialogues)


func get_location(location_id: String) -> Dictionary:
	return _dictionary_copy(locations.get(location_id, {}))


func has_location(location_id: String) -> bool:
	return locations.has(location_id)


func location_ids() -> Array[String]:
	return _dictionary_keys(locations)


func get_faction(faction_id: String) -> Dictionary:
	return _dictionary_copy(factions.get(faction_id, {}))


func has_faction(faction_id: String) -> bool:
	return factions.has(faction_id)


func faction_ids() -> Array[String]:
	return _dictionary_keys(factions)


func get_shop(shop_id: String) -> Dictionary:
	return _dictionary_copy(shops.get(shop_id, {}))


func has_shop(shop_id: String) -> bool:
	return shops.has(shop_id)


func shop_ids() -> Array[String]:
	return _dictionary_keys(shops)


func get_schedule_profile(profile_id: String) -> Dictionary:
	return _dictionary_copy(schedule_profiles.get(profile_id, {}))


func get_schedule_binding(binding_id: String) -> Dictionary:
	return _dictionary_copy(schedule_bindings.get(binding_id, {}))


func get_schedule_binding_for_npc(npc_id: String) -> Dictionary:
	for binding_id in schedule_bindings:
		var binding: Dictionary = schedule_bindings[binding_id]
		if String(binding.get("npc_id", "")) == npc_id:
			var result := binding.duplicate(true)
			result["id"] = String(binding_id)
			return result
	return {}


func get_schedule_destinations() -> Dictionary:
	return schedule_destinations.duplicate(true)


func get_status_effect(status_id: String) -> Dictionary:
	return _dictionary_copy(status_effects.get(status_id, {}))


func has_status_effect(status_id: String) -> bool:
	return status_effects.has(status_id)


func status_effect_ids() -> Array[String]:
	return _dictionary_keys(status_effects)


func get_spell(spell_id: String) -> Dictionary:
	return _dictionary_copy(spells.get(spell_id, {}))


func has_spell(spell_id: String) -> bool:
	return spells.has(spell_id)


func spell_ids() -> Array[String]:
	return _dictionary_keys(spells)


func world_object_entries() -> Array[Dictionary]:
	return world_objects.duplicate(true)


func get_world_terrain() -> Dictionary:
	return world_terrain.duplicate(true)


func get_structure_archetype(archetype_id: String) -> Dictionary:
	return _dictionary_copy(structure_archetypes.get(archetype_id, {}))


func has_structure_archetype(archetype_id: String) -> bool:
	return structure_archetypes.has(archetype_id)


func structure_archetype_ids() -> Array[String]:
	return _dictionary_keys(structure_archetypes)


func world_structure_entries() -> Array[Dictionary]:
	return world_structures.duplicate(true)


func validate_all() -> Array[String]:
	var errors: Array[String] = []
	ContentItemValidator.validate(self, errors)
	ContentHumanoidFaceValidator.validate(self, errors)
	ContentQuestValidator.validate(self, errors)
	ContentPeopleValidator.validate(self, errors)
	ContentWorldValidator.validate(self, errors)
	ContentScheduleValidator.validate(self, errors)
	return errors


func _load_dictionary(path: String) -> Dictionary:
	var error_count := load_errors.size()
	var parsed: Variant = _load_json(path)
	if parsed is Dictionary:
		return parsed
	if parsed == null and load_errors.size() > error_count:
		return {}
	_record_load_error("Expected dictionary JSON at %s" % path)
	return {}


func _load_array(path: String) -> Array[Dictionary]:
	var error_count := load_errors.size()
	var parsed: Variant = _load_json(path)
	var result: Array[Dictionary] = []
	if parsed is Array:
		for entry in parsed:
			if entry is Dictionary:
				result.append(entry)
		return result
	if parsed == null and load_errors.size() > error_count:
		return result
	_record_load_error("Expected array JSON at %s" % path)
	return result


func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		_record_load_error("Missing content file: %s" % path)
		return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_record_load_error(
			"Could not read content file %s: %s"
			% [path, error_string(FileAccess.get_open_error())]
		)
		return null
	var raw := file.get_as_text()
	var parser := JSON.new()
	var error := parser.parse(raw)
	if error != OK:
		_record_load_error(
			"Invalid JSON at %s line %d: %s"
			% [path, parser.get_error_line(), parser.get_error_message()]
		)
		return null
	return parser.data


func _record_load_error(message: String) -> void:
	load_errors.append(message)
	push_warning(message)


func _dictionary_copy(value: Variant) -> Dictionary:
	return ContentSchemaValidator.dictionary_field(value).duplicate(true)


func _merge_runtime_dictionary(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		target[String(key)] = source[key]


func _dictionary_keys(source: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key in source:
		result.append(String(key))
	return result
