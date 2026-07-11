class_name WorldAtlasPreview
extends Control

const REGION_COLORS := [
	Color("496b45"), Color("315b47"), Color("6c6758"), Color("8a7b46"),
	Color("60706b"), Color("405e4f"), Color("626052"), Color("6e7076"),
	Color("765b3d"), Color("536875"), Color("314c59")
]
const ROUTE_COLORS := {
	"major_road": Color("f2d17d"), "trade_road": Color("d9b86b"),
	"ferry": Color("75c4dc"), "canopy_route": Color("8fd16a"),
	"cliff_route": Color("dfaa70")
}

var atlas: Dictionary = {}
var warnings := PackedStringArray()
var content_rect := Rect2(28, 52, 1096, 548)


func setup(atlas_data: Dictionary, validation_warnings: PackedStringArray = PackedStringArray()) -> void:
	atlas = atlas_data
	warnings = validation_warnings
	queue_redraw()


static func atlas_to_preview(point: Vector2, atlas_bounds: Rect2, preview_rect: Rect2) -> Vector2:
	if atlas_bounds.size.x <= 0.0 or atlas_bounds.size.y <= 0.0:
		return preview_rect.position
	return preview_rect.position + Vector2(
		(point.x - atlas_bounds.position.x) / atlas_bounds.size.x * preview_rect.size.x,
		(point.y - atlas_bounds.position.y) / atlas_bounds.size.y * preview_rect.size.y
	)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("101b25"))
	if atlas.is_empty():
		_draw_text(Vector2(28, 34), "ATLAS UNAVAILABLE", Color("ef786f"), 18)
		return
	var bounds := _atlas_bounds()
	_draw_text(Vector2(28, 32), "VELCOR ATLAS — PROPOSAL / NOT RUNTIME CANON", Color("f0d594"), 18)
	var traversal: Dictionary = atlas.get("traversal_target", {})
	_draw_text(Vector2(690, 32), "Scale: %s tiles/unit  |  Crossing: ~%s min" % [
		str(atlas.get("generator_coordinate_space", {}).get("global_tiles_per_atlas_unit", "?")),
		str(traversal.get("target_minutes", "?"))
	], Color("b7c6cc"), 13)
	draw_rect(content_rect, Color("172d36"), true)
	for index in atlas.get("regions", []).size():
		var region: Dictionary = atlas["regions"][index]
		var points := _preview_points(region.get("polygon", []), bounds)
		if points.size() >= 3:
			var color: Color = REGION_COLORS[index % REGION_COLORS.size()]
			draw_colored_polygon(points, Color(color, 0.78))
			draw_polyline(_closed(points), color.lightened(0.34), 1.5, true)
	for exclusion in atlas.get("water_exclusions", []):
		var water := _preview_points(exclusion.get("polygon", []), bounds)
		if water.size() >= 3:
			draw_colored_polygon(water, Color("173e55"))
			draw_polyline(_closed(water), Color("65a8c4"), 1.5, true)
	for zone in atlas.get("zones", []):
		var zone_points := _preview_points(zone.get("polygon", []), bounds)
		if zone_points.size() >= 3:
			var zone_color := Color("bb72c7") if String(zone.get("kind", "")) == "cult_pressure" else Color("8fc67c")
			draw_polyline(_closed(zone_points), Color(zone_color, 0.72), 1.2, true)
	for feature in atlas.get("terrain_features", []):
		if feature.has("path"):
			var feature_points := _preview_points(feature["path"], bounds)
			if feature_points.size() >= 2:
				var feature_color := Color("55add1") if String(feature.get("kind", "")) == "river" else Color("adb0ae")
				draw_polyline(feature_points, feature_color, 2.0, true)
	for route in atlas.get("routes", []):
		var route_points := _preview_points(route.get("path", []), bounds)
		if route_points.size() >= 2:
			var route_color: Color = ROUTE_COLORS.get(String(route.get("kind", "")), Color.WHITE)
			draw_polyline(route_points, route_color, 1.8, true)
	for settlement in atlas.get("settlements", []):
		var point := _preview_point(settlement.get("anchor", [0, 0]), bounds)
		var unresolved := String(settlement.get("review_status", "")) != "aligned"
		draw_circle(point, 4.0 if String(settlement.get("size_band", "")) == "large" else 2.8, Color("ef7f73") if unresolved else Color("f4e4ad"))
		if String(settlement.get("size_band", "")) == "large" or unresolved:
			_draw_text(point + Vector2(5, -3), String(settlement.get("name", "")), Color("f2ead4"), 10)
	for landmark in atlas.get("landmarks", []):
		var point := _preview_point(landmark.get("anchor", [0, 0]), bounds)
		draw_line(point + Vector2(-3, 0), point + Vector2(3, 0), Color("d9a8e4"), 1.5)
		draw_line(point + Vector2(0, -3), point + Vector2(0, 3), Color("d9a8e4"), 1.5)
	draw_rect(content_rect, Color("8da0a4"), false, 1.0)
	var warning_color := Color("8bd197") if warnings.is_empty() else Color("ef786f")
	_draw_text(Vector2(28, 626), "VALIDATION: %s" % ("PASS" if warnings.is_empty() else "%d WARNING(S)" % warnings.size()), warning_color, 14)
	if not warnings.is_empty():
		_draw_text(Vector2(225, 626), String(warnings[0]).left(110), Color("efb0a9"), 11)


func _atlas_bounds() -> Rect2:
	var value: Dictionary = atlas.get("continent_bounds", {})
	var minimum := _raw_point(value.get("min", [0, 0]))
	var maximum := _raw_point(value.get("max", [1, 1]))
	return Rect2(minimum, maximum - minimum)


func _preview_points(raw_points: Array, bounds: Rect2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for raw_point in raw_points:
		result.append(_preview_point(raw_point, bounds))
	return result


func _preview_point(raw_point: Array, bounds: Rect2) -> Vector2:
	return atlas_to_preview(_raw_point(raw_point), bounds, content_rect)


func _raw_point(raw_point: Array) -> Vector2:
	return Vector2(float(raw_point[0]), float(raw_point[1]))


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	result.append(points[0])
	return result


func _draw_text(position: Vector2, value: String, color: Color, font_size: int) -> void:
	draw_string(ThemeDB.fallback_font, position, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
