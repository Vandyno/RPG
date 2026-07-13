class_name WorldSettlementGenerator
extends RefCounted

const StableHash = preload("res://scripts/core/stable_hash.gd")
const WorldAtlasApprovalGate = preload("res://scripts/data/world_atlas_approval_gate.gd")
const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")

const GENERATOR_VERSION := "world_settlement_v6"
const DEFAULT_REVIEW_PATH := "res://data/world_atlas_review.json"
const DEFAULT_TEMPLATE_PATH := "res://data/settlement_generation_templates.json"


static func generate(
	atlas: Dictionary, settlement_id: String, seed: int, options: Dictionary = {}
) -> Dictionary:
	if not WorldAtlasValidator.validate(atlas).is_empty():
		return {}
	var review: Dictionary = options.get(
		"atlas_review", WorldAtlasApprovalGate.load_review(DEFAULT_REVIEW_PATH)
	)
	var gate := WorldAtlasApprovalGate.evaluate(atlas, review)
	if not bool(gate.get("can_generate", false)):
		return {}
	var catalog: Dictionary = options.get(
		"generation_templates", load_templates(DEFAULT_TEMPLATE_PATH)
	)
	var settlement := _entry_by_id(atlas.get("settlements", []), settlement_id)
	if settlement.is_empty() or catalog.is_empty():
		return {}
	var role := String(settlement.get("role", ""))
	var settlement_template: Dictionary = catalog.get("settlement_roles", {}).get(role, {})
	if settlement_template.is_empty():
		return {}
	var anchor := WorldAtlasValidator.atlas_to_global_tile(
		atlas, _point(settlement.get("anchor", [0, 0]))
	)
	var local_bounds := _rect(settlement_template.get("bounds_local", {}))
	var global_bounds := Rect2i(anchor + local_bounds.position, local_bounds.size)
	var base := {
		"atlas_region_id": String(settlement.get("region_id", "")),
		"atlas_settlement_id": settlement_id,
		"seed": seed,
		"generator_version": GENERATOR_VERSION
	}
	var streets := _offset_rect_entries(
		settlement_template.get("streets", []), anchor, base, "street"
	)
	var districts := _offset_rect_entries(
		settlement_template.get("districts", []), anchor, base, "district"
	)
	var building_profiles: Dictionary = catalog.get("building_profiles", {})
	var bundle := _generate_plots_and_buildings(
		settlement_template.get("plots", []),
		building_profiles,
		anchor,
		streets,
		base,
		seed
	)
	_append_building_paths(streets, bundle["structures"], base)
	var defenses := _generate_defenses(
		settlement_template.get("defense", {}), global_bounds, anchor, streets, base
	)
	return {
		"schema_version": "1.0.0",
		"proposal_status": "proposal",
		"activation_status": "review_required",
		"id": "proposal_%s_seed_%d" % [settlement_id, seed],
		"atlas_id": String(atlas.get("atlas_id", "")),
		"atlas_region_id": String(settlement.get("region_id", "")),
		"atlas_settlement_id": settlement_id,
		"settlement_name": String(settlement.get("name", "")),
		"settlement_role": role,
		"seed": seed,
		"template": String(settlement_template.get("template_id", "")),
		"template_catalog_version": String(catalog.get("catalog_version", "")),
		"generator_version": GENERATOR_VERSION,
		"atlas_approval": {
			"status": String(gate.get("status", "")),
			"reviewed_by": String(review.get("reviewed_by", "")),
			"reviewed_at_utc": String(review.get("reviewed_at_utc", ""))
		},
		"world_layer": "surface",
		"anchor_global_tile": [anchor.x, anchor.y],
		"bounds": _rect_data(global_bounds),
		"districts": districts,
		"streets": streets,
		"public_spaces": streets.filter(
			func(entry): return String(entry.get("kind", "")) == "public_square"
		),
		"defenses": defenses,
		"plots": bundle["plots"],
		"structure_archetypes": bundle["structure_archetypes"],
		"structures": bundle["structures"],
		"portals": bundle["portals"],
		"npc_role_slots": bundle["npc_role_slots"],
		"service_slots": bundle["service_slots"],
		"interior_fixture_slots": bundle["interior_fixture_slots"],
		"quest_hook_slots": bundle["quest_hook_slots"],
		"encounter_zones": _encounter_zones(global_bounds, streets, base),
		"review": {
			"canon_status": "proposal",
			"atlas_approval_verified": true,
			"required_artifacts": [
				"overview_screenshot",
				"structure_screenshot",
				"interior_screenshot",
				"validation_report"
			]
		}
	}


