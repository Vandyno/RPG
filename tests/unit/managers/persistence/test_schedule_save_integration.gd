extends GutTest

const SaveManager = preload("res://scripts/managers/persistence/save_manager.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")

const SAVE_PATH := "user://schedule_save_integration.json"


class Provider:
	var payload: Dictionary
	var loaded: Dictionary = {}

	func _init(value: Dictionary = {}) -> void:
		payload = value

	func get_save_data() -> Dictionary:
		return payload.duplicate(true)

	func load_save_data(data: Dictionary) -> void:
		loaded = data.duplicate(true)


func before_each() -> void:
	_remove_save()


func after_each() -> void:
	_remove_save()


func test_save_manager_round_trips_optional_civilian_schedule_section() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var schedule := Provider.new({
		"states": {"npc_northgate_farmer": {"activity": "work", "global_tile": [-3148, -3843]}},
		"reservations": {},
		"last_absolute_minute": 1800
	})
	var providers := {}
	for id in SaveManager.REQUIRED_PROVIDERS:
		providers[id] = Provider.new({"id": id})
	providers["civilian_schedules"] = schedule
	var manager := SaveManager.new()
	add_child_autofree(manager)
	manager.setup(bus, providers, SAVE_PATH)

	assert_true(manager.save_game().ok)
	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	assert_eq(parsed["civilian_schedules"]["states"]["npc_northgate_farmer"]["activity"], "work")
	assert_true(manager.load_game().ok)
	var loaded_tile: Array = schedule.loaded["states"]["npc_northgate_farmer"]["global_tile"]
	assert_eq(Vector2i(int(loaded_tile[0]), int(loaded_tile[1])), Vector2i(-3148, -3843))


func _remove_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
