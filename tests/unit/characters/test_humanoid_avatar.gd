# gdlint:disable=max-public-methods
extends GutTest

const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")
const PlayerController = preload("res://scripts/player/player_controller.gd")
const ContentDatabase = preload("res://scripts/data/content_database.gd")
const FacingBuckets = preload("res://scripts/core/facing_buckets.gd")
const ItemVisual2D = preload("res://scripts/items/item_visual_2d.gd")
const HumanoidHeldItemDrawer = preload("res://scripts/characters/humanoid_held_item_drawer.gd")
const HumanoidPeopleFeatureDrawer = preload(
	"res://scripts/characters/humanoid_people_feature_drawer.gd"
)
const HumanoidSpeciesFeatureDrawer = preload(
	"res://scripts/characters/humanoid_species_feature_drawer.gd"
)


class ContentStub:
	var items := {
		"item_training_sword":
		{
			"id": "item_training_sword",
			"avatar_visual":
			{
				"avatar_slot": "right_hand",
				"visual_layer_id": "placeholder_sword",
				"accepted_placeholder": true
			}
		},
		"item_test_polearm":
		{
			"id": "item_test_polearm",
			"avatar_visual":
			{
				"avatar_slot": "right_hand",
				"visual_layer_id": "placeholder_polearm",
				"accepted_placeholder": true
			}
		},
		"item_hunting_bow":
		{
			"id": "item_hunting_bow",
			"avatar_visual":
			{
				"avatar_slot": "right_hand",
				"visual_layer_id": "placeholder_bow",
				"accepted_placeholder": true
			}
		},
		"item_test_buckler":
		{
			"id": "item_test_buckler",
			"avatar_visual":
			{
				"avatar_slot": "left_hand",
				"visual_layer_id": "placeholder_buckler",
				"accepted_placeholder": true
			}
		},
		"item_test_leather_vest":
		{
			"id": "item_test_leather_vest",
			"avatar_visual":
			{
				"avatar_slot": "chest",
				"visual_layer_id": "placeholder_leather_vest",
				"accepted_placeholder": true
			}
		},
		"item_smith_apron":
		{
			"id": "item_smith_apron",
			"avatar_visual":
			{
				"avatar_slot": "chest",
				"visual_layer_id": "placeholder_smith_apron",
				"accepted_placeholder": true
			}
		},
		"item_test_leather_cap":
		{
			"id": "item_test_leather_cap",
			"avatar_visual":
			{
				"avatar_slot": "head",
				"visual_layer_id": "placeholder_leather_cap",
				"accepted_placeholder": true
			}
		},
		"item_test_trousers":
		{
			"id": "item_test_trousers",
			"avatar_visual":
			{
				"avatar_slot": "legs",
				"visual_layer_id": "placeholder_trousers",
				"accepted_placeholder": true
			}
		},
		"item_test_gloves":
		{
			"id": "item_test_gloves",
			"avatar_visual":
			{
				"avatar_slot": "gloves",
				"visual_layer_id": "placeholder_gloves",
				"accepted_placeholder": true
			}
		},
		"item_test_boots":
		{
			"id": "item_test_boots",
			"avatar_visual":
			{
				"avatar_slot": "boots",
				"visual_layer_id": "placeholder_boots",
				"accepted_placeholder": true
			}
		},
		"item_test_cloak":
		{
			"id": "item_test_cloak",
			"avatar_visual":
			{
				"avatar_slot": "back",
				"visual_layer_id": "placeholder_cloak",
				"accepted_placeholder": true
			}
		}
	}

	func get_item(item_id: String) -> Dictionary:
		return items.get(item_id, {})


func test_avatar_has_required_body_stack_and_equipment_refresh() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup(
		{
			"character_id": "char_test",
			"appearance":
			{"proportions": {"body_height": 0.9, "shoulder_width": 1.2, "hand_size": 0.8}}
		}
	)

	assert_true(avatar.has_body_stack())
	assert_eq(avatar.get_proportion("body_height"), 0.9)
	assert_eq(avatar.get_proportion("shoulder_width"), 1.2)
	assert_eq(avatar.get_proportion("hand_size"), 0.8)
	assert_false(avatar.has_equipment_visual("right_hand"))

	avatar.set_equipped_items({"right_hand": "item_training_sword"}, ContentStub.new())

	assert_true(avatar.has_equipment_visual("right_hand"))


func test_avatar_locomotion_advances_walk_cycle() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup()

	avatar.set_locomotion(true, false, 0.1)

	assert_eq(avatar.locomotion_state, "walk")
	assert_false(avatar.is_sneaking)
	assert_gt(avatar.animation_time, 0.0)
	assert_gt(avatar.move_intensity, 0.0)


