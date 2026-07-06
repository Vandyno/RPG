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
	"spells",
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
		"spells": providers["spells"].get_save_data(),
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
	var parsed := _parsed_save_file()
	if parsed.is_empty():
		return false
	if not _has_supported_version(parsed):
		return false
	if not _has_required_sections(parsed):
		return false
	providers["world_state"].load_save_data(parsed["world_state"])
	providers["quests"].load_save_data(parsed["quests"])
	providers["inventory"].load_save_data(parsed["inventory"])
	providers["equipment"].load_save_data(parsed["equipment"])
	providers["spells"].load_save_data(parsed["spells"])
	providers["factions"].load_save_data(parsed["factions"])
	providers["progression"].load_save_data(parsed["progression"])
	providers["statuses"].load_save_data(parsed["statuses"])
	providers["time"].load_save_data(parsed["time"])
	providers["readables"].load_save_data(parsed["readables"])
	providers["combat"].load_save_data(parsed["combat"])
	providers["chunks"].load_save_data(parsed["chunks"])
	providers["player"].load_save_data(parsed["player"])
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


func _parsed_save_file() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		_post_message("No save file yet.")
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK:
		_post_message("Save file is invalid.")
		return {}
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		_post_message("Save file is invalid.")
		return {}
	return parsed


func _has_supported_version(data: Dictionary) -> bool:
	var version := _valid_save_version(data.get("version", null))
	if version == CURRENT_VERSION:
		return true
	if version < 0:
		_post_message("Save version is invalid.")
	else:
		_post_message("Save version %d is not supported." % version)
	return false


func _has_required_sections(data: Dictionary) -> bool:
	for section_id in REQUIRED_PROVIDERS:
		if not data.has(section_id) or not data[section_id] is Dictionary:
			_post_message("Save section is invalid: %s." % section_id)
			return false
	return true


func _post_message(text: String) -> void:
	if event_bus:
		event_bus.post_message(text)


func _valid_save_version(value: Variant) -> int:
	if value is int:
		return int(value)
	if value is float and is_equal_approx(value, float(int(value))):
		return int(value)
	return -1
