class_name ContentScheduleValidator
extends RefCounted

const ScheduleResolver = preload("res://scripts/core/schedule_resolver.gd")


static func validate(content, errors: Array[String]) -> void:
	for profile_id in content.schedule_profiles:
		var profile: Dictionary = content.schedule_profiles[profile_id]
		if String(profile.get("id", "")) != String(profile_id):
			errors.append("Schedule profile key/id mismatch: %s." % String(profile_id))
		if String(profile.get("brain_id", "")) != "civilian_schedule":
			errors.append("Schedule profile %s must use civilian_schedule." % String(profile_id))
		for error in ScheduleResolver.validate_full_day(profile):
			errors.append(error)
		var weekend_blocks: Variant = profile.get("weekend_blocks", [])
		if weekend_blocks is Array and not weekend_blocks.is_empty():
			for error in ScheduleResolver.validate_full_day(profile, 6):
				errors.append(error)
		_validate_weather_overrides(profile, String(profile_id), errors)
	for binding_id in content.schedule_bindings:
		var binding: Dictionary = content.schedule_bindings[binding_id]
		var npc_id := String(binding.get("npc_id", ""))
		if npc_id.is_empty():
			errors.append("Schedule binding %s has no npc_id." % String(binding_id))
		elif not content.has_npc(npc_id):
			errors.append("Schedule binding %s references missing NPC %s." % [binding_id, npc_id])
		var schedule_id := String(binding.get("schedule_id", ""))
		if not content.schedule_profiles.has(schedule_id):
			errors.append("Schedule binding %s references missing profile %s." % [binding_id, schedule_id])
		for destination_field in ["home_destination_id", "work_destination_id", "work_break_destination_id"]:
			var destination_id := String(binding.get(destination_field, ""))
			if destination_id.is_empty():
				if destination_field == "work_break_destination_id":
					continue
				errors.append("Schedule binding %s has no %s." % [binding_id, destination_field])
			elif not content.schedule_destinations.has(destination_id):
				errors.append("Schedule binding %s references missing destination %s." % [binding_id, destination_id])
		var leisure: Variant = binding.get("leisure_destination_ids", [])
		if leisure is Array:
			for destination_id_value in leisure:
				var destination_id := String(destination_id_value)
				if not content.schedule_destinations.has(destination_id):
					errors.append("Schedule binding %s references missing leisure destination %s." % [binding_id, destination_id])
		var visit_destinations: Variant = binding.get("visit_destination_ids", [])
		var visit_targets: Variant = binding.get("visit_target_npc_ids", [])
		if visit_destinations is Array:
			for destination_id_value in visit_destinations:
				var visit_destination_id := String(destination_id_value)
				if not content.schedule_destinations.has(visit_destination_id):
					errors.append("Schedule binding %s references missing visit destination %s." % [binding_id, visit_destination_id])
		if visit_targets is Array:
			for target_id_value in visit_targets:
				var visit_target_id := String(target_id_value)
				if not content.has_npc(visit_target_id):
					errors.append("Schedule binding %s references missing visit target %s." % [binding_id, visit_target_id])
		if visit_destinations is Array and visit_targets is Array and visit_destinations.size() != visit_targets.size():
			errors.append("Schedule binding %s has mismatched visit destinations and targets." % binding_id)
		var services: Variant = binding.get("service_ids", [])
		if services is Array:
			for service_id_value in services:
				var service_id := String(service_id_value)
				if not _has_shop_service(content, service_id):
					errors.append("Schedule binding %s references missing service %s." % [binding_id, service_id])
				elif not _service_worker_matches(content, service_id, npc_id):
					errors.append("Schedule binding %s is not qualified for service %s." % [binding_id, service_id])
	for error in _destination_errors(content.schedule_destinations):
		errors.append(error)


static func _validate_weather_overrides(profile: Dictionary, profile_id: String, errors: Array[String]) -> void:
	var source: Variant = profile.get("weather_overrides", {})
	if source == null:
		return
	if not source is Dictionary:
		errors.append("Schedule profile %s weather_overrides must be a dictionary." % profile_id)
		return
	var known_blocks: Dictionary = {}
	for block_value in profile.get("weekday_blocks", profile.get("blocks", [])):
		if block_value is Dictionary:
			known_blocks[String(block_value.get("id", ""))] = true
	for block_value in profile.get("weekend_blocks", []):
		if block_value is Dictionary:
			known_blocks[String(block_value.get("id", ""))] = true
	for weather_id in source:
		var rules: Variant = (source as Dictionary)[weather_id]
		var weather_owner := "Schedule profile %s weather %s" % [profile_id, weather_id]
		if not rules is Array:
			errors.append("%s must be an array." % weather_owner)
			continue
		for rule_value in rules:
			if not rule_value is Dictionary:
				errors.append("%s has malformed override." % weather_owner)
				continue
			var rule: Dictionary = rule_value
			var block_id := String(rule.get("block_id", ""))
			var block_index := int(rule.get("index", -1))
			if block_id.is_empty() and block_index < 0:
				errors.append("%s override is missing block_id or index." % weather_owner)
			elif not block_id.is_empty() and not known_blocks.has(block_id):
				errors.append("%s references missing block %s." % [weather_owner, block_id])
			if String(rule.get("action", "")).is_empty() and not rule.has("action_pool"):
				errors.append("%s override must provide action or action_pool." % weather_owner)


static func _destination_errors(source: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for destination_id in source:
		var destination: Dictionary = source[destination_id]
		var tile: Variant = destination.get("global_tile", [])
		if not tile is Array or tile.size() < 2:
			errors.append("Destination %s has no global_tile." % String(destination_id))
		if String(destination.get("world_layer", "")).is_empty():
			errors.append("Destination %s has no world_layer." % String(destination_id))
		var fallback_id := String(destination.get("fallback_destination_id", ""))
		if not fallback_id.is_empty() and not source.has(fallback_id):
			errors.append("Destination %s references missing fallback %s." % [destination_id, fallback_id])
		var activity_tiles: Variant = destination.get("activity_tiles", [])
		if activity_tiles is Array:
			for activity_tile in activity_tiles:
				if not activity_tile is Array or activity_tile.size() < 2:
					errors.append("Destination %s has malformed activity tile." % [destination_id])
		else:
			errors.append("Destination %s has malformed activity_tiles." % [destination_id])
		var portal_chain: Variant = destination.get("portal_chain", [])
		if portal_chain is Array:
			for portal in portal_chain:
				if not portal is Dictionary or String(portal.get("target_layer", "")).is_empty():
					errors.append("Destination %s has malformed portal_chain." % String(destination_id))
	return errors


static func _has_shop_service(content, service_id: String) -> bool:
	if content.has_shop(service_id):
		return true
	for shop_id in content.shops:
		var shop: Dictionary = content.shops[shop_id]
		if String(shop.get("service_id", shop_id)) == service_id:
			return true
	return false


static func _service_worker_matches(content, service_id: String, npc_id: String) -> bool:
	for shop_id in content.shop_ids():
		var shop: Dictionary = content.get_shop(shop_id)
		if String(shop.get("service_id", shop_id)) != service_id:
			continue
		return String(shop.get("worker_npc_id", "")) == npc_id
	return false
