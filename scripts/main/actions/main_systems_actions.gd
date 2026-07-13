class_name MainSystemsActions
extends RefCounted

const MainInventoryTransfer = preload("res://scripts/main/actions/main_inventory_transfer.gd")
const DirectionalAttack = preload("res://scripts/core/directional_attack.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")
const CombatActionEffect = preload("res://scripts/world/combat_action_effect.gd")
const ActorWeaponAttackAction = preload("res://scripts/world/actor_weapon_attack_action.gd")
const FacingBuckets = preload("res://scripts/core/facing_buckets.gd")
const SystemsActionIds = preload("res://scripts/main/actions/systems_action_ids.gd")

const MIN_AIM_DIRECTION := 0.1
const DEFAULT_BOW_CHARGE_SECONDS := 2.0
const MIN_PROJECTILE_CHARGE_DAMAGE_RATIO := 0.15
const MAX_HELD_ATTACKS_PER_FRAME := 2
const MAX_CHANNELED_DAMAGE_TICKS_PER_FRAME := 3


class SystemsActionContext:
	var content
	var equipment
	var event_bus
	var hud
	var inventory_transfer_context
	var inventory
	var progression
	var shops
	var spells
	var time
	var current_shop_id := ""
	var _apply_effect: Callable
	var _appearance_requested: Callable
	var _load_requested: Callable
	var _refresh_hud: Callable
	var _save_requested: Callable
	var _update_nearby: Callable

	func _init(main) -> void:
		content = main.get("content")
		equipment = main.get("equipment")
		event_bus = main.get("event_bus")
		hud = main.get("hud")
		inventory = main.get("inventory")
		inventory_transfer_context = (
			MainInventoryTransfer.context(main) if main.get("chunks") else null
		)
		progression = main.get("progression")
		shops = main.get("shops")
		spells = main.get("spells")
		time = main.get("time")
		if main.has_method("_current_shop_id"):
			current_shop_id = String(main.call("_current_shop_id"))
		_apply_effect = Callable(main, "apply_effect")
		_appearance_requested = Callable(main, "open_character_appearance")
		_load_requested = Callable(main, "_handle_load_requested")
		_refresh_hud = Callable(main, "_refresh_hud")
		_save_requested = Callable(main, "_handle_save_requested")
		_update_nearby = Callable(main, "_update_nearby")

	func hide_systems_panel() -> void:
		if hud:
			hud.hide_systems_panel()

	func apply_effect(effect: Dictionary) -> bool:
		return _apply_effect.is_valid() and bool(_apply_effect.call(effect))

	func post_message(message: String) -> void:
		if event_bus and not message.is_empty():
			event_bus.post_message(message)

	func refresh_hud() -> void:
		if _refresh_hud.is_valid():
			_refresh_hud.call()

	func update_nearby() -> void:
		if _update_nearby.is_valid():
			_update_nearby.call()
		else:
			refresh_hud()

	func open_character_appearance() -> void:
		if _appearance_requested.is_valid():
			_appearance_requested.call()

	func post_result(result: Dictionary) -> void:
		post_message(String(result.get("message", "")))
		if String(result.get("refresh", "hud")) == "nearby":
			update_nearby()
		else:
			refresh_hud()


class AimCombatContext:
	var allegiances
	var channeled_spell_damage_bank: Dictionary
	var channeled_spell_empty_reported: Dictionary
	var combat
	var companions
	var content
	var effect_runner
	var entities
	var equipment
	var event_bus
	var held_weapon_attack_elapsed: Dictionary
	var held_spell_charge_elapsed: Dictionary
	var held_spell_charge_visual_elapsed: Dictionary
	var inventory
	var player
	var progression
	var spells
	var statuses
	var _add_effect_child: Callable
	var _apply_effect: Callable
	var _refresh_hud: Callable

	func _init(main) -> void:
		allegiances = main.get("allegiances")
		channeled_spell_damage_bank = _dictionary_property(main, "channeled_spell_damage_bank")
		channeled_spell_empty_reported = _dictionary_property(
			main, "channeled_spell_empty_reported"
		)
		combat = main.get("combat")
		companions = main.get("companions")
		content = main.get("content")
		effect_runner = main.get("effect_runner")
		entities = main.get("entities")
		equipment = main.get("equipment")
		event_bus = main.get("event_bus")
		held_weapon_attack_elapsed = _dictionary_property(main, "held_weapon_attack_elapsed")
		held_spell_charge_elapsed = _dictionary_property(main, "held_spell_charge_elapsed")
		held_spell_charge_visual_elapsed = _dictionary_property(
			main, "held_spell_charge_visual_elapsed"
		)
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

	func apply_effect(effect: Dictionary, emit_feedback: bool = true) -> bool:
		return _apply_effect.is_valid() and bool(_apply_effect.call(effect, emit_feedback))

	func refresh_hud() -> void:
		_refresh_hud.call()

	func _dictionary_property(source, property_name: String) -> Dictionary:
		var value: Variant = source.get(property_name)
		return value if value is Dictionary else {}


