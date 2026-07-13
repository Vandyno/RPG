class_name WorldRegionGenerator
extends RefCounted

const WorldAtlasApprovalGate = preload("res://scripts/data/world_atlas_approval_gate.gd")
const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")
const WorldPoiGenerator = preload("res://scripts/generation/world_poi_generator.gd")

const GENERATOR_VERSION := "world_region_v3"
const DEFAULT_CELL_SIZE_CHUNKS := 8
const CHUNK_SIZE_TILES := 16
const DEFAULT_ATLAS_REVIEW_PATH := "res://data/world_atlas_review.json"
const DEFAULT_TEMPLATE_PATH := "res://data/world_region_generation_templates.json"


static func generate(
	atlas: Dictionary, region_id: String, seed: int, options: Dictionary = {}
) -> Dictionary:
	if not WorldAtlasValidator.validate(atlas).is_empty():
		return {}
	var atlas_review: Dictionary = options.get(
		"atlas_review", WorldAtlasApprovalGate.load_review(DEFAULT_ATLAS_REVIEW_PATH)
	)
	var approval := WorldAtlasApprovalGate.evaluate(atlas, atlas_review)
	if not bool(approval.get("can_generate", false)):
		return {}
	var generation_templates: Dictionary = options.get(
		"generation_templates", load_templates(DEFAULT_TEMPLATE_PATH)
	)
	if generation_templates.is_empty():
		return {}
	var region := _entry_by_id(atlas.get("regions", []), region_id)
	if region.is_empty():
		return {}
	var cell_size_chunks := maxi(int(options.get("cell_size_chunks", DEFAULT_CELL_SIZE_CHUNKS)), 1)
	var global_polygon := _global_points(atlas, region.get("polygon", []))
	if global_polygon.size() < 3:
		return {}
	var fixed_constraints := _fixed_constraints(atlas, region_id, global_polygon)
	var terrain_cells := _generate_terrain_cells(
		region,
		region_id,
		seed,
		global_polygon,
		cell_size_chunks,
		generation_templates,
		fixed_constraints
	)
	var poi_count := int(options.get("poi_count", clampi(terrain_cells.size() / 48, 72, 140)))
	var pois := _generate_pois(
		region_id,
		seed,
		terrain_cells,
		global_polygon,
		poi_count,
		generation_templates,
		fixed_constraints
	)
	_mesh_terrain_with_pois(terrain_cells, pois, generation_templates)
	var minor_routes := _generate_minor_routes(
		region_id,
		seed,
		pois,
		fixed_constraints.get("routes", []),
		fixed_constraints.get("terrain_features", [])
	)
	return {
		"schema_version": "1.0.0",
		"proposal_status": "proposal",
		"activation_status": "review_required",
		"id": "proposal_%s_seed_%d" % [region_id, seed],
		"atlas_id": String(atlas.get("atlas_id", "")),
		"atlas_region_id": region_id,
		"seed": seed,
		"template": "atlas_region",
		"generator_version": GENERATOR_VERSION,
		"template_catalog_version": String(generation_templates.get("catalog_version", "")),
		"terrain_palette": generation_templates.get("terrain_templates", {}).duplicate(true),
		"atlas_approval": {
			"status": String(approval.get("status", "")),
			"reviewed_by": String(atlas_review.get("reviewed_by", "")),
			"reviewed_at_utc": String(atlas_review.get("reviewed_at_utc", ""))
		},
		"world_layer": "surface",
		"cell_size_chunks": cell_size_chunks,
		"region_polygon_global_tiles": _pairs(global_polygon),
		"biome_weights": region.get("biome_weights", {}).duplicate(true),
		"terrain_cells": terrain_cells,
		"fixed_constraints": fixed_constraints,
		"minor_routes": minor_routes,
		"pois": pois,
		"review": {
			"canon_status": "proposal",
			"atlas_approval_verified": true,
			"required_artifacts": ["overview_screenshot", "validation_report"]
		}
	}


