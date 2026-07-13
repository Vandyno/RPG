class_name ContentWorldValidator
extends RefCounted

const Schema = preload("res://scripts/data/content_schema_validator.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")


static func validate(content: ContentDatabase, errors: Array[String]) -> void:
	_validate_locations(content, errors)
	_validate_structure_archetypes(content, errors)
	_validate_world_structures(content, errors)
	_validate_world_objects(content, errors)
	_validate_world_terrain(content, errors)


static func _validate_locations(content: ContentDatabase, errors: Array[String]) -> void:
	for location_id in content.location_ids():
		var location: Dictionary = content.get_location(location_id)
		Schema.validate_keyed_id(location, String(location_id), "Location", errors)
		if String(location.get("name", "")).is_empty():
			errors.append("Location %s is missing name." % location_id)
		if String(location.get("region", "")).is_empty():
			errors.append("Location %s is missing region." % location_id)
		if String(location.get("description", "")).is_empty():
			errors.append("Location %s is missing description." % location_id)


static func _validate_world_objects(content: ContentDatabase, errors: Array[String]) -> void:
	var seen_ids: Dictionary = {}
	for entry in content.world_object_entries():
		var object_id := String(entry.get("id", ""))
		if object_id.is_empty():
			errors.append("World object is missing id.")
			continue
		if seen_ids.has(object_id):
			errors.append("Duplicate world object id %s." % object_id)
		seen_ids[object_id] = true
		if object_id.begins_with("enemy_"):
			errors.append(
				"World object %s uses legacy enemy_ id; use npc_, actor_, or creature_."
				% object_id
			)
		Schema.validate_global_tile(entry, "World object %s" % object_id, errors)
		if String(entry.get("name", "")).is_empty():
			errors.append("World object %s is missing name." % object_id)
		Schema.validate_optional_positive_number(
			entry, "interaction_radius", "World object %s" % object_id, errors
		)
		Schema.validate_optional_positive_number(
			entry, "pick_radius", "World object %s" % object_id, errors
		)
		_validate_world_object_kind(content, entry, object_id, errors)
		Schema.validate_effect_list(
			content, entry, "effects_on_pickup", "world object %s" % object_id, errors
		)
		Schema.validate_effect_list(
			content, entry, "effects_on_defeat", "world object %s" % object_id, errors
		)
		Schema.validate_condition_list(
			content, entry, "conditions", "world object %s" % object_id, errors
		)
		Schema.validate_condition_list(
			content, entry, "open_conditions", "world object %s" % object_id, errors
		)
		Schema.validate_spell_loadout_fields(content, entry, "World object %s" % object_id, errors)


