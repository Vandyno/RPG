class_name MainSystemsActions
extends RefCounted

const MainInventoryTransfer = preload("res://scripts/main/actions/main_inventory_transfer.gd")
const MainInputRouter = preload("res://scripts/main/input/main_input_router.gd")
const DirectionalAttack = preload("res://scripts/core/directional_attack.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")
const CombatActionEffect = preload("res://scripts/world/combat_action_effect.gd")
const ActorWeaponAttackAction = preload("res://scripts/world/actor_weapon_attack_action.gd")
const FacingBuckets = preload("res://scripts/core/facing_buckets.gd")

const MIN_AIM_DIRECTION := 0.1
const DEFAULT_BOW_CHARGE_SECONDS := 2.0
const MIN_PROJECTILE_CHARGE_DAMAGE_RATIO := 0.15


class SystemsActionContext:
	var content
	var event_bus
	var hud
	var inventory_transfer_context
	var spells
	var _buy_item: Callable
	var _equip_item: Callable
	var _equip_item_to_slot: Callable
	var _load_requested: Callable
	var _refresh_hud: Callable
	var _save_requested: Callable
	var _sell_item: Callable
	var _swap_mainhand_weapon: Callable
	var _train_stat: Callable
	var _unequip_slot: Callable
	var _use_inventory_item: Callable
	var _wait_action: Callable
	var _target_entity: Callable

	func _init(main) -> void:
		content = main.get("content")
		event_bus = main.get("event_bus")
		hud = main.get("hud")
		inventory_transfer_context = (
			MainInventoryTransfer.context(main) if main.get("chunks") else null
		)
		spells = main.get("spells")
		_buy_item = Callable(main, "_handle_buy_item")
		_equip_item = Callable(main, "_handle_equip_item")
		_equip_item_to_slot = Callable(main, "_handle_equip_item_to_slot")
		_load_requested = Callable(main, "_handle_load_requested")
		_refresh_hud = Callable(main, "_refresh_hud")
		_save_requested = Callable(main, "_handle_save_requested")
		_sell_item = Callable(main, "_handle_sell_item")
		_swap_mainhand_weapon = Callable(main, "_handle_swap_mainhand_weapon")
		_train_stat = Callable(main, "_handle_train_stat")
		_unequip_slot = Callable(main, "_handle_unequip_slot")
		_use_inventory_item = Callable(main, "_use_inventory_item")
		_wait_action = Callable(main, "_handle_wait_action")
		_target_entity = func(target_id: String) -> void:
			MainInputRouter.target_entity(MainInputRouter.context(main), target_id)

	func hide_systems_panel() -> void:
		if hud:
			hud.hide_systems_panel()


class AimCombatContext:
	var channeled_spell_damage_bank: Dictionary
	var channeled_spell_empty_reported: Dictionary
	var combat
	var content
	var effect_runner
	var entities
	var equipment
	var event_bus
	var held_weapon_attack_elapsed: Dictionary
	var inventory
	var player
	var progression
	var spells
	var statuses
	var _add_effect_child: Callable
	var _apply_effect: Callable
	var _refresh_hud: Callable

	func _init(main) -> void:
		channeled_spell_damage_bank = _dictionary_property(main, "channeled_spell_damage_bank")
		channeled_spell_empty_reported = _dictionary_property(
			main, "channeled_spell_empty_reported"
		)
		combat = main.get("combat")
		content = main.get("content")
		effect_runner = main.get("effect_runner")
		entities = main.get("entities")
		equipment = main.get("equipment")
		event_bus = main.get("event_bus")
		held_weapon_attack_elapsed = _dictionary_property(main, "held_weapon_attack_elapsed")
		inventory = main.get("inventory")
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
		elif effect.is_inside_tree():
			effect.queue_free()
		else:
			effect.free()

	func apply_effect(effect: Dictionary, refresh: bool = false) -> void:
		_apply_effect.call(effect, refresh)

	func refresh_hud() -> void:
		_refresh_hud.call()

	func _dictionary_property(source, property_name: String) -> Dictionary:
		var value: Variant = source.get(property_name)
		return value if value is Dictionary else {}


static func context(main) -> SystemsActionContext:
	return systems_context(main)


static func systems_context(main) -> SystemsActionContext:
	return SystemsActionContext.new(main)


static func aim_context(main) -> AimCombatContext:
	return AimCombatContext.new(main)


