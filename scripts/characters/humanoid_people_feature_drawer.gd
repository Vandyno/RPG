class_name HumanoidPeopleFeatureDrawer
extends RefCounted

const PEOPLE_FEATURE_LAYER_BACK := "back"
const PEOPLE_FEATURE_LAYER_BODY := "body"
const PEOPLE_FEATURE_LAYER_FRONT := "front"


static func draw_layer(avatar, skin: Color, proportions: Dictionary, layer_id: String) -> void:
	var people_id := String(avatar.profile.get("people_id", ""))
	var feature_ids: Array[String] = avatar._appearance_feature_ids(people_id)
	if people_id == "people_tanglekin":
		if layer_id == PEOPLE_FEATURE_LAYER_BACK:
			avatar._draw_tanglekin_back_feature(skin, proportions, feature_ids)
		elif layer_id == PEOPLE_FEATURE_LAYER_FRONT:
			avatar._draw_tanglekin_feature(skin, proportions, feature_ids)
		return
	if people_id == "people_ravenfolk":
		if layer_id == PEOPLE_FEATURE_LAYER_BACK:
			avatar._draw_ravenfolk_back_feature(skin, proportions, feature_ids)
		elif layer_id == PEOPLE_FEATURE_LAYER_BODY:
			avatar._draw_ravenfolk_body_feature(skin, proportions, feature_ids)
		elif layer_id == PEOPLE_FEATURE_LAYER_FRONT:
			avatar._draw_ravenfolk_front_feature(skin, proportions, feature_ids)
		return
	if layer_id != PEOPLE_FEATURE_LAYER_FRONT:
		return
	if people_id == "people_tuskfolk":
		avatar._draw_tuskfolk_feature(skin, proportions, feature_ids)
	elif people_id == "people_mirefolk":
		avatar._draw_mirefolk_feature(skin, proportions, feature_ids)
	elif people_id == "people_rootborn":
		avatar._draw_rootborn_feature(skin, proportions, feature_ids)


static func debug_layer_entries(avatar, people_id: String, layer_id: String) -> Array[String]:
	var entries: Array[String] = []
	for feature_id in avatar._people_feature_layer_ids(people_id, layer_id):
		entries.append("people_feature_%s:%s" % [layer_id, feature_id])
	return entries
