class_name PickpocketRules
extends RefCounted


static func is_pickpocket_target(entity) -> bool:
	if not entity:
		return false
	if not ["npc", "enemy"].has(entity.get_kind()):
		return false
	var profile: Variant = entity.data.get("character_profile", {})
	return profile is Dictionary and not profile.is_empty()


static func access_result(entity, player_position: Vector2, is_sneaking: bool) -> Dictionary:
	if not is_pickpocket_target(entity):
		return {"allowed": false, "reason": "No pockets to pick."}
	if not is_sneaking:
		return {"allowed": false, "reason": "Need to be sneaking."}
	if can_see_player(entity, player_position):
		return {"allowed": false, "reason": "%s can see you." % entity.get_display_name()}
	return {"allowed": true, "reason": ""}


static func can_see_player(entity, player_position: Vector2) -> bool:
	if not entity:
		return false
	var to_player: Vector2 = player_position - entity.global_position
	if to_player.length() <= 0.001:
		return true
	var facing := facing_direction(entity)
	if facing.length() <= 0.001:
		return false
	return facing.normalized().dot(to_player.normalized()) > 0.0


static func facing_direction(entity) -> Vector2:
	if not entity:
		return Vector2.DOWN
	var value: Variant = entity.data.get("facing_direction", [])
	if value is Array and value.size() >= 2 and _is_number(value[0]) and _is_number(value[1]):
		var vector := Vector2(float(value[0]), float(value[1]))
		if vector.length() > 0.001:
			return vector.normalized()
	match String(entity.data.get("facing", "")).to_lower():
		"north":
			return Vector2.UP
		"south":
			return Vector2.DOWN
		"east":
			return Vector2.RIGHT
		"west":
			return Vector2.LEFT
	return Vector2.DOWN


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
