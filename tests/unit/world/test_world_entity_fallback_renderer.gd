extends GutTest

const WorldEntityFallbackRenderer = preload(
	"res://scripts/world/world_entity_fallback_renderer.gd"
)


class DrawProbe:
	extends Node2D

	var draw_callable: Callable
	var draw_count := 0

	func _draw() -> void:
		draw_count += 1
		draw_callable.call(self)


func test_color_for_kind_returns_expected_palette_and_default() -> void:
	assert_eq(WorldEntityFallbackRenderer.color_for_kind("npc"), Color(0.61, 0.43, 0.24))
	assert_eq(WorldEntityFallbackRenderer.color_for_kind("pickup"), Color(0.78, 0.58, 0.12))
	assert_eq(WorldEntityFallbackRenderer.color_for_kind("container"), Color(0.50, 0.32, 0.16))
	assert_eq(WorldEntityFallbackRenderer.color_for_kind("door"), Color(0.38, 0.25, 0.16))
	assert_eq(WorldEntityFallbackRenderer.color_for_kind("readable"), Color(0.84, 0.80, 0.58))
	assert_eq(WorldEntityFallbackRenderer.color_for_kind("rest"), Color(0.94, 0.45, 0.18))
	assert_eq(WorldEntityFallbackRenderer.color_for_kind("poi"), Color(0.48, 0.38, 0.24))
	assert_eq(WorldEntityFallbackRenderer.color_for_kind("location"), Color(0.18, 0.38, 0.56))
	assert_eq(WorldEntityFallbackRenderer.color_for_kind("unknown"), Color(0.60, 0.60, 0.60))


func test_draw_entity_smoke_covers_known_fallback_kinds() -> void:
	var kinds := [
		"npc",
		"container",
		"door",
		"readable",
		"body",
		"rest",
		"poi",
		"location",
		"unknown"
	]

	for kind in kinds:
		var probe := _draw_probe(
			func(canvas: CanvasItem) -> void:
				WorldEntityFallbackRenderer.draw_entity(canvas, kind, false, {})
		)
		await get_tree().process_frame
		assert_eq(probe.draw_count, 1)


func test_draw_entity_smoke_covers_combat_target_and_pickups() -> void:
	var combat_probe := _draw_probe(
		func(canvas: CanvasItem) -> void:
			WorldEntityFallbackRenderer.draw_entity(canvas, "npc", true, {})
	)
	var empty_pickup_probe := _draw_probe(
		func(canvas: CanvasItem) -> void:
			WorldEntityFallbackRenderer.draw_entity(canvas, "pickup", false, {})
	)
	var visual_pickup_probe := _draw_probe(
		func(canvas: CanvasItem) -> void:
			WorldEntityFallbackRenderer.draw_entity(
				canvas,
				"pickup",
				false,
				{"visual_id": "placeholder_hatchet", "direction": Vector2.RIGHT}
		)
	)

	await get_tree().process_frame

	for probe in [combat_probe, empty_pickup_probe, visual_pickup_probe]:
		assert_eq(probe.draw_count, 1)


func _draw_probe(draw_callable: Callable) -> DrawProbe:
	var probe := DrawProbe.new()
	probe.draw_callable = draw_callable
	add_child_autofree(probe)
	probe.queue_redraw()
	return probe
