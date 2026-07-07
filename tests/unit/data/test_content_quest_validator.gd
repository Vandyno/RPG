extends GutTest


func test_validate_accepts_minimal_valid_quest_dialogue_and_npc_content() -> void:
	var content := _valid_content()
	var errors: Array[String] = []

	ContentQuestValidator.validate(content, errors)

	assert_eq(errors, [])


func test_validate_reports_malformed_quests_factions_dialogues_and_npcs() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.quests = {
		"quest_bad":
		{
			"id": "wrong_id",
			"title": "",
			"start_stage": "missing",
			"stages":
			{
				"": "bad",
				"start":
				{
					"objectives":
					{
						"": "",
						"find": {"text": "", "target_id": "missing_object"}
					}
				}
			}
		}
	}
	content.factions = {
		"faction_bad":
		{"id": "faction_bad", "name": "", "description": "", "starting_reputation": 200}
	}
	content.dialogues = {
		"dialogue_bad":
		{
			"id": "dialogue_bad",
			"lines":
			[
				"bad",
				{
					"id": "",
					"speaker": "",
					"text": "",
					"choices": [{"id": "", "text": ""}, {"id": "ask", "text": ""}]
				},
				{"id": "", "speaker": "Harrow", "text": "Again."}
			]
		}
	}
	content.npcs = {
		"npc_bad":
		{
			"id": "npc_bad",
			"name": "",
			"quest_id": "missing_quest",
			"faction": "missing_faction",
			"dialogue_id": "missing_dialogue",
			"shop_id": "missing_shop",
			"character_profile_id": "missing_profile"
		}
	}
	var errors: Array[String] = []

	ContentQuestValidator.validate(content, errors)
	var joined := "\n".join(errors)

	assert_true(joined.contains("Quest quest_bad has mismatched id wrong_id"))
	assert_true(joined.contains("Quest quest_bad is missing title."))
	assert_true(joined.contains("references missing start_stage missing"))
	assert_true(joined.contains("Quest quest_bad has stage with missing id."))
	assert_true(joined.contains("Quest quest_bad stage  must be a dictionary."))
	assert_true(joined.contains("Quest quest_bad stage start has objective with missing id."))
	assert_true(joined.contains("objective  is missing text."))
	assert_true(joined.contains("objective find is missing text."))
	assert_true(joined.contains("references missing target missing_object"))
	assert_true(joined.contains("Faction faction_bad is missing name."))
	assert_true(joined.contains("Faction faction_bad is missing description."))
	assert_true(joined.contains("Dialogue dialogue_bad has malformed line."))
	assert_true(joined.contains("Dialogue dialogue_bad has line with missing id."))
	assert_true(joined.contains("Dialogue dialogue_bad line  is missing speaker."))
	assert_true(joined.contains("Dialogue dialogue_bad line  is missing text."))
	assert_true(joined.contains("has choice with missing id."))
	assert_true(joined.contains("choice ask is missing text."))
	assert_true(joined.contains("NPC npc_bad is missing name."))
	assert_true(joined.contains("NPC npc_bad references missing quest missing_quest"))
	assert_true(joined.contains("NPC npc_bad references missing faction missing_faction"))
	assert_true(joined.contains("NPC npc_bad references missing dialogue missing_dialogue"))
	assert_true(joined.contains("NPC npc_bad references missing shop missing_shop"))
	assert_true(joined.contains("NPC npc_bad references missing character profile missing_profile"))


func _valid_content() -> ContentDatabase:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.quests = {
		"quest_tools":
		{
			"id": "quest_tools",
			"title": "Missing Tools",
			"start_stage": "start",
			"stages": {"start": {"objectives": {"find": "Find the tools."}}},
			"rewards": []
		}
	}
	content.factions = {
		"faction_town":
		{
			"id": "faction_town",
			"name": "Town",
			"description": "Local people.",
			"starting_reputation": 0
		}
	}
	content.dialogues = {
		"dialogue_harrow":
		{
			"id": "dialogue_harrow",
			"lines":
			[
				{
					"id": "start",
					"speaker": "Harrow",
					"text": "Need tools?",
					"choices": [{"id": "accept", "text": "I will help."}]
				}
			]
		}
	}
	content.npcs = {
		"npc_harrow":
		{
			"id": "npc_harrow",
			"name": "Harrow",
			"quest_id": "quest_tools",
			"faction": "faction_town",
			"dialogue_id": "dialogue_harrow",
			"character_profile_id": "char_harrow"
		}
	}
	content.character_profiles = {"char_harrow": {"character_id": "char_harrow"}}
	return content
