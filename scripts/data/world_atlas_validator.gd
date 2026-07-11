class_name WorldAtlasValidator
extends RefCounted

const PATH_ENDPOINT_TOLERANCE := 18.0
const COLLECTIONS_WITH_IDS := [
	"regions", "terrain_features", "settlements", "routes", "zones", "landmarks"
]
const ROUTE_KINDS := ["major_road", "trade_road", "ferry", "canopy_route", "cliff_route"]


static func load_atlas(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func validate(atlas: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if atlas.is_empty():
		errors.append("Atlas is empty or unreadable")
		return errors
	_require_text(atlas, "schema_version", "Atlas", errors)
	if String(atlas.get("proposal_status", "")) != "proposal":
		errors.append("Atlas proposal_status must be proposal")
	var bounds := _bounds_rect(atlas.get("continent_bounds", {}), errors)
	_validate_generator_scale(atlas, errors)
	_validate_polygon("coastline", atlas.get("coastline", []), bounds, errors)
	var ids := {}
	for collection_name in COLLECTIONS_WITH_IDS:
		_validate_collection_ids(atlas, collection_name, ids, errors)
	for exclusion in atlas.get("water_exclusions", []):
		var exclusion_label := "water exclusion %s" % String(exclusion.get("id", "<missing>"))
		_validate_polygon(exclusion_label, exclusion.get("polygon", []), bounds, errors)
	for region in atlas.get("regions", []):
		var region_label := "region %s" % String(region.get("id", "<missing>"))
		_validate_polygon(region_label, region.get("polygon", []), bounds, errors)
		_validate_biomes(region, errors)
	for feature in atlas.get("terrain_features", []):
		_validate_geometry("terrain feature", feature, bounds, errors)
	for zone in atlas.get("zones", []):
		var zone_label := "zone %s" % String(zone.get("id", "<missing>"))
		_validate_polygon(zone_label, zone.get("polygon", []), bounds, errors)
	for route in atlas.get("routes", []):
		_validate_route(route, atlas, ids, bounds, errors)
	_validate_settlements(atlas, bounds, errors)
	_validate_landmarks(atlas, bounds, errors)
	for required_id in atlas.get("required_named_location_ids", []):
		if not ids.has(String(required_id)):
			errors.append("Missing required named location %s" % String(required_id))
	return errors


static func atlas_to_global_tile(atlas: Dictionary, atlas_point: Vector2) -> Vector2i:
	var config: Dictionary = atlas.get("generator_coordinate_space", {})
	var origin_value: Variant = config.get("atlas_origin_maps_to_global_tile", [0, 0])
	var origin := _point(origin_value) if _valid_point(origin_value) else Vector2.ZERO
	var scale := float(config.get("global_tiles_per_atlas_unit", 1.0))
	return Vector2i(roundi(origin.x + atlas_point.x * scale), roundi(origin.y + atlas_point.y * scale))


static func _validate_generator_scale(atlas: Dictionary, errors: PackedStringArray) -> void:
	var config: Variant = atlas.get("generator_coordinate_space", {})
	if not config is Dictionary or String(config.get("kind", "")) != "global_tiles":
		errors.append("generator_coordinate_space kind must be global_tiles")
		return
	if not _valid_point(config.get("atlas_origin_maps_to_global_tile", [])):
		errors.append("generator_coordinate_space needs a numeric atlas origin")
	var scale_value: Variant = config.get("global_tiles_per_atlas_unit", 0)
	if (not scale_value is int and not scale_value is float) or float(scale_value) <= 0.0:
		errors.append("global_tiles_per_atlas_unit must be positive")
	var target: Variant = atlas.get("traversal_target", {})
	if not target is Dictionary or float(target.get("target_minutes", 0.0)) < 25.0:
		errors.append("traversal_target must preserve a roughly half-hour continent crossing")
	elif (
		float(target.get("scaled_land_width_tiles", 0.0))
		< float(target.get("target_route_tiles", 0.0))
	):
		errors.append("scaled land width is shorter than the traversal target")


static func _require_text(
	data: Dictionary, key: String, label: String, errors: PackedStringArray
) -> void:
	if String(data.get(key, "")).strip_edges().is_empty():
		errors.append("%s is missing %s" % [label, key])


static func _bounds_rect(value: Variant, errors: PackedStringArray) -> Rect2:
	if (
		not value is Dictionary
		or not _valid_point(value.get("min", []))
		or not _valid_point(value.get("max", []))
	):
		errors.append("continent_bounds must contain numeric min and max points")
		return Rect2()
	var minimum := _point(value["min"])
	var maximum := _point(value["max"])
	if maximum.x <= minimum.x or maximum.y <= minimum.y:
		errors.append("continent_bounds max must exceed min")
	return Rect2(minimum, maximum - minimum)


static func _validate_collection_ids(
	atlas: Dictionary, collection_name: String, ids: Dictionary, errors: PackedStringArray
) -> void:
	var collection: Variant = atlas.get(collection_name, [])
	if not collection is Array:
		errors.append("%s must be an array" % collection_name)
		return
	for entry in collection:
		if not entry is Dictionary:
			errors.append("%s contains a non-object entry" % collection_name)
			continue
		var entry_id := String(entry.get("id", ""))
		if entry_id.is_empty():
			errors.append("%s contains an entry with missing id" % collection_name)
		elif ids.has(entry_id):
			errors.append("Duplicate atlas id %s" % entry_id)
		else:
			ids[entry_id] = entry


static func _validate_polygon(
	label: String, value: Variant, bounds: Rect2, errors: PackedStringArray
) -> void:
	if not value is Array or value.size() < 3:
		errors.append("%s must have at least 3 points" % label)
		return
	var points := PackedVector2Array()
	for raw_point in value:
		if not _valid_point(raw_point):
			errors.append("%s contains an invalid point" % label)
			return
		var point := _point(raw_point)
		points.append(point)
		if not bounds.has_point(point) and point != bounds.end:
			errors.append("%s point %s is outside continent bounds" % [label, point])
	if absf(_signed_area(points)) < 1.0:
		errors.append("%s has zero area" % label)
	if _self_intersects(points):
		errors.append("%s self-intersects" % label)


static func _validate_geometry(
	label: String, entry: Dictionary, bounds: Rect2, errors: PackedStringArray
) -> void:
	var entry_label := "%s %s" % [label, String(entry.get("id", "<missing>"))]
	if entry.has("polygon"):
		_validate_polygon(entry_label, entry["polygon"], bounds, errors)
	elif entry.has("path"):
		_validate_path(entry_label, entry["path"], bounds, errors)
	elif entry.has("anchor"):
		_validate_anchor(entry_label, entry["anchor"], bounds, errors)
	else:
		errors.append("%s has no polygon, path, or anchor" % entry_label)


static func _validate_path(
	label: String, value: Variant, bounds: Rect2, errors: PackedStringArray
) -> void:
	if not value is Array or value.size() < 2:
		errors.append("%s path must have at least 2 points" % label)
		return
	for raw_point in value:
		if not _valid_point(raw_point):
			errors.append("%s path contains an invalid point" % label)
			return
		_validate_anchor(label, raw_point, bounds, errors)


static func _validate_anchor(
	label: String, value: Variant, bounds: Rect2, errors: PackedStringArray
) -> void:
	if not _valid_point(value):
		errors.append("%s anchor must be [x, y]" % label)
		return
	var point := _point(value)
	if not bounds.has_point(point) and point != bounds.end:
		errors.append("%s anchor is outside continent bounds" % label)


static func _validate_biomes(region: Dictionary, errors: PackedStringArray) -> void:
	var weights: Variant = region.get("biome_weights", {})
	if not weights is Dictionary or weights.is_empty():
		errors.append("Region %s has no biome weights" % String(region.get("id", "<missing>")))
		return
	var total := 0.0
	for value in weights.values():
		if not value is float and not value is int:
			errors.append("Region %s has non-numeric biome weight" % String(region.get("id", "<missing>")))
			return
		total += float(value)
	if not is_equal_approx(total, 1.0):
		errors.append("Region %s biome weights must sum to 1.0" % String(region.get("id", "<missing>")))


static func _validate_settlements(
	atlas: Dictionary, bounds: Rect2, errors: PackedStringArray
) -> void:
	var regions_by_id := {}
	for region in atlas.get("regions", []):
		regions_by_id[String(region.get("id", ""))] = region
	for settlement in atlas.get("settlements", []):
		var settlement_id := String(settlement.get("id", "<missing>"))
		_validate_anchor(
			"settlement %s" % settlement_id, settlement.get("anchor", []), bounds, errors
		)
		for key in ["name", "type", "size_band", "role", "region_id", "review_status"]:
			_require_text(settlement, key, "Settlement %s" % settlement_id, errors)
		var region_id := String(settlement.get("region_id", ""))
		if not regions_by_id.has(region_id):
			errors.append("Settlement %s references missing region %s" % [settlement_id, region_id])
		elif _valid_point(settlement.get("anchor", [])):
			var polygon := _packed_points(regions_by_id[region_id].get("polygon", []))
			if (
				polygon.size() >= 3
				and not Geometry2D.is_point_in_polygon(_point(settlement["anchor"]), polygon)
			):
				errors.append("Settlement %s is outside intended region %s" % [settlement_id, region_id])
		if _point_in_water(settlement.get("anchor", []), atlas.get("water_exclusions", [])):
			errors.append("Settlement %s contradicts water exclusion" % settlement_id)


static func _validate_landmarks(
	atlas: Dictionary, bounds: Rect2, errors: PackedStringArray
) -> void:
	for landmark in atlas.get("landmarks", []):
		var landmark_label := "landmark %s" % String(landmark.get("id", "<missing>"))
		_validate_anchor(landmark_label, landmark.get("anchor", []), bounds, errors)


static func _validate_route(
	route: Dictionary, atlas: Dictionary, ids: Dictionary, bounds: Rect2, errors: PackedStringArray
) -> void:
	var route_id := String(route.get("id", "<missing>"))
	_validate_path("route %s" % route_id, route.get("path", []), bounds, errors)
	var kind := String(route.get("kind", ""))
	if kind not in ROUTE_KINDS:
		errors.append("Route %s has unsupported kind %s" % [route_id, kind])
	var endpoint_refs: Variant = route.get("endpoint_refs", [])
	if not endpoint_refs is Array or endpoint_refs.size() != 2:
		errors.append("Route %s must have exactly 2 endpoint_refs" % route_id)
		return
	var path: Variant = route.get("path", [])
	if not path is Array or path.size() < 2:
		return
	for index in 2:
		var ref_id := String(endpoint_refs[index])
		if not ids.has(ref_id):
			errors.append("Route %s endpoint references missing anchor %s" % [route_id, ref_id])
			continue
		var target: Dictionary = ids[ref_id]
		var anchor: Variant = target.get("anchor", [])
		if not _valid_point(anchor):
			errors.append(
				"Route %s endpoint %s is not a settlement, port, pass, or landmark anchor"
				% [route_id, ref_id]
			)
			continue
		var path_point := _point(path[0 if index == 0 else path.size() - 1])
		if path_point.distance_to(_point(anchor)) > PATH_ENDPOINT_TOLERANCE:
			errors.append("Route %s endpoint does not meet %s" % [route_id, ref_id])
	if kind != "ferry":
		for raw_point in path:
			if _point_in_water(raw_point, atlas.get("water_exclusions", [])):
				errors.append("Land route %s contradicts water exclusion" % route_id)
				break


static func _point_in_water(raw_point: Variant, exclusions: Array) -> bool:
	if not _valid_point(raw_point):
		return false
	for exclusion in exclusions:
		var polygon := _packed_points(exclusion.get("polygon", []))
		if polygon.size() >= 3 and Geometry2D.is_point_in_polygon(_point(raw_point), polygon):
			return true
	return false


static func _valid_point(value: Variant) -> bool:
	return (
		value is Array
		and value.size() == 2
		and (value[0] is int or value[0] is float)
		and (value[1] is int or value[1] is float)
	)


static func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


static func _packed_points(value: Variant) -> PackedVector2Array:
	var points := PackedVector2Array()
	if value is Array:
		for raw_point in value:
			if _valid_point(raw_point):
				points.append(_point(raw_point))
	return points


static func _signed_area(points: PackedVector2Array) -> float:
	var area := 0.0
	for index in points.size():
		area += points[index].cross(points[(index + 1) % points.size()])
	return area * 0.5


static func _self_intersects(points: PackedVector2Array) -> bool:
	for first in points.size():
		var first_next := (first + 1) % points.size()
		for second in range(first + 1, points.size()):
			var second_next := (second + 1) % points.size()
			if first == second or first_next == second or second_next == first:
				continue
			if (
				Geometry2D.segment_intersects_segment(
					points[first], points[first_next], points[second], points[second_next]
				)
				!= null
			):
				return true
	return false
