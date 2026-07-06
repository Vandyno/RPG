class_name MainSystemsActions
extends RefCounted

const MainInventoryTransfer = preload("res://scripts/main/actions/main_inventory_transfer.gd")
const DirectionalAttack = preload("res://scripts/core/directional_attack.gd")
const CombatActionEffect = preload("res://scripts/world/combat_action_effect.gd")
const FacingBuckets = preload("res://scripts/core/facing_buckets.gd")

const MIN_AIM_DIRECTION := 0.1


class SystemsContext:
	var channeled_spell_damage_bank: Dictionary
	var channeled_spell_empty_reported: Dictionary
	var combat
	var content
	var effect_runner
	var entities
	var equipment
	var event_bus
	var held_weapon_attack_elapsed: Dictionary
	var hud
	var inventory
	var inventory_transfer_context
	var player
	var progression
	var spells
	var statuses
	var _add_effect_child: Callable
	var _apply_effect: Callable
	var _refresh_hud: Callable

	func _init(main) -> void:
		channeled_spell_damage_bank = _dictionary_property(main, "channeled_spell_damage_bank")
		channeled_spell_empty_reported = _dictionary_property(main, "channeled_spell_empty_reported")
		combat = main.get("combat")
		content = main.get("content")
		effect_runner = main.get("effect_runner")
		entities = main.get("entities")
		equipment = main.get("equipment")
		event_bus = main.get("event_bus")
		held_weapon_attack_elapsed = _dictionary_property(main, "held_weapon_attack_elapsed")
		hud = main.get("hud")
		inventory = main.get("inventory")
		inventory_transfer_context = (
			MainInventoryTransfer.context(main) if main.get("chunks") else null
		)
		player = main.get("player")
		progression = main.get("progression")
		spells = main.get("spells")
		statuses = main.get("statuses")
		_add_effect_child = Callable(main, "add_child")
		_apply_effect = Callable(main, "apply_effect")
		_refresh_hud = Callable(main, "_refresh_hud")

	func add_effect_child(effect: Node) -> void:
		if _add_effect_child.is_valid():
			_add_effect_child.call(effect)
		else:
			effect.queue_free()

	func apply_effect(effect: Dictionary, refresh: bool = false) -> void:
		_apply_effect.call(effect, refresh)

	func refresh_hud() -> void:
		_refresh_hud.call()

	func _dictionary_property(source, property_name: String) -> Dictionary:
		var value: Variant = source.get(property_name)
		return value if value is Dictionary else {}


static func context(main) -> SystemsContext:
	return SystemsContext.new(main)


static func handle(ctx: SystemsContext, action_id: String) -> void:
	var parsed := parse_action_id(action_id)
	var action := String(parsed.get("action", "use"))
	var target_id := String(parsed.get("target_id", action_id))
	match action:
		"assign_spell":
			_handle_assign_spell_to_slot(ctx, target_id, String(parsed.get("slot_id", "")))
		"take":
			MainInventoryTransfer.take_item(ctx.inventory_transfer_context, target_id)
		"put":
			MainInventoryTransfer.put_item(ctx.inventory_transfer_context, target_id)
		_:
			if ctx.event_bus:
				ctx.event_bus.post_message("Unknown systems action.")


static func handle_aim(ctx: SystemsContext, action_id: String, direction: Vector2) -> void:
	var attack_action := action_id == "attack" or action_id == "primary"
	var snapped_direction := _snapped_aim_direction(direction)
	if direction.length() > MIN_AIM_DIRECTION and ctx.player.has_method("set_facing_direction"):
		ctx.player.set_facing_direction(snapped_direction)
	if attack_action:
		if _consume_held_melee_release(ctx, action_id):
			ctx.refresh_hud()
			return
		_perform_weapon_attack(ctx, snapped_direction)
		ctx.refresh_hud()
		return
	var spell_id: String = ctx.spells.get_assigned_spell(action_id) if ctx.spells else ""
	var spell: Dictionary = ctx.content.get_spell(spell_id)
	if spell.is_empty():
		ctx.event_bus.post_message("%s is empty." % action_id.replace("_", " "))
	elif bool(spell.get("channel", false)):
		pass
	else:
		var spell_name := String(spell.get("name", spell_id))
		var spell_attack := DirectionalAttack.spell_attack(spell)
		var targets := DirectionalAttack.targets_in_shape(
			_enemy_candidates(ctx), ctx.player.global_position, snapped_direction, spell_attack
		)
		var damage := maxi(1, int(spell_attack.get("damage", spell.get("mana_cost", 1))))
		if targets.is_empty():
			ctx.event_bus.post_message("%s missed." % spell_name)
		else:
			_damage_targets(ctx, targets, damage, spell_name)
	ctx.refresh_hud()


