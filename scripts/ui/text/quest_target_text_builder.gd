class_name QuestTargetTextBuilder
extends RefCounted


static func directions(quest_manager, entity_manager, player_world_position: Vector2) -> String:
	if not quest_manager or not entity_manager:
		return "none"
	var lines: Array[String] = []
	for objective in quest_manager.get_active_objectives_data():
		var target_id := String(objective.get("target_id", ""))
		if target_id.is_empty():
			continue
		var entity = entity_manager.get_entity(target_id)
		if not entity:
			continue
		lines.append(
			(
				"%s: %s %s"
				% [
					String(objective.get("title", "Quest")),
					entity_manager.get_navigation_hint(player_world_position, entity),
					entity.get_display_name()
				]
			)
		)
	return "none" if lines.is_empty() else "\n".join(lines)
