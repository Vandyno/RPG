extends GutTest

const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")
const HumanoidHeldItemDrawer = preload("res://scripts/characters/humanoid_held_item_drawer.gd")


class ContentStub:
	func get_item(item_id: String) -> Dictionary:
		if item_id == "item_sword":
			return {"avatar_visual": {"visual_layer_id": "placeholder_sword"}}
		return {}


func test_slot_side_and_primary_weapon_side_are_stable() -> void:
	var avatar := HumanoidAvatar2D.new()
	add_child_autofree(avatar)
	avatar.set_profile({"character_id": "char_drawer_test", "handedness": "left"})
	avatar.set_equipped_items({"left_hand": "item_sword"}, ContentStub.new())

	assert_eq(HumanoidHeldItemDrawer.slot_side("left_hand"), -1.0)
	assert_eq(HumanoidHeldItemDrawer.slot_side("right_hand"), 1.0)
	assert_eq(HumanoidHeldItemDrawer.primary_weapon_slot_id(avatar), "left_hand")
	assert_eq(HumanoidHeldItemDrawer.primary_weapon_visual_id(avatar), "placeholder_sword")


func test_math_helpers_keep_weapon_motion_predictable() -> void:
	assert_eq(HumanoidHeldItemDrawer.smooth_step(0.0), 0.0)
	assert_eq(HumanoidHeldItemDrawer.smooth_step(1.0), 1.0)
	var actual := HumanoidHeldItemDrawer.quadratic_bezier(
		Vector2.ZERO,
		Vector2(10.0, 0.0),
		Vector2(10.0, 10.0),
		0.5
	)

	assert_eq(
		actual,
		Vector2(7.5, 2.5)
	)
