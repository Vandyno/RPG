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
const OPTIONAL_PROVIDERS := ["entities", "civilian_schedules", "crime", "companions"]

var event_bus: EventBus
var providers: Dictionary = {}
var save_path := DEFAULT_SAVE_PATH


class SaveResult:
	var ok := false
	var code := ""
	var message := ""
	var path := ""

	func _init(
		success: bool, result_code: String, result_message: String, result_path: String
	) -> void:
		ok = success
		code = result_code
		message = result_message
		path = result_path


class LoadResult:
	var ok := false
	var code := ""
	var message := ""
	var path := ""
	var data: Dictionary = {}

	func _init(
		success: bool,
		result_code: String,
		result_message: String,
		result_path: String,
		result_data: Dictionary = {}
	) -> void:
		ok = success
		code = result_code
		message = result_message
		path = result_path
		data = result_data


func setup(bus: EventBus, save_providers: Dictionary, path: String = DEFAULT_SAVE_PATH) -> void:
	event_bus = bus
	providers = save_providers
	save_path = path


func save_game() -> SaveResult:
	var missing_provider := _missing_required_provider()
	if not missing_provider.is_empty():
		return _save_failure(
			"missing_provider", "Save provider missing: %s." % missing_provider
		)
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
	for provider_id in OPTIONAL_PROVIDERS:
		if providers.has(provider_id):
			data[provider_id] = providers[provider_id].get_save_data()
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		var open_error := FileAccess.get_open_error()
		return _save_failure(
			"write_failed",
			"Could not write save file at %s: %s." % [save_path, error_string(open_error)]
		)
	file.store_string(JSON.stringify(data, "\t"))
	var result := SaveResult.new(true, "ok", "Saved to %s" % save_path, save_path)
	if event_bus:
		event_bus.save_completed.emit(save_path)
		event_bus.post_message(result.message)
	return result


func load_game() -> LoadResult:
	var missing_provider := _missing_required_provider()
	if not missing_provider.is_empty():
		var failure := _load_failure(
			"missing_provider", "Save provider missing: %s." % missing_provider
		)
		_post_message(failure.message)
		return failure
	var parsed_result := _parsed_save_file()
	if not parsed_result.ok:
		_post_message(parsed_result.message)
		return parsed_result
	var parsed := parsed_result.data
	var version_result := _supported_version_result(parsed)
	if not version_result.ok:
		_post_message(version_result.message)
		return version_result
	var sections_result := _required_sections_result(parsed)
	if not sections_result.ok:
		_post_message(sections_result.message)
		return sections_result
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
	for provider_id in OPTIONAL_PROVIDERS:
		if providers.has(provider_id) and parsed.has(provider_id) and parsed[provider_id] is Dictionary:
			providers[provider_id].load_save_data(parsed[provider_id])
	providers["player"].load_save_data(parsed["player"])
	var result := LoadResult.new(true, "ok", "Loaded %s" % save_path, save_path)
	if event_bus:
		event_bus.load_completed.emit(save_path)
		event_bus.post_message(result.message)
	return result


func _missing_required_provider() -> String:
	for provider_id in REQUIRED_PROVIDERS:
		if not providers.has(provider_id):
			return provider_id
	return ""


func _parsed_save_file() -> LoadResult:
	if not FileAccess.file_exists(save_path):
		return _load_failure("missing_file", "No save file yet at %s." % save_path)
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return _load_failure(
			"read_failed",
			"Could not read save file %s: %s." % [save_path, error_string(FileAccess.get_open_error())]
		)
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		return _load_failure(
			"invalid_json",
			(
				"Save file is invalid at %s line %d: %s."
				% [save_path, json.get_error_line(), json.get_error_message()]
			)
		)
	var parsed: Variant = json.data
	if not parsed is Dictionary:
		return _load_failure("invalid_root", "Save file is invalid at %s." % save_path)
	return LoadResult.new(true, "ok", "", save_path, parsed)


func _supported_version_result(data: Dictionary) -> LoadResult:
	var version := _valid_save_version(data.get("version", null))
	if version == CURRENT_VERSION:
		return LoadResult.new(true, "ok", "", save_path)
	if version < 0:
		return _load_failure("invalid_version", "Save version is invalid.")
	return _load_failure("unsupported_version", "Save version %d is not supported." % version)


func _required_sections_result(data: Dictionary) -> LoadResult:
	for section_id in REQUIRED_PROVIDERS:
		if not data.has(section_id) or not data[section_id] is Dictionary:
			return _load_failure("invalid_section", "Save section is invalid: %s." % section_id)
	return LoadResult.new(true, "ok", "", save_path)


func _save_failure(code: String, message: String) -> SaveResult:
	_post_message(message)
	return SaveResult.new(false, code, message, save_path)


func _load_failure(code: String, message: String) -> LoadResult:
	return LoadResult.new(false, code, message, save_path)


func _post_message(text: String) -> void:
	if event_bus:
		event_bus.post_message(text)


func _valid_save_version(value: Variant) -> int:
	if value is int:
		return int(value)
	if value is float and is_equal_approx(value, float(int(value))):
		return int(value)
	return -1
