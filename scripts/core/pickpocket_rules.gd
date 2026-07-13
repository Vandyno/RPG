class_name PickpocketRules
extends RefCounted

const ActorRules = preload("res://scripts/core/actor_rules.gd")
const NpcPerception = preload("res://scripts/core/npc_perception.gd")


static func is_pickpocket_target(entity) -> bool:
	if not entity:
		return false
	return ActorRules.can_pickpocket_data(entity.data)


static func access_result(
	entity,
	player_position: Vector2,
	is_sneaking: bool,
	perception_manager = null,
	player_layer: String = "surface"
) -> Dictionary:
	if not is_pickpocket_target(entity):
		return {"allowed": false, "reason": "No pockets to pick."}
	if not is_sneaking:
		return {"allowed": false, "reason": "Need to be sneaking."}
	if can_see_player(entity, player_position, is_sneaking, perception_manager, player_layer):
		return {"allowed": false, "reason": "%s can see you." % entity.get_display_name()}
	return {"allowed": true, "reason": ""}


static func can_see_player(
	entity,
	player_position: Vector2,
	is_sneaking: bool = false,
	perception_manager = null,
	player_layer: String = "surface"
) -> bool:
	if not entity:
		return false
	var context := {"target_sneaking": is_sneaking}
	if perception_manager and perception_manager.has_method("can_see_position"):
		return perception_manager.can_see_position(entity, player_position, player_layer, context)
	return NpcPerception.can_see_position(entity, player_position, player_layer, null, context)


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
