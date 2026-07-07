extends GutTest

const ItemVisual2D = preload("res://scripts/items/item_visual_2d.gd")
const WorldEntity = preload("res://scripts/world/world_entity.gd")


func test_polearm_visual_exposes_stable_model_grips() -> void:
	var model := ItemVisual2D.model(
		"placeholder_polearm", Vector2(10.0, 20.0), Vector2.RIGHT, {"grip_side_offset": 2.0}
	)

	assert_eq(ItemVisual2D.grip_position(model, "front"), Vector2(20.0, 22.0))
	assert_eq(ItemVisual2D.grip_position(model, "rear"), Vector2(4.0, 18.0))
	assert_gt(ItemVisual2D.visual_bounds(model).size.x, 60.0)


func test_item_visual_grips_use_explicit_side_axis_when_provided() -> void:
	var model := ItemVisual2D.model(
		"placeholder_polearm",
		Vector2(10.0, 20.0),
		Vector2.RIGHT,
		{"grip_side_offset": 2.0, "side_axis": Vector2.UP}
	)

	assert_eq(ItemVisual2D.grip_position(model, "front"), Vector2(20.0, 22.0))
	assert_eq(ItemVisual2D.grip_position(model, "rear"), Vector2(4.0, 18.0))

	model["side_axis"] = Vector2.DOWN

	assert_eq(ItemVisual2D.grip_position(model, "front"), Vector2(20.0, 18.0))
	assert_eq(ItemVisual2D.grip_position(model, "rear"), Vector2(4.0, 22.0))


func test_world_pickup_weapon_uses_item_visual_model() -> void:
	var entity := WorldEntity.new()
	add_child_autofree(entity)

	entity.setup(
		{
			"id": "pickup_test_polearm",
			"name": "Test Polearm",
			"kind": "pickup",
			"item_id": "item_test_polearm",
			"global_tile": [0, 0],
			"item_direction": [1, 0]
		},
		ItemContentStub.new()
	)
	var item_model := entity.get_pickup_item_visual_state()

	assert_eq(String(item_model.get("visual_id", "")), "placeholder_polearm")
	assert_eq(item_model.get("direction"), Vector2.RIGHT)
	assert_true(bool(item_model.get("ground", false)))


class ItemContentStub:
	extends RefCounted

	func get_item(item_id: String) -> Dictionary:
		if item_id == "item_test_polearm":
			return {
				"id": item_id,
				"avatar_visual":
				{
					"avatar_slot": "right_hand",
					"visual_layer_id": "placeholder_polearm",
					"accepted_placeholder": true
				}
			}
		return {}
