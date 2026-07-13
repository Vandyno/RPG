extends GutTest

const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")


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


func test_worn_equipment_layers_body_slots_and_hands() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup(
		{},
		{
			"head": "item_test_leather_cap",
			"chest": "item_test_leather_vest",
			"legs": "item_test_trousers",
			"gloves": "item_test_gloves",
			"boots": "item_test_boots",
			"back": "item_test_cloak",
			"left_hand": "item_test_buckler",
			"right_hand": "item_training_sword"
		},
		ContentStub.new()
	)
	avatar.set_facing_direction(Vector2.DOWN)
	var order := avatar.get_debug_draw_layer_order()
	var feet_index := order.find("body:feet")
	var waist_index := order.find("body:waist")
	var torso_index := order.find("body:torso")
	var head_index := order.find("body:head")
	var left_hand_index := order.find("hand:left_hand")
	var left_glove_index := order.find("equipment:gloves:left_hand")
	var left_held_index := order.find("equipment:left_hand")

	assert_lt(order.find("equipment:back:rear"), feet_index)
	assert_gt(order.find("equipment:boots"), feet_index)
	assert_lt(order.find("equipment:boots"), waist_index)
	assert_gt(order.find("equipment:legs"), waist_index)
	assert_lt(order.find("equipment:legs"), torso_index)
	assert_gt(order.find("equipment:chest"), torso_index)
	assert_lt(order.find("equipment:chest"), head_index)
	assert_gt(left_glove_index, left_hand_index)
	assert_lt(left_glove_index, left_held_index)
	assert_gt(order.find("equipment:head"), order.find("hair"))


func test_back_equipment_moves_to_front_layer_when_facing_back() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)

	avatar.setup({}, {"back": "item_test_cloak"}, ContentStub.new())
	avatar.set_facing_direction(Vector2.UP)
	var order := avatar.get_debug_draw_layer_order()

	assert_eq(order.find("equipment:back:rear"), -1)
	assert_gt(order.find("equipment:back:front"), order.find("body:torso"))


func test_smith_apron_uses_wrapping_chest_visual() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)

	avatar.setup({}, {"chest": "item_smith_apron"}, ContentStub.new())

	assert_eq(avatar._equipment_layer_id("chest"), "placeholder_smith_apron")
	assert_true(avatar._chest_equipment_uses_wrap_style())


func test_body_projection_turns_side_edges_with_facing() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup()

	avatar.set_facing_direction(Vector2.RIGHT)
	assert_gt(avatar._body_point(5.0, 0.0).y, avatar._body_point(-5.0, 0.0).y)

	avatar.set_facing_direction(Vector2.LEFT)
	assert_lt(avatar._body_point(5.0, 0.0).y, avatar._body_point(-5.0, 0.0).y)

	avatar.set_facing_direction(Vector2.DOWN)
	assert_almost_eq(avatar._body_point(5.0, 0.0).y, avatar._body_point(-5.0, 0.0).y, 0.001)


func test_all_sixteen_buckets_keep_equipped_anchors_and_layers_valid() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.setup(
		{},
		{
			"head": "item_test_leather_cap",
			"chest": "item_smith_apron",
			"legs": "item_test_trousers",
			"gloves": "item_test_gloves",
			"boots": "item_test_boots",
			"back": "item_test_cloak",
			"left_hand": "item_test_buckler",
			"right_hand": "item_training_sword"
		},
		ContentStub.new()
	)

	for bucket_index in avatar.get_facing_bucket_count():
		var angle := TAU * float(bucket_index) / float(avatar.get_facing_bucket_count())
		avatar.set_facing_direction(Vector2(cos(angle), sin(angle)))
		var anchors := avatar.get_body_part_anchors()
		var order := avatar.get_debug_draw_layer_order()

		for anchor_id in anchors:
			var anchor: Vector2 = anchors[anchor_id]
			assert_false(is_nan(anchor.x), "%s x should be valid." % anchor_id)
			assert_false(is_nan(anchor.y), "%s y should be valid." % anchor_id)
		assert_true(order.has("equipment:chest"))
		assert_true(order.has("equipment:boots"))
		assert_true(order.has("equipment:legs"))
		assert_true(order.has("equipment:head"))
