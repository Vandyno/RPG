class_name HostileActorBrain
extends RefCounted

const ActorRules = preload("res://scripts/core/actor_rules.gd")
const DirectionalAttack = preload("res://scripts/core/directional_attack.gd")
const CombatActionEffect = preload("res://scripts/world/combat_action_effect.gd")
const ActorWeaponAttackAction = preload("res://scripts/world/actor_weapon_attack_action.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")
const SpellSlots = preload("res://scripts/core/spell_slots.gd")
const WorldPathfinder = preload("res://scripts/world/world_pathfinder.gd")

const BASIC_BRAIN_ID := "hostile_basic"
const DEFAULT_AGGRO_RADIUS := 160.0
const DEFAULT_LEASH_RADIUS := 240.0
const DEFAULT_MOVE_SPEED := 80.0
const DEFAULT_SPELL_INTERVAL := 1.0
const DEFAULT_SPELL_SLOT := SpellSlots.DEFAULT_SLOT
const DEFAULT_REPATH_SECONDS := 0.35
const SPELL_EFFECT_PULSE_SECONDS := 0.08
const PATH_DESTINATION_REPATH_DISTANCE := 24.0
const PATH_WAYPOINT_ARRIVAL_DISTANCE := 8.0
const HOME_ARRIVAL_DISTANCE := 8.0
const MIN_DIRECTION_LENGTH := 0.01


class BrainContext:
	var player
	var entities
	var content
	var chunks
	var event_bus
	var _add_effect_child: Callable
	var _player_defeated: Callable
	var _refresh_hud: Callable

	func _init(values: Dictionary = {}) -> void:
		player = values.get("player")
		entities = values.get("entities")
		content = values.get("content")
		chunks = values.get("chunks")
		event_bus = values.get("event_bus")
		_add_effect_child = values.get("add_effect_child", Callable())
		_player_defeated = values.get("player_defeated", Callable())
		_refresh_hud = values.get("refresh_hud", Callable())

	func add_effect_child(effect: Node) -> void:
		if _add_effect_child.is_valid():
			_add_effect_child.call(effect)

	func player_defeated(source_name: String) -> void:
		if _player_defeated.is_valid():
			_player_defeated.call(source_name)

	func refresh_hud() -> void:
		if _refresh_hud.is_valid():
			_refresh_hud.call()

	func path_query() -> Dictionary:
		return {"can_stand_at": Callable(player, "_can_stand_at")}


static func context(main) -> BrainContext:
	if not main:
		return BrainContext.new()
	return BrainContext.new(
		{
			"player": main.get("player"),
			"entities": main.get("entities"),
			"content": main.get("content"),
			"chunks": main.get("chunks"),
			"event_bus": main.get("event_bus"),
			"add_effect_child": Callable(main, "add_child"),
			"player_defeated": Callable(main, "_handle_player_defeated"),
			"refresh_hud": Callable(main, "_refresh_hud")
		}
	)


static func update(context_or_main, delta: float) -> void:
	var ctx: BrainContext = (
		context_or_main if context_or_main is BrainContext else context(context_or_main)
	)
	if delta <= 0.0 or not _has_runtime(ctx):
		return
	if ctx.player.health <= 0:
		return
	for entity in ctx.entities.entities_by_id.values():
		_update_actor(ctx, entity, delta)


