class_name WorldAtlasApprovalGate
extends RefCounted

const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")
const DECISIONS := ["pending", "approved", "rejected"]


static func load_review(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func evaluate(atlas: Dictionary, review: Dictionary) -> Dictionary:
	var blockers := PackedStringArray()
	var validation_errors := WorldAtlasValidator.validate(atlas)
	if not validation_errors.is_empty():
		blockers.append("Atlas validation failed")
	if review.is_empty():
		blockers.append("Atlas review record is missing or unreadable")
		return _result("missing_review", false, blockers, [], validation_errors)
	if String(review.get("atlas_id", "")) != String(atlas.get("atlas_id", "")):
		blockers.append("Review atlas_id does not match atlas")
	if String(review.get("atlas_schema_version", "")) != String(atlas.get("schema_version", "")):
		blockers.append("Review atlas_schema_version is stale")
	var overall_decision := String(review.get("decision_status", ""))
	if overall_decision not in DECISIONS:
		blockers.append("Review decision_status must be pending, approved, or rejected")
	var expected := {}
	for item in WorldAtlasValidator.build_report(atlas).get("review_items", []):
		expected[_key(item)] = item
	var seen := {}
	var decisions: Array[Dictionary] = []
	var any_pending := false
	var any_rejected := false
	var raw_decisions: Variant = review.get("item_decisions", [])
	if not raw_decisions is Array:
		blockers.append("Review item_decisions must be an array")
		raw_decisions = []
	for raw_decision in raw_decisions:
		if not raw_decision is Dictionary:
			blockers.append("Review contains a non-object item decision")
			continue
		var key := _key(raw_decision)
		var decision := String(raw_decision.get("decision", ""))
		if seen.has(key):
			blockers.append("Duplicate review decision %s" % key)
			continue
		seen[key] = true
		if not expected.has(key):
			blockers.append("Review decision %s is stale or unknown" % key)
		if decision not in DECISIONS:
			blockers.append("Review decision %s has invalid value %s" % [key, decision])
		elif decision == "pending":
			any_pending = true
		elif decision == "rejected":
			any_rejected = true
		decisions.append(
			{
				"collection": String(raw_decision.get("collection", "")),
				"id": String(raw_decision.get("id", "")),
				"decision": decision,
				"note": String(raw_decision.get("note", ""))
			}
		)
	for key in expected:
		if not seen.has(key):
			blockers.append("Review is missing decision %s" % key)
			any_pending = true
	if any_rejected:
		blockers.append("Rejected atlas items require atlas revision")
	if any_pending:
		blockers.append("Atlas review still has pending items")
	if overall_decision != "approved":
		blockers.append("Atlas decision_status is not approved")
	if overall_decision == "approved":
		if String(review.get("reviewed_by", "")).strip_edges().is_empty():
			blockers.append("Approved atlas review is missing reviewed_by")
		if String(review.get("reviewed_at_utc", "")).strip_edges().is_empty():
			blockers.append("Approved atlas review is missing reviewed_at_utc")
	var status := "approved"
	if not validation_errors.is_empty():
		status = "invalid_atlas"
	elif any_rejected or overall_decision == "rejected":
		status = "rejected"
	elif not blockers.is_empty():
		status = "pending"
	return _result(status, blockers.is_empty(), blockers, decisions, validation_errors)


static func _result(
	status: String,
	can_generate: bool,
	blockers: PackedStringArray,
	decisions: Array,
	validation_errors: PackedStringArray
) -> Dictionary:
	return {
		"status": status,
		"can_generate": can_generate,
		"blockers": Array(blockers),
		"item_decisions": decisions,
		"validation_errors": Array(validation_errors)
	}


static func _key(item: Dictionary) -> String:
	return "%s:%s" % [String(item.get("collection", "")), String(item.get("id", ""))]