static func handle(ctx: SystemsActionContext, action_id: String) -> void:
	var parsed := parse_action_id(action_id)
	var action := String(parsed.get("action", "use"))
	var target_id := String(parsed.get("target_id", action_id))
	match action:
		"equip":
			ctx._equip_item.call(target_id)
		"equip_slot":
			ctx._equip_item_to_slot.call(target_id, String(parsed.get("slot_id", "")))
		"swap_mainhand":
			ctx._swap_mainhand_weapon.call()
		"unequip":
			ctx._unequip_slot.call(target_id)
		"train":
			ctx._train_stat.call(target_id)
		"buy":
			ctx._buy_item.call(target_id)
		"sell":
			ctx._sell_item.call(target_id)
		"wait":
			ctx._wait_action.call(target_id.to_int())
		"target":
			ctx._target_entity.call(target_id)
		"save":
			ctx._save_requested.call()
		"load":
			ctx._load_requested.call()
		"ui":
			if target_id == "back":
				ctx.hide_systems_panel()
		"assign_spell":
			_handle_assign_spell_to_slot(ctx, target_id, String(parsed.get("slot_id", "")))
		"take":
			MainInventoryTransfer.take_item(ctx.inventory_transfer_context, target_id)
		"put":
			MainInventoryTransfer.put_item(ctx.inventory_transfer_context, target_id)
		_:
			ctx._use_inventory_item.call(target_id)


static func handle_aim(ctx: AimCombatContext, action_id: String, direction: Vector2) -> void:
	var attack_action := action_id == "attack" or action_id == "primary"
	var aim_direction := _aim_direction(direction)
	if direction.length() > MIN_AIM_DIRECTION and ctx.player.has_method("set_facing_direction"):
		ctx.player.set_facing_direction(aim_direction)
	if attack_action:
		var attack := DirectionalAttack.weapon_attack(ctx.content, ctx.equipment)
		if _is_projectile_attack(attack):
			var charge_ratio := _consume_projectile_charge_ratio(ctx, action_id, attack)
			_perform_weapon_attack(ctx, aim_direction, charge_ratio)
			ctx.refresh_hud()
			return
		if _consume_held_weapon_release(ctx, action_id):
			ctx.refresh_hud()
			return
		_perform_weapon_attack(ctx, aim_direction)
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
		var spell_query := {
			"origin": ctx.player.global_position,
			"direction": aim_direction,
			"attack": spell_attack
		}
		var targets := DirectionalAttack.targets_in_shape(
			_combat_candidates(ctx), spell_query
		)
		var damage := maxi(1, int(spell_attack.get("damage", spell.get("mana_cost", 1))))
		if targets.is_empty():
			ctx.event_bus.post_message("%s missed." % spell_name)
		else:
			_damage_targets(ctx, targets, damage, spell_name)
	ctx.refresh_hud()