func test_avatar_sneak_and_idle_locomotion_states() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup()

	avatar.set_locomotion(true, true, 0.1)
	var sneak_time := avatar.animation_time
	assert_eq(avatar.locomotion_state, "sneak")

	avatar.set_locomotion(false, true, 0.1)
	var idle_delta := avatar.animation_time - sneak_time

	assert_eq(avatar.locomotion_state, "idle")
	assert_true(avatar.is_sneaking)
	assert_gt(idle_delta, 0.0)
	assert_lt(idle_delta, 0.3)


func test_avatar_sneak_toggle_keeps_visible_crouch_when_idle() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup()

	avatar.set_sneaking(true)

	assert_true(avatar.is_sneaking)
	assert_eq(avatar.locomotion_state, "idle")
	assert_gt(avatar._sneak_crouch_offset(), 0.0)


func test_avatar_stride_follows_facing_direction() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup()

	avatar.set_facing_direction(Vector2.RIGHT)
	avatar.set_locomotion(true, false, 0.1)
	var right_stride: Vector2 = avatar._stride_offset(-1.0)

	avatar.set_facing_direction(Vector2.DOWN)
	var down_stride: Vector2 = avatar._stride_offset(-1.0)

	assert_gt(absf(right_stride.x), absf(right_stride.y))
	assert_gt(absf(down_stride.y), absf(down_stride.x))


func test_avatar_quantizes_visual_facing_to_sixteen_buckets() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup()
	var seen := {}

	for index in 16:
		var angle := TAU * float(index) / 16.0
		avatar.set_facing_direction(Vector2(cos(angle), sin(angle)))
		seen[avatar.get_facing_bucket_id()] = true

	assert_eq(avatar.get_facing_bucket_count(), 16)
	assert_eq(seen.size(), 16)
	avatar.set_facing_direction(Vector2.RIGHT)
	assert_eq(avatar.get_facing_bucket_id(), "east")
	avatar.set_facing_direction(Vector2.DOWN)
	assert_eq(avatar.get_facing_bucket_id(), "south")
	avatar.set_facing_direction(Vector2.LEFT)
	assert_eq(avatar.get_facing_bucket_id(), "west")
	avatar.set_facing_direction(Vector2.UP)
	assert_eq(avatar.get_facing_bucket_id(), "north")


func test_avatar_stores_snapped_facing_not_raw_analog_angle() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup()
	var raw_direction := Vector2(1.0, 0.31)
	var snapped := FacingBuckets.snap_direction(raw_direction)

	avatar.set_facing_direction(raw_direction)

	assert_eq(avatar.facing_direction, snapped)
	assert_ne(avatar.facing_direction, raw_direction.normalized())


func test_avatar_turn_profile_changes_across_sixteen_buckets() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup()
	var signatures := {}

	for index in avatar.get_facing_bucket_count():
		var angle := TAU * float(index) / float(avatar.get_facing_bucket_count())
		avatar.set_facing_direction(Vector2(cos(angle), sin(angle)))
		var profile := avatar.get_debug_turn_profile()
		var axis: Vector2 = profile["body_axis"]
		var head: Vector2 = profile["head_offset"]
		var signature := (
			"%0.2f:%0.2f:%0.2f:%0.1f:%0.2f:%0.2f:%0.2f"
			% [
				float(profile["front"]),
				float(profile["side"]),
				float(profile["back"]),
				float(profile["face_side"]),
				axis.x,
				axis.y,
				head.y
			]
		)
		signatures[signature] = true

	assert_gte(signatures.size(), 12)

	avatar.set_facing_direction(Vector2.DOWN)
	var front := avatar.get_debug_turn_profile()
	avatar.set_facing_direction(Vector2.RIGHT)
	var side := avatar.get_debug_turn_profile()
	avatar.set_facing_direction(Vector2.UP)
	var back := avatar.get_debug_turn_profile()
	avatar.set_facing_direction(Vector2(1, -1))
	var back_diagonal := avatar.get_debug_turn_profile()

	assert_gt(float(front["front"]), 0.9)
	assert_gt(float(side["side"]), 0.9)
	assert_gt(float(back["back"]), 0.9)
	assert_gt(float(back_diagonal["side"]), 0.5)
	assert_gt(float(back_diagonal["back"]), 0.5)


