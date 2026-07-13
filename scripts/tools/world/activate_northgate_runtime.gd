extends SceneTree

const PROPOSAL_PATH := "res://data/proposals/settlement_northgate_seed_2701.json"
const OUTPUT_DIR := "res://data/runtime"
const RUNTIME_REAUTHOR_OFFSETS := {
	"structure_northgate_shrine_plot": [2, 4],
	"structure_northgate_guard_plot": [1, 5],
	"structure_northgate_hall_plot": [1, 0],
	"structure_northgate_inn_plot": [0, 0],
	"structure_northgate_stable_plot": [-2, 2],
	"structure_northgate_shop_plot": [2, -1],
	"structure_northgate_store_plot": [0, -5],
	"structure_northgate_west_home_plot": [3, -4],
	"structure_northgate_south_home_plot": [0, -10],
	"structure_northgate_smith_plot": [0, 0],
	"structure_northgate_east_home_plot": [-2, -1],
	"structure_northgate_southeast_home_plot": [0, -4],
	"structure_northgate_far_east_home_plot": [-1, -4]
}
const RUNTIME_BOUNDARY := [
	[-3274, -3957], [-3259, -3958], [-3245, -3957], [-3232, -3954],
	[-3229, -3945], [-3229, -3940], [-3232, -3927], [-3244, -3922],
	[-3260, -3921], [-3275, -3924], [-3280, -3933], [-3281, -3941],
	[-3278, -3951]
]
const RUNTIME_GATES := [
	{"id": "north_gate", "global_tile": [-3260, -3958]},
	{"id": "east_gate", "global_tile": [-3229, -3940]},
	{"id": "south_gate", "global_tile": [-3260, -3921]},
	{"id": "west_gate", "global_tile": [-3281, -3941]}
]

var _layout_offsets: Dictionary = {}


func _init() -> void:
	var proposal := _load_dictionary(PROPOSAL_PATH)
	if proposal.is_empty() or String(proposal.get("atlas_settlement_id", "")) != "northgate":
		push_error("Northgate proposal is missing or invalid")
		quit(1)
		return
	_layout_offsets = proposal.get("runtime_reauthor_offsets", {}).duplicate(true)
	_layout_offsets.merge(RUNTIME_REAUTHOR_OFFSETS, true)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	_write_json("%s/northgate_terrain.json" % OUTPUT_DIR, _terrain(proposal))
	_write_json(
		"%s/northgate_structure_archetypes.json" % OUTPUT_DIR,
		_runtime_archetypes(proposal)
	)
	_write_json("%s/northgate_structures.json" % OUTPUT_DIR, _runtime_structures(proposal))
	var runtime_content := _runtime_content(proposal)
	var objects := _portal_and_place_objects(proposal)
	objects.append_array(_fixture_objects(proposal))
	objects.append_array(runtime_content["objects"])
	_write_json("%s/northgate_objects.json" % OUTPUT_DIR, objects)
	for content_key in ["items", "readables", "quests", "npcs", "character_profiles", "dialogues", "shops"]:
		_write_json(
			"%s/northgate_%s.json" % [OUTPUT_DIR, content_key],
			runtime_content[content_key]
		)
	var schedule_runtime := _schedule_runtime(proposal)
	_write_json("%s/northgate_schedule_bindings.json" % OUTPUT_DIR, schedule_runtime["bindings"])
	_write_json("%s/northgate_schedule_destinations.json" % OUTPUT_DIR, schedule_runtime["destinations"])
	_write_json("%s/northgate_schedule_npcs.json" % OUTPUT_DIR, schedule_runtime["npcs"])
	_write_json(
		"%s/northgate_schedule_character_profiles.json" % OUTPUT_DIR,
		schedule_runtime["character_profiles"]
	)
	_write_json("%s/northgate_schedule_actors.json" % OUTPUT_DIR, schedule_runtime["actors"])
	print(
		"Activated Northgate geometry: %d structures, %d portals"
		% [proposal.get("structures", []).size(), proposal.get("portals", []).size()]
	)
	quit(0)


func _terrain(proposal: Dictionary) -> Dictionary:
	var regions: Array[Dictionary] = []
	var defenses: Dictionary = _runtime_defenses(proposal)
	# Plot-authored yard surfaces are laid first. Streets and footpaths follow so
	# access always wins where a garden or work yard meets a route.
	for plot in proposal.get("plots", []):
		var zone_index := 0
		var plot_offset := _compact_offset_for_structure(String(plot.get("structure_id", "")))
		for zone in plot.get("yard_zones", []):
			var yard_rect: Dictionary = zone.get("rect", {}).duplicate(true)
			if yard_rect.has("position"):
				var yard_position := _pair(yard_rect["position"]) + plot_offset
				yard_rect["position"] = [yard_position.x, yard_position.y]
			regions.append({
				"id": "runtime_%s_yard_%02d" % [String(plot.get("id", "plot")), zone_index],
				"kind": String(zone.get("kind", "soil")),
				"rect": yard_rect
			})
			zone_index += 1
	for worn_yard in _runtime_worn_yards():
		regions.append(worn_yard)
	for street in _runtime_streets(proposal):
		var region := {
			"id": "runtime_%s" % String(street.get("id", "street")),
			"kind": "road"
		}
		if street.has("rect"):
			region["rect"] = street["rect"].duplicate(true)
		else:
			var tiles := {}
			var path: Array = street.get("path", [])
			var radius := maxi(int(street.get("width", 1)) / 2, 0)
			for index in range(path.size() - 1):
				_add_thick_segment(tiles, _pair(path[index]), _pair(path[index + 1]), radius)
			region["tiles"] = _sorted_pairs(tiles)
		regions.append(region)
	var wall_tiles := {}
	var boundary: Array = defenses.get("boundary_polygon", [])
	var bank_tiles := {}
	for index in boundary.size():
		var start := _pair(boundary[index])
		var finish := _pair(boundary[(index + 1) % boundary.size()])
		_add_thick_segment(
			bank_tiles, start, finish, 1
		)
		_add_thick_segment(
			wall_tiles, start, finish, 0
		)
	regions.append({
		"id": "runtime_northgate_defense_bank", "kind": "hill",
		"tiles": _sorted_pairs(bank_tiles)
	})
	var gate_width := int(defenses.get("gate_width", 5))
	for gate in defenses.get("gates", []):
		var gate_tile := _pair(gate.get("global_tile", [0, 0]))
		for tile in wall_tiles.keys():
			if (tile as Vector2i).distance_to(gate_tile) <= float(gate_width) * 0.55:
				wall_tiles.erase(tile)
	regions.append({
		"id": "runtime_northgate_palisade", "kind": "palisade",
		"tiles": _sorted_pairs(wall_tiles)
	})
	var gate_roads := {}
	var anchor := _pair(proposal.get("anchor_global_tile", [0, 0]))
	for gate in defenses.get("gates", []):
		var gate_tile := _pair(gate.get("global_tile", [0, 0]))
		var outward := Vector2i(signi(gate_tile.x - anchor.x), signi(gate_tile.y - anchor.y))
		if outward.x != 0 and outward.y != 0:
			outward = Vector2i(outward.x, 0) if absi(gate_tile.x - anchor.x) > absi(gate_tile.y - anchor.y) else Vector2i(0, outward.y)
		_add_thick_segment(gate_roads, gate_tile - outward * 2, gate_tile + outward * 14, 2)
	regions.append({
		"id": "runtime_northgate_gate_approaches", "kind": "road",
		"tiles": _sorted_pairs(gate_roads)
	})
	var farm_route_tiles := {}
	_add_thick_segment(farm_route_tiles, Vector2i(-3210, -3938), Vector2i(-3148, -3843), 2)
	return {"areas": [
		{
			"id": "area_northgate_runtime",
			"name": "Northgate",
			"bounds": {"min": [-3300, -3980], "max": [-3200, -3880]},
			"default_kind": "grass",
			"regions": regions
		},
		{
			"id": "area_northgate_farm_route_runtime",
			"name": "Northgate Farm Route",
			"bounds": {"min": [-3225, -3960], "max": [-3130, -3820]},
			"default_kind": "grass",
			"regions": [{
				"id": "runtime_northgate_farm_route",
				"kind": "road",
				"tiles": _sorted_pairs(farm_route_tiles)
			}]
		}
	]}