static func handle_aim_held(
	ctx: AimCombatContext, action_id: String, direction: Vector2, delta: float
) -> void:
	if delta <= 0.0 or direction.length() <= MIN_AIM_DIRECTION:
		return
	var aim_direction := _aim_direction(direction)
	if action_id == "attack" or action_id == "primary":
		_handle_held_weapon_attack(ctx, action_id, aim_direction, delta)
		return
	var spell_id: String = ctx.spells.get_assigned_spell(action_id) if ctx.spells else ""
	var spell: Dictionary = ctx.content.get_spell(spell_id)
	if spell.is_empty() or not bool(spell.get("channel", false)):
		return
	if ctx.player.has_method("set_facing_direction"):
		ctx.player.set_facing_direction(aim_direction)
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
	_spawn_effect(ctx, String(attack.get("visual", "fire_stream")), aim_direction, attack)
	var dps := maxf(0.0, float(attack.get("damage_per_second", spell.get("mana_cost", 1))))
	var bank: float = float(ctx.channeled_spell_damage_bank.get(action_id, 0.0)) + dps * delta
	while bank >= 1.0:
		bank -= 1.0
		var channel_query := {
			"origin": ctx.player.global_position, "direction": aim_direction, "attack": attack
		}
		var targets := DirectionalAttack.targets_in_shape(
			_combat_candidates(ctx), channel_query
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


static func _perform_weapon_attack(
	ctx: AimCombatContext, direction: Vector2, charge_ratio: float = 1.0
) -> void:
	if direction.length() <= MIN_AIM_DIRECTION:
		ctx.event_bus.post_message("Aim attack first.")
		return
	var attack := DirectionalAttack.weapon_attack(ctx.content, ctx.equipment)
	var full_damage := maxi(1, int(attack.get("damage", 2)) + _player_action_damage_bonus(ctx))
	var damage := full_damage
	if _is_projectile_attack(attack):
		var safe_charge_ratio := clampf(charge_ratio, 0.0, 1.0)
		attack["charge_ratio"] = safe_charge_ratio
		attack["released"] = true
		damage = maxi(1, int(round(float(full_damage) * safe_charge_ratio)))
	_spawn_weapon_action(ctx, attack, direction, damage, String(attack.get("item_name", "Attack")))


static func _handle_held_weapon_attack(
	ctx: AimCombatContext, action_id: String, direction: Vector2, delta: float
) -> void:
	if ctx.player.has_method("set_facing_direction"):
		ctx.player.set_facing_direction(direction)
	var attack := DirectionalAttack.weapon_attack(ctx.content, ctx.equipment)
	if _is_projectile_attack(attack):
		var charge_seconds := _projectile_charge_seconds(attack)
		var elapsed := float(ctx.held_weapon_attack_elapsed.get(action_id, 0.0)) + delta
		elapsed = minf(elapsed, charge_seconds)
		ctx.held_weapon_attack_elapsed[action_id] = elapsed
		_set_actor_attack_pose(ctx.player, attack, direction, elapsed / charge_seconds)
		return
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


static func _consume_held_weapon_release(ctx: AimCombatContext, action_id: String) -> bool:
	if not ctx.held_weapon_attack_elapsed.has(action_id):
		return false
	ctx.held_weapon_attack_elapsed.erase(action_id)
	_clear_actor_attack_pose(ctx.player)
	return true


static func _consume_projectile_charge_ratio(
	ctx: AimCombatContext, action_id: String, attack: Dictionary
) -> float:
	var elapsed := float(ctx.held_weapon_attack_elapsed.get(action_id, 0.0))
	ctx.held_weapon_attack_elapsed.erase(action_id)
	_clear_actor_attack_pose(ctx.player)
	var ratio := clampf(elapsed / _projectile_charge_seconds(attack), 0.0, 1.0)
	return maxf(MIN_PROJECTILE_CHARGE_DAMAGE_RATIO, ratio)


static func _damage_targets(
	ctx: AimCombatContext, targets: Array, damage: int, source_name: String
) -> void:
	for entity in targets:
		_damage_target(ctx, entity, damage, source_name)


static func _damage_target(ctx: AimCombatContext, entity, damage: int, source_name: String) -> void:
	if not ActorRules.is_combat_target_entity(entity):
		return
	var result: Dictionary = ctx.combat.damage_entity(entity, damage, false)
	if bool(result.get("defeated", false)):
		_defeat_actor(ctx, entity, result)
	else:
		ctx.event_bus.post_message(
			"%s hits %s for %d." % [source_name, entity.get_display_name(), damage]
		)


static func _combat_candidates(ctx: AimCombatContext) -> Array:
	if not ctx.entities:
		return []
	return ctx.entities.entities_by_id.values()


static func _player_action_damage_bonus(ctx: AimCombatContext) -> int:
	var bonus := 0
	if ctx.progression and ctx.progression.has_method("get_player_damage_bonus"):
		bonus += int(ctx.progression.get_player_damage_bonus())
	if ctx.statuses and ctx.statuses.has_method("get_player_damage_bonus"):
		bonus += int(ctx.statuses.get_player_damage_bonus())
	return maxi(0, bonus)


static func _defeat_actor(ctx: AimCombatContext, entity, result: Dictionary) -> void:
	var defeat_effects := []
	if entity and entity.data is Dictionary:
		defeat_effects = entity.data.get("effects_on_defeat", [])
	_create_body_for_defeated_humanoid(ctx, entity)
	ctx.combat.clear_entity(entity.get_entity_id())
	ctx.entities.remove_entity(entity.get_entity_id())
	ctx.event_bus.post_message("Defeated %s." % result.get("name", "hostile actor"))
	for effect in defeat_effects:
		if effect is Dictionary:
			ctx.apply_effect(effect, false)
	var reward_text: String = ctx.effect_runner.describe_effects(defeat_effects)
	if not reward_text.is_empty():
		ctx.event_bus.post_message("Rewards: %s." % reward_text)


static func _create_body_for_defeated_humanoid(ctx: AimCombatContext, entity) -> void:
	if not entity or not (entity.data is Dictionary):
		return
	var profile: Dictionary = ActorRules.profile(entity.data)
	if profile.is_empty():
		return
	if not ctx.entities.has_method("add_runtime_entity"):
		return
	var owner_id := ActorRules.inventory_owner_id(entity.data)
	var equipment_owner_id := ActorRules.equipment_owner_id(entity.data)
	if owner_id.is_empty():
		return
	_seed_body_inventory(ctx, owner_id, entity.data)
	var body_profile := profile.duplicate(true)
	body_profile["state"] = ActorRules.STATE_DEAD_BODY
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


static func _seed_body_inventory(ctx: AimCombatContext, owner_id: String, data: Dictionary) -> void:
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
	ctx: AimCombatContext, visual: String, direction: Vector2, attack: Dictionary
) -> void:
	var effect := CombatActionEffect.new()
	effect.setup(visual, ctx.player.global_position, _aim_direction(direction), attack)
	ctx.add_effect_child(effect)


