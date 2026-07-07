extends GutTest

const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")


class ContentStub:
	func get_item(item_id: String) -> Dictionary:
		match item_id:
			"item_sword":
				return {"avatar_visual": {"visual_layer_id": "placeholder_sword"}}
			"item_vest":
				return {"avatar_visual": {"visual_layer_id": "placeholder_leather_vest"}}
		return {}


func test_profile_direction_and_locomotion_state_drive_debug_output() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)

	avatar.set_profile(
		{
			"character_id": "char_avatar_test",
			"people_id": "people_tanglekin",
			"handedness": "left",
			"appearance":
			{
				"palette_id": "tanglekin_moss",
				"proportions": {"body_height": 1.2, "shoulder_width": 0.9}
			}
		}
	)
	avatar.set_facing_direction(Vector2.RIGHT)
	avatar.set_locomotion(true, true, 0.25)

	assert_eq(avatar.profile["character_id"], "char_avatar_test")
	assert_eq(avatar.profile["handedness"], "left")
	assert_eq(avatar.locomotion_state, HumanoidAvatar2D.LOCOMOTION_SNEAK)
	assert_gt(avatar.animation_time, 0.0)
	assert_true(avatar.get_facing_bucket_count() > 0)
	assert_false(avatar.get_facing_bucket_id().is_empty())
	assert_true(avatar.get_debug_turn_profile().has("bucket_id"))


func test_equipment_visuals_ignore_empty_slots_and_keep_body_stack_state() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)

	avatar.set_equipped_items(
		{
			"right_hand": "item_sword",
			"chest": "item_vest",
			"empty": "missing_item"
		},
		ContentStub.new()
	)

	assert_true(avatar.has_equipment_visual("right_hand"))
	assert_true(avatar.has_equipment_visual("chest"))
	assert_false(avatar.has_equipment_visual("empty"))
	assert_true(avatar.has_body_stack())
	assert_true(avatar.get_equipment_body_slots().has("chest"))
