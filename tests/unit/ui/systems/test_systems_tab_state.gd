extends GutTest

const SystemsTabState = preload("res://scripts/ui/systems/systems_tab_state.gd")


func test_inventory_fallback_builds_transfer_state_from_flat_hud_state() -> void:
	var state := {
		"inventory": "3 items",
		"inventory_items": [{"id": "toolbox"}],
		"inventory_details": "Useful gear",
		"inventory_actions": [{"id": "sort"}],
		"transfer_open": true,
		"transfer_target": {"id": "chest"},
		"transfer_player_items": [{"id": "coin"}],
		"transfer_target_items": [{"id": "mint"}],
	}

	assert_eq(
		SystemsTabState.inventory(state),
		{
			"summary": "3 items",
			"items": [{"id": "toolbox"}],
			"details": "Useful gear",
			"actions": [{"id": "sort"}],
			"transfer":
			{
				"open": true,
				"target": {"id": "chest"},
				"player_items": [{"id": "coin"}],
				"target_items": [{"id": "mint"}],
			}
		}
	)


func test_tabs_dictionary_overrides_flat_fallback_when_tab_is_present() -> void:
	var state := {
		"inventory": "flat",
		SystemsTabState.TABS_KEY:
		{"inventory": {"summary": "tabbed", "items": [], "actions": [{"id": "use"}]}}
	}

	assert_eq(
		SystemsTabState.inventory(state),
		{"summary": "tabbed", "items": [], "actions": [{"id": "use"}]}
	)


func test_empty_or_invalid_tab_data_falls_back_to_flat_state() -> void:
	assert_eq(
		SystemsTabState.trade({SystemsTabState.TABS_KEY: {"trade": {}}, "trade": "Flat"}),
		{"summary": "Flat", "actions": [], "stock_rows": []}
	)
	assert_eq(
		SystemsTabState.spells({SystemsTabState.TABS_KEY: {"spells": "bad"}}),
		{"spells": [], "spell_slots": {}}
	)


func test_character_spells_trade_quests_and_journal_defaults_are_player_facing() -> void:
	assert_eq(SystemsTabState.character({})["health"], "Health unknown")
	assert_eq(SystemsTabState.character({})["equipment"], "Weapon: empty\nOffhand: empty\nBody: empty")
	assert_eq(SystemsTabState.spells({}), {"spells": [], "spell_slots": {}})
	assert_eq(SystemsTabState.trade({})["summary"], "No trader selected.")
	assert_eq(SystemsTabState.quests({})["directions"], "none")
	assert_eq(SystemsTabState.journal({})["time"], "Day 1, 08:00")


func test_actions_for_tab_returns_only_array_actions_for_known_tabs() -> void:
	var state := {
		"inventory_actions": [{"id": "inventory"}],
		"progression_actions": [{"id": "character"}],
		"trade_actions": "bad",
		"quest_target_actions": [{"id": "quest"}],
		"time_actions": [{"id": "journal"}],
	}

	assert_eq(SystemsTabState.actions_for_tab(state, "inventory"), [{"id": "inventory"}])
	assert_eq(SystemsTabState.actions_for_tab(state, "character"), [{"id": "character"}])
	assert_eq(SystemsTabState.actions_for_tab(state, "trade"), [])
	assert_eq(SystemsTabState.actions_for_tab(state, "quests"), [{"id": "quest"}])
	assert_eq(SystemsTabState.actions_for_tab(state, "journal"), [{"id": "journal"}])
	assert_eq(SystemsTabState.actions_for_tab(state, "log"), [{"id": "journal"}])
	assert_eq(SystemsTabState.actions_for_tab(state, "unknown"), [])
