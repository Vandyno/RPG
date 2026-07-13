extends SceneTree

const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")

const DEFAULT_ATLAS_PATH := "res://data/world_atlas_proposal.json"
const DEFAULT_OUTPUT_PATH := "res://reports/world_atlas/atlas_preview.png"
const DEFAULT_REPORT_PATH := "res://reports/world_atlas/atlas_validation_report.json"
const WIDTH := 1536
const HEIGHT := 1024
const MAP_RECT := Rect2(28, 82, 1480, 842)

const REGION_COLORS := [
	"#496b45", "#315b47", "#6c6758", "#8a7b46", "#60706b", "#405e4f",
	"#626052", "#6e7076", "#765b3d", "#536875", "#314c59"
]
const ROUTE_COLORS := {
	"major_road": "#f2d17d", "trade_road": "#d9b86b", "ferry": "#75c4dc",
	"canopy_route": "#8fd16a", "cliff_route": "#dfaa70"
}
const BITMAP_FONT := {
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"B": ["11110", "10001", "10001", "11110", "10001", "10001", "11110"],
	"C": ["01111", "10000", "10000", "10000", "10000", "10000", "01111"],
	"D": ["11110", "10001", "10001", "10001", "10001", "10001", "11110"],
	"E": ["11111", "10000", "10000", "11110", "10000", "10000", "11111"],
	"F": ["11111", "10000", "10000", "11110", "10000", "10000", "10000"],
	"G": ["01111", "10000", "10000", "10111", "10001", "10001", "01111"],
	"H": ["10001", "10001", "10001", "11111", "10001", "10001", "10001"],
	"I": ["11111", "00100", "00100", "00100", "00100", "00100", "11111"],
	"J": ["00111", "00010", "00010", "00010", "10010", "10010", "01100"],
	"K": ["10001", "10010", "10100", "11000", "10100", "10010", "10001"],
	"L": ["10000", "10000", "10000", "10000", "10000", "10000", "11111"],
	"M": ["10001", "11011", "10101", "10101", "10001", "10001", "10001"],
	"N": ["10001", "11001", "10101", "10011", "10001", "10001", "10001"],
	"O": ["01110", "10001", "10001", "10001", "10001", "10001", "01110"],
	"P": ["11110", "10001", "10001", "11110", "10000", "10000", "10000"],
	"Q": ["01110", "10001", "10001", "10001", "10101", "10010", "01101"],
	"R": ["11110", "10001", "10001", "11110", "10100", "10010", "10001"],
	"S": ["01111", "10000", "10000", "01110", "00001", "00001", "11110"],
	"T": ["11111", "00100", "00100", "00100", "00100", "00100", "00100"],
	"U": ["10001", "10001", "10001", "10001", "10001", "10001", "01110"],
	"V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
	"W": ["10001", "10001", "10001", "10101", "10101", "10101", "01010"],
	"X": ["10001", "10001", "01010", "00100", "01010", "10001", "10001"],
	"Y": ["10001", "10001", "01010", "00100", "00100", "00100", "00100"],
	"Z": ["11111", "00001", "00010", "00100", "01000", "10000", "11111"],
	"0": ["01110", "10011", "10101", "10101", "11001", "10001", "01110"],
	"1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
	"2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
	"3": ["11110", "00001", "00001", "01110", "00001", "00001", "11110"],
	"4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
	"5": ["11111", "10000", "10000", "11110", "00001", "00001", "11110"],
	"6": ["01110", "10000", "10000", "11110", "10001", "10001", "01110"],
	"7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
	"8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
	"9": ["01110", "10001", "10001", "01111", "00001", "00001", "01110"],
	"-": ["00000", "00000", "00000", "11111", "00000", "00000", "00000"],
	"/": ["00001", "00010", "00010", "00100", "01000", "01000", "10000"],
	":": ["00000", "00100", "00100", "00000", "00100", "00100", "00000"],
	".": ["00000", "00000", "00000", "00000", "00000", "00110", "00110"],
	",": ["00000", "00000", "00000", "00000", "00110", "00100", "01000"],
	"~": ["00000", "00000", "01010", "10101", "00000", "00000", "00000"],
	"_": ["00000", "00000", "00000", "00000", "00000", "00000", "11111"],
	"|": ["00100", "00100", "00100", "00100", "00100", "00100", "00100"],
	"(": ["00010", "00100", "01000", "01000", "01000", "00100", "00010"],
	")": ["01000", "00100", "00010", "00010", "00010", "00100", "01000"],
	"?": ["01110", "10001", "00001", "00010", "00100", "00000", "00100"]
}


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var config := capture_config(OS.get_cmdline_user_args())
	var atlas := WorldAtlasValidator.load_atlas(config["atlas_path"])
	var report := WorldAtlasValidator.build_report(atlas)
	var output_path := String(config["output_path"])
	var report_path := String(config["report_path"])
	for path in [output_path, report_path]:
		var make_error := DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(String(path)).get_base_dir()
		)
		if make_error != OK:
			printerr("Could not create atlas report directory: %s" % error_string(make_error))
			quit(1)
			return
	var svg := build_svg(atlas, report)
	var absolute_output := ProjectSettings.globalize_path(output_path)
	var svg_path := absolute_output.get_basename() + ".svg"
	var svg_file := FileAccess.open(svg_path, FileAccess.WRITE)
	if svg_file == null:
		printerr("Could not write atlas SVG: %s" % error_string(FileAccess.get_open_error()))
		quit(1)
		return
	svg_file.store_string(svg)
	svg_file.close()
	var save_error := _save_png(svg, svg_path, absolute_output)
	if save_error != OK:
		printerr("Could not save atlas preview: %s" % error_string(save_error))
		quit(1)
		return
	var report_file := FileAccess.open(report_path, FileAccess.WRITE)
	if report_file == null:
		printerr("Could not write atlas validation report: %s" % error_string(FileAccess.get_open_error()))
		quit(1)
		return
	report_file.store_string(JSON.stringify(report, "  ") + "\n")
	for warning in report["validation_errors"]:
		printerr(warning)
	print(
		"Wrote atlas preview and report (%s, %d review items)"
		% [report["validation_status"], report["review_items"].size()]
	)
	quit(0 if report["validation_status"] == "pass" else 2)