static func handle_aim_held(
	ctx: SystemsContext, action_id: String, direction: Vector2, delta: float
) -> void:
	if delta <= 0.0 or direction.length() <= MIN_AIM_DIRECTION:
		return
	var snapped_direction := _snapped_aim_direction(direction)
	if action_id == "attack" or action_id == "primary":
		_handle_held_weapon_attack(ctx, action_id, snapped_direction, delta)
		return
	var spell_id: String = ctx.spells.get_assigned_spell(action_id) if ctx.spells else ""
	var spell: Dictionary = ctx.content.get_spell(spell_id)
	if spell.is_empty() or not bool(spell.get("channel", false)):
		return
	if ctx.player.has_method("set_facing_direction"):
		ctx.player.set_facing_direction(snapped_direction)
	var spell_name := String(spell.get("name", spell_id))
	var drain_value: Variant = spell.get("mana_drain_per_second", spell.get("mana_cost", 1))
	var drain_rate := maxf(0.1, float(drain_value))
	var spent: float = 0.0
	if ctx.player.has_method("spend_mana"):
		spent = ctx.player.spend_mana(drain_rate * delta)
	if spent <= 0.0:
		if not bool(ctx.channeled_spell_empty_reported.get(action_id, false)):
			ctx.event_bus.post_message("Not enough mana for %s." % spell_name)
			ctx.channeled_spell_empty_reported[action_id] = true
		ctx.refresh_hud()
		return
	ctx.channeled_spell_empty_reported[action_id] = false
	var attack := DirectionalAttack.spell_attack(spell)
	_spawn_effect(ctx, String(attack.get("visual", "fire_stream")), snapped_direction, attack)
	var dps := maxf(0.0, float(attack.get("damage_per_second", spell.get("mana_cost", 1))))
	var bank: float = float(ctx.channeled_spell_damage_bank.get(action_id, 0.0)) + dps * delta
	while bank >= 1.0:
		bank -= 1.0
		var targets := DirectionalAttack.targets_in_shape(
			_enemy_candidates(ctx), ctx.player.global_position, snapped_direction, attack
		)
		_damage_targets(ctx, targets, 1, spell_name)
	ctx.channeled_spell_damage_bank[action_id] = bank
	ctx.refresh_hud()


static func parse_action_id(action_id: String) -> Dictionary:
	var parts := action_id.split(":", false)
	if parts.size() >= 3 and ["equip_slot", "assign_spell"].has(parts[0]):
		return {"action": parts[0], "target_id": parts[1], "slot_id": parts[2]}
	if parts.size() >= 2:
		return {"action": parts[0], "target_id": parts[1]}
	return {"action": "use", "target_id": action_id}


static func _perform_weapon_attack(ctx: SystemsContext, direction: Vector2) -> void:
	if direction.length() <= MIN_AIM_DIRECTION:
		ctx.event_bus.post_message("Aim attack first.")
		return
	var attack := DirectionalAttack.weapon_attack(ctx.content, ctx.equipment)
	_spawn_effect(ctx, String(attack.get("visual", attack.get("shape", "swing"))), direction, attack)
	var targets := DirectionalAttack.targets_in_shape(
		_enemy_candidates(ctx), ctx.player.global_position, direction, attack
	)
	if targets.is_empty():
		ctx.event_bus.post_message(
			"%s %s." % [String(attack.get("miss_text", "Attacked")), _direction_text(direction)]
		)
		return
	var damage := maxi(1, int(attack.get("damage", 2)) + _player_action_damage_bonus(ctx))
	_damage_targets(ctx, targets, damage, String(attack.get("item_name", "Attack")))


static func _handle_held_weapon_attack(
	ctx: SystemsContext, action_id: String, direction: Vector2, delta: float
) -> void:
	if ctx.player.has_method("set_facing_direction"):
		ctx.player.set_facing_direction(direction)
	var attack := DirectionalAttack.weapon_attack(ctx.content, ctx.equipment)
	if not DirectionalAttack.is_melee_attack(attack):
		return
	var interval := maxf(0.05, float(attack.get("attack_interval_seconds", 0.55)))
	var elapsed := float(ctx.held_weapon_attack_elapsed.get(action_id, interval)) + delta
	var fired := false
	while elapsed >= interval:
		elapsed -= interval
		_perform_weapon_attack(ctx, direction)
		fired = true
	ctx.held_weapon_attack_elapsed[action_id] = elapsed
	if fired:
		ctx.refresh_hud()


static func _consume_held_melee_release(ctx: SystemsContext, action_id: String) -> bool:
	if not ctx.held_weapon_attack_elapsed.has(action_id):
		return false
	ctx.held_weapon_attack_elapsed.erase(action_id)
	return true


static func _damage_targets(
	ctx: SystemsContext, targets: Array, damage: int, source_name: String
) -> void:
	for entity in targets:
		if not entity or entity.get_kind() != "enemy":
			continue
		var result: Dictionary = ctx.combat.damage_entity(entity, damage, false)
		if bool(result.get("defeated", false)):
			_defeat_enemy(ctx, entity, result)
		else:
			ctx.event_bus.post_message(
				"%s hits %s for %d." % [source_name, entity.get_display_name(), damage]
			)


static func _enemy_candidates(ctx: SystemsContext) -> Array:
	if not ctx.entities:
		return []
	return ctx.entities.entities_by_id.values()