func test_avatar_exposes_body_equipment_slots_for_armour_generation() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup()
	var slots := avatar.get_equipment_body_slots()

	for slot_id in ["head", "chest", "legs", "gloves", "boots", "back"]:
		assert_true(slots.has(slot_id))

	var anchors := avatar.get_body_part_anchors()
	for anchor_id in [
		"head",
		"chest",
		"waist",
		"left_hand",
		"right_hand",
		"weapon_hand",
		"draw_hand",
		"off_hand",
		"bow_hand",
		"left_foot",
		"right_foot"
	]:
		assert_true(anchors.has(anchor_id))
		assert_true(anchors[anchor_id] is Vector2)
	assert_lt((anchors["left_hand"] as Vector2).x, (anchors["right_hand"] as Vector2).x)
	assert_eq(anchors["weapon_hand"], anchors["right_hand"])
	assert_eq(anchors["bow_hand"], anchors["left_hand"])
	assert_gt((anchors["left_foot"] as Vector2).distance_to(anchors["right_foot"] as Vector2), 1.0)


func test_avatar_side_face_features_turn_with_character() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup()

	avatar.set_facing_direction(Vector2.RIGHT)
	var right_features: Dictionary = avatar._face_feature_positions(1.0)
	avatar.set_facing_direction(Vector2.LEFT)
	var left_features: Dictionary = avatar._face_feature_positions(1.0)

	assert_true(right_features.has("eye_a"))
	assert_true(right_features.has("mouth_a"))
	assert_gt((right_features["mouth_a"] as Vector2).x, 0.0)
	assert_lt((left_features["mouth_a"] as Vector2).x, 0.0)
	assert_gt((right_features["eye_a"] as Vector2).x, (left_features["eye_a"] as Vector2).x)


func test_avatar_face_markings_hide_on_far_side_and_back() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup({"appearance": {"marking_id": "marking_brow_left"}})

	avatar.set_facing_direction(Vector2.DOWN)
	assert_true(avatar._should_draw_marking("marking_brow_left"))
	assert_true(avatar.get_debug_draw_layer_order().has("marking"))

	avatar.set_facing_direction(Vector2.RIGHT)
	assert_false(avatar._should_draw_marking("marking_brow_left"))
	assert_false(avatar.get_debug_draw_layer_order().has("marking"))

	avatar.set_facing_direction(Vector2.LEFT)
	assert_true(avatar._should_draw_marking("marking_brow_left"))

	avatar.set_facing_direction(Vector2.UP)
	assert_false(avatar._should_draw_marking("marking_brow_left"))

	avatar.setup({"appearance": {"marking_id": "marking_cheek_dots"}})
	avatar.set_facing_direction(Vector2.DOWN)
	assert_true(avatar._should_draw_marking("marking_cheek_dots"))

	avatar.set_facing_direction(Vector2.RIGHT)
	assert_false(avatar._should_draw_marking("marking_cheek_dots"))

	avatar.set_facing_direction(Vector2.LEFT)
	assert_true(avatar._should_draw_marking("marking_cheek_dots"))


func test_avatar_face_marking_points_turn_to_near_side() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup()

	avatar.set_facing_direction(Vector2.RIGHT)
	var east_point := avatar._face_mark_point(3.8, -17.2, 1.0)
	avatar.set_facing_direction(Vector2.LEFT)
	var west_point := avatar._face_mark_point(-3.8, -17.2, 1.0)

	assert_gt(east_point.x, 0.0)
	assert_lt(west_point.x, 0.0)

	avatar.set_facing_direction(Vector2.DOWN)
	var left_cheek_point := avatar._face_mark_point(-2.6, -11.7, 1.0)
	assert_lt(left_cheek_point.x, 0.0)


func test_avatar_mirefolk_belly_is_front_surface_only() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup({"people_id": "people_mirefolk"})

	avatar.set_facing_direction(Vector2.DOWN)
	assert_true(avatar._front_surface_visible())

	avatar.set_facing_direction(Vector2.RIGHT)
	assert_true(avatar._front_surface_visible())

	avatar.set_facing_direction(Vector2.UP)
	assert_false(avatar._front_surface_visible())


func test_avatar_tanglekin_side_muzzle_is_rounded_and_mirrored() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup({"people_id": "people_tanglekin"})

	avatar.set_facing_direction(Vector2.RIGHT)
	var east_rect := HumanoidSpeciesFeatureDrawer.tanglekin_side_muzzle_rect(avatar, 1.0)
	avatar.set_facing_direction(Vector2.LEFT)
	var west_rect := HumanoidSpeciesFeatureDrawer.tanglekin_side_muzzle_rect(avatar, 1.0)

	assert_gt(east_rect.size.x, east_rect.size.y)
	assert_gt(east_rect.get_center().x, 0.0)
	assert_lt(west_rect.get_center().x, 0.0)
	assert_almost_eq(absf(east_rect.get_center().x), absf(west_rect.get_center().x), 0.001)


