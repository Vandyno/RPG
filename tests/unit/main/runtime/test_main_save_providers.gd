extends GutTest


func test_build_returns_all_save_provider_services_by_stable_key() -> void:
	var main := SaveProviderMainStub.new()

	var providers := MainSaveProviders.build(main)

	for key in [
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
	]:
		assert_true(providers.has(key))
		assert_same(providers[key], main.get(key))


class SaveProviderMainStub:
	extends RefCounted

	var player := RefCounted.new()
	var world_state := RefCounted.new()
	var quests := RefCounted.new()
	var inventory := RefCounted.new()
	var equipment := RefCounted.new()
	var spells := RefCounted.new()
	var factions := RefCounted.new()
	var progression := RefCounted.new()
	var statuses := RefCounted.new()
	var time := RefCounted.new()
	var readables := RefCounted.new()
	var combat := RefCounted.new()
	var chunks := RefCounted.new()
