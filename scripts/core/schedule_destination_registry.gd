class_name ScheduleDestinationRegistry
extends RefCounted

var destinations: Dictionary = {}
var portals_by_layer: Dictionary = {}


func load_data(source: Dictionary) -> void:
	destinations.clear()
	for key in source:
		var value: Variant = source[key]
		if value is Dictionary and not String(key).is_empty():
			destinations[String(key)] = value.duplicate(true)


func load_portals(entries: Array) -> void:
	portals_by_layer.clear()
	for value in entries:
		if not value is Dictionary or not value.has("portal"):
			continue
		var source_layer := String(value.get("world_layer", "surface"))
		var portal: Variant = value.get("portal", {})
		if source_layer.is_empty() or not portal is Dictionary:
			continue
		var target_layer := String(portal.get("target_layer", ""))
		var source_tile: Variant = value.get("global_tile", [])
		var target_tile: Variant = portal.get("target_tile", [])
		if target_layer.is_empty() or not _valid_tile(source_tile) or not _valid_tile(target_tile):
			continue
		if not portals_by_layer.has(source_layer):
			portals_by_layer[source_layer] = []
		portals_by_layer[source_layer].append(
			{
				"id": String(value.get("id", "")),
				"from_layer": source_layer,
				"from_tile": [int(source_tile[0]), int(source_tile[1])],
				"to_layer": target_layer,
				"to_tile": [int(target_tile[0]), int(target_tile[1])]
			}
		)


func get_destination(destination_id: String) -> Dictionary:
	return destinations.get(destination_id, {}).duplicate(true)


func resolve_portal_chain(source_layer: String, destination: Dictionary) -> Array:
	var authored: Variant = destination.get("portal_chain", [])
	if destination.has("portal_chain") and authored is Array and not authored.is_empty():
		return authored.duplicate(true)
	var target_layer := String(destination.get("world_layer", source_layer))
	if source_layer == target_layer:
		return []
	return _find_portal_chain(source_layer, target_layer)


func resolve(binding: Dictionary, destination_key: String, day: int, block_index: int) -> Dictionary:
	var destination_id := destination_key
	if destination_key == "home" or destination_key == "home.sleep" or destination_key == "home.meal":
		destination_id = String(binding.get("home_destination_id", ""))
	elif destination_key == "primary_workplace":
		destination_id = String(binding.get("work_destination_id", ""))
	elif destination_key == "patrol":
		destination_id = String(binding.get("patrol_destination_id", binding.get("work_destination_id", "")))
	elif destination_key == "visit":
		var visit_value: Variant = binding.get("visit_destination_ids", [])
		if visit_value is Array:
			var visits: Array = visit_value
			var selected_visit: Variant = ScheduleResolver.choose_deterministic(
				visits, String(binding.get("npc_id", "")), day, block_index
			)
			destination_id = String(selected_visit if selected_visit != null else "")
	elif destination_key == "workplace_break":
		destination_id = String(binding.get("work_break_destination_id", binding.get("work_destination_id", "")))
	elif destination_key == "town_leisure":
		var leisure_value: Variant = binding.get("leisure_destination_ids", [])
		if leisure_value is Array:
			var leisure: Array = leisure_value
			var selected: Variant = ScheduleResolver.choose_deterministic(leisure, String(binding.get("npc_id", "")), day, block_index)
			destination_id = String(selected if selected != null else "")
	var destination: Dictionary = get_destination(destination_id)
	if destination.is_empty():
		return {}
	destination["id"] = destination_id
	if not destination.has("portal_chain"):
		destination["portal_chain"] = []
	return destination


func validate() -> Array[String]:
	var errors: Array[String] = []
	for destination_id in destinations:
		var destination: Dictionary = destinations[destination_id]
		var tile: Variant = destination.get("global_tile", [])
		if not tile is Array or tile.size() < 2:
			errors.append("Destination %s has no global_tile." % String(destination_id))
		if String(destination.get("world_layer", "")).is_empty():
			errors.append("Destination %s has no world_layer." % String(destination_id))
	return errors


func _find_portal_chain(source_layer: String, target_layer: String) -> Array:
	var frontier: Array[String] = [source_layer]
	var previous: Dictionary = {source_layer: {"layer": "", "portal": {}}}
	var read_index := 0
	while read_index < frontier.size():
		var layer := frontier[read_index]
		read_index += 1
		if layer == target_layer:
			break
		for portal_value in portals_by_layer.get(layer, []):
			var portal: Dictionary = portal_value
			var next_layer := String(portal.get("to_layer", ""))
			if next_layer.is_empty() or previous.has(next_layer):
				continue
			previous[next_layer] = {"layer": layer, "portal": portal.duplicate(true)}
			frontier.append(next_layer)
	if not previous.has(target_layer):
		return []
	var chain: Array = []
	var current := target_layer
	while current != source_layer:
		var link: Dictionary = previous[current]
		chain.push_front(link["portal"])
		current = String(link["layer"])
	return chain


func _valid_tile(value: Variant) -> bool:
	return value is Array and value.size() >= 2 and _is_number(value[0]) and _is_number(value[1])


func _is_number(value: Variant) -> bool:
	return value is int or value is float