static func load_templates(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func _generate_terrain_cells(
	region: Dictionary,
	region_id: String,
	seed: int,
	polygon: PackedVector2Array,
	cell_size_chunks: int,
	generation_templates: Dictionary,
	fixed_constraints: Dictionary
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var cell_tiles := cell_size_chunks * CHUNK_SIZE_TILES
	var bounds := _polygon_bounds(polygon)
	var start_x := floori(float(bounds.position.x) / cell_tiles) * cell_tiles
	var start_y := floori(float(bounds.position.y) / cell_tiles) * cell_tiles
	var end_x := ceili(float(bounds.end.x) / cell_tiles) * cell_tiles
	var end_y := ceili(float(bounds.end.y) / cell_tiles) * cell_tiles
	for tile_y in range(start_y, end_y, cell_tiles):
		for tile_x in range(start_x, end_x, cell_tiles):
			var cell_rect := Rect2i(tile_x, tile_y, cell_tiles, cell_tiles)
			if not _rect_touches_polygon(cell_rect, polygon):
				continue
			var chunk_position := Vector2i(
				floori(float(tile_x) / CHUNK_SIZE_TILES),
				floori(float(tile_y) / CHUNK_SIZE_TILES)
			)
			var center := Vector2(cell_rect.position) + Vector2(cell_rect.size) * 0.5
			var key := "%s:%d:%d:%d" % [region_id, seed, chunk_position.x, chunk_position.y]
			var biome_weights := _contextual_biome_weights(
				region, region_id, center, fixed_constraints
			)
			var macro := _value_noise(region_id, seed, chunk_position, 48, "macro")
			var local := _value_noise(region_id, seed, chunk_position, 14, "local")
			var biome := _weighted_biome(biome_weights, macro * 0.92 + local * 0.08)
			var surface_noise := _value_noise(region_id, seed, chunk_position, 22, "surface")
			var terrain_template := _terrain_template_for_biome_unit(
				generation_templates, biome, surface_noise
			)
			var terrain_definition: Dictionary = generation_templates.get(
				"terrain_templates", {}
			).get(terrain_template, {})
			var context := _terrain_context(center, fixed_constraints)
			result.append(
				{
					"id": "terrain_cell_%s_%s_%s" % [region_id, _signed_id(chunk_position.x), _signed_id(chunk_position.y)],
					"atlas_region_id": region_id,
					"seed": seed,
					"template": terrain_template,
					"generator_version": GENERATOR_VERSION,
					"chunk_rect": {"position": [chunk_position.x, chunk_position.y], "size": [cell_size_chunks, cell_size_chunks]},
					"biome": biome,
					"generation_context": context,
					"recommended_default_kind": String(
						terrain_definition.get("tile_kind", _terrain_kind_for_biome(biome))
					),
					"editable": true
				}
			)
	return result


static func _fixed_constraints(
	atlas: Dictionary, region_id: String, region_polygon: PackedVector2Array
) -> Dictionary:
	var result := {"terrain_features": [], "routes": [], "settlements": [], "landmarks": []}
	for feature in atlas.get("terrain_features", []):
		if _entry_touches_polygon(atlas, feature, region_polygon):
			result["terrain_features"].append(_global_constraint(atlas, feature))
	for route in atlas.get("routes", []):
		if _entry_touches_polygon(atlas, route, region_polygon):
			result["routes"].append(_global_constraint(atlas, route))
	for settlement in atlas.get("settlements", []):
		if String(settlement.get("region_id", "")) == region_id:
			result["settlements"].append(_global_constraint(atlas, settlement))
	for landmark in atlas.get("landmarks", []):
		if _entry_touches_polygon(atlas, landmark, region_polygon):
			result["landmarks"].append(_global_constraint(atlas, landmark))
	return result


static func _global_constraint(atlas: Dictionary, source: Dictionary) -> Dictionary:
	var result := {
		"source_atlas_id": String(source.get("id", "")),
		"name": String(source.get("name", "")),
		"kind": String(source.get("kind", source.get("type", ""))),
		"preserve": true
	}
	for geometry_key in ["anchor", "path", "polygon"]:
		if not source.has(geometry_key):
			continue
		if geometry_key == "anchor":
			var tile := WorldAtlasValidator.atlas_to_global_tile(atlas, _point(source[geometry_key]))
			result["global_tile"] = [tile.x, tile.y]
		else:
			result["global_%s" % geometry_key] = _pairs(_global_points(atlas, source[geometry_key]))
	return result


static func _generate_pois(
	region_id: String,
	seed: int,
	terrain_cells: Array[Dictionary],
	region_polygon: PackedVector2Array,
	requested_count: int,
	generation_templates: Dictionary,
	fixed_constraints: Dictionary
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var occupied := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed) * 104729 + _mixed_hash(region_id)
	if terrain_cells.is_empty():
		return result
	var eligible_cells: Array[Dictionary] = []
	for cell in terrain_cells:
		var rect: Dictionary = cell.get("chunk_rect", {})
		var origin := Vector2(rect.get("position", [0, 0])[0], rect.get("position", [0, 0])[1])
		var size := Vector2(rect.get("size", [0, 0])[0], rect.get("size", [0, 0])[1])
		var center := (origin + size * 0.5) * CHUNK_SIZE_TILES
		if Geometry2D.is_point_in_polygon(center, region_polygon):
			eligible_cells.append(cell)
	if eligible_cells.is_empty():
		return result
	var protected_points := PackedVector2Array()
	for collection_name in ["settlements", "landmarks"]:
		for entry in fixed_constraints.get(collection_name, []):
			if entry.has("global_tile"):
				protected_points.append(_point(entry["global_tile"]))
	for required_poi in _required_hinterland_pois(
		region_id, seed, eligible_cells, region_polygon, generation_templates, fixed_constraints
	):
		result.append(required_poi)
		occupied.append(_point(required_poi["global_tile"]))
	for poi_index in clampi(requested_count * 8, 0, eligible_cells.size() * 2):
		if result.size() >= requested_count:
			break
		var cell_index := rng.randi_range(0, eligible_cells.size() - 1)
		var cell: Dictionary = eligible_cells[cell_index]
		var chunk_rect: Dictionary = cell["chunk_rect"]
		var cell_origin := Vector2i(chunk_rect["position"][0], chunk_rect["position"][1]) * CHUNK_SIZE_TILES
		var cell_size_tiles := Vector2i(chunk_rect["size"][0], chunk_rect["size"][1]) * CHUNK_SIZE_TILES
		var jitter := Vector2(rng.randf(), rng.randf())
		var tile := cell_origin + Vector2i(
			maxi(1, floori(jitter.x * float(cell_size_tiles.x - 2))),
			maxi(1, floori(jitter.y * float(cell_size_tiles.y - 2)))
		)
		if not Geometry2D.is_point_in_polygon(Vector2(tile), region_polygon):
			tile = cell_origin + cell_size_tiles / 2
		if not Geometry2D.is_point_in_polygon(Vector2(tile), region_polygon):
			continue
		if _within_distance(Vector2(tile), protected_points, 384.0):
			continue
		if _within_distance(Vector2(tile), occupied, 96.0):
			continue
		var road_distance := _nearest_path_distance(
			Vector2(tile), fixed_constraints.get("routes", []), "global_path"
		)
		var water_distance := _nearest_water_distance(
			Vector2(tile), fixed_constraints.get("terrain_features", [])
		)
		var settlement_distance := _nearest_anchor_distance(
			Vector2(tile), fixed_constraints.get("settlements", [])
		)
		if water_distance < 36.0:
			continue
		var distribution_slot := result.size() % 20
		var placement_reason := "terrain_affinity"
		if distribution_slot < 7:
			placement_reason = "roadside_support"
			if road_distance < 80.0 or road_distance > 520.0:
				continue
		elif distribution_slot < 11:
			placement_reason = "river_edge"
			if water_distance < 48.0 or water_distance > 320.0:
				continue
		elif distribution_slot < 15:
			placement_reason = "settlement_hinterland"
			if settlement_distance < 384.0 or settlement_distance > 1500.0:
				continue
		else:
			if road_distance < 420.0 or water_distance < 260.0 or settlement_distance < 1000.0:
				continue
		occupied.append(Vector2(tile))
		var templates_by_biome: Dictionary = generation_templates.get(
			"poi_templates_by_biome", {}
		)
		var templates: Array = templates_by_biome.get(
			String(cell.get("biome", "")), templates_by_biome.get("fallback", ["road_camp"])
		)
		if placement_reason == "roadside_support":
			templates = generation_templates.get("poi_templates_by_context", {}).get(
				"roadside", templates
			)
		elif placement_reason == "river_edge":
			templates = generation_templates.get("poi_templates_by_context", {}).get(
				"riverside", templates
			)
		elif placement_reason == "settlement_hinterland":
			templates = generation_templates.get("poi_templates_by_context", {}).get(
				"settlement_hinterland", templates
			)
		elif String(cell.get("biome", "")) == "farmland":
			placement_reason = "agricultural_cluster"
		var template_id := String(templates[rng.randi_range(0, templates.size() - 1)])
		var poi_definition: Dictionary = generation_templates.get("poi_templates", {}).get(
			template_id, {}
		)
		var poi_id := "poi_%s_%s_%03d" % [region_id, template_id, poi_index]
		result.append(
			{
				"id": poi_id,
				"atlas_region_id": region_id,
				"seed": seed,
				"template": template_id,
				"generator_version": GENERATOR_VERSION,
				"global_tile": [tile.x, tile.y],
				"placement_context": {
					"reason": placement_reason,
					"terrain_cell_id": String(cell.get("id", "")),
					"biome": String(cell.get("biome", "")),
					"distance_to_fixed_route_tiles": _distance_value(road_distance),
					"distance_to_water_tiles": _distance_value(water_distance),
					"distance_to_settlement_tiles": _distance_value(settlement_distance)
				},
				"walkability": {"required": true, "approach_radius_tiles": 2},
				"slots": poi_definition.get(
					"slots", {"interaction": 1, "service": 0, "loot": 1, "quest_hooks": 1}
				).duplicate(true),
				"visual_style": String(poi_definition.get("visual_style", "region place")),
				"encounter_rules": {
					"status": "proposal",
					"allowed": true,
					"profile": String(poi_definition.get("encounter", "local_pressure"))
				},
				"quest_hooks": [{"id": "hook_%s" % poi_id, "status": "proposal_slot"}],
				"activation_status": "review_required"
			}
		)
	return result


static func _required_hinterland_pois(
	region_id: String,
	seed: int,
	terrain_cells: Array[Dictionary],
	region_polygon: PackedVector2Array,
	templates: Dictionary,
	fixed_constraints: Dictionary
) -> Array[Dictionary]:
	if region_id != "region_marches_velcor":
		return []
	var northgate: Dictionary = {}
	for settlement in fixed_constraints.get("settlements", []):
		if String(settlement.get("source_atlas_id", "")) == "northgate":
			northgate = settlement
			break
	if northgate.is_empty() or not northgate.has("global_tile"):
		return []
	var anchor := Vector2i(_point(northgate["global_tile"]))
	var tile := anchor + Vector2i(112, 88)
	if not Geometry2D.is_point_in_polygon(Vector2(tile), region_polygon):
		return []
	var nearest_cell: Dictionary = {}
	var nearest_distance := INF
	for cell in terrain_cells:
		var rect: Dictionary = cell.get("chunk_rect", {})
		var center := (
			_point(rect.get("position", [0, 0]))
			+ _point(rect.get("size", [0, 0])) * 0.5
		) * CHUNK_SIZE_TILES
		var distance := center.distance_squared_to(Vector2(tile))
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_cell = cell
	var definition: Dictionary = templates.get("poi_templates", {}).get("working_farm", {})
	var site_layout := WorldPoiGenerator.generate(region_id, "farm", seed + 4101, tile)
	var road_distance := _nearest_path_distance(Vector2(tile), fixed_constraints.get("routes", []), "global_path")
	var water_distance := _nearest_water_distance(Vector2(tile), fixed_constraints.get("terrain_features", []))
	return [{
		"id": "poi_northgate_working_farm",
		"atlas_region_id": region_id,
		"seed": seed,
		"template": "working_farm",
		"generator_version": GENERATOR_VERSION,
		"global_tile": [tile.x, tile.y],
		"required_site": true,
		"source_settlement_id": "northgate",
		"site_layout": site_layout,
		"placement_context": {
			"reason": "required_settlement_hinterland",
			"terrain_cell_id": String(nearest_cell.get("id", "")),
			"biome": "farmland",
			"distance_to_fixed_route_tiles": _distance_value(road_distance),
			"distance_to_water_tiles": _distance_value(water_distance),
			"distance_to_settlement_tiles": roundi(Vector2(tile).distance_to(Vector2(anchor)))
		},
		"walkability": {"required": true, "approach_radius_tiles": 2},
		"slots": definition.get("slots", {}).duplicate(true),
		"visual_style": String(definition.get("visual_style", "working farmstead")),
		"encounter_rules": {
			"status": "proposal", "allowed": true,
			"profile": String(definition.get("encounter", "civilian_with_local_pressure"))
		},
		"quest_hooks": [{"id": "hook_poi_northgate_working_farm", "status": "proposal_slot"}],
		"activation_status": "review_required"
	}]


static func _generate_minor_routes(
	region_id: String,
	seed: int,
	pois: Array[Dictionary],
	fixed_routes: Array,
	fixed_features: Array
) -> Array[Dictionary]:
	var route_points := PackedVector2Array()
	for fixed_route in fixed_routes:
		for pair in fixed_route.get("global_path", []):
			route_points.append(_point(pair))
	if route_points.is_empty():
		return []
	var result: Array[Dictionary] = []
	for poi in pois:
		if String(poi.get("template", "")) not in [
			"road_camp", "wayside_shrine", "working_farm", "field_shrine",
			"coppice_camp", "woodland_shrine"
		]:
			continue
		var route_distance := int(
			poi.get("placement_context", {}).get("distance_to_fixed_route_tiles", -1)
		)
		if route_distance < 0 or route_distance > 700:
			continue
		var poi_point := _point(poi["global_tile"])
		var nearest := _nearest_point_on_paths(poi_point, fixed_routes, "global_path")
		var midpoint := (nearest + poi_point) * 0.5
		var perpendicular := (poi_point - nearest).normalized().orthogonal()
		var bend := (_stable_unit("%s:%d:%s:bend" % [region_id, seed, poi["id"]]) - 0.5) * 96.0
		midpoint += perpendicular * bend
		if _segment_crosses_water(nearest, midpoint, fixed_features) or _segment_crosses_water(midpoint, poi_point, fixed_features):
			continue
		var route_index := result.size()
		result.append(
			{
				"id": "minor_route_%s_%03d" % [region_id, route_index],
				"atlas_region_id": region_id,
				"seed": seed,
				"template": "minor_road_connector",
				"generator_version": GENERATOR_VERSION,
				"kind": "minor_road",
				"path": [
					[roundi(nearest.x), roundi(nearest.y)],
					[roundi(midpoint.x), roundi(midpoint.y)],
					poi["global_tile"]
				],
				"connects_poi_id": String(poi["id"]),
				"activation_status": "review_required"
			}
		)
	return result


static func _within_distance(
	point: Vector2, others: PackedVector2Array, minimum_distance: float
) -> bool:
	for other in others:
		if point.distance_squared_to(other) < minimum_distance * minimum_distance:
			return true
	return false


static func _point_near_water(point: Vector2, features: Array, distance: float) -> bool:
	for feature in features:
		if String(feature.get("kind", "")) not in ["river", "lake", "water_body"]:
			continue
		var geometry: Array = feature.get(
			"global_path", feature.get("global_polygon", [])
		)
		for index in range(geometry.size() - 1):
			var nearest := Geometry2D.get_closest_point_to_segment(
				point, _point(geometry[index]), _point(geometry[index + 1])
			)
			if point.distance_to(nearest) < distance:
				return true
	return false


static func _nearest_water_distance(point: Vector2, features: Array) -> float:
	var nearest := INF
	for feature in features:
		if String(feature.get("kind", "")) not in ["river", "lake", "water_body"]:
			continue
		var geometry: Array = feature.get("global_path", feature.get("global_polygon", []))
		for index in range(geometry.size() - 1):
			nearest = minf(nearest, point.distance_to(Geometry2D.get_closest_point_to_segment(
				point, _point(geometry[index]), _point(geometry[index + 1])
			)))
	return nearest


static func _nearest_path_distance(point: Vector2, entries: Array, path_key: String) -> float:
	var nearest := INF
	for entry in entries:
		var path: Array = entry.get(path_key, [])
		for index in range(path.size() - 1):
			nearest = minf(nearest, point.distance_to(Geometry2D.get_closest_point_to_segment(
				point, _point(path[index]), _point(path[index + 1])
			)))
	return nearest


static func _nearest_anchor_distance(point: Vector2, entries: Array) -> float:
	var nearest := INF
	for entry in entries:
		if entry.has("global_tile"):
			nearest = minf(nearest, point.distance_to(_point(entry["global_tile"])))
	return nearest


static func _nearest_point_on_paths(point: Vector2, entries: Array, path_key: String) -> Vector2:
	var nearest := point
	var nearest_distance := INF
	for entry in entries:
		var path: Array = entry.get(path_key, [])
		for index in range(path.size() - 1):
			var candidate := Geometry2D.get_closest_point_to_segment(
				point, _point(path[index]), _point(path[index + 1])
			)
			var distance := point.distance_squared_to(candidate)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = candidate
	return nearest


static func _segment_crosses_water(start: Vector2, end: Vector2, features: Array) -> bool:
	for feature in features:
		if String(feature.get("kind", "")) not in ["river", "lake", "water_body"]:
			continue
		var geometry: Array = feature.get(
			"global_path", feature.get("global_polygon", [])
		)
		for index in range(geometry.size() - 1):
			if Geometry2D.segment_intersects_segment(
				start, end, _point(geometry[index]), _point(geometry[index + 1])
			) != null:
				return true
	return false


static func _entry_touches_polygon(
	atlas: Dictionary, entry: Dictionary, region_polygon: PackedVector2Array
) -> bool:
	if entry.has("anchor"):
		var anchor := WorldAtlasValidator.atlas_to_global_tile(atlas, _point(entry["anchor"]))
		return Geometry2D.is_point_in_polygon(Vector2(anchor), region_polygon)
	for geometry_key in ["path", "polygon"]:
		if not entry.has(geometry_key):
			continue
		var points := _global_points(atlas, entry[geometry_key])
		for point in points:
			if Geometry2D.is_point_in_polygon(point, region_polygon):
				return true
		for region_point in region_polygon:
			if geometry_key == "polygon" and Geometry2D.is_point_in_polygon(region_point, points):
				return true
		for point_index in range(points.size() - 1):
			for region_index in region_polygon.size():
				if Geometry2D.segment_intersects_segment(
					points[point_index], points[point_index + 1],
					region_polygon[region_index], region_polygon[(region_index + 1) % region_polygon.size()]
				) != null:
					return true
	return false


static func _weighted_biome(weights: Dictionary, unit_value: float) -> String:
	var keys := PackedStringArray()
	for key in weights:
		keys.append(String(key))
	keys.sort()
	var cumulative := 0.0
	for key in keys:
		cumulative += float(weights[key])
		if unit_value <= cumulative:
			return key
	return String(keys[-1]) if not keys.is_empty() else "grassland"


static func _value_noise(
	region_id: String, seed: int, position: Vector2i, spacing: int, layer: String
) -> float:
	var lattice := Vector2(floor(float(position.x) / spacing), floor(float(position.y) / spacing))
	var fraction := Vector2(
		fposmod(float(position.x), float(spacing)) / float(spacing),
		fposmod(float(position.y), float(spacing)) / float(spacing)
	)
	fraction = Vector2(
		fraction.x * fraction.x * (3.0 - 2.0 * fraction.x),
		fraction.y * fraction.y * (3.0 - 2.0 * fraction.y)
	)
	var x := int(lattice.x)
	var y := int(lattice.y)
	var a := _stable_unit("%s:%d:%s:%d:%d" % [region_id, seed, layer, x, y])
	var b := _stable_unit("%s:%d:%s:%d:%d" % [region_id, seed, layer, x + 1, y])
	var c := _stable_unit("%s:%d:%s:%d:%d" % [region_id, seed, layer, x, y + 1])
	var d := _stable_unit("%s:%d:%s:%d:%d" % [region_id, seed, layer, x + 1, y + 1])
	return lerpf(lerpf(a, b, fraction.x), lerpf(c, d, fraction.x), fraction.y)


static func _terrain_context(center: Vector2, constraints: Dictionary) -> Dictionary:
	var settlement_distance := INF
	for settlement in constraints.get("settlements", []):
		if settlement.has("global_tile"):
			settlement_distance = minf(
				settlement_distance, center.distance_to(_point(settlement["global_tile"]))
			)
	var route_distance := _nearest_path_distance(center, constraints.get("routes", []), "global_path")
	var water_distance := _nearest_water_distance(center, constraints.get("terrain_features", []))
	var influence := "open_region"
	if settlement_distance < 1200.0:
		influence = "settlement_hinterland"
	elif route_distance < 480.0:
		influence = "road_corridor"
	elif water_distance < 360.0:
		influence = "river_corridor"
	return {
		"primary_influence": influence,
		"distance_to_settlement_tiles": _distance_value(settlement_distance),
		"distance_to_route_tiles": _distance_value(route_distance),
		"distance_to_water_tiles": _distance_value(water_distance)
	}


static func _distance_value(distance: float) -> int:
	return roundi(distance) if is_finite(distance) else -1


static func _mesh_terrain_with_pois(
	terrain_cells: Array[Dictionary], pois: Array[Dictionary], templates: Dictionary
) -> void:
	var affinities := {
		"working_farm": "farmland", "abandoned_granary": "farmland",
		"coppice_camp": "managed_woodland", "shallow_cave": "managed_woodland"
	}
	for poi in pois:
		var template_id := String(poi.get("template", ""))
		if not affinities.has(template_id):
			continue
		var poi_point := _point(poi["global_tile"])
		var influence_radius := 160.0
		if template_id in ["working_farm", "abandoned_granary"]:
			influence_radius = 280.0
		for cell in terrain_cells:
			var rect: Dictionary = cell.get("chunk_rect", {})
			var position := _point(rect.get("position", [0, 0])) * CHUNK_SIZE_TILES
			var size := _point(rect.get("size", [0, 0])) * CHUNK_SIZE_TILES
			if poi_point.distance_to(position + size * 0.5) > influence_radius:
				continue
			var biome: String = affinities[template_id]
			cell["biome"] = biome
			cell["template"] = _terrain_template_for_biome(
				templates, biome, "%s:%s" % [cell.get("id", ""), poi.get("id", "")]
			)
			var definition: Dictionary = templates.get("terrain_templates", {}).get(
				cell["template"], {}
			)
			cell["recommended_default_kind"] = String(
				definition.get("tile_kind", _terrain_kind_for_biome(biome))
			)
			cell["generation_context"]["meshed_to_poi_id"] = String(poi.get("id", ""))


static func _contextual_biome_weights(
	region: Dictionary,
	region_id: String,
	center: Vector2,
	fixed_constraints: Dictionary
) -> Dictionary:
	var authored: Dictionary = region.get("biome_weights", {})
	if region_id != "region_marches_velcor":
		return authored
	authored = {"grassland": 0.54, "farmland": 0.34, "managed_woodland": 0.12}
	for settlement in fixed_constraints.get("settlements", []):
		if settlement.has("global_tile") and center.distance_to(_point(settlement["global_tile"])) < 1200.0:
			return {
				"farmland": 0.57,
				"grassland": 0.35,
				"managed_woodland": 0.08
			}
	if _point_near_paths(center, fixed_constraints.get("routes", []), "global_path", 480.0):
		return {
			"grassland": 0.52,
			"farmland": 0.39,
			"managed_woodland": 0.09
		}
	if _point_near_paths(
		center, fixed_constraints.get("terrain_features", []), "global_path", 360.0
	):
		return {
			"grassland": 0.53,
			"farmland": 0.29,
			"managed_woodland": 0.18
		}
	return authored


static func _point_near_paths(
	point: Vector2, entries: Array, path_key: String, distance: float
) -> bool:
	for entry in entries:
		var path: Array = entry.get(path_key, [])
		for index in range(path.size() - 1):
			var nearest := Geometry2D.get_closest_point_to_segment(
				point, _point(path[index]), _point(path[index + 1])
			)
			if point.distance_to(nearest) < distance:
				return true
	return false


static func _terrain_template_for_biome(
	templates: Dictionary, biome: String, key: String
) -> String:
	var by_biome: Dictionary = templates.get("terrain_templates_by_biome", {})
	var candidates: Array = by_biome.get(biome, by_biome.get("fallback", []))
	if candidates.is_empty():
		return ""
	return String(candidates[_stable_index(key, candidates.size())])


static func _terrain_template_for_biome_unit(
	templates: Dictionary, biome: String, unit_value: float
) -> String:
	var by_biome: Dictionary = templates.get("terrain_templates_by_biome", {})
	var candidates: Array = by_biome.get(biome, by_biome.get("fallback", []))
	if candidates.is_empty():
		return ""
	return String(candidates[mini(floori(unit_value * candidates.size()), candidates.size() - 1)])


static func _terrain_kind_for_biome(biome: String) -> String:
	var value := biome.to_lower()
	if "forest" in value or "woodland" in value:
		return "forest"
	if "mountain" in value or "hill" in value or "cliff" in value or "highland" in value:
		return "hill"
	if "water" in value:
		return "water"
	return "grass"


static func _global_points(atlas: Dictionary, raw_points: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for raw_point in raw_points:
		result.append(Vector2(WorldAtlasValidator.atlas_to_global_tile(atlas, _point(raw_point))))
	return result


static func _pairs(points: PackedVector2Array) -> Array:
	var result := []
	for point in points:
		result.append([roundi(point.x), roundi(point.y)])
	return result


static func _polygon_bounds(points: PackedVector2Array) -> Rect2i:
	var minimum := Vector2i(roundi(points[0].x), roundi(points[0].y))
	var maximum := minimum
	for point in points:
		minimum.x = mini(minimum.x, floori(point.x))
		minimum.y = mini(minimum.y, floori(point.y))
		maximum.x = maxi(maximum.x, ceili(point.x))
		maximum.y = maxi(maximum.y, ceili(point.y))
	return Rect2i(minimum, maximum - minimum + Vector2i.ONE)


static func _rect_touches_polygon(rect: Rect2i, polygon: PackedVector2Array) -> bool:
	var center := Vector2(rect.position) + Vector2(rect.size) * 0.5
	if Geometry2D.is_point_in_polygon(center, polygon):
		return true
	var corners := PackedVector2Array([
		Vector2(rect.position), Vector2(rect.end.x, rect.position.y),
		Vector2(rect.end), Vector2(rect.position.x, rect.end.y)
	])
	for corner in corners:
		if Geometry2D.is_point_in_polygon(corner, polygon):
			return true
	for point in polygon:
		if rect.has_point(Vector2i(roundi(point.x), roundi(point.y))):
			return true
	return false


static func _entry_by_id(entries: Array, entry_id: String) -> Dictionary:
	for entry in entries:
		if String(entry.get("id", "")) == entry_id:
			return entry
	return {}


static func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


static func _signed_id(value: int) -> String:
	return "m%d" % absi(value) if value < 0 else "p%d" % value


static func _stable_index(key: String, size: int) -> int:
	return posmod(_mixed_hash(key), size) if size > 0 else 0


static func _stable_unit(key: String) -> float:
	return float(posmod(_mixed_hash(key), 1000003)) / 1000002.0


static func _mixed_hash(key: String) -> int:
	var value: int = key.hash()
	value = (value ^ (value >> 16)) * 0x45d9f3b
	value = (value ^ (value >> 16)) * 0x45d9f3b
	return (value ^ (value >> 16)) & 0x7fffffff
