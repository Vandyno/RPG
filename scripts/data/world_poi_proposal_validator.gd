class_name WorldPoiProposalValidator
extends RefCounted

const GENERATOR_VERSION := "world_poi_v1"


static func validate(proposal: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if proposal.is_empty():
		errors.append("POI proposal is empty")
		return errors
	for key in ["id", "atlas_region_id", "template", "template_catalog_version", "generator_version", "visual_style"]:
		if String(proposal.get(key, "")).is_empty():
			errors.append("POI proposal is missing %s" % key)
	if String(proposal.get("proposal_status", "")) != "proposal" or String(proposal.get("activation_status", "")) != "review_required":
		errors.append("POI proposal must remain review-gated proposal data")
	var bounds := _rect(proposal.get("bounds", {}))
	var walkable := {}
	var seen := {}
	for terrain in proposal.get("terrain", []):
		_validate_entity(terrain, proposal, seen, errors)
		var rect := _rect(terrain.get("rect", {}))
		for y in rect.size.y:
			for x in rect.size.x:
				walkable[rect.position + Vector2i(x, y)] = true
	for slot in proposal.get("slots", []):
		_validate_entity(slot, proposal, seen, errors)
		var tile := _pair(slot.get("global_tile", []))
		if not bounds.has_point(tile) or not walkable.has(tile):
			errors.append("POI slot %s is outside walkable layout" % String(slot.get("id", "")))
	for hook in proposal.get("quest_hooks", []):
		_validate_entity(hook, proposal, seen, errors)
	var approaches: Variant = proposal.get("walkability", {}).get("approach_tiles", [])
	if not approaches is Array or approaches.is_empty():
		errors.append("POI proposal needs at least one approach tile")
	else:
		for pair in approaches:
			var tile := _pair(pair)
			if not bounds.has_point(tile) or not walkable.has(tile):
				errors.append("POI approach tile is outside walkable layout")
	if not proposal.get("encounter_rules", {}) is Dictionary:
		errors.append("POI proposal needs encounter rules")
	return errors


static func _validate_entity(
	entry: Variant, proposal: Dictionary, seen: Dictionary, errors: PackedStringArray
) -> void:
	if not entry is Dictionary:
		errors.append("POI generated collection contains a non-object")
		return
	var id := String(entry.get("id", ""))
	if id.is_empty() or seen.has(id):
		errors.append("POI generated entity has missing or duplicate id %s" % id)
	seen[id] = true
	for key in ["atlas_region_id", "seed", "template", "generator_version"]:
		if not entry.has(key) or (key != "seed" and String(entry.get(key, "")).is_empty()):
			errors.append("POI generated entity %s is missing %s" % [id, key])
	if String(entry.get("atlas_region_id", "")) != String(proposal.get("atlas_region_id", "")) or int(entry.get("seed", 0)) != int(proposal.get("seed", 0)) or String(entry.get("generator_version", "")) != GENERATOR_VERSION:
		errors.append("POI generated entity %s has mismatched provenance" % id)


static func _rect(value: Variant) -> Rect2i:
	if not value is Dictionary:
		return Rect2i()
	return Rect2i(_pair(value.get("position", [])), _pair(value.get("size", [])))


static func _pair(value: Variant) -> Vector2i:
	if not value is Array or value.size() != 2:
		return Vector2i.ZERO
	return Vector2i(int(value[0]), int(value[1]))
