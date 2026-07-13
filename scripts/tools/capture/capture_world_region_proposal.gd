extends SceneTree

const AtlasPreview = preload("res://scripts/tools/capture/capture_world_atlas_preview.gd")
const RegionProposalValidator = preload("res://scripts/data/world_region_proposal_validator.gd")

const DEFAULT_PROPOSAL_PATH := "res://data/proposals/region_marches_velcor_seed_1701.json"
const DEFAULT_OUTPUT_PATH := "res://reports/world_generation/region_marches_velcor_seed_1701_overview.png"
const DEFAULT_REPORT_PATH := "res://reports/world_generation/region_marches_velcor_seed_1701_validation.json"
const WIDTH := 1536
const HEIGHT := 1024
const MAP_RECT := Rect2(28, 82, 1480, 842)
const TERRAIN_COLORS := {
	"grass": "#777341", "forest": "#315b47", "hill": "#68685f", "water": "#1c526b",
	"meadow_grass": "#7f8248", "wildflower_down": "#8c8752",
	"red_loam_field": "#8a5b3e", "fallow_field": "#88704b", "orchard_edge": "#48623d",
	"managed_oak_copse": "#35553d", "hedgerow_lane": "#426843",
	"rolling_stone_hill": "#6f7064", "chalk_rise": "#85877a"
}


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var config := capture_config(OS.get_cmdline_user_args())
	var proposal := RegionProposalValidator.load_proposal(config["proposal_path"])
	var report := RegionProposalValidator.build_report(proposal)
	for output_key in ["output_path", "report_path"]:
		var absolute_path := ProjectSettings.globalize_path(String(config[output_key]))
		var make_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
		if make_error != OK:
			printerr("Could not create region proposal report directory: %s" % error_string(make_error))
			quit(1)
			return
	var svg := build_svg(proposal, report)
	var absolute_output := ProjectSettings.globalize_path(String(config["output_path"]))
	var svg_path := absolute_output.get_basename() + ".svg"
	var svg_file := FileAccess.open(svg_path, FileAccess.WRITE)
	if svg_file == null:
		printerr("Could not write region proposal SVG: %s" % error_string(FileAccess.get_open_error()))
		quit(1)
		return
	svg_file.store_string(svg)
	var image := Image.new()
	var render_error := image.load_svg_from_string(svg, 1.0)
	if render_error != OK:
		printerr("Could not render region proposal: %s" % error_string(render_error))
		quit(1)
		return
	var save_error := image.save_png(absolute_output)
	if save_error != OK:
		printerr("Could not save region proposal overview: %s" % error_string(save_error))
		quit(1)
		return
	var report_file := FileAccess.open(String(config["report_path"]), FileAccess.WRITE)
	if report_file == null:
		printerr("Could not write region proposal validation report")
		quit(1)
		return
	report_file.store_string(JSON.stringify(report, "  ") + "\n")
	var summary_file := FileAccess.open(
		String(config["report_path"]).get_base_dir().path_join("region_summary.md"),
		FileAccess.WRITE
	)
	if summary_file == null:
		printerr("Could not write region proposal summary")
		quit(1)
		return
	summary_file.store_string(build_summary(proposal, report))
	print(
		"Wrote region overview and report (%s, %d terrain cells, %d POIs)"
		% [report["validation_status"], report["counts"]["terrain_cells"], report["counts"]["pois"]]
	)
	quit(0 if report["validation_status"] == "pass" else 2)


