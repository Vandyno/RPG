extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const QuestProposalGenerator = preload("res://scripts/generation/quest_proposal_generator.gd")
const QuestProposalValidator = preload("res://scripts/data/quest_proposal_validator.gd")

var content


func before_each() -> void:
	content = ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()


func test_generator_is_deterministic_and_review_only() -> void:
	var first := QuestProposalGenerator.generate(content, "briarwatch_quest_seed")
	var second := QuestProposalGenerator.generate(content, "briarwatch_quest_seed")

	assert_eq(first, second)
	assert_eq(first["schema_version"], QuestProposalGenerator.SCHEMA_VERSION)
	assert_eq(first["proposal_status"], "proposal")
	assert_eq(first["runtime_import"], "manual_only")
	assert_eq(first["pitches"].size(), 5)
	assert_false(first.has("quests"))


func test_generator_uses_only_existing_context_and_validates() -> void:
	var bundle := QuestProposalGenerator.generate(
		content, "briarwatch_quest_seed", 3, "location_briarwatch_crossroads"
	)

	assert_eq(QuestProposalValidator.validate(content, bundle), [])
	for pitch_value in bundle["pitches"]:
		var pitch: Dictionary = pitch_value
		assert_eq(pitch["location_id"], "location_briarwatch_crossroads")
		assert_eq(pitch["approval_status"], "unreviewed")
		assert_true(String(pitch["id"]).begins_with("proposal_quest_"))
		assert_false(pitch["implementation_gaps"].is_empty())


func test_validator_rejects_runtime_collision_and_unknown_context() -> void:
	var bundle := QuestProposalGenerator.generate(content, "briarwatch_quest_seed", 1)
	var pitch: Dictionary = bundle["pitches"][0]
	pitch["id"] = "quest_missing_tools"
	pitch["required_existing_ids"]["locations"] = ["location_unknown"]
	var errors := "\n".join(QuestProposalValidator.validate(content, bundle))

	assert_true(errors.contains("proposal_quest_ ID prefix"))
	assert_true(errors.contains("missing locations location_unknown"))
