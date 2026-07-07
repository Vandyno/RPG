extends GutTest


func test_people_feature_drawer_routes_tanglekin_and_ravenfolk_layers() -> void:
	var avatar := PeopleFeatureAvatarStub.new()
	var skin := Color(0.4, 0.3, 0.2)
	var proportions := {"height": 1.0}

	avatar.profile = {"people_id": "people_tanglekin"}
	HumanoidPeopleFeatureDrawer.draw_layer(avatar, skin, proportions, "back")
	HumanoidPeopleFeatureDrawer.draw_layer(avatar, skin, proportions, "front")
	avatar.profile = {"people_id": "people_ravenfolk"}
	HumanoidPeopleFeatureDrawer.draw_layer(avatar, skin, proportions, "back")
	HumanoidPeopleFeatureDrawer.draw_layer(avatar, skin, proportions, "body")
	HumanoidPeopleFeatureDrawer.draw_layer(avatar, skin, proportions, "front")

	assert_eq(
		avatar.calls,
		[
			(
				"tanglekin_back:"
				+ "feature_tanglekin_tail,"
				+ "feature_tanglekin_grasping_hands,"
				+ "feature_tanglekin_muzzle"
			),
			(
				"tanglekin_front:"
				+ "feature_tanglekin_tail,"
				+ "feature_tanglekin_grasping_hands,"
				+ "feature_tanglekin_muzzle"
			),
			(
				"ravenfolk_back:"
				+ "feature_ravenfolk_body_feathers,"
				+ "feature_ravenfolk_head_crest,"
				+ "feature_ravenfolk_beak"
			),
			(
				"ravenfolk_body:"
				+ "feature_ravenfolk_body_feathers,"
				+ "feature_ravenfolk_head_crest,"
				+ "feature_ravenfolk_beak"
			),
			(
				"ravenfolk_front:"
				+ "feature_ravenfolk_body_feathers,"
				+ "feature_ravenfolk_head_crest,"
				+ "feature_ravenfolk_beak"
			),
		]
	)
	assert_eq(avatar.last_skin, skin)
	assert_eq(avatar.last_proportions, proportions)


func test_people_feature_drawer_routes_front_only_people_features() -> void:
	var avatar := PeopleFeatureAvatarStub.new()
	var skin := Color(0.4, 0.3, 0.2)

	for people_id in ["people_tuskfolk", "people_mirefolk", "people_rootborn"]:
		avatar.profile = {"people_id": people_id}
		HumanoidPeopleFeatureDrawer.draw_layer(avatar, skin, {}, "body")
		HumanoidPeopleFeatureDrawer.draw_layer(avatar, skin, {}, "front")

	assert_eq(
		avatar.calls,
		[
			"tuskfolk:feature_tusks_broad",
			"mirefolk:feature_mirefolk_high_eyes",
			(
				"rootborn:"
				+ "feature_rootborn_leaf_crown,"
				+ "feature_rootborn_bark_marks,"
				+ "feature_rootborn_branch_crown"
			),
		]
	)


func test_debug_layer_entries_use_avatar_feature_layers() -> void:
	var avatar := PeopleFeatureAvatarStub.new()
	avatar.profile = {
		"appearance":
		{"feature_ids": ["feature_ravenfolk_beak", "feature_ravenfolk_head_crest"]}
	}

	assert_eq(
		HumanoidPeopleFeatureDrawer.debug_layer_entries(avatar, "people_ravenfolk", "front"),
		[
			"people_feature_front:feature_ravenfolk_beak",
			"people_feature_front:feature_ravenfolk_head_crest"
		]
	)


class PeopleFeatureAvatarStub:
	extends RefCounted

	var profile := {}
	var calls: Array[String] = []
	var last_skin := Color.TRANSPARENT
	var last_proportions := {}

	func _draw_tanglekin_back_feature(
		skin: Color, proportions: Dictionary, feature_ids: Array[String]
	) -> void:
		_record("tanglekin_back", skin, proportions, feature_ids)

	func _draw_tanglekin_feature(
		skin: Color, proportions: Dictionary, feature_ids: Array[String]
	) -> void:
		_record("tanglekin_front", skin, proportions, feature_ids)

	func _draw_ravenfolk_back_feature(
		skin: Color, proportions: Dictionary, feature_ids: Array[String]
	) -> void:
		_record("ravenfolk_back", skin, proportions, feature_ids)

	func _draw_ravenfolk_body_feature(
		skin: Color, proportions: Dictionary, feature_ids: Array[String]
	) -> void:
		_record("ravenfolk_body", skin, proportions, feature_ids)

	func _draw_ravenfolk_front_feature(
		skin: Color, proportions: Dictionary, feature_ids: Array[String]
	) -> void:
		_record("ravenfolk_front", skin, proportions, feature_ids)

	func _draw_tuskfolk_feature(
		skin: Color, proportions: Dictionary, feature_ids: Array[String]
	) -> void:
		_record("tuskfolk", skin, proportions, feature_ids)

	func _draw_mirefolk_feature(
		skin: Color, proportions: Dictionary, feature_ids: Array[String]
	) -> void:
		_record("mirefolk", skin, proportions, feature_ids)

	func _draw_rootborn_feature(
		skin: Color, proportions: Dictionary, feature_ids: Array[String]
	) -> void:
		_record("rootborn", skin, proportions, feature_ids)

	func _record(
		method_id: String, skin: Color, proportions: Dictionary, feature_ids: Array[String]
	) -> void:
		last_skin = skin
		last_proportions = proportions
		calls.append("%s:%s" % [method_id, ",".join(feature_ids)])
