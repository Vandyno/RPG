extends GutTest

const SystemsActionBuilder = preload("res://scripts/ui/systems_action_builder.gd")


func test_actions_for_tab_routes_each_system_tab() -> void:
	var state := {
		"inventory_actions": [{"id": "use:item", "text": "Use Item"}],
		"progression_actions": [{"id": "train:might", "text": "Train Might"}],
		"trade_actions": [{"id": "buy:item", "text": "Buy Item"}],
		"quest_target_actions": [{"id": "target:npc", "text": "Target Guide"}],
		"time_actions": [{"id": "wait:1", "text": "Wait 1h"}]
	}

	assert_eq(SystemsActionBuilder.actions_for_tab(state, "inventory")[0]["id"], "use:item")
	assert_eq(SystemsActionBuilder.actions_for_tab(state, "character")[0]["id"], "train:might")
	assert_eq(SystemsActionBuilder.actions_for_tab(state, "trade")[0]["id"], "buy:item")
	assert_eq(SystemsActionBuilder.actions_for_tab(state, "quests")[0]["id"], "target:npc")

	var world_actions := SystemsActionBuilder.actions_for_tab(state, "world")
	assert_eq(world_actions[0]["id"], "wait:1")
	assert_eq(world_actions[1]["id"], "save:game")
	assert_eq(world_actions[2]["id"], "load:game")


func test_actions_for_tab_sanitizes_malformed_fields() -> void:
	assert_true(
		SystemsActionBuilder.actions_for_tab({"inventory_actions": "bad"}, "inventory").is_empty()
	)
	assert_true(SystemsActionBuilder.actions_for_tab({}, "quests").is_empty())