static func systems_context(main) -> SystemsActionContext:
	return SystemsActionContext.new(main)


static func aim_context(main) -> AimCombatContext:
	return AimCombatContext.new(main)


static func handle(ctx: SystemsActionContext, action_id: String) -> Dictionary:
	var parsed := parse_action_id(action_id)
	var action := String(parsed.get("action", "use"))
	var target_id := String(parsed.get("target_id", action_id))
	match action:
		SystemsActionIds.ACTION_EQUIP:
			_handle_equip_item(ctx, target_id)
		SystemsActionIds.ACTION_EQUIP_SLOT:
			_handle_equip_item_to_slot(ctx, target_id, String(parsed.get("slot_id", "")))
		SystemsActionIds.ACTION_SWAP_MAINHAND:
			_handle_swap_mainhand_weapon(ctx)
		SystemsActionIds.ACTION_UNEQUIP:
			_handle_unequip_slot(ctx, target_id)
		SystemsActionIds.ACTION_TRAIN:
			_handle_train_stat(ctx, target_id)
		SystemsActionIds.ACTION_BUY:
			_handle_buy_item(ctx, target_id)
		SystemsActionIds.ACTION_SELL:
			_handle_sell_item(ctx, target_id)
		SystemsActionIds.ACTION_WAIT:
			_handle_wait_action(ctx, target_id.to_int())
		SystemsActionIds.ACTION_TARGET:
			return {"intent": "target_entity", "entity_id": target_id}
		SystemsActionIds.ACTION_SAVE:
			ctx._save_requested.call()
		SystemsActionIds.ACTION_LOAD:
			ctx._load_requested.call()
		SystemsActionIds.ACTION_UI:
			if target_id == "back":
				ctx.hide_systems_panel()
			elif target_id == "appearance":
				ctx.open_character_appearance()
		SystemsActionIds.ACTION_ASSIGN_SPELL:
			_handle_assign_spell_to_slot(ctx, target_id, String(parsed.get("slot_id", "")))
		SystemsActionIds.ACTION_TAKE:
			MainInventoryTransfer.take_item(ctx.inventory_transfer_context, target_id)
		SystemsActionIds.ACTION_PUT:
			MainInventoryTransfer.put_item(ctx.inventory_transfer_context, target_id)
		_:
			_use_inventory_item(ctx, target_id)
	return {}


static func handle_aim(ctx: AimCombatContext, action_id: String, direction: Vector2) -> void:
	var attack_action := action_id == "attack" or action_id == "primary"
	var aim_direction := _aim_direction(direction)
	if direction.length() > MIN_AIM_DIRECTION and ctx.player.has_method("set_facing_direction"):
		ctx.player.set_facing_direction(aim_direction)
	if attack_action:
		_handle_weapon_aim_release(ctx, action_id, aim_direction)
		return
	_handle_spell_aim_release(ctx, action_id, aim_direction)


static func _handle_weapon_aim_release(
	ctx: AimCombatContext, action_id: String, aim_direction: Vector2
) -> void:
	var attack := DirectionalAttack.weapon_attack(ctx.content, ctx.equipment)
	if _is_projectile_attack(attack):
		var charge_ratio := _consume_projectile_charge_ratio(ctx, action_id, attack)
		_perform_weapon_attack(ctx, aim_direction, charge_ratio)
	elif _consume_held_weapon_release(ctx, action_id):
		pass
	else:
		_perform_weapon_attack(ctx, aim_direction)
	ctx.refresh_hud()


