extends GutTest

const HudTextBuilder = preload("res://scripts/ui/hud_text_builder.gd")


func test_status_text_summarizes_multiple_quests_and_targets() -> void:
	var text := HudTextBuilder.status_text(
		{
			"time": "Day 1, 08:00 (Morning)",
			"locations": "Briarwatch Crossroads",
			"player_tile": "(0, 0)",
			"terrain": "road",
			"inventory": "empty",
			"quests":
			[
				"The Missing Tools: Return the toolbox to Harrow Venn.",
				"Briarwatch Road Patrol: Defeat the road thug."
			],
			"quest_directions":
			"The Missing Tools: E 5.0t Harrow Venn\n" + "Briarwatch Road Patrol: W 5.4t Road Thug"
		}
	)

	assert_true(text.contains("Briarwatch Crossroads  Day 1, 08:00"))
	assert_true(text.contains("Quest: The Missing Tools (+1)"))
	assert_true(text.contains("Goal: Return the toolbox to Harrow Venn."))
	assert_true(text.contains("Next: E 5.0t Harrow Venn (+1)"))


func test_status_text_omits_empty_inventory_and_empty_quest_noise() -> void:
	var text := HudTextBuilder.status_text(
		{
			"time": "Day 1, 08:00 (Morning)",
			"locations": "none",
			"player_tile": "(0, 0)",
			"terrain": "road",
			"inventory": "Road Hatchet x1",
			"quests": []
		}
	)

	assert_false(text.contains("Inventory: empty"))
	assert_false(text.contains("Inventory: Road Hatchet x1"))
	assert_false(text.contains("Quest: none"))
	assert_false(text.contains("Tile (0, 0)  road"))
	assert_true(text.contains("Velcor  Day 1, 08:00"))


func test_message_text_uses_latest_message_only_in_compact_layout() -> void:
	var messages: Array[String] = ["First", "Second", "Discovered Briarwatch Crossroads."]

	assert_eq(HudTextBuilder.message_text(messages, true), "Discovered Briarwatch Crossroads.")
	assert_eq(
		HudTextBuilder.message_text(messages, false),
		"First\nSecond\nDiscovered Briarwatch Crossroads."
	)