static func _update_actor(ctx: BrainContext, actor, delta: float) -> void:
	if not _uses_basic_brain(actor):
		return
	_tick_cooldown(actor.data, delta)
	var to_player: Vector2 = ctx.player.global_position - actor.global_position
	var distance: float = to_player.length()
	var aggro_radius: float = _positive_float_field(
		actor.data, "aggro_radius", DEFAULT_AGGRO_RADIUS
	)
	var leash_radius: float = _positive_float_field(
		actor.data, "leash_radius", DEFAULT_LEASH_RADIUS
	)
	var disengage_radius: float = _positive_float_field(
		actor.data, "disengage_radius", maxf(aggro_radius * 1.5, leash_radius)
	)
	var home_position: Vector2 = _home_position(actor.data)
	var home_distance: float = actor.global_position.distance_to(home_position)
	var mode := String(actor.data.get("_brain_mode", "idle"))
	if mode == "returning":
		if distance <= aggro_radius and home_distance <= leash_radius:
			actor.data["_brain_mode"] = "engaged"
		else:
			_return_home(ctx, actor, home_position, delta)
			return
	elif distance > aggro_radius and mode != "engaged":
		_idle_or_return_home(ctx, actor, home_position, delta)
		return
	elif distance > disengage_radius or home_distance > leash_radius:
		_return_home(ctx, actor, home_position, delta)
		return
	actor.data["_brain_mode"] = "engaged"

	var aim_direction := _attack_direction(actor, to_player)
	if actor.has_method("set_facing_direction"):
		actor.set_facing_direction(aim_direction)

	var attack_info := _selected_attack_info(ctx.content, actor.data)
	var attack: Dictionary = attack_info.get("attack", {})
	var attack_query := {
		"origin": actor.global_position, "direction": aim_direction, "attack": attack
	}
	if DirectionalAttack.contains_point(ctx.player.global_position, attack_query):
		_set_behavior_state(actor, "attacking")
		_set_locomotion(actor, false, delta)
		_try_attack_player(ctx, actor, attack_info, aim_direction, delta)
		return

	_set_behavior_state(actor, "chasing")
	var move_speed := _positive_float_field(actor.data, "move_speed", DEFAULT_MOVE_SPEED)
	var stop_distance := _approach_stop_distance(attack)
	var move_target := _next_path_target(
		ctx, actor, ctx.player.global_position, stop_distance, true
	)
	if actor.has_method("try_move"):
		actor.try_move(move_target - actor.global_position, delta, ctx.chunks, move_speed)


static func _idle_or_return_home(
	ctx: BrainContext, actor, home_position: Vector2, delta: float
) -> void:
	if actor.global_position.distance_to(home_position) > HOME_ARRIVAL_DISTANCE:
		_return_home(ctx, actor, home_position, delta)
		return
	actor.data["_brain_mode"] = "idle"
	_set_behavior_state(actor, "idle")
	_clear_path(actor.data)
	_set_locomotion(actor, false, delta)


static func _return_home(ctx: BrainContext, actor, home_position: Vector2, delta: float) -> void:
	var distance_to_home: float = actor.global_position.distance_to(home_position)
	if distance_to_home <= HOME_ARRIVAL_DISTANCE:
		actor.data["_brain_mode"] = "idle"
		_set_behavior_state(actor, "idle")
		_clear_path(actor.data)
		_set_locomotion(actor, false, delta)
		return
	actor.data["_brain_mode"] = "returning"
	_set_behavior_state(actor, "returning")
	if actor.has_method("set_facing_direction"):
		actor.set_facing_direction(home_position - actor.global_position)
	var move_speed := _positive_float_field(actor.data, "move_speed", DEFAULT_MOVE_SPEED)
	var move_target := _next_path_target(ctx, actor, home_position, HOME_ARRIVAL_DISTANCE, false)
	if actor.has_method("try_move"):
		actor.try_move(move_target - actor.global_position, delta, ctx.chunks, move_speed)


static func _try_attack_player(
	ctx: BrainContext, actor, attack_info: Dictionary, direction: Vector2, delta: float
) -> void:
	if (
		String(attack_info.get("kind", "weapon")) == "spell"
		and bool(attack_info.get("channel", false))
	):
		_try_channel_spell_player(ctx, actor, attack_info, direction, delta)
		return
	var cooldown := _non_negative_float_value(actor.data.get("_brain_attack_cooldown", 0.0), 0.0)
	if cooldown > 0.0:
		return
	var damage := maxi(1, int(attack_info.get("damage", 1)))
	if String(attack_info.get("kind", "weapon")) == "weapon":
		_spawn_weapon_action(ctx, actor, direction, attack_info, damage)
	else:
		_spawn_effect(ctx, actor, direction, attack_info.get("attack", {}))
		ctx.player.apply_damage(damage)
		_post_attack_message(ctx, actor, attack_info, damage)
	actor.data["_brain_attack_cooldown"] = maxf(0.05, float(attack_info.get("interval", 0.55)))
	if ctx.player.health <= 0:
		ctx.player_defeated(actor.get_display_name())
	ctx.refresh_hud()


