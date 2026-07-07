extends GutTest

const GridMath = preload("res://scripts/core/grid_math.gd")
const WorldEntityMarkerRenderer = preload("res://scripts/world/world_entity_marker_renderer.gd")


func test_setup_normalizes_position_tile_and_spawn_data() -> void:
	var source := {
		"id": "road_notice",
		"name": "Road Notice",
		"kind": "object",
		"global_tile": [2, 3],
		"facing_direction": [1, 0]
	}
	var entity := WorldEntity.new()
	add_child_autofree(entity)

	entity.setup(source)

	var expected_position := (
		GridMath.tile_to_world(Vector2i(2, 3))
		+ Vector2(GridMath.TILE_SIZE, GridMath.TILE_SIZE) * 0.5
	)
	assert_eq(entity.name, "road_notice")
	assert_eq(entity.get_entity_id(), "road_notice")
	assert_eq(entity.get_display_name(), "Road Notice")
	assert_eq(entity.get_kind(), "object")
	assert_eq(entity.position, expected_position)
	assert_eq(entity.global_tile, Vector2i(2, 3))
	assert_eq(entity.data["global_tile"], [2, 3])
	assert_eq(entity.data["_spawn_global_tile"], [2, 3])
	assert_eq(entity.get_facing_direction(), Vector2.RIGHT)
	assert_false(source.has("_spawn_global_tile"))


func test_world_position_and_facing_updates_runtime_data() -> void:
	var entity := WorldEntity.new()
	add_child_autofree(entity)
	entity.setup({"id": "guard", "kind": "npc", "global_tile": [0, 0]})

	entity.set_global_tile(Vector2i(4, 5))
	entity.set_facing_direction(Vector2.ZERO)
	assert_eq(entity.global_tile, Vector2i(4, 5))
	assert_eq(entity.data["global_tile"], [4, 5])
	assert_eq(entity.data["_runtime_moved"], true)
	assert_true(entity.get_facing_direction().is_equal_approx(Vector2.DOWN))

	entity.set_facing_direction(Vector2.LEFT)

	assert_true(entity.get_facing_direction().is_equal_approx(Vector2.LEFT))
	assert_almost_eq(float(entity.data["facing_direction"][0]), -1.0, 0.001)
	assert_almost_eq(float(entity.data["facing_direction"][1]), 0.0, 0.001)


func test_action_hint_ellipsizes_offsets_and_prioritizes_selected_pick() -> void:
	var entity := WorldEntity.new()
	add_child_autofree(entity)
	entity.setup({"id": "forge", "kind": "object", "global_tile": [0, 0]})

	entity.set_action_hint(true, "Sharpen Road Hatchet With Long Label", false, 12.0)

	assert_true(entity.action_hint_visible)
	assert_lte(
		entity.action_hint_text.length(),
		WorldEntityMarkerRenderer.ACTION_HINT_MAX_CHARS
	)
	assert_eq(entity.action_hint_offset_y, 12.0)
	assert_eq(entity.z_index, 0)

	entity.set_action_hint(true, "Guard", true, 12.0)
	var pick_position := entity.to_global(entity._action_hint_rect().get_center())
	var pick := entity.get_pick_distance(pick_position, 1.0)

	assert_eq(entity.action_hint_offset_y, 0.0)
	assert_eq(entity.z_index, 20)
	assert_eq(pick, WorldEntityMarkerRenderer.SELECTED_ACTION_HINT_PICK_DISTANCE)


func test_quest_marker_ellipsizes_and_is_pickable() -> void:
	var entity := WorldEntity.new()
	add_child_autofree(entity)
	entity.setup({"id": "harrow", "kind": "npc", "global_tile": [0, 0]})

	entity.set_quest_marker(true, "Missing Tools Quest")
	var pick_position := entity.to_global(entity._quest_marker_rect().get_center())
	var pick := entity.get_pick_distance(pick_position, 1.0)

	assert_true(entity.quest_marker_visible)
	assert_lte(entity.quest_marker_text.length(), 12)
	assert_eq(pick, 0.5)


func test_pickup_visual_state_requires_valid_content_and_visual() -> void:
	var entity := WorldEntity.new()
	add_child_autofree(entity)
	entity.setup(
		{
			"id": "pickup_test_polearm",
			"kind": "pickup",
			"item_id": "item_test_polearm",
			"global_tile": [0, 0],
			"item_direction": [0, -2]
		},
		ItemContentStub.new()
	)

	var item_model := entity.get_pickup_item_visual_state()

	assert_eq(item_model.get("visual_id"), "placeholder_polearm")
	assert_eq(item_model.get("direction"), Vector2.UP)
	assert_true(bool(item_model.get("ground", false)))
	var blank := WorldEntity.new()
	add_child_autofree(blank)
	assert_eq(blank.get_pickup_item_visual_state(), {})


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
