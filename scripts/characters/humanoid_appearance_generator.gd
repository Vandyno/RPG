class_name HumanoidAppearanceGenerator
extends RefCounted

const HumanoidProfile = preload("res://scripts/characters/humanoid_profile.gd")

const DEFAULT_JITTER_STRENGTH := 0.025
const MAX_JITTER_STRENGTH := 0.08

const APPEARANCE_FIELDS := [
	"body_plan_id",
	"head_id",
	"palette_id",
	"hair_id",
	"hair_color_id",
	"eye_id",
	"marking_id",
	"feature_ids",
	"visual_model_id",
	"base_clothing_id"
]


static func generate_appearance(
	people_id: String,
	definition: Dictionary,
	visual_model: Dictionary,
	seed_key: String = "",
	options: Dictionary = {}
) -> Dictionary:
	if people_id.is_empty() or definition.is_empty() or visual_model.is_empty():
		return HumanoidProfile.appearance_from_data({})
	var variant := _select_variant(people_id, visual_model, seed_key, options)
	if variant.is_empty():
		return HumanoidProfile.appearance_from_data({})

	var variant_id := String(variant.get("id", ""))
	var body_plans := _array_field(definition.get("body_plans", []))
	var proportions := HumanoidProfile.proportions_from_data(
		definition.get("default_proportions", {})
	)
	_apply_proportion_deltas(proportions, _dictionary_field(variant.get("proportion_deltas", {})))
	if options.get("proportion_jitter", false) is bool and options.get("proportion_jitter") == true:
		var strength := _jitter_strength(options.get("jitter_strength", DEFAULT_JITTER_STRENGTH))
		_apply_proportion_jitter(proportions, people_id, variant_id, seed_key, strength)

	var appearance := {
		"people_id": people_id,
		"body_plan_id":
		String(body_plans[0]) if not body_plans.is_empty() else HumanoidProfile.DEFAULT_BODY_PLAN_ID,
		"head_id": String(variant.get("head_id", "")),
		"palette_id": String(variant.get("palette_id", "")),
		"hair_id": String(variant.get("hair_id", "")),
		"hair_color_id": String(variant.get("hair_color_id", HumanoidProfile.DEFAULT_HAIR_COLOR_ID)),
		"eye_id": HumanoidProfile.DEFAULT_EYE_ID,
		"marking_id": String(variant.get("marking_id", "")),
		"feature_ids": HumanoidProfile.string_array(variant.get("feature_ids", [])),
		"visual_model_id": variant_id,
		"base_clothing_id": HumanoidProfile.DEFAULT_BASE_CLOTHING_ID,
		"proportions": proportions
	}
	var overrides := _dictionary_field(options.get("appearance_overrides", {}))
	if not overrides.is_empty():
		appearance = apply_appearance_overrides(appearance, overrides, people_id)
	return HumanoidProfile.appearance_from_data(appearance, people_id)


static func apply_appearance_overrides(
	base_appearance: Dictionary, overrides: Dictionary, people_id: String
) -> Dictionary:
	var appearance := base_appearance.duplicate(true)
	for field_id in APPEARANCE_FIELDS:
		if not overrides.has(field_id):
			continue
		if field_id == "feature_ids":
			appearance[field_id] = HumanoidProfile.string_array(overrides.get(field_id, []))
		else:
			appearance[field_id] = overrides[field_id]
	if overrides.has("proportions"):
		var current := HumanoidProfile.proportions_from_data(appearance.get("proportions", {}))
		var proportion_overrides := _dictionary_field(overrides.get("proportions", {}))
		for field_id in proportion_overrides:
			var key := String(field_id)
			if not HumanoidProfile.DEFAULT_PROPORTIONS.has(key):
				continue
			current[key] = proportion_overrides[field_id]
		appearance["proportions"] = HumanoidProfile.proportions_from_data(current)
	appearance["people_id"] = people_id
	return appearance


static func _select_variant(
	people_id: String, visual_model: Dictionary, seed_key: String, options: Dictionary
) -> Dictionary:
	var variants := _array_field(visual_model.get("variants", []))
	if variants.is_empty():
		return {}
	var variant_id := _string_field(options.get("variant_id", ""))
	if not variant_id.is_empty():
		for variant_value in variants:
			if variant_value is Dictionary and String(variant_value.get("id", "")) == variant_id:
				return variant_value.duplicate(true)
		return {}
	var key := "%s:%s" % [people_id, seed_key]
	if seed_key.is_empty():
		key = people_id
	var index := _stable_index(key, variants.size())
	var selected: Variant = variants[index]
	if selected is Dictionary:
		return selected.duplicate(true)
	return {}


static func _apply_proportion_deltas(proportions: Dictionary, deltas: Dictionary) -> void:
	for field_id in deltas:
		var key := String(field_id)
		if not proportions.has(key) or not _is_number(deltas[field_id]):
			continue
		proportions[key] = float(proportions[key]) + float(deltas[field_id])


static func _apply_proportion_jitter(
	proportions: Dictionary, people_id: String, variant_id: String, seed_key: String, strength: float
) -> void:
	if strength <= 0.0:
		return
	for field_id in proportions:
		var jitter_key := "%s:%s:%s:%s" % [people_id, variant_id, seed_key, String(field_id)]
		var index := _stable_index(jitter_key, 2001)
		var amount := (float(index) / 1000.0) - 1.0
		proportions[field_id] = clampf(
			float(proportions[field_id]) + amount * strength,
			HumanoidProfile.MIN_PROPORTION,
			HumanoidProfile.MAX_PROPORTION
		)


static func _jitter_strength(value: Variant) -> float:
	if not _is_number(value):
		return DEFAULT_JITTER_STRENGTH
	return clampf(float(value), 0.0, MAX_JITTER_STRENGTH)


static func _stable_index(text: String, size: int) -> int:
	if size <= 0:
		return 0
	var total: int = 0
	for index in text.length():
		total += text.unicode_at(index) * (index + 1)
	return total % size


static func _array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []


static func _dictionary_field(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


static func _string_field(value: Variant) -> String:
	if value is String:
		return value
	return ""


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
