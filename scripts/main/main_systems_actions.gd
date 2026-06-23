class_name MainSystemsActions
extends RefCounted

const MainInputRouter = preload("res://scripts/main/main_input_router.gd")
const InteractionTargetSelector = preload("res://scripts/main/interaction_target_selector.gd")

const MIN_AIM_DIRECTION := 0.1


static func handle(main, action_id: String) -> void:
	var parsed := parse_action_id(action_id)
	var action := String(parsed.get("action", "use"))
	var target_id := String(parsed.get("target_id", action_id))
	match action:
		"equip":
			main._handle_equip_item(target_id)
		"equip_slot":
			_handle_equip_item_to_slot(main, target_id, String(parsed.get("slot_id", "")))
		"assign_spell":
			_handle_assign_spell_to_slot(main, target_id, String(parsed.get("slot_id", "")))
		"unequip":
			main._handle_unequip_slot(target_id)
		"train":
			main._handle_train_stat(target_id)
		"buy":
			main._handle_buy_item(target_id)
		"sell":
			main._handle_sell_item(target_id)
		"wait":
			main._handle_wait_action(target_id.to_int())
		"target":
			MainInputRouter.target_entity(main, target_id)
		"save":
			main._handle_save_requested()
		"load":
			main._handle_load_requested()
		"ui":
			if target_id == "back" and main.hud:
				main.hud.hide_systems_panel()
		_:
			main._use_inventory_item(target_id)


static func handle_aim(main, action_id: String, direction: Vector2) -> void:
	var attack_action := action_id == "attack" or action_id == "primary"
	if direction.length() > MIN_AIM_DIRECTION and main.player.has_method("set_facing_direction"):
		main.player.set_facing_direction(direction)
	var aimed_entity = _select_aimed_target(main, direction, true)
	if action_id == "primary":
		return
	if attack_action:
		if aimed_entity and aimed_entity.get_kind() == "enemy":
			main._interact_enemy(aimed_entity)
		else:
			main.event_bus.post_message("Swung %s." % _direction_text(direction))
		main._refresh_hud()
		return
	var spell_id: String = main.spells.get_assigned_spell(action_id) if main.spells else ""
	var spell: Dictionary = main.content.get_spell(spell_id)
	if spell.is_empty():
		main.event_bus.post_message("%s is empty." % action_id.replace("_", " "))
	elif bool(spell.get("channel", false)):
		pass
	elif aimed_entity and aimed_entity.get_kind() == "enemy":
		main.event_bus.post_message(
			"%s at %s." % [String(spell.get("name", spell_id)), aimed_entity.get_display_name()]
		)
		main._interact_enemy(aimed_entity)
	else:
		var spell_name := String(spell.get("name", spell_id))
		main.event_bus.post_message("%s needs an enemy target." % spell_name)
	main._refresh_hud()


static func handle_aim_held(main, action_id: String, direction: Vector2, delta: float) -> void:
	if delta <= 0.0 or direction.length() <= MIN_AIM_DIRECTION:
		return
	if action_id == "attack" or action_id == "primary":
		return
	var spell_id: String = main.spells.get_assigned_spell(action_id) if main.spells else ""
	var spell: Dictionary = main.content.get_spell(spell_id)
	if spell.is_empty() or not bool(spell.get("channel", false)):
		return
	if main.player.has_method("set_facing_direction"):
		main.player.set_facing_direction(direction)
	var spell_name := String(spell.get("name", spell_id))
	var drain_value: Variant = spell.get("mana_drain_per_second", spell.get("mana_cost", 1))
	var drain_rate := maxf(0.1, float(drain_value))
	var spent: float = 0.0
	if main.player.has_method("spend_mana"):
		spent = main.player.spend_mana(drain_rate * delta)
	if spent <= 0.0:
		if not bool(main.channeled_spell_empty_reported.get(action_id, false)):
			main.event_bus.post_message("Not enough mana for %s." % spell_name)
			main.channeled_spell_empty_reported[action_id] = true
		main._refresh_hud()
		return
	main.channeled_spell_empty_reported[action_id] = false
	var pulse_cost := maxf(1.0, float(spell.get("mana_cost", 1)))
	var bank: float = float(main.channeled_spell_damage_bank.get(action_id, 0.0)) + spent
	while bank >= pulse_cost:
		bank -= pulse_cost
		var aimed_entity = _select_aimed_target(main, direction, true)
		if aimed_entity and aimed_entity.get_kind() == "enemy":
			main.event_bus.post_message(
				"%s burns %s." % [spell_name, aimed_entity.get_display_name()]
			)
			main._interact_enemy(aimed_entity)
		else:
			main.event_bus.post_message("%s pours %s." % [spell_name, _direction_text(direction)])
	main.channeled_spell_damage_bank[action_id] = bank
	main._refresh_hud()


static func parse_action_id(action_id: String) -> Dictionary:
	var parts := action_id.split(":", false)
	if parts.size() >= 3 and ["equip_slot", "assign_spell"].has(parts[0]):
		return {"action": parts[0], "target_id": parts[1], "slot_id": parts[2]}
	if parts.size() >= 2:
		return {"action": parts[0], "target_id": parts[1]}
	return {"action": "use", "target_id": action_id}


static func _handle_equip_item_to_slot(main, item_id: String, slot_id: String) -> void:
	if main.has_method("_handle_equip_item_to_slot"):
		main._handle_equip_item_to_slot(item_id, slot_id)
		return
	var item: Dictionary = main.content.get_item(item_id)
	if (
		item.is_empty()
		or not main.inventory.has_item(item_id)
		or not main.equipment.equip_item_to_slot(item_id, slot_id)
	):
		main.event_bus.post_message("Could not equip that item there.")
		main._refresh_hud()
		return
	main.event_bus.post_message("Equipped %s." % String(item.get("name", item_id)))
	main._refresh_hud()


static func _select_aimed_target(main, direction: Vector2, enemies_only: bool):
	if direction.length() <= MIN_AIM_DIRECTION:
		var nearby = main._get_nearby_entity()
		if not enemies_only or (nearby and nearby.get_kind() == "enemy"):
			return nearby
		for entity in main._get_nearby_entities():
			if entity.get_kind() == "enemy":
				return entity
		return null
	var targets := []
	for entity in main._get_nearby_entities():
		if not enemies_only or entity.get_kind() == "enemy":
			targets.append(entity)
	if targets.is_empty():
		return null
	var ranked := InteractionTargetSelector.ranked_targets(
		targets, main.player.global_position, direction
	)
	var entity = ranked[0]
	main._select_nearby_target(entity.get_entity_id(), false)
	return entity


static func _direction_text(direction: Vector2) -> String:
	if direction.length() <= MIN_AIM_DIRECTION:
		return "forward"
	var normalized := direction.normalized()
	if absf(normalized.x) > absf(normalized.y):
		return "east" if normalized.x > 0.0 else "west"
	return "south" if normalized.y > 0.0 else "north"


static func _handle_assign_spell_to_slot(main, spell_id: String, slot_id: String) -> void:
	var spell: Dictionary = main.content.get_spell(spell_id)
	if spell.is_empty() or not main.spells.assign_spell_to_slot(spell_id, slot_id):
		main.event_bus.post_message("Could not assign that spell.")
		main._refresh_hud()
		return
	main.event_bus.post_message(
		"Assigned %s to %s." % [String(spell.get("name", spell_id)), slot_id.replace("_", " ")]
	)
	main._refresh_hud()