static func _save_png(svg: String, svg_path: String, png_path: String) -> Error:
	var command_output := []
	var convert_exit := OS.execute(
		"magick", PackedStringArray([svg_path, png_path]), command_output, true
	)
	if convert_exit == 0 and FileAccess.file_exists(png_path):
		return OK
	var image := Image.new()
	var render_error := image.load_svg_from_string(svg, 1.0)
	if render_error != OK:
		return render_error
	return image.save_png(png_path)


static func capture_config(args: Array) -> Dictionary:
	return {
		"atlas_path": String(args[0]) if args.size() > 0 else DEFAULT_ATLAS_PATH,
		"output_path": String(args[1]) if args.size() > 1 else DEFAULT_OUTPUT_PATH,
		"report_path": String(args[2]) if args.size() > 2 else DEFAULT_REPORT_PATH
	}


static func build_svg(atlas: Dictionary, report: Dictionary) -> String:
	var parts := PackedStringArray([
		'<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % [WIDTH, HEIGHT, WIDTH, HEIGHT],
		'<rect width="%d" height="%d" fill="#101b25"/>' % [WIDTH, HEIGHT],
		'<text x="28" y="34" fill="#f0d594" font-family="sans-serif" font-size="22" font-weight="bold">VELCOR WORLD ATLAS</text>',
		'<rect x="%.0f" y="%.0f" width="%.0f" height="%.0f" fill="#172d36" stroke="#8da0a4" stroke-width="1.5"/>' % [MAP_RECT.position.x, MAP_RECT.position.y, MAP_RECT.size.x, MAP_RECT.size.y]
	])
	var bounds := _atlas_bounds(atlas)
	parts.append(_text(Vector2(370, 34), "PROPOSAL - NOT RUNTIME CANON", "#ef9d8f", 15))
	for index in atlas.get("regions", []).size():
		var region: Dictionary = atlas["regions"][index]
		parts.append(
			'<polygon points="%s" fill="%s" fill-opacity="0.78" stroke="#a9bab1" stroke-width="1.5"/>'
			% [_svg_points(region.get("polygon", []), bounds), REGION_COLORS[index % REGION_COLORS.size()]]
		)
		var center := _polygon_center(region.get("polygon", []), bounds)
		parts.append(_text(center + Vector2(0, -6), String(region.get("name", "")), "#d9e2d7", 12, "middle"))
	parts.append(
		'<polygon points="%s" fill="none" stroke="#e8d897" stroke-width="2.4"/>'
		% _svg_points(atlas.get("coastline", []), bounds)
	)
	for exclusion in atlas.get("water_exclusions", []):
		parts.append(
			'<polygon points="%s" fill="#173e55" stroke="#65a8c4" stroke-width="1.5"/>'
			% _svg_points(exclusion.get("polygon", []), bounds)
		)
	for zone in atlas.get("zones", []):
		var stroke := "#bb72c7" if String(zone.get("kind", "")) == "cult_pressure" else "#8fc67c"
		parts.append(
			'<polygon points="%s" fill="none" stroke="%s" stroke-opacity="0.82" stroke-width="1.6" stroke-dasharray="7 5"/>'
			% [_svg_points(zone.get("polygon", []), bounds), stroke]
		)
	for feature in atlas.get("terrain_features", []):
		if feature.has("path"):
			var stroke := "#55add1" if String(feature.get("kind", "")) == "river" else "#adb0ae"
			parts.append(
				'<polyline points="%s" fill="none" stroke="%s" stroke-width="2.5"/>'
				% [_svg_points(feature["path"], bounds), stroke]
			)
	for route in atlas.get("routes", []):
		var kind := String(route.get("kind", ""))
		parts.append(
			'<polyline points="%s" fill="none" stroke="%s" stroke-width="%s"/>'
			% [_svg_points(route.get("path", []), bounds), ROUTE_COLORS.get(kind, "#ffffff"), "2.6" if kind == "major_road" else "1.9"]
		)
	for settlement in atlas.get("settlements", []):
		var point := _preview_point(settlement.get("anchor", [0, 0]), bounds)
		var unresolved := String(settlement.get("review_status", "")) != "aligned"
		parts.append(
			'<circle cx="%.2f" cy="%.2f" r="%s" fill="%s" stroke="#101b25" stroke-width="1"/>'
			% [point.x, point.y, "5" if String(settlement.get("size_band", "")) == "large" else "3.5", "#ef7f73" if unresolved else "#f4e4ad"]
		)
		parts.append(_text(point + Vector2(6, -4), String(settlement.get("name", "")), "#f2ead4", 10))
	for landmark in atlas.get("landmarks", []):
		var point := _preview_point(landmark.get("anchor", [0, 0]), bounds)
		var unresolved := String(landmark.get("review_status", "")) != "aligned"
		parts.append(
			'<path d="M %.2f %.2f l 8 0 M %.2f %.2f l 0 8" stroke="%s" stroke-width="2"/>'
			% [point.x - 4, point.y, point.x, point.y - 4, "#ef7f73" if unresolved else "#d9a8e4"]
		)
	var scale: Dictionary = report.get("world_scale", {})
	parts.append(
		_text(
			Vector2(28, 61),
			"World: 30,720 x 20,480 global tiles | %.1f min baseline crossing | %s tiles per atlas unit"
			% [float(scale.get("baseline_crossing_minutes", 0.0)), str(scale.get("global_tiles_per_atlas_unit", 0))],
			"#b7c6cc", 14
		)
	)
	parts.append(_legend_svg())
	var validation_passed := String(report.get("validation_status", "")) == "pass"
	var review_count: int = report.get("review_items", []).size()
	parts.append(
		_text(Vector2(28, 966), "VALIDATION: %s" % ("PASS" if validation_passed else "FAIL"), "#8bd197" if validation_passed else "#ef786f", 16)
	)
	parts.append(
		_text(Vector2(300, 966), "APPROVAL: PENDING - %d explicit review item(s)" % review_count, "#f0d594", 16)
	)
	parts.append(
		_text(Vector2(28, 994), "Red markers are unresolved image labels or proposal geometry. Generated content remains proposal-only.", "#b7c6cc", 13)
	)
	parts.append("</svg>")
	return "".join(parts)