static func load_templates(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func _generate_plots_and_buildings(
	plot_templates: Array,
	profiles: Dictionary,
	anchor: Vector2i,
	streets: Array[Dictionary],
	base: Dictionary,
	seed: int
) -> Dictionary:
	var plots: Array[Dictionary] = []
	var archetypes: Dictionary = {}
	var structures: Array[Dictionary] = []
	var portals: Array[Dictionary] = []
	var npc_slots: Array[Dictionary] = []
	var service_slots: Array[Dictionary] = []
	var fixture_slots: Array[Dictionary] = []
	var quest_slots: Array[Dictionary] = []
	var footprints := {}
	for source in plot_templates:
		var source_plot := _rect(source.get("rect", {}))
		var source_global := Rect2i(anchor + source_plot.position, source_plot.size)
		var footprint := Rect2i(
			source_global.position + Vector2i(2, 2), source_global.size - Vector2i(4, 4)
		)
		var authored_footprint: Variant = source.get("footprint", null)
		if authored_footprint is Dictionary:
			var local_footprint := _rect(authored_footprint)
			footprint = Rect2i(source_global.position + local_footprint.position, local_footprint.size)
		footprints[String(source.get("id", ""))] = footprint
	for plot_index in plot_templates.size():
		var source: Dictionary = plot_templates[plot_index]
		var plot_id := String(source.get("id", "plot_%d" % plot_index))
		var role := String(source.get("building_role", "home"))
		var profile: Dictionary = profiles.get(role, {})
		if profile.is_empty():
			continue
		var local_plot := _rect(source.get("rect", {}))
		var plot_rect := Rect2i(anchor + local_plot.position, local_plot.size)
		var footprint: Rect2i = footprints[plot_id]
		var entry_side := String(source.get("entry_side", _entry_side(footprint, anchor)))
		var entry_tile := _entry_tile(footprint, entry_side)
		var approach := _approach_path(
			entry_tile, entry_side, streets, footprints.values()
		)
		var structure_id := "structure_%s_%s" % [String(base["atlas_settlement_id"]), plot_id]
		var interior_layer := "interior:%s" % structure_id
		var exterior_archetype_id := "archetype_%s_exterior" % structure_id
		var interior_archetype_id := "archetype_%s_interior" % structure_id
		var interior_variant := _interior_variant(profile, source, role)
		var exterior_entry := entry_tile - footprint.position
		archetypes[exterior_archetype_id] = _with_base(
		_exterior_archetype(
				exterior_archetype_id,
				role,
				String(profile.get("visual_style", role)),
				footprint.size,
				exterior_entry,
				StableHash.index("%s:%d:%s:shape" % [String(base["atlas_settlement_id"]), seed, plot_id], 4)
			), base
		)
		archetypes[exterior_archetype_id]["template"] = "structure_archetype_exterior"
		var interior_size := _pair(profile.get("interior_size", [10, 8]))
		archetypes[interior_archetype_id] = _with_base(
			_interior_archetype(
				interior_archetype_id, role,
				String(profile.get("visual_style", role)), interior_size,
				String(interior_variant.get("id", "%s_purpose" % role)),
				String(interior_variant.get("visual_story", "Purpose-built %s interior." % role.replace("_", " ")))
			), base
		)
		archetypes[interior_archetype_id]["template"] = "structure_archetype_interior"
		var interior_exit: Array = archetypes[interior_archetype_id]["anchors"]["exit"]
		var plot := _with_base(
			{
				"id": "plot_%s_%s" % [String(base["atlas_settlement_id"]), plot_id],
				"template": "plot_%s" % role,
				"building_role": role,
				"rect": _rect_data(plot_rect),
				"yard_zones": _global_yard_zones(source.get("yard_zones", []), plot_rect.position),
				"structure_id": structure_id,
				"editable": true
			},
			base
		)
		plots.append(plot)
		structures.append(
			_with_base(
				{
					"id": structure_id,
					"name": _display_name(role, plot_index),
					"template": role,
					"archetype_id": exterior_archetype_id,
					"plot_id": String(plot["id"]),
					"world_layer": "surface",
					"origin_tile": [footprint.position.x, footprint.position.y],
					"bounds": _rect_data(footprint),
					"entry_global_tile": [entry_tile.x, entry_tile.y],
					"entry_side": entry_side,
					"approach_path": _pairs(approach),
					"variation_key": StableHash.index(
						"%s:%d:%s:exterior" % [String(base["atlas_settlement_id"]), seed, plot_id], 10000
					),
					"interior_identity": String(interior_variant.get("id", "%s_purpose" % role)),
					"visual_story": String(interior_variant.get("visual_story", "Purpose-built %s interior." % role.replace("_", " "))),
					"occupant_binding_status": "proposal_slot",
					"interior_structure_id": "%s_interior" % structure_id,
					"activation_status": "review_required"
				},
				base
			)
		)
		structures.append(
			_with_base(
				{
					"id": "%s_interior" % structure_id,
					"name": "%s Interior" % _display_name(role, plot_index),
					"template": "%s_interior" % role,
					"archetype_id": interior_archetype_id,
					"plot_id": String(plot["id"]),
					"world_layer": interior_layer,
					"origin_tile": [0, 0],
					"bounds": {
						"position": [0, 0], "size": [interior_size.x, interior_size.y]
					},
					"surface_structure_id": structure_id,
					"variation_key": StableHash.index(
						"%s:%d:%s:interior" % [String(base["atlas_settlement_id"]), seed, plot_id], 10000
					),
					"activation_status": "review_required"
				},
				base
			)
		)
		portals.append_array(
			_portal_pair(
				structure_id,
				entry_tile,
				entry_side,
				interior_layer,
				_pair(interior_exit),
				base
			)
		)
		var home_anchor: Array = archetypes[interior_archetype_id]["anchors"]["home"]
		var service_anchor: Array = archetypes[interior_archetype_id]["anchors"]["service"]
		for role_index in profile.get("npc_roles", []).size():
			var npc_role := String(profile["npc_roles"][role_index])
			npc_slots.append(
				_with_base(
					{
						"id": "npc_slot_%s_%s_%02d" % [String(base["atlas_settlement_id"]), plot_id, role_index],
						"template": "npc_role_%s" % npc_role,
						"role": npc_role,
						"home_structure_id": structure_id,
						"home_layer": interior_layer,
						"home_tile": [home_anchor[0] + role_index % 2, home_anchor[1]],
						"activation_status": "review_required"
					},
					base
				)
			)
		for service_index in profile.get("services", []).size():
			var service := String(profile["services"][service_index])
			service_slots.append(
				_with_base(
					{
						"id": "service_slot_%s_%s_%02d" % [String(base["atlas_settlement_id"]), plot_id, service_index],
						"template": "service_%s" % service,
						"service": service,
						"structure_id": structure_id,
						"world_layer": interior_layer,
						"interaction_tile": [service_anchor[0] + service_index % 2, service_anchor[1]],
						"activation_status": "review_required"
					},
					base
				)
			)
		var fixtures: Array = profile.get("fixtures", []).duplicate()
		fixtures.append_array(interior_variant.get("fixtures", []))
		var fixture_positions := _fixture_positions(interior_size, fixtures.size())
		var authored_fixture_positions: Dictionary = profile.get("fixture_positions", {}).duplicate(true)
		for fixture_id in interior_variant.get("fixture_positions", {}):
			authored_fixture_positions[fixture_id] = interior_variant["fixture_positions"][fixture_id]
		for fixture_index in fixtures.size():
			var fixture := String(fixtures[fixture_index])
			var fixture_tile: Vector2i = _pair(authored_fixture_positions[fixture]) if authored_fixture_positions.has(fixture) else fixture_positions[fixture_index % fixture_positions.size()]
			fixture_slots.append(
				_with_base(
					{
						"id": "fixture_slot_%s_%s_%02d" % [String(base["atlas_settlement_id"]), plot_id, fixture_index],
						"template": "interior_fixture_%s" % fixture,
						"fixture": fixture,
						"structure_id": structure_id,
						"world_layer": interior_layer,
						"global_tile": [fixture_tile.x, fixture_tile.y],
						"interaction_slot": fixture in [
							"road_altar", "offering_bowl", "notice_board", "road_map",
							"locked_chest", "ledger_desk", "anvil", "workbench"
						],
						"loot_slot": fixture in [
							"locked_chest", "crate_stack", "barrel_stack", "locked_store",
							"storage_chest"
						],
						"authored_purpose": "personal" if role == "home" else "operational",
						"activation_status": "review_required"
					},
					base
				)
			)
		if bool(profile.get("public", false)):
			quest_slots.append(
				_with_base(
					{
						"id": "quest_hook_%s_%s" % [String(base["atlas_settlement_id"]), plot_id],
						"template": "settlement_role_hook",
						"structure_id": structure_id,
						"role_context": role,
						"status": "proposal_slot"
					},
					base
				)
			)
	return {
		"plots": plots,
		"structure_archetypes": archetypes,
		"structures": structures,
		"portals": portals,
		"npc_role_slots": npc_slots,
		"service_slots": service_slots,
		"interior_fixture_slots": fixture_slots,
		"quest_hook_slots": quest_slots
	}


static func _exterior_archetype(
	archetype_id: String, role: String, visual_style: String, size: Vector2i,
	entry: Vector2i, shape_variant: int
) -> Dictionary:
	var rows := _organic_exterior_rows(size, entry, shape_variant, role)
	return {
		"id": archetype_id,
		"name": "%s Exterior" % role.capitalize(),
		"role": "surface_exterior",
		"size": [size.x, size.y],
		"terrain_rows": rows,
		# Surface buildings are solid silhouettes. Their interior-looking `f`
		# cells only shape the footprint; they must not let the player walk under
		# the rendered facade or stand on its roof. Only the authored door opens.
		"tile_kinds": {"w": "wood_wall", "f": "wood_wall", "d": "wood_floor"},
		"footprint_shape": "irregular_%d" % shape_variant,
		"visual_style": visual_style,
		"anchors": {"entry": [entry.x, entry.y]}
	}


static func _organic_exterior_rows(
	size: Vector2i, door: Vector2i, variant: int, role: String
) -> Array[String]:
	var grid: Array[PackedStringArray] = []
	for y in size.y:
		var row := PackedStringArray()
		for x in size.x:
			row.append("w" if x == 0 or y == 0 or x == size.x - 1 or y == size.y - 1 else "f")
		grid.append(row)
	var cut_width := mini(3 + variant % 2, size.x / 3)
	var cut_height := mini(2 + (variant + 1) % 2, size.y / 3)
	var cut_right := variant % 2 == 0
	var cut_bottom := variant >= 2
	if role in ["coaching_inn", "stable"]:
		cut_width = mini(2, cut_width)
	for y in cut_height:
		for x in cut_width:
			var gx := size.x - 1 - x if cut_right else x
			var gy := size.y - 1 - y if cut_bottom else y
			if Vector2i(gx, gy) != door:
				grid[gy][gx] = "."
	var vertical_wall_x := size.x - cut_width - 1 if cut_right else cut_width
	var horizontal_wall_y := size.y - cut_height - 1 if cut_bottom else cut_height
	for y in cut_height:
		var gy := size.y - 1 - y if cut_bottom else y
		if grid[gy][vertical_wall_x] != ".":
			grid[gy][vertical_wall_x] = "w"
	for x in cut_width:
		var gx := size.x - 1 - x if cut_right else x
		if grid[horizontal_wall_y][gx] != ".":
			grid[horizontal_wall_y][gx] = "w"
	grid[door.y][door.x] = "d"
	var rows: Array[String] = []
	for row in grid:
		rows.append("".join(row))
	return rows


static func _interior_archetype(
	archetype_id: String, role: String, visual_style: String, size: Vector2i,
	interior_identity: String, visual_story: String
) -> Dictionary:
	var exit := Vector2i(size.x / 2, size.y - 1)
	var rows := _room_rows(size, exit)
	var interior_style := "%s_interior" % visual_style
	if role == "home":
		interior_style = "%s_%s_interior" % [visual_style, interior_identity]
	return {
		"id": archetype_id,
		"name": "%s Interior" % role.capitalize(),
		"role": "interior_room",
		"size": [size.x, size.y],
		"terrain_rows": rows,
		"tile_kinds": {"w": "wood_wall", "f": "wood_floor", "d": "wood_floor"},
		"visual_style": interior_style,
		"interior_identity": interior_identity,
		"visual_story": visual_story,
		"anchors": {
			"exit": [exit.x, exit.y],
			"service": [2, 2],
			"home": [size.x - 3, 2],
			"storage": [size.x - 3, size.y - 3]
		}
	}


static func _interior_variant(
	profile: Dictionary, plot_source: Dictionary, role: String
) -> Dictionary:
	var variant_id := String(plot_source.get("interior_variant", "%s_purpose" % role))
	var variant: Dictionary = profile.get("interior_variants", {}).get(variant_id, {})
	var result := variant.duplicate(true)
	result["id"] = variant_id
	return result


static func _fixture_positions(size: Vector2i, count: int) -> Array[Vector2i]:
	var candidates: Array[Vector2i] = []
	for y in range(2, size.y - 1):
		for x in range(2, size.x - 1):
			if (x + y) % 2 == 0:
				candidates.append(Vector2i(x, y))
	var result: Array[Vector2i] = []
	for index in mini(count, candidates.size()):
		result.append(candidates[index])
	return result


static func _global_yard_zones(source_zones: Variant, plot_origin: Vector2i) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not source_zones is Array:
		return result
	for source_zone in source_zones:
		if not source_zone is Dictionary:
			continue
		var local_rect := _rect(source_zone.get("rect", {}))
		if local_rect.size == Vector2i.ZERO:
			continue
		result.append({
			"kind": String(source_zone.get("kind", "soil")),
			"rect": _rect_data(Rect2i(plot_origin + local_rect.position, local_rect.size))
		})
	return result


static func _room_rows(size: Vector2i, door: Vector2i) -> Array[String]:
	var rows: Array[String] = []
	for y in size.y:
		var row := ""
		for x in size.x:
			var boundary := x == 0 or y == 0 or x == size.x - 1 or y == size.y - 1
			row += "d" if Vector2i(x, y) == door else ("w" if boundary else "f")
		rows.append(row)
	return rows


static func _portal_pair(
	structure_id: String,
	entry_tile: Vector2i,
	entry_side: String,
	interior_layer: String,
	interior_exit: Vector2i,
	base: Dictionary
) -> Array[Dictionary]:
	var outward := _side_vector(entry_side)
	return [
		_with_base(
			{
				"id": "portal_%s_entry" % structure_id,
				"template": "structure_entry_portal",
				"world_layer": "surface",
				"global_tile": [entry_tile.x, entry_tile.y],
				"target_layer": interior_layer,
				# Spawn far enough inside that the exit prompt does not cover the
				# room on entry. The player can still approach the door normally.
				"target_tile": [interior_exit.x, interior_exit.y - 4],
				"target_facing": [0, -1],
				"reciprocal_portal_id": "portal_%s_exit" % structure_id
			},
			base
		),
		_with_base(
			{
				"id": "portal_%s_exit" % structure_id,
				"template": "structure_exit_portal",
				"world_layer": interior_layer,
				"global_tile": [interior_exit.x, interior_exit.y],
				"target_layer": "surface",
				"target_tile": [entry_tile.x + outward.x, entry_tile.y + outward.y],
				"target_facing": [outward.x, outward.y],
				"reciprocal_portal_id": "portal_%s_entry" % structure_id
			},
			base
		)
	]


static func _generate_defenses(
	config: Dictionary,
	bounds: Rect2i,
	anchor: Vector2i,
	streets: Array[Dictionary],
	base: Dictionary
) -> Dictionary:
	var gates := [
		{"id": "north_gate", "global_tile": [anchor.x, bounds.position.y]},
		{"id": "east_gate", "global_tile": [bounds.end.x - 1, anchor.y]},
		{"id": "south_gate", "global_tile": [anchor.x, bounds.end.y - 1]},
		{"id": "west_gate", "global_tile": [bounds.position.x, anchor.y]}
	]
	if config.has("gates_local"):
		gates = []
		for gate in config["gates_local"]:
			var tile := anchor + _pair(gate.get("tile", [0, 0]))
			gates.append({"id": String(gate.get("id", "gate")), "global_tile": [tile.x, tile.y]})
	var boundary_polygon := []
	for pair in config.get("boundary_polygon_local", []):
		var point := anchor + _pair(pair)
		boundary_polygon.append([point.x, point.y])
	return _with_base(
		{
			"id": "defense_%s" % String(base["atlas_settlement_id"]),
			"template": String(config.get("kind", "none")),
			"kind": String(config.get("kind", "none")),
			"bounds": _rect_data(bounds),
			"boundary_polygon": boundary_polygon,
			"gate_width": int(config.get("gate_width", 7)),
			"gates": gates,
			"collision": "blocks_except_gates",
			"visual_style": String(config.get("visual_style", "")),
			"street_ids": streets.map(func(street): return street["id"])
		},
		base
	)


static func _encounter_zones(
	bounds: Rect2i, streets: Array[Dictionary], base: Dictionary
) -> Array[Dictionary]:
	return [
		_with_base(
			{
				"id": "encounter_%s_gates" % String(base["atlas_settlement_id"]),
				"template": "gate_arrivals",
				"kind": "travel_arrival",
				"bounds": _rect_data(bounds),
				"street_ids": streets.map(func(street): return street["id"]),
				"activation_status": "review_required"
			},
			base
		)
	]


static func _offset_rect_entries(
	entries: Array, anchor: Vector2i, base: Dictionary, prefix: String
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in entries:
		var data: Dictionary = entry.duplicate(true)
		data["id"] = "%s_%s_%s" % [prefix, String(base["atlas_settlement_id"]), entry.get("id", "")]
		data["template"] = "%s_%s" % [prefix, String(entry.get("role", entry.get("kind", "")))]
		if entry.has("rect"):
			var local := _rect(entry.get("rect", {}))
			data["rect"] = _rect_data(Rect2i(anchor + local.position, local.size))
		if entry.has("path"):
			var global_path := []
			for pair in entry["path"]:
				var point := anchor + _pair(pair)
				global_path.append([point.x, point.y])
			data["path"] = global_path
		result.append(_with_base(data, base))
	return result


static func _approach_path(
	entry: Vector2i,
	side: String,
	streets: Array[Dictionary],
	blocked_rects: Array
) -> PackedVector2Array:
	var direction := _side_vector(side)
	var start := entry + direction
	if _blocked(start, blocked_rects):
		return PackedVector2Array()
	var street_tiles := _street_tiles(streets)
	var search_bounds := Rect2i(start - Vector2i(64, 64), Vector2i(129, 129))
	for street in streets:
		if street.has("rect"):
			search_bounds = search_bounds.merge(_rect(street["rect"]))
		for pair in street.get("path", []):
			var point := _pair(pair)
			search_bounds = search_bounds.expand(point)
	var frontier: Array[Vector2i] = [start]
	var came_from := {start: entry}
	var directions := [
		direction,
		Vector2i(-direction.y, direction.x),
		Vector2i(direction.y, -direction.x),
		-direction
	]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		if street_tiles.has(current):
			var reversed: Array[Vector2i] = [current]
			while reversed[-1] != entry:
				reversed.append(came_from[reversed[-1]])
			reversed.reverse()
			return PackedVector2Array(reversed)
		for offset in directions:
			var next_tile: Vector2i = current + offset
			if came_from.has(next_tile) or not search_bounds.has_point(next_tile):
				continue
			if _blocked(next_tile, blocked_rects):
				continue
			came_from[next_tile] = current
			frontier.append(next_tile)
	return PackedVector2Array()


static func _append_building_paths(
	streets: Array[Dictionary], structures: Array[Dictionary], base: Dictionary
) -> void:
	for structure in structures:
		if String(structure.get("world_layer", "")) != "surface":
			continue
		var path: Array = structure.get("approach_path", [])
		if path.size() < 2:
			continue
		var path_id := "street_%s_to_%s" % [
			String(base["atlas_settlement_id"]), String(structure["id"])
		]
		streets.append(_with_base({
			"id": path_id,
			"template": "street_building_footpath",
			"kind": "building_footpath",
			"path": path.duplicate(true),
			"width": 1,
			"connects_structure_id": String(structure["id"]),
			"activation_status": "review_required"
		}, base))
		structure["approach_street_id"] = path_id


static func _street_tiles(streets: Array[Dictionary]) -> Dictionary:
	var result := {}
	for street in streets:
		if street.has("rect"):
			var rect := _rect(street["rect"])
			for y in rect.size.y:
				for x in rect.size.x:
					result[rect.position + Vector2i(x, y)] = true
		var path: Array = street.get("path", [])
		var radius := maxi(int(street.get("width", 1)) / 2, 0)
		for index in range(path.size() - 1):
			_add_thick_segment(result, _pair(path[index]), _pair(path[index + 1]), radius)
	return result


static func _add_thick_segment(
	target: Dictionary, start: Vector2i, finish: Vector2i, radius: int
) -> void:
	var delta := finish - start
	var steps := maxi(absi(delta.x), absi(delta.y))
	for step in range(steps + 1):
		var unit := float(step) / float(maxi(steps, 1))
		var center := Vector2i(roundi(lerpf(start.x, finish.x, unit)), roundi(lerpf(start.y, finish.y, unit)))
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if Vector2(x, y).length() <= float(radius) + 0.5:
					target[center + Vector2i(x, y)] = true


static func _blocked(tile: Vector2i, blocked_rects: Array) -> bool:
	for rect in blocked_rects:
		if (rect as Rect2i).has_point(tile):
			return true
	return false


static func _entry_side(footprint: Rect2i, anchor: Vector2i) -> String:
	var center := footprint.position + footprint.size / 2
	var delta := center - anchor
	if absi(delta.x) > absi(delta.y):
		return "east" if delta.x < 0 else "west"
	return "south" if delta.y < 0 else "north"


static func _entry_tile(footprint: Rect2i, side: String) -> Vector2i:
	var center := footprint.position + footprint.size / 2
	match side:
		"north": return Vector2i(center.x, footprint.position.y)
		"south": return Vector2i(center.x, footprint.end.y - 1)
		"west": return Vector2i(footprint.position.x, center.y)
		_: return Vector2i(footprint.end.x - 1, center.y)


static func _side_vector(side: String) -> Vector2i:
	match side:
		"north": return Vector2i.UP
		"south": return Vector2i.DOWN
		"west": return Vector2i.LEFT
		_: return Vector2i.RIGHT


static func _with_base(data: Dictionary, base: Dictionary) -> Dictionary:
	var result := data.duplicate(true)
	for key in base:
		result[key] = base[key]
	return result


static func _display_name(role: String, index: int) -> String:
	if role == "home":
		return "Northgate Home %02d" % (index + 1)
	return "Northgate %s" % role.capitalize()


static func _entry_by_id(entries: Array, entry_id: String) -> Dictionary:
	for entry in entries:
		if String(entry.get("id", "")) == entry_id:
			return entry
	return {}


static func _rect(value: Variant) -> Rect2i:
	if not value is Dictionary:
		return Rect2i()
	return Rect2i(_pair(value.get("position", [0, 0])), _pair(value.get("size", [0, 0])))


static func _rect_data(rect: Rect2i) -> Dictionary:
	return {
		"position": [rect.position.x, rect.position.y],
		"size": [rect.size.x, rect.size.y]
	}


static func _pair(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))


static func _point(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))


static func _pairs(points: PackedVector2Array) -> Array:
	var result := []
	for point in points:
		result.append([roundi(point.x), roundi(point.y)])
	return result