static func _handle_spell_aim_release(
	ctx: AimCombatContext, action_id: String, aim_direction: Vector2
) -> void:
	var spell_id: String = ctx.spells.get_assigned_spell(action_id) if ctx.spells else ""
	var spell: Dictionary = ctx.content.get_spell(spell_id)
	if spell.is_empty():
		ctx.event_bus.post_message("%s is empty." % action_id.replace("_", " "))
	elif bool(spell.get("channel", false)):
		ctx.refresh_hud()
		return
	elif String(spell.get("cast_type", "")) == "raise_thrall":
		_cast_raise_thrall(ctx, action_id, aim_direction, spell)
	else:
		var spell_name := String(spell.get("name", spell_id))
		var spell_attack := DirectionalAttack.spell_attack(spell)
		var spell_query := {
			"origin": ctx.player.global_position, "direction": aim_direction, "attack": spell_attack
		}
		var targets := DirectionalAttack.targets_in_shape(_combat_candidates(ctx), spell_query)
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
	_handle_held_spell_aim(ctx, action_id, aim_direction, delta)


static func _handle_held_spell_aim(
	ctx: AimCombatContext, action_id: String, aim_direction: Vector2, delta: float
) -> void:
	var spell_id: String = ctx.spells.get_assigned_spell(action_id) if ctx.spells else ""
	var spell: Dictionary = ctx.content.get_spell(spell_id)
	if spell.is_empty():
		return
	if String(spell.get("cast_type", "")) == "raise_thrall":
		_charge_spell_cast(ctx, action_id, aim_direction, spell, delta)
		return
	if not bool(spell.get("channel", false)):
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
	var damage_ticks := 0
	while bank >= 1.0 and damage_ticks < MAX_CHANNELED_DAMAGE_TICKS_PER_FRAME:
		bank -= 1.0
		var channel_query := {
			"origin": ctx.player.global_position, "direction": aim_direction, "attack": attack
		}
		var targets := DirectionalAttack.targets_in_shape(_combat_candidates(ctx), channel_query)
		_damage_targets(ctx, targets, 1, spell_name)
		damage_ticks += 1
	if damage_ticks >= MAX_CHANNELED_DAMAGE_TICKS_PER_FRAME:
		bank = 0.0
	ctx.channeled_spell_damage_bank[action_id] = bank
	ctx.refresh_hud()


static func _charge_spell_cast(
	ctx: AimCombatContext, action_id: String, aim_direction: Vector2, spell: Dictionary, delta: float
) -> void:
	if ctx.player.has_method("set_facing_direction"):
		ctx.player.set_facing_direction(aim_direction)
	var charge_seconds := _spell_charge_seconds(spell)
	var elapsed := minf(
		charge_seconds, float(ctx.held_spell_charge_elapsed.get(action_id, 0.0)) + delta
	)
	ctx.held_spell_charge_elapsed[action_id] = elapsed
	var visual_elapsed := float(ctx.held_spell_charge_visual_elapsed.get(action_id, 0.0)) + delta
	if visual_elapsed >= 0.12:
		visual_elapsed = 0.0
		var attack := DirectionalAttack.spell_attack(spell)
		attack["charge_ratio"] = elapsed / charge_seconds
		_spawn_effect(ctx, "charge_cast", aim_direction, attack)
		_spawn_effect(ctx, "direction_indicator", aim_direction, attack)
	ctx.held_spell_charge_visual_elapsed[action_id] = visual_elapsed


static func _cast_raise_thrall(
	ctx: AimCombatContext, action_id: String, aim_direction: Vector2, spell: Dictionary
) -> void:
	var charge_ratio := _consume_spell_charge_ratio(ctx, action_id, spell)
	if aim_direction.length() <= MIN_AIM_DIRECTION:
		ctx.event_bus.post_message("Aim Raise Thrall at a body.")
		return
	if charge_ratio < float(spell.get("min_charge_ratio", 0.0)):
		ctx.event_bus.post_message("Raise Thrall needs more charge.")
		return
	var attack := DirectionalAttack.spell_attack(spell)
	var corpse = _corpse_in_shape(ctx, aim_direction, attack)
	if not corpse:
		ctx.event_bus.post_message("Raise Thrall needs a dead humanoid in range.")
		return
	var mana_cost := maxi(1, int(spell.get("mana_cost", 1)))
	if not ctx.player.has_method("spend_mana") or ctx.player.spend_mana(mana_cost) < mana_cost:
		ctx.event_bus.post_message("Not enough mana for Raise Thrall.")
		return
	if not ctx.companions or not ctx.companions.has_method("resurrect_as_thrall"):
		ctx.event_bus.post_message("No necromancy binding is available.")
		return
	var result: Dictionary = ctx.companions.resurrect_as_thrall(corpse.get_entity_id())
	ctx.event_bus.post_message(String(result.get("message", "Nothing happens.")))
	if bool(result.get("ok", false)):
		attack["charge_ratio"] = charge_ratio
		_spawn_effect_at(ctx, "raise_thrall", corpse.global_position, aim_direction, attack)