static func _try_channel_spell_player(
	ctx: BrainContext, actor, attack_info: Dictionary, direction: Vector2, delta: float
) -> void:
	var attack: Dictionary = attack_info.get("attack", {})
	var effect_cooldown := _non_negative_float_value(
		actor.data.get("_brain_spell_effect_cooldown", 0.0), 0.0
	)
	if effect_cooldown <= 0.0:
		_spawn_effect(ctx, actor, direction, attack)
		actor.data["_brain_spell_effect_cooldown"] = SPELL_EFFECT_PULSE_SECONDS
	var damage_per_second := maxf(
		0.0, float(attack.get("damage_per_second", attack_info.get("damage", 1)))
	)
	var bank: float = (
		float(actor.data.get("_brain_spell_damage_bank", 0.0)) + damage_per_second * delta
	)
	var damage := 0
	while bank >= 1.0:
		damage += 1
		bank -= 1.0
	actor.data["_brain_spell_damage_bank"] = bank
	if damage <= 0:
		return
	ctx.player.apply_damage(damage)
	_post_attack_message(ctx, actor, attack_info, damage)
	if ctx.player.health <= 0:
		ctx.player_defeated(actor.get_display_name())
	ctx.refresh_hud()


static func _approach_stop_distance(attack: Dictionary) -> float:
	var attack_range := maxf(1.0, float(attack.get("range_pixels", 32.0)))
	match String(attack.get("shape", "swing")):
		"projectile", "cone", "stream":
			return maxf(16.0, attack_range * 0.85)
		_:
			return maxf(12.0, attack_range * 0.75)


static func _selected_attack_info(content, data: Dictionary) -> Dictionary:
	if _should_use_spells(data):
		var spell_info := _spell_attack_info(content, data)
		if not spell_info.is_empty():
			return spell_info
	return _weapon_attack_info(content, data)


static func _weapon_attack_info(content, data: Dictionary) -> Dictionary:
	var equipped := _dictionary_field(data.get("equipped_items", {}))
	var item_id := String(equipped.get("right_hand", ""))
	var attack := DirectionalAttack.weapon_attack_for_item(content, item_id)
	return {
		"attack": attack,
		"damage": maxi(1, int(attack.get("damage", 2))),
		"interval": maxf(0.05, float(attack.get("attack_interval_seconds", 0.55))),
		"source_name": String(attack.get("item_name", attack.get("name", "Attack"))),
		"kind": "weapon"
	}


static func _spell_attack_info(content, data: Dictionary) -> Dictionary:
	if not content:
		return {}
	var slot_id := String(data.get("spell_attack_slot", DEFAULT_SPELL_SLOT))
	var loadout_slots := _dictionary_field(data.get("loadout_slots", {}))
	var spell_id := String(loadout_slots.get(slot_id, ""))
	if spell_id.is_empty():
		return {}
	var spell: Dictionary = content.get_spell(spell_id)
	if spell.is_empty():
		return {}
	var attack := DirectionalAttack.spell_attack(spell)
	var interval := _positive_float_field(
		data, "actor_spell_interval_seconds", DEFAULT_SPELL_INTERVAL
	)
	return {
		"attack": attack,
		"damage": _spell_damage_for_interval(spell, attack, interval),
		"interval": interval,
		"source_name": String(spell.get("name", spell_id)),
		"kind": "spell",
		"channel": bool(spell.get("channel", false))
	}


static func _spell_damage_for_interval(
	spell: Dictionary, attack: Dictionary, interval: float
) -> int:
	if attack.has("damage"):
		return maxi(1, int(attack.get("damage", spell.get("mana_cost", 1))))
	var damage_per_second := maxf(
		0.0, float(attack.get("damage_per_second", spell.get("mana_cost", 1)))
	)
	return maxi(1, ceili(damage_per_second * maxf(0.05, interval)))


