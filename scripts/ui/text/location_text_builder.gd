class_name LocationTextBuilder
extends RefCounted


static func names(discovered_locations: Dictionary, content) -> String:
	var ids := _sorted_location_ids(discovered_locations)
	if ids.is_empty():
		return "none"
	var result: Array[String] = []
	for location_id in ids:
		var location: Dictionary = content.get_location(location_id)
		result.append(String(location.get("name", location_id)))
	return ", ".join(result)


static func details(discovered_locations: Dictionary, content) -> String:
	var ids := _sorted_location_ids(discovered_locations)
	if ids.is_empty():
		return "none"
	var result: Array[String] = []
	for location_id in ids:
		var location: Dictionary = content.get_location(location_id)
		var name := String(location.get("name", location_id))
		var region := String(location.get("region", ""))
		var description := String(location.get("description", ""))
		var line := name
		if not region.is_empty():
			line += " - %s" % region
		if not description.is_empty():
			line += "\n%s" % description
		result.append(line)
	return "\n\n".join(result)


static func _sorted_location_ids(discovered_locations: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for location_id in discovered_locations:
		var key := String(location_id)
		if not key.is_empty():
			ids.append(key)
	ids.sort()
	return ids
