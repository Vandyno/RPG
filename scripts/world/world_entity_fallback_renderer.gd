class_name WorldEntityFallbackRenderer
extends RefCounted

const ItemVisual2D = preload("res://scripts/items/item_visual_2d.gd")
const NORTHGATE_PROP_TEXTURES := {
	"anvil": preload("res://assets/world/northgate/props/anvil.png"),
	"barrel_stack": preload("res://assets/world/northgate/props/barrel_stack.png"),
	"basket": preload("res://assets/world/northgate/props/basket.png"),
	"bench": preload("res://assets/world/northgate/props/bench.png"),
	"cart": preload("res://assets/world/northgate/props/cart.png"),
	"crate_stack": preload("res://assets/world/northgate/props/crate_stack.png"),
	"fence": preload("res://assets/world/northgate/props/fence.png"),
	"hanging_sign": preload("res://assets/world/northgate/props/hanging_sign.png"),
	"hay_bale": preload("res://assets/world/northgate/props/hay_bale.png"),
	"hitching_post": preload("res://assets/world/northgate/props/hitching_post.png"),
	"lantern_post": preload("res://assets/world/northgate/props/lantern_post.png"),
	"market_stall": preload("res://assets/world/northgate/props/market_stall.png"),
	"planter": preload("res://assets/world/northgate/props/planter.png"),
	"rain_barrel": preload("res://assets/world/northgate/props/rain_barrel.png"),
	"wash_line": preload("res://assets/world/northgate/props/wash_line.png"),
	"water_trough": preload("res://assets/world/northgate/props/water_trough.png"),
	"well": preload("res://assets/world/northgate/props/well.png"),
	"woodpile": preload("res://assets/world/northgate/props/woodpile.png")
}
const NORTHGATE_GROUND_TEXTURES := {
	"ash_scatter": preload("res://assets/world/northgate/ground/ash_scatter.png"),
	"bootprints": preload("res://assets/world/northgate/ground/bootprints.png"),
	"broken_plank": preload("res://assets/world/northgate/ground/broken_plank.png"),
	"clover": preload("res://assets/world/northgate/ground/clover.png"),
	"drainage_stones": preload("res://assets/world/northgate/ground/drainage_stones.png"),
	"flat_stones": preload("res://assets/world/northgate/ground/flat_stones.png"),
	"grain_scatter": preload("res://assets/world/northgate/ground/grain_scatter.png"),
	"grass_tuft": preload("res://assets/world/northgate/ground/grass_tuft.png"),
	"herbs": preload("res://assets/world/northgate/ground/herbs.png"),
	"leaf_scatter": preload("res://assets/world/northgate/ground/leaf_scatter.png"),
	"moss_patch": preload("res://assets/world/northgate/ground/moss_patch.png"),
	"mud_puddle": preload("res://assets/world/northgate/ground/mud_puddle.png"),
	"straw_scatter": preload("res://assets/world/northgate/ground/straw_scatter.png"),
	"weeds": preload("res://assets/world/northgate/ground/weeds.png"),
	"wheel_ruts": preload("res://assets/world/northgate/ground/wheel_ruts.png"),
	"wildflowers": preload("res://assets/world/northgate/ground/wildflowers.png")
}
const NORTHGATE_INTERIOR_PROP_TEXTURES := {
	"altar": preload("res://assets/world/northgate/interior_props/altar.png"),
	"bed": preload("res://assets/world/northgate/interior_props/bed.png"),
	"bench": preload("res://assets/world/northgate/interior_props/bench.png"),
	"bucket": preload("res://assets/world/northgate/interior_props/bucket.png"),
	"chest": preload("res://assets/world/northgate/interior_props/chest.png"),
	"counter": preload("res://assets/world/northgate/interior_props/counter.png"),
	"cupboard": preload("res://assets/world/northgate/interior_props/cupboard.png"),
	"hearth": preload("res://assets/world/northgate/interior_props/hearth.png"),
	"partition": preload("res://assets/world/northgate/interior_props/partition.png"),
	"sacks": preload("res://assets/world/northgate/interior_props/sacks.png"),
	"shelf": preload("res://assets/world/northgate/interior_props/shelf.png"),
	"stool": preload("res://assets/world/northgate/interior_props/stool.png"),
	"table": preload("res://assets/world/northgate/interior_props/table.png"),
	"weapon_rack": preload("res://assets/world/northgate/interior_props/weapon_rack.png"),
	"workbench": preload("res://assets/world/northgate/interior_props/workbench.png")
}
const NORTHGATE_INN_V3_TEXTURES := {
	"backbar_shelf": preload("res://assets/world/northgate/inn_v3/interior_props/backbar_shelf.png"),
	"bar_counter": preload("res://assets/world/northgate/inn_v3/interior_props/bar_counter.png"),
	"bed": preload("res://assets/world/northgate/inn_v3/interior_props/bed.png"),
	"bench": preload("res://assets/world/northgate/inn_v3/interior_props/bench.png"),
	"common_table": preload("res://assets/world/northgate/inn_v3/interior_props/common_table.png"),
	"hearth": preload("res://assets/world/northgate/inn_v3/interior_props/hearth.png"),
	"partition": preload("res://assets/world/northgate/inn_v3/interior_props/partition.png"),
	"stool": preload("res://assets/world/northgate/inn_v3/interior_props/stool.png"),
	"trunk": preload("res://assets/world/northgate/inn_v3/interior_props/trunk.png")
}


