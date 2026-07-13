extends GutTest

const WorldAtlasApprovalGate = preload("res://scripts/data/world_atlas_approval_gate.gd")
const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")
const ATLAS_PATH := "res://data/world_atlas_proposal.json"
const REVIEW_PATH := "res://data/world_atlas_review.json"


func test_authored_review_record_matches_user_approval() -> void:
	var atlas := WorldAtlasValidator.load_atlas(ATLAS_PATH)
	var review := WorldAtlasApprovalGate.load_review(REVIEW_PATH)
	var result := WorldAtlasApprovalGate.evaluate(atlas, review)

	assert_eq(result["status"], "approved")
	assert_true(result["can_generate"])
	assert_eq(result["item_decisions"].size(), 7)
	assert_true(result["blockers"].is_empty())


func test_pending_decision_keeps_generation_locked() -> void:
	var atlas := WorldAtlasValidator.load_atlas(ATLAS_PATH)
	var review := WorldAtlasApprovalGate.load_review(REVIEW_PATH).duplicate(true)
	review["decision_status"] = "pending"
	review["item_decisions"][0]["decision"] = "pending"
	var result := WorldAtlasApprovalGate.evaluate(atlas, review)

	assert_eq(result["status"], "pending")
	assert_false(result["can_generate"])
	assert_true(result["blockers"].has("Atlas review still has pending items"))


func test_gate_opens_only_after_explicit_complete_approval() -> void:
	var atlas := WorldAtlasValidator.load_atlas(ATLAS_PATH)
	var review := WorldAtlasApprovalGate.load_review(REVIEW_PATH).duplicate(true)
	review["decision_status"] = "approved"
	review["reviewed_by"] = "user"
	review["reviewed_at_utc"] = "2026-07-11T00:00:00Z"
	for decision in review["item_decisions"]:
		decision["decision"] = "approved"
	var result := WorldAtlasApprovalGate.evaluate(atlas, review)

	assert_eq(result["status"], "approved")
	assert_true(result["can_generate"])
	assert_true(result["blockers"].is_empty())


func test_rejection_and_stale_review_keep_generation_locked() -> void:
	var atlas := WorldAtlasValidator.load_atlas(ATLAS_PATH)
	var review := WorldAtlasApprovalGate.load_review(REVIEW_PATH).duplicate(true)
	review["decision_status"] = "rejected"
	review["item_decisions"][0]["decision"] = "rejected"
	review["atlas_schema_version"] = "old"
	var result := WorldAtlasApprovalGate.evaluate(atlas, review)

	assert_eq(result["status"], "rejected")
	assert_false(result["can_generate"])
	assert_true(result["blockers"].has("Review atlas_schema_version is stale"))
	assert_true(result["blockers"].has("Rejected atlas items require atlas revision"))


func test_missing_and_unknown_item_decisions_are_blockers() -> void:
	var atlas := WorldAtlasValidator.load_atlas(ATLAS_PATH)
	var review := WorldAtlasApprovalGate.load_review(REVIEW_PATH).duplicate(true)
	review["item_decisions"].pop_back()
	review["item_decisions"].append(
		{"collection": "landmarks", "id": "invented", "decision": "approved", "note": ""}
	)
	var result := WorldAtlasApprovalGate.evaluate(atlas, review)
	var joined := "\n".join(result["blockers"])

	assert_false(result["can_generate"])
	assert_true(joined.contains("stale or unknown"))
	assert_true(joined.contains("Review is missing decision landmarks:last_perch"))
