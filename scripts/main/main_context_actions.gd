class_name MainContextActions
extends RefCounted

const PoiInteraction = preload("res://scripts/main/poi_interaction.gd")


static func build(main, entity) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if entity and entity.get_kind() == "poi":
		for action in PoiInteraction.available_actions_for_main(entity, main):
			actions.append(
				{"id": "poi:%s" % String(action.get("id", "")), "text": action.get("text", "")}
			)
		if _poi_should_offer_inspect(main, entity):
			actions.append({"id": "inspect:%s" % entity.get_entity_id(), "text": "Inspect"})
	if entity and entity.get_kind() == "npc":
		var npc: Dictionary = _npc_for_entity(main, entity)
		var shop_id := String(npc.get("shop_id", ""))
		if not shop_id.is_empty():
			actions.append({"id": "trade:%s" % shop_id, "text": "Trade"})
			if not String(npc.get("dialogue_id", "")).is_empty():
				actions.append({"id": "talk:%s" % String(npc.get("dialogue_id", "")), "text": "Talk"})
		var line: Dictionary = _preview_dialogue_line(main, npc, entity)
		if not _array_field(line.get("effects", [])).is_empty():
			actions.append(
				{"id": "line:%s" % String(line.get("line_id", "")), "text": _line_action_text(line)}
			)
		for choice in _effectful_dialogue_choices(main, npc, entity):
			actions.append(
				{"id": "dialogue:%s" % String(choice.get("id", "")), "text": choice.get("text", "")}
			)
	return actions


static func preferred_primary(main, entity) -> Dictionary:
	var actions := build(main, entity)
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
		and _poi_has_been_discovered(main, entity)
	):
		return _single_poi_action(actions)
	return {}


static func secondary(main, entity) -> Array[Dictionary]:
	var actions := build(main, entity)
	var primary := preferred_primary(main, entity)
	var primary_id := String(primary.get("id", ""))
	if primary_id.is_empty():
		return actions
	var result: Array[Dictionary] = []
	for action in actions:
		if String(action.get("id", "")) == primary_id:
			continue
		result.append(action)
	return result


static func handle(main, action_id: String) -> void:
	var parsed := _parse_action_id(action_id)
	match String(parsed.get("kind", "")):
		"poi":
			_handle_poi_action_selected(main, String(parsed.get("id", "")))
		"dialogue":
			_handle_dialogue_action_selected(main, String(parsed.get("id", "")))
		"line":
			_handle_dialogue_line_action_selected(main, String(parsed.get("id", "")))
		"trade":
			_handle_trade_action_selected(main, String(parsed.get("id", "")))
		"talk":
			_handle_talk_action_selected(main, String(parsed.get("id", "")))
		"inspect":
			_handle_poi_inspect_selected(main, String(parsed.get("id", "")))
		_:
			main.event_bus.post_message("Unknown action.")


static func _handle_poi_action_selected(main, action_id: String) -> void:
	var entity = main._get_nearby_entity()
	if not entity or entity.get_kind() != "poi":
		main.event_bus.post_message("No place action available.")
		return
	for action in PoiInteraction.available_actions_for_main(entity, main):
		if String(action.get("id", "")) == action_id:
			_apply_poi_action(main, action)
			return
	main.event_bus.post_message("That action is no longer available.")
	main._refresh_hud()


static func _apply_poi_action(main, action: Dictionary) -> void:
	_apply_choice_action(main, action)


static func _handle_dialogue_action_selected(main, choice_id: String) -> void:
	var entity = main._get_nearby_entity()
	if not entity or entity.get_kind() != "npc":
		main.event_bus.post_message("No dialogue action available.")
		return
	var npc: Dictionary = _npc_for_entity(main, entity)
	for choice in _effectful_dialogue_choices(main, npc, entity):
		if String(choice.get("id", "")) == choice_id:
			_apply_choice_action(main, choice)
			return
	main.event_bus.post_message("That choice is no longer available.")
	main._refresh_hud()