static func _legend_svg() -> String:
	return "".join(PackedStringArray([
		'<rect x="1190" y="92" width="302" height="122" rx="4" fill="#101b25" fill-opacity="0.9" stroke="#8da0a4"/>',
		_text(Vector2(1204, 114), "LEGEND", "#f0d594", 13),
		'<line x1="1204" y1="132" x2="1240" y2="132" stroke="#f2d17d" stroke-width="2.6"/>',
		_text(Vector2(1248, 136), "Major / trade roads", "#d8e0df", 11),
		'<line x1="1204" y1="151" x2="1240" y2="151" stroke="#75c4dc" stroke-width="2"/>',
		_text(Vector2(1248, 155), "River / ferry", "#d8e0df", 11),
		'<line x1="1204" y1="170" x2="1240" y2="170" stroke="#bb72c7" stroke-width="1.6" stroke-dasharray="7 5"/>',
		_text(Vector2(1248, 174), "Cult pressure zone", "#d8e0df", 11),
		'<circle cx="1210" cy="194" r="4" fill="#ef7f73"/>',
		_text(Vector2(1222, 198), "Needs explicit review", "#d8e0df", 11)
	]))


static func _atlas_bounds(atlas: Dictionary) -> Rect2:
	var value: Dictionary = atlas.get("continent_bounds", {})
	var minimum := _raw_point(value.get("min", [0, 0]))
	var maximum := _raw_point(value.get("max", [1, 1]))
	return Rect2(minimum, maximum - minimum)


