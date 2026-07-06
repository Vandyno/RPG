class_name ContentPeopleValidator
extends RefCounted

const HumanoidProfile = preload("res://scripts/characters/humanoid_profile.gd")
const HumanoidProfileResolver = preload("res://scripts/characters/humanoid_profile_resolver.gd")
const Schema = preload("res://scripts/data/content_schema_validator.gd")


static func validate(content, errors: Array[String]) -> void:
	_validate_people(content, errors)
	_validate_people_visual_models(content, errors)
	_validate_character_profiles(content, errors)


static func _validate_people(content, errors: Array[String]) -> void:
	for people_id in content.people:
		var definition_value: Variant = content.people[people_id]
		if not definition_value is Dictionary:
			errors.append("People %s must be a dictionary." % people_id)
			continue
		var definition: Dictionary = definition_value
		Schema.validate_keyed_id(definition, String(people_id), "People", errors)
		if String(definition.get("display_name", "")).is_empty():
			errors.append("People %s is missing display_name." % people_id)
		for field_id in ["body_plans", "heads", "palettes", "features"]:
			if not definition.get(field_id, []) is Array:
				errors.append("People %s %s must be an array." % [people_id, field_id])
		var bonuses: Variant = definition.get("bonuses", {})
		if not bonuses is Dictionary:
			errors.append("People %s bonuses must be a dictionary." % people_id)
			continue
		for bonus_id in bonuses:
			if String(bonus_id).is_empty():
				errors.append("People %s has blank bonus id." % people_id)
			if not Schema.is_number(bonuses[bonus_id]):
				errors.append("People %s bonus %s must be numeric." % [people_id, String(bonus_id)])
		if definition.has("default_proportions"):
			HumanoidProfile.validate_proportions(
				definition.get("default_proportions", {}),
				"People %s default_proportions" % people_id,
				errors
			)


static func _validate_people_visual_models(content, errors: Array[String]) -> void:
	for model_id in content.people_visual_models:
		var model_value: Variant = content.people_visual_models[model_id]
		if not model_value is Dictionary:
			errors.append("People visual model %s must be a dictionary." % model_id)
			continue
		var model: Dictionary = model_value
		var people_id := String(model.get("people_id", ""))
		if people_id != String(model_id):
			errors.append(
				"People visual model %s has mismatched people_id %s." % [model_id, people_id]
			)
		if not content.people.has(people_id):
			errors.append(
				"People visual model %s references missing people %s." % [model_id, people_id]
			)
			continue
		_validate_people_visual_variants(content, model, String(model_id), people_id, errors)
	for people_id in content.people:
		if not content.people_visual_models.has(people_id):
			errors.append("People %s is missing visual model variants." % people_id)


static func _validate_people_visual_variants(
	content, model: Dictionary, model_id: String, people_id: String, errors: Array[String]
) -> void:
	var definition: Dictionary = content.people.get(people_id, {})
	var variants: Array = Schema.array_field(model.get("variants", []))
	if variants.size() < 4:
		errors.append("People visual model %s must define at least four variants." % model_id)
	var seen_variant_ids: Dictionary = {}
	for variant_value in variants:
		if not variant_value is Dictionary:
			errors.append("People visual model %s has malformed variant." % model_id)
			continue
		var variant: Dictionary = variant_value
		var variant_id := String(variant.get("id", ""))
		var owner := "People visual model %s variant %s" % [model_id, variant_id]
		if variant_id.is_empty():
			errors.append("People visual model %s has variant with missing id." % model_id)
		elif seen_variant_ids.has(variant_id):
			errors.append("People visual model %s has duplicate variant %s." % [model_id, variant_id])
		seen_variant_ids[variant_id] = true
		_validate_people_visual_variant_fields(content, definition, variant, owner, errors)
		_validate_people_visual_variant_proportions(
			content, people_id, variant, "%s final proportions" % owner, errors
		)


static func _validate_people_visual_variant_fields(
	_content,
	definition: Dictionary,
	variant: Dictionary,
	owner: String,
	errors: Array[String]
) -> void:
	if String(variant.get("display_name", "")).is_empty():
		errors.append("%s is missing display_name." % owner)
	var palette_id := String(variant.get("palette_id", ""))
	if not Schema.array_field(definition.get("palettes", [])).has(palette_id):
		errors.append("%s references unsupported palette %s." % [owner, palette_id])
	var head_id := String(variant.get("head_id", ""))
	if not Schema.array_field(definition.get("heads", [])).has(head_id):
		errors.append("%s references unsupported head %s." % [owner, head_id])
	for feature_id in Schema.array_field(variant.get("feature_ids", [])):
		if not Schema.array_field(definition.get("features", [])).has(String(feature_id)):
			errors.append("%s references unsupported feature %s." % [owner, String(feature_id)])
	if String(variant.get("notes", "")).is_empty():
		errors.append("%s is missing notes." % owner)


static func _validate_people_visual_variant_proportions(
	content, people_id: String, variant: Dictionary, owner: String, errors: Array[String]
) -> void:
	var deltas_value: Variant = variant.get("proportion_deltas", {})
	if not deltas_value is Dictionary:
		errors.append("%s proportion_deltas must be a dictionary." % owner)
		return
	_validate_people_model_proportion_deltas(content, deltas_value, owner, errors)
	_validate_people_model_final_proportions(content, people_id, deltas_value, owner, errors)