static func _validate_world_object_kind(
	content: ContentDatabase, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	var kind := String(entry.get("kind", ""))
	match kind:
		"readable":
			_validate_readable_object(content, entry, object_id, errors)
		"npc":
			_validate_npc_object(content, entry, object_id, errors)
		"pickup":
			_validate_pickup_object(content, entry, object_id, errors)
		"container":
			_validate_container_object(content, entry, object_id, errors)
		"door":
			Schema.validate_effect_list(
				content, entry, "effects_on_open", "world object %s" % object_id, errors
			)
			_validate_portal(entry, "World object %s portal" % object_id, errors)
		"enemy":
			errors.append(
				"World object %s uses legacy kind enemy; use kind npc with hostility hostile."
				% object_id
			)
		"rest":
			_validate_rest_object(content, entry, object_id, errors)
		"poi":
			_validate_poi_object(content, entry, object_id, errors)
		"location":
			_validate_location_object(content, entry, object_id, errors)
		"fixture":
			pass
		"surface_detail":
			pass
		_:
			errors.append("World object %s has unsupported kind %s." % [object_id, kind])


static func _validate_readable_object(
	content: ContentDatabase, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	var readable_id := String(entry.get("readable_id", ""))
	if not content.has_readable(readable_id):
		errors.append("World object %s references missing readable %s." % [object_id, readable_id])


static func _validate_npc_object(
	content: ContentDatabase, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	var npc_id := String(entry.get("npc_id", ""))
	var profile_id := String(entry.get("character_profile_id", ""))
	if npc_id.is_empty() and profile_id.is_empty():
		errors.append("World object %s is missing npc_id or character_profile_id." % object_id)
	elif not npc_id.is_empty() and not content.has_npc(npc_id):
		errors.append("World object %s references missing NPC %s." % [object_id, npc_id])
	_validate_actor_world_object(content, entry, object_id, errors)
	if ActorRules.has_combat_behavior_data(entry):
		_validate_combat_actor_object(entry, object_id, errors)


static func _validate_pickup_object(
	content: ContentDatabase, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	var item_id := String(entry.get("item_id", ""))
	if not content.has_item(item_id):
		errors.append("World object %s references missing item %s." % [object_id, item_id])
	Schema.validate_optional_positive_number(
		entry, "count", "World object %s" % object_id, errors
	)


static func _validate_container_object(
	content: ContentDatabase, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	var effects: Array = Schema.array_field(entry.get("effects_on_open", []))
	if effects.is_empty():
		errors.append("Container %s must have effects_on_open." % object_id)
	Schema.validate_effect_list(
		content, entry, "effects_on_open", "world object %s" % object_id, errors
	)


static func _validate_combat_actor_object(
	entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	Schema.validate_required_positive_number(
		entry, "max_health", "Hostile actor %s" % object_id, errors
	)
	Schema.validate_required_positive_number(
		entry, "damage_taken_per_hit", "Hostile actor %s" % object_id, errors
	)
	Schema.validate_required_non_negative_number(
		entry, "attack_damage", "Hostile actor %s" % object_id, errors
	)


static func _validate_rest_object(
	_content: ContentDatabase, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	Schema.validate_required_positive_number(
		entry, "heal_amount", "Rest object %s" % object_id, errors
	)
	Schema.validate_optional_positive_number(
		entry, "rest_hours", "Rest object %s" % object_id, errors
	)


static func _validate_poi_object(
	content: ContentDatabase, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	if String(entry.get("description", "")).is_empty():
		errors.append("POI %s is missing description." % object_id)
	var location_id := String(entry.get("location_id", ""))
	if not location_id.is_empty() and not content.has_location(location_id):
		errors.append("POI %s references missing location %s." % [object_id, location_id])
	var shop_id := String(entry.get("shop_id", ""))
	if not shop_id.is_empty() and not content.has_shop(shop_id):
		errors.append("POI %s references missing shop %s." % [object_id, shop_id])
	var system_tab := String(entry.get("system_tab", ""))
	if not system_tab.is_empty() and not Schema.supported_system_tabs().has(system_tab):
		errors.append("POI %s has unsupported system_tab %s." % [object_id, system_tab])
	if system_tab == "trade" and shop_id.is_empty():
		errors.append("POI %s has trade system_tab without shop_id." % object_id)
	Schema.validate_action_list(content, entry, "actions", "POI %s" % object_id, errors)
	Schema.validate_effect_list(
		content,
		entry, "effects_on_discover", "world object %s" % object_id, errors
	)


static func _validate_location_object(
	content: ContentDatabase, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	var location_id := String(entry.get("location_id", ""))
	if not content.has_location(location_id):
		errors.append("Location object %s references missing location %s." % [object_id, location_id])
	Schema.validate_optional_positive_number(
		entry, "discovery_radius", "Location object %s" % object_id, errors
	)


static func _validate_structure_archetypes(content: ContentDatabase, errors: Array[String]) -> void:
	for archetype_id in content.structure_archetype_ids():
		var archetype: Dictionary = content.get_structure_archetype(archetype_id)
		Schema.validate_keyed_id(archetype, String(archetype_id), "Structure archetype", errors)
		if String(archetype.get("name", "")).is_empty():
			errors.append("Structure archetype %s is missing name." % archetype_id)
		if String(archetype.get("visual_style", "")).is_empty():
			errors.append("Structure archetype %s is missing visual_style." % archetype_id)
		Schema.validate_positive_pair(
			archetype.get("size", []), "Structure archetype %s size" % archetype_id, errors
		)
		_validate_structure_rows(content, archetype, archetype_id, errors)
		_validate_anchor_dictionary(
			archetype.get("anchors", {}), "Structure archetype %s anchors" % archetype_id, errors
		)


static func _validate_structure_rows(
	_content: ContentDatabase, archetype: Dictionary, archetype_id: String, errors: Array[String]
) -> void:
	var rows_value: Variant = archetype.get("terrain_rows", [])
	var rows: Array = Schema.array_field(rows_value)
	if rows_value == null or rows.is_empty():
		return
	var size_value: Variant = archetype.get("size", [])
	if not size_value is Array or size_value.size() < 2:
		return
	var width := int(size_value[0])
	var height := int(size_value[1])
	if rows.size() != height:
		errors.append(
			"Structure archetype %s terrain_rows height must match size." % archetype_id
		)
	var tile_kinds := Schema.dictionary_field(archetype.get("tile_kinds", {}))
	for y in range(rows.size()):
		var row := String(rows[y])
		if row.length() != width:
			errors.append(
				"Structure archetype %s terrain row %d width must match size."
				% [archetype_id, y]
			)
		for x in range(row.length()):
			var code := row.substr(x, 1)
			if code == ".":
				continue
			if not tile_kinds.has(code):
				errors.append(
					"Structure archetype %s terrain code %s has no tile kind."
					% [archetype_id, code]
				)
				continue
			var kind := String(tile_kinds.get(code, ""))
			if not Schema.supported_terrain_kinds().has(kind):
				errors.append(
					"Structure archetype %s terrain code %s has unsupported kind %s."
					% [archetype_id, code, kind]
				)


static func _validate_world_structures(content: ContentDatabase, errors: Array[String]) -> void:
	var seen_ids: Dictionary = {}
	for entry_value in content.world_structure_entries():
		if not entry_value is Dictionary:
			errors.append("World structure has malformed entry.")
			continue
		var entry: Dictionary = entry_value
		var structure_id := String(entry.get("id", ""))
		if structure_id.is_empty():
			errors.append("World structure is missing id.")
			continue
		if seen_ids.has(structure_id):
			errors.append("Duplicate world structure id %s." % structure_id)
		seen_ids[structure_id] = true
		if String(entry.get("name", "")).is_empty():
			errors.append("World structure %s is missing name." % structure_id)
		var archetype_id := String(entry.get("archetype_id", ""))
		if not content.has_structure_archetype(archetype_id):
			errors.append(
				"World structure %s references missing archetype %s."
				% [structure_id, archetype_id]
			)
		if String(entry.get("world_layer", "")).is_empty():
			errors.append("World structure %s is missing world_layer." % structure_id)
		Schema.validate_numeric_pair(
			entry.get("origin_tile", []), "World structure %s origin_tile" % structure_id, errors
		)


static func _validate_portal(entry: Dictionary, owner: String, errors: Array[String]) -> void:
	if not entry.has("portal"):
		return
	var portal := Schema.dictionary_field(entry.get("portal", {}))
	if portal.is_empty():
		errors.append("%s must be a dictionary." % owner)
		return
	var target_layer := String(portal.get("target_layer", ""))
	if target_layer.is_empty():
		errors.append("%s is missing target_layer." % owner)
	Schema.validate_numeric_pair(portal.get("target_tile", []), "%s target_tile" % owner, errors)
	if portal.has("target_facing"):
		Schema.validate_numeric_pair(
			portal.get("target_facing", []), "%s target_facing" % owner, errors
		)


static func _validate_anchor_dictionary(
	value: Variant, owner: String, errors: Array[String]
) -> void:
	var anchors := Schema.dictionary_field(value)
	for anchor_id in anchors:
		var key := String(anchor_id)
		if key.is_empty():
			errors.append("%s has blank anchor id." % owner)
			continue
		Schema.validate_numeric_pair(anchors[anchor_id], "%s anchor %s" % [owner, key], errors)


static func _validate_actor_world_object(
	content: ContentDatabase, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	var kind := String(entry.get("kind", ""))
	var profile_id := String(entry.get("character_profile_id", ""))
	if kind == "npc":
		var npc: Dictionary = content.get_npc(String(entry.get("npc_id", "")))
		var npc_profile_id := String(npc.get("character_profile_id", ""))
		if profile_id.is_empty():
			profile_id = npc_profile_id
		elif not npc_profile_id.is_empty() and profile_id != npc_profile_id:
			errors.append(
				"World object %s character_profile_id must match NPC profile %s."
				% [object_id, npc_profile_id]
			)
	if profile_id.is_empty():
		errors.append("World object %s is missing character_profile_id." % object_id)
	elif not content.has_character_profile(profile_id):
		errors.append(
			"World object %s references missing character profile %s." % [object_id, profile_id]
		)
	for owner_field in ["inventory_owner_id", "equipment_owner_id"]:
		var owner_id := String(entry.get(owner_field, ""))
		if owner_id.is_empty():
			errors.append("World object %s is missing %s." % [object_id, owner_field])
		elif not profile_id.is_empty() and owner_id != profile_id:
			errors.append(
				"World object %s %s must match character_profile_id %s."
				% [object_id, owner_field, profile_id]
			)


static func _validate_world_terrain(content: ContentDatabase, errors: Array[String]) -> void:
	var terrain: Dictionary = content.get_world_terrain()
	if terrain.is_empty():
		return
	var areas_value: Variant = terrain.get("areas", [])
	var areas: Array = Schema.array_field(areas_value)
	if not areas_value is Array or areas.is_empty():
		errors.append("World terrain must define at least one area.")
		return
	var seen_ids: Dictionary = {}
	for area_value in areas:
		if not area_value is Dictionary:
			errors.append("World terrain has malformed area.")
			continue
		var area: Dictionary = area_value
		var area_id := String(area.get("id", ""))
		var owner := "World terrain area %s" % area_id
		if area_id.is_empty():
			errors.append("World terrain area is missing id.")
		elif seen_ids.has(area_id):
			errors.append("Duplicate world terrain area id %s." % area_id)
		seen_ids[area_id] = true
		_validate_terrain_bounds(content, area.get("bounds", {}), owner, errors)
		_validate_terrain_kind(content, area, "default_kind", owner, errors)
		_validate_terrain_regions(content, area, owner, errors)


static func _validate_terrain_regions(
	content: ContentDatabase, area: Dictionary, owner: String, errors: Array[String]
) -> void:
	var regions_value: Variant = area.get("regions", [])
	var regions: Array = Schema.array_field(regions_value)
	if not regions_value is Array or regions.is_empty():
		errors.append("%s must define regions." % owner)
		return
	var seen_ids: Dictionary = {}
	for region_value in regions:
		if not region_value is Dictionary:
			errors.append("%s has malformed region." % owner)
			continue
		var region: Dictionary = region_value
		var region_id := String(region.get("id", ""))
		var region_owner := "%s region %s" % [owner, region_id]
		if region_id.is_empty():
			errors.append("%s has region with missing id." % owner)
		elif seen_ids.has(region_id):
			errors.append("%s has duplicate region id %s." % [owner, region_id])
		seen_ids[region_id] = true
		_validate_terrain_kind(content, region, "kind", region_owner, errors)
		var has_rect := region.has("rect")
		var has_tiles := region.has("tiles")
		if not has_rect and not has_tiles:
			errors.append("%s must define rect or tiles." % region_owner)
		if has_rect:
			_validate_terrain_rect(content, region.get("rect", {}), region_owner, errors)
		if has_tiles:
			_validate_terrain_tiles(content, region.get("tiles", []), region_owner, errors)


static func _validate_terrain_bounds(
	_content: ContentDatabase, value: Variant, owner: String, errors: Array[String]
) -> void:
	var bounds: Dictionary = Schema.dictionary_field(value)
	if bounds.is_empty():
		errors.append("%s must define bounds." % owner)
		return
	Schema.validate_numeric_pair(bounds.get("min", []), "%s bounds min" % owner, errors)
	Schema.validate_numeric_pair(bounds.get("max", []), "%s bounds max" % owner, errors)


static func _validate_terrain_rect(
	_content: ContentDatabase, value: Variant, owner: String, errors: Array[String]
) -> void:
	var rect: Dictionary = Schema.dictionary_field(value)
	if rect.is_empty():
		errors.append("%s rect must be a dictionary." % owner)
		return
	Schema.validate_numeric_pair(rect.get("position", []), "%s rect position" % owner, errors)
	Schema.validate_positive_pair(rect.get("size", []), "%s rect size" % owner, errors)


static func _validate_terrain_tiles(
	_content: ContentDatabase, value: Variant, owner: String, errors: Array[String]
) -> void:
	var tiles: Array = Schema.array_field(value)
	if not value is Array or tiles.is_empty():
		errors.append("%s tiles must be a non-empty array." % owner)
		return
	for tile in tiles:
		Schema.validate_numeric_pair(tile, "%s tile" % owner, errors)


static func _validate_terrain_kind(
	_content: ContentDatabase,
	entry: Dictionary,
	field_id: String,
	owner: String,
	errors: Array[String]
) -> void:
	var kind := String(entry.get(field_id, ""))
	if not Schema.supported_terrain_kinds().has(kind):
		errors.append("%s has unsupported terrain kind %s." % [owner, kind])
