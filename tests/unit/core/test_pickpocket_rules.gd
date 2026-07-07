extends GutTest


func test_access_result_requires_valid_target_and_sneaking() -> void:
	var target := PickpocketEntityStub.new(
		"Harrow Venn",
		{
			"kind": "npc",
			"actor_category": "humanoid",
			"inventory_owner_id": "char_harrow",
			"facing_direction": [0, 1]
		}
	)

	assert_eq(
		PickpocketRules.access_result(null, Vector2.ZERO, true),
		{"allowed": false, "reason": "No pockets to pick."}
	)
	assert_eq(
		PickpocketRules.access_result(target, Vector2(0, -10), false),
		{"allowed": false, "reason": "Need to be sneaking."}
	)


func test_access_result_blocks_visible_player_and_allows_unseen_player() -> void:
	var target := PickpocketEntityStub.new(
		"Harrow Venn",
		{
			"kind": "npc",
			"actor_category": "humanoid",
			"inventory_owner_id": "char_harrow",
			"facing": "north"
		}
	)

	assert_eq(
		PickpocketRules.access_result(target, Vector2(0, -10), true),
		{"allowed": false, "reason": "Harrow Venn can see you."}
	)
	assert_eq(
		PickpocketRules.access_result(target, Vector2(0, 10), true),
		{"allowed": true, "reason": ""}
	)


func test_facing_direction_prefers_valid_vector_then_cardinal_text() -> void:
	var target := PickpocketEntityStub.new("Guard", {"facing_direction": [2, 0], "facing": "west"})
	assert_eq(PickpocketRules.facing_direction(target), Vector2.RIGHT)

	target.data = {"facing_direction": ["bad", 0], "facing": "west"}
	assert_eq(PickpocketRules.facing_direction(target), Vector2.LEFT)
	assert_eq(PickpocketRules.facing_direction(null), Vector2.DOWN)


class PickpocketEntityStub:
	extends RefCounted

	var data: Dictionary
	var display_name: String
	var global_position := Vector2.ZERO

	func _init(entity_name: String, entity_data: Dictionary) -> void:
		display_name = entity_name
		data = entity_data

	func get_display_name() -> String:
		return display_name