static func _validate_character_profiles(content, errors: Array[String]) -> void:
	for profile_id in content.character_profiles:
		var profile_value: Variant = content.character_profiles[profile_id]
		if not profile_value is Dictionary:
			errors.append("Character profile %s must be a dictionary." % profile_id)
			continue
		var profile: Dictionary = profile_value
		var people_id := String(profile.get("people_id", ""))
		if not content.people.has(people_id):
			errors.append("Character profile %s references missing people %s." % [profile_id, people_id])
		var character_id := String(profile.get("character_id", ""))
		if character_id.is_empty():
			errors.append("Character profile %s is missing character_id." % profile_id)
		elif character_id != String(profile_id):
			errors.append(
				"Character profile %s has mismatched character_id %s."
				% [profile_id, character_id]
			)
		_validate_appearance_generation(content, profile, String(profile_id), errors)
		var validation_profile := HumanoidProfileResolver.profile_source_with_generated_appearance(
			content, profile
		)
		errors.append_array(
			HumanoidProfile.validate(validation_profile, "Character profile %s" % profile_id)
		)


static func _validate_appearance_generation(
	content, profile: Dictionary, profile_id: String, errors: Array[String]
) -> void:
	if not profile.has("appearance_generation"):
		return
	var owner := "Character profile %s appearance_generation" % profile_id
	var generation_value: Variant = profile.get("appearance_generation", {})
	if not generation_value is Dictionary:
		errors.append("%s must be a dictionary." % owner)
		return
	var generation: Dictionary = generation_value
	var people_id := String(profile.get("people_id", ""))
	if generation.has("seed") and not generation.get("seed") is String:
		errors.append("%s seed must be a string." % owner)
	if generation.has("variant_id"):
		_validate_appearance_generation_variant(content, generation, people_id, owner, errors)
	if generation.has("proportion_jitter") and not generation.get("proportion_jitter") is bool:
		errors.append("%s proportion_jitter must be a boolean." % owner)
	_validate_appearance_generation_jitter(content, generation, owner, errors)
	_validate_appearance_generation_overrides(generation, owner, errors)


static func _validate_appearance_generation_variant(
	content, generation: Dictionary, people_id: String, owner: String, errors: Array[String]
) -> void:
	if not generation.get("variant_id") is String:
		errors.append("%s variant_id must be a string." % owner)
		return
	var variant_id := String(generation.get("variant_id", ""))
	var variant: Dictionary = content.get_people_visual_variant(people_id, variant_id)
	if not variant_id.is_empty() and variant.is_empty():
		errors.append("%s references missing variant %s." % [owner, variant_id])


static func _validate_appearance_generation_jitter(
	_content, generation: Dictionary, owner: String, errors: Array[String]
) -> void:
	if not generation.has("jitter_strength"):
		return
	if not Schema.is_number(generation.get("jitter_strength")):
		errors.append("%s jitter_strength must be numeric." % owner)
		return
	var strength := float(generation.get("jitter_strength"))
	if strength < 0.0 or strength > HumanoidProfileResolver.MAX_JITTER_STRENGTH:
		errors.append("%s jitter_strength must be between 0.00 and 0.08." % owner)


static func _validate_appearance_generation_overrides(
	generation: Dictionary, owner: String, errors: Array[String]
) -> void:
	if not generation.has("appearance_overrides"):
		return
	var overrides_value: Variant = generation.get("appearance_overrides", {})
	if not overrides_value is Dictionary:
		errors.append("%s appearance_overrides must be a dictionary." % owner)
		return
	var overrides: Dictionary = overrides_value
	if overrides.has("proportions"):
		HumanoidProfile.validate_proportions(
			overrides.get("proportions", {}), "%s appearance_overrides" % owner, errors
		)


static func _validate_people_model_proportion_deltas(
	_content, value: Dictionary, owner: String, errors: Array[String]
) -> void:
	for field_id in value:
		var key := String(field_id)
		if not HumanoidProfile.DEFAULT_PROPORTIONS.has(key):
			errors.append("%s has unsupported proportion delta %s." % [owner, key])
			continue
		if not Schema.is_number(value[field_id]):
			errors.append("%s proportion delta %s must be numeric." % [owner, key])
			continue
		var amount := float(value[field_id])
		if amount < -0.25 or amount > 0.25:
			errors.append("%s proportion delta %s must be between -0.25 and 0.25." % [owner, key])


static func _validate_people_model_final_proportions(
	content, people_id: String, deltas: Dictionary, owner: String, errors: Array[String]
) -> void:
	var proportions: Dictionary = content.get_people_default_proportions(people_id)
	_apply_proportion_deltas(content, proportions, deltas)
	for field_id in proportions:
		var amount := float(proportions[field_id])
		if amount < HumanoidProfile.MIN_PROPORTION or amount > HumanoidProfile.MAX_PROPORTION:
			errors.append(
				"%s %s must be between %.2f and %.2f."
				% [owner, String(field_id), HumanoidProfile.MIN_PROPORTION, HumanoidProfile.MAX_PROPORTION]
			)


static func _apply_proportion_deltas(_content, proportions: Dictionary, deltas: Dictionary) -> void:
	for field_id in deltas:
		var key := String(field_id)
		if not proportions.has(key) or not Schema.is_number(deltas[field_id]):
			continue
		proportions[key] = float(proportions[key]) + float(deltas[field_id])
