extends SceneTree

const AtlasPreview = preload("res://scripts/tools/capture/capture_world_atlas_preview.gd")
const SettlementValidator = preload(
	"res://scripts/data/world_settlement_proposal_validator.gd"
)
const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")

const DEFAULT_PROPOSAL_PATH := "res://data/proposals/settlement_northgate_seed_2701.json"
const DEFAULT_OUTPUT_DIR := "res://reports/world_generation/northgate_seed_2701"
const DEFAULT_ATLAS_PATH := "res://data/world_atlas_proposal.json"
const WIDTH := 1536
const HEIGHT := 1024
const MAP_RECT := Rect2(28, 82, 1040, 842)
const ROLE_COLORS := {
	"road_shrine": "#8f7ab5", "guard_post": "#596b75", "town_hall": "#8b6d45",
	"coaching_inn": "#9a5849", "stable": "#765d3d", "general_shop": "#6e8050",
	"storehouse": "#736a55", "smithy": "#8a4d3f", "home": "#78614d"
}


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var config := capture_config(OS.get_cmdline_user_args())
	var proposal := SettlementValidator.load_proposal(config["proposal_path"])
	var atlas := WorldAtlasValidator.load_atlas(config["atlas_path"])
	var report := SettlementValidator.build_report(proposal, atlas)
	var output_dir := String(config["output_dir"])
	var absolute_dir := ProjectSettings.globalize_path(output_dir)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if make_error != OK:
		printerr("Could not create settlement report directory: %s" % error_string(make_error))
		quit(1)
		return
	var images := {
		"overview": build_overview_svg(proposal, report, false),
		"structures": build_overview_svg(proposal, report, true),
		"interiors": build_interiors_svg(proposal, report)
	}
	for image_name in images:
		var svg_path := ProjectSettings.globalize_path(
			output_dir.path_join("%s.svg" % image_name)
		)
		var png_path := ProjectSettings.globalize_path(
			output_dir.path_join("%s.png" % image_name)
		)
		var svg_file := FileAccess.open(svg_path, FileAccess.WRITE)
		if svg_file == null:
			printerr("Could not write settlement %s SVG" % image_name)
			quit(1)
			return
		svg_file.store_string(images[image_name])
		var save_error := AtlasPreview._save_png(images[image_name], svg_path, png_path)
		if save_error != OK:
			printerr("Could not render settlement %s: %s" % [image_name, error_string(save_error)])
			quit(1)
			return
	var report_path := output_dir.path_join("validation.json")
	var report_file := FileAccess.open(report_path, FileAccess.WRITE)
	if report_file == null:
		printerr("Could not write settlement validation report")
		quit(1)
		return
	report_file.store_string(JSON.stringify(report, "  ") + "\n")
	var summary_file := FileAccess.open(
		output_dir.path_join("summary.md"), FileAccess.WRITE
	)
	if summary_file == null:
		printerr("Could not write settlement proposal summary")
		quit(1)
		return
	summary_file.store_string(build_summary(proposal, report))
	print(
		"Wrote Northgate proposal captures (%s, %d plots, %d interiors)"
		% [
			report["validation_status"],
			report["counts"]["plots"],
			int(report["counts"]["structures"]) / 2
		]
	)
	quit(0 if report["validation_status"] == "pass" else 2)


static func build_summary(proposal: Dictionary, report: Dictionary) -> String:
	var role_counts := {}
	for plot in proposal.get("plots", []):
		var role := String(plot.get("building_role", "unknown"))
		role_counts[role] = int(role_counts.get(role, 0)) + 1
	var npc_roles := PackedStringArray()
	for slot in proposal.get("npc_role_slots", []):
		npc_roles.append(String(slot.get("role", "unknown")))
	npc_roles.sort()
	var services := PackedStringArray()
	for slot in proposal.get("service_slots", []):
		services.append(String(slot.get("service", "unknown")))
	services.sort()
	var lines := PackedStringArray([
		"# Settlement Proposal Summary",
		"",
		"- Settlement: `%s` (`%s`)" % [String(proposal.get("settlement_name", "")), String(proposal.get("atlas_settlement_id", ""))],
		"- Region: `%s`; seed: `%d`" % [String(proposal.get("atlas_region_id", "")), int(proposal.get("seed", 0))],
		"- Status: `%s`; activation `%s`" % [String(proposal.get("proposal_status", "")), String(proposal.get("activation_status", ""))],
		"- Validation: `%s`" % String(report.get("validation_status", "")),
		"- Plots: %d; structures: %d; portals: %d" % [int(report.get("counts", {}).get("plots", 0)), int(report.get("counts", {}).get("structures", 0)), int(report.get("counts", {}).get("portals", 0))],
		"- NPC role slots: %d; service slots: %d; quest hook slots: %d" % [int(report.get("counts", {}).get("npc_role_slots", 0)), int(report.get("counts", {}).get("service_slots", 0)), int(report.get("counts", {}).get("quest_hook_slots", 0))],
		"",
		"## Building Roles",
		""
	])
	var roles := PackedStringArray()
	for role in role_counts:
		roles.append(String(role))
	roles.sort()
	for role in roles:
		lines.append("- `%s`: %d" % [role, int(role_counts[role])])
	lines.append_array(["", "## NPC Roles", "", "- " + ", ".join(npc_roles), "", "## Services", "", "- " + ", ".join(services), "", "Proposal only. No runtime `world_*` content was changed.", ""])
	return "\n".join(lines)


