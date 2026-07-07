class_name MainContextActions
extends RefCounted

const PoiInteraction = preload("res://scripts/main/actions/poi_interaction.gd")
const MainInventoryTransfer = preload("res://scripts/main/actions/main_inventory_transfer.gd")
const PickpocketRules = preload("res://scripts/core/pickpocket_rules.gd")


class ActionContext:
	var active_content_choices: Dictionary
	var condition_evaluator
	var content
	var dialogues
	var event_bus
	var hud
	var inventory_transfer_context
	var player
	var world_state
	var _apply_effect: Callable
	var _get_nearby_entity: Callable
	var _interact_npc: Callable
	var _refresh_hud: Callable
	var _update_nearby: Callable

	func _init(main) -> void:
		active_content_choices = main.active_content_choices
		condition_evaluator = main.condition_evaluator
		content = main.content
		dialogues = main.dialogues
		event_bus = main.event_bus
		hud = main.hud
		inventory_transfer_context = MainInventoryTransfer.context(main)
		player = main.player
		world_state = main.world_state
		_apply_effect = Callable(main, "apply_effect")
		_get_nearby_entity = Callable(main, "_get_nearby_entity")
		_interact_npc = Callable(main, "_interact_npc")
		_refresh_hud = Callable(main, "_refresh_hud")
		_update_nearby = Callable(main, "_update_nearby")


static func context(main) -> ActionContext:
	return ActionContext.new(main)


static func build(ctx: ActionContext, entity) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if entity and entity.get_kind() == "poi":
		for action in PoiInteraction.available_actions(entity, ctx.condition_evaluator):
			actions.append(
				{"id": "poi:%s" % String(action.get("id", "")), "text": action.get("text", "")}
			)
		if _poi_should_offer_inspect(ctx, entity):
			actions.append({"id": "inspect:%s" % entity.get_entity_id(), "text": "Inspect"})
	if entity and entity.get_kind() == "npc":
		var npc: Dictionary = _npc_for_entity(ctx, entity)
		if ctx.player.is_sneaking and PickpocketRules.is_pickpocket_target(entity):
			actions.append({"id": "pickpocket:%s" % entity.get_entity_id(), "text": "Pickpocket"})
		var shop_id := String(npc.get("shop_id", ""))
		if not shop_id.is_empty():
			actions.append({"id": "trade:%s" % shop_id, "text": "Trade"})
			if not String(npc.get("dialogue_id", "")).is_empty():
				actions.append({"id": "talk:%s" % String(npc.get("dialogue_id", "")), "text": "Talk"})
		var line: Dictionary = _preview_dialogue_line(ctx, npc, entity)
		if not _array_field(line.get("effects", [])).is_empty():
			actions.append(
				{"id": "line:%s" % String(line.get("line_id", "")), "text": _line_action_text(line)}
			)
		for choice in _effectful_dialogue_choices(ctx, npc, entity):
			actions.append(
				{"id": "dialogue:%s" % String(choice.get("id", "")), "text": choice.get("text", "")}
			)
	return actions


static func preferred_primary(ctx: ActionContext, entity) -> Dictionary:
	var actions := build(ctx, entity)
	for action in actions:
		var action_id := String(action.get("id", ""))
		if action_id.begins_with("line:"):
			return action
	if entity and entity.get_kind() == "npc":
		return _first_action_with_prefix(actions, "trade:")
	if (
		entity
		and entity.get_kind() == "poi"
		and bool(entity.data.get("prefer_primary_action", true))
		and _poi_has_been_discovered(ctx, entity)
	):
		return _single_poi_action(actions)
	return {}


static func secondary(ctx: ActionContext, entity) -> Array[Dictionary]:
	var actions := build(ctx, entity)
	var primary := preferred_primary(ctx, entity)
	var primary_id := String(primary.get("id", ""))
	if primary_id.is_empty():
		return actions
	var result: Array[Dictionary] = []
	for action in actions:
		if String(action.get("id", "")) == primary_id:
			continue
		result.append(action)
	return result


