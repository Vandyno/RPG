extends GutTest

const InteractionTargetSelector = preload("res://scripts/main/interaction_target_selector.gd")


func test_forward_target_beats_closer_side_clutter() -> void:
	var side_clutter := Node2D.new()
	var forward_target := Node2D.new()
	add_child_autofree(side_clutter)
	add_child_autofree(forward_target)
	side_clutter.global_position = Vector2(20.0, 70.0)
	forward_target.global_position = Vector2(86.0, 8.0)

	var best_index := InteractionTargetSelector.best_index(
		[side_clutter, forward_target], Vector2.ZERO, Vector2.RIGHT
	)

	assert_eq(best_index, 1)


func test_centered_target_beats_much_closer_forward_edge_clutter() -> void:
	var edge_clutter := Node2D.new()
	var centered_target := Node2D.new()
	add_child_autofree(edge_clutter)
	add_child_autofree(centered_target)
	edge_clutter.global_position = Vector2(35.0, 42.0)
	centered_target.global_position = Vector2(96.0, 0.0)

	var best_index := InteractionTargetSelector.best_index(
		[edge_clutter, centered_target], Vector2.ZERO, Vector2.RIGHT
	)

	assert_eq(best_index, 1)


func test_forward_target_beats_closer_behind_target() -> void:
	var behind_target := Node2D.new()
	var forward_target := Node2D.new()
	add_child_autofree(behind_target)
	add_child_autofree(forward_target)
	behind_target.global_position = Vector2(-24.0, 0.0)
	forward_target.global_position = Vector2(80.0, 0.0)

	var best_index := InteractionTargetSelector.best_index(
		[behind_target, forward_target], Vector2.ZERO, Vector2.RIGHT
	)

	assert_eq(best_index, 1)


func test_ranked_targets_follow_same_intent_order_as_default_selection() -> void:
	var behind_target := Node2D.new()
	var side_clutter := Node2D.new()
	var forward_target := Node2D.new()
	add_child_autofree(behind_target)
	add_child_autofree(side_clutter)
	add_child_autofree(forward_target)
	behind_target.name = "behind"
	side_clutter.name = "side"
	forward_target.name = "forward"
	behind_target.global_position = Vector2(-24.0, 0.0)
	side_clutter.global_position = Vector2(20.0, 70.0)
	forward_target.global_position = Vector2(86.0, 8.0)

	var ranked := InteractionTargetSelector.ranked_targets(
		[behind_target, side_clutter, forward_target], Vector2.ZERO, Vector2.RIGHT
	)

	assert_eq(ranked[0].name, "forward")
	assert_eq(ranked[1].name, "side")
	assert_eq(ranked[2].name, "behind")