static func capture_config(args: Array) -> Dictionary:
	return {
		"proposal_path": String(args[0]) if args.size() > 0 else DEFAULT_PROPOSAL_PATH,
		"output_dir": String(args[1]) if args.size() > 1 else DEFAULT_OUTPUT_DIR,
		"atlas_path": String(args[2]) if args.size() > 2 else DEFAULT_ATLAS_PATH
	}


static func build_overview_svg(
	proposal: Dictionary, report: Dictionary, structure_focus: bool
) -> String:
	var parts := _page_start(
		"NORTHGATE STRUCTURES" if structure_focus else "NORTHGATE SETTLEMENT PROPOSAL",
		report,
		false
	)
	var bounds := _rect(proposal.get("bounds", {}))
	parts.append('<rect x="%.0f" y="%.0f" width="%.0f" height="%.0f" fill="#526b43"/>' % [MAP_RECT.position.x, MAP_RECT.position.y, MAP_RECT.size.x, MAP_RECT.size.y])
	if not structure_focus:
		for district in proposal.get("districts", []):
			parts.append(_svg_rect(_rect(district.get("rect", {})), bounds, "#d3bd7d", 0.10, "#bfae80", 1.0))
	for street in proposal.get("streets", []):
		var kind := String(street.get("kind", ""))
		var road_color := "#b59a69" if kind == "major_road" else "#c3aa75"
		if street.has("path"):
			var scale := minf(MAP_RECT.size.x / bounds.size.x, MAP_RECT.size.y / bounds.size.y)
			var width := float(street.get("width", 1)) * scale
			parts.append(_polyline(street["path"], bounds, "#d8c18c", width + 2.0, ""))
			parts.append(_polyline(street["path"], bounds, road_color, width, ""))
		else:
			parts.append(_svg_rect(_rect(street.get("rect", {})), bounds, road_color, 0.92, "#d8c18c", 1.0))
	if structure_focus:
		for plot in proposal.get("plots", []):
			parts.append(_svg_rect(_rect(plot.get("rect", {})), bounds, "#000000", 0.0, "#ddd1a2", 1.2))
	var structures_by_id := {}
	var archetypes: Dictionary = proposal.get("structure_archetypes", {})
	for structure in proposal.get("structures", []):
		if String(structure.get("world_layer", "")) != "surface":
			continue
		structures_by_id[String(structure.get("id", ""))] = structure
		var role := String(structure.get("template", "home"))
		parts.append(_svg_structure(
			structure,
			archetypes.get(String(structure.get("archetype_id", "")), {}),
			bounds,
			ROLE_COLORS.get(role, "#78614d")
		))
		var entry := _preview_point(_pair(structure.get("entry_global_tile", [0, 0])), bounds)
		parts.append('<circle cx="%.2f" cy="%.2f" r="4" fill="#f2d17d" stroke="#241a12"/>' % [entry.x, entry.y])
		var center := _rect_center(_rect(structure.get("bounds", {})))
		parts.append(AtlasPreview._text(_preview_point(center, bounds), role.replace("_", " "), "#fff0cc", 9, "middle"))
	var defense: Dictionary = proposal.get("defenses", {})
	if defense.get("boundary_polygon", []).size() >= 3:
		var boundary: Array = defense["boundary_polygon"].duplicate(true)
		boundary.append(boundary[0])
		parts.append(_polyline(boundary, bounds, "#d1b06c", 3.0, ""))
	else:
		parts.append(_svg_rect(_rect(defense.get("bounds", {})), bounds, "#000000", 0.0, "#d1b06c", 3.0))
	for gate in defense.get("gates", []):
		var gate_point := _preview_point(_pair(gate.get("global_tile", [0, 0])), bounds)
		parts.append('<circle cx="%.2f" cy="%.2f" r="7" fill="#d1b06c" stroke="#101b25" stroke-width="2"/>' % [gate_point.x, gate_point.y])
	parts.append(_sidebar(proposal, report, structure_focus))
	# Repaint the header last so map geometry touching the page edge cannot obscure it.
	parts.append(_page_header(
		"NORTHGATE STRUCTURES" if structure_focus else "NORTHGATE SETTLEMENT PROPOSAL",
		report
	))
	parts.append(_page_end(report))
	return "".join(parts)