static func _corpse_in_shape(ctx: AimCombatContext, direction: Vector2, attack: Dictionary):
	var query := {"origin": ctx.player.global_position, "direction": direction, "attack": attack}
	var closest = null
	var closest_distance := INF
	for entity in _combat_candidates(ctx):
		if not entity or not (entity.data is Dictionary):
			continue
		if not ActorRules.is_dead_actor_data(entity.data):
			continue
		if String(entity.data.get("world_layer", "surface")) != _actor_world_layer(ctx.player):
			continue
		if not DirectionalAttack.contains_point(entity.global_position, query):
			continue
		var distance: float = ctx.player.global_position.distance_to(entity.global_position)
		if distance < closest_distance:
			closest = entity
			closest_distance = distance
	return closest


static func parse_action_id(action_id: String) -> Dictionary:
	return SystemsActionIds.parse(action_id)


static func _handle_wait_action(ctx: SystemsActionContext, hours: int) -> void:
	var result: Dictionary = (
		ctx.time.wait_hours(hours)
		if ctx.time
		else {"ok": false, "message": "Could not wait right now.", "refresh": "hud"}
	)
	ctx.post_result(result)


static func _use_inventory_item(ctx: SystemsActionContext, item_id: String) -> void:
	var item: Dictionary = ctx.content.get_item(item_id) if ctx.content else {}
	if item.is_empty() or not ctx.inventory or not ctx.inventory.has_item(item_id):
		ctx.post_message("That item is no longer available.")
		ctx.refresh_hud()
		return
	var applied := false
	for effect in _array_field(item.get("effects_on_use", [])):
		if effect is Dictionary and ctx.apply_effect(effect):
			applied = true
	if not applied:
		ctx.post_message("%s has no effect right now." % String(item.get("name", item_id)))
		ctx.refresh_hud()
		return
	if bool(item.get("consume_on_use", false)):
		ctx.inventory.remove_item(item_id, 1)
	ctx.post_message("Used %s." % String(item.get("name", item_id)))
	ctx.refresh_hud()


static func _handle_equip_item(ctx: SystemsActionContext, item_id: String) -> void:
	var item: Dictionary = ctx.content.get_item(item_id) if ctx.content else {}
	if (
		item.is_empty()
		or not ctx.inventory
		or not ctx.inventory.has_item(item_id)
		or not ctx.equipment
		or not ctx.equipment.equip_item(item_id)
	):
		ctx.post_message("Could not equip that item.")
		ctx.refresh_hud()
		return
	ctx.post_message("Equipped %s." % String(item.get("name", item_id)))
	ctx.refresh_hud()


static func _handle_equip_item_to_slot(
	ctx: SystemsActionContext, item_id: String, slot_id: String
) -> void:
	var item: Dictionary = ctx.content.get_item(item_id) if ctx.content else {}
	if item.is_empty() or not ctx.inventory or not ctx.inventory.has_item(item_id):
		ctx.post_message("Could not equip that item there.")
		ctx.refresh_hud()
		return
	if not ctx.equipment or not ctx.equipment.equip_item_to_slot(item_id, slot_id):
		ctx.post_message("Could not equip that item there.")
		ctx.refresh_hud()
		return
	ctx.post_message("Equipped %s." % String(item.get("name", item_id)))
	ctx.refresh_hud()