static func _post_attack_message(
	ctx: BrainContext, actor, attack_info: Dictionary, damage: int
) -> void:
	if not ctx.event_bus:
		return
	var source_name := String(attack_info.get("source_name", "Attack"))
	if String(attack_info.get("kind", "weapon")) == "spell":
		if bool(attack_info.get("channel", false)):
			ctx.event_bus.post_message(
				"%s channels %s for %d." % [actor.get_display_name(), source_name, damage]
			)
			return
		ctx.event_bus.post_message(
			"%s casts %s for %d." % [actor.get_display_name(), source_name, damage]
		)
	else:
		ctx.event_bus.post_message(
			"%s hits you with %s for %d." % [actor.get_display_name(), source_name, damage]
		)


static func _spawn_effect(ctx: BrainContext, actor, direction: Vector2, attack: Dictionary) -> void:
	if not ctx:
		return
	var visual := String(attack.get("visual", attack.get("shape", "swing")))
	var effect := CombatActionEffect.new()
	ctx.add_effect_child(effect)
	effect.setup(visual, actor.global_position, direction.normalized(), attack)


static func _spawn_weapon_action(
	ctx: BrainContext, actor, direction: Vector2, attack_info: Dictionary, damage: int
) -> void:
	if not ctx:
		return
	var targets_provider := func() -> Array: return [ctx.player]
	var hit_callback := func(_target, dealt_damage: int, _source_name: String) -> void:
		ctx.player.apply_damage(dealt_damage)
		_post_attack_message(ctx, actor, attack_info, dealt_damage)
	var action := ActorWeaponAttackAction.new()
	action.setup(
		{
			"source_actor": actor,
			"direction": direction,
			"attack": attack_info.get("attack", {}),
			"damage": damage,
			"source_name": String(attack_info.get("source_name", "Attack")),
			"targets_provider": targets_provider,
			"hit_callback": hit_callback
		}
	)
	ctx.add_effect_child(action)


static func _attack_direction(actor, to_player: Vector2) -> Vector2:
	if to_player.length() > MIN_DIRECTION_LENGTH:
		return to_player.normalized()
	if actor and actor.has_method("get_facing_direction"):
		return actor.get_facing_direction()
	return Vector2.DOWN


static func _tick_cooldown(data: Dictionary, delta: float) -> void:
	var cooldown := _non_negative_float_value(data.get("_brain_attack_cooldown", 0.0), 0.0)
	data["_brain_attack_cooldown"] = maxf(0.0, cooldown - delta)
	var path_cooldown := _non_negative_float_value(data.get("_brain_path_cooldown", 0.0), 0.0)
	data["_brain_path_cooldown"] = maxf(0.0, path_cooldown - delta)
	var spell_effect_cooldown := _non_negative_float_value(
		data.get("_brain_spell_effect_cooldown", 0.0), 0.0
	)
	data["_brain_spell_effect_cooldown"] = maxf(0.0, spell_effect_cooldown - delta)


static func _next_path_target(
	ctx: BrainContext, actor, destination: Vector2, stop_distance: float, approach_destination: bool
) -> Vector2:
	var path := _current_path(actor.data)
	if _should_repath(actor.data, path, destination):
		path = (
			WorldPathfinder.approach_path_to(
				ctx.path_query(), actor.global_position, destination, stop_distance
			)
			if approach_destination
			else WorldPathfinder.path_to(ctx.path_query(), actor.global_position, destination)
		)
		actor.data["_brain_path"] = path
		actor.data["_brain_path_index"] = 0
		actor.data["_brain_path_destination"] = [destination.x, destination.y]
		actor.data["_brain_path_cooldown"] = _positive_float_field(
			actor.data, "brain_repath_seconds", DEFAULT_REPATH_SECONDS
		)
	if path.is_empty():
		return destination
	var index := clampi(int(actor.data.get("_brain_path_index", 0)), 0, path.size() - 1)
	while (
		index < path.size() - 1
		and actor.global_position.distance_to(path[index]) <= PATH_WAYPOINT_ARRIVAL_DISTANCE
	):
		index += 1
	actor.data["_brain_path_index"] = index
	return path[index]


