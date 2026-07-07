class_name HumanoidProfile
extends RefCounted

const ActorState = preload("res://scripts/core/actor_state.gd")

const STATE_ALIVE := ActorState.ALIVE
const STATE_UNCONSCIOUS := ActorState.UNCONSCIOUS
const STATE_DEAD := ActorState.DEAD
const STATE_DEAD_BODY := ActorState.DEAD_BODY
const STATE_DESPAWNED := ActorState.DESPAWNED
const VALID_STATES := ActorState.VALID_STATES
const DEAD_STATES := ActorState.DEAD_STATES
const VALID_HANDEDNESS := ["right", "left"]
const DEFAULT_CHARACTER_ID := "char_unknown"
const DEFAULT_PEOPLE_ID := "people_human"
const DEFAULT_STATE := ActorState.DEFAULT
const DEFAULT_HANDEDNESS := "right"
const DEFAULT_BODY_PLAN_ID := "body_humanoid_average"
const DEFAULT_HEAD_ID := "head_human_round"
const DEFAULT_PALETTE_ID := "palette_human_warm_brown"
const DEFAULT_HAIR_ID := "hair_short_waves"
const DEFAULT_HAIR_COLOR_ID := "hair_black"
const DEFAULT_EYE_ID := "eyes_dark"
const DEFAULT_BASE_CLOTHING_ID := ""
const DEFAULT_PROPORTIONS := {
	"body_height": 1.0,
	"shoulder_width": 1.0,
	"torso_width": 1.0,
	"waist_width": 1.0,
	"head_size": 1.0,
	"hand_size": 1.0,
	"foot_size": 1.0
}
const MIN_PROPORTION := 0.65
const MAX_PROPORTION := 1.45


static func from_data(data: Dictionary) -> Dictionary:
	var character_id := _string_or_default(data.get("character_id", ""), DEFAULT_CHARACTER_ID)
	var people_id := _string_or_default(data.get("people_id", ""), DEFAULT_PEOPLE_ID)
	var state := _string_or_default(data.get("state", ""), DEFAULT_STATE)
	if not VALID_STATES.has(state):
		state = DEFAULT_STATE

	return {
		"character_id": character_id,
		"people_id": people_id,
		"faction_id": _string_or_default(data.get("faction_id", ""), ""),
		"state": state,
		"handedness": handedness_from_data(data.get("handedness", DEFAULT_HANDEDNESS)),
		"level": _positive_int(data.get("level", 1), 1),
		"stats": number_dictionary(data.get("stats", {})),
		"derived_bonuses": number_dictionary(data.get("derived_bonuses", {})),
		"appearance": appearance_from_data(data.get("appearance", {}), people_id),
		"inventory_owner_id": _string_or_default(data.get("inventory_owner_id", ""), character_id),
		"equipment_owner_id": _string_or_default(data.get("equipment_owner_id", ""), character_id),
		"spellbook_owner_id": _string_or_default(data.get("spellbook_owner_id", ""), character_id),
		"loadout_id": _string_or_default(data.get("loadout_id", ""), ""),
		"corpse_entity_id": _string_or_default(data.get("corpse_entity_id", ""), "")
	}


static func appearance_from_data(
	value: Variant, people_id: String = DEFAULT_PEOPLE_ID
) -> Dictionary:
	var data: Dictionary = {}
	if value is Dictionary:
		data = value
	return {
		"people_id": _string_or_default(data.get("people_id", ""), people_id),
		"body_plan_id": _string_or_default(data.get("body_plan_id", ""), DEFAULT_BODY_PLAN_ID),
		"head_id": _string_or_default(data.get("head_id", ""), DEFAULT_HEAD_ID),
		"palette_id": _string_or_default(data.get("palette_id", ""), DEFAULT_PALETTE_ID),
		"hair_id": _string_or_default(data.get("hair_id", ""), DEFAULT_HAIR_ID),
		"hair_color_id": _string_or_default(data.get("hair_color_id", ""), DEFAULT_HAIR_COLOR_ID),
		"eye_id": _string_or_default(data.get("eye_id", ""), DEFAULT_EYE_ID),
		"marking_id": _string_or_default(data.get("marking_id", ""), ""),
		"feature_ids": string_array(data.get("feature_ids", [])),
		"visual_model_id": _string_or_default(data.get("visual_model_id", ""), ""),
		"base_clothing_id":
		_string_or_default(data.get("base_clothing_id", ""), DEFAULT_BASE_CLOTHING_ID),
		"proportions": proportions_from_data(data.get("proportions", {}))
	}