func _runtime_worn_yards() -> Array[Dictionary]:
	return [
		{
			"id": "runtime_northgate_market_wear",
			"kind": "worn_ground",
			"tiles": _worn_patch_tiles(Rect2i(-3276, -3942, 13, 10), 3)
		},
		{
			"id": "runtime_northgate_coach_yard_wear",
			"kind": "worn_ground",
			"tiles": _worn_patch_tiles(Rect2i(-3245, -3949, 16, 11), 7)
		},
		{
			"id": "runtime_northgate_smith_yard_wear",
			"kind": "worn_ground",
			"tiles": _worn_patch_tiles(Rect2i(-3255, -3938, 14, 10), 11)
		}
	]


func _worn_patch_tiles(rect: Rect2i, edge_seed: int) -> Array:
	var tiles := {}
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var on_edge := (
				x == rect.position.x
				or x == rect.end.x - 1
				or y == rect.position.y
				or y == rect.end.y - 1
			)
			if on_edge and posmod(x * 17 + y * 31 + edge_seed, 5) < 2:
				continue
			tiles[Vector2i(x, y)] = true
	return _sorted_pairs(tiles)


func _runtime_streets(proposal: Dictionary) -> Array:
	var result: Array = proposal.get("streets", []).duplicate(true)
	for street in result:
		match String(street.get("id", "")):
			"street_northgate_north_road":
				street["path"] = [[-3260, -3958], [-3261, -3951], [-3259, -3946], [-3260, -3942]]
			"street_northgate_junction_square":
				street["rect"] = {"position": [-3265, -3946], "size": [10, 7]}
			"street_northgate_south_road":
				street["path"] = [[-3260, -3942], [-3259, -3936], [-3261, -3930], [-3260, -3921]]
			"street_northgate_west_road":
				street["path"] = [[-3260, -3942], [-3267, -3941], [-3274, -3943], [-3281, -3941]]
			"street_northgate_east_road":
				street["path"] = [[-3260, -3942], [-3252, -3941], [-3244, -3943], [-3237, -3940], [-3229, -3940]]
		var offset := _compact_offset_for_structure(String(street.get("connects_structure_id", "")))
		if offset == Vector2i.ZERO or not street.has("path"):
			continue
		var shifted_path := []
		for point in street["path"]:
			var shifted := _pair(point) + offset
			shifted_path.append([shifted.x, shifted.y])
		street["path"] = shifted_path
	return result


func _runtime_archetypes(proposal: Dictionary) -> Dictionary:
	var result := {}
	for archetype_id in proposal.get("structure_archetypes", {}):
		var source: Dictionary = proposal["structure_archetypes"][archetype_id]
		var role := String(source.get("role", "interior_room"))
		var tile_kinds: Dictionary = source.get("tile_kinds", {}).duplicate(true)
		if role == "surface_exterior":
			# Exterior collision stays aligned to the authored footprint, but its
			# generated wall/floor tiles must not show through the facade art.
			tile_kinds["w"] = "structure_blocker"
			tile_kinds["f"] = "grass"
			tile_kinds["d"] = "grass"
		result[String(archetype_id)] = {
			"id": String(source.get("id", archetype_id)),
			"name": String(source.get("name", archetype_id)),
			"role": role,
			"size": source.get("size", []).duplicate(true),
			"terrain_rows": source.get("terrain_rows", []).duplicate(true),
			"tile_kinds": tile_kinds,
			"visual_style": String(source.get("visual_style", "northgate_timber")),
			"anchors": source.get("anchors", {}).duplicate(true)
		}
	return result


