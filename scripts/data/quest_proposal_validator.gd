class_name QuestProposalValidator
extends RefCounted

const QuestProposalGenerator = preload("res://scripts/generation/quest_proposal_generator.gd")
const PITCH_STATUSES := ["IDEA", "REVIEW", "REWORK", "APPROVED", "CANON", "CUT"]


static func validate(content, bundle: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if String(bundle.get("schema_version", "")) != QuestProposalGenerator.SCHEMA_VERSION:
		errors.append("Quest proposal bundle has unsupported schema_version.")
	if String(bundle.get("proposal_status", "")) != "proposal":
		errors.append("Quest proposal bundle must remain proposal status.")
	if String(bundle.get("runtime_import", "")) != "manual_only":
		errors.append("Quest proposal bundle must require manual runtime import.")
	var pitches: Variant = bundle.get("pitches", [])
	if not pitches is Array or pitches.is_empty():
		errors.append("Quest proposal bundle must contain at least one pitch.")
		return errors
	var seen_ids := {}
	for pitch_value in pitches:
		if not pitch_value is Dictionary:
			errors.append("Quest proposal bundle contains malformed pitch.")
			continue
		_validate_pitch(content, pitch_value, seen_ids, errors)
	return errors


static func _validate_pitch(
	content, pitch: Dictionary, seen_ids: Dictionary, errors: Array[String]
) -> void:
	var pitch_id := String(pitch.get("id", ""))
	if not pitch_id.begins_with("proposal_quest_"):
		errors.append("Quest pitch must use proposal_quest_ ID prefix.")
	elif seen_ids.has(pitch_id):
		errors.append("Quest proposal bundle has duplicate pitch %s." % pitch_id)
	elif content.has_quest(pitch_id):
		errors.append("Quest pitch %s collides with runtime quest content." % pitch_id)
	seen_ids[pitch_id] = true
	for field_id in ["title", "type", "summary", "player_hook", "twist", "canon_risk"]:
		if String(pitch.get(field_id, "")).strip_edges().is_empty():
			errors.append("Quest pitch %s is missing %s." % [pitch_id, field_id])
	if String(pitch.get("status", "")) not in PITCH_STATUSES:
		errors.append("Quest pitch %s has unsupported status." % pitch_id)
	if String(pitch.get("approval_status", "")) != "unreviewed":
		errors.append("Quest pitch %s must begin unreviewed." % pitch_id)
	_validate_existing_ids(content, pitch_id, pitch.get("required_existing_ids", {}), errors)
	_validate_string_list(pitch_id, "possible_outcomes", pitch.get("possible_outcomes", []), errors)
	_validate_string_list(
		pitch_id, "implementation_gaps", pitch.get("implementation_gaps", []), errors
	)


static func _validate_existing_ids(
	content, pitch_id: String, value: Variant, errors: Array[String]
) -> void:
	if not value is Dictionary:
		errors.append("Quest pitch %s has invalid required_existing_ids." % pitch_id)
		return
	var checks := {
		"locations": Callable(content, "has_location"),
		"npcs": Callable(content, "has_npc"),
		"factions": Callable(content, "has_faction"),
		"readables": Callable(content, "has_readable")
	}
	for category in checks:
		var ids: Variant = value.get(category, [])
		if not ids is Array:
			errors.append("Quest pitch %s %s must be an array." % [pitch_id, category])
			continue
		for entry_id in ids:
			if not checks[category].call(String(entry_id)):
				errors.append("Quest pitch %s references missing %s %s." % [
					pitch_id, category, String(entry_id)
				])


static func _validate_string_list(
	pitch_id: String, field_id: String, value: Variant, errors: Array[String]
) -> void:
	if not value is Array or value.is_empty():
		errors.append("Quest pitch %s must have %s." % [pitch_id, field_id])
		return
	for entry in value:
		if String(entry).strip_edges().is_empty():
			errors.append("Quest pitch %s has blank %s entry." % [pitch_id, field_id])