static func _svg_points(raw_points: Array, bounds: Rect2) -> String:
	var values := PackedStringArray()
	for raw_point in raw_points:
		var point := _preview_point(raw_point, bounds)
		values.append("%.2f,%.2f" % [point.x, point.y])
	return " ".join(values)


static func _polygon_center(raw_points: Array, bounds: Rect2) -> Vector2:
	if raw_points.is_empty():
		return MAP_RECT.position
	var sum := Vector2.ZERO
	for raw_point in raw_points:
		sum += _preview_point(raw_point, bounds)
	return sum / float(raw_points.size())


static func _preview_point(raw_point: Array, bounds: Rect2) -> Vector2:
	var point := _raw_point(raw_point)
	return MAP_RECT.position + Vector2(
		(point.x - bounds.position.x) / bounds.size.x * MAP_RECT.size.x,
		(point.y - bounds.position.y) / bounds.size.y * MAP_RECT.size.y
	)


static func _raw_point(raw_point: Array) -> Vector2:
	return Vector2(float(raw_point[0]), float(raw_point[1]))


static func _text(
	position: Vector2, value: String, color: String, font_size: int, anchor := "start"
) -> String:
	var label := value.to_upper()
	var pixel_size := maxf(float(font_size) / 7.0, 1.0)
	var advance := pixel_size * 6.0
	var start_x := position.x
	if anchor == "middle":
		start_x -= float(label.length()) * advance * 0.5
	var start_y := position.y - pixel_size * 7.0
	var commands := PackedStringArray()
	for character_index in label.length():
		var character := label.substr(character_index, 1)
		if character == " ":
			continue
		var rows: Array = BITMAP_FONT.get(character, BITMAP_FONT["?"])
		for row_index in rows.size():
			var row := String(rows[row_index])
			for column_index in 5:
				if row.substr(column_index, 1) == "1":
					var x := start_x + float(character_index) * advance + float(column_index) * pixel_size
					var y := start_y + float(row_index) * pixel_size
					commands.append(
						"M %.2f %.2f h %.2f v %.2f h %.2f z"
						% [x, y, pixel_size, pixel_size, -pixel_size]
					)
	return '<path data-label="%s" fill="%s" d="%s"/>' % [
		_xml_escape(value), color, " ".join(commands)
	]


static func _xml_escape(value: String) -> String:
	return (
		value.replace("&", "&amp;")
		.replace("<", "&lt;")
		.replace(">", "&gt;")
		.replace('"', "&quot;")
	)