static func _player_action_damage_bonus(ctx: SystemsContext) -> int:
	var bonus := 0
	if ctx.progression and ctx.progression.has_method("get_player_damage_bonus"):
		bonus += int(ctx.progression.get_player_damage_bonus())
	if ctx.statuses and ctx.statuses.has_method("get_player_damage_bonus"):
		bonus += int(ctx.statuses.get_player_damage_bonus())
	return maxi(0, bonus)


static func _defeat_enemy(ctx: SystemsContext, entity, result: Dictionary) -> void:
	var defeat_effects := []
	if entity and entity.data is Dictionary:
		defeat_effects = entity.data.get("effects_on_defeat", [])
	_create_body_for_defeated_humanoid(ctx, entity)
	ctx.combat.clear_entity(entity.get_entity_id())
	ctx.entities.remove_entity(entity.get_entity_id())
	ctx.event_bus.post_message("Defeated %s." % result.get("name", "enemy"))
	for effect in defeat_effects:
		if effect is Dictionary:
			ctx.apply_effect(effect, false)
	var reward_text: String = ctx.effect_runner.describe_effects(defeat_effects)
	if not reward_text.is_empty():
		ctx.event_bus.post_message("Rewards: %s." % reward_text)


static func _create_body_for_defeated_humanoid(ctx: SystemsContext, entity) -> void:
	if not entity or not (entity.data is Dictionary):
		return
	var profile: Dictionary = entity.data.get("character_profile", {})
	if profile.is_empty():
		return
	if not ctx.entities.has_method("add_runtime_entity"):
		return
	var owner_id := String(
		entity.data.get("inventory_owner_id", profile.get("inventory_owner_id", ""))
	)
	var equipment_owner_id := String(
		entity.data.get("equipment_owner_id", profile.get("equipment_owner_id", owner_id))
	)
	if owner_id.is_empty():
		return
	_seed_body_inventory(ctx, owner_id, entity.data)
	var body_profile := profile.duplicate(true)
	body_profile["state"] = "dead_body"
	var entity_id: String = entity.get_entity_id()
	var body_id: String = "body_%s" % entity_id
	var body_entry := {
		"id": body_id,
		"name": "%s Body" % entity.get_display_name(),
		"kind": "body",
		"global_tile": [entity.global_tile.x, entity.global_tile.y],
		"interaction_radius": 128,
		"character_id": String(profile.get("character_id", "")),
		"character_profile_id": String(entity.data.get("character_profile_id", "")),
		"character_profile": body_profile,
		"inventory_owner_id": owner_id,
		"equipment_owner_id": equipment_owner_id,
		"equipped_items": _dictionary_field(entity.data.get("equipped_items", {})),
		"collapsed_pose_id": "pose_fallen_side"
	}
	ctx.entities.add_runtime_entity(body_entry)


static func _seed_body_inventory(ctx: SystemsContext, owner_id: String, data: Dictionary) -> void:
	for entry in _array_field(data.get("inventory", [])):
		if not entry is Dictionary:
			continue
		var item_id := String(entry.get("item_id", ""))
		var count := _positive_int_value(entry.get("count", 1), 1)
		ctx.inventory.add_item_to_owner(owner_id, item_id, count)
	for item_id_value in _dictionary_field(data.get("equipped_items", {})).values():
		var item_id := String(item_id_value)
		if not item_id.is_empty():
			ctx.inventory.add_item_to_owner(owner_id, item_id, 1)


static func _spawn_effect(
	ctx: SystemsContext, visual: String, direction: Vector2, attack: Dictionary
) -> void:
	var effect := CombatActionEffect.new()
	ctx.add_effect_child(effect)
	effect.setup(visual, ctx.player.global_position, _snapped_aim_direction(direction), attack)


static func _direction_text(direction: Vector2) -> String:
	if direction.length() <= MIN_AIM_DIRECTION:
		return "forward"
	var normalized := _snapped_aim_direction(direction)
	if absf(normalized.x) > absf(normalized.y):
		return "east" if normalized.x > 0.0 else "west"
	return "south" if normalized.y > 0.0 else "north"


static func _snapped_aim_direction(direction: Vector2) -> Vector2:
	return FacingBuckets.snap_direction(direction, Vector2.DOWN)


static func _dictionary_field(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []


static func _positive_int_value(value: Variant, fallback: int) -> int:
	if not (value is int or value is float):
		return maxi(1, fallback)
	return maxi(1, int(value))


static func _handle_assign_spell_to_slot(
	ctx: SystemsContext, spell_id: String, slot_id: String
) -> void:
	var spell: Dictionary = ctx.content.get_spell(spell_id)
	if spell.is_empty() or not ctx.spells.assign_spell_to_slot(spell_id, slot_id):
		ctx.event_bus.post_message("Could not assign that spell.")
		ctx.refresh_hud()
		return
	ctx.event_bus.post_message(
		"Assigned %s to %s." % [String(spell.get("name", spell_id)), slot_id.replace("_", " ")]
	)
	ctx.refresh_hud()