static func _handle_dialogue_line_action_selected(main, line_id: String) -> void:
	var entity = main._get_nearby_entity()
	if not entity or entity.get_kind() != "npc":
		main.event_bus.post_message("No dialogue action available.")
		return
	var npc: Dictionary = _npc_for_entity(main, entity)
	var line: Dictionary = _preview_dialogue_line(main, npc, entity)
	if String(line.get("line_id", "")) != line_id:
		main.event_bus.post_message("That action is no longer available.")
		main._refresh_hud()
		return
	_apply_line_action(main, line)


static func _handle_trade_action_selected(main, shop_id: String) -> void:
	if shop_id.is_empty() or not main.hud:
		main.event_bus.post_message("No trader selected.")
		return
	main.active_content_choices.clear()
	main.hud.hide_content_card()
	main.hud.show_systems_panel("trade")
	main.event_bus.post_message("Trading.")
	main._refresh_hud()


static func _handle_talk_action_selected(main, _dialogue_id: String) -> void:
	var entity = main._get_nearby_entity()
	if not entity or entity.get_kind() != "npc":
		main.event_bus.post_message("No one to talk to.")
		return
	main._interact_npc(entity)


static func _handle_poi_inspect_selected(main, _entity_id: String) -> void:
	var entity = main._get_nearby_entity()
	if not entity or entity.get_kind() != "poi":
		main.event_bus.post_message("No place to inspect.")
		return
	PoiInteraction.inspect_with_main(entity, main)


static func _apply_choice_action(main, action: Dictionary) -> void:
	main.active_content_choices.clear()
	if main.hud:
		main.hud.hide_content_card()
	var result: Dictionary = main.dialogues.apply_choice(action)
	var response := String(result.get("response", ""))
	if response.is_empty():
		main.event_bus.post_message(String(result.get("text", "Done.")))
	else:
		main.event_bus.post_message(response)
	main._update_nearby()


static func _apply_line_action(main, line: Dictionary) -> void:
	main.active_content_choices.clear()
	if main.hud:
		main.hud.hide_content_card()
	for effect in _array_field(line.get("effects", [])):
		if effect is Dictionary:
			main.apply_effect(effect)
	var response := String(line.get("text", "Done."))
	if not response.is_empty():
		main.event_bus.post_message(response)
	main._update_nearby()


static func _effectful_dialogue_choices(main, npc: Dictionary, entity) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if npc.is_empty():
		return result
	var line: Dictionary = _preview_dialogue_line(main, npc, entity)
	for choice in _array_field(line.get("choices", [])):
		if not choice is Dictionary:
			continue
		if _array_field(choice.get("effects", [])).is_empty():
			continue
		result.append(choice)
	return result


static func _preview_dialogue_line(main, npc: Dictionary, entity) -> Dictionary:
	if npc.is_empty():
		return {}
	return main.dialogues.preview_dialogue(
		String(npc.get("dialogue_id", "")), String(npc.get("name", entity.get_display_name()))
	)


static func _line_action_text(line: Dictionary) -> String:
	for effect in _array_field(line.get("effects", [])):
		if not effect is Dictionary:
			continue
		if String(effect.get("type", "")) == "complete_quest":
			return "Turn In"
	return "Continue"


static func _npc_for_entity(main, entity) -> Dictionary:
	if not entity:
		return {}
	return main.content.get_npc(String(entity.data.get("npc_id", "")))


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


static func _poi_has_been_discovered(main, entity) -> bool:
	var location_id := String(entity.data.get("location_id", ""))
	return location_id.is_empty() or main.world_state.discovered_locations.has(location_id)


static func _poi_should_offer_inspect(main, entity) -> bool:
	if String(entity.data.get("description", "")).is_empty():
		return false
	if not String(entity.data.get("shop_id", "")).is_empty():
		return true
	if not String(entity.data.get("system_tab", "")).is_empty():
		return true
	return (
		_poi_has_been_discovered(main, entity)
		and not _available_poi_actions(main, entity).is_empty()
	)


static func _available_poi_actions(main, entity) -> Array[Dictionary]:
	return PoiInteraction.available_actions_for_main(entity, main)


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
