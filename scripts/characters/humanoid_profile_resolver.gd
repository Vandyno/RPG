class_name HumanoidProfileResolver
extends RefCounted

const HumanoidAppearanceGenerator = preload(
	"res://scripts/characters/humanoid_appearance_generator.gd"
)
const HumanoidProfile = preload("res://scripts/characters/humanoid_profile.gd")
const MAX_JITTER_STRENGTH := HumanoidAppearanceGenerator.MAX_JITTER_STRENGTH


static func resolved_character_profile(content, profile_id: String) -> Dictionary:
	var source: Dictionary = _dictionary_field(content.get_authored_character_profile(profile_id))
	var resolved_source := profile_source_with_generated_appearance(content, source)
	var profile := HumanoidProfile.from_data(resolved_source)
	profile["derived_bonuses"] = people_bonuses(content, String(profile.get("people_id", "")))
	_apply_people_visual_defaults(content, profile, resolved_source)
	return profile


static func people_bonuses(content, people_id: String) -> Dictionary:
	var definition: Dictionary = content.get_people(people_id)
	return HumanoidProfile.number_dictionary(definition.get("bonuses", {}))


static func people_visual_variant(content, people_id: String, variant_id: String) -> Dictionary:
	var model: Dictionary = content.get_people_visual_model(people_id)
	for variant in _array_field(model.get("variants", [])):
		if variant is Dictionary and String(variant.get("id", "")) == variant_id:
			return variant.duplicate(true)
	return {}


static func people_visual_variant_profile(
	content, people_id: String, variant_id: String, character_id: String = ""
) -> Dictionary:
	var profile_id := character_id
	if profile_id.is_empty():
		profile_id = "preview_%s" % variant_id
	return generated_people_profile(
		content,
		people_id,
		profile_id,
		variant_id,
		{"variant_id": variant_id, "proportion_jitter": false}
	)


static func generated_people_appearance(
	content, people_id: String, seed_key: String = "", options: Dictionary = {}
) -> Dictionary:
	return HumanoidAppearanceGenerator.generate_appearance(
		people_id,
		content.get_people(people_id),
		content.get_people_visual_model(people_id),
		seed_key,
		options
	)


static func generated_people_profile(
	content, people_id: String, character_id: String, seed_key: String = "", options: Dictionary = {}
) -> Dictionary:
	var profile_id := character_id
	if profile_id.is_empty():
		profile_id = "generated_%s" % people_id
	var appearance := generated_people_appearance(content, people_id, seed_key, options)
	return HumanoidProfile.from_data(
		{
			"character_id": profile_id,
			"people_id": people_id,
			"state": "alive",
			"appearance": appearance,
			"inventory_owner_id": profile_id,
			"equipment_owner_id": profile_id,
			"spellbook_owner_id": profile_id
		}
	)


static func people_default_proportions(content, people_id: String) -> Dictionary:
	var definition: Dictionary = content.get_people(people_id)
	return HumanoidProfile.proportions_from_data(definition.get("default_proportions", {}))


static func profile_source_with_generated_appearance(
	content, source_profile: Dictionary
) -> Dictionary:
	var generation := _dictionary_field(source_profile.get("appearance_generation", {}))
	if generation.is_empty():
		return source_profile
	var resolved := source_profile.duplicate(true)
	var people_id := str(resolved.get("people_id", ""))
	var seed_key := ""
	if generation.get("seed", "") is String:
		seed_key = String(generation.get("seed", ""))
	var appearance := generated_people_appearance(
		content, people_id, seed_key, safe_appearance_generation_options(generation)
	)
	var authored_appearance := _dictionary_field(source_profile.get("appearance", {}))
	if not authored_appearance.is_empty():
		appearance = HumanoidAppearanceGenerator.apply_appearance_overrides(
			appearance, authored_appearance, people_id
		)
	appearance["people_id"] = people_id
	resolved["appearance"] = appearance
	return resolved


static func safe_appearance_generation_options(generation: Dictionary) -> Dictionary:
	var options: Dictionary = {}
	if generation.get("variant_id", "") is String:
		options["variant_id"] = String(generation.get("variant_id", ""))
	if generation.get("proportion_jitter", false) is bool:
		options["proportion_jitter"] = generation.get("proportion_jitter", false) == true
	if _is_number(generation.get("jitter_strength")):
		options["jitter_strength"] = generation.get("jitter_strength")
	if _is_number(generation.get("marking_chance")):
		options["marking_chance"] = generation.get("marking_chance")
	if generation.get("appearance_overrides", {}) is Dictionary:
		options["appearance_overrides"] = generation.get("appearance_overrides", {})
	return options


static func _apply_people_visual_defaults(
	content, profile: Dictionary, source_profile: Dictionary
) -> void:
	var people_id := String(profile.get("people_id", ""))
	var defaults := people_default_proportions(content, people_id)
	var appearance: Dictionary = profile.get("appearance", {})
	var current: Dictionary = appearance.get("proportions", {}).duplicate(true)
	var source_appearance := _dictionary_field(source_profile.get("appearance", {}))
	var authored := _dictionary_field(source_appearance.get("proportions", {}))
	for field_id in defaults:
		if not authored.has(field_id):
			current[field_id] = defaults[field_id]
	appearance["proportions"] = current
	profile["appearance"] = appearance


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []


static func _dictionary_field(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