func test_avatar_ravenfolk_side_eye_and_beak_are_mirrored_and_compact() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup({"people_id": "people_ravenfolk"})

	avatar.set_facing_direction(Vector2.RIGHT)
	var east_eye := avatar._ravenfolk_near_eye_point(1.0)
	var east_beak := avatar._ravenfolk_side_beak_points(1.0)
	avatar.set_facing_direction(Vector2.LEFT)
	var west_eye := avatar._ravenfolk_near_eye_point(1.0)
	var west_beak := avatar._ravenfolk_side_beak_points(1.0)

	assert_gt(east_eye.x, 0.0)
	assert_lt(west_eye.x, 0.0)
	assert_almost_eq(absf(east_eye.x), absf(west_eye.x), 0.001)
	assert_almost_eq(east_eye.y, west_eye.y, 0.001)
	assert_lt(absf((east_beak[1] as Vector2).x), 5.4)
	assert_lt(absf((west_beak[1] as Vector2).x), 5.4)
	assert_almost_eq(absf((east_beak[1] as Vector2).x), absf((west_beak[1] as Vector2).x), 0.001)


func test_avatar_tuskfolk_side_tusk_stays_mounted_to_face() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup({"people_id": "people_tuskfolk"})

	avatar.set_facing_direction(Vector2.RIGHT)
	var points := HumanoidSpeciesFeatureDrawer.tuskfolk_side_tusk_points(avatar, 1.0, 9.2)
	var base_top: Vector2 = points[0]
	var tip: Vector2 = points[1]
	var base_bottom: Vector2 = points[2]

	assert_gt(base_top.x, 0.0)
	assert_gt(tip.x, base_top.x)
	assert_lt(tip.x, 5.8)
	assert_lt(base_bottom.x, tip.x)
	assert_lt(absf(base_top.y - base_bottom.y), 1.5)


func test_avatar_layers_tanglekin_tail_behind_body() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup(
		{
			"character_id": "char_tanglekin_layer_test",
			"people_id": "people_tanglekin",
			"appearance":
			{
				"feature_ids":
				[
					"feature_tanglekin_tail",
					"feature_tanglekin_grasping_hands",
					"feature_tanglekin_muzzle"
				]
			}
		}
	)
	avatar.set_facing_direction(Vector2.DOWN)
	var order := avatar.get_debug_draw_layer_order()

	assert_lt(order.find("people_feature_back:feature_tanglekin_tail"), order.find("body:torso"))
	assert_eq(order.find("people_feature_front:feature_tanglekin_tail"), -1)
	assert_gt(order.find("people_feature_front:feature_tanglekin_muzzle"), order.find("body:head"))


func test_avatar_places_far_hand_behind_torso_on_front_diagonals() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup()

	avatar.set_facing_direction(Vector2.DOWN)
	assert_eq(avatar._near_hand_sides({}), [-1.0, 1.0])

	avatar.set_facing_direction(Vector2(1.0, 1.0))
	assert_eq(avatar._near_hand_sides({}), [1.0])
	assert_eq(avatar._hand_sides_for_layer("back", {}), [-1.0])
	assert_eq(avatar._hand_sides_for_layer("front", {}), [1.0])

	avatar.set_facing_direction(Vector2(-1.0, 1.0))
	assert_eq(avatar._near_hand_sides({}), [-1.0])
	assert_eq(avatar._hand_sides_for_layer("back", {}), [1.0])
	assert_eq(avatar._hand_sides_for_layer("front", {}), [-1.0])


func test_avatar_keeps_mirefolk_eyes_in_face_feature_layer() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup(
		{
			"character_id": "char_mirefolk_layer_test",
			"people_id": "people_mirefolk",
			"appearance": {"feature_ids": ["feature_mirefolk_reed_marks"]}
		}
	)
	var feature_ids := HumanoidPeopleFeatureDrawer.appearance_feature_ids(
		avatar.profile, "people_mirefolk"
	)
	var order := avatar.get_debug_draw_layer_order()

	assert_true(feature_ids.has("feature_mirefolk_high_eyes"))
	assert_gt(
		order.find("people_feature_front:feature_mirefolk_high_eyes"), order.find("body:head")
	)