static func proportions_from_data(value: Variant) -> Dictionary:
	var source: Dictionary = {}
	if value is Dictionary:
		source = value
	var proportions: Dictionary = DEFAULT_PROPORTIONS.duplicate(true)
	for field_id in proportions:
		proportions[field_id] = _bounded_float(
			source.get(field_id, proportions[field_id]),
			float(proportions[field_id]),
			MIN_PROPORTION,
			MAX_PROPORTION
		)
	return proportions


static func proportion_value(proportions: Dictionary, field_id: String) -> float:
	return _bounded_float(proportions.get(field_id, 1.0), 1.0, MIN_PROPORTION, MAX_PROPORTION)


static func validate(profile: Dictionary, owner: String) -> Array[String]:
	var errors: Array[String] = []
	var character_id := String(profile.get("character_id", ""))
	if character_id.is_empty():
		errors.append("%s is missing character_id." % owner)
	if String(profile.get("people_id", "")).is_empty():
		errors.append("%s is missing people_id." % owner)
	var state := String(profile.get("state", ""))
	if state.is_empty() or not VALID_STATES.has(state):
		errors.append("%s has invalid state %s." % [owner, state])
	if profile.has("handedness"):
		var handedness := String(profile.get("handedness", ""))
		if handedness.is_empty() or not VALID_HANDEDNESS.has(handedness):
			errors.append("%s has invalid handedness %s." % [owner, handedness])
	for owner_field in ["inventory_owner_id", "equipment_owner_id", "spellbook_owner_id"]:
		if String(profile.get(owner_field, "")).is_empty():
			errors.append("%s is missing %s." % [owner, owner_field])
	_validate_number_dictionary(profile.get("stats", {}), "%s stats" % owner, errors)
	_validate_number_dictionary(
		profile.get("derived_bonuses", {}), "%s derived_bonuses" % owner, errors
	)
	var appearance: Variant = profile.get("appearance", {})
	if not (appearance is Dictionary):
		errors.append("%s appearance must be a dictionary." % owner)
	else:
		for field_id in ["people_id", "body_plan_id", "head_id", "palette_id"]:
			if String(appearance.get(field_id, "")).is_empty():
				errors.append("%s appearance is missing %s." % [owner, field_id])
		_validate_proportions(appearance.get("proportions", {}), "%s appearance" % owner, errors)
	return errors


static func number_dictionary(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not (value is Dictionary):
		return result
	for key in value:
		var amount: Variant = value[key]
		if not _is_number(amount):
			continue
		var id := String(key)
		if id.is_empty():
			continue
		result[id] = int(amount) if amount is int else float(amount)
	return result


static func handedness_from_data(value: Variant) -> String:
	var handedness := String(value)
	if VALID_HANDEDNESS.has(handedness):
		return handedness
	return DEFAULT_HANDEDNESS


static func string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not value is Array:
		return result
	for entry in value:
		var text := str(entry)
		if not text.is_empty() and not result.has(text):
			result.append(text)
	return result


static func validate_proportions(value: Variant, owner: String, errors: Array[String]) -> void:
	_validate_proportions(value, owner, errors)


static func _positive_int(value: Variant, fallback: int) -> int:
	if not _is_number(value):
		return maxi(1, fallback)
	return maxi(1, int(value))


static func _bounded_float(
	value: Variant, fallback: float, min_value: float, max_value: float
) -> float:
	if not _is_number(value):
		return clampf(fallback, min_value, max_value)
	return clampf(float(value), min_value, max_value)


static func _validate_proportions(value: Variant, owner: String, errors: Array[String]) -> void:
	if not (value is Dictionary):
		errors.append("%s proportions must be a dictionary." % owner)
		return
	for field_id in value:
		if not DEFAULT_PROPORTIONS.has(field_id):
			continue
		if not _is_number(value[field_id]):
			errors.append("%s proportions %s must be numeric." % [owner, field_id])
			continue
		var amount := float(value[field_id])
		if amount < MIN_PROPORTION or amount > MAX_PROPORTION:
			errors.append(
				(
					"%s proportions %s must be between %.2f and %.2f."
					% [owner, field_id, MIN_PROPORTION, MAX_PROPORTION]
				)
			)


static func _validate_number_dictionary(
	value: Variant, owner: String, errors: Array[String]
) -> void:
	if not (value is Dictionary):
		errors.append("%s must be a dictionary." % owner)
		return
	for key in value:
		if String(key).is_empty():
			errors.append("%s has blank id." % owner)
		if not _is_number(value[key]):
			errors.append("%s %s must be numeric." % [owner, String(key)])


static func _string_or_default(value: Variant, fallback: String) -> String:
	var text := String(value)
	return fallback if text.is_empty() else text


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