static func _spawn_weapon_action(
	ctx: AimCombatContext, attack: Dictionary, direction: Vector2, damage: int, source_name: String
) -> void:
	var targets_provider := func() -> Array: return _combat_candidates(ctx)
	var hit_callback := func(entity, dealt_damage: int, hit_source_name: String) -> void:
		_damage_target(ctx, entity, dealt_damage, hit_source_name)
	var miss_callback := func(
		_hit_source_name: String, miss_attack: Dictionary, miss_direction: Vector2
	) -> void:
		ctx.event_bus.post_message(
			(
				"%s %s."
				% [
					String(miss_attack.get("miss_text", "Attacked")),
					_direction_text(miss_direction)
				]
			)
		)
	var action := ActorWeaponAttackAction.new()
	action.setup(
		{
			"source_actor": ctx.player,
			"direction": direction,
			"attack": attack,
			"damage": damage,
			"source_name": source_name,
			"targets_provider": targets_provider,
			"hit_callback": hit_callback,
			"miss_callback": miss_callback
		}
	)
	ctx.add_effect_child(action)


static func _direction_text(direction: Vector2) -> String:
	if direction.length() <= MIN_AIM_DIRECTION:
		return "forward"
	var normalized := _snapped_aim_direction(direction)
	if absf(normalized.x) > absf(normalized.y):
		return "east" if normalized.x > 0.0 else "west"
	return "south" if normalized.y > 0.0 else "north"


static func _snapped_aim_direction(direction: Vector2) -> Vector2:
	return FacingBuckets.snap_direction(direction, Vector2.DOWN)


static func _aim_direction(direction: Vector2) -> Vector2:
	if direction.length() <= MIN_AIM_DIRECTION:
		return Vector2.ZERO
	return direction.normalized()


static func _is_projectile_attack(attack: Dictionary) -> bool:
	return String(attack.get("shape", "")) == "projectile"


static func _projectile_charge_seconds(attack: Dictionary) -> float:
	return maxf(0.05, float(attack.get("charge_seconds", DEFAULT_BOW_CHARGE_SECONDS)))


static func _set_actor_attack_pose(
	actor, attack: Dictionary, direction: Vector2, progress: float
) -> void:
	if actor and actor.has_method("set_attack_pose"):
		actor.set_attack_pose(attack, direction, progress)
		return
	var avatar = actor.get("humanoid_avatar") if actor and actor is Object else null
	if avatar and avatar.has_method("set_attack_pose"):
		avatar.set_attack_pose(attack, direction, progress)


static func _clear_actor_attack_pose(actor) -> void:
	if actor and actor.has_method("clear_attack_pose"):
		actor.clear_attack_pose()
		return
	var avatar = actor.get("humanoid_avatar") if actor and actor is Object else null
	if avatar and avatar.has_method("clear_attack_pose"):
		avatar.clear_attack_pose()


static func _dictionary_field(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []


static func _positive_int_value(value: Variant, fallback: int) -> int:
	if not (value is int or value is float):
		return maxi(1, fallback)
	return maxi(1, int(value))


static func _handle_assign_spell_to_slot(
	ctx: SystemsActionContext, spell_id: String, slot_id: String
) -> void:
	var spell: Dictionary = ctx.content.get_spell(spell_id)
	if spell.is_empty() or not ctx.spells.assign_spell_to_slot(spell_id, slot_id):
		ctx.event_bus.post_message("Could not assign that spell.")
		ctx._refresh_hud.call()
		return
	ctx.event_bus.post_message(
		"Assigned %s to %s." % [String(spell.get("name", spell_id)), slot_id.replace("_", " ")]
	)
	ctx._refresh_hud.call()
