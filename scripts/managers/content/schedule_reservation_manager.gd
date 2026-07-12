class_name ScheduleReservationManager
extends RefCounted

var reservations: Dictionary = {}


func reserve(anchor_id: String, npc_id: String, absolute_minute: int, ttl_minutes: int = 60) -> bool:
	if anchor_id.is_empty() or npc_id.is_empty():
		return false
	prune(absolute_minute)
	var current: Dictionary = reservations.get(anchor_id, {})
	if not current.is_empty() and String(current.get("npc_id", "")) != npc_id:
		return false
	reservations[anchor_id] = {
		"npc_id": npc_id,
		"expires_at": absolute_minute + maxi(1, ttl_minutes)
	}
	return true


func release_for_npc(npc_id: String) -> void:
	for anchor_id in reservations.keys():
		if String(reservations[anchor_id].get("npc_id", "")) == npc_id:
			reservations.erase(anchor_id)


func is_reserved(anchor_id: String, by_npc_id: String = "") -> bool:
	if not reservations.has(anchor_id):
		return false
	return by_npc_id.is_empty() or String(reservations[anchor_id].get("npc_id", "")) != by_npc_id


func prune(absolute_minute: int) -> void:
	for anchor_id in reservations.keys():
		if int(reservations[anchor_id].get("expires_at", 0)) <= absolute_minute:
			reservations.erase(anchor_id)


func get_save_data() -> Dictionary:
	return reservations.duplicate(true)


func load_save_data(data: Dictionary) -> void:
	reservations.clear()
	for anchor_id in data:
		var value: Variant = data[anchor_id]
		if value is Dictionary and not String(anchor_id).is_empty():
			reservations[String(anchor_id)] = value.duplicate(true)
