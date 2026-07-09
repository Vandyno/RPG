extends GutTest

const SystemsActionBuilder = preload("res://scripts/ui/systems/systems_action_builder.gd")


func test_actions_for_tab_routes_each_system_tab() -> void:
	var state := {
		"inventory_actions": [{"id": "use:item", "text": "Use Item"}],
		"progression_actions": [{"id": "train:legacy", "text": "Train Legacy"}],
		"trade_actions": [{"id": "buy:item", "text": "Buy Item"}],
		"quest_target_actions": [{"id": "target:npc", "text": "Target Guide"}],
		"time_actions": [{"id": "wait:1", "text": "Wait 1h"}]
	}

	assert_eq(SystemsActionBuilder.actions_for_tab(state, "inventory")[0]["id"], "use:item")
	assert_eq(SystemsActionBuilder.actions_for_tab(state, "character")[0]["id"], "train:legacy")
	assert_eq(SystemsActionBuilder.actions_for_tab(state, "trade")[0]["id"], "buy:item")
	assert_eq(SystemsActionBuilder.actions_for_tab(state, "quests")[0]["id"], "target:npc")
	assert_true(SystemsActionBuilder.actions_for_tab(state, "map").is_empty())
	assert_true(SystemsActionBuilder.actions_for_tab(state, "world").is_empty())

	var journal_actions := SystemsActionBuilder.actions_for_tab(state, "journal")
	assert_eq(journal_actions[0]["id"], "wait:1")
	assert_eq(journal_actions[1]["id"], "save:game")
	assert_eq(journal_actions[2]["id"], "load:game")
	var log_actions := SystemsActionBuilder.actions_for_tab(state, "log")
	assert_eq(log_actions[0]["id"], "wait:1")
	assert_eq(log_actions[1]["id"], "save:game")
	assert_eq(log_actions[2]["id"], "load:game")


func test_actions_for_tab_prefers_narrow_tab_state() -> void:
	var state := {
		"inventory_actions": [{"id": "legacy:use", "text": "Legacy Use"}],
		"system_tabs": {
			"inventory": {"actions": [{"id": "tab:use", "text": "Tab Use"}]},
			"character": {"actions": [{"id": "tab:train", "text": "Tab Train"}]},
			"trade": {"actions": [{"id": "tab:buy", "text": "Tab Buy"}]},
			"quests": {"actions": [{"id": "tab:target", "text": "Tab Target"}]},
			"journal": {"actions": [{"id": "tab:wait", "text": "Tab Wait"}]}
		}
	}

	assert_eq(SystemsActionBuilder.actions_for_tab(state, "inventory")[0]["id"], "tab:use")
	assert_eq(SystemsActionBuilder.actions_for_tab(state, "character")[0]["id"], "tab:train")
	assert_eq(SystemsActionBuilder.actions_for_tab(state, "trade")[0]["id"], "tab:buy")
	assert_eq(SystemsActionBuilder.actions_for_tab(state, "quests")[0]["id"], "tab:target")
	assert_eq(SystemsActionBuilder.actions_for_tab(state, "journal")[0]["id"], "tab:wait")


func test_actions_for_tab_sanitizes_malformed_fields() -> void:
	assert_true(
		SystemsActionBuilder.actions_for_tab({"inventory_actions": "bad"}, "inventory").is_empty()
	)
	assert_true(SystemsActionBuilder.actions_for_tab({}, "quests").is_empty())
