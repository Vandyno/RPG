extends GutTest

const ConditionEvaluator = preload("res://scripts/core/condition_evaluator.gd")
const ContentDatabase = preload("res://scripts/data/content_database.gd")
const DialogueManager = preload("res://scripts/managers/content/dialogue_manager.gd")
const EffectRunner = preload("res://scripts/core/effect_runner.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const FactionManager = preload("res://scripts/managers/content/faction_manager.gd")
const InventoryManager = preload("res://scripts/managers/actors/inventory_manager.gd")
const ProgressionManager = preload("res://scripts/managers/actors/progression_manager.gd")
const QuestManager = preload("res://scripts/managers/content/quest_manager.gd")
const ReadableManager = preload("res://scripts/managers/content/readable_manager.gd")
const WorldStateManager = preload("res://scripts/managers/world/world_state_manager.gd")


func test_dialogue_manager_resolves_first_valid_line_and_applies_effects() -> void:
	var systems := _make_systems()
	var manager: DialogueManager = systems["dialogues"]
	var quests: QuestManager = systems["quests"]

	var first_line := manager.resolve_dialogue("dialogue_harrow_venn", "Harrow Venn")

	assert_eq(first_line.get("line_id", ""), "start_missing_tools")
	assert_true(first_line.get("text", "").contains("old toolbox back"))
	assert_eq(first_line.get("choices", []).size(), 2)
	assert_eq(quests.get_quest_state("quest_missing_tools"), "inactive")

	var choice_result := manager.apply_choice(first_line.get("choices", [])[0])

	assert_eq(choice_result.get("choice_id", ""), "accept_missing_tools")
	assert_true(choice_result.get("response", "").contains("brass latch"))
	assert_eq(quests.get_quest_state("quest_missing_tools"), "active")


func test_dialogue_manager_respects_conditions_for_active_complete_and_after_lines() -> void:
	var systems := _make_systems()
	var manager: DialogueManager = systems["dialogues"]
	var inventory: InventoryManager = systems["inventory"]
	var quests: QuestManager = systems["quests"]
	var world_state: WorldStateManager = systems["world_state"]
	var factions: FactionManager = systems["factions"]
	var progression: ProgressionManager = systems["progression"]

	quests.start_quest("quest_missing_tools")
	var active_line := manager.resolve_dialogue("dialogue_harrow_venn", "Harrow Venn")
	assert_eq(active_line.get("line_id", ""), "active_missing_tools")

	inventory.add_item("item_old_toolbox", 1)
	var complete_line := manager.resolve_dialogue("dialogue_harrow_venn", "Harrow Venn")
	assert_eq(complete_line.get("line_id", ""), "complete_missing_tools")
	assert_eq(quests.get_quest_state("quest_missing_tools"), "completed")
	assert_false(inventory.has_item("item_old_toolbox"))
	assert_eq(inventory.get_count("item_gold_coin"), 25)
	assert_eq(factions.get_reputation("faction_marches_of_velcor"), 5)
	assert_eq(progression.level, 2)
	assert_true(world_state.has_flag("flag_blacksmith_tools_returned"))

	var after_line := manager.resolve_dialogue("dialogue_harrow_venn", "Harrow Venn")
	assert_eq(after_line.get("line_id", ""), "after_complete_missing_tools")


func test_dialogue_preview_reports_line_effects_without_applying_them() -> void:
	var systems := _make_systems()
	var manager: DialogueManager = systems["dialogues"]
	var inventory: InventoryManager = systems["inventory"]
	var quests: QuestManager = systems["quests"]

	quests.start_quest("quest_missing_tools")
	inventory.add_item("item_old_toolbox", 1)

	var preview := manager.preview_dialogue("dialogue_harrow_venn", "Harrow Venn")

	assert_eq(preview.get("line_id", ""), "complete_missing_tools")
	assert_eq(preview.get("effects", []).size(), 3)
	assert_eq(quests.get_quest_state("quest_missing_tools"), "active")
	assert_true(inventory.has_item("item_old_toolbox"))


func test_dialogue_manager_handles_missing_or_unmatched_dialogue() -> void:
	var systems := _make_systems()
	var manager: DialogueManager = systems["dialogues"]

	assert_eq(manager.resolve_dialogue("missing_dialogue"), {})

	systems["content"].dialogues["dialogue_unmatched"] = {
		"id": "dialogue_unmatched",
		"lines":
		[
			{
				"id": "requires_flag",
				"speaker": "Nobody",
				"text": "Hidden",
				"conditions": [{"type": "has_flag", "flag_id": "flag_missing"}]
			}
		]
	}

	assert_eq(manager.resolve_dialogue("dialogue_unmatched"), {})


func test_dialogue_manager_uses_readable_conditioned_lines() -> void:
	var systems := _make_systems()
	var manager: DialogueManager = systems["dialogues"]
	var readables: ReadableManager = systems["readables"]

	var default_line := manager.resolve_dialogue("dialogue_maera_pike", "Maera Pike")
	assert_eq(default_line.get("line_id", ""), "shop_greeting")

	readables.read_readable("readable_briarwatch_notice")
	var noticed_line := manager.resolve_dialogue("dialogue_maera_pike", "Maera Pike")

	assert_eq(noticed_line.get("line_id", ""), "notice_read_greeting")
	assert_true(noticed_line.get("text", "").contains("warden's notice"))


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
	var effects := EffectRunner.new()
	effects.setup(
		EffectRunner.Dependencies.new(
			{
				"world_state": world_state,
				"quests": quests,
				"inventory": inventory,
				"content": content,
				"factions": factions,
				"progression": progression
			}
		)
	)
	var conditions := ConditionEvaluator.new()
	conditions.setup(
		ConditionEvaluator.Services.new(
			{
				"world_state": world_state,
				"quests": quests,
				"inventory": inventory,
				"readables": readables,
				"factions": factions,
				"progression": progression
			}
		)
	)
	var dialogues := DialogueManager.new()
	add_child_autofree(dialogues)
	dialogues.setup(content, conditions, effects)
	return {
		"content": content,
		"world_state": world_state,
		"inventory": inventory,
		"quests": quests,
		"readables": readables,
		"factions": factions,
		"progression": progression,
		"dialogues": dialogues
	}