static func _handle_swap_mainhand_weapon(ctx: SystemsActionContext) -> void:
	if not ctx.equipment or not ctx.equipment.equip_last_mainhand_weapon():
		ctx.post_message("No previous main hand weapon.")
	else:
		var item_id: String = ctx.equipment.get_equipped_item("right_hand")
		var item: Dictionary = ctx.content.get_item(item_id) if ctx.content else {}
		ctx.post_message("Equipped %s." % String(item.get("name", item_id)))
	ctx.refresh_hud()


static func _handle_unequip_slot(ctx: SystemsActionContext, slot_id: String) -> void:
	var item_id := ""
	if ctx.equipment:
		item_id = String(ctx.equipment.get_equipped_item(slot_id))
	var item: Dictionary = ctx.content.get_item(item_id) if ctx.content else {}
	if item_id.is_empty() or not ctx.equipment or not ctx.equipment.unequip_slot(slot_id):
		ctx.post_message("Nothing equipped there.")
		ctx.refresh_hud()
		return
	ctx.post_message("Unequipped %s." % String(item.get("name", item_id)))
	ctx.refresh_hud()


static func _handle_train_stat(ctx: SystemsActionContext, stat_id: String) -> void:
	var result: Dictionary = (
		ctx.progression.train_stat(stat_id)
		if ctx.progression
		else {"ok": false, "message": "Could not train %s." % stat_id, "refresh": "hud"}
	)
	ctx.post_result(result)


static func _handle_buy_item(ctx: SystemsActionContext, item_id: String) -> void:
	var result: Dictionary = (
		ctx.shops.buy_result(ctx.current_shop_id, item_id)
		if ctx.shops
		else {"ok": false, "message": "Could not buy that.", "refresh": "hud"}
	)
	ctx.post_result(result)


static func _handle_sell_item(ctx: SystemsActionContext, item_id: String) -> void:
	var result: Dictionary = (
		ctx.shops.sell_result(ctx.current_shop_id, item_id)
		if ctx.shops
		else {"ok": false, "message": "Could not sell that.", "refresh": "hud"}
	)
	ctx.post_result(result)


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
	_emit_player_attack_noise(ctx, attack)
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
	var attacks_fired := 0
	while elapsed >= interval and attacks_fired < MAX_HELD_ATTACKS_PER_FRAME:
		elapsed -= interval
		_perform_weapon_attack(ctx, direction)
		fired = true
		attacks_fired += 1
	if attacks_fired >= MAX_HELD_ATTACKS_PER_FRAME:
		elapsed = 0.0
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
	if not ActorRules.is_damageable_actor_entity(entity):
		return
	var was_hostile := ActorRules.is_hostile_to_player_data(entity.data)
	_aggravate_attacked_actor(ctx, entity)
	var result: Dictionary = ctx.combat.damage_entity(entity, damage, false)
	if not was_hostile:
		_emit_player_violent_crime(ctx, entity, bool(result.get("defeated", false)))
	if bool(result.get("defeated", false)):
		_defeat_actor(ctx, entity, result)
	else:
		ctx.event_bus.post_message(
			"%s hits %s for %d." % [source_name, entity.get_display_name(), damage]
		)


static func _emit_player_attack_noise(ctx: AimCombatContext, attack: Dictionary) -> void:
	if not ctx.event_bus or not ctx.player or not ctx.event_bus.has_signal("noise_emitted"):
		return
	var shape := String(attack.get("shape", "swing"))
	var radius := 48.0 if shape == "punch" else 96.0
	if shape in ["projectile", "cone", "stream"]:
		radius = 160.0
	ctx.event_bus.noise_emitted.emit(
		{
			"kind": "weapon_attack",
			"source_id": "player",
			"world_position": [ctx.player.global_position.x, ctx.player.global_position.y],
			"world_layer": _actor_world_layer(ctx.player),
			"noise_radius": radius,
			"loudness": "loud",
			"visible": false
		}
	)


static func _actor_world_layer(actor) -> String:
	if actor and actor.has_method("get_world_layer"):
		return String(actor.get_world_layer())
	var value: Variant = actor.get("world_layer") if actor else null
	return String(value) if value is String and not String(value).is_empty() else "surface"


