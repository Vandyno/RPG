extends GutTest

const WorldEntityMarkerRenderer = preload(
	"res://scripts/world/world_entity_marker_renderer.gd"
)


class DrawProbe:
	extends Node2D

	var draw_callable: Callable
	var draw_count := 0

	func _draw() -> void:
		draw_count += 1
		draw_callable.call(self)


func test_ellipsized_respects_limits_and_short_values() -> void:
	assert_eq(WorldEntityMarkerRenderer.ellipsized("Talk", 22), "Talk")
	assert_eq(WorldEntityMarkerRenderer.ellipsized("abcdef", 1), "a")
	assert_eq(WorldEntityMarkerRenderer.ellipsized("abcdef", 0), "")
	assert_eq(WorldEntityMarkerRenderer.ellipsized("abcdef", 5), "ab...")


func test_quest_marker_center_and_rect_account_for_action_hint_offset() -> void:
	assert_eq(WorldEntityMarkerRenderer.quest_marker_center(false, 12.0), Vector2(0.0, -36.0))
	assert_eq(WorldEntityMarkerRenderer.quest_marker_center(true, 12.0), Vector2(0.0, -46.0))
	assert_eq(
		WorldEntityMarkerRenderer.quest_marker_rect(true, 12.0),
		Rect2(Vector2(-26.0, -56.0), Vector2(52.0, 20.0))
	)


func test_action_hint_rect_clamps_width_and_applies_offset() -> void:
	var short_rect := WorldEntityMarkerRenderer.action_hint_rect("", 5.0)
	var medium_rect := WorldEntityMarkerRenderer.action_hint_rect("Talk", 0.0)
	var long_rect := WorldEntityMarkerRenderer.action_hint_rect("Very Long Action Hint Text", -4.0)

	assert_eq(short_rect.size, Vector2(48.0, WorldEntityMarkerRenderer.ACTION_HINT_HEIGHT))
	assert_eq(short_rect.position, Vector2(-24.0, -40.0))
	assert_eq(medium_rect.size.x, 48.0)
	assert_eq(long_rect.size.x, WorldEntityMarkerRenderer.ACTION_HINT_MAX_WIDTH)
	assert_eq(long_rect.position.y, -49.0)


func test_marker_pick_radius_uses_default_and_large_kind_floor() -> void:
	assert_eq(WorldEntityMarkerRenderer.marker_pick_radius("npc", 12.0), 40.0)
	assert_eq(WorldEntityMarkerRenderer.marker_pick_radius("npc", 52.0), 52.0)
	assert_eq(WorldEntityMarkerRenderer.marker_pick_radius("door", 12.0), 46.0)
	assert_eq(WorldEntityMarkerRenderer.marker_pick_radius("container", 52.0), 52.0)


func test_draw_quest_marker_and_action_hint_smoke() -> void:
	var quest_probe := _draw_probe(
		func(canvas: CanvasItem) -> void:
			WorldEntityMarkerRenderer.draw_quest_marker(canvas, "Q", true, 10.0)
	)
	var action_probe := _draw_probe(
		func(canvas: CanvasItem) -> void:
			WorldEntityMarkerRenderer.draw_action_hint(canvas, "Talk", false, 0.0)
	)
	var selected_probe := _draw_probe(
		func(canvas: CanvasItem) -> void:
			WorldEntityMarkerRenderer.draw_action_hint(canvas, "Trade", true, 4.0)
	)

	await get_tree().process_frame

	assert_eq(quest_probe.draw_count, 1)
	assert_eq(action_probe.draw_count, 1)
	assert_eq(selected_probe.draw_count, 1)


func _draw_probe(draw_callable: Callable) -> DrawProbe:
	var probe := DrawProbe.new()
	probe.draw_callable = draw_callable
	add_child_autofree(probe)
	probe.queue_redraw()
	return probe