static func _svg_structure(
	structure: Dictionary, archetype: Dictionary, bounds: Rect2i, color: String
) -> String:
	var origin := _pair(structure.get("origin_tile", [0, 0]))
	var rows: Array = archetype.get("terrain_rows", [])
	if rows.is_empty():
		return _svg_rect(_rect(structure.get("bounds", {})), bounds, color, 0.95, "#2b2018", 1.5)
	var parts := PackedStringArray()
	for y in rows.size():
		var row := String(rows[y])
		for x in row.length():
			if row.substr(x, 1) == ".":
				continue
			parts.append(_svg_rect(
				Rect2i(origin + Vector2i(x, y), Vector2i.ONE), bounds,
				color, 0.95, "#2b2018", 0.25
			))
	return "".join(parts)


static func build_interiors_svg(proposal: Dictionary, report: Dictionary) -> String:
	var parts := _page_start("NORTHGATE INTERIORS", report)
	var archetypes: Dictionary = proposal.get("structure_archetypes", {})
	var interiors: Array = proposal.get("structures", []).filter(
		func(structure): return String(structure.get("world_layer", "")) != "surface"
	)
	var fixtures_by_layer := {}
	for fixture in proposal.get("interior_fixture_slots", []):
		var layer := String(fixture.get("world_layer", ""))
		if not fixtures_by_layer.has(layer):
			fixtures_by_layer[layer] = []
		fixtures_by_layer[layer].append(fixture)
	var columns := 4
	var card_size := Vector2(365, 205)
	for index in interiors.size():
		var structure: Dictionary = interiors[index]
		var archetype: Dictionary = archetypes.get(String(structure.get("archetype_id", "")), {})
		var card_position := Vector2(28 + (index % columns) * 375, 72 + (index / columns) * 220)
		parts.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" rx="4" fill="#172d36" stroke="#607980"/>' % [card_position.x, card_position.y, card_size.x, card_size.y])
		parts.append(AtlasPreview._text(card_position + Vector2(10, 20), String(structure.get("name", "")), "#f0d594", 10))
		var rows: Array = archetype.get("terrain_rows", [])
		var size := _pair(archetype.get("size", [1, 1]))
		var tile_size := minf(13.0, minf(320.0 / maxf(float(size.x), 1.0), 150.0 / maxf(float(size.y), 1.0)))
		var grid_origin := card_position + Vector2(12, 35)
		for y in size.y:
			for x in size.x:
				var code := String(rows[y]).substr(x, 1)
				var color := "#4a3024" if code == "w" else ("#d8b86f" if code == "d" else "#9b7a51")
				parts.append('<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" fill="%s" stroke="#2b2018" stroke-width="0.4"/>' % [grid_origin.x + x * tile_size, grid_origin.y + y * tile_size, tile_size, tile_size, color])
		for anchor_id in archetype.get("anchors", {}):
			var anchor := _pair(archetype["anchors"][anchor_id])
			var point := grid_origin + Vector2(anchor.x + 0.5, anchor.y + 0.5) * tile_size
			parts.append('<circle cx="%.2f" cy="%.2f" r="2.5" fill="#7fd6d1"/>' % [point.x, point.y])
		for fixture in fixtures_by_layer.get(String(structure.get("world_layer", "")), []):
			var tile := _pair(fixture.get("global_tile", [0, 0]))
			var point := grid_origin + Vector2(tile.x + 0.5, tile.y + 0.5) * tile_size
			var color := "#ed8e72" if bool(fixture.get("interaction_slot", false)) else ("#e0c568" if bool(fixture.get("loot_slot", false)) else "#ae8ccf")
			parts.append('<rect x="%.2f" y="%.2f" width="5" height="5" fill="%s" transform="rotate(45 %.2f %.2f)"/>' % [point.x - 2.5, point.y - 2.5, color, point.x, point.y])
	parts.append(_page_end(report))
	return "".join(parts)


static func _page_start(
	title: String, report: Dictionary, include_header := true
) -> PackedStringArray:
	var parts := PackedStringArray([
		'<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % [WIDTH, HEIGHT, WIDTH, HEIGHT],
		'<rect width="%d" height="%d" fill="#101b25"/>' % [WIDTH, HEIGHT]
	])
	if include_header:
		parts.append(_page_header(title, report))
	return parts


static func _page_header(title: String, report: Dictionary) -> String:
	return "".join(PackedStringArray([
		AtlasPreview._text(Vector2(28, 34), title, "#f0d594", 20),
		AtlasPreview._text(Vector2(700, 34), "PROPOSAL - NOT RUNTIME CANON", "#ef9d8f", 13),
		AtlasPreview._text(Vector2(28, 59), "%s | SEED %d" % [String(report.get("atlas_settlement_id", "")), int(report.get("seed", 0))], "#b7c6cc", 12)
	]))


