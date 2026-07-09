extends GutTest

const RpgIconDrawer = preload("res://scripts/ui/controls/display/rpg_icon_drawer.gd")


class DrawProbe:
	extends Node2D

	var draw_callable: Callable
	var draw_count := 0

	func _draw() -> void:
		draw_count += 1
		draw_callable.call(self)


func test_draw_icon_smoke_covers_public_icon_kinds() -> void:
	var probes: Array[DrawProbe] = []
	for kind in ["quest", "spell", "map", "journal", "book", "trade", "item", "unknown"]:
		probes.append(_draw_probe(
			func(canvas: CanvasItem) -> void:
				RpgIconDrawer.draw_icon(canvas, kind, Vector2(20, 20), 10.0, Color.WHITE)
		))

	await get_tree().process_frame

	for probe in probes:
		assert_eq(probe.draw_count, 1)


func test_private_draw_helpers_smoke_cover_each_shape() -> void:
	var helpers: Array[Callable] = [
		func(canvas: CanvasItem) -> void:
			RpgIconDrawer._draw_quest(canvas, Vector2(20, 20), 10.0, Color.WHITE),
		func(canvas: CanvasItem) -> void:
			RpgIconDrawer._draw_spell(canvas, Vector2(20, 20), 10.0, Color.WHITE),
		func(canvas: CanvasItem) -> void:
			RpgIconDrawer._draw_map(canvas, Vector2(20, 20), 10.0, Color.WHITE),
		func(canvas: CanvasItem) -> void:
			RpgIconDrawer._draw_journal(canvas, Vector2(20, 20), 10.0, Color.WHITE),
		func(canvas: CanvasItem) -> void:
			RpgIconDrawer._draw_trade(canvas, Vector2(20, 20), 10.0, Color.WHITE),
		func(canvas: CanvasItem) -> void:
			RpgIconDrawer._draw_item(canvas, Vector2(20, 20), 10.0, Color.WHITE)
	]
	var probes: Array[DrawProbe] = []
	for helper in helpers:
		probes.append(_draw_probe(helper))

	await get_tree().process_frame

	for probe in probes:
		assert_eq(probe.draw_count, 1)


func _draw_probe(draw_callable: Callable) -> DrawProbe:
	var probe := DrawProbe.new()
	probe.draw_callable = draw_callable
	add_child_autofree(probe)
	probe.queue_redraw()
	return probe