static func handle(ctx: ActionContext, action_id: String) -> void:
	var parsed := _parse_action_id(action_id)
	match String(parsed.get("kind", "")):
		"poi":
			_handle_poi_action_selected(ctx, String(parsed.get("id", "")))
		"dialogue":
			_handle_dialogue_action_selected(ctx, String(parsed.get("id", "")))
		"line":
			_handle_dialogue_line_action_selected(ctx, String(parsed.get("id", "")))
		"trade":
			_handle_trade_action_selected(ctx, String(parsed.get("id", "")))
		"talk":
			_handle_talk_action_selected(ctx, String(parsed.get("id", "")))
		"inspect":
			_handle_poi_inspect_selected(ctx, String(parsed.get("id", "")))
		"pickpocket":
			_handle_pickpocket_selected(ctx, String(parsed.get("id", "")))
		_:
			ctx.event_bus.post_message("Unknown action.")


static func _handle_poi_action_selected(ctx: ActionContext, action_id: String) -> void:
	var entity = ctx._get_nearby_entity.call()
	if not entity or entity.get_kind() != "poi":
		ctx.event_bus.post_message("No place action available.")
		return
	for action in PoiInteraction.available_actions(entity, ctx.condition_evaluator):
		if String(action.get("id", "")) == action_id:
			_apply_poi_action(ctx, action)
			return
	ctx.event_bus.post_message("That action is no longer available.")
	ctx._refresh_hud.call()


static func _apply_poi_action(ctx: ActionContext, action: Dictionary) -> void:
	_apply_choice_action(ctx, action)


static func _handle_dialogue_action_selected(ctx: ActionContext, choice_id: String) -> void:
	var entity = ctx._get_nearby_entity.call()
	if not entity or entity.get_kind() != "npc":
		ctx.event_bus.post_message("No dialogue action available.")
		return
	var npc: Dictionary = _npc_for_entity(ctx, entity)
	for choice in _effectful_dialogue_choices(ctx, npc, entity):
		if String(choice.get("id", "")) == choice_id:
			_apply_choice_action(ctx, choice)
			return
	ctx.event_bus.post_message("That choice is no longer available.")
	ctx._refresh_hud.call()


static func _handle_dialogue_line_action_selected(ctx: ActionContext, line_id: String) -> void:
	var entity = ctx._get_nearby_entity.call()
	if not entity or entity.get_kind() != "npc":
		ctx.event_bus.post_message("No dialogue action available.")
		return
	var npc: Dictionary = _npc_for_entity(ctx, entity)
	var line: Dictionary = _preview_dialogue_line(ctx, npc, entity)
	if String(line.get("line_id", "")) != line_id:
		ctx.event_bus.post_message("That action is no longer available.")
		ctx._refresh_hud.call()
		return
	_apply_line_action(ctx, line)


static func _handle_trade_action_selected(ctx: ActionContext, shop_id: String) -> void:
	if shop_id.is_empty() or not ctx.hud:
		ctx.event_bus.post_message("No trader selected.")
		return
	ctx.active_content_choices.clear()
	ctx.hud.hide_content_card()
	ctx.hud.show_systems_panel("trade")
	ctx.event_bus.post_message("Trading.")
	ctx._refresh_hud.call()


static func _handle_talk_action_selected(ctx: ActionContext, _dialogue_id: String) -> void:
	var entity = ctx._get_nearby_entity.call()
	if not entity or entity.get_kind() != "npc":
		ctx.event_bus.post_message("No one to talk to.")
		return
	ctx._interact_npc.call(entity)


static func _handle_poi_inspect_selected(ctx: ActionContext, _entity_id: String) -> void:
	var entity = ctx._get_nearby_entity.call()
	if not entity or entity.get_kind() != "poi":
		ctx.event_bus.post_message("No place to inspect.")
		return
	PoiInteraction.inspect(
		PoiInteraction.InteractionContext.new(
			entity,
			ctx.world_state,
			ctx.hud,
			ctx._apply_effect,
			ctx.event_bus,
			ctx.active_content_choices,
			ctx.condition_evaluator
		)
	)


