class_name PoiInteraction
extends RefCounted


class InteractionContext:
	var entity
	var world_state
	var hud
	var apply_effect: Callable
	var event_bus
	var active_choices: Dictionary
	var condition_evaluator

	func _init(
		p_entity,
		p_world_state,
		p_hud,
		p_apply_effect: Callable,
		p_event_bus,
		p_active_choices: Dictionary,
		p_condition_evaluator = null
	) -> void:
		entity = p_entity
		world_state = p_world_state
		hud = p_hud
		apply_effect = p_apply_effect
		event_bus = p_event_bus
		active_choices = p_active_choices
		condition_evaluator = p_condition_evaluator


static func detail(entity) -> String:
	var poi_type := String(entity.data.get("poi_type", "POI"))
	var summary := String(entity.data.get("summary", ""))
	return poi_type if summary.is_empty() else "%s: %s" % [poi_type, summary]


static func primary_action_text(entity) -> String:
	if not entity:
		return "Use"
	var system_tab := String(entity.data.get("system_tab", ""))
	var shop_id := String(entity.data.get("shop_id", ""))
	if system_tab == "trade" or not shop_id.is_empty():
		return "Trade"
	if not system_tab.is_empty():
		return "Open"
	return "Use"


static func available_actions(entity, condition_evaluator) -> Array[Dictionary]:
	return _available_actions(entity, condition_evaluator)


static func interact(context: InteractionContext) -> void:
	if not context:
		return
	context.active_choices.clear()
	_discover_or_visit(context.entity, context.world_state, context.apply_effect, context.event_bus)
	var shop_id := String(context.entity.data.get("shop_id", ""))
	var system_tab := String(context.entity.data.get("system_tab", ""))
	if system_tab.is_empty() and not shop_id.is_empty():
		system_tab = "trade"
	if (
		not system_tab.is_empty()
		and context.hud
		and context.hud.has_method("show_systems_panel")
	):
		context.hud.show_systems_panel(system_tab)
		return
	_show_content(context)


static func inspect(context: InteractionContext) -> void:
	if not context:
		return
	context.active_choices.clear()
	_discover_or_visit(context.entity, context.world_state, context.apply_effect, context.event_bus)
	_show_content(context)


static func _show_content(context: InteractionContext) -> void:
	var actions := _available_actions(context.entity, context.condition_evaluator)
	for action in actions:
		context.active_choices[String(action.get("id", ""))] = action
	if context.hud:
		context.hud.show_content_card(
			context.entity.get_display_name(), _body_text(context.entity), actions, "place"
		)


static func _body_text(entity) -> String:
	var description := String(entity.data.get("description", ""))
	return description if not description.is_empty() else "There is nothing notable here yet."


static func _discover_or_visit(entity, world_state, apply_effect: Callable, event_bus) -> void:
	var location_id := String(entity.data.get("location_id", ""))
	var discovered := false
	if not location_id.is_empty() and world_state:
		discovered = world_state.discover_location(location_id)
	if discovered:
		_apply_effects(entity.data.get("effects_on_discover", []), apply_effect)
		if event_bus:
			event_bus.post_message("Discovered %s." % entity.get_display_name())
	elif event_bus:
		event_bus.post_message("Visited %s." % entity.get_display_name())


static func _apply_effects(effects_value: Variant, apply_effect: Callable) -> void:
	if not apply_effect.is_valid():
		return
	for effect in _array_field(effects_value):
		if effect is Dictionary:
			apply_effect.call(effect)


static func _available_actions(entity, condition_evaluator) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action in _array_field(entity.data.get("actions", [])):
		if not action is Dictionary:
			continue
		var conditions := _array_field(action.get("conditions", []))
		if condition_evaluator and not condition_evaluator.evaluate_all(conditions):
			continue
		result.append(action.duplicate(true))
	return result


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