static func build_summary(proposal: Dictionary, report: Dictionary) -> String:
	var poi_counts := {}
	var hook_count := 0
	for poi in proposal.get("pois", []):
		var template := String(poi.get("template", "unknown"))
		poi_counts[template] = int(poi_counts.get(template, 0)) + 1
		hook_count += poi.get("quest_hooks", []).size()
	var fixed: Dictionary = proposal.get("fixed_constraints", {})
	var lines := PackedStringArray([
		"# Region Proposal Summary",
		"",
		"- Region: `%s`" % String(proposal.get("atlas_region_id", "")),
		"- Seed: `%d`" % int(proposal.get("seed", 0)),
		"- Status: `%s`; activation `%s`" % [String(proposal.get("proposal_status", "")), String(proposal.get("activation_status", ""))],
		"- Validation: `%s`" % String(report.get("validation_status", "")),
		"- Terrain cells: %d" % int(report.get("counts", {}).get("terrain_cells", 0)),
		"- Minor roads: %d" % int(report.get("counts", {}).get("minor_routes", 0)),
		"- Preserved settlements: %d; routes: %d; terrain features: %d" % [fixed.get("settlements", []).size(), fixed.get("routes", []).size(), fixed.get("terrain_features", []).size()],
		"- Quest hook slots: %d" % hook_count,
		"",
		"## Generated POIs",
		""
	])
	var templates := PackedStringArray()
	for template in poi_counts:
		templates.append(String(template))
	templates.sort()
	for template in templates:
		lines.append("- `%s`: %d" % [template, int(poi_counts[template])])
	lines.append_array(["", "Proposal only. No runtime `world_*` content was changed.", ""])
	return "\n".join(lines)


static func capture_config(args: Array) -> Dictionary:
	return {
		"proposal_path": String(args[0]) if args.size() > 0 else DEFAULT_PROPOSAL_PATH,
		"output_path": String(args[1]) if args.size() > 1 else DEFAULT_OUTPUT_PATH,
		"report_path": String(args[2]) if args.size() > 2 else DEFAULT_REPORT_PATH
	}


