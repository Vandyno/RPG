class_name WorldSettlementProposalValidator
extends RefCounted

const GENERATOR_VERSION := "world_settlement_v6"
const ENTITY_COLLECTIONS := [
	"districts", "streets", "plots", "structures", "portals", "npc_role_slots",
	"service_slots", "interior_fixture_slots", "quest_hook_slots", "encounter_zones"
]


static func load_proposal(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func validate(proposal: Dictionary, atlas: Dictionary = {}) -> PackedStringArray:
	var errors := PackedStringArray()
	if proposal.is_empty():
		errors.append("Settlement proposal is empty")
		return errors
	for key in ["id", "atlas_id", "atlas_region_id", "atlas_settlement_id", "template", "template_catalog_version", "generator_version"]:
		if String(proposal.get(key, "")).is_empty():
			errors.append("Settlement proposal is missing %s" % key)
	if String(proposal.get("proposal_status", "")) != "proposal":
		errors.append("Settlement proposal must remain proposal-only")
	if String(proposal.get("activation_status", "")) != "review_required":
		errors.append("Settlement activation_status must be review_required")
	if String(proposal.get("atlas_approval", {}).get("status", "")) != "approved":
		errors.append("Settlement proposal requires approved atlas review")
	if not atlas.is_empty():
		_validate_atlas_anchor(proposal, atlas, errors)
	var bounds := _rect(proposal.get("bounds", {}))
	if bounds.size.x <= 0 or bounds.size.y <= 0:
		errors.append("Settlement bounds are invalid")
	var seen := {}
	for collection_name in ENTITY_COLLECTIONS:
		var entries: Variant = proposal.get(collection_name, [])
		if not entries is Array:
			errors.append("%s must be an array" % collection_name)
			continue
		for entry in entries:
			_validate_entity(entry, collection_name, proposal, seen, errors)
	var defense: Variant = proposal.get("defenses", {})
	_validate_entity(defense, "defenses", proposal, seen, errors)
	var archetypes: Variant = proposal.get("structure_archetypes", {})
	if not archetypes is Dictionary or archetypes.is_empty():
		errors.append("structure_archetypes must be a non-empty object")
	else:
		for archetype_id in archetypes:
			_validate_entity(archetypes[archetype_id], "structure_archetypes", proposal, seen, errors)
			_validate_archetype(String(archetype_id), archetypes[archetype_id], errors)
	_validate_plots(proposal, bounds, errors)
	_validate_structures(proposal, bounds, errors)
	_validate_defenses(proposal, bounds, errors)
	_validate_portals(proposal, errors)
	_validate_slots(proposal, errors)
	_validate_surface_reachability(proposal, bounds, errors)
	_validate_interior_reachability(proposal, errors)
	return errors


static func _validate_atlas_anchor(
	proposal: Dictionary, atlas: Dictionary, errors: PackedStringArray
) -> void:
	var settlement_id := String(proposal.get("atlas_settlement_id", ""))
	var found := false
	for settlement in atlas.get("settlements", []):
		if String(settlement.get("id", "")) != settlement_id:
			continue
		found = true
		if String(settlement.get("region_id", "")) != String(proposal.get("atlas_region_id", "")):
			errors.append("Settlement proposal atlas region does not match anchor")
		break
	if not found:
		errors.append("Settlement proposal references missing atlas settlement")


static func build_report(
	proposal: Dictionary, atlas: Dictionary = {}
) -> Dictionary:
	var errors := validate(proposal, atlas)
	return {
		"proposal_id": String(proposal.get("id", "")),
		"atlas_region_id": String(proposal.get("atlas_region_id", "")),
		"atlas_settlement_id": String(proposal.get("atlas_settlement_id", "")),
		"settlement_name": String(proposal.get("settlement_name", "")),
		"seed": int(proposal.get("seed", 0)),
		"generator_version": String(proposal.get("generator_version", "")),
		"proposal_status": String(proposal.get("proposal_status", "")),
		"activation_status": String(proposal.get("activation_status", "")),
		"validation_status": "pass" if errors.is_empty() else "fail",
		"validation_errors": Array(errors),
		"checks": {
			"plot_collision": "pass" if not _contains(errors, "overlap") else "fail",
			"structure_collision": "pass" if not _contains(errors, "collides") else "fail",
			"surface_reachability": "pass" if not _contains(errors, "unreachable from streets") else "fail",
			"interior_reachability": "pass" if not _contains(errors, "unreachable interior") else "fail",
			"portals": "pass" if not _starts_with(errors, "Portal") else "fail",
			"homes_services": "pass" if not _starts_with(errors, "NPC slot") and not _starts_with(errors, "Service slot") else "fail"
		},
		"counts": {
			"plots": proposal.get("plots", []).size(),
			"structures": proposal.get("structures", []).size(),
			"archetypes": proposal.get("structure_archetypes", {}).size(),
			"portals": proposal.get("portals", []).size(),
			"npc_role_slots": proposal.get("npc_role_slots", []).size(),
			"service_slots": proposal.get("service_slots", []).size(),
			"interior_fixture_slots": proposal.get("interior_fixture_slots", []).size(),
			"quest_hook_slots": proposal.get("quest_hook_slots", []).size()
		},
		"review": proposal.get("review", {}).duplicate(true)
	}


static func _validate_entity(
	entry: Variant, collection: String, proposal: Dictionary, seen: Dictionary,
	errors: PackedStringArray
) -> void:
	if not entry is Dictionary:
		errors.append("%s contains a non-object" % collection)
		return
	var id := String(entry.get("id", ""))
	if id.is_empty():
		errors.append("%s contains an entry without id" % collection)
	elif seen.has(id):
		errors.append("Duplicate settlement entity id %s" % id)
	else:
		seen[id] = true
	for key in ["atlas_region_id", "atlas_settlement_id", "seed", "template", "generator_version"]:
		if not entry.has(key) or (key != "seed" and String(entry.get(key, "")).is_empty()):
			errors.append("Generated settlement entity %s is missing %s" % [id, key])
	if String(entry.get("atlas_region_id", "")) != String(proposal.get("atlas_region_id", "")):
		errors.append("Generated settlement entity %s has mismatched atlas region" % id)
	if String(entry.get("atlas_settlement_id", "")) != String(proposal.get("atlas_settlement_id", "")):
		errors.append("Generated settlement entity %s has mismatched atlas settlement" % id)
	if int(entry.get("seed", 0)) != int(proposal.get("seed", 0)):
		errors.append("Generated settlement entity %s has mismatched seed" % id)
	if String(entry.get("generator_version", "")) != GENERATOR_VERSION:
		errors.append("Generated settlement entity %s has mismatched generator version" % id)


static func _validate_archetype(
	id: String, archetype: Dictionary, errors: PackedStringArray
) -> void:
	if String(archetype.get("id", "")) != id:
		errors.append("Archetype %s has mismatched id" % id)
	var size := _pair(archetype.get("size", []))
	var rows: Variant = archetype.get("terrain_rows", [])
	if size.x <= 0 or size.y <= 0 or not rows is Array or rows.size() != size.y:
		errors.append("Archetype %s terrain height does not match size" % id)
		return
	for row in rows:
		if String(row).length() != size.x:
			errors.append("Archetype %s terrain width does not match size" % id)
	for anchor_id in archetype.get("anchors", {}):
		var tile := _pair(archetype["anchors"][anchor_id])
		if not _archetype_walkable(archetype, tile):
			errors.append("Archetype %s anchor %s is blocked or outside" % [id, anchor_id])


static func _validate_plots(
	proposal: Dictionary, bounds: Rect2i, errors: PackedStringArray
) -> void:
	var plots: Array = proposal.get("plots", [])
	for index in plots.size():
		var rect := _rect(plots[index].get("rect", {}))
		if rect.size.x <= 0 or rect.size.y <= 0 or not bounds.encloses(rect):
			errors.append("Plot %s is outside settlement bounds" % String(plots[index].get("id", "")))
		for other_index in range(index + 1, plots.size()):
			if rect.intersects(_rect(plots[other_index].get("rect", {}))):
				errors.append("Plots %s and %s overlap" % [String(plots[index].get("id", "")), String(plots[other_index].get("id", ""))])


static func _validate_structures(
	proposal: Dictionary, bounds: Rect2i, errors: PackedStringArray
) -> void:
	var plots := {}
	for plot in proposal.get("plots", []):
		plots[String(plot.get("id", ""))] = _rect(plot.get("rect", {}))
	var archetypes: Dictionary = proposal.get("structure_archetypes", {})
	var exteriors: Array[Rect2i] = []
	for structure in proposal.get("structures", []):
		var id := String(structure.get("id", ""))
		var archetype_id := String(structure.get("archetype_id", ""))
		if not archetypes.has(archetype_id):
			errors.append("Structure %s references missing archetype" % id)
			continue
		if String(structure.get("world_layer", "")) != "surface":
			continue
		var rect := _rect(structure.get("bounds", {}))
		var plot_id := String(structure.get("plot_id", ""))
		if not plots.has(plot_id) or not plots[plot_id].encloses(rect):
			errors.append("Structure %s is outside its plot" % id)
		if not bounds.encloses(rect):
			errors.append("Structure %s is outside settlement bounds" % id)
		for other in exteriors:
			if rect.intersects(other):
				errors.append("Structure %s collides with another structure" % id)
		exteriors.append(rect)
		var entry := _pair(structure.get("entry_global_tile", []))
		if not rect.has_point(entry) or not _archetype_walkable(archetypes[archetype_id], entry - rect.position):
			errors.append("Structure %s entry is blocked or outside" % id)


static func _validate_defenses(
	proposal: Dictionary, bounds: Rect2i, errors: PackedStringArray
) -> void:
	var defense: Dictionary = proposal.get("defenses", {})
	if _rect(defense.get("bounds", {})) != bounds:
		errors.append("Defense bounds do not match settlement bounds")
	for gate in defense.get("gates", []):
		var tile := _pair(gate.get("global_tile", []))
		if not bounds.has_point(tile) or not (
			tile.x == bounds.position.x or tile.x == bounds.end.x - 1
			or tile.y == bounds.position.y or tile.y == bounds.end.y - 1
		):
			errors.append("Defense gate %s is not on settlement edge" % String(gate.get("id", "")))


static func _validate_portals(proposal: Dictionary, errors: PackedStringArray) -> void:
	var portals := {}
	var archetypes: Dictionary = proposal.get("structure_archetypes", {})
	var layer_archetypes := {}
	for structure in proposal.get("structures", []):
		if String(structure.get("world_layer", "")) != "surface":
			layer_archetypes[String(structure.get("world_layer", ""))] = archetypes.get(String(structure.get("archetype_id", "")), {})
	for portal in proposal.get("portals", []):
		portals[String(portal.get("id", ""))] = portal
	for portal in proposal.get("portals", []):
		var id := String(portal.get("id", ""))
		var reciprocal_id := String(portal.get("reciprocal_portal_id", ""))
		if not portals.has(reciprocal_id):
			errors.append("Portal %s references missing reciprocal portal" % id)
			continue
		if String(portals[reciprocal_id].get("reciprocal_portal_id", "")) != id:
			errors.append("Portal %s reciprocal link is not symmetric" % id)
		for side in ["world", "target"]:
			var layer_key := "world_layer" if side == "world" else "target_layer"
			var tile_key := "global_tile" if side == "world" else "target_tile"
			var layer := String(portal.get(layer_key, ""))
			if layer != "surface":
				if not layer_archetypes.has(layer) or not _archetype_walkable(layer_archetypes[layer], _pair(portal.get(tile_key, []))):
					errors.append("Portal %s %s is blocked or missing" % [id, side])


static func _validate_slots(proposal: Dictionary, errors: PackedStringArray) -> void:
	var surface_structures := {}
	var interiors_by_surface := {}
	var archetypes: Dictionary = proposal.get("structure_archetypes", {})
	for structure in proposal.get("structures", []):
		if String(structure.get("world_layer", "")) == "surface":
			surface_structures[String(structure.get("id", ""))] = structure
		else:
			interiors_by_surface[String(structure.get("surface_structure_id", ""))] = structure
	for npc in proposal.get("npc_role_slots", []):
		var id := String(npc.get("id", ""))
		var home_id := String(npc.get("home_structure_id", ""))
		if not surface_structures.has(home_id) or not interiors_by_surface.has(home_id):
			errors.append("NPC slot %s references missing home" % id)
			continue
		var interior: Dictionary = interiors_by_surface[home_id]
		var archetype: Dictionary = archetypes.get(String(interior.get("archetype_id", "")), {})
		if not _archetype_walkable(archetype, _pair(npc.get("home_tile", []))):
			errors.append("NPC slot %s home tile is blocked" % id)
	for service in proposal.get("service_slots", []):
		var id := String(service.get("id", ""))
		var structure_id := String(service.get("structure_id", ""))
		if not interiors_by_surface.has(structure_id):
			errors.append("Service slot %s references missing structure interior" % id)
			continue
		var interior: Dictionary = interiors_by_surface[structure_id]
		var archetype: Dictionary = archetypes.get(String(interior.get("archetype_id", "")), {})
		if not _archetype_walkable(archetype, _pair(service.get("interaction_tile", []))):
			errors.append("Service slot %s tile is blocked" % id)
	for fixture in proposal.get("interior_fixture_slots", []):
		var id := String(fixture.get("id", ""))
		var structure_id := String(fixture.get("structure_id", ""))
		if not interiors_by_surface.has(structure_id):
			errors.append("Interior fixture %s references missing structure interior" % id)
			continue
		var interior: Dictionary = interiors_by_surface[structure_id]
		if String(fixture.get("world_layer", "")) != String(interior.get("world_layer", "")):
			errors.append("Interior fixture %s has mismatched world layer" % id)
		var archetype: Dictionary = archetypes.get(String(interior.get("archetype_id", "")), {})
		if not _archetype_walkable(archetype, _pair(fixture.get("global_tile", []))):
			errors.append("Interior fixture %s tile is blocked" % id)


static func _validate_surface_reachability(
	proposal: Dictionary, bounds: Rect2i, errors: PackedStringArray
) -> void:
	var walkable := {}
	for street in proposal.get("streets", []):
		if street.has("rect"):
			_add_rect(walkable, _rect(street.get("rect", {})))
		var path: Array = street.get("path", [])
		var radius := maxi(int(street.get("width", 1)) / 2, 0)
		for index in range(path.size() - 1):
			_add_thick_segment(walkable, _pair(path[index]), _pair(path[index + 1]), radius)
	var doors: Array[Vector2i] = []
	var streets_by_id := {}
	for street in proposal.get("streets", []):
		streets_by_id[String(street.get("id", ""))] = street
	for structure in proposal.get("structures", []):
		if String(structure.get("world_layer", "")) != "surface":
			continue
		var door := _pair(structure.get("entry_global_tile", []))
		doors.append(door)
		var approach_street_id := String(structure.get("approach_street_id", ""))
		if not streets_by_id.has(approach_street_id):
			errors.append("Structure door %s has no building footpath" % door)
		else:
			var approach_street: Dictionary = streets_by_id[approach_street_id]
			if String(approach_street.get("connects_structure_id", "")) != String(structure.get("id", "")):
				errors.append("Structure door %s has mismatched building footpath" % door)
		for pair in structure.get("approach_path", []):
			walkable[_pair(pair)] = true
	var start := _pair(proposal.get("anchor_global_tile", []))
	var reached := _flood(start, walkable, bounds)
	for door in doors:
		if not reached.has(door):
			errors.append("Structure door %s is unreachable from streets" % door)


static func _validate_interior_reachability(
	proposal: Dictionary, errors: PackedStringArray
) -> void:
	var archetypes: Dictionary = proposal.get("structure_archetypes", {})
	for structure in proposal.get("structures", []):
		if String(structure.get("world_layer", "")) == "surface":
			continue
		var archetype: Dictionary = archetypes.get(String(structure.get("archetype_id", "")), {})
		var size := _pair(archetype.get("size", []))
		var walkable := {}
		for y in size.y:
			for x in size.x:
				var tile := Vector2i(x, y)
				if _archetype_walkable(archetype, tile):
					walkable[tile] = true
		var exit := _pair(archetype.get("anchors", {}).get("exit", []))
		var reached := _flood(exit, walkable, Rect2i(Vector2i.ZERO, size))
		for anchor_id in ["home", "service", "storage"]:
			var anchor := _pair(archetype.get("anchors", {}).get(anchor_id, []))
			if not reached.has(anchor):
				errors.append("Structure %s has unreachable interior anchor %s" % [String(structure.get("id", "")), anchor_id])


static func _archetype_walkable(archetype: Dictionary, tile: Vector2i) -> bool:
	var size := _pair(archetype.get("size", []))
	if tile.x < 0 or tile.y < 0 or tile.x >= size.x or tile.y >= size.y:
		return false
	var rows: Array = archetype.get("terrain_rows", [])
	if tile.y >= rows.size() or tile.x >= String(rows[tile.y]).length():
		return false
	var code := String(rows[tile.y]).substr(tile.x, 1)
	var kind := String(archetype.get("tile_kinds", {}).get(code, ""))
	return kind not in ["", "wood_wall", "stone_wall", "water"]


static func _flood(start: Vector2i, walkable: Dictionary, bounds: Rect2i) -> Dictionary:
	var reached := {}
	if not walkable.has(start):
		return reached
	var queue: Array[Vector2i] = [start]
	reached[start] = true
	var index := 0
	while index < queue.size():
		var current: Vector2i = queue[index]
		index += 1
		for direction: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = current + direction
			if bounds.has_point(next) and walkable.has(next) and not reached.has(next):
				reached[next] = true
				queue.append(next)
	return reached


static func _rect(value: Variant) -> Rect2i:
	if not value is Dictionary:
		return Rect2i()
	return Rect2i(_pair(value.get("position", [])), _pair(value.get("size", [])))


static func _pair(value: Variant) -> Vector2i:
	if not value is Array or value.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))


static func _add_rect(target: Dictionary, rect: Rect2i) -> void:
	for y in rect.size.y:
		for x in rect.size.x:
			target[rect.position + Vector2i(x, y)] = true


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


static func _contains(errors: PackedStringArray, text: String) -> bool:
	for error in errors:
		if text in String(error):
			return true
	return false


static func _starts_with(errors: PackedStringArray, prefix: String) -> bool:
	for error in errors:
		if String(error).begins_with(prefix):
			return true
	return false
