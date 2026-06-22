class_name MainWorldGuidance
extends RefCounted

const PrimaryActionTextBuilder = preload("res://scripts/ui/primary_action_text_builder.gd")
const MainContextActions = preload("res://scripts/main/main_context_actions.gd")
const PoiInteraction = preload("res://scripts/main/poi_interaction.gd")
const ObjectInteractionRules = preload("res://scripts/core/object_interaction_rules.gd")

const MAX_WORLD_ACTION_HINTS := 2
const COMPACT_WORLD_ACTION_HINTS := 1
const COMPACT_HINT_WIDTH := 720.0
const ACTION_HINT_WITH_NAME_MAX_CHARS := 22
const COMPACT_SELECTED_NAME_MAX_CHARS := 18
const UNSELECTED_HINT_OFFSETS := [20.0]
const HINT_FORWARD_CONE_DOT := 0.28
const HINT_FORWARD_BONUS := 28.0
const HINT_BEHIND_PENALTY := 92.0


static func sync(main, nearby_entities: Array) -> void:
	if not main.entities:
		return
	main.entities.set_quest_markers(_quest_target_markers(main))
	if main.auto_move_active:
		main.entities.set_action_hints({})
		return
	var hints: Dictionary = {}
	var unselected_index := 0
	var player_position: Vector2 = main.player.global_position if main.player else Vector2.ZERO
	var facing: Vector2 = (
		main.player.get_facing_direction()
		if main.player and main.player.has_method("get_facing_direction")
		else Vector2.ZERO
	)
	var max_hints := _max_world_action_hints(main)
	for entity in _hint_entities(
		nearby_entities, main.selected_target_id, player_position, facing, max_hints
	):
		var entity_id: String = entity.get_entity_id()
		var selected: bool = entity_id == main.selected_target_id
		var offset_y := 0.0
		if not selected:
			offset_y = _unselected_hint_offset(unselected_index)
			unselected_index += 1
		hints[entity_id] = {
			"text": _action_hint_text(main, entity, selected),
			"selected": selected,
			"offset_y": offset_y
		}
	main.entities.set_action_hints(hints)


static func _quest_target_markers(main) -> Dictionary:
	var markers: Dictionary = {}
	if not main.quests:
		return markers
	for objective in main.quests.get_active_objectives_data():
		if not objective is Dictionary:
			continue
		var target_id := String(objective.get("target_id", ""))
		if not target_id.is_empty():
			markers[target_id] = {"text": "Quest"}
	return markers


static func _hint_entities(
	nearby_entities: Array,
	selected_target_id: String,
	player_world_position: Vector2,
	facing_direction: Vector2,
	max_hints: int
) -> Array:
	var result := []
	var unselected := []
	for entity in nearby_entities:
		if entity.get_entity_id() == selected_target_id:
			result.append(entity)
			break
	for entity in nearby_entities:
		if entity.get_entity_id() == selected_target_id:
			continue
		unselected.append(entity)
	_sort_hint_candidates(unselected, player_world_position, facing_direction)
	for entity in unselected:
		if result.size() >= max_hints:
			break
		result.append(entity)
	return result


static func _max_world_action_hints(main) -> int:
	return _max_world_action_hints_for_width(_viewport_width(main))


static func _viewport_width(main) -> float:
	var viewport_width := 0.0
	if main and main.has_method("get_viewport_rect"):
		viewport_width = main.get_viewport_rect().size.x
	return viewport_width


static func _max_world_action_hints_for_width(viewport_width: float) -> int:
	if viewport_width > 0.0 and viewport_width < COMPACT_HINT_WIDTH:
		return COMPACT_WORLD_ACTION_HINTS
	return MAX_WORLD_ACTION_HINTS


static func _sort_hint_candidates(
	entities: Array, player_world_position: Vector2, facing_direction: Vector2
) -> void:
	entities.sort_custom(
		func(a, b) -> bool:
			return (
				_hint_score(a, player_world_position, facing_direction)
				< _hint_score(b, player_world_position, facing_direction)
			)
	)


static func _hint_score(entity, player_world_position: Vector2, facing_direction: Vector2) -> float:
	var delta: Vector2 = entity.global_position - player_world_position
	var score := delta.length()
	var facing := facing_direction.normalized()
	if facing.length() <= 0.01 or delta.length() <= 1.0:
		return score
	var alignment := facing.dot(delta.normalized())
	if alignment >= HINT_FORWARD_CONE_DOT:
		score -= HINT_FORWARD_BONUS * alignment
	else:
		score += HINT_BEHIND_PENALTY * (1.0 - maxf(alignment, -1.0))
	return score


static func _unselected_hint_offset(index: int) -> float:
	if index < 0 or index >= UNSELECTED_HINT_OFFSETS.size():
		return 0.0
	return UNSELECTED_HINT_OFFSETS[index]


static func _action_hint_text(main, entity, selected: bool) -> String:
	var action := _action_text(main, entity, selected)
	return _hint_text_for_width(action, entity.get_display_name(), selected, _viewport_width(main))


static func _hint_text_for_width(
	action: String, display_name: String, selected: bool, viewport_width: float
) -> String:
	if (
		selected
		and viewport_width > 0.0
		and viewport_width < COMPACT_HINT_WIDTH
		and display_name.length() <= COMPACT_SELECTED_NAME_MAX_CHARS
	):
		return display_name
	var full_hint := "%s %s" % [action, display_name]
	if full_hint.length() <= ACTION_HINT_WITH_NAME_MAX_CHARS:
		return full_hint
	return action


static func _action_text(main, entity, selected: bool) -> String:
	if selected:
		var preferred := MainContextActions.preferred_primary(main, entity)
		if not preferred.is_empty():
			return String(
				preferred.get("text", PrimaryActionTextBuilder.for_kind(entity.get_kind()))
			)
	if entity and ["container", "door"].has(entity.get_kind()):
		return ObjectInteractionRules.access_action_text(
			entity, main.chunks, main.condition_evaluator
		)
	if entity and entity.get_kind() == "poi":
		return PoiInteraction.primary_action_text(entity)
	return PrimaryActionTextBuilder.for_kind(entity.get_kind())