static func draw_entity(
	canvas: CanvasItem,
	kind: String,
	combat_target: bool,
	pickup_item_model: Dictionary,
	visual_style: String = "",
	entity_data: Dictionary = {}
) -> void:
	if visual_style == "hidden":
		return
	var is_inn_v3 := String(entity_data.get("world_layer", "")) == "interior:structure_northgate_inn_plot"
	if kind == "pickup":
		_draw_pickup(canvas, pickup_item_model)
		return
	if combat_target:
		_draw_hostile_marker(canvas)
	elif kind == "npc":
		_draw_npc_marker(canvas)
	elif kind == "container":
		canvas.draw_rect(Rect2(Vector2(-7, -5), Vector2(14, 10)), Color(0.55, 0.34, 0.14), true)
		canvas.draw_line(Vector2(-7, -1), Vector2(7, -1), Color(0.92, 0.76, 0.42), 1.5)
	elif kind == "door":
		canvas.draw_rect(Rect2(Vector2(-4, -9), Vector2(8, 18)), Color(0.44, 0.28, 0.16), true)
		canvas.draw_circle(Vector2(2, 0), 1.5, Color(0.96, 0.78, 0.34))
	elif kind == "readable":
		canvas.draw_rect(Rect2(Vector2(-6, -8), Vector2(12, 16)), Color(0.93, 0.88, 0.67), true)
	elif kind == "body":
		canvas.draw_ellipse(Vector2(0.0, 2.0), 11.0, 6.0, Color(0.36, 0.25, 0.17))
		canvas.draw_ellipse(Vector2(0.0, 2.0), 11.0, 6.0, Color(0.05, 0.04, 0.03), false, 1.5)
	elif kind == "rest":
		if visual_style.begins_with("fixture:"):
			var rest_fixture := visual_style.trim_prefix("fixture:")
			if not is_inn_v3 or not _draw_northgate_inn_v3_prop(canvas, rest_fixture):
				_draw_fixture(canvas, rest_fixture)
		else:
			canvas.draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.45, 0.16))
			canvas.draw_line(Vector2(-6, 6), Vector2(6, 6), Color(0.25, 0.12, 0.05), 2.0)
	elif kind == "poi":
		if visual_style == "sign":
			_draw_sign(canvas)
		else:
			_draw_poi(canvas)
	elif kind == "location":
		var points := PackedVector2Array(
			[Vector2(0, -8), Vector2(8, 0), Vector2(0, 8), Vector2(-8, 0)]
		)
		canvas.draw_polygon(points, PackedColorArray([Color(0.42, 0.68, 0.92)]))
	elif kind == "fixture":
		var fixture := visual_style.trim_prefix("fixture:")
		if not is_inn_v3 or not _draw_northgate_inn_v3_prop(canvas, fixture):
			_draw_fixture(canvas, fixture)
	elif kind == "surface_detail":
		var fixture := visual_style.trim_prefix("fixture:")
		if not _draw_northgate_surface_prop(canvas, fixture):
			_draw_fixture(canvas, fixture)
	else:
		canvas.draw_rect(Rect2(Vector2(-4.0, -4.0), Vector2(8.0, 8.0)), color_for_kind(kind), true)


