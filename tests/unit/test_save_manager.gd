extends GutTest

const SaveManager = preload("res://scripts/managers/save_manager.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")

const TEST_SAVE_PATH := "user://test_save_manager.json"


class ProviderStub:
	var save_payload: Dictionary = {}
	var loaded_payload: Dictionary = {}

	func _init(payload: Dictionary = {}) -> void:
		save_payload = payload.duplicate(true)

	func get_save_data() -> Dictionary:
		return save_payload.duplicate(true)

	func load_save_data(data: Dictionary) -> void:
		loaded_payload = data.duplicate(true)


class EntityProviderStub:
	var spawn_count := 0

	func spawn_all() -> void:
		spawn_count += 1


func before_each() -> void:
	_remove_test_save()


func after_each() -> void:
	_remove_test_save()


func test_save_and_load_round_trips_all_system_sections() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var messages: Array[String] = []
	var saves: Array[String] = []
	var loads: Array[String] = []
	bus.message_posted.connect(func(text: String) -> void: messages.append(text))
	bus.save_completed.connect(func(path: String) -> void: saves.append(path))
	bus.load_completed.connect(func(path: String) -> void: loads.append(path))

	var providers := _provider_set()
	var manager := SaveManager.new()
	add_child_autofree(manager)
	manager.setup(bus, providers, TEST_SAVE_PATH)

	assert_true(manager.save_game())
	assert_true(FileAccess.file_exists(TEST_SAVE_PATH))
	assert_eq(saves, [TEST_SAVE_PATH])

	var parsed: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEST_SAVE_PATH))
	assert_eq(int(parsed.get("version", 0)), 1)
	assert_eq(int(parsed["player"]["health"]), 77)
	assert_eq(parsed["equipment"]["equipped"]["weapon"], "item_road_hatchet")
	assert_eq(parsed["spells"]["assigned"]["ability_1"], "spell_fire_blast")
	assert_eq(int(parsed["factions"]["reputation"]["faction_marches_of_velcor"]), 5)
	assert_eq(int(parsed["progression"]["level"]), 2)
	assert_false(parsed["progression"].has("stats"))
	assert_eq(int(parsed["statuses"]["active"][0]["charges"]), 2)
	assert_eq(int(parsed["time"]["day"]), 3)
	assert_eq(int(parsed["time"]["minute_of_day"]), 1260)
	assert_eq(int(parsed["combat"]["health_by_entity_id"]["enemy"]), 6)

	assert_true(manager.load_game())
	assert_eq(loads, [TEST_SAVE_PATH])
	assert_true(messages.back().contains("Loaded"))
	assert_eq(int(providers["player"].loaded_payload["health"]), 77)
	assert_eq(providers["world_state"].loaded_payload, {"flags": {"flag": true}})
	assert_eq(providers["quests"].loaded_payload, {"quest": {"state": "active"}})
	assert_eq(providers["inventory"].loaded_payload["items"][0]["item_id"], "coin")
	assert_eq(int(providers["inventory"].loaded_payload["items"][0]["count"]), 3)
	assert_eq(providers["equipment"].loaded_payload, {"equipped": {"weapon": "item_road_hatchet"}})
	assert_eq(providers["spells"].loaded_payload, {"assigned": {"ability_1": "spell_fire_blast"}})
	assert_eq(
		int(providers["factions"].loaded_payload["reputation"]["faction_marches_of_velcor"]), 5
	)
	assert_eq(int(providers["progression"].loaded_payload["level"]), 2)
	assert_eq(int(providers["progression"].loaded_payload["experience"]), 7)
	assert_false(providers["progression"].loaded_payload.has("stats"))
	assert_eq(providers["statuses"].loaded_payload["active"][0]["status_id"], "status_road_focus")
	assert_eq(int(providers["statuses"].loaded_payload["active"][0]["charges"]), 2)
	assert_eq(int(providers["time"].loaded_payload["day"]), 3)
	assert_eq(int(providers["time"].loaded_payload["minute_of_day"]), 1260)
	assert_eq(providers["readables"].loaded_payload, {"read": ["notice"]})
	assert_eq(int(providers["combat"].loaded_payload["health_by_entity_id"]["enemy"]), 6)
	assert_eq(providers["chunks"].loaded_payload, {"surface:0:0": {"removed_entities": []}})
	assert_eq(providers["entities"].spawn_count, 1)


func test_load_missing_save_file_reports_failure() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var messages: Array[String] = []
	bus.message_posted.connect(func(text: String) -> void: messages.append(text))
	var manager := SaveManager.new()
	add_child_autofree(manager)
	manager.setup(bus, _provider_set(), TEST_SAVE_PATH)

	assert_false(manager.load_game())
	assert_true(messages.back().contains("No save file"))


func test_missing_required_provider_reports_failure() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var messages: Array[String] = []
	bus.message_posted.connect(func(text: String) -> void: messages.append(text))
	var providers := _provider_set()
	providers.erase("combat")
	var manager := SaveManager.new()
	add_child_autofree(manager)
	manager.setup(bus, providers, TEST_SAVE_PATH)

	assert_false(manager.save_game())
	assert_true(messages.back().contains("combat"))


func test_unsupported_save_version_reports_failure_without_loading() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var messages: Array[String] = []
	bus.message_posted.connect(func(text: String) -> void: messages.append(text))
	var providers := _provider_set()
	var manager := SaveManager.new()
	add_child_autofree(manager)
	manager.setup(bus, providers, TEST_SAVE_PATH)
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": SaveManager.CURRENT_VERSION + 1}))
	file = null

	assert_false(manager.load_game())
	assert_true(messages.back().contains("not supported"))
	assert_eq(providers["player"].loaded_payload, {})
	assert_eq(providers["entities"].spawn_count, 0)


