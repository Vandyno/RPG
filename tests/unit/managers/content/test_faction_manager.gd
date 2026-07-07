extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const FactionManager = preload("res://scripts/managers/content/faction_manager.gd")


func test_faction_reputation_changes_clamps_summarizes_and_saves() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var changed: Array[String] = []
	bus.faction_reputation_changed.connect(
		func(faction_id: String, reputation: int) -> void:
			changed.append("%s:%d" % [faction_id, reputation])
	)
	var factions := _make_factions(bus)

	assert_eq(factions.get_reputation("faction_marches_of_velcor"), 0)
	assert_true(factions.change_reputation("faction_marches_of_velcor", 7))
	assert_true(factions.change_reputation("faction_marches_of_velcor", 200))
	assert_eq(factions.get_reputation("faction_marches_of_velcor"), 100)
	assert_false(factions.change_reputation("faction_marches_of_velcor", 10))
	assert_true(factions.change_reputation("faction_road_bandits", -5))
	assert_true(factions.is_reputation_at_least("faction_marches_of_velcor", 50))
	assert_true(factions.get_summary().contains("Marches of Velcor +100"))
	assert_eq(
		changed,
		["faction_marches_of_velcor:7", "faction_marches_of_velcor:100", "faction_road_bandits:-5"]
	)
	assert_eq(
		factions.get_save_data(),
		{"reputation": {"faction_marches_of_velcor": 100, "faction_road_bandits": -5}}
	)


func test_faction_load_ignores_unknown_malformed_and_default_entries() -> void:
	var factions := _make_factions(null)

	factions.load_save_data(
		{
			"reputation":
			{
				"faction_marches_of_velcor": 5,
				"faction_road_bandits": -200,
				"missing": 9,
				"bad": "many"
			}
		}
	)

	assert_eq(factions.get_reputation("faction_marches_of_velcor"), 5)
	assert_eq(factions.get_reputation("faction_road_bandits"), -100)
	assert_eq(
		factions.get_save_data(),
		{"reputation": {"faction_marches_of_velcor": 5, "faction_road_bandits": -100}}
	)

	factions.load_save_data({"reputation": "bad"})
	assert_eq(factions.get_save_data(), {"reputation": {}})


func _make_factions(bus) -> FactionManager:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var factions := FactionManager.new()
	add_child_autofree(factions)
	factions.setup(bus, content)
	return factions