static func color_for_kind(kind: String) -> Color:
	var color := Color(0.60, 0.60, 0.60)
	match kind:
		"npc":
			color = Color(0.61, 0.43, 0.24)
		"pickup":
			color = Color(0.78, 0.58, 0.12)
		"container":
			color = Color(0.50, 0.32, 0.16)
		"door":
			color = Color(0.38, 0.25, 0.16)
		"readable":
			color = Color(0.84, 0.80, 0.58)
		"rest":
			color = Color(0.94, 0.45, 0.18)
		"poi":
			color = Color(0.48, 0.38, 0.24)
		"location":
			color = Color(0.18, 0.38, 0.56)
	return color


static func _draw_pickup(canvas: CanvasItem, pickup_item_model: Dictionary) -> void:
	if pickup_item_model.is_empty():
		canvas.draw_rect(Rect2(Vector2(-5, -5), Vector2(10, 10)), Color(0.93, 0.76, 0.25), true)
		return
	ItemVisual2D.draw_visual(canvas, pickup_item_model)


static func _draw_poi(canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(Vector2(-9, -3), Vector2(18, 12)), Color(0.46, 0.36, 0.22), true)
	var roof := PackedVector2Array([Vector2(-11, -3), Vector2(0, -11), Vector2(11, -3)])
	canvas.draw_polygon(roof, PackedColorArray([Color(0.58, 0.18, 0.14)]))
	canvas.draw_rect(Rect2(Vector2(-2, 2), Vector2(4, 7)), Color(0.18, 0.11, 0.07), true)


static func _draw_sign(canvas: CanvasItem) -> void:
	canvas.draw_line(Vector2(0.0, -8.0), Vector2(0.0, 8.0), Color(0.18, 0.10, 0.045), 2.0)
	var board := Rect2(Vector2(-8.0, -8.0), Vector2(16.0, 10.0))
	canvas.draw_rect(board, Color(0.50, 0.35, 0.16), true)
	canvas.draw_rect(board, Color(0.10, 0.06, 0.025), false, 1.0)
	canvas.draw_line(
		board.position + Vector2(3.0, 3.5),
		board.position + Vector2(13.0, 3.5),
		Color(0.82, 0.72, 0.48),
		0.8
	)
	canvas.draw_line(
		board.position + Vector2(3.0, 6.5),
		board.position + Vector2(11.0, 6.5),
		Color(0.82, 0.72, 0.48),
		0.8
	)


static func _draw_npc_marker(canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(Vector2(-3.0, -7.0), Vector2(6.0, 8.0)), Color(0.61, 0.43, 0.24), true)
	canvas.draw_rect(Rect2(Vector2(-5.0, 1.0), Vector2(10.0, 7.0)), Color(0.47, 0.31, 0.18), true)


