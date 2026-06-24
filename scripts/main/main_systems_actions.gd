class_name MainSystemsActions
extends RefCounted

const MainInputRouter = preload("res://scripts/main/main_input_router.gd")
const DirectionalAttack = preload("res://scripts/core/directional_attack.gd")
const CombatActionEffect = preload("res://scripts/world/combat_action_effect.gd")

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
		"swap_mainhand":
			main._handle_swap_mainhand_weapon()
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
	if attack_action:
		if _consume_held_melee_release(main, action_id):
			main._refresh_hud()
			return
		_perform_weapon_attack(main, direction)
		main._refresh_hud()
		return
	var spell_id: String = main.spells.get_assigned_spell(action_id) if main.spells else ""
	var spell: Dictionary = main.content.get_spell(spell_id)
	if spell.is_empty():
		main.event_bus.post_message("%s is empty." % action_id.replace("_", " "))
	elif bool(spell.get("channel", false)):
		pass
	else:
		var spell_name := String(spell.get("name", spell_id))
		var spell_attack := DirectionalAttack.spell_attack(spell)
		var targets := DirectionalAttack.targets_in_shape(
			main, main.player.global_position, direction, spell_attack
		)
		var damage := maxi(1, int(spell_attack.get("damage", spell.get("mana_cost", 1))))
		if targets.is_empty():
			main.event_bus.post_message("%s missed." % spell_name)
		else:
			_damage_targets(main, targets, damage, spell_name)
	main._refresh_hud()


static func handle_aim_held(main, action_id: String, direction: Vector2, delta: float) -> void:
	if delta <= 0.0 or direction.length() <= MIN_AIM_DIRECTION:
		return
	if action_id == "attack" or action_id == "primary":
		_handle_held_weapon_attack(main, action_id, direction, delta)
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
	var attack := DirectionalAttack.spell_attack(spell)
	_spawn_effect(main, String(attack.get("visual", "fire_stream")), direction, attack)
	var dps := maxf(0.0, float(attack.get("damage_per_second", spell.get("mana_cost", 1))))
	var bank: float = float(main.channeled_spell_damage_bank.get(action_id, 0.0)) + dps * delta
	while bank >= 1.0:
		bank -= 1.0
		var targets := DirectionalAttack.targets_in_shape(
			main, main.player.global_position, direction, attack
		)
		_damage_targets(main, targets, 1, spell_name)
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


static func _perform_weapon_attack(main, direction: Vector2) -> void:
	if direction.length() <= MIN_AIM_DIRECTION:
		main.event_bus.post_message("Aim attack first.")
		return
	var attack := DirectionalAttack.weapon_attack(main.content, main.equipment)
	_spawn_effect(main, String(attack.get("visual", attack.get("shape", "swing"))), direction, attack)
	var targets := DirectionalAttack.targets_in_shape(
		main, main.player.global_position, direction, attack
	)
	if targets.is_empty():
		main.event_bus.post_message(
			"%s %s." % [String(attack.get("miss_text", "Attacked")), _direction_text(direction)]
		)
		return
	var damage := maxi(1, int(attack.get("damage", 2)) + _player_action_damage_bonus(main))
	_damage_targets(main, targets, damage, String(attack.get("item_name", "Attack")))


static func _handle_held_weapon_attack(
	main, action_id: String, direction: Vector2, delta: float
) -> void:
	if main.player.has_method("set_facing_direction"):
		main.player.set_facing_direction(direction)
	var attack := DirectionalAttack.weapon_attack(main.content, main.equipment)
	if not DirectionalAttack.is_melee_attack(attack):
		return
	var interval := maxf(0.05, float(attack.get("attack_interval_seconds", 0.55)))
	var elapsed := float(main.held_weapon_attack_elapsed.get(action_id, interval)) + delta
	var fired := false
	while elapsed >= interval:
		elapsed -= interval
		_perform_weapon_attack(main, direction)
		fired = true
	main.held_weapon_attack_elapsed[action_id] = elapsed
	if fired:
		main._refresh_hud()


static func _consume_held_melee_release(main, action_id: String) -> bool:
	if not main.held_weapon_attack_elapsed.has(action_id):
		return false
	main.held_weapon_attack_elapsed.erase(action_id)
	return true


static func _damage_targets(main, targets: Array, damage: int, source_name: String) -> void:
	for entity in targets:
		if not entity or entity.get_kind() != "enemy":
			continue
		var result: Dictionary = main.combat.damage_entity(entity, damage, false)
		if bool(result.get("defeated", false)):
			_defeat_enemy(main, entity, result)
		else:
			main.event_bus.post_message(
				"%s hits %s for %d." % [source_name, entity.get_display_name(), damage]
			)


static func _player_action_damage_bonus(main) -> int:
	var bonus := 0
	var progression = main.get("progression")
	if progression and progression.has_method("get_player_damage_bonus"):
		bonus += int(progression.get_player_damage_bonus())
	var statuses = main.get("statuses")
	if statuses and statuses.has_method("get_player_damage_bonus"):
		bonus += int(statuses.get_player_damage_bonus())
	return maxi(0, bonus)


static func _defeat_enemy(main, entity, result: Dictionary) -> void:
	var defeat_effects := []
	if entity and entity.data is Dictionary:
		defeat_effects = entity.data.get("effects_on_defeat", [])
	main.combat.clear_entity(entity.get_entity_id())
	main.entities.remove_entity(entity.get_entity_id())
	main.event_bus.post_message("Defeated %s." % result.get("name", "enemy"))
	for effect in defeat_effects:
		if effect is Dictionary:
			main.apply_effect(effect, false)
	var reward_text: String = main.effect_runner.describe_effects(defeat_effects)
	if not reward_text.is_empty():
		main.event_bus.post_message("Rewards: %s." % reward_text)


static func _spawn_effect(main, visual: String, direction: Vector2, attack: Dictionary) -> void:
	if not (main is Node):
		return
	var effect := CombatActionEffect.new()
	main.add_child(effect)
	effect.setup(visual, main.player.global_position, direction, attack)


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