static func _emit_player_violent_crime(ctx: AimCombatContext, victim, defeated: bool) -> void:
	if (
		not ctx.event_bus
		or not ctx.event_bus.has_signal("player_crime_committed")
		or not victim
		or not (victim.data is Dictionary)
	):
		return
	var profile := ActorRules.profile(victim.data)
	ctx.event_bus.player_crime_committed.emit(
		{
			"kind": "murder" if defeated else "assault",
			"offender_id": "player",
			"victim_entity_id": victim.get_entity_id(),
			"victim_npc_id": String(victim.data.get("npc_id", victim.get_entity_id())),
			"victim_faction_id": String(profile.get("faction_id", victim.data.get("faction_id", ""))),
			"world_position": [victim.global_position.x, victim.global_position.y],
			"world_layer": String(victim.data.get("world_layer", "surface")),
			"noise_radius": 160.0,
			"loudness": "loud",
			"visible": true
		}
	)


static func _aggravate_attacked_actor(ctx: AimCombatContext, entity) -> void:
	if not entity or not (entity.data is Dictionary):
		return
	if ActorRules.is_hostile_to_player_data(entity.data):
		if ctx.allegiances and ctx.allegiances.has_method("alert_actor"):
			ctx.allegiances.alert_actor(entity)
		return
	entity.data["hostility"] = ActorRules.HOSTILITY_HOSTILE
	entity.data["hostile_to_player"] = true
	entity.data["combat_enabled"] = true
	if String(entity.data.get("brain_id", "")) == "civilian_schedule":
		entity.data["schedule_brain_id"] = "civilian_schedule"
		entity.data["brain_id"] = "hostile_basic"
		entity.data["schedule_reaction"] = "defending_home"
	if String(entity.data.get("brain_id", "")).is_empty():
		entity.data["brain_id"] = "hostile_basic"
	entity.data["_brain_mode"] = "engaged"
	entity.data["behavior_state"] = "chasing"
	if ctx.allegiances and ctx.allegiances.has_method("alert_actor"):
		ctx.allegiances.alert_actor(entity)
	if ctx.event_bus:
		ctx.event_bus.post_message("%s turns hostile." % entity.get_display_name())


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
	if ctx.entities.has_method("transition_actor_to_dead"):
		ctx.entities.transition_actor_to_dead(entity)
	ctx.combat.clear_entity(entity.get_entity_id())
	ctx.event_bus.post_message("Defeated %s." % result.get("name", "hostile actor"))
	var effects_failed := _apply_effects(defeat_effects, ctx, false)
	if effects_failed:
		ctx.event_bus.post_message("Some rewards could not be applied.")
	var reward_text: String = ctx.effect_runner.describe_effects(defeat_effects)
	if not reward_text.is_empty() and not effects_failed:
		ctx.event_bus.post_message("Rewards: %s." % reward_text)


static func _spawn_effect(
	ctx: AimCombatContext, visual: String, direction: Vector2, attack: Dictionary
) -> void:
	var effect := CombatActionEffect.new()
	effect.setup(visual, ctx.player.global_position, _aim_direction(direction), attack)
	ctx.add_effect_child(effect)


static func _spawn_effect_at(
	ctx: AimCombatContext, visual: String, origin: Vector2, direction: Vector2, attack: Dictionary
) -> void:
	var effect := CombatActionEffect.new()
	effect.setup(visual, origin, _aim_direction(direction), attack)
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


static func _spell_charge_seconds(spell: Dictionary) -> float:
	return maxf(0.05, float(spell.get("charge_seconds", DEFAULT_BOW_CHARGE_SECONDS)))


static func _consume_spell_charge_ratio(
	ctx: AimCombatContext, action_id: String, spell: Dictionary
) -> float:
	var elapsed := float(ctx.held_spell_charge_elapsed.get(action_id, 0.0))
	ctx.held_spell_charge_elapsed.erase(action_id)
	ctx.held_spell_charge_visual_elapsed.erase(action_id)
	return clampf(elapsed / _spell_charge_seconds(spell), 0.0, 1.0)


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


static func _apply_effects(
	effects_value: Variant, ctx: AimCombatContext, emit_feedback: bool
) -> bool:
	var failed := false
	for effect in _array_field(effects_value):
		if effect is Dictionary:
			failed = not ctx.apply_effect(effect, emit_feedback) or failed
	return failed


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
		ctx.refresh_hud()
		return
	ctx.event_bus.post_message(
		"Assigned %s to %s." % [String(spell.get("name", spell_id)), slot_id.replace("_", " ")]
	)
	ctx.refresh_hud()
