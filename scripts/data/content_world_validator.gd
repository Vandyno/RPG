class_name ContentWorldValidator
extends RefCounted

const Schema = preload("res://scripts/data/content_schema_validator.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")


static func validate(content, errors: Array[String]) -> void:
	_validate_locations(content, errors)
	_validate_world_objects(content, errors)
	_validate_world_terrain(content, errors)


static func _validate_locations(content, errors: Array[String]) -> void:
	for location_id in content.locations:
		var location: Dictionary = content.locations[location_id]
		Schema.validate_keyed_id(location, String(location_id), "Location", errors)
		if String(location.get("name", "")).is_empty():
			errors.append("Location %s is missing name." % location_id)
		if String(location.get("region", "")).is_empty():
			errors.append("Location %s is missing region." % location_id)
		if String(location.get("description", "")).is_empty():
			errors.append("Location %s is missing description." % location_id)


static func _validate_world_objects(content, errors: Array[String]) -> void:
	var seen_ids: Dictionary = {}
	for entry in content.world_objects:
		var object_id := String(entry.get("id", ""))
		if object_id.is_empty():
			errors.append("World object is missing id.")
			continue
		if seen_ids.has(object_id):
			errors.append("Duplicate world object id %s." % object_id)
		seen_ids[object_id] = true
		Schema.validate_global_tile(entry, "World object %s" % object_id, errors)
		if String(entry.get("name", "")).is_empty():
			errors.append("World object %s is missing name." % object_id)
		Schema.validate_optional_positive_number(
			entry, "interaction_radius", "World object %s" % object_id, errors
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
	content, entry: Dictionary, object_id: String, errors: Array[String]
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
		_:
			errors.append("World object %s has unsupported kind %s." % [object_id, kind])


static func _validate_readable_object(
	content, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	var readable_id := String(entry.get("readable_id", ""))
	if not content.readables.has(readable_id):
		errors.append("World object %s references missing readable %s." % [object_id, readable_id])


static func _validate_npc_object(
	content, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	var npc_id := String(entry.get("npc_id", ""))
	var profile_id := String(entry.get("character_profile_id", ""))
	if npc_id.is_empty() and profile_id.is_empty():
		errors.append("World object %s is missing npc_id or character_profile_id." % object_id)
	elif not npc_id.is_empty() and not content.npcs.has(npc_id):
		errors.append("World object %s references missing NPC %s." % [object_id, npc_id])
	_validate_actor_world_object(content, entry, object_id, errors)
	if ActorRules.has_combat_behavior_data(entry):
		_validate_combat_actor_object(entry, object_id, errors)


static func _validate_pickup_object(
	content, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	var item_id := String(entry.get("item_id", ""))
	if not content.items.has(item_id):
		errors.append("World object %s references missing item %s." % [object_id, item_id])
	Schema.validate_optional_positive_number(
		entry, "count", "World object %s" % object_id, errors
	)


static func _validate_container_object(
	content, entry: Dictionary, object_id: String, errors: Array[String]
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
	_content, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	Schema.validate_required_positive_number(
		entry, "heal_amount", "Rest object %s" % object_id, errors
	)
	Schema.validate_optional_positive_number(
		entry, "rest_hours", "Rest object %s" % object_id, errors
	)


static func _validate_poi_object(
	content, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	if String(entry.get("description", "")).is_empty():
		errors.append("POI %s is missing description." % object_id)
	var location_id := String(entry.get("location_id", ""))
	if not location_id.is_empty() and not content.locations.has(location_id):
		errors.append("POI %s references missing location %s." % [object_id, location_id])
	var shop_id := String(entry.get("shop_id", ""))
	if not shop_id.is_empty() and not content.shops.has(shop_id):
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
	content, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	var location_id := String(entry.get("location_id", ""))
	if not content.locations.has(location_id):
		errors.append("Location object %s references missing location %s." % [object_id, location_id])
	Schema.validate_optional_positive_number(
		entry, "discovery_radius", "Location object %s" % object_id, errors
	)


static func _validate_actor_world_object(
	content, entry: Dictionary, object_id: String, errors: Array[String]
) -> void:
	var kind := String(entry.get("kind", ""))
	var profile_id := String(entry.get("character_profile_id", ""))
	if kind == "npc":
		var npc: Dictionary = content.npcs.get(String(entry.get("npc_id", "")), {})
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
	elif not content.character_profiles.has(profile_id):
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


static func _validate_world_terrain(content, errors: Array[String]) -> void:
	if content.world_terrain.is_empty():
		return
	var areas_value: Variant = content.world_terrain.get("areas", [])
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
	content, area: Dictionary, owner: String, errors: Array[String]
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
	_content, value: Variant, owner: String, errors: Array[String]
) -> void:
	var bounds: Dictionary = Schema.dictionary_field(value)
	if bounds.is_empty():
		errors.append("%s must define bounds." % owner)
		return
	Schema.validate_numeric_pair(bounds.get("min", []), "%s bounds min" % owner, errors)
	Schema.validate_numeric_pair(bounds.get("max", []), "%s bounds max" % owner, errors)


static func _validate_terrain_rect(
	_content, value: Variant, owner: String, errors: Array[String]
) -> void:
	var rect: Dictionary = Schema.dictionary_field(value)
	if rect.is_empty():
		errors.append("%s rect must be a dictionary." % owner)
		return
	Schema.validate_numeric_pair(rect.get("position", []), "%s rect position" % owner, errors)
	Schema.validate_positive_pair(rect.get("size", []), "%s rect size" % owner, errors)


static func _validate_terrain_tiles(
	_content, value: Variant, owner: String, errors: Array[String]
) -> void:
	var tiles: Array = Schema.array_field(value)
	if not value is Array or tiles.is_empty():
		errors.append("%s tiles must be a non-empty array." % owner)
		return
	for tile in tiles:
		Schema.validate_numeric_pair(tile, "%s tile" % owner, errors)


static func _validate_terrain_kind(
	_content, entry: Dictionary, field_id: String, owner: String, errors: Array[String]
) -> void:
	var kind := String(entry.get(field_id, ""))
	if not Schema.supported_terrain_kinds().has(kind):
		errors.append("%s has unsupported terrain kind %s." % [owner, kind])
