extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const QuestManager = preload("res://scripts/managers/content/quest_manager.gd")

var content: ContentDatabase
var event_bus: EventBus
var quests: QuestManager
var changed_quests: Array[String]


func before_each() -> void:
	content = ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	event_bus = EventBus.new()
	add_child_autofree(event_bus)
	changed_quests = []
	event_bus.quest_changed.connect(
		func(quest_id: String, _state: Dictionary) -> void: changed_quests.append(quest_id)
	)
	quests = QuestManager.new()
	add_child_autofree(quests)
	quests.setup(event_bus, content)


func test_lifecycle_blocks_invalid_restarts_and_terminal_stage_changes() -> void:
	assert_false(quests.start_quest(""))
	assert_false(quests.start_quest("quest_missing"))
	assert_true(quests.start_quest("quest_missing_tools"))
	assert_false(quests.start_quest("quest_missing_tools"))
	assert_true(quests.set_stage("quest_missing_tools", "found_toolbox"))
	assert_false(quests.set_stage("quest_missing_tools", "missing_stage"))
	assert_true(quests.complete_quest("quest_missing_tools"))
	assert_false(quests.fail_quest("quest_missing_tools"))
	assert_false(quests.set_stage("quest_missing_tools", "started"))

	assert_eq(quests.get_quest_state("quest_missing_tools"), "completed")
	assert_eq(
		changed_quests,
		["quest_missing_tools", "quest_missing_tools", "quest_missing_tools"]
	)


func test_load_save_data_regenerates_objectives_and_ignores_unknown_entries() -> void:
	quests.load_save_data(
		{
			"quest_missing_tools":
			{"state": "active", "stage": "missing_stage", "objectives": {"fake": "Bad"}},
			"quest_unknown": {"state": "active", "stage": "started"},
			"quest_bad_state": {"state": "nonsense", "stage": "started"},
			"": {"state": "active", "stage": "started"}
		}
	)

	assert_eq(quests.quests.keys(), ["quest_missing_tools"])
	assert_eq(quests.quests["quest_missing_tools"]["stage"], "started")
	assert_eq(
		quests.get_active_objectives_data()[0],
		{
			"quest_id": "quest_missing_tools",
			"title": "The Missing Tools",
			"stage": "started",
			"objective_id": "find_toolbox",
			"text": "Find Harrow's old toolbox by the west road.",
			"target_id": "pickup_old_toolbox"
		}
	)


func test_live_state_sanitizes_summary_and_save_output() -> void:
	quests.quests = {
		"quest_missing_tools": {"state": "active", "stage": "bad", "objectives": "bad"},
		"quest_unknown": {"state": "completed"},
		"quest_bad_state": {"state": "nonsense", "stage": "started"},
		"": {"state": "active", "stage": "started"}
	}

	assert_eq(
		quests.get_active_summary(), ["The Missing Tools: Find Harrow's old toolbox by the west road."]
	)
	assert_eq(
		quests.get_save_data(),
		{
			"quest_missing_tools":
			{
				"state": "active",
				"stage": "started",
				"objectives":
				{
					"find_toolbox":
					{
						"text": "Find Harrow's old toolbox by the west road.",
						"target_id": "pickup_old_toolbox"
					}
				}
			}
		}
	)
