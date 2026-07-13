class_name WorldRegionProposalValidator
extends RefCounted

const GENERATOR_VERSION := "world_region_v3"


static func load_proposal(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


static func validate(proposal: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if proposal.is_empty():
		errors.append("Region proposal is empty")
		return errors
	for key in ["id", "atlas_id", "atlas_region_id", "template", "generator_version"]:
		if String(proposal.get(key, "")).is_empty():
			errors.append("Region proposal is missing %s" % key)
	if String(proposal.get("proposal_status", "")) != "proposal":
		errors.append("Region proposal must remain proposal-only")
	if String(proposal.get("activation_status", "")) != "review_required":
		errors.append("Region proposal activation_status must be review_required")
	if String(proposal.get("generator_version", "")) != GENERATOR_VERSION:
		errors.append("Region proposal has unsupported generator_version")
	if String(proposal.get("atlas_approval", {}).get("status", "")) != "approved":
		errors.append("Region proposal requires an approved atlas review")
	if String(proposal.get("template_catalog_version", "")).is_empty():
		errors.append("Region proposal is missing template_catalog_version")
	_validate_terrain_palette(proposal.get("terrain_palette", {}), errors)
	var seen_ids := {}
	for collection_name in ["terrain_cells", "minor_routes", "pois"]:
		var collection: Variant = proposal.get(collection_name, [])
		if not collection is Array:
			errors.append("%s must be an array" % collection_name)
			continue
		for entity in collection:
			_validate_generated_entity(entity, collection_name, proposal, seen_ids, errors)
	_validate_fixed_constraints(proposal.get("fixed_constraints", {}), errors)
	return errors


static func build_report(proposal: Dictionary) -> Dictionary:
	var errors := validate(proposal)
	var fixed: Dictionary = proposal.get("fixed_constraints", {})
	return {
		"proposal_id": String(proposal.get("id", "")),
		"atlas_id": String(proposal.get("atlas_id", "")),
		"atlas_region_id": String(proposal.get("atlas_region_id", "")),
		"seed": int(proposal.get("seed", 0)),
		"generator_version": String(proposal.get("generator_version", "")),
		"proposal_status": String(proposal.get("proposal_status", "")),
		"activation_status": String(proposal.get("activation_status", "")),
		"validation_status": "pass" if errors.is_empty() else "fail",
		"validation_errors": Array(errors),
		"counts": {
			"terrain_cells": proposal.get("terrain_cells", []).size(),
			"minor_routes": proposal.get("minor_routes", []).size(),
			"pois": proposal.get("pois", []).size(),
			"fixed_terrain_features": fixed.get("terrain_features", []).size(),
			"fixed_routes": fixed.get("routes", []).size(),
			"fixed_settlements": fixed.get("settlements", []).size(),
			"fixed_landmarks": fixed.get("landmarks", []).size()
		},
		"review": proposal.get("review", {}).duplicate(true)
	}


static func _validate_generated_entity(
	entity: Variant,
	collection_name: String,
	proposal: Dictionary,
	seen_ids: Dictionary,
	errors: PackedStringArray
) -> void:
	if not entity is Dictionary:
		errors.append("%s contains a non-object" % collection_name)
		return
	var entity_id := String(entity.get("id", ""))
	if entity_id.is_empty():
		errors.append("%s contains an entity without id" % collection_name)
	elif seen_ids.has(entity_id):
		errors.append("Duplicate generated entity id %s" % entity_id)
	else:
		seen_ids[entity_id] = true
	for key in ["atlas_region_id", "seed", "template", "generator_version"]:
		if not entity.has(key) or (key != "seed" and String(entity.get(key, "")).is_empty()):
			errors.append("Generated entity %s is missing %s" % [entity_id, key])
	if String(entity.get("atlas_region_id", "")) != String(proposal.get("atlas_region_id", "")):
		errors.append("Generated entity %s has mismatched atlas region" % entity_id)
	if int(entity.get("seed", 0)) != int(proposal.get("seed", 0)):
		errors.append("Generated entity %s has mismatched seed" % entity_id)
	if String(entity.get("generator_version", "")) != GENERATOR_VERSION:
		errors.append("Generated entity %s has mismatched generator version" % entity_id)
	if collection_name == "terrain_cells":
		_validate_cell(entity, proposal.get("terrain_palette", {}), errors)
	elif collection_name == "minor_routes":
		if not _valid_path(entity.get("path", [])):
			errors.append("Minor route %s has invalid path" % entity_id)
	elif collection_name == "pois":
		_validate_poi(entity, errors)


static func _validate_cell(
	cell: Dictionary, terrain_palette: Dictionary, errors: PackedStringArray
) -> void:
	var rect: Variant = cell.get("chunk_rect", {})
	if not rect is Dictionary or not _valid_pair(rect.get("position", [])) or not _valid_pair(rect.get("size", [])):
		errors.append("Terrain cell %s has invalid chunk_rect" % String(cell.get("id", "")))
		return
	if int(rect["size"][0]) <= 0 or int(rect["size"][1]) <= 0:
		errors.append("Terrain cell %s chunk size must be positive" % String(cell.get("id", "")))
	if String(cell.get("biome", "")).is_empty():
		errors.append("Terrain cell %s is missing biome" % String(cell.get("id", "")))
	var template_id := String(cell.get("template", ""))
	if not terrain_palette.has(template_id):
		errors.append("Terrain cell %s references missing terrain template" % String(cell.get("id", "")))
	elif String(cell.get("recommended_default_kind", "")) != String(
		terrain_palette[template_id].get("tile_kind", "")
	):
		errors.append("Terrain cell %s has mismatched terrain kind" % String(cell.get("id", "")))


static func _validate_terrain_palette(value: Variant, errors: PackedStringArray) -> void:
	if not value is Dictionary or value.is_empty():
		errors.append("terrain_palette must be a non-empty object")
		return
	for template_id in value:
		var definition: Variant = value[template_id]
		if not definition is Dictionary:
			errors.append("Terrain template %s must be an object" % template_id)
			continue
		for key in ["tile_kind", "base_kind", "visual_style", "collision", "movement_cost"]:
			if not definition.has(key) or (key != "movement_cost" and String(definition.get(key, "")).is_empty()):
				errors.append("Terrain template %s is missing %s" % [template_id, key])
		if String(definition.get("base_kind", "")) not in ["grass", "forest", "hill", "water"]:
			errors.append("Terrain template %s has unsupported base_kind" % template_id)
		if not definition.get("walkable", null) is bool:
			errors.append("Terrain template %s must define walkable" % template_id)
		if float(definition.get("movement_cost", 0.0)) <= 0.0:
			errors.append("Terrain template %s movement_cost must be positive" % template_id)


static func _validate_poi(poi: Dictionary, errors: PackedStringArray) -> void:
	var poi_id := String(poi.get("id", ""))
	if not _valid_pair(poi.get("global_tile", [])):
		errors.append("POI %s has invalid global_tile" % poi_id)
	for key in ["walkability", "slots", "encounter_rules", "quest_hooks", "visual_style"]:
		if not poi.has(key):
			errors.append("POI %s is missing %s" % [poi_id, key])
	if String(poi.get("activation_status", "")) != "review_required":
		errors.append("POI %s must require review" % poi_id)


static func _validate_fixed_constraints(value: Variant, errors: PackedStringArray) -> void:
	if not value is Dictionary:
		errors.append("fixed_constraints must be an object")
		return
	for collection_name in ["terrain_features", "routes", "settlements", "landmarks"]:
		var entries: Variant = value.get(collection_name, [])
		if not entries is Array:
			errors.append("fixed_constraints %s must be an array" % collection_name)
			continue
		for entry in entries:
			if String(entry.get("source_atlas_id", "")).is_empty() or not bool(entry.get("preserve", false)):
				errors.append("Fixed %s entry must preserve a source atlas id" % collection_name)


static func _valid_pair(value: Variant) -> bool:
	return (
		value is Array
		and value.size() == 2
		and _is_integral_number(value[0])
		and _is_integral_number(value[1])
	)


static func _is_integral_number(value: Variant) -> bool:
	return (
		value is int
		or (value is float and is_equal_approx(float(value), float(roundi(value))))
	)


static func _valid_path(value: Variant) -> bool:
	if not value is Array or value.size() < 2:
		return false
	for point in value:
		if not _valid_pair(point):
			return false
	return true
