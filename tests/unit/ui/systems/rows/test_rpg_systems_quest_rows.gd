extends GutTest

const RpgSystemsQuestRows = preload(
	"res://scripts/ui/systems/rows/rpg_systems_quest_rows.gd"
)


func test_category_labels_match_quest_sections() -> void:
	assert_eq(RpgSystemsQuestRows.category_labels(), ["Active", "Routes", "Rewards"])


func test_active_rows_build_quest_and_target_action_entries() -> void:
	var rows := RpgSystemsQuestRows.rows(_quest_state(), "active")

	assert_eq(rows.size(), 3)
	assert_eq(rows[0]["id"], "quest_0")
	assert_eq(rows[0]["title"], "Find Herb")
	assert_eq(rows[0]["subtitle"], "Speak to Mara")
	assert_eq(rows[0]["meta"], "Quest")
	assert_string_contains(rows[0]["detail"], "Find Herb: Speak to Mara")
	assert_string_contains(rows[0]["detail"], "Herb: 3 tiles north to grove")
	assert_eq(rows[1]["title"], "No colon quest")
	assert_eq(rows[1]["subtitle"], "Active quest")
	assert_eq(rows[2]["id"], "quest_action_2")
	assert_eq(rows[2]["action_id"], "quest:set_target:herb")
	assert_eq(rows[2]["title"], "Track Herb")
	assert_eq(rows[2]["subtitle"], "Set active target")
	assert_eq(rows[2]["meta"], "Route")
	assert_eq(rows[2]["detail"], "Track Herb")


func test_route_rows_format_navigation_and_skip_blank_lines() -> void:
	var rows := RpgSystemsQuestRows.rows(_quest_state(), "routes")

	assert_eq(rows.size(), 2)
	assert_eq(rows[0]["id"], "quest_route_0")
	assert_eq(rows[0]["title"], "Herb")
	assert_eq(rows[0]["subtitle"], "3 tiles north to grove")
	assert_eq(rows[0]["meta"], "Route")
	assert_eq(rows[0]["detail"], "Herb: 3 tiles north to grove")
	assert_eq(rows[1]["title"], "Camp")
	assert_eq(rows[1]["subtitle"], "2.5 tiles southwest")


func test_route_rows_return_empty_state_without_directions() -> void:
	var rows := RpgSystemsQuestRows.rows({}, "routes")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["id"], "quest_routes_empty")
	assert_eq(rows[0]["title"], "No Routes")
	assert_eq(rows[0]["subtitle"], "No active quest target selected.")
	assert_eq(rows[0]["meta"], "Route")
	assert_eq(rows[0]["detail"], "No quest routes available.")


func test_reward_rows_build_actions_and_default_missing_text() -> void:
	var rows := RpgSystemsQuestRows.rows({
		"quests": [],
		"quest_target_actions": [
			{"id": "reward:claim", "text": "Claim 25g"},
			{"id": "reward:unknown"},
			"not an action"
		]
	}, "rewards")

	assert_eq(rows.size(), 2)
	assert_eq(rows[0]["id"], "quest_reward_0")
	assert_eq(rows[0]["action_id"], "reward:claim")
	assert_eq(rows[0]["title"], "Claim 25g")
	assert_eq(rows[0]["subtitle"], "Quest action")
	assert_eq(rows[0]["meta"], "Reward")
	assert_eq(rows[0]["detail"], "Claim 25g")
	assert_eq(rows[1]["id"], "quest_reward_1")
	assert_eq(rows[1]["title"], "Quest Reward")


func test_reward_rows_return_empty_state_without_actions() -> void:
	var rows := RpgSystemsQuestRows.rows({}, "rewards")

	assert_eq(rows.size(), 1)
	assert_eq(rows[0]["id"], "quest_rewards_empty")
	assert_eq(rows[0]["title"], "No Rewards Ready")
	assert_eq(rows[0]["subtitle"], "Finish objectives to reveal rewards.")
	assert_eq(rows[0]["meta"], "Reward")
	assert_eq(rows[0]["detail"], "No quest rewards are ready.")


func _quest_state() -> Dictionary:
	return {
		"system_tabs": {
			"quests": {
				"quests": ["Find Herb: Speak to Mara", "No colon quest"],
				"directions": "Herb: N 3t grove\n\nCamp: SW 2.5t",
				"actions": [
					{"id": "quest:set_target:herb", "text": "Track Herb"},
					{"id": "quest:set_target:empty", "text": ""},
					"not an action"
				]
			}
		}
	}
