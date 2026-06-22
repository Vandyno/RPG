class_name SaveManager
extends Node

const DEFAULT_SAVE_PATH := "user://save_slot_1.json"
const CURRENT_VERSION := 1
const REQUIRED_PROVIDERS := [
	"player",
	"world_state",
	"quests",
	"inventory",
	"equipment",
	"factions",
	"progression",
	"statuses",
	"time",
	"readables",
	"combat",
	"chunks"
]

var event_bus
var providers: Dictionary = {}
var save_path := DEFAULT_SAVE_PATH


func setup(bus, save_providers: Dictionary, path: String = DEFAULT_SAVE_PATH) -> void:
	event_bus = bus
	providers = save_providers
	save_path = path


func save_game() -> bool:
	if not _has_required_providers():
		return false
	var data := {
		"version": CURRENT_VERSION,
		"player": providers["player"].get_save_data(),
		"world_state": providers["world_state"].get_save_data(),
		"quests": providers["quests"].get_save_data(),
		"inventory": providers["inventory"].get_save_data(),
		"equipment": providers["equipment"].get_save_data(),
		"factions": providers["factions"].get_save_data(),
		"progression": providers["progression"].get_save_data(),
		"statuses": providers["statuses"].get_save_data(),
		"time": providers["time"].get_save_data(),
		"readables": providers["readables"].get_save_data(),
		"combat": providers["combat"].get_save_data(),
		"chunks": providers["chunks"].get_save_data()
	}
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		_post_message("Could not write save file.")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	if event_bus:
		event_bus.save_completed.emit(save_path)
		event_bus.post_message("Saved to %s" % save_path)
	return true


func load_game() -> bool:
	if not _has_required_providers():
		return false
	if not FileAccess.file_exists(save_path):
		_post_message("No save file yet.")
		return false
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK:
		_post_message("Save file is invalid.")
		return false
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		_post_message("Save file is invalid.")
		return false
	var version := _valid_save_version(parsed.get("version", null))
	if version < 0 or version != CURRENT_VERSION:
		if version < 0:
			_post_message("Save version is invalid.")
		else:
			_post_message("Save version %d is not supported." % version)
		return false
	providers["world_state"].load_save_data(_dictionary_section(parsed, "world_state"))
	providers["quests"].load_save_data(_dictionary_section(parsed, "quests"))
	providers["inventory"].load_save_data(_dictionary_section(parsed, "inventory"))
	providers["equipment"].load_save_data(_dictionary_section(parsed, "equipment"))
	providers["factions"].load_save_data(_dictionary_section(parsed, "factions"))
	providers["progression"].load_save_data(_dictionary_section(parsed, "progression"))
	providers["statuses"].load_save_data(_dictionary_section(parsed, "statuses"))
	providers["time"].load_save_data(_dictionary_section(parsed, "time"))
	providers["readables"].load_save_data(_dictionary_section(parsed, "readables"))
	providers["combat"].load_save_data(_dictionary_section(parsed, "combat"))
	providers["chunks"].load_save_data(_dictionary_section(parsed, "chunks"))
	providers["player"].load_save_data(_dictionary_section(parsed, "player"))
	if providers.has("entities"):
		providers["entities"].spawn_all()
	if event_bus:
		event_bus.load_completed.emit(save_path)
		event_bus.post_message("Loaded %s" % save_path)
	return true


func _has_required_providers() -> bool:
	for provider_id in REQUIRED_PROVIDERS:
		if not providers.has(provider_id):
			_post_message("Save provider missing: %s." % provider_id)
			return false
	return true


func _post_message(text: String) -> void:
	if event_bus:
		event_bus.post_message(text)


func _dictionary_section(data: Dictionary, section_id: String) -> Dictionary:
	var section: Variant = data.get(section_id, {})
	if section is Dictionary:
		return section
	return {}


func _valid_save_version(value: Variant) -> int:
	if value is int:
		return int(value)
	if value is float and is_equal_approx(value, float(int(value))):
		return int(value)
	return -1