static func _draw_fixture(canvas: CanvasItem, fixture: String) -> void:
	if _draw_northgate_interior_prop(canvas, fixture):
		return
	var wood := Color(0.38, 0.22, 0.11)
	var light_wood := Color(0.58, 0.38, 0.19)
	if fixture.contains("hearth") or fixture == "road_altar":
		canvas.draw_circle(Vector2(0, 2), 7.0, Color(0.24, 0.20, 0.17))
		canvas.draw_circle(Vector2(0, 1), 4.0, Color(0.96, 0.43, 0.12))
		canvas.draw_circle(Vector2(1, -1), 2.0, Color(1.0, 0.78, 0.25))
	elif fixture.contains("bed") or fixture.contains("bunk") or fixture == "cradle":
		canvas.draw_rect(Rect2(-8, -5, 16, 11), wood, true)
		canvas.draw_rect(Rect2(-6, -4, 12, 8), Color(0.39, 0.48, 0.55), true)
		canvas.draw_rect(Rect2(-5, -3, 5, 3), Color(0.79, 0.74, 0.61), true)
	elif fixture.contains("table") or fixture.contains("desk") or fixture.contains("counter") or fixture == "workbench":
		canvas.draw_rect(Rect2(-9, -4, 18, 8), light_wood, true)
		canvas.draw_line(Vector2(-6, 3), Vector2(-6, 8), wood, 2.0)
		canvas.draw_line(Vector2(6, 3), Vector2(6, 8), wood, 2.0)
	elif fixture.contains("screen"):
		for x in [-6.0, 0.0, 6.0]:
			canvas.draw_rect(Rect2(x - 3.0, -9, 6, 17), Color(0.46, 0.27, 0.13), true)
			canvas.draw_line(Vector2(x, -7), Vector2(x, 6), Color(0.78, 0.61, 0.34), 1.0)
	elif fixture.contains("cloak"):
		canvas.draw_line(Vector2(-7, -8), Vector2(7, -8), wood, 2.0)
		canvas.draw_polygon(PackedVector2Array([Vector2(-5,-7), Vector2(4,-7), Vector2(7,8), Vector2(-7,8)]), PackedColorArray([Color(0.25, 0.34, 0.39)]))
		canvas.draw_line(Vector2(0, -6), Vector2(1, 7), Color(0.61, 0.72, 0.73, 0.55), 1.0)
	elif fixture.contains("jar"):
		for entry in [[-5.0, 1.0, 4.0], [1.0, -1.0, 5.0], [6.0, 2.0, 3.0]]:
			canvas.draw_circle(Vector2(entry[0], entry[1]), entry[2], Color(0.58, 0.33, 0.17))
			canvas.draw_line(Vector2(entry[0] - 2, entry[1] - entry[2]), Vector2(entry[0] + 2, entry[1] - entry[2]), Color(0.87, 0.67, 0.31), 1.0)
	elif fixture.contains("basket"):
		canvas.draw_ellipse(Vector2(0, 2), 8.0, 5.5, Color(0.57, 0.37, 0.17))
		for x in [-5.0, 0.0, 5.0]:
			canvas.draw_line(Vector2(x, -1), Vector2(x * 0.7, 6), Color(0.80, 0.61, 0.30), 1.0)
		canvas.draw_arc(Vector2(0, 0), 7.0, PI, TAU, 12, Color(0.82, 0.63, 0.31), 1.5)
	elif fixture.contains("memento"):
		canvas.draw_rect(Rect2(-8, -7, 6, 8), Color(0.49, 0.30, 0.14), true)
		canvas.draw_rect(Rect2(1, -8, 7, 9), Color(0.60, 0.40, 0.19), true)
		canvas.draw_circle(Vector2(-4, -3), 1.5, Color(0.84, 0.68, 0.39))
		canvas.draw_circle(Vector2(4, -4), 2.0, Color(0.78, 0.60, 0.34))
		canvas.draw_rect(Rect2(-6, 3, 12, 4), wood, true)
	elif fixture.contains("shelf") or fixture.contains("rack"):
		canvas.draw_rect(Rect2(-7, -8, 14, 16), wood, true)
		for y in [-4, 1, 6]:
			canvas.draw_line(Vector2(-6, y), Vector2(6, y), Color(0.76, 0.56, 0.28), 1.5)
	elif fixture.contains("chest") or fixture.contains("trunk") or fixture.contains("crate") or fixture.contains("barrel"):
		canvas.draw_rect(Rect2(-7, -5, 14, 11), light_wood, true)
		canvas.draw_rect(Rect2(-7, -5, 14, 11), Color(0.17, 0.10, 0.05), false, 1.3)
		canvas.draw_circle(Vector2(0, 0), 1.5, Color(0.86, 0.69, 0.30))
	elif fixture.contains("chair") or fixture.contains("stool") or fixture.contains("bench"):
		canvas.draw_rect(Rect2(-6, -3, 12, 6), light_wood, true)
		canvas.draw_line(Vector2(-4, 2), Vector2(-4, 8), wood, 2.0)
		canvas.draw_line(Vector2(4, 2), Vector2(4, 8), wood, 2.0)
	elif fixture == "anvil" or fixture.contains("tool") or fixture.contains("weapon"):
		canvas.draw_polygon(PackedVector2Array([Vector2(-8,-4), Vector2(7,-4), Vector2(4,1), Vector2(-5,1)]), PackedColorArray([Color(0.30,0.33,0.35)]))
		canvas.draw_rect(Rect2(-3, 1, 6, 7), Color(0.20, 0.22, 0.23), true)
	elif fixture.contains("notice") or fixture.contains("map"):
		canvas.draw_rect(Rect2(-9, -7, 18, 14), Color(0.34, 0.20, 0.09), true)
		canvas.draw_rect(Rect2(-7, -5, 14, 10), Color(0.78, 0.68, 0.45), true)
		canvas.draw_line(Vector2(-5, -2), Vector2(5, -2), Color(0.42, 0.30, 0.17), 1.0)
		canvas.draw_line(Vector2(-5, 1), Vector2(3, 1), Color(0.42, 0.30, 0.17), 1.0)
	elif fixture.contains("stall"):
		canvas.draw_line(Vector2(-9, -8), Vector2(-9, 8), wood, 2.5)
		canvas.draw_line(Vector2(9, -8), Vector2(9, 8), wood, 2.5)
		canvas.draw_line(Vector2(-9, 4), Vector2(9, 4), light_wood, 2.5)
		canvas.draw_circle(Vector2(0, -1), 5.0, Color(0.34, 0.24, 0.15))
		canvas.draw_circle(Vector2(-2, -3), 1.0, Color(0.08, 0.06, 0.04))
	elif fixture.contains("trough") or fixture.contains("feed_bin"):
		canvas.draw_polygon(PackedVector2Array([Vector2(-9,-5), Vector2(9,-5), Vector2(7,6), Vector2(-7,6)]), PackedColorArray([Color(0.33, 0.23, 0.14)]))
		canvas.draw_line(Vector2(-7, -2), Vector2(7, -2), Color(0.14, 0.23, 0.24), 2.0)
	elif fixture.contains("offering_bowl"):
		canvas.draw_circle(Vector2.ZERO, 7.0, Color(0.38, 0.32, 0.23))
		canvas.draw_circle(Vector2.ZERO, 4.0, Color(0.78, 0.57, 0.20))
		canvas.draw_circle(Vector2(-1, -1), 1.5, Color(0.94, 0.78, 0.31))
	elif fixture == "well":
		canvas.draw_circle(Vector2(0, 2), 9.0, Color(0.31, 0.32, 0.29))
		canvas.draw_circle(Vector2(0, 2), 6.0, Color(0.12, 0.25, 0.29))
		canvas.draw_line(Vector2(-10, -7), Vector2(10, -7), wood, 2.0)
		canvas.draw_line(Vector2(-8, -8), Vector2(-8, 4), wood, 2.0)
		canvas.draw_line(Vector2(8, -8), Vector2(8, 4), wood, 2.0)
	elif fixture == "lantern_post":
		canvas.draw_line(Vector2(0, 8), Vector2(0, -8), wood, 2.0)
		canvas.draw_rect(Rect2(-4, -11, 8, 7), Color(0.18, 0.15, 0.10), true)
		canvas.draw_circle(Vector2(0, -7), 2.0, Color(1.0, 0.70, 0.24, 0.88))
	elif fixture == "gate_tower":
		canvas.draw_rect(Rect2(-9, -6, 18, 15), Color(0.31, 0.17, 0.075), true)
		for x in [-6.0, 0.0, 6.0]:
			canvas.draw_line(Vector2(x, -5), Vector2(x, 8), Color(0.62, 0.39, 0.17), 1.5)
		canvas.draw_polygon(PackedVector2Array([Vector2(-10,-6), Vector2(-5,-13), Vector2(0,-7), Vector2(5,-13), Vector2(10,-6)]), PackedColorArray([Color(0.24, 0.12, 0.05)]))
		canvas.draw_line(Vector2(0, -11), Vector2(0, -20), wood, 2.0)
		canvas.draw_polygon(PackedVector2Array([Vector2(1,-19), Vector2(9,-16), Vector2(1,-12)]), PackedColorArray([Color(0.69, 0.30, 0.16)]))
	elif fixture == "road_post":
		canvas.draw_line(Vector2(0, 8), Vector2(0, -8), Color(0.25, 0.14, 0.07), 2.0)
		canvas.draw_polygon(PackedVector2Array([Vector2(-7,-8), Vector2(7,-8), Vector2(5,-2), Vector2(-5,-2)]), PackedColorArray([Color(0.67, 0.51, 0.28)]))
	elif fixture == "hanging_sign":
		canvas.draw_line(Vector2(0, -9), Vector2(0, -4), wood, 1.5)
		canvas.draw_rect(Rect2(-9, -4, 18, 10), Color(0.46, 0.28, 0.12), true)
		canvas.draw_circle(Vector2(0, 1), 2.0, Color(0.89, 0.68, 0.28))
	elif fixture == "market_stall":
		canvas.draw_rect(Rect2(-11, -2, 22, 8), Color(0.42, 0.24, 0.10), true)
		canvas.draw_line(Vector2(-10, -2), Vector2(-10, -10), wood, 2.0)
		canvas.draw_line(Vector2(10, -2), Vector2(10, -10), wood, 2.0)
		canvas.draw_polygon(PackedVector2Array([Vector2(-12,-11), Vector2(12,-11), Vector2(9,-5), Vector2(-9,-5)]), PackedColorArray([Color(0.24, 0.43, 0.40)]))
		for x in [-7.0, 0.0, 7.0]:
			canvas.draw_line(Vector2(x, -10), Vector2(x + 2, -6), Color(0.86, 0.63, 0.28), 1.5)
	elif fixture == "hitching_post":
		canvas.draw_line(Vector2(-9, 0), Vector2(9, 0), light_wood, 2.5)
		canvas.draw_line(Vector2(-7, -7), Vector2(-7, 8), wood, 2.5)
		canvas.draw_line(Vector2(7, -7), Vector2(7, 8), wood, 2.5)
		canvas.draw_circle(Vector2(0, 2), 3.0, Color(0.23, 0.14, 0.08), false, 1.5)
	elif fixture == "water_trough":
		canvas.draw_polygon(PackedVector2Array([Vector2(-11,-5), Vector2(11,-5), Vector2(8,6), Vector2(-8,6)]), PackedColorArray([Color(0.34, 0.24, 0.15)]))
		canvas.draw_line(Vector2(-8, -2), Vector2(8, -2), Color(0.13, 0.31, 0.34), 3.0)
	elif fixture == "notice_kiosk":
		canvas.draw_line(Vector2(0, 8), Vector2(0, -8), wood, 2.5)
		canvas.draw_rect(Rect2(-10, -11, 20, 13), Color(0.37, 0.22, 0.10), true)
		canvas.draw_rect(Rect2(-8, -9, 7, 8), Color(0.81, 0.70, 0.47), true)
		canvas.draw_rect(Rect2(2, -8, 6, 7), Color(0.73, 0.62, 0.41), true)
	elif fixture == "woodpile" or fixture == "coal_stack":
		for offset in [-5.0, 0.0, 5.0]:
			canvas.draw_line(Vector2(-8, offset * 0.25), Vector2(7, offset * 0.25 + 2.0), Color(0.45, 0.24, 0.10), 3.0)
		canvas.draw_circle(Vector2(-8, 0), 2.0, Color(0.68, 0.42, 0.19))
	elif fixture == "hay_bale":
		canvas.draw_circle(Vector2(0, 0), 7.0, Color(0.78, 0.59, 0.25))
		canvas.draw_line(Vector2(-4, -5), Vector2(-4, 5), Color(0.43, 0.28, 0.10), 1.0)
		canvas.draw_line(Vector2(2, -6), Vector2(2, 6), Color(0.43, 0.28, 0.10), 1.0)
	elif fixture == "cart":
		canvas.draw_rect(Rect2(-10, -4, 18, 8), Color(0.42, 0.25, 0.11), true)
		canvas.draw_circle(Vector2(-7, 6), 3.0, Color(0.16, 0.10, 0.06))
		canvas.draw_circle(Vector2(6, 6), 3.0, Color(0.16, 0.10, 0.06))
		canvas.draw_line(Vector2(8, -2), Vector2(13, -8), wood, 2.0)
	elif fixture == "crate_stack" or fixture == "basket":
		canvas.draw_rect(Rect2(-8, -7, 15, 13), Color(0.57, 0.35, 0.15), true)
		canvas.draw_line(Vector2(-6, -6), Vector2(5, 5), Color(0.24, 0.13, 0.06), 1.0)
		canvas.draw_line(Vector2(5, -6), Vector2(-6, 5), Color(0.24, 0.13, 0.06), 1.0)
	elif fixture == "candle_cluster":
		canvas.draw_circle(Vector2(0, 3), 7.0, Color(0.22, 0.17, 0.10))
		for offset in [-4.0, 0.0, 4.0]:
			canvas.draw_rect(Rect2(offset - 1.0, -5, 2, 7), Color(0.88, 0.75, 0.45), true)
			canvas.draw_circle(Vector2(offset, -7), 1.5, Color(1.0, 0.68, 0.18))
	elif fixture == "stone_marker":
		canvas.draw_circle(Vector2(-4, 2), 5.0, Color(0.45, 0.47, 0.43))
		canvas.draw_circle(Vector2(4, 3), 4.0, Color(0.35, 0.38, 0.36))
	elif fixture == "planter" or fixture == "rain_barrel":
		canvas.draw_rect(Rect2(-8, -4, 16, 9), Color(0.39, 0.24, 0.11), true)
		if fixture == "planter":
			for offset in [-4.0, 0.0, 4.0]:
				canvas.draw_line(Vector2(offset, -4), Vector2(offset - 2, -10), Color(0.24, 0.48, 0.20), 2.0)
		else:
			canvas.draw_line(Vector2(-5, -3), Vector2(5, -3), Color(0.72, 0.48, 0.22), 1.0)
	elif fixture == "wash_line":
		canvas.draw_line(Vector2(-9, -7), Vector2(9, -7), Color(0.24, 0.14, 0.08), 1.0)
		for offset in [-6.0, 0.0, 6.0]:
			canvas.draw_line(Vector2(offset, -7), Vector2(offset, -1), Color(0.72, 0.75, 0.69), 3.0)
	elif fixture == "fence":
		canvas.draw_line(Vector2(-10, 0), Vector2(10, 0), Color(0.38, 0.22, 0.10), 2.0)
		for offset in [-8.0, 0.0, 8.0]:
			canvas.draw_line(Vector2(offset, -7), Vector2(offset, 7), Color(0.45, 0.27, 0.12), 2.0)
	elif fixture == "tree":
		canvas.draw_line(Vector2(0, 7), Vector2(0, -2), Color(0.25, 0.13, 0.06), 3.0)
		canvas.draw_circle(Vector2(-4, -5), 6.0, Color(0.16, 0.33, 0.16))
		canvas.draw_circle(Vector2(4, -6), 6.0, Color(0.21, 0.40, 0.18))
		canvas.draw_circle(Vector2(0, -10), 5.0, Color(0.26, 0.45, 0.19))
	else:
		canvas.draw_circle(Vector2.ZERO, 6.0, Color(0.52, 0.36, 0.18))
		canvas.draw_circle(Vector2.ZERO, 3.0, Color(0.72, 0.60, 0.34))


