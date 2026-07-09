extends GutTest


func test_people_feature_drawer_routes_tanglekin_layers() -> void:
	var profile := {"people_id": "people_tanglekin"}

	assert_eq(
		HumanoidPeopleFeatureDrawer.people_feature_layer_ids(profile, "people_tanglekin", "back"),
		["feature_tanglekin_tail"]
	)
	assert_eq(
		HumanoidPeopleFeatureDrawer.people_feature_layer_ids(profile, "people_tanglekin", "front"),
		["feature_tanglekin_grasping_hands", "feature_tanglekin_muzzle"]
	)


func test_people_feature_drawer_routes_ravenfolk_layers_to_feature_drawer() -> void:
	var avatar := PeopleFeatureAvatarStub.new()
	var skin := Color(0.4, 0.3, 0.2)
	var proportions := {"head_size": 1.0, "torso_width": 1.0, "waist_width": 1.0}
	avatar.profile = {
		"people_id": "people_ravenfolk",
		"appearance":
		{
			"visual_model_id": "ravenfolk_test",
			"feature_ids":
			[
				"feature_ravenfolk_body_feathers",
				"feature_ravenfolk_head_crest",
				"feature_ravenfolk_beak",
				"feature_ravenfolk_tail_feathers",
				"feature_ravenfolk_quill_marks"
			]
		}
	}

	HumanoidPeopleFeatureDrawer.draw_layer(avatar, skin, proportions, "back")
	HumanoidPeopleFeatureDrawer.draw_layer(avatar, skin, proportions, "body")
	HumanoidPeopleFeatureDrawer.draw_layer(avatar, skin, proportions, "front")

	assert_true(avatar.calls.has("shape"))
	assert_true(avatar.calls.has("line"))
	assert_true(avatar.calls.has("circle"))


func test_people_feature_drawer_routes_front_only_people_features() -> void:
	assert_eq(
		HumanoidPeopleFeatureDrawer.people_feature_layer_ids({}, "people_tuskfolk", "body"), []
	)
	assert_eq(
		HumanoidPeopleFeatureDrawer.people_feature_layer_ids({}, "people_tuskfolk", "front"),
		["feature_tusks_broad"]
	)
	assert_eq(
		HumanoidPeopleFeatureDrawer.people_feature_layer_ids({}, "people_mirefolk", "body"), []
	)
	assert_eq(
		HumanoidPeopleFeatureDrawer.people_feature_layer_ids({}, "people_mirefolk", "front"),
		["feature_mirefolk_high_eyes"]
	)
	assert_eq(
		HumanoidPeopleFeatureDrawer.people_feature_layer_ids({}, "people_rootborn", "body"), []
	)
	assert_eq(
		HumanoidPeopleFeatureDrawer.people_feature_layer_ids({}, "people_rootborn", "front"),
		[
			"feature_rootborn_leaf_crown",
			"feature_rootborn_bark_marks",
			"feature_rootborn_branch_crown"
		]
	)


func test_debug_layer_entries_use_avatar_feature_layers() -> void:
	var avatar := PeopleFeatureAvatarStub.new()
	avatar.profile = {
		"appearance": {"feature_ids": ["feature_ravenfolk_beak", "feature_ravenfolk_head_crest"]}
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

	func _record(
		method_id: String, skin: Color, proportions: Dictionary, feature_ids: Array[String]
	) -> void:
		last_skin = skin
		last_proportions = proportions
		calls.append("%s:%s" % [method_id, ",".join(feature_ids)])

	func _proportion(proportions: Dictionary, field_id: String) -> float:
		return float(proportions.get(field_id, 1.0))

	func _side_turn_amount() -> float:
		return 0.0

	func _back_turn_amount() -> float:
		return 0.0

	func _front_turn_amount() -> float:
		return 1.0

	func _face_side() -> float:
		return 1.0

	func _facing_forward() -> Vector2:
		return Vector2.DOWN

	func _body_point(local_x: float, local_y: float) -> Vector2:
		return Vector2(local_x, local_y)

	func _body_polygon(local_points: Array) -> PackedVector2Array:
		var points := PackedVector2Array()
		for local_point in local_points:
			var point: Vector2 = local_point
			points.append(_body_point(point.x, point.y))
		return points

	func _head_turn_offset() -> Vector2:
		return Vector2.ZERO

	func _draw_shape(
		_points: PackedVector2Array,
		_fill: Color,
		_outline: Color = Color.TRANSPARENT,
		_outline_width: float = 0.0
	) -> void:
		calls.append("shape")

	func draw_line(
		_from: Vector2,
		_to: Vector2,
		_color: Color,
		_width: float = -1.0,
		_antialiased: bool = false
	) -> void:
		calls.append("line")

	func draw_circle(
		_position: Vector2,
		_radius: float,
		_color: Color,
		_filled: bool = true,
		_width: float = -1.0
	) -> void:
		calls.append("circle")