static func _current_path(data: Dictionary) -> Array[Vector2]:
	var value: Variant = data.get("_brain_path", [])
	var result: Array[Vector2] = []
	if not value is Array:
		return result
	for point in value:
		if point is Vector2:
			result.append(point)
	return result


static func _should_repath(data: Dictionary, path: Array[Vector2], destination: Vector2) -> bool:
	if path.is_empty():
		return true
	var path_cooldown := _non_negative_float_value(data.get("_brain_path_cooldown", 0.0), 0.0)
	if path_cooldown <= 0.0:
		return true
	var previous_destination := _vector2_from_pair(
		data.get("_brain_path_destination", []), destination
	)
	return previous_destination.distance_to(destination) >= PATH_DESTINATION_REPATH_DISTANCE


static func _clear_path(data: Dictionary) -> void:
	data["_brain_path"] = []
	data["_brain_path_index"] = 0
	data["_brain_path_destination"] = []
	data["_brain_path_cooldown"] = 0.0


static func _home_position(data: Dictionary) -> Vector2:
	var home_position := _vector2_from_pair(data.get("home_position", []), Vector2.INF)
	if home_position != Vector2.INF:
		return home_position
	var home_tile := _tile_from_pair(data.get("home_tile", []), Vector2i(999999, 999999))
	if home_tile != Vector2i(999999, 999999):
		return _tile_center(home_tile)
	var spawn_tile := _tile_from_pair(data.get("_spawn_global_tile", []), Vector2i(999999, 999999))
	if spawn_tile != Vector2i(999999, 999999):
		return _tile_center(spawn_tile)
	return _tile_center(_tile_from_pair(data.get("global_tile", [0, 0]), Vector2i.ZERO))


static func _uses_basic_brain(actor) -> bool:
	if not actor or not (actor.data is Dictionary):
		return false
	if String(actor.data.get("brain_id", "")) != BASIC_BRAIN_ID:
		return false
	return ActorRules.is_combat_target_data(actor.data)


static func _should_use_spells(data: Dictionary) -> bool:
	if bool(data.get("use_spells", false)):
		return true
	var preferred := String(data.get("combat_preferred_attack", "")).to_lower()
	return preferred == "spell" or preferred == "magic"


static func _set_behavior_state(actor, state: String) -> void:
	if actor and actor.data is Dictionary:
		actor.data["behavior_state"] = state


static func _set_locomotion(actor, moving: bool, delta: float) -> void:
	if actor and actor.has_method("set_locomotion"):
		actor.set_locomotion(moving, delta)


static func _has_runtime(ctx: BrainContext) -> bool:
	return (
		ctx
		and ctx.player
		and ctx.entities
		and ctx.content
		and ctx.chunks
	)


static func _dictionary_field(value: Variant) -> Dictionary:
	return value if value is Dictionary else {}


static func _vector2_from_pair(value: Variant, fallback: Vector2) -> Vector2:
	if not value is Array or value.size() < 2:
		return fallback
	if not _is_number(value[0]) or not _is_number(value[1]):
		return fallback
	return Vector2(float(value[0]), float(value[1]))


static func _tile_from_pair(value: Variant, fallback: Vector2i) -> Vector2i:
	if not value is Array or value.size() < 2:
		return fallback
	if not _is_number(value[0]) or not _is_number(value[1]):
		return fallback
	return Vector2i(int(value[0]), int(value[1]))


static func _tile_center(tile: Vector2i) -> Vector2:
	return GridMath.tile_to_world(tile) + Vector2(GridMath.TILE_SIZE, GridMath.TILE_SIZE) * 0.5


static func _positive_float_field(source: Dictionary, field_id: String, fallback: float) -> float:
	return _positive_float_value(source.get(field_id, fallback), fallback)


static func _positive_float_value(value: Variant, fallback: float) -> float:
	if not _is_number(value):
		return maxf(0.01, fallback)
	return maxf(0.01, float(value))


static func _non_negative_float_value(value: Variant, fallback: float) -> float:
	if not _is_number(value):
		return maxf(0.0, fallback)
	return maxf(0.0, float(value))


static func _is_number(value: Variant) -> bool:
	return value is int or value is float
