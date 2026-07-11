class_name AtlasPreview
extends Control

const REGION_COLORS := [
	Color("5e8c61"), Color("466b4d"), Color("8a7960"), Color("9c9a62"),
	Color("718a7a"), Color("557a68"), Color("77758a"), Color("72777c"),
	Color("8d6748"), Color("65737e"), Color("394d5c")
]
const ROUTE_COLORS := {
	"major_road": Color("f4d58d"), "trade_road": Color("dcbf78"),
	"ferry": Color("7fc8f8"), "canopy_route": Color("9bd36a"),
	"cliff_route": Color("df9f62")
}

var atlas: Dictionary = {}
var warnings := PackedStringArray()
var show_zones := true


func setup(atlas_data: Dictionary, validation_warnings: PackedStringArray = PackedStringArray()) -> void:
	atlas = atlas_data
	warnings = validation_warnings
	queue_redraw()


func atlas_rect() -> Rect2:
	var margin := Vector2(28, 48)
	var available := size - Vector2(56, 100)
	var atlas_size_value: Array = atlas.get("coordinate_space", {}).get("size", [1536, 1024])
	var source_size := Vector2(float(atlas_size_value[0]), float(atlas_size_value[1]))
	var scale := minf(available.x / source_size.x, available.y / source_size.y)
	return Rect2(margin, source_size * scale)


func atlas_to_preview(point: Vector2) -> Vector2:
	var rect := atlas_rect()
	var atlas_size_value: Array = atlas.get("coordinate_space", {}).get("size", [1536, 1024])
	return rect.position + point * (rect.size.x / float(atlas_size_value[0]))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("111922"))
	var rect := atlas_rect()
	draw_rect(rect.grow(3), Color("d3b66b"), false, 2.0)
	for index in atlas.get("regions", []).size():
		var region: Dictionary = atlas["regions"][index]
		var polygon := _preview_points(region.get("polygon", []))
		if polygon.size() >= 3:
			var color: Color = REGION_COLORS[index % REGION_COLORS.size()]
			draw_colored_polygon(polygon, color.darkened(0.22))
			draw_polyline(_closed(polygon), color.lightened(0.22), 1.4, true)
	if show_zones:
		for zone in atlas.get("zones", []):
			var polygon := _preview_points(zone.get("polygon", []))
			if polygon.size() >= 3:
				var zone_color := Color("bd72d6") if zone.get("kind") == "cult_pressure" else Color("9fd18b")
				draw_polyline(_closed(polygon), zone_color, 1.3, true)
	for feature in atlas.get("terrain_features", []):
		if feature.has("path"):
			var color := Color("5eb7e5") if feature.get("kind") == "river" else Color("9aa0a4")
			draw_polyline(_preview_points(feature["path"]), color, 2.0, true)
		elif feature.get("kind") in ["lake", "water_body"]:
			draw_colored_polygon(_preview_points(feature.get("polygon", [])), Color("305f7a"))
	for route in atlas.get("routes", []):
		var kind := String(route.get("kind", ""))
		draw_polyline(_preview_points(route.get("path", [])), ROUTE_COLORS.get(kind, Color.WHITE), 2.1 if kind == "major_road" else 1.35, true)
	for landmark in atlas.get("landmarks", []):
		_draw_anchor(landmark, Color("dd8dea"), false)
	for settlement in atlas.get("settlements", []):
		_draw_anchor(settlement, Color("f7e7ad"), true)
	_draw_header(rect)
	_draw_warning_panel(rect)


func _draw_anchor(entry: Dictionary, color: Color, label: bool) -> void:
	var raw_anchor: Variant = entry.get("anchor", [])
	if not raw_anchor is Array or raw_anchor.size() != 2:
		return
	var point := atlas_to_preview(Vector2(float(raw_anchor[0]), float(raw_anchor[1])))
	draw_circle(point, 3.2, color)
	draw_circle(point, 4.8, Color("17202a"), false, 1.2)
	if label:
		draw_string(ThemeDB.fallback_font, point + Vector2(6, 3), String(entry.get("name", entry.get("id", ""))), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("f5edd7"))


func _draw_header(rect: Rect2) -> void:
	var target: Dictionary = atlas.get("traversal_target", {})
	var scale: Dictionary = atlas.get("generator_coordinate_space", {})
	var subtitle := "PROPOSAL • %s global tiles • ~%.1f min coast-to-coast" % [
		str(scale.get("global_tile_bounds", {})),
		float(target.get("scaled_land_width_tiles", 0.0)) / maxf(float(target.get("baseline_tiles_per_second", 1.0)), 0.01) / 60.0
	]
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, 24), "VELCOR WORLD ATLAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f1d487"))
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 220, 23), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("b8c2ca"))


func _draw_warning_panel(rect: Rect2) -> void:
	var text := "VALIDATION: clean" if warnings.is_empty() else "VALIDATION: %d warning(s)" % warnings.size()
	var color := Color("8bd49c") if warnings.is_empty() else Color("ff8c7a")
	draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, size.y - 22), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
	if not warnings.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(rect.position.x + 180, size.y - 22), warnings[0], HORIZONTAL_ALIGNMENT_LEFT, int(size.x - rect.position.x - 200), 12, color)


func _preview_points(raw_points: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for raw_point in raw_points:
		if raw_point is Array and raw_point.size() == 2:
			points.append(atlas_to_preview(Vector2(float(raw_point[0]), float(raw_point[1]))))
	return points


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if not result.is_empty():
		result.append(result[0])
	return result
