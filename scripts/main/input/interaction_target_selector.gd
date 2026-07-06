class_name InteractionTargetSelector
extends RefCounted

const CENTER_CONE_DOT := 0.62
const FORWARD_CONE_DOT := 0.28
const FORWARD_PRIORITY_BONUS := 42.0
const CENTER_PRIORITY_BONUS := 84.0
const BEHIND_PENALTY := 220.0
const LATERAL_WEIGHT := 0.35


static func best_index(
	targets: Array, player_world_position: Vector2, facing_direction: Vector2
) -> int:
	if targets.is_empty():
		return -1
	var facing := facing_direction.normalized()
	var has_facing := facing.length() > 0.01
	var best_index := 0
	var best_score := INF
	for index in range(targets.size()):
		var entity = targets[index]
		if not entity:
			continue
		var score := _target_score(entity, player_world_position, facing, has_facing)
		if score < best_score:
			best_score = score
			best_index = index
	return best_index


static func select(
	targets: Array,
	selected_target_id: String,
	manual_target_locked: bool,
	player_world_position: Vector2,
	facing_direction: Vector2
) -> Dictionary:
	if targets.is_empty():
		return {"entity": null, "index": 0, "id": "", "manual": false}
	var selected_index := _index_of_target_id(targets, selected_target_id)
	if selected_index >= 0 and manual_target_locked:
		var manual_entity = targets[selected_index]
		return {
			"entity": manual_entity,
			"index": selected_index,
			"id": manual_entity.get_entity_id(),
			"manual": true
		}
	var index := best_index(targets, player_world_position, facing_direction)
	if index < 0:
		index = 0
	var entity = targets[index]
	return {"entity": entity, "index": index, "id": entity.get_entity_id(), "manual": false}


static func next_id(
	targets: Array,
	selected_target_id: String,
	fallback_index: int,
	player_world_position: Vector2,
	facing_direction: Vector2
) -> String:
	if targets.is_empty():
		return ""
	var ranked := ranked_targets(targets, player_world_position, facing_direction)
	var current_index := _index_of_target_id(ranked, selected_target_id)
	if current_index < 0:
		current_index = clampi(fallback_index, 0, ranked.size() - 1)
	return ranked[(current_index + 1) % ranked.size()].get_entity_id()


static func ranked_targets(
	targets: Array, player_world_position: Vector2, facing_direction: Vector2
) -> Array:
	var ranked := targets.duplicate()
	var facing := facing_direction.normalized()
	var has_facing := facing.length() > 0.01
	ranked.sort_custom(
		func(a, b) -> bool:
			return (
				_target_score(a, player_world_position, facing, has_facing)
				< _target_score(b, player_world_position, facing, has_facing)
			)
	)
	return ranked


static func _index_of_target_id(targets: Array, entity_id: String) -> int:
	if entity_id.is_empty():
		return -1
	for index in range(targets.size()):
		if targets[index].get_entity_id() == entity_id:
			return index
	return -1


static func _target_score(
	entity, player_world_position: Vector2, facing: Vector2, has_facing: bool
) -> float:
	var delta: Vector2 = entity.global_position - player_world_position
	var score := delta.length()
	if has_facing and delta.length() > 1.0:
		var direction := delta.normalized()
		var alignment := facing.dot(direction)
		var lateral := absf(facing.cross(direction)) * delta.length()
		score += lateral * LATERAL_WEIGHT
		if alignment >= CENTER_CONE_DOT:
			score -= FORWARD_PRIORITY_BONUS + CENTER_PRIORITY_BONUS * alignment
		elif alignment >= FORWARD_CONE_DOT:
			score -= FORWARD_PRIORITY_BONUS * alignment
		else:
			score += BEHIND_PENALTY * (1.0 - maxf(alignment, -1.0))
	return score
