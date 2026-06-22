extends GutTest

const ConditionEvaluator = preload("res://scripts/core/condition_evaluator.gd")
const ContentDatabase = preload("res://scripts/data/content_database.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const FactionManager = preload("res://scripts/managers/faction_manager.gd")
const InventoryManager = preload("res://scripts/managers/inventory_manager.gd")
const ProgressionManager = preload("res://scripts/managers/progression_manager.gd")
const QuestManager = preload("res://scripts/managers/quest_manager.gd")
const ReadableManager = preload("res://scripts/managers/readable_manager.gd")
const TimeManager = preload("res://scripts/managers/time_manager.gd")
const WorldStateManager = preload("res://scripts/managers/world_state_manager.gd")


func test_condition_evaluator_checks_supported_conditions() -> void:
	var systems := _make_systems()
	var evaluator: ConditionEvaluator = systems["evaluator"]
	var world_state: WorldStateManager = systems["world_state"]
	var inventory: InventoryManager = systems["inventory"]
	var quests: QuestManager = systems["quests"]
	var readables: ReadableManager = systems["readables"]
	var factions: FactionManager = systems["factions"]
	var progression: ProgressionManager = systems["progression"]
	var time: TimeManager = systems["time"]

	world_state.set_flag("flag_test", true)
	world_state.discover_location("location_briarwatch_crossroads")
	inventory.add_item("item_old_toolbox", 1)
	quests.start_quest("quest_missing_tools")
	quests.set_stage("quest_missing_tools", "found_toolbox")
	readables.read_readable("readable_briarwatch_notice")
	factions.change_reputation("faction_marches_of_velcor", 5)
	progression.add_experience(20)
	assert_true(progression.spend_point("might"))
	time.advance_hours(12)

	assert_true(evaluator.evaluate({"type": "has_flag", "flag_id": "flag_test"}))
	assert_true(evaluator.evaluate({"type": "not_flag", "flag_id": "flag_missing"}))
	assert_true(evaluator.evaluate({"type": "has_item", "item_id": "item_old_toolbox", "count": 1}))
	assert_true(
		evaluator.evaluate(
			{"type": "quest_state", "quest_id": "quest_missing_tools", "state": "active"}
		)
	)
	assert_true(
		evaluator.evaluate(
			{"type": "quest_stage", "quest_id": "quest_missing_tools", "stage": "found_toolbox"}
		)
	)
	assert_true(
		evaluator.evaluate({"type": "read_readable", "readable_id": "readable_briarwatch_notice"})
	)
	assert_true(
		evaluator.evaluate(
			{"type": "location_discovered", "location_id": "location_briarwatch_crossroads"}
		)
	)
	assert_true(
		evaluator.evaluate(
			{
				"type": "faction_reputation_at_least",
				"faction_id": "faction_marches_of_velcor",
				"reputation": 5
			}
		)
	)
	assert_true(evaluator.evaluate({"type": "player_level_at_least", "level": 2}))
	assert_true(evaluator.evaluate({"type": "stat_at_least", "stat_id": "might", "rank": 1}))
	assert_true(evaluator.evaluate({"type": "time_phase", "phase": "Evening"}))
	assert_true(evaluator.evaluate({"type": "time_hour_between", "start_hour": 18, "end_hour": 6}))


func test_condition_evaluator_rejects_invalid_or_unmet_conditions() -> void:
	var systems := _make_systems()
	var evaluator: ConditionEvaluator = systems["evaluator"]

	assert_false(evaluator.evaluate({}))
	assert_false(evaluator.evaluate({"type": "unknown"}))
	assert_false(evaluator.evaluate({"type": "has_flag", "flag_id": "missing"}))
	assert_false(evaluator.evaluate({"type": "not_flag", "flag_id": ""}))
	assert_false(
		evaluator.evaluate({"type": "has_item", "item_id": "item_old_toolbox", "count": 1})
	)
	assert_false(
		evaluator.evaluate({"type": "has_item", "item_id": "item_old_toolbox", "count": "1"})
	)
	assert_false(
		evaluator.evaluate(
			{"type": "quest_state", "quest_id": "quest_missing_tools", "state": "active"}
		)
	)
	assert_false(
		evaluator.evaluate(
			{"type": "quest_stage", "quest_id": "quest_missing_tools", "stage": "started"}
		)
	)
	assert_false(
		evaluator.evaluate({"type": "read_readable", "readable_id": "readable_briarwatch_notice"})
	)
	assert_false(
		evaluator.evaluate(
			{"type": "location_discovered", "location_id": "location_briarwatch_crossroads"}
		)
	)
	assert_false(
		evaluator.evaluate(
			{
				"type": "faction_reputation_at_least",
				"faction_id": "faction_marches_of_velcor",
				"reputation": 1
			}
		)
	)
	assert_false(evaluator.evaluate({"type": "player_level_at_least", "level": 2}))
	assert_false(evaluator.evaluate({"type": "player_level_at_least", "level": "two"}))
	assert_false(evaluator.evaluate({"type": "stat_at_least", "stat_id": "might", "rank": 1}))
	assert_false(evaluator.evaluate({"type": "stat_at_least", "stat_id": "", "rank": 1}))
	assert_false(evaluator.evaluate({"type": "stat_at_least", "stat_id": "might", "rank": "one"}))
	assert_false(evaluator.evaluate({"type": "time_phase", "phase": "Night"}))
	assert_false(evaluator.evaluate({"type": "time_phase", "phase": ""}))
	assert_false(
		evaluator.evaluate({"type": "time_hour_between", "start_hour": "night", "end_hour": 6})
	)
	assert_false(evaluator.evaluate({"type": "time_hour_between", "start_hour": 18}))
	assert_false(evaluator.evaluate_all([{"type": "not_flag", "flag_id": "flag_missing"}, "bad"]))


func test_condition_evaluator_requires_all_conditions() -> void:
	var systems := _make_systems()
	var evaluator: ConditionEvaluator = systems["evaluator"]
	var inventory: InventoryManager = systems["inventory"]
	inventory.add_item("item_old_toolbox", 1)

	assert_true(evaluator.evaluate({"type": "has_item", "item_id": "item_old_toolbox"}))
	assert_false(
		evaluator.evaluate({"type": "has_item", "item_id": "item_old_toolbox", "count": "1"})
	)
	assert_true(
		evaluator.evaluate_all(
			[
				{"type": "has_item", "item_id": "item_old_toolbox", "count": 1},
				{"type": "not_flag", "flag_id": "flag_missing"}
			]
		)
	)
	assert_false(
		evaluator.evaluate_all(
			[
				{"type": "has_item", "item_id": "item_old_toolbox", "count": 2},
				{"type": "not_flag", "flag_id": "flag_missing"}
			]
		)
	)


func _make_systems() -> Dictionary:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var world_state := WorldStateManager.new()
	add_child_autofree(world_state)
	world_state.setup(bus)
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.setup(bus)
	var quests := QuestManager.new()
	add_child_autofree(quests)
	quests.setup(bus, content)
	var readables := ReadableManager.new()
	add_child_autofree(readables)
	readables.setup(bus, content, Callable())
	var factions := FactionManager.new()
	add_child_autofree(factions)
	factions.setup(bus, content)
	var progression := ProgressionManager.new()
	add_child_autofree(progression)
	progression.setup(bus)
	var time := TimeManager.new()
	add_child_autofree(time)
	time.setup(bus)
	var evaluator := ConditionEvaluator.new()
	evaluator.setup(world_state, quests, inventory, readables, factions, progression, time)
	return {
		"evaluator": evaluator,
		"world_state": world_state,
		"inventory": inventory,
		"quests": quests,
		"readables": readables,
		"factions": factions,
		"progression": progression,
		"time": time
	}
