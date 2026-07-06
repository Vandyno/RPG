# gdlint:disable=max-public-methods
extends GutTest

const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")
const PlayerController = preload("res://scripts/player/player_controller.gd")
const ContentDatabase = preload("res://scripts/data/content_database.gd")
const FacingBuckets = preload("res://scripts/core/facing_buckets.gd")


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
			"appearance": {
				"proportions": {
					"body_height": 0.9,
					"shoulder_width": 1.2,
					"hand_size": 0.8
				}
			}
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
		var signature := "%0.2f:%0.2f:%0.2f:%0.1f:%0.2f:%0.2f:%0.2f" % [
			float(profile["front"]),
			float(profile["side"]),
			float(profile["back"]),
			float(profile["face_side"]),
			axis.x,
			axis.y,
			head.y
		]
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
	for anchor_id in ["head", "chest", "waist", "left_hand", "right_hand", "left_foot", "right_foot"]:
		assert_true(anchors.has(anchor_id))
		assert_true(anchors[anchor_id] is Vector2)
	assert_lt((anchors["left_hand"] as Vector2).x, (anchors["right_hand"] as Vector2).x)
	assert_gt(
		(anchors["left_foot"] as Vector2).distance_to(anchors["right_foot"] as Vector2),
		1.0
	)


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

	assert_lt(
		order.find("people_feature_back:feature_tanglekin_tail"),
		order.find("body:torso")
	)
	assert_eq(order.find("people_feature_front:feature_tanglekin_tail"), -1)
	assert_gt(
		order.find("people_feature_front:feature_tanglekin_muzzle"),
		order.find("body:head")
	)


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
	var feature_ids := avatar._appearance_feature_ids("people_mirefolk")
	var order := avatar.get_debug_draw_layer_order()

	assert_true(feature_ids.has("feature_mirefolk_high_eyes"))
	assert_gt(
		order.find("people_feature_front:feature_mirefolk_high_eyes"),
		order.find("body:head")
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
		order.find("people_feature_body:feature_ravenfolk_body_feathers"),
		order.find("body:torso")
	)
	assert_lt(
		order.find("people_feature_body:feature_ravenfolk_body_feathers"),
		order.find("body:head")
	)
	assert_gt(order.find("people_feature_front:feature_ravenfolk_beak"), order.find("body:head"))
	assert_gt(order.find("people_feature_front:feature_ravenfolk_head_crest"), order.find("body:head"))
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
	player.setup(content.get_character_profile("char_player"))
	harrow.setup(content.get_character_profile("char_harrow_venn"))
	raider.setup(content.get_character_profile("char_test_raider"))

	assert_ne(player.get_proportion("shoulder_width"), harrow.get_proportion("shoulder_width"))
	assert_ne(harrow.get_proportion("hand_size"), raider.get_proportion("hand_size"))
	assert_ne(
		player.get_body_part_anchors()["right_hand"],
		harrow.get_body_part_anchors()["right_hand"]
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

	assert_eq(avatar._appearance_feature_ids("people_tanglekin"), ["feature_tanglekin_brow_tuft"])

	avatar.setup({"character_id": "char_tuskfolk_preview", "people_id": "people_tuskfolk"})

	assert_eq(avatar._appearance_feature_ids("people_tuskfolk"), ["feature_tusks_broad"])


func test_avatar_uses_people_specific_head_overlays() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)

	assert_true(avatar._should_draw_hair("people_human"))
	assert_false(avatar._should_draw_hair("people_ravenfolk"))
	assert_false(avatar._should_draw_hair("people_mirefolk"))
	assert_false(avatar._should_draw_generic_face("people_tanglekin"))
	assert_false(avatar._should_draw_generic_face("people_ravenfolk"))
	assert_false(avatar._should_draw_generic_face("people_mirefolk"))
	assert_true(avatar._should_draw_generic_face("people_tuskfolk"))


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