static func _handle_pickpocket_selected(ctx: ActionContext, entity_id: String) -> void:
	var entity = ctx._get_nearby_entity.call()
	if not entity or entity.get_entity_id() != entity_id:
		ctx.event_bus.post_message("No pickpocket target nearby.")
		ctx._refresh_hud.call()
		return
	var result := PickpocketRules.access_result(
		entity, ctx.player.global_position, ctx.player.is_sneaking
	)
	if not bool(result.get("allowed", false)):
		ctx.event_bus.post_message(String(result.get("reason", "Cannot pickpocket.")))
		ctx._refresh_hud.call()
		return
	MainInventoryTransfer.open_pickpocket(ctx.inventory_transfer_context, entity)


static func _apply_choice_action(ctx: ActionContext, action: Dictionary) -> void:
	ctx.active_content_choices.clear()
	if ctx.hud:
		ctx.hud.hide_content_card()
	var result: Dictionary = ctx.dialogues.apply_choice(action)
	var response := String(result.get("response", ""))
	if response.is_empty():
		ctx.event_bus.post_message(String(result.get("text", "Done.")))
	else:
		ctx.event_bus.post_message(response)
	ctx._update_nearby.call()


static func _apply_line_action(ctx: ActionContext, line: Dictionary) -> void:
	ctx.active_content_choices.clear()
	if ctx.hud:
		ctx.hud.hide_content_card()
	for effect in _array_field(line.get("effects", [])):
		if effect is Dictionary:
			ctx._apply_effect.call(effect)
	var response := String(line.get("text", "Done."))
	if not response.is_empty():
		ctx.event_bus.post_message(response)
	ctx._update_nearby.call()


static func _effectful_dialogue_choices(
	ctx: ActionContext, npc: Dictionary, entity
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if npc.is_empty():
		return result
	var line: Dictionary = _preview_dialogue_line(ctx, npc, entity)
	for choice in _array_field(line.get("choices", [])):
		if not choice is Dictionary:
			continue
		if _array_field(choice.get("effects", [])).is_empty():
			continue
		result.append(choice)
	return result


static func _preview_dialogue_line(
	ctx: ActionContext, npc: Dictionary, entity
) -> Dictionary:
	if npc.is_empty():
		return {}
	return ctx.dialogues.preview_dialogue(
		String(npc.get("dialogue_id", "")), String(npc.get("name", entity.get_display_name()))
	)


static func _line_action_text(line: Dictionary) -> String:
	for effect in _array_field(line.get("effects", [])):
		if not effect is Dictionary:
			continue
		if String(effect.get("type", "")) == "complete_quest":
			return "Turn In"
	return "Continue"


static func _npc_for_entity(ctx: ActionContext, entity) -> Dictionary:
	if not entity:
		return {}
	return ctx.content.get_npc(String(entity.data.get("npc_id", "")))


static func _parse_action_id(action_id: String) -> Dictionary:
	var delimiter := action_id.find(":")
	if delimiter < 0:
		return {"kind": "", "id": action_id}
	return {"kind": action_id.substr(0, delimiter), "id": action_id.substr(delimiter + 1)}


static func _single_action_with_prefix(actions: Array[Dictionary], prefix: String) -> Dictionary:
	if actions.size() != 1:
		return {}
	var action: Dictionary = actions[0]
	return action if String(action.get("id", "")).begins_with(prefix) else {}


static func _single_poi_action(actions: Array[Dictionary]) -> Dictionary:
	var result := {}
	for action in actions:
		if not String(action.get("id", "")).begins_with("poi:"):
			continue
		if not result.is_empty():
			return {}
		result = action
	return result


static func _first_action_with_prefix(actions: Array[Dictionary], prefix: String) -> Dictionary:
	for action in actions:
		if String(action.get("id", "")).begins_with(prefix):
			return action
	return {}


static func _poi_has_been_discovered(ctx: ActionContext, entity) -> bool:
	var location_id := String(entity.data.get("location_id", ""))
	return location_id.is_empty() or ctx.world_state.discovered_locations.has(location_id)


static func _poi_should_offer_inspect(ctx: ActionContext, entity) -> bool:
	if String(entity.data.get("description", "")).is_empty():
		return false
	if not String(entity.data.get("shop_id", "")).is_empty():
		return true
	if not String(entity.data.get("system_tab", "")).is_empty():
		return true
	return (
		_poi_has_been_discovered(ctx, entity)
		and not PoiInteraction.available_actions(entity, ctx.condition_evaluator).is_empty()
	)


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
