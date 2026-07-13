class_name HumanoidPeopleFeatureDrawer
extends RefCounted

const HumanoidProfile = preload("res://scripts/characters/humanoid_profile.gd")
const HumanoidRavenfolkFeatureDrawer = preload(
	"res://scripts/characters/humanoid_ravenfolk_feature_drawer.gd"
)
const HumanoidSpeciesFeatureDrawer = preload(
	"res://scripts/characters/humanoid_species_feature_drawer.gd"
)

const PEOPLE_FEATURE_LAYER_BACK := "back"
const PEOPLE_FEATURE_LAYER_BODY := "body"
const PEOPLE_FEATURE_LAYER_FRONT := "front"


static func draw_layer(avatar, skin: Color, proportions: Dictionary, layer_id: String) -> void:
	var people_id := String(avatar.profile.get("people_id", ""))
	var feature_ids := appearance_feature_ids(avatar.profile, people_id)
	var procedural_feature_ids := feature_ids
	if HumanoidSpeciesFeatureDrawer.draw_layer(
		avatar, people_id, skin, proportions, procedural_feature_ids, layer_id
	):
		return
	if people_id == "people_ravenfolk":
		var appearance: Dictionary = avatar.profile.get("appearance", {})
		if layer_id == PEOPLE_FEATURE_LAYER_BACK:
			HumanoidRavenfolkFeatureDrawer.draw_back(
				avatar, skin, proportions, procedural_feature_ids, appearance
			)
		elif layer_id == PEOPLE_FEATURE_LAYER_BODY:
			HumanoidRavenfolkFeatureDrawer.draw_body(
				avatar, skin, proportions, procedural_feature_ids, appearance
			)
		elif layer_id == PEOPLE_FEATURE_LAYER_FRONT:
			HumanoidRavenfolkFeatureDrawer.draw_front(
				avatar, skin, proportions, procedural_feature_ids, appearance
			)
		return


static func draw_headgear_face_overlay(avatar, skin: Color, proportions: Dictionary) -> void:
	var people_id := String(avatar.profile.get("people_id", ""))
	if people_id != "people_mirefolk":
		return
	var feature_ids := appearance_feature_ids(avatar.profile, people_id)
	var appearance: Dictionary = avatar.profile.get("appearance", {})
	HumanoidSpeciesFeatureDrawer.draw_headgear_face_overlay(
		avatar, people_id, skin, proportions, feature_ids, appearance
	)


static func debug_layer_entries(avatar, people_id: String, layer_id: String) -> Array[String]:
	var entries: Array[String] = []
	for feature_id in people_feature_layer_ids(avatar.profile, people_id, layer_id):
		entries.append("people_feature_%s:%s" % [layer_id, feature_id])
	return entries


static func people_feature_layer_ids(
	profile: Dictionary, people_id: String, layer_id: String
) -> Array[String]:
	var source_ids := appearance_feature_ids(profile, people_id)
	return HumanoidSpeciesFeatureDrawer.feature_ids_for_layer(source_ids, people_id, layer_id)


static func appearance_feature_ids(profile: Dictionary, people_id: String) -> Array[String]:
	var appearance: Dictionary = profile.get("appearance", {})
	var feature_ids := HumanoidProfile.string_array(appearance.get("feature_ids", []))
	if people_id == "people_mirefolk" and not feature_ids.has("feature_mirefolk_high_eyes"):
		feature_ids.append("feature_mirefolk_high_eyes")
	if not feature_ids.is_empty():
		return feature_ids
	var defaults := {
		"people_tanglekin":
		["feature_tanglekin_tail", "feature_tanglekin_grasping_hands", "feature_tanglekin_muzzle"],
		"people_tuskfolk": ["feature_tusks_broad"],
		"people_mirefolk": ["feature_mirefolk_high_eyes"],
		"people_ravenfolk":
		[
			"feature_ravenfolk_body_feathers",
			"feature_ravenfolk_head_crest",
			"feature_ravenfolk_beak"
		],
		"people_rootborn":
		[
			"feature_rootborn_leaf_crown",
			"feature_rootborn_bark_marks",
			"feature_rootborn_branch_crown"
		]
	}
	var fallback: Array[String] = []
	for feature_id in defaults.get(people_id, []):
		fallback.append(str(feature_id))
	return fallback


static func should_draw_hair(people_id: String) -> bool:
	return people_id == "people_human"


static func should_draw_generic_face(people_id: String) -> bool:
	return not ["people_tanglekin", "people_mirefolk", "people_ravenfolk"].has(people_id)