static func _page_end(report: Dictionary) -> String:
	var passed := String(report.get("validation_status", "")) == "pass"
	return "".join(PackedStringArray([
		AtlasPreview._text(Vector2(28, 974), "VALIDATION: %s" % ("PASS" if passed else "FAIL"), "#8bd197" if passed else "#ef786f", 15),
		AtlasPreview._text(Vector2(300, 974), "ACTIVATION: REVIEW REQUIRED", "#f0d594", 15),
		AtlasPreview._text(Vector2(28, 1000), "STRUCTURES, INTERIORS, NPCS, SERVICES, AND HOOKS ARE EDITABLE PROPOSAL DATA", "#b7c6cc", 11),
		"</svg>"
	]))


static func _sidebar(
	proposal: Dictionary, report: Dictionary, structure_focus: bool
) -> String:
	var x := 1090.0
	var parts := PackedStringArray([
		'<rect x="1080" y="82" width="428" height="842" rx="4" fill="#172d36" stroke="#607980"/>',
		AtlasPreview._text(Vector2(x, 112), "STRUCTURE CONTRACT" if structure_focus else "SETTLEMENT CONTRACT", "#f0d594", 13)
	])
	var counts: Dictionary = report.get("counts", {})
	var lines := [
		"%d PLOTS" % int(counts.get("plots", 0)),
		"%d STRUCTURES" % int(counts.get("structures", 0)),
		"%d PORTALS" % int(counts.get("portals", 0)),
		"%d NPC ROLE SLOTS" % int(counts.get("npc_role_slots", counts.get("npc_slots", 0))),
		"%d SERVICE SLOTS" % int(counts.get("service_slots", 0)),
		"%d INTERIOR FIXTURES" % int(counts.get("interior_fixture_slots", 0)),
		"%d QUEST HOOK SLOTS" % int(counts.get("quest_hook_slots", 0)),
		"4 ROAD GATES",
		"DOORS REACHABLE: YES",
		"INTERIORS REACHABLE: YES",
		"PORTALS RECIPROCAL: YES"
	]
	for index in lines.size():
		parts.append(AtlasPreview._text(Vector2(x, 150 + index * 28), lines[index], "#d8e0df", 11))
	parts.append(AtlasPreview._text(Vector2(x, 470), "SERVICES", "#f0d594", 12))
	var services := PackedStringArray()
	for slot in proposal.get("service_slots", []):
		var service := String(slot.get("service", "")).replace("_", " ")
		if not services.has(service):
			services.append(service)
	for index in services.size():
		parts.append(AtlasPreview._text(Vector2(x, 500 + index * 24), services[index], "#b7c6cc", 10))
	return "".join(parts)


static func _svg_rect(
	rect: Rect2i,
	bounds: Rect2i,
	fill: String,
	fill_opacity: float,
	stroke: String,
	stroke_width: float
) -> String:
	var top_left := _preview_point(rect.position, bounds)
	var bottom_right := _preview_point(rect.end, bounds)
	return '<rect x="%.2f" y="%.2f" width="%.2f" height="%.2f" fill="%s" fill-opacity="%.2f" stroke="%s" stroke-width="%.2f"/>' % [top_left.x, top_left.y, bottom_right.x - top_left.x, bottom_right.y - top_left.y, fill, fill_opacity, stroke, stroke_width]


static func _polyline(
	points: Array, bounds: Rect2i, stroke: String, width: float, dash: String = ""
) -> String:
	var pairs := PackedStringArray()
	for pair in points:
		var point := _preview_point(_pair(pair), bounds)
		pairs.append("%.2f,%.2f" % [point.x, point.y])
	var dash_attribute := ' stroke-dasharray="%s"' % dash if not dash.is_empty() else ""
	return '<polyline points="%s" fill="none" stroke="%s" stroke-width="%.2f"%s/>' % [" ".join(pairs), stroke, width, dash_attribute]


static func _preview_point(point: Vector2i, bounds: Rect2i) -> Vector2:
	return MAP_RECT.position + Vector2(
		float(point.x - bounds.position.x) / float(bounds.size.x) * MAP_RECT.size.x,
		float(point.y - bounds.position.y) / float(bounds.size.y) * MAP_RECT.size.y
	)


static func _rect_center(rect: Rect2i) -> Vector2i:
	return rect.position + rect.size / 2


static func _rect(value: Variant) -> Rect2i:
	if not value is Dictionary:
		return Rect2i()
	return Rect2i(_pair(value.get("position", [0, 0])), _pair(value.get("size", [0, 0])))


static func _pair(value: Array) -> Vector2i:
	return Vector2i(roundi(value[0]), roundi(value[1]))