func test_avatar_layers_ravenfolk_feather_anatomy() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup(
		{
			"character_id": "char_ravenfolk_layer_test",
			"people_id": "people_ravenfolk",
			"appearance":
			{
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
	)
	var order := avatar.get_debug_draw_layer_order()

	assert_lt(
		order.find("people_feature_back:feature_ravenfolk_tail_feathers"), order.find("body:feet")
	)
	assert_gt(
		order.find("people_feature_body:feature_ravenfolk_body_feathers"), order.find("body:torso")
	)
	assert_lt(
		order.find("people_feature_body:feature_ravenfolk_body_feathers"), order.find("body:head")
	)
	assert_gt(order.find("people_feature_front:feature_ravenfolk_beak"), order.find("body:head"))
	assert_gt(
		order.find("people_feature_front:feature_ravenfolk_head_crest"), order.find("body:head")
	)


func test_avatar_draws_body_features_beneath_chest_equipment() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup(
		{
			"people_id": "people_ravenfolk",
			"appearance": {"feature_ids": ["feature_ravenfolk_body_feathers"]}
		}
	)
	avatar.equipped_visuals["chest"] = {"visual_layer_id": "placeholder_iron_cuirass"}

	var order := avatar.get_debug_draw_layer_order()
	assert_lt(
		order.find("people_feature_body:feature_ravenfolk_body_feathers"),
		order.find("equipment:chest")
	)
	assert_eq(order.find("people_feature_front:feature_ravenfolk_tail_feathers"), -1)


func test_held_equipment_follows_near_and_far_hand_layers() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup(
		{},
		{"left_hand": "item_test_buckler", "right_hand": "item_training_sword"},
		ContentStub.new()
	)
	avatar.set_facing_direction(Vector2.RIGHT)
	var order := avatar.get_debug_draw_layer_order()
	var torso_index := order.find("body:torso")

	assert_lt(order.find("equipment:left_hand"), torso_index)
	assert_gt(order.find("equipment:right_hand"), torso_index)


func test_attack_pose_moves_hand_anchor_instead_of_external_effect_only() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup({})
	avatar.set_facing_direction(Vector2.RIGHT)
	var idle_hand: Vector2 = avatar.get_body_part_anchors()["weapon_hand"]

	avatar.set_attack_pose({"shape": "punch"}, Vector2.RIGHT, 0.5)
	var punch_hand: Vector2 = avatar.get_body_part_anchors()["weapon_hand"]

	assert_gt(punch_hand.x, idle_hand.x + 4.0)
	avatar.clear_attack_pose()
	assert_eq(avatar.get_body_part_anchors()["weapon_hand"], idle_hand)


func test_two_hand_weapon_anchors_to_item_grip_sockets() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup({}, {"right_hand": "item_test_polearm"}, ContentStub.new())
	avatar.set_facing_direction(Vector2.RIGHT)
	var anchors := avatar.get_body_part_anchors()
	var proportions: Dictionary = avatar.profile.get("appearance", {}).get("proportions", {})
	var model := HumanoidHeldItemDrawer.polearm_item_model(avatar, proportions)

	assert_almost_eq(
		anchors["left_hand"], ItemVisual2D.grip_position(model, "front"), Vector2.ONE * 0.001
	)
	assert_almost_eq(
		anchors["right_hand"], ItemVisual2D.grip_position(model, "rear"), Vector2.ONE * 0.001
	)
	assert_eq(anchors["weapon_hand"], anchors["right_hand"])
	assert_eq(anchors["off_hand"], anchors["left_hand"])


func test_left_handed_two_hand_weapon_mirrors_grip_roles() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup({"handedness": "left"}, {"right_hand": "item_test_polearm"}, ContentStub.new())
	avatar.set_facing_direction(Vector2.RIGHT)
	var anchors := avatar.get_body_part_anchors()
	var proportions: Dictionary = avatar.profile.get("appearance", {}).get("proportions", {})
	var model := HumanoidHeldItemDrawer.polearm_item_model(avatar, proportions)

	assert_eq(anchors["weapon_hand"], anchors["left_hand"])
	assert_eq(anchors["off_hand"], anchors["right_hand"])
	assert_almost_eq(
		anchors["right_hand"], ItemVisual2D.grip_position(model, "front"), Vector2.ONE * 0.001
	)
	assert_almost_eq(
		anchors["left_hand"], ItemVisual2D.grip_position(model, "rear"), Vector2.ONE * 0.001
	)


func test_polearm_uses_side_lane_instead_of_torso_center() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup({}, {"right_hand": "item_test_polearm"}, ContentStub.new())
	avatar.set_facing_direction(Vector2.RIGHT)
	var proportions: Dictionary = avatar.profile.get("appearance", {}).get("proportions", {})
	var model := HumanoidHeldItemDrawer.polearm_item_model(avatar, proportions)
	var origin: Vector2 = model.get("origin")
	var torso_center := avatar._body_point(0.0, 1.2)

	assert_gt(absf(origin.y - torso_center.y), 6.0)
	assert_gt((origin - torso_center).dot(avatar._body_side_axis()), 1.0)

	avatar.set_facing_direction(Vector2.LEFT)
	model = HumanoidHeldItemDrawer.polearm_item_model(avatar, proportions)
	origin = model.get("origin")
	torso_center = avatar._body_point(0.0, 1.2)

	assert_gt(absf(origin.y - torso_center.y), 6.0)
	assert_gt((origin - torso_center).dot(avatar._body_side_axis()), 1.0)

	avatar.set_facing_direction(Vector2.DOWN)
	model = HumanoidHeldItemDrawer.polearm_item_model(avatar, proportions)
	origin = model.get("origin")
	torso_center = avatar._body_point(0.0, 1.2)

	assert_gt(absf(origin.x - torso_center.x), 6.0)
	assert_gt((origin - torso_center).dot(avatar._body_side_axis()), 1.0)

	var left_handed := HumanoidAvatar2D.new()
	add_child_autofree(left_handed)
	left_handed.setup(
		{"handedness": "left"}, {"right_hand": "item_test_polearm"}, ContentStub.new()
	)
	left_handed.set_facing_direction(Vector2.DOWN)
	var left_proportions: Dictionary = left_handed.profile.get("appearance", {}).get(
		"proportions", {}
	)
	var left_model := HumanoidHeldItemDrawer.polearm_item_model(left_handed, left_proportions)
	var left_origin: Vector2 = left_model.get("origin")
	var left_torso := left_handed._body_point(0.0, 1.2)

	assert_lt(left_origin.x, left_torso.x - 6.0)
	assert_gt((left_origin - left_torso).dot(-left_handed._body_side_axis()), 1.0)


func test_bow_grip_hands_replace_base_hands() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup({}, {"right_hand": "item_hunting_bow"}, ContentStub.new())
	avatar.set_facing_direction(Vector2.RIGHT)
	var order := avatar.get_debug_draw_layer_order()
	var anchors := avatar.get_body_part_anchors()
	var proportions: Dictionary = avatar.profile.get("appearance", {}).get("proportions", {})
	var model := HumanoidHeldItemDrawer.bow_item_model(avatar, proportions)

	assert_false(order.has("hand:left_hand"))
	assert_false(order.has("hand:right_hand"))
	assert_true(order.has("item_grip:left_hand"))
	assert_true(order.has("item_grip:right_hand"))
	assert_almost_eq(
		anchors["left_hand"], ItemVisual2D.grip_position(model, "bow"), Vector2.ONE * 0.001
	)
	assert_almost_eq(
		anchors["right_hand"], ItemVisual2D.grip_position(model, "draw"), Vector2.ONE * 0.001
	)
	assert_eq(anchors["bow_hand"], anchors["left_hand"])
	assert_eq(anchors["draw_hand"], anchors["right_hand"])


func test_left_handed_bow_mirrors_bow_and_draw_hands() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup({"handedness": "left"}, {"right_hand": "item_hunting_bow"}, ContentStub.new())
	avatar.set_facing_direction(Vector2.RIGHT)
	var order := avatar.get_debug_draw_layer_order()
	var anchors := avatar.get_body_part_anchors()
	var proportions: Dictionary = avatar.profile.get("appearance", {}).get("proportions", {})
	var model := HumanoidHeldItemDrawer.bow_item_model(avatar, proportions)

	assert_false(order.has("hand:left_hand"))
	assert_false(order.has("hand:right_hand"))
	assert_true(order.has("item_grip:left_hand"))
	assert_true(order.has("item_grip:right_hand"))
	assert_almost_eq(
		anchors["right_hand"], ItemVisual2D.grip_position(model, "bow"), Vector2.ONE * 0.001
	)
	assert_almost_eq(
		anchors["left_hand"], ItemVisual2D.grip_position(model, "draw"), Vector2.ONE * 0.001
	)
	assert_eq(anchors["bow_hand"], anchors["right_hand"])
	assert_eq(anchors["draw_hand"], anchors["left_hand"])


func test_held_item_grips_match_hand_anchors_in_all_sixteen_directions() -> void:
	for handedness in ["right", "left"]:
		for item_id in ["item_training_sword", "item_test_polearm", "item_hunting_bow"]:
			var avatar := HumanoidAvatar2D.new()
			add_child_autofree(avatar)
			avatar.setup({"handedness": handedness}, {"right_hand": item_id}, ContentStub.new())
			for bucket_index in avatar.get_facing_bucket_count():
				var angle := TAU * float(bucket_index) / float(avatar.get_facing_bucket_count())
				avatar.set_facing_direction(Vector2(cos(angle), sin(angle)))
				var anchors := avatar.get_body_part_anchors()
				var proportions: Dictionary = avatar.profile.get("appearance", {}).get(
					"proportions", {}
				)
				var model := HumanoidHeldItemDrawer.held_item_model(
					avatar, "right_hand", proportions
				)
				for grip_id in ItemVisual2D.grip_ids(String(model.get("visual_id", ""))):
					var side := HumanoidHeldItemDrawer.grip_side_for_slot(
						avatar, grip_id, "right_hand"
					)
					if is_zero_approx(side):
						continue
					var hand_id := avatar._hand_slot_id(side)
					assert_almost_eq(
						anchors[hand_id],
						ItemVisual2D.grip_position(model, grip_id),
						Vector2.ONE * 0.001,
						"%s %s %s bucket %d" % [handedness, item_id, grip_id, bucket_index]
					)


func test_held_item_attack_grips_match_hands_for_all_people_directions_and_scales() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var attack_items := [
		"item_road_hatchet", "item_training_sword", "item_test_polearm", "item_hunting_bow"
	]
	for people_id in [
		"people_human", "people_tanglekin", "people_tuskfolk", "people_mirefolk", "people_ravenfolk",
		"people_rootborn"
	]:
		var profile := content.get_generated_people_profile(people_id, "held_item_anchor_%s" % people_id)
		for handedness in ["right", "left"]:
			profile["handedness"] = handedness
			for item_id in attack_items:
				var item: Dictionary = content.get_item(item_id)
				var attack: Dictionary = item.get("weapon_attack", {})
				for bucket_index in FacingBuckets.COUNT:
					var avatar := HumanoidAvatar2D.new()
					add_child_autofree(avatar)
					avatar.setup(profile, {"right_hand": item_id}, content)
					var angle := TAU * float(bucket_index) / float(FacingBuckets.COUNT)
					var direction := Vector2(cos(angle), sin(angle))
					avatar.set_facing_direction(direction)
					for progress in [0.0, 0.5, 1.0]:
						avatar.set_attack_pose(attack, direction, progress)
						_assert_held_item_grips_match_anchors(avatar, "right_hand", item_id, bucket_index, progress)


func test_buckler_stays_on_equipped_hand_for_all_people_and_directions() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	for people_id in [
		"people_human", "people_tanglekin", "people_tuskfolk", "people_mirefolk", "people_ravenfolk",
		"people_rootborn"
	]:
		var profile := content.get_generated_people_profile(people_id, "buckler_anchor_%s" % people_id)
		for bucket_index in FacingBuckets.COUNT:
			var avatar := HumanoidAvatar2D.new()
			add_child_autofree(avatar)
			avatar.setup(profile, {"left_hand": "item_traveler_buckler"}, content)
			var angle := TAU * float(bucket_index) / float(FacingBuckets.COUNT)
			avatar.set_facing_direction(Vector2(cos(angle), sin(angle)))
			var model := HumanoidHeldItemDrawer.held_item_model(
				avatar, "left_hand", avatar.profile.get("appearance", {}).get("proportions", {})
			)
			var origin: Vector2 = model.get("origin", Vector2.ZERO)
			origin.y *= avatar.get_proportion("body_height")
			assert_almost_eq(
				avatar.get_body_part_anchors()["left_hand"], origin, Vector2.ONE * 0.001,
				"%s buckler bucket %d" % [people_id, bucket_index]
			)


func _assert_held_item_grips_match_anchors(
	avatar: HumanoidAvatar2D, slot_id: String, item_id: String, bucket_index: int, progress: float
) -> void:
	var anchors := avatar.get_body_part_anchors()
	var proportions: Dictionary = avatar.profile.get("appearance", {}).get("proportions", {})
	var model := HumanoidHeldItemDrawer.held_item_model(avatar, slot_id, proportions)
	var body_height := avatar.get_proportion("body_height")
	for grip_id in ItemVisual2D.grip_ids(String(model.get("visual_id", ""))):
		var side := HumanoidHeldItemDrawer.grip_side_for_slot(avatar, grip_id, slot_id)
		if is_zero_approx(side):
			continue
		var expected := ItemVisual2D.grip_position(model, grip_id)
		expected.y *= body_height
		var hand_id := avatar._hand_slot_id(side)
		assert_almost_eq(
			anchors[hand_id], expected, Vector2.ONE * 0.001,
			"%s %s %s bucket %d progress %.2f" % [
				String(avatar.profile.get("people_id", "")), item_id, grip_id, bucket_index, progress
			]
		)


func test_seed_humanoids_have_visual_variation() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var player := HumanoidAvatar2D.new()
	var harrow := HumanoidAvatar2D.new()
	var raider := HumanoidAvatar2D.new()
	add_child_autofree(player)
	add_child_autofree(harrow)
	add_child_autofree(raider)
	player.setup(content.get_resolved_character_profile("char_player"))
	harrow.setup(content.get_resolved_character_profile("char_harrow_venn"))
	raider.setup(content.get_resolved_character_profile("char_test_raider"))

	assert_ne(player.get_proportion("shoulder_width"), harrow.get_proportion("shoulder_width"))
	assert_ne(harrow.get_proportion("hand_size"), raider.get_proportion("hand_size"))
	assert_ne(
		player.get_body_part_anchors()["right_hand"], harrow.get_body_part_anchors()["right_hand"]
	)


func test_renderer_supports_all_people_palettes() -> void:
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	var supported_palettes := avatar.get_supported_palette_ids()

	for people_id in content.people:
		var definition: Dictionary = content.people[people_id]
		for palette_id in Array(definition.get("palettes", [])):
			assert_true(
				supported_palettes.has(String(palette_id)),
				"%s should be supported by HumanoidAvatar2D." % palette_id
			)


func test_avatar_reads_variant_feature_ids_with_legacy_fallbacks() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup(
		{
			"character_id": "char_tanglekin_preview",
			"people_id": "people_tanglekin",
			"appearance": {"feature_ids": ["feature_tanglekin_brow_tuft"]}
		}
	)

	assert_eq(
		HumanoidPeopleFeatureDrawer.appearance_feature_ids(avatar.profile, "people_tanglekin"),
		["feature_tanglekin_brow_tuft"]
	)

	avatar.setup({"character_id": "char_tuskfolk_preview", "people_id": "people_tuskfolk"})

	assert_eq(
		HumanoidPeopleFeatureDrawer.appearance_feature_ids(avatar.profile, "people_tuskfolk"),
		["feature_tusks_broad"]
	)


func test_avatar_uses_people_specific_head_overlays() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)

	assert_true(HumanoidPeopleFeatureDrawer.should_draw_hair("people_human"))
	assert_false(HumanoidPeopleFeatureDrawer.should_draw_hair("people_ravenfolk"))
	assert_false(HumanoidPeopleFeatureDrawer.should_draw_hair("people_mirefolk"))
	assert_false(HumanoidPeopleFeatureDrawer.should_draw_generic_face("people_tanglekin"))
	assert_false(HumanoidPeopleFeatureDrawer.should_draw_generic_face("people_ravenfolk"))
	assert_false(HumanoidPeopleFeatureDrawer.should_draw_generic_face("people_mirefolk"))
	assert_true(HumanoidPeopleFeatureDrawer.should_draw_generic_face("people_tuskfolk"))


func test_avatar_does_not_draw_clothing_from_appearance() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)

	avatar.setup(
		{
			"appearance":
			{"visual_model_id": "human_road_guard", "base_clothing_id": "accent_guard_belt"}
		}
	)
	var order := avatar.get_debug_draw_layer_order()

	assert_eq(order.find("body:human_clothing"), -1)
	assert_eq(order.find("equipment:role_accent"), -1)
	assert_eq(order.find("equipment:chest"), -1)


func test_equipped_chest_item_draws_body_equipment_layer() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)

	avatar.setup({}, {"chest": "item_test_leather_vest"}, ContentStub.new())

	assert_true(avatar.has_equipment_visual("chest"))
	assert_true(avatar.get_debug_draw_layer_order().has("equipment:chest"))


func test_player_uses_humanoid_avatar_child() -> void:
	var player := PlayerController.new()
	add_child_autofree(player)
	player.setup(null, null, Vector2i.ZERO)
	player.set_humanoid_profile({"character_id": "char_player"})

	assert_not_null(player.humanoid_avatar)
	assert_eq(player.humanoid_avatar.name, "HumanoidAvatar2D")
	assert_eq(player.humanoid_profile["character_id"], "char_player")