static func build_svg(proposal: Dictionary, report: Dictionary) -> String:
	var parts := PackedStringArray([
		'<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % [WIDTH, HEIGHT, WIDTH, HEIGHT],
		'<rect width="%d" height="%d" fill="#101b25"/>' % [WIDTH, HEIGHT],
		'<defs><clipPath id="mapClip"><rect x="%.0f" y="%.0f" width="%.0f" height="%.0f"/></clipPath></defs>' % [MAP_RECT.position.x, MAP_RECT.position.y, MAP_RECT.size.x, MAP_RECT.size.y],
		'<rect x="%.0f" y="%.0f" width="%.0f" height="%.0f" fill="#172d36" stroke="#8da0a4" stroke-width="1.5"/>' % [MAP_RECT.position.x, MAP_RECT.position.y, MAP_RECT.size.x, MAP_RECT.size.y]
	])
	parts.append(AtlasPreview._text(Vector2(28, 34), "REGION PROPOSAL", "#f0d594", 22))
	parts.append(AtlasPreview._text(Vector2(350, 34), "NOT RUNTIME CANON", "#ef9d8f", 15))
	parts.append('<g clip-path="url(#mapClip)">')
	var bounds := _proposal_bounds(proposal)
	var region_polygon: Array = proposal.get("region_polygon_global_tiles", [])
	parts.append(
		'<defs><clipPath id="map-clip"><rect x="%.0f" y="%.0f" width="%.0f" height="%.0f"/></clipPath><clipPath id="region-clip"><polygon points="%s"/></clipPath></defs>'
		% [MAP_RECT.position.x, MAP_RECT.position.y, MAP_RECT.size.x, MAP_RECT.size.y, _svg_points(region_polygon, bounds)]
	)
	parts.append('<g clip-path="url(#region-clip)">')
	for cell in proposal.get("terrain_cells", []):
		var chunk_rect: Dictionary = cell.get("chunk_rect", {})
		var tile_position := Vector2(chunk_rect.get("position", [0, 0])[0], chunk_rect.get("position", [0, 0])[1]) * 16.0
		var tile_size := Vector2(chunk_rect.get("size", [0, 0])[0], chunk_rect.get("size", [0, 0])[1]) * 16.0
		var top_left := _preview_point(tile_position, bounds)
		var bottom_right := _preview_point(tile_position + tile_size, bounds)
		parts.append(
			'<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" fill="%s" fill-opacity="0.78"/>'
			% [top_left.x, top_left.y, bottom_right.x - top_left.x, bottom_right.y - top_left.y, TERRAIN_COLORS.get(String(cell.get("recommended_default_kind", "grass")), "#777341")]
		)
	parts.append("</g>")
	parts.append('<g clip-path="url(#map-clip)">')
	parts.append('<polygon points="%s" fill="none" stroke="#e8d897" stroke-width="3"/>' % _svg_points(region_polygon, bounds))
	var fixed: Dictionary = proposal.get("fixed_constraints", {})
	for feature in fixed.get("terrain_features", []):
		var feature_kind := String(feature.get("kind", ""))
		if feature.has("global_path"):
			parts.append('<polyline points="%s" fill="none" stroke="%s" stroke-width="3"/>' % [_svg_points(feature["global_path"], bounds), "#55add1" if feature_kind == "river" else "#adb0ae"])
		elif feature.has("global_polygon"):
			parts.append('<polygon points="%s" fill="#173e55" fill-opacity="0.68" stroke="#65a8c4" stroke-width="2"/>' % _svg_points(feature["global_polygon"], bounds))
	for route in fixed.get("routes", []):
		if route.has("global_path"):
			parts.append('<polyline points="%s" fill="none" stroke="#f2d17d" stroke-width="2.6"/>' % _svg_points(route["global_path"], bounds))
	for route in proposal.get("minor_routes", []):
		parts.append('<polyline points="%s" fill="none" stroke="#d9b86b" stroke-width="1.3" stroke-dasharray="5 3"/>' % _svg_points(route.get("path", []), bounds))
	for settlement in fixed.get("settlements", []):
		var point := _preview_point(_point(settlement.get("global_tile", [0, 0])), bounds)
		parts.append('<circle cx="%.2f" cy="%.2f" r="5" fill="#f4e4ad" stroke="#101b25"/>' % [point.x, point.y])
		parts.append(AtlasPreview._text(point + Vector2(7, -4), String(settlement.get("name", "")), "#f2ead4", 10))
	for poi in proposal.get("pois", []):
		var point := _preview_point(_point(poi.get("global_tile", [0, 0])), bounds)
		parts.append('<rect x="%.2f" y="%.2f" width="6" height="6" fill="#ef9d8f" transform="rotate(45 %.2f %.2f)"/>' % [point.x - 3, point.y - 3, point.x, point.y])
	parts.append("</g>")
	parts.append("</g>")
	parts.append(
		AtlasPreview._text(
			Vector2(28, 61),
			"%s | SEED %d | %d CELLS | %d MINOR ROADS | %d POIS"
			% [String(report.get("atlas_region_id", "")).replace("_", " "), int(report.get("seed", 0)), int(report.get("counts", {}).get("terrain_cells", 0)), int(report.get("counts", {}).get("minor_routes", 0)), int(report.get("counts", {}).get("pois", 0))],
			"#b7c6cc", 14
		)
	)
	var passed := String(report.get("validation_status", "")) == "pass"
	parts.append(AtlasPreview._text(Vector2(28, 966), "VALIDATION: %s" % ("PASS" if passed else "FAIL"), "#8bd197" if passed else "#ef786f", 16))
	parts.append(AtlasPreview._text(Vector2(300, 966), "ACTIVATION: REVIEW REQUIRED", "#f0d594", 16))
	parts.append(AtlasPreview._text(Vector2(28, 994), "TERRAIN CELLS AND GENERATED ENTITIES ARE EDITABLE PROPOSAL DATA", "#b7c6cc", 13))
	parts.append("</svg>")
	return "".join(parts)


static func _proposal_bounds(proposal: Dictionary) -> Rect2:
	var points: Array = proposal.get("region_polygon_global_tiles", [])
	if points.is_empty():
		return Rect2(0, 0, 1, 1)
	var minimum := _point(points[0])
	var maximum := minimum
	for pair in points:
		var point := _point(pair)
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	return Rect2(minimum, maximum - minimum)


static func _preview_point(point: Vector2, bounds: Rect2) -> Vector2:
	return MAP_RECT.position + Vector2(
		(point.x - bounds.position.x) / bounds.size.x * MAP_RECT.size.x,
		(point.y - bounds.position.y) / bounds.size.y * MAP_RECT.size.y
	)


static func _svg_points(raw_points: Array, bounds: Rect2) -> String:
	var result := PackedStringArray()
	for pair in raw_points:
		var point := _preview_point(_point(pair), bounds)
		result.append("%.2f,%.2f" % [point.x, point.y])
	return " ".join(result)


static func _point(pair: Array) -> Vector2:
	return Vector2(float(pair[0]), float(pair[1]))
