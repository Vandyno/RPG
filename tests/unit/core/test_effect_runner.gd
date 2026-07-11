extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const EffectRunner = preload("res://scripts/core/effect_runner.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const FactionManager = preload("res://scripts/managers/content/faction_manager.gd")
const InventoryManager = preload("res://scripts/managers/actors/inventory_manager.gd")
const PlayerController = preload("res://scripts/player/player_controller.gd")
const ProgressionManager = preload("res://scripts/managers/actors/progression_manager.gd")
const QuestManager = preload("res://scripts/managers/content/quest_manager.gd")
const StatusEffectManager = preload("res://scripts/managers/actors/status_effect_manager.gd")
const TimeManager = preload("res://scripts/managers/content/time_manager.gd")
const WorldStateManager = preload("res://scripts/managers/world/world_state_manager.gd")


func test_effect_runner_applies_supported_effects() -> void:
	var systems := _make_systems()
	var runner: EffectRunner = systems["runner"]
	var world_state: WorldStateManager = systems["world_state"]
	var inventory: InventoryManager = systems["inventory"]
	var quests: QuestManager = systems["quests"]
	var player: PlayerController = systems["player"]
	var factions: FactionManager = systems["factions"]
	var progression: ProgressionManager = systems["progression"]
	var statuses: StatusEffectManager = systems["statuses"]
	var time: TimeManager = systems["time"]

	assert_true(runner.apply({"type": "set_flag", "flag_id": "flag_test", "value": true}))
	assert_true(world_state.has_flag("flag_test"))
	assert_true(runner.apply({"type": "set_flag", "flag_id": "flag_default"}))
	assert_true(world_state.has_flag("flag_default"))

	assert_true(runner.apply({"type": "add_item", "item_id": "item_gold_coin", "count": 5}))
	assert_eq(inventory.get_count("item_gold_coin"), 5)
	assert_true(runner.apply({"type": "add_item", "item_id": "item_gold_coin"}))
	assert_eq(inventory.get_count("item_gold_coin"), 6)
	assert_true(runner.apply({"type": "remove_item", "item_id": "item_gold_coin", "count": 2}))
	assert_eq(inventory.get_count("item_gold_coin"), 4)

	assert_true(runner.apply({"type": "start_quest", "quest_id": "quest_missing_tools"}))
	assert_eq(quests.get_quest_state("quest_missing_tools"), "active")
	assert_true(
		runner.apply(
			{"type": "set_quest_stage", "quest_id": "quest_missing_tools", "stage": "found_toolbox"}
		)
	)
	assert_eq(quests.quests["quest_missing_tools"]["stage"], "found_toolbox")
	assert_true(runner.apply({"type": "complete_quest", "quest_id": "quest_missing_tools"}))
	assert_eq(quests.get_quest_state("quest_missing_tools"), "completed")
	assert_eq(inventory.get_count("item_gold_coin"), 29)
	assert_eq(factions.get_reputation("faction_marches_of_velcor"), 5)
	assert_eq(progression.level, 2)
	assert_eq(progression.experience, 0)
	assert_eq(progression.skill_points, 1)
	assert_false(runner.apply({"type": "complete_quest", "quest_id": "quest_missing_tools"}))
	assert_eq(inventory.get_count("item_gold_coin"), 29)
	assert_eq(factions.get_reputation("faction_marches_of_velcor"), 5)
	assert_eq(progression.level, 2)
	assert_true(
		runner.apply(
			{"type": "change_reputation", "faction_id": "faction_road_bandits", "amount": -5}
		)
	)
	assert_eq(factions.get_reputation("faction_road_bandits"), -5)
	assert_true(runner.apply({"type": "add_experience", "amount": 10}))
	assert_eq(progression.experience, 10)
	assert_true(runner.apply({"type": "apply_status", "status_id": "status_test_focus"}))
	assert_eq(statuses.get_remaining_charges("status_test_focus"), 2)
	assert_true(runner.apply({"type": "advance_time", "hours": 2, "minutes": 30}))
	assert_eq(time.get_summary(), "Day 1, 10:30 (Morning)")

	assert_true(
		runner.apply({"type": "discover_location", "location_id": "location_briarwatch_crossroads"})
	)
	assert_true(world_state.discovered_locations.has("location_briarwatch_crossroads"))
	player.apply_damage(40)
	assert_true(runner.apply({"type": "heal_player", "amount": 25}))
	assert_eq(player.health, 85)

	var failure_systems := _make_systems()
	var failure_runner: EffectRunner = failure_systems["runner"]
	var failure_quests: QuestManager = failure_systems["quests"]
	assert_true(failure_runner.apply({"type": "fail_quest", "quest_id": "quest_missing_tools"}))
	assert_eq(failure_quests.get_quest_state("quest_missing_tools"), "failed")
	assert_false(failure_runner.apply({"type": "fail_quest", "quest_id": "quest_missing_tools"}))
	assert_false(
		failure_runner.apply({"type": "complete_quest", "quest_id": "quest_missing_tools"})
	)


func test_effect_runner_rejects_unknown_or_invalid_effects() -> void:
	var systems := _make_systems()
	var runner: EffectRunner = systems["runner"]
	var inventory: InventoryManager = systems["inventory"]
	var world_state: WorldStateManager = systems["world_state"]
	inventory.add_item("item_gold_coin", 1)

	assert_false(runner.apply({}))
	assert_false(runner.apply({"type": "unknown"}))
	assert_false(runner.apply({"type": "set_flag", "flag_id": ""}))
	assert_false(runner.apply({"type": "set_flag", "flag_id": "flag_bad", "value": "false"}))
	assert_false(world_state.has_flag("flag_bad"))
	assert_false(runner.apply({"type": "start_quest", "quest_id": ""}))
	assert_false(runner.apply({"type": "start_quest", "quest_id": "missing_quest"}))
	assert_false(
		runner.apply(
			{"type": "set_quest_stage", "quest_id": "quest_missing_tools", "stage": "missing"}
		)
	)
	assert_false(runner.apply({"type": "fail_quest", "quest_id": ""}))
	assert_false(runner.apply({"type": "add_item", "item_id": "item_gold_coin", "count": 0}))
	assert_false(runner.apply({"type": "add_item", "item_id": "item_gold_coin", "count": "5"}))
	assert_eq(inventory.get_count("item_gold_coin"), 1)
	assert_false(runner.apply({"type": "remove_item", "item_id": "item_gold_coin", "count": 2}))
	assert_false(runner.apply({"type": "remove_item", "item_id": "item_gold_coin", "count": "1"}))
	assert_eq(inventory.get_count("item_gold_coin"), 1)
	assert_false(runner.apply({"type": "discover_location", "location_id": ""}))
	assert_false(runner.apply({"type": "heal_player"}))
	assert_false(runner.apply({"type": "heal_player", "amount": 0}))
	assert_false(runner.apply({"type": "heal_player", "amount": "full"}))
	assert_false(runner.apply({"type": "change_reputation", "faction_id": "", "amount": 1}))
	assert_false(
		runner.apply(
			{"type": "change_reputation", "faction_id": "faction_marches_of_velcor", "amount": 0}
		)
	)
	assert_false(
		runner.apply(
			{
				"type": "change_reputation",
				"faction_id": "faction_marches_of_velcor",
				"amount": "good"
			}
		)
	)
	assert_false(runner.apply({"type": "add_experience", "amount": 0}))
	assert_false(runner.apply({"type": "add_experience", "amount": "ten"}))
	assert_false(runner.apply({"type": "advance_time"}))
	assert_false(runner.apply({"type": "advance_time", "hours": 0}))
	assert_false(runner.apply({"type": "advance_time", "minutes": "soon"}))
	assert_false(runner.apply({"type": "apply_status", "status_id": ""}))
	assert_false(runner.apply({"type": "apply_status", "status_id": "missing_status"}))
	assert_false(
		runner.apply({"type": "apply_status", "status_id": "status_test_focus", "charges": "two"})
	)

	assert_true(runner.apply({"type": "discover_location", "location_id": "location_test"}))
	assert_false(runner.apply({"type": "discover_location", "location_id": "location_test"}))
	assert_true(world_state.discovered_locations.has("location_test"))


func _make_systems() -> Dictionary:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	content.status_effects = {
		"status_test_focus": {"name": "Test Focus", "attack_charges": 2, "damage_bonus": 3}
	}
	var world_state := WorldStateManager.new()
	add_child_autofree(world_state)
	world_state.setup(bus)
	var inventory := InventoryManager.new()
	add_child_autofree(inventory)
	inventory.setup(bus, content)
	var quests := QuestManager.new()
	add_child_autofree(quests)
	quests.setup(bus, content)
	var factions := FactionManager.new()
	add_child_autofree(factions)
	factions.setup(bus, content)
	var progression := ProgressionManager.new()
	add_child_autofree(progression)
	progression.setup(bus)
	var statuses := StatusEffectManager.new()
	add_child_autofree(statuses)
	statuses.setup(bus, content)
	var time := TimeManager.new()
	add_child_autofree(time)
	time.setup(bus)
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(bus, null)
	var runner := EffectRunner.new()
	runner.setup(
		EffectRunner.Dependencies.new(
			{
				"world_state": world_state,
				"quests": quests,
				"inventory": inventory,
				"content": content,
				"player": player,
				"factions": factions,
				"progression": progression,
				"time": time,
				"statuses": statuses
			}
		)
	)
	return {
		"runner": runner,
		"world_state": world_state,
		"inventory": inventory,
		"quests": quests,
		"factions": factions,
		"progression": progression,
		"statuses": statuses,
		"time": time,
		"player": player
	}