func _runtime_structures(proposal: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for source in proposal.get("structures", []):
		var structure_id := String(source.get("id", ""))
		var origin := _pair(source.get("origin_tile", [0, 0]))
		origin += _compact_offset_for_structure(structure_id)
		result.append({
			"id": structure_id,
			"name": String(source.get("name", "Northgate Building")),
			"archetype_id": String(source.get("archetype_id", "")),
			"world_layer": String(source.get("world_layer", "surface")),
			"origin_tile": [origin.x, origin.y],
			"seed": "northgate:2701:%s" % structure_id
		})
	return result


func _portal_and_place_objects(proposal: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for source in proposal.get("portals", []):
		var entering := String(source.get("world_layer", "")) == "surface"
		var portal_offset := _compact_offset_for_portal(String(source.get("id", "")))
		var runtime_tile: Variant = source.get("global_tile", []).duplicate(true)
		var runtime_target: Variant = source.get("target_tile", []).duplicate(true)
		if entering:
			var shifted_tile := _pair(runtime_tile) + portal_offset
			runtime_tile = [shifted_tile.x, shifted_tile.y]
		elif String(source.get("target_layer", "")) == "surface":
			var shifted_target := _pair(runtime_target) + portal_offset
			runtime_target = [shifted_target.x, shifted_target.y]
		var portal_entry := {
			"id": String(source.get("id", "")),
			"name": "Northgate Building Door" if entering else "Exit to Northgate",
			"kind": "door",
			"world_layer": String(source.get("world_layer", "surface")),
			"global_tile": runtime_tile,
			"interaction_radius": 96 if entering else 48,
			"pick_radius": 12,
			"portal": {
				"target_layer": String(source.get("target_layer", "surface")),
				"target_tile": runtime_target,
				"target_facing": source.get("target_facing", [0, 1]).duplicate(true),
				"message": "Entered a Northgate building." if entering else "Returned to Northgate."
			}
		}
		if String(source.get("id", "")).contains("northgate_inn_plot"):
			portal_entry["visual_style"] = "hidden"
		result.append(portal_entry)
	var anchor: Array = proposal.get("anchor_global_tile", [0, 0])
	result.append({
		"id": "location_northgate_runtime_marker",
		"name": "Northgate",
		"kind": "location",
		"global_tile": anchor.duplicate(true),
		"interaction_radius": 160,
		"discovery_radius": 1024,
		"location_id": "location_northgate"
	})
	var anchor_tile := _pair(anchor)
	for gate in _runtime_defenses(proposal).get("gates", []):
		var gate_tile := _pair(gate.get("global_tile", [0, 0]))
		result.append({
			"id": "poi_northgate_%s_route" % String(gate.get("id", "gate")),
			"name": String(gate.get("id", "Town Gate")).replace("_", " ").capitalize(),
			"kind": "poi",
			"global_tile": _pair_data(_route_sign_tile(gate_tile, anchor_tile)),
			"interaction_radius": 96,
			"visual_style": "sign",
			"poi_type": "Town Route",
			"summary": "arrival and departure road",
			"description": "The road continues beyond Northgate into the Marches."
		})
	# Coach yard sits on the east road between the inn and stable. Keeping it out
	# of the civic core prevents the coach action from stealing nearby building
	# doors and gives arrivals an immediate view of both road services.
	var northgate_arrival := Vector2i(-3237, -3940)
	result.append({
		"id": "object_briarwatch_northgate_coach", "name": "Coach to Northgate",
		"kind": "door", "global_tile": [12, 6], "interaction_radius": 96,
		"pick_radius": 14, "canon_status": "proposal",
		"portal": {
			"target_layer": "surface",
			"target_tile": [northgate_arrival.x, northgate_arrival.y],
			"target_facing": [0, -1],
			"message": "The road coach brings you to Northgate."
		}
	})
	result.append({
		"id": "object_northgate_briarwatch_coach", "name": "Coach to Briarwatch",
		"kind": "door", "global_tile": [northgate_arrival.x + 1, northgate_arrival.y],
		"interaction_radius": 96, "pick_radius": 14, "canon_status": "proposal",
		"portal": {
			"target_layer": "surface", "target_tile": [10, 8],
			"target_facing": [0, -1], "message": "The road coach returns you to Briarwatch."
		}
	})
	return result


func _fixture_objects(proposal: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for fixture in proposal.get("interior_fixture_slots", []):
		var fixture_id := String(fixture.get("fixture", "furnishing"))
		var runtime_fixture := {
			"id": String(fixture.get("id", "")),
			"name": fixture_id.replace("_", " ").capitalize(),
			"kind": "fixture",
			"world_layer": String(fixture.get("world_layer", "surface")),
			"global_tile": fixture.get("global_tile", []).duplicate(true),
			"visual_style": "fixture:%s" % fixture_id,
			"structure_id": String(fixture.get("structure_id", "")),
			"authored_purpose": String(fixture.get("authored_purpose", "operational")),
			"canon_status": "proposal"
		}
		if String(fixture.get("structure_id", "")) == "structure_northgate_inn_plot":
			if fixture_id in ["guest_bed", "pantry_shelf", "west_bar_counter"]:
				runtime_fixture["visual_style"] = "hidden"
			elif fixture_id == "ale_barrels":
				runtime_fixture["visual_style"] = "fixture:guest_trunk"
		result.append(runtime_fixture)
	for detail in _surface_detail_slots():
		var runtime_detail := {
			"id": String(detail.get("id", "")),
			"name": String(detail.get("name", "Northgate detail")),
			"kind": "surface_detail",
			"world_layer": "surface",
			"global_tile": _runtime_detail_tile(detail, proposal),
			"visual_style": "fixture:%s" % String(detail.get("fixture", "yard_detail")),
			"authored_purpose": "Northgate visual dressing",
			"canon_status": "proposal"
		}
		if String(detail.get("id", "")) == "detail_northgate_inn_sign":
			runtime_detail["visual_style"] = "hidden"
		result.append(runtime_detail)
	return result


func _runtime_detail_tile(detail: Dictionary, proposal: Dictionary) -> Array:
	var detail_id := String(detail.get("id", ""))
	var position := _pair(detail.get("global_tile", [0, 0]))
	if detail_id.contains("_gate_post_"):
		position = _gate_tower_tile(detail_id, proposal)
	elif detail_id.contains("square_notice"):
		position = Vector2i(-3257, -3942)
	elif detail_id.contains("square_lantern_north"):
		position = Vector2i(-3263, -3947)
	elif detail_id.contains("market_stall_west"):
		position = Vector2i(-3269, -3940)
	elif detail_id.contains("market_stall_south"):
		position = Vector2i(-3268, -3938)
	elif detail_id.contains("inn_hitching"):
		position = Vector2i(-3249, -3946)
	elif detail_id.contains("stable_hitching"):
		position = Vector2i(-3232, -3941)
	elif detail_id.contains("stable_water"):
		position = Vector2i(-3230, -3941)
	elif detail_id.contains("square_edge_stones"):
		position = Vector2i(-3267, -3944) if detail_id.contains("west") else Vector2i(-3251, -3943)
	elif detail_id.contains("inn_sign"):
		position = Vector2i(-3254, -3949)
	elif detail_id.contains("inn_barrel"):
		position = Vector2i(-3242, -3949) if detail_id.ends_with("01") else Vector2i(-3242, -3948)
	elif detail_id.contains("inn_woodpile"):
		position = Vector2i(-3242, -3947)
	elif detail_id.contains("inn_yard_bench"):
		position = Vector2i(-3245, -3946)
	elif detail_id.contains("inn_yard_cart"):
		position = Vector2i(-3246, -3944)
	elif detail_id.contains("inn_rain_barrel"):
		position = Vector2i(-3251, -3946)
	elif detail_id.contains("stable_hay"):
		position = Vector2i(-3235, -3942) if detail_id.ends_with("01") else Vector2i(-3234, -3942)
	elif detail_id.contains("stable_cart"):
		position = Vector2i(-3231, -3942)
	elif detail_id.contains("smith_coal"):
		position = Vector2i(-3244, -3928)
	elif detail_id.contains("smith_wood"):
		position = Vector2i(-3243, -3928)
	elif detail_id.contains("smith_water"):
		position = Vector2i(-3244, -3930)
	elif detail_id.contains("shop_crate"):
		position = Vector2i(-3266, -3931) if detail_id.ends_with("01") else Vector2i(-3265, -3931)
	elif detail_id.contains("shop_sign"):
		position = Vector2i(-3274, -3939)
	elif detail_id.contains("store_barrels"):
		position = Vector2i(-3261, -3927)
	elif detail_id.contains("store_crates"):
		position = Vector2i(-3261, -3926)
	elif detail_id.contains("shrine_"):
		position = Vector2i(-3269, -3952) if detail_id.contains("candle") else Vector2i(-3261, -3951)
	elif detail_id.contains("west_home"):
		if detail_id.contains("wash"):
			position = Vector2i(-3281, -3922)
		elif detail_id.contains("planter"):
			position = Vector2i(-3274, -3925)
		else:
			position = Vector2i(-3274, -3922)
	elif detail_id.contains("south_home"):
		if detail_id.contains("wood"):
			position = Vector2i(-3270, -3914)
		elif detail_id.contains("bench"):
			position = Vector2i(-3261, -3915)
		else:
			position = Vector2i(-3269, -3914)
	elif detail_id.contains("southeast_home"):
		if detail_id.contains("basket"):
			position = Vector2i(-3255, -3923)
		elif detail_id.contains("bench"):
			position = Vector2i(-3247, -3924)
		else:
			position = Vector2i(-3255, -3921)
	elif detail_id.contains("far_east_home"):
		if detail_id.contains("fence"):
			position = Vector2i(-3242, -3923)
		elif detail_id.contains("tree"):
			position = Vector2i(-3233, -3925)
		else:
			position = Vector2i(-3233, -3924)
	elif detail_id.contains("east_home"):
		if detail_id.contains("herbs"):
			position = Vector2i(-3234, -3934)
		elif detail_id.contains("wash"):
			position = Vector2i(-3233, -3936)
		else:
			position = Vector2i(-3235, -3932)
	elif detail_id.contains("road_tree"):
		if detail_id.contains("west_road"):
			position = Vector2i(-3278, -3958)
		elif detail_id.contains("east_road"):
			position = Vector2i(-3226, -3947)
		elif detail_id.contains("south_road"):
			position = Vector2i(-3272, -3917)
		else:
			position = Vector2i(-3268, -3961)
	position += _compact_offset_for_detail(detail_id)
	return [position.x, position.y]


func _compact_offset_for_structure(structure_id: String) -> Vector2i:
	return _pair(_layout_offsets.get(structure_id, [0, 0]))


func _compact_offset_for_portal(portal_id: String) -> Vector2i:
	for structure_id in [
		"structure_northgate_shrine_plot",
		"structure_northgate_guard_plot",
		"structure_northgate_hall_plot",
		"structure_northgate_inn_plot",
		"structure_northgate_stable_plot",
		"structure_northgate_shop_plot",
		"structure_northgate_store_plot",
		"structure_northgate_west_home_plot",
		"structure_northgate_south_home_plot",
		"structure_northgate_smith_plot",
		"structure_northgate_east_home_plot",
		"structure_northgate_southeast_home_plot",
		"structure_northgate_far_east_home_plot"
	]:
		if portal_id.contains(structure_id):
			return _compact_offset_for_structure(structure_id)
	return Vector2i.ZERO


func _compact_offset_for_detail(detail_id: String) -> Vector2i:
	if detail_id.contains("west_home"):
		return _compact_offset_for_structure("structure_northgate_west_home_plot")
	if detail_id.contains("south_home") and not detail_id.contains("southeast_home"):
		return _compact_offset_for_structure("structure_northgate_south_home_plot")
	if detail_id.contains("southeast_home"):
		return _compact_offset_for_structure("structure_northgate_southeast_home_plot")
	if detail_id.contains("far_east_home"):
		return _compact_offset_for_structure("structure_northgate_far_east_home_plot")
	return Vector2i.ZERO


func _gate_tower_tile(detail_id: String, proposal: Dictionary) -> Vector2i:
	var gate_direction := ""
	for direction in ["north", "east", "south", "west"]:
		if detail_id.contains("_%s_gate_" % direction):
			gate_direction = direction
			break
	var gate_tile := _pair(proposal.get("anchor_global_tile", [0, 0]))
	for gate in _runtime_defenses(proposal).get("gates", []):
		if String(gate.get("id", "")) == "%s_gate" % gate_direction:
			gate_tile = _pair(gate.get("global_tile", []))
			break
	var outward := _cardinal_outward(gate_tile, _pair(proposal.get("anchor_global_tile", [0, 0])))
	var lateral := Vector2i.ZERO
	if gate_direction in ["north", "south"]:
		lateral = Vector2i.LEFT * 3 if detail_id.ends_with("_west") else Vector2i.RIGHT * 3
	else:
		lateral = Vector2i.UP * 3 if detail_id.ends_with("_north") else Vector2i.DOWN * 3
	return gate_tile + outward + lateral


func _runtime_defenses(proposal: Dictionary) -> Dictionary:
	var defenses: Dictionary = proposal.get("defenses", {}).duplicate(true)
	defenses["boundary_polygon"] = RUNTIME_BOUNDARY.duplicate(true)
	defenses["gates"] = RUNTIME_GATES.duplicate(true)
	return defenses


func _surface_detail_slots() -> Array[Dictionary]:
	return [
		{"id": "detail_northgate_well", "name": "Town Well", "fixture": "well", "global_tile": [-3265, -3942]},
		{"id": "detail_northgate_square_bench_west", "name": "Square Bench", "fixture": "bench", "global_tile": [-3270, -3941]},
		{"id": "detail_northgate_square_bench_east", "name": "Square Bench", "fixture": "bench", "global_tile": [-3257, -3941]},
		{"id": "detail_northgate_square_lantern_north", "name": "Square Lantern", "fixture": "lantern_post", "global_tile": [-3266, -3949]},
		{"id": "detail_northgate_square_lantern_south", "name": "Square Lantern", "fixture": "lantern_post", "global_tile": [-3255, -3931]},
		{"id": "detail_northgate_square_notice_kiosk", "name": "Road Notice Kiosk", "fixture": "notice_kiosk", "global_tile": [-3260, -3947]},
		{"id": "detail_northgate_market_stall_west", "name": "West Market Stall", "fixture": "market_stall", "global_tile": [-3275, -3937]},
		{"id": "detail_northgate_market_stall_south", "name": "Produce Stall", "fixture": "market_stall", "global_tile": [-3270, -3933]},
		{"id": "detail_northgate_inn_hitching_post", "name": "Inn Hitching Rail", "fixture": "hitching_post", "global_tile": [-3244, -3951]},
		{"id": "detail_northgate_stable_hitching_post", "name": "Stable Hitching Rail", "fixture": "hitching_post", "global_tile": [-3223, -3952]},
		{"id": "detail_northgate_stable_water_trough", "name": "Horse Trough", "fixture": "water_trough", "global_tile": [-3220, -3952]},
		{"id": "detail_northgate_square_edge_stones_west", "name": "Drainage Stones", "fixture": "stone_marker", "global_tile": [-3272, -3947]},
		{"id": "detail_northgate_square_edge_stones_east", "name": "Drainage Stones", "fixture": "stone_marker", "global_tile": [-3251, -3944]},
		{"id": "detail_northgate_north_gate_post_west", "name": "North Gate Tower", "fixture": "gate_tower", "global_tile": [-3267, -3991]},
		{"id": "detail_northgate_north_gate_post_east", "name": "North Gate Tower", "fixture": "gate_tower", "global_tile": [-3255, -3991]},
		{"id": "detail_northgate_south_gate_post_west", "name": "South Gate Tower", "fixture": "gate_tower", "global_tile": [-3262, -3890]},
		{"id": "detail_northgate_south_gate_post_east", "name": "South Gate Tower", "fixture": "gate_tower", "global_tile": [-3250, -3890]},
		{"id": "detail_northgate_west_gate_post_north", "name": "West Gate Tower", "fixture": "gate_tower", "global_tile": [-3313, -3944]},
		{"id": "detail_northgate_west_gate_post_south", "name": "West Gate Tower", "fixture": "gate_tower", "global_tile": [-3313, -3932]},
		{"id": "detail_northgate_east_gate_post_north", "name": "East Gate Tower", "fixture": "gate_tower", "global_tile": [-3208, -3944]},
		{"id": "detail_northgate_east_gate_post_south", "name": "East Gate Tower", "fixture": "gate_tower", "global_tile": [-3208, -3932]},
		{"id": "detail_northgate_inn_sign", "name": "Coaching Inn Sign", "fixture": "hanging_sign", "global_tile": [-3242, -3960]},
		{"id": "detail_northgate_inn_barrel_01", "name": "Inn Yard Basket", "fixture": "basket", "global_tile": [-3237, -3961]},
		{"id": "detail_northgate_inn_barrel_02", "name": "Inn Barrel", "fixture": "barrel_stack", "global_tile": [-3235, -3961]},
		{"id": "detail_northgate_inn_woodpile", "name": "Inn Firewood", "fixture": "woodpile", "global_tile": [-3241, -3947]},
		{"id": "detail_northgate_inn_yard_bench", "name": "Inn Yard Bench", "fixture": "bench", "global_tile": [-3248, -3944]},
		{"id": "detail_northgate_inn_yard_cart", "name": "Inn Yard Cart", "fixture": "cart", "global_tile": [-3246, -3944]},
		{"id": "detail_northgate_inn_rain_barrel", "name": "Inn Rain Barrel", "fixture": "rain_barrel", "global_tile": [-3251, -3946]},
		{"id": "detail_northgate_guard_crates", "name": "Guard Stores", "fixture": "crate_stack", "global_tile": [-3257, -3952]},
		{"id": "detail_northgate_guard_bench", "name": "Guard Bench", "fixture": "bench", "global_tile": [-3247, -3952]},
		{"id": "detail_northgate_hall_barrels", "name": "Hall Rain Barrels", "fixture": "barrel_stack", "global_tile": [-3272, -3944]},
		{"id": "detail_northgate_hall_bench", "name": "Petitioners Bench", "fixture": "bench", "global_tile": [-3270, -3943]},
		{"id": "detail_northgate_north_altar_bench", "name": "Pilgrim Bench", "fixture": "bench", "global_tile": [-3271, -3951]},
		{"id": "detail_northgate_north_yard_fence_west", "name": "North Yard Fence", "fixture": "fence", "global_tile": [-3276, -3951]},
		{"id": "detail_northgate_north_yard_fence_east", "name": "North Yard Fence", "fixture": "fence", "global_tile": [-3240, -3953]},
		{"id": "detail_northgate_north_yard_crates", "name": "Road Stores", "fixture": "crate_stack", "global_tile": [-3240, -3949]},
		{"id": "detail_northgate_stable_hay_01", "name": "Stable Hay", "fixture": "hay_bale", "global_tile": [-3214, -3960]},
		{"id": "detail_northgate_stable_hay_02", "name": "Stable Hay", "fixture": "hay_bale", "global_tile": [-3212, -3960]},
		{"id": "detail_northgate_stable_cart", "name": "Stable Cart", "fixture": "cart", "global_tile": [-3209, -3959]},
		{"id": "detail_northgate_smith_coal", "name": "Coal Stack", "fixture": "coal_stack", "global_tile": [-3241, -3923]},
		{"id": "detail_northgate_smith_wood", "name": "Smithy Woodpile", "fixture": "woodpile", "global_tile": [-3238, -3923]},
		{"id": "detail_northgate_smith_water", "name": "Quench Barrel", "fixture": "barrel_stack", "global_tile": [-3235, -3922]},
		{"id": "detail_northgate_shop_crate_01", "name": "Shop Crate", "fixture": "crate_stack", "global_tile": [-3300, -3921]},
		{"id": "detail_northgate_shop_crate_02", "name": "Shop Crate", "fixture": "crate_stack", "global_tile": [-3298, -3921]},
		{"id": "detail_northgate_shop_sign", "name": "General Shop Sign", "fixture": "hanging_sign", "global_tile": [-3302, -3924]},
		{"id": "detail_northgate_store_barrels", "name": "Storehouse Barrels", "fixture": "barrel_stack", "global_tile": [-3282, -3920]},
		{"id": "detail_northgate_store_crates", "name": "Storehouse Crates", "fixture": "crate_stack", "global_tile": [-3279, -3920]},
		{"id": "detail_northgate_shrine_candle", "name": "Road Candle", "fixture": "candle_cluster", "global_tile": [-3305, -3978]},
		{"id": "detail_northgate_shrine_stones", "name": "Offering Stones", "fixture": "stone_marker", "global_tile": [-3302, -3978]},
		{"id": "detail_northgate_west_home_wash", "name": "Wash Line", "fixture": "wash_line", "global_tile": [-3281, -3922]},
		{"id": "detail_northgate_west_home_planter", "name": "Window Planter", "fixture": "planter", "global_tile": [-3273, -3922]},
		{"id": "detail_northgate_west_home_wood", "name": "Craft Firewood", "fixture": "woodpile", "global_tile": [-3273, -3925]},
		{"id": "detail_northgate_south_home_wood", "name": "Firewood", "fixture": "woodpile", "global_tile": [-3269, -3913]},
		{"id": "detail_northgate_south_home_bench", "name": "Door Bench", "fixture": "bench", "global_tile": [-3261, -3914]},
		{"id": "detail_northgate_south_home_planter", "name": "Family Garden", "fixture": "planter", "global_tile": [-3269, -3915]},
		{"id": "detail_northgate_east_home_herbs", "name": "Herb Bed", "fixture": "planter", "global_tile": [-3241, -3930]},
		{"id": "detail_northgate_east_home_rain", "name": "Rain Barrel", "fixture": "rain_barrel", "global_tile": [-3232, -3932]},
		{"id": "detail_northgate_east_home_wash", "name": "Courier Drying Line", "fixture": "wash_line", "global_tile": [-3233, -3930]},
		{"id": "detail_northgate_southeast_home_basket", "name": "Market Basket", "fixture": "basket", "global_tile": [-3255, -3919]},
		{"id": "detail_northgate_southeast_home_bench", "name": "Door Bench", "fixture": "bench", "global_tile": [-3246, -3919]},
		{"id": "detail_northgate_southeast_home_planter", "name": "Kitchen Garden", "fixture": "planter", "global_tile": [-3255, -3917]},
		{"id": "detail_northgate_far_east_home_fence", "name": "Garden Fence", "fixture": "fence", "global_tile": [-3243, -3917]},
		{"id": "detail_northgate_far_east_home_tree", "name": "Apple Tree", "fixture": "tree", "global_tile": [-3233, -3918]},
		{"id": "detail_northgate_far_east_home_rain", "name": "Lodger Rain Barrel", "fixture": "rain_barrel", "global_tile": [-3232, -3921]},
		{"id": "detail_northgate_west_road_tree", "name": "Road Tree", "fixture": "tree", "global_tile": [-3309, -3955]},
		{"id": "detail_northgate_east_road_tree", "name": "Road Tree", "fixture": "tree", "global_tile": [-3211, -3951]},
		{"id": "detail_northgate_south_road_tree", "name": "Road Tree", "fixture": "tree", "global_tile": [-3290, -3898]},
		{"id": "detail_northgate_north_road_tree", "name": "Road Tree", "fixture": "tree", "global_tile": [-3240, -3983]}
	]


func _runtime_content(proposal: Dictionary) -> Dictionary:
	var home_ids := [
		"structure_northgate_west_home_plot",
		"structure_northgate_south_home_plot",
		"structure_northgate_east_home_plot",
		"structure_northgate_southeast_home_plot",
		"structure_northgate_far_east_home_plot"
	]
	var workers := [
		{"id": "innkeeper", "label": "Northgate Innkeeper", "role": "Innkeeper", "work": "structure_northgate_inn_plot", "home": home_ids[2], "dialogue": "dialogue_northgate_innkeeper"},
		{"id": "shopkeeper", "label": "Northgate Shopkeeper", "role": "General shopkeeper", "work": "structure_northgate_shop_plot", "home": home_ids[0], "dialogue": "dialogue_northgate_shopkeeper", "shop": "shop_northgate_general"},
		{"id": "smith", "label": "Northgate Smith", "role": "Town smith", "work": "structure_northgate_smith_plot", "home": home_ids[3], "dialogue": "dialogue_northgate_smith", "shop": "shop_northgate_smith"},
		{"id": "apprentice", "label": "Northgate Smith Apprentice", "role": "Smith apprentice", "work": "structure_northgate_smith_plot", "home": home_ids[3], "dialogue": "dialogue_northgate_resident"},
		{"id": "reeve", "label": "Northgate Reeve", "role": "Town reeve", "work": "structure_northgate_hall_plot", "home": home_ids[1], "dialogue": "dialogue_northgate_reeve", "quest": "quest_northgate_missing_manifest"},
		{"id": "clerk", "label": "Northgate Clerk", "role": "Town clerk", "work": "structure_northgate_hall_plot", "home": home_ids[1], "dialogue": "dialogue_northgate_resident"},
		{"id": "storekeeper", "label": "Northgate Storekeeper", "role": "Storekeeper", "work": "structure_northgate_store_plot", "home": home_ids[4], "dialogue": "dialogue_northgate_resident"},
		{"id": "stablehand", "label": "Northgate Stablehand", "role": "Stablehand", "work": "structure_northgate_stable_plot", "home": home_ids[4], "dialogue": "dialogue_northgate_resident"},
		{"id": "guard_north", "label": "Northgate Gate Guard", "role": "Gate guard", "work": "structure_northgate_guard_plot", "home": home_ids[0], "dialogue": "dialogue_northgate_resident"},
		{"id": "shrine_keeper", "label": "Northgate Shrine Keeper", "role": "Road shrine keeper", "work": "structure_northgate_shrine_plot", "home": home_ids[2], "dialogue": "dialogue_northgate_resident"}
	]
	var residents := []
	for index in home_ids.size():
		residents.append({
			"id": "resident_%02d" % (index + 1),
			"label": "Northgate Resident %02d" % (index + 1),
			"role": "Resident",
			"work": home_ids[index],
			"home": home_ids[index],
			"dialogue": "dialogue_northgate_resident"
		})
	workers.append_array(residents)
	var profiles := {}
	var npcs := {}
	var objects: Array[Dictionary] = []
	var work_counts := {}
	for index in workers.size():
		var worker: Dictionary = workers[index]
		var short_id := String(worker["id"])
		var profile_id := "char_northgate_%s" % short_id
		var npc_id := "npc_northgate_%s" % short_id
		profiles[profile_id] = _character_profile(profile_id, short_id)
		var npc := {
			"id": npc_id,
			"name": String(worker["label"]),
			"role": String(worker["role"]),
			"location": "northgate",
			"faction": "faction_marches_of_velcor",
			"character_profile_id": profile_id,
			"dialogue_id": String(worker["dialogue"]),
			"canon_status": "proposal"
		}
		if worker.has("shop"):
			npc["shop_id"] = String(worker["shop"])
		if worker.has("quest"):
			npc["quest_id"] = String(worker["quest"])
		npcs[npc_id] = npc
		var work_id := String(worker["work"])
		var work_index := int(work_counts.get(work_id, 0))
		work_counts[work_id] = work_index + 1
		var spawn := _interior_spawn(proposal, work_id, work_index)
		if short_id == "shopkeeper":
			spawn = _fixture_tile(proposal, work_id, "trade_counter", spawn)
		objects.append({
			"id": "%s_world" % npc_id,
			"name": String(worker["label"]),
			"kind": "npc",
			"world_layer": "interior:%s" % work_id,
			"global_tile": [spawn.x, spawn.y],
			"home_tile": [spawn.x, spawn.y],
			"npc_id": npc_id,
			"character_profile_id": profile_id,
			"actor_category": "humanoid",
			"hostility": "neutral",
			"combat_enabled": true,
			# Every bound civilian starts in schedule control. Combat may interrupt
			# that brain temporarily, then the schedule manager resumes it.
			"brain_id": "civilian_schedule",
			"behavior_state": "idle",
			"max_health": 14 + index % 5,
			"damage_taken_per_hit": 4,
			"attack_damage": 2,
			"aggro_radius": 128,
			"move_speed": 72,
			"inventory_owner_id": profile_id,
			"equipment_owner_id": profile_id,
			"assigned_home_structure_id": String(worker["home"]),
			"assigned_work_structure_id": work_id,
			"canon_status": "proposal",
			"inventory": [{"item_id": "item_gold_coin", "count": 2 + index % 4}]
		})
	var town_hall := "structure_northgate_hall_plot"
	var storehouse := "structure_northgate_store_plot"
	var inn := "structure_northgate_inn_plot"
	var smithy := "structure_northgate_smith_plot"
	var board_tile := _fixture_tile(proposal, town_hall, "notice_board", Vector2i(2, 2))
	objects.append({
		"id": "poi_northgate_notice_board", "name": "Northgate Notice Board",
		"kind": "poi", "world_layer": "interior:%s" % town_hall,
		"global_tile": [board_tile.x, board_tile.y], "interaction_radius": 96,
		"poi_type": "Town Notices", "summary": "jobs and civic notices",
		"description": "The reeve's board carries road notices, work offers, and a missing manifest posting.",
		"actions": _manifest_board_actions()
	})
	var readable_tile := board_tile + Vector2i(1, 0)
	objects.append({
		"id": "object_northgate_road_notice", "name": "Northgate Road Notice",
		"kind": "readable", "world_layer": "interior:%s" % town_hall,
		"global_tile": [readable_tile.x, readable_tile.y], "interaction_radius": 96,
		"readable_id": "readable_northgate_road_notice"
	})
	var manifest_tile := _fixture_tile(proposal, storehouse, "ledger_desk", Vector2i(3, 3))
	objects.append({
		"id": "pickup_northgate_missing_manifest", "name": "Missing Trade Manifest",
		"kind": "pickup", "world_layer": "interior:%s" % storehouse,
		"global_tile": [manifest_tile.x, manifest_tile.y], "interaction_radius": 96,
		"item_id": "item_northgate_trade_manifest", "count": 1,
		"conditions": [{"type": "quest_state", "quest_id": "quest_northgate_missing_manifest", "state": "active"}],
		"effects_on_pickup": [{"type": "set_quest_stage", "quest_id": "quest_northgate_missing_manifest", "stage": "found"}]
	})
	var bed_tile := _fixture_tile(proposal, inn, "guest_bed", Vector2i(3, 3))
	objects.append({
		"id": "object_northgate_inn_bed", "name": "Northgate Inn Bed",
		"kind": "rest", "world_layer": "interior:%s" % inn,
		"global_tile": [bed_tile.x, bed_tile.y], "interaction_radius": 96,
		"heal_amount": 999, "rest_hours": 8, "visual_style": "fixture:guest_bed"
	})
	var storage_tile := _fixture_tile(proposal, storehouse, "locked_store", Vector2i(4, 4))
	objects.append({
		"id": "object_northgate_player_storage", "name": "Rented Storage Chest",
		"kind": "container", "world_layer": "interior:%s" % storehouse,
		"global_tile": [storage_tile.x, storage_tile.y], "interaction_radius": 96,
		"inventory_owner_id": "storage_northgate_player",
		"effects_on_open": [{"type": "set_flag", "flag_id": "flag_northgate_storage_used", "value": true}]
	})
	var repair_tile := _fixture_tile(proposal, smithy, "workbench", Vector2i(4, 4))
	objects.append({
		"id": "poi_northgate_repair_bench", "name": "Northgate Repair Bench",
		"kind": "poi", "world_layer": "interior:%s" % smithy,
		"global_tile": [repair_tile.x, repair_tile.y], "interaction_radius": 96,
		"poi_type": "Smithing Service", "summary": "equipment repair and smithing",
		"description": "A maintained workbench for fitting, sharpening, and repairing travel gear.",
		"actions": [{
			"id": "repair_equipment", "text": "Repair Equipped Gear (5g)",
			"conditions": [{"type": "has_item", "item_id": "item_gold_coin", "count": 5}],
			"effects": [{"type": "repair_equipment", "cost": 5}],
			"response": "The smith refits, sharpens, and oils your equipped gear."
		}]
	})
	var result := {
		"items": _runtime_items(),
		"readables": _runtime_readables(),
		"quests": _runtime_quests(),
		"npcs": npcs,
		"character_profiles": profiles,
		"dialogues": _runtime_dialogues(),
		"shops": _runtime_shops(),
		"objects": objects
	}
	return result


func _append_northgate_schedule_coverage(result: Dictionary, proposal: Dictionary) -> void:
	var bindings: Dictionary = result["bindings"]
	var destinations: Dictionary = result["destinations"]
	var north_gate_tile := Vector2i(-3260, -3962)
	for gate in proposal.get("defenses", {}).get("gates", []):
		if String(gate.get("id", "")) == "north_gate":
			north_gate_tile = _pair(gate.get("global_tile", [north_gate_tile.x, north_gate_tile.y]))
			break
	var north_guard_patrol := north_gate_tile + Vector2i(-3, 3)
	var square_rect := Rect2i(Vector2i(-3265, -3946), Vector2i(10, 7))
	for street in proposal.get("streets", []):
		if String(street.get("kind", "")) == "public_square" and street.has("rect"):
			square_rect = _rect(street.get("rect", {}))
			break
	var square_center := square_rect.position + square_rect.size / 2
	var square_activity_tiles := [
		[square_rect.position.x + 2, square_rect.position.y + 2],
		[square_rect.position.x + 4, square_rect.position.y + 2],
		[square_rect.position.x + 6, square_rect.position.y + 2],
		[square_rect.end.x - 2, square_rect.position.y + 2],
		[square_rect.position.x + 2, square_rect.end.y - 2],
		[square_rect.position.x + 4, square_rect.end.y - 2],
		[square_rect.position.x + 6, square_rect.end.y - 2],
		[square_rect.end.x - 2, square_rect.end.y - 2]
	]
	var home_layers := {
		"west": "interior:structure_northgate_west_home_plot",
		"south": "interior:structure_northgate_south_home_plot",
		"east": "interior:structure_northgate_east_home_plot",
		"southeast": "interior:structure_northgate_southeast_home_plot",
		"far_east": "interior:structure_northgate_far_east_home_plot"
	}
	for home_id in home_layers:
		destinations["northgate_%s_home_runtime" % home_id] = {
			"world_layer": home_layers[home_id], "global_tile": [6, 2], "kind": "home.personal"
		}
	destinations["northgate_square_runtime"] = {
		"world_layer": "surface", "global_tile": [square_center.x, square_center.y], "kind": "town.square",
		"activity_tiles": square_activity_tiles,
		"activity_cycle_minutes": 45
	}
	destinations.merge(
		{
			"northgate_inn_service_runtime": {"world_layer": "interior:structure_northgate_inn_plot", "global_tile": [2, 2], "kind": "inn.bar", "activity_tiles": [[2, 2], [3, 2], [4, 2]], "activity_cycle_minutes": 45, "exclusive": true, "reservation_minutes": 90},
			"northgate_smith_service_runtime": {"world_layer": "interior:structure_northgate_smith_plot", "global_tile": [5, 3], "kind": "smith.anvil", "activity_tiles": [[5, 3], [6, 3], [5, 4]], "activity_cycle_minutes": 45, "exclusive": true, "reservation_minutes": 90},
			"northgate_smith_anvil_runtime": {"world_layer": "interior:structure_northgate_smith_plot", "global_tile": [3, 5], "kind": "smith.anvil", "activity_tiles": [[3, 5], [4, 5], [3, 6]], "activity_cycle_minutes": 45},
			"northgate_smith_break_runtime": {"world_layer": "interior:structure_northgate_smith_plot", "global_tile": [10, 7], "kind": "smith.break"},
			"northgate_inn_break_runtime": {"world_layer": "interior:structure_northgate_inn_plot", "global_tile": [15, 9], "kind": "inn.break"},
			"northgate_hall_notice_runtime": {"world_layer": "interior:structure_northgate_hall_plot", "global_tile": [2, 2], "kind": "hall.notice", "activity_tiles": [[2, 2], [3, 2], [2, 3]], "activity_cycle_minutes": 60},
			"northgate_hall_clerk_runtime": {"world_layer": "interior:structure_northgate_hall_plot", "global_tile": [4, 3], "kind": "hall.desk", "activity_tiles": [[4, 3], [5, 3], [4, 4]], "activity_cycle_minutes": 60},
			"northgate_hall_break_runtime": {"world_layer": "interior:structure_northgate_hall_plot", "global_tile": [9, 5], "kind": "hall.break"},
			"northgate_store_counter_runtime": {"world_layer": "interior:structure_northgate_store_plot", "global_tile": [4, 2], "kind": "store.counter", "activity_tiles": [[4, 2], [5, 2], [4, 3]], "activity_cycle_minutes": 60, "exclusive": true, "reservation_minutes": 90},
			"northgate_store_ledger_runtime": {"world_layer": "interior:structure_northgate_store_plot", "global_tile": [3, 3], "kind": "store.ledger", "activity_tiles": [[3, 3], [4, 3]], "activity_cycle_minutes": 45},
			"northgate_store_break_runtime": {"world_layer": "interior:structure_northgate_store_plot", "global_tile": [9, 6], "kind": "store.break"},
			"northgate_stable_work_runtime": {"world_layer": "interior:structure_northgate_stable_plot", "global_tile": [3, 4], "kind": "stable.work", "activity_tiles": [[3, 4], [4, 4], [3, 5]], "activity_cycle_minutes": 45, "exclusive": true, "reservation_minutes": 90},
			"northgate_stable_break_runtime": {"world_layer": "interior:structure_northgate_stable_plot", "global_tile": [6, 8], "kind": "stable.break"},
			"northgate_guard_watch_runtime": {"world_layer": "interior:structure_northgate_guard_plot", "global_tile": [8, 2], "kind": "guard.watch", "activity_tiles": [[8, 2], [7, 2], [8, 3]], "activity_cycle_minutes": 60, "exclusive": true, "reservation_minutes": 90},
			"northgate_guard_break_runtime": {"world_layer": "interior:structure_northgate_guard_plot", "global_tile": [8, 5], "kind": "guard.break"},
			"northgate_guard_gate_runtime": {"world_layer": "surface", "global_tile": [north_guard_patrol.x, north_guard_patrol.y], "kind": "guard.patrol"},
			"northgate_shrine_service_runtime": {"world_layer": "interior:structure_northgate_shrine_plot", "global_tile": [2, 2], "kind": "shrine.service", "exclusive": true, "reservation_minutes": 90},
			"northgate_shrine_break_runtime": {"world_layer": "interior:structure_northgate_shrine_plot", "global_tile": [6, 5], "kind": "shrine.break"}
		}
	)
	var role_bindings := [
		["innkeeper", "npc_northgate_innkeeper", "schedule_innkeeper_standard", "east", "northgate_inn_service_runtime", "northgate_inn_table_runtime"],
		["smith", "npc_northgate_smith", "schedule_smith_standard", "southeast", "northgate_smith_service_runtime", "northgate_smith_break_runtime"],
		["apprentice", "npc_northgate_apprentice", "schedule_smith_standard", "southeast", "northgate_smith_anvil_runtime", "northgate_smith_break_runtime"],
		["reeve", "npc_northgate_reeve", "schedule_clerk_standard", "south", "northgate_hall_notice_runtime", "northgate_hall_break_runtime"],
		["clerk", "npc_northgate_clerk", "schedule_clerk_standard", "south", "northgate_hall_clerk_runtime", "northgate_hall_break_runtime"],
		["storekeeper", "npc_northgate_storekeeper", "schedule_storekeeper_standard", "far_east", "northgate_store_counter_runtime", "northgate_store_break_runtime"],
		["stablehand", "npc_northgate_stablehand", "schedule_stablehand_standard", "far_east", "northgate_stable_work_runtime", "northgate_stable_break_runtime"],
		["guard_north", "npc_northgate_guard_north", "schedule_guard_standard", "west", "northgate_guard_watch_runtime", "northgate_guard_break_runtime"],
		["shrine_keeper", "npc_northgate_shrine_keeper", "schedule_shrine_keeper_standard", "east", "northgate_shrine_service_runtime", "northgate_shrine_break_runtime"]
	]
	for entry in role_bindings:
		var role_id := String(entry[0])
		var npc_id := String(entry[1])
		bindings["binding_northgate_%s" % role_id] = _schedule_binding(
			npc_id, String(entry[2]), "northgate_%s_home_runtime" % String(entry[3]), String(entry[4]), String(entry[5])
		)
		if role_id == "guard_north":
			bindings["binding_northgate_%s" % role_id]["patrol_destination_id"] = "northgate_guard_gate_runtime"
	bindings["binding_northgate_smith"]["service_ids"] = ["service_northgate_smith"]
	for index in range(1, 6):
		var home_id: String = String(["west", "south", "east", "southeast", "far_east"][index - 1])
		bindings["binding_northgate_resident_%02d" % index] = _schedule_binding(
			"npc_northgate_resident_%02d" % index,
			"schedule_resident_standard",
			"northgate_%s_home_runtime" % home_id,
			"northgate_square_runtime",
			"northgate_%s_home_runtime" % home_id
		)
		var next_index := (index % 5) + 1
		var next_home_id: String = String(["west", "south", "east", "southeast", "far_east"][next_index - 1])
		var resident_binding: Dictionary = bindings["binding_northgate_resident_%02d" % index]
		resident_binding["visit_target_npc_ids"] = ["npc_northgate_resident_%02d" % next_index]
		resident_binding["visit_destination_ids"] = ["northgate_%s_home_runtime" % next_home_id]
		if index == 5:
			resident_binding["personal_overrides"] = [
				{"block_id": "weekend_visit", "destination": "home", "action": "host_visitors"}
			]


func _schedule_binding(npc_id: String, schedule_id: String, home_id: String, work_id: String, break_id: String) -> Dictionary:
	return {
		"npc_id": npc_id,
		"schedule_id": schedule_id,
		"home_destination_id": home_id,
		"work_destination_id": work_id,
		"work_break_destination_id": break_id,
		"leisure_destination_ids": ["northgate_inn_table_runtime", "northgate_square_runtime"],
		"canon_status": "proposal",
		"activation_status": "review_required"
	}


func _character_profile(profile_id: String, seed_key: String) -> Dictionary:
	return {
		"character_id": profile_id, "people_id": "people_human",
		"faction_id": "faction_marches_of_velcor", "state": "alive", "level": 1,
		"stats": {}, "derived_bonuses": {},
		"appearance_generation": {"seed": "northgate:%s" % seed_key, "proportion_jitter": true, "jitter_strength": 0.025},
		"inventory_owner_id": profile_id, "equipment_owner_id": profile_id,
		"spellbook_owner_id": profile_id, "loadout_id": "", "corpse_entity_id": ""
	}


func _interior_spawn(proposal: Dictionary, surface_structure_id: String, offset: int) -> Vector2i:
	for structure in proposal.get("structures", []):
		if String(structure.get("surface_structure_id", "")) != surface_structure_id:
			continue
		var archetype: Dictionary = proposal.get("structure_archetypes", {}).get(String(structure.get("archetype_id", "")), {})
		var home := _pair(archetype.get("anchors", {}).get("home", [2, 2]))
		return home + Vector2i(offset % 2, offset / 2)
	return Vector2i(2, 2)


func _fixture_tile(
	proposal: Dictionary, structure_id: String, fixture_id: String, fallback: Vector2i
) -> Vector2i:
	for fixture in proposal.get("interior_fixture_slots", []):
		if String(fixture.get("structure_id", "")) == structure_id and String(fixture.get("fixture", "")) == fixture_id:
			return _pair(fixture.get("global_tile", [fallback.x, fallback.y]))
	return fallback


func _manifest_board_actions() -> Array:
	return [
		{"id": "take_manifest_job", "text": "Take Missing Manifest Job", "conditions": [{"type": "quest_state", "quest_id": "quest_northgate_missing_manifest", "state": "inactive"}], "effects": [{"type": "start_quest", "quest_id": "quest_northgate_missing_manifest"}], "response": "The posting says the last trade manifest was misplaced in the storehouse."},
		{"id": "manifest_still_missing", "text": "Review Missing Manifest Job", "conditions": [{"type": "quest_stage", "quest_id": "quest_northgate_missing_manifest", "stage": "search"}], "response": "Search the storehouse ledger desk for the missing manifest."},
		{"id": "return_manifest", "text": "Return Trade Manifest", "conditions": [{"type": "quest_state", "quest_id": "quest_northgate_missing_manifest", "state": "active"}, {"type": "has_item", "item_id": "item_northgate_trade_manifest", "count": 1}], "effects": [{"type": "remove_item", "item_id": "item_northgate_trade_manifest", "count": 1}, {"type": "complete_quest", "quest_id": "quest_northgate_missing_manifest"}], "response": "The clerk restores the manifest to the road ledger and marks the job paid."}
	]


func _runtime_items() -> Dictionary:
	return {"item_northgate_trade_manifest": {"id": "item_northgate_trade_manifest", "name": "Northgate Trade Manifest", "description": "A wax-marked road ledger sheet listing carts expected through Northgate.", "type": "quest", "max_stack": 1, "value": 0, "tags": ["quest"]}}


func _runtime_readables() -> Dictionary:
	return {"readable_northgate_road_notice": {"id": "readable_northgate_road_notice", "title": "Northgate Road Notice", "type": "notice", "author": "Northgate Reeve (proposal)", "body": "Keep gate approaches clear. Record damaged carts and missing manifests with the hall clerk.", "effects_on_read": [{"type": "set_flag", "flag_id": "flag_northgate_notice_read", "value": true}]}}


func _runtime_quests() -> Dictionary:
	return {"quest_northgate_missing_manifest": {"id": "quest_northgate_missing_manifest", "title": "The Missing Manifest", "description": "Northgate's trade manifest has gone missing inside the storehouse.", "initial_state": "inactive", "required_npc_ids": ["npc_northgate_storekeeper"], "start_stage": "search", "canon_status": "proposal", "stages": {"search": {"objectives": {"find": {"text": "Find the missing trade manifest in Northgate's storehouse.", "target_id": "pickup_northgate_missing_manifest"}}, "npc_routines": [{"npc_id": "npc_northgate_storekeeper", "routine_id": "search_missing_manifest", "destination_id": "northgate_store_ledger_runtime", "action": "search the ledger desk", "reason": "quest duty"}]}, "found": {"objectives": {"return": {"text": "Return the manifest to Northgate's notice board.", "target_id": "poi_northgate_notice_board"}}}}, "rewards": [{"type": "add_item", "item_id": "item_gold_coin", "count": 12}, {"type": "change_reputation", "faction_id": "faction_marches_of_velcor", "amount": 2}, {"type": "add_experience", "amount": 10}]}}


func _runtime_dialogues() -> Dictionary:
	return {
		"dialogue_northgate_resident": {"id": "dialogue_northgate_resident", "lines": [{"id": "greeting", "speaker": "Northgate Resident", "text": "Roads are busy today. The hall board carries local work."}]},
		"dialogue_northgate_innkeeper": {"id": "dialogue_northgate_innkeeper", "lines": [{"id": "greeting", "speaker": "Northgate Innkeeper", "text": "Beds are kept upstairs and the common room stays warm for travellers."}]},
		"dialogue_northgate_shopkeeper": {"id": "dialogue_northgate_shopkeeper", "lines": [{"id": "trade", "speaker": "Northgate Shopkeeper", "text": "General road goods, weighed and honestly priced.", "choices": [{"id": "trade_general", "text": "Trade", "open_shop_id": "shop_northgate_general"}]}]},
		"dialogue_northgate_smith": {"id": "dialogue_northgate_smith", "lines": [{"id": "trade", "speaker": "Northgate Smith", "text": "I keep road gear sound and sell what the forge can spare.", "choices": [{"id": "trade_smith", "text": "Browse smithing stock", "open_shop_id": "shop_northgate_smith"}]}]},
		"dialogue_northgate_reeve": {"id": "dialogue_northgate_reeve", "lines": [{"id": "greeting", "speaker": "Northgate Reeve", "text": "The hall board carries work that needs doing. Names and details remain provisional."}]}
	}


func _runtime_shops() -> Dictionary:
	return {
		"shop_northgate_general": {"id": "shop_northgate_general", "name": "Northgate General Store", "open_hour": 8, "close_hour": 18, "worker_npc_id": "npc_northgate_shopkeeper", "service_id": "service_northgate_general_shop", "stock": [{"item_id": "item_traveler_buckler", "price": 18}, {"item_id": "item_leather_cuirass", "price": 35}, {"item_id": "item_leather_boots", "price": 16}]},
		"shop_northgate_smith": {"id": "shop_northgate_smith", "name": "Northgate Smithy", "open_hour": 7, "close_hour": 18, "worker_npc_id": "npc_northgate_smith", "service_id": "service_northgate_smith", "stock": [{"item_id": "item_iron_cuirass", "price": 70}, {"item_id": "item_iron_helm", "price": 38}, {"item_id": "item_iron_gauntlets", "price": 32}, {"item_id": "item_iron_boots", "price": 34}]}
	}


func _schedule_runtime(proposal: Dictionary) -> Dictionary:
	var shop_structure := "structure_northgate_shop_plot"
	var home_structure := "structure_northgate_west_home_plot"
	var inn_structure := "structure_northgate_inn_plot"
	var work_tile := _fixture_tile(proposal, shop_structure, "trade_counter", Vector2i(2, 2))
	var home_tile := _interior_spawn(proposal, home_structure, 0)
	var inn_tile := _fixture_tile(proposal, inn_structure, "common_table", Vector2i(4, 4))
	var farmer_id := "npc_northgate_farmer"
	var farmer_profile_id := "char_northgate_farmer"
	var result := {
		"bindings": {
			"binding_northgate_shopkeeper": {
				"npc_id": "npc_northgate_shopkeeper",
				"schedule_id": "schedule_shopkeeper_standard",
				"home_destination_id": "northgate_shopkeeper_home_runtime",
				"work_destination_id": "northgate_shop_counter_runtime",
				"leisure_destination_ids": ["northgate_inn_table_runtime"],
				"service_ids": ["service_northgate_general_shop"],
				"canon_status": "proposal"
			},
			"binding_northgate_farmer": {
				"npc_id": farmer_id,
				"schedule_id": "schedule_farmer_standard",
				"home_destination_id": "northgate_farmer_home_runtime",
				"work_destination_id": "northgate_farm_field_runtime",
				"work_break_destination_id": "northgate_farm_meal_runtime",
				"leisure_destination_ids": ["northgate_inn_table_runtime"],
				"canon_status": "proposal",
				"activation_status": "review_required"
			}
		},
		"destinations": {
			"northgate_shopkeeper_home_runtime": {"world_layer": "interior:%s" % home_structure, "global_tile": [home_tile.x, home_tile.y], "kind": "home.sleep"},
			"northgate_shop_counter_runtime": {"world_layer": "interior:%s" % shop_structure, "global_tile": [work_tile.x, work_tile.y], "kind": "shop.counter", "activity_tiles": [[work_tile.x, work_tile.y], [work_tile.x + 1, work_tile.y], [work_tile.x, work_tile.y + 1]], "activity_cycle_minutes": 60, "exclusive": true, "reservation_minutes": 90},
			"northgate_inn_table_runtime": {"world_layer": "interior:%s" % inn_structure, "global_tile": [inn_tile.x, inn_tile.y], "kind": "inn.table", "activity_tiles": [[4, 2], [6, 2], [8, 2], [10, 2]], "activity_cycle_minutes": 60},
			"northgate_farmer_home_runtime": {"world_layer": "surface", "global_tile": [-3282, -3902], "kind": "home.sleep"},
			"northgate_farm_field_runtime": {"world_layer": "surface", "global_tile": [-3148, -3843], "kind": "farm.field", "activity_tiles": [[-3148, -3843], [-3149, -3843], [-3148, -3844]], "activity_cycle_minutes": 30},
			"northgate_farm_meal_runtime": {"world_layer": "surface", "global_tile": [-3154, -3855], "kind": "farm.meal", "activity_tiles": [[-3154, -3855], [-3155, -3855]], "activity_cycle_minutes": 45}
		},
		"npcs": {
			farmer_id: {
				"id": farmer_id,
				"name": "Northgate Farmer Proposal",
				"role": "Farmer",
				"location": "northgate",
				"dialogue_id": "dialogue_northgate_resident",
				"character_profile_id": farmer_profile_id,
				"canon_status": "proposal",
				"activation_status": "review_required"
			}
		},
		"character_profiles": {
			farmer_profile_id: {
				"character_id": farmer_profile_id,
				"people_id": "people_human",
				"faction_id": "faction_marches_of_velcor",
				"state": "alive",
				"level": 1,
				"stats": {},
				"derived_bonuses": {},
				"appearance_generation": {"seed": "northgate:farmer", "proportion_jitter": true, "jitter_strength": 0.025},
				"inventory_owner_id": farmer_profile_id,
				"equipment_owner_id": farmer_profile_id,
				"spellbook_owner_id": farmer_profile_id,
				"loadout_id": ""
			}
		},
		"actors": [{
			"id": "npc_northgate_farmer_world",
			"name": "Northgate Farmer Proposal",
			"kind": "npc",
			"npc_id": farmer_id,
			"character_profile_id": farmer_profile_id,
			"actor_category": "humanoid",
			"hostility": "neutral",
			"combat_enabled": true,
			"brain_id": "civilian_schedule",
			"behavior_state": "idle",
			"canon_status": "proposal",
			"activation_status": "review_required",
			"world_layer": "surface",
			"global_tile": [-3282, -3902],
			"home_tile": [-3282, -3902],
			"move_speed": 96,
			"max_health": 12,
			"damage_taken_per_hit": 4,
			"attack_damage": 0,
			"inventory_owner_id": farmer_profile_id,
			"equipment_owner_id": farmer_profile_id,
			"assigned_home_structure_id": "structure_northgate_south_home_plot",
			"assigned_work_structure_id": "poi_northgate_working_farm",
			"inventory": []
		}]
	}
	_append_northgate_schedule_coverage(result, proposal)
	return result


func _add_thick_segment(target: Dictionary, start: Vector2i, finish: Vector2i, radius: int) -> void:
	var delta := finish - start
	var steps := maxi(absi(delta.x), absi(delta.y))
	for step in range(steps + 1):
		var unit := float(step) / float(maxi(steps, 1))
		var center := Vector2i(roundi(lerpf(start.x, finish.x, unit)), roundi(lerpf(start.y, finish.y, unit)))
		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				if Vector2(x, y).length() <= float(radius) + 0.5:
					target[center + Vector2i(x, y)] = true


func _sorted_pairs(tiles: Dictionary) -> Array:
	var points: Array[Vector2i] = []
	for tile in tiles:
		points.append(tile)
	points.sort_custom(func(a: Vector2i, b: Vector2i): return a.y < b.y or (a.y == b.y and a.x < b.x))
	return points.map(func(tile: Vector2i): return [tile.x, tile.y])


func _load_dictionary(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Could not write %s" % path)
		return
	file.store_string(JSON.stringify(value, "  ") + "\n")


func _rect(value: Dictionary) -> Rect2i:
	return Rect2i(_pair(value.get("position", [0, 0])), _pair(value.get("size", [0, 0])))


func _route_sign_tile(gate_tile: Vector2i, anchor: Vector2i) -> Vector2i:
	var outward := _cardinal_outward(gate_tile, anchor)
	var roadside := Vector2i(outward.y, -outward.x)
	return gate_tile + outward * 3 + roadside * 4


func _cardinal_outward(gate_tile: Vector2i, anchor: Vector2i) -> Vector2i:
	var outward := Vector2i(signi(gate_tile.x - anchor.x), signi(gate_tile.y - anchor.y))
	if outward.x != 0 and outward.y != 0:
		outward = (
			Vector2i(outward.x, 0)
			if absi(gate_tile.x - anchor.x) > absi(gate_tile.y - anchor.y)
			else Vector2i(0, outward.y)
		)
	return outward


func _pair_data(value: Vector2i) -> Array:
	return [value.x, value.y]


func _pair(value: Array) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1]))