static func _draw_northgate_surface_prop(canvas: CanvasItem, fixture: String) -> bool:
	var texture: Texture2D = NORTHGATE_PROP_TEXTURES.get(fixture)
	if texture == null:
		texture = NORTHGATE_GROUND_TEXTURES.get(fixture)
	if texture == null:
		return false
	var size := texture.get_size()
	canvas.draw_texture(texture, -size * 0.5)
	return true


static func _draw_northgate_interior_prop(canvas: CanvasItem, fixture: String) -> bool:
	if fixture.begins_with("inn_v3_"):
		var inn_key := fixture.trim_prefix("inn_v3_")
		var inn_texture: Texture2D = NORTHGATE_INN_V3_TEXTURES.get(inn_key)
		if inn_texture == null:
			return false
		var inn_size := inn_texture.get_size()
		canvas.draw_texture(inn_texture, -inn_size * 0.5)
		return true
	var key := ""
	if fixture.contains("road_altar") or fixture.contains("offering") or fixture.contains("shrine_altar"):
		key = "altar"
	elif fixture.contains("hearth"):
		key = "hearth"
	elif fixture.contains("bed") or fixture.contains("bunk") or fixture == "cradle":
		key = "bed"
	elif fixture.contains("counter") or fixture.contains("bar"):
		key = "counter"
	elif fixture == "workbench" or fixture.contains("tool"):
		key = "workbench"
	elif fixture.contains("weapon"):
		key = "weapon_rack"
	elif fixture.contains("table") or fixture.contains("desk"):
		key = "table"
	elif fixture.contains("screen") or fixture.contains("partition"):
		key = "partition"
	elif fixture.contains("cupboard") or fixture.contains("cabinet"):
		key = "cupboard"
	elif fixture.contains("shelf") or fixture.contains("jar"):
		key = "shelf"
	elif fixture.contains("chest") or fixture.contains("trunk"):
		key = "chest"
	elif fixture.contains("sack"):
		key = "sacks"
	elif fixture.contains("bucket"):
		key = "bucket"
	elif fixture.contains("bench"):
		key = "bench"
	elif fixture.contains("chair") or fixture.contains("stool"):
		key = "stool"
	if key.is_empty():
		return false
	var texture: Texture2D = NORTHGATE_INTERIOR_PROP_TEXTURES.get(key)
	if texture == null:
		return false
	var size := texture.get_size()
	canvas.draw_texture(texture, -size * 0.5)
	return true


