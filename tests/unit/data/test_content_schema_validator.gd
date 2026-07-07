extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const ContentSchemaValidator = preload("res://scripts/data/content_schema_validator.gd")

var content: ContentDatabase


func before_each() -> void:
	content = ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()


func test_rejects_bad_effects_conditions_and_actions() -> void:
	var errors: Array[String] = []
	var entry := {
		"effects":
		[
			{"type": "add_item", "item_id": "missing_item", "count": 0},
			{"type": "set_quest_stage", "quest_id": "quest_missing_tools", "stage": "missing"},
			{"type": "advance_time"}
		],
		"conditions":
		[
			{"type": "quest_state", "quest_id": "quest_missing_tools", "state": "nonsense"},
			{"type": "time_hour_between", "start_hour": "early", "end_hour": 99}
		],
		"actions":
		[
			{"id": "inspect", "text": "", "conditions": ["bad"], "effects": ["bad"]},
			{"id": "inspect", "text": "Duplicate", "response": "Again"}
		]
	}

	ContentSchemaValidator.validate_effect_list(content, entry, "effects", "Fixture", errors)
	ContentSchemaValidator.validate_condition_list(content, entry, "conditions", "Fixture", errors)
	ContentSchemaValidator.validate_action_list(content, entry, "actions", "Fixture", errors)
	var joined := "\n".join(errors)

	assert_true(joined.contains("references missing item missing_item"))
	assert_true(joined.contains("has non-positive count"))
	assert_true(joined.contains("references missing quest stage quest_missing_tools:missing"))
	assert_true(joined.contains("advance_time requires minutes or hours"))
	assert_true(joined.contains("quest_state with invalid state nonsense"))
	assert_true(joined.contains("start_hour must be numeric"))
	assert_true(joined.contains("end_hour must be between"))
	assert_true(joined.contains("duplicate action id inspect"))
	assert_true(joined.contains("action inspect is missing text"))
	assert_true(joined.contains("conditions has malformed condition"))
	assert_true(joined.contains("effects has malformed effect"))