func test_malformed_save_version_reports_failure_without_loading() -> void:
	for malformed_version in ["1", 1.5, null]:
		_remove_test_save()
		var bus := EventBus.new()
		add_child_autofree(bus)
		var messages: Array[String] = []
		bus.message_posted.connect(func(text: String) -> void: messages.append(text))
		var providers := _provider_set()
		var manager := SaveManager.new()
		add_child_autofree(manager)
		manager.setup(bus, providers, TEST_SAVE_PATH)
		var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
		file.store_string(JSON.stringify({"version": malformed_version, "player": {"health": 1}}))
		file = null

		assert_false(manager.load_game())
		assert_true(messages.back().contains("version is invalid"))
		assert_eq(providers["player"].loaded_payload, {})
		assert_eq(providers["entities"].spawn_count, 0)


func test_malformed_required_save_sections_fail_without_loading() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var messages: Array[String] = []
	var loads: Array[String] = []
	bus.message_posted.connect(func(text: String) -> void: messages.append(text))
	bus.load_completed.connect(func(path: String) -> void: loads.append(path))
	var providers := _provider_set()
	var manager := SaveManager.new()
	add_child_autofree(manager)
	manager.setup(bus, providers, TEST_SAVE_PATH)
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string(
		JSON.stringify(
			{
				"version": SaveManager.CURRENT_VERSION,
				"player": "bad",
				"world_state": [],
				"quests": 12,
				"inventory": false,
				"equipment": "bad",
				"factions": "bad",
				"progression": "bad",
				"statuses": "bad",
				"time": "bad",
				"readables": "bad",
				"combat": null,
				"chunks": "bad"
			}
		)
	)
	file = null

	assert_false(manager.load_game())
	assert_true(messages.back().contains("Save section is invalid: player"))
	assert_eq(loads, [])
	assert_eq(providers["player"].loaded_payload, {})
	assert_eq(providers["world_state"].loaded_payload, {})
	assert_eq(providers["quests"].loaded_payload, {})
	assert_eq(providers["inventory"].loaded_payload, {})
	assert_eq(providers["equipment"].loaded_payload, {})
	assert_eq(providers["spells"].loaded_payload, {})
	assert_eq(providers["factions"].loaded_payload, {})
	assert_eq(providers["progression"].loaded_payload, {})
	assert_eq(providers["statuses"].loaded_payload, {})
	assert_eq(providers["time"].loaded_payload, {})
	assert_eq(providers["readables"].loaded_payload, {})
	assert_eq(providers["combat"].loaded_payload, {})
	assert_eq(providers["chunks"].loaded_payload, {})
	assert_eq(providers["entities"].spawn_count, 0)


func test_missing_required_save_section_fails_without_loading() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var messages: Array[String] = []
	var loads: Array[String] = []
	bus.message_posted.connect(func(text: String) -> void: messages.append(text))
	bus.load_completed.connect(func(path: String) -> void: loads.append(path))
	var providers := _provider_set()
	var manager := SaveManager.new()
	add_child_autofree(manager)
	manager.setup(bus, providers, TEST_SAVE_PATH)
	var save_data := _complete_save_data()
	save_data.erase("inventory")
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file = null

	assert_false(manager.load_game())
	assert_true(messages.back().contains("Save section is invalid: inventory"))
	assert_eq(loads, [])
	assert_eq(providers["player"].loaded_payload, {})
	assert_eq(providers["inventory"].loaded_payload, {})
	assert_eq(providers["entities"].spawn_count, 0)


func _provider_set() -> Dictionary:
	return {
		"player": ProviderStub.new({"health": 77}),
		"world_state": ProviderStub.new({"flags": {"flag": true}}),
		"quests": ProviderStub.new({"quest": {"state": "active"}}),
		"inventory": ProviderStub.new({"items": [{"item_id": "coin", "count": 3}]}),
		"equipment": ProviderStub.new({"equipped": {"weapon": "item_road_hatchet"}}),
		"spells": ProviderStub.new({"assigned": {"ability_1": "spell_fire_blast"}}),
		"factions": ProviderStub.new({"reputation": {"faction_marches_of_velcor": 5}}),
		"progression":
		ProviderStub.new({"level": 2, "experience": 7, "skill_points": 1}),
		"statuses":
		ProviderStub.new({"active": [{"status_id": "status_road_focus", "charges": 2}]}),
		"time": ProviderStub.new({"day": 3, "minute_of_day": 1260}),
		"readables": ProviderStub.new({"read": ["notice"]}),
		"combat": ProviderStub.new({"health_by_entity_id": {"enemy": 6}}),
		"chunks": ProviderStub.new({"surface:0:0": {"removed_entities": []}}),
		"entities": EntityProviderStub.new()
	}


func _complete_save_data() -> Dictionary:
	return {
		"version": SaveManager.CURRENT_VERSION,
		"player": {"health": 77},
		"world_state": {"flags": {"flag": true}},
		"quests": {"quest": {"state": "active"}},
		"inventory": {"items": [{"item_id": "coin", "count": 3}]},
		"equipment": {"equipped": {"weapon": "item_road_hatchet"}},
		"spells": {"assigned": {"ability_1": "spell_fire_blast"}},
		"factions": {"reputation": {"faction_marches_of_velcor": 5}},
		"progression": {"level": 2, "experience": 7, "skill_points": 1},
		"statuses": {"active": [{"status_id": "status_road_focus", "charges": 2}]},
		"time": {"day": 3, "minute_of_day": 1260},
		"readables": {"read": ["notice"]},
		"combat": {"health_by_entity_id": {"enemy": 6}},
		"chunks": {"surface:0:0": {"removed_entities": []}}
	}


func _remove_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE_PATH))