static func _draw_northgate_inn_v3_prop(canvas: CanvasItem, fixture: String) -> bool:
	var key := ""
	if fixture.contains("hearth"):
		key = "hearth"
	elif fixture.contains("bed") or fixture.contains("bunk"):
		key = "bed"
	elif fixture.contains("counter"):
		key = "bar_counter"
	elif fixture.contains("shelf") or fixture.contains("barrel"):
		key = "backbar_shelf"
	elif fixture.contains("table"):
		key = "common_table"
	elif fixture.contains("bench"):
		key = "bench"
	elif fixture.contains("stool") or fixture.contains("chair"):
		key = "stool"
	elif fixture.contains("partition") or fixture.contains("screen"):
		key = "partition"
	elif fixture.contains("trunk") or fixture.contains("chest"):
		key = "trunk"
	if key.is_empty():
		return false
	var texture: Texture2D = NORTHGATE_INN_V3_TEXTURES.get(key)
	if texture == null:
		return false
	var size := texture.get_size()
	canvas.draw_texture(texture, -size * 0.5)
	return true


static func _draw_hostile_marker(canvas: CanvasItem) -> void:
	var points := PackedVector2Array(
		[Vector2(0.0, -9.0), Vector2(7.0, 0.0), Vector2(0.0, 9.0), Vector2(-7.0, 0.0)]
	)
	canvas.draw_polygon(points, PackedColorArray([Color(0.75, 0.20, 0.16)]))
	points.append(points[0])
	canvas.draw_polyline(points, Color(0.12, 0.02, 0.02), 1.5)
