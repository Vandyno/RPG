# gdlint:disable=class-definitions-order
class_name MainInputRouter
extends RefCounted

const MainPathfinder = preload("res://scripts/main/input/main_pathfinder.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")

const AUTO_INTERACT_STUCK_SECONDS := 0.7
const AUTO_MOVE_ARRIVAL_DISTANCE := 8.0
const WORLD_PICK_RADIUS := 36.0
const WORLD_TOUCH_PICK_RADIUS := 48.0


class InputContext:
	var can_stand_at: Callable
	var entities
	var event_bus
	var hud
	var condition_evaluator
	var content
	var dialogues
	var player
	var world_state
	var get_viewport: Callable
	var toggle_debug_character_creator: Callable
	var close_open_overlay_panel: Callable
	var get_nearby_entity: Callable
	var get_nearby_entities: Callable
	var handle_cycle_target_requested: Callable
	var handle_interact_requested: Callable
	var interact_entity: Callable
	var handle_load_requested: Callable
	var handle_save_requested: Callable
	var index_of_target_id: Callable
	var refresh_hud: Callable
	var _state

	func _init(main) -> void:
		_state = main
		entities = main.entities
		event_bus = main.event_bus
		hud = main.hud
		condition_evaluator = main.get("condition_evaluator")
		content = main.get("content")
		dialogues = main.get("dialogues")
		player = main.player
		world_state = main.get("world_state")
		can_stand_at = Callable(player, "_can_stand_at")
		get_viewport = Callable(main, "get_viewport")
		toggle_debug_character_creator = Callable(main, "toggle_debug_character_creator")
		close_open_overlay_panel = Callable(main, "_close_open_overlay_panel")
		get_nearby_entity = Callable(main, "_get_nearby_entity")
		get_nearby_entities = Callable(main, "_get_nearby_entities")
		handle_cycle_target_requested = Callable(main, "_handle_cycle_target_requested")
		handle_interact_requested = Callable(main, "_handle_interact_requested")
		interact_entity = Callable(main, "_interact_entity")
		handle_load_requested = Callable(main, "_handle_load_requested")
		handle_save_requested = Callable(main, "_handle_save_requested")
		index_of_target_id = Callable(main, "_index_of_target_id")
		refresh_hud = Callable(main, "_refresh_hud")

	func _selected_target_id() -> String:
		return String(_state.selected_target_id)

	func _target_cycle_index() -> int:
		return int(_state.target_cycle_index)

	func _select_target(entity_id: String, cycle_index: int, manual_locked := true) -> void:
		_state.selected_target_id = entity_id
		_state.target_cycle_index = cycle_index
		_state.manual_target_locked = manual_locked

	func _clear_target() -> void:
		_select_target("", 0, false)

	func _manual_target_locked() -> bool:
		return bool(_state.manual_target_locked)

	func _clear_manual_target_lock() -> void:
		_state.manual_target_locked = false

	func _can_stand_at(world_position: Vector2) -> bool:
		return can_stand_at.is_valid() and bool(can_stand_at.call(world_position))

	func _auto_interact_target_id() -> String:
		return String(_state.auto_interact_target_id)

	func _has_auto_interaction() -> bool:
		return not _auto_interact_target_id().is_empty()

	func _begin_auto_interaction(target_id: String, previous_distance: float) -> void:
		_state.auto_interact_target_id = target_id
		_state.auto_interact_previous_distance = previous_distance
		_state.auto_interact_stuck_seconds = 0.0

	func _clear_auto_interaction_state() -> void:
		_state.auto_interact_target_id = ""
		_state.auto_interact_previous_distance = INF
		_state.auto_interact_stuck_seconds = 0.0

	func _auto_interact_previous_distance() -> float:
		return float(_state.auto_interact_previous_distance)

	func _set_auto_interact_previous_distance(distance: float) -> void:
		_state.auto_interact_previous_distance = distance

	func _reset_auto_interact_stuck_time() -> void:
		_state.auto_interact_stuck_seconds = 0.0

	func _add_auto_interact_stuck_time(delta_seconds: float) -> float:
		_state.auto_interact_stuck_seconds += delta_seconds
		return float(_state.auto_interact_stuck_seconds)

	func _has_auto_move() -> bool:
		return bool(_state.auto_move_active)

	func _begin_auto_move(destination: Vector2, previous_distance: float) -> void:
		_state.auto_move_active = true
		_state.auto_move_destination = destination
		_state.auto_move_previous_distance = previous_distance
		_state.auto_move_stuck_seconds = 0.0

	func _clear_auto_move_state() -> void:
		_state.auto_move_active = false
		_state.auto_move_destination = Vector2.ZERO
		_state.auto_move_previous_distance = INF
		_state.auto_move_stuck_seconds = 0.0

	func _auto_move_destination() -> Vector2:
		return _state.auto_move_destination

	func _auto_move_path() -> Array:
		return _state.auto_move_path

	func _auto_move_path_index() -> int:
		return int(_state.auto_move_path_index)

	func _set_auto_move_path(path: Array) -> void:
		_state.auto_move_path = path
		_state.auto_move_path_index = 0

	func _advance_auto_move_path() -> void:
		_state.auto_move_path_index += 1

	func _clear_auto_move_path() -> void:
		_set_auto_move_path([])

	func _auto_move_previous_distance() -> float:
		return float(_state.auto_move_previous_distance)

	func _set_auto_move_previous_distance(distance: float) -> void:
		_state.auto_move_previous_distance = distance

	func _reset_auto_move_stuck_time() -> void:
		_state.auto_move_stuck_seconds = 0.0

	func _add_auto_move_stuck_time(delta_seconds: float) -> float:
		_state.auto_move_stuck_seconds += delta_seconds
		return float(_state.auto_move_stuck_seconds)


static func context(main) -> InputContext:
	return InputContext.new(main)


static func handle_event(source, event: InputEvent) -> void:
	var ctx: InputContext = _input_context(source)
	if event is InputEventKey and event.echo:
		return
	if _handle_pointer_event(ctx, event):
		return
	if event.is_action_pressed("interact"):
		ctx.handle_interact_requested.call()
	elif event.is_action_pressed("save_game"):
		ctx.handle_save_requested.call()
	elif event.is_action_pressed("load_game"):
		ctx.handle_load_requested.call()
	elif event.is_action_pressed("toggle_debug"):
		ctx.hud.toggle_debug()
	elif event.is_action_pressed("toggle_character_creator"):
		ctx.toggle_debug_character_creator.call()
	elif event.is_action_pressed("toggle_systems"):
		ctx.hud.toggle_systems()
	elif event.is_action_pressed("cycle_target"):
		ctx.handle_cycle_target_requested.call()


static func target_world(
	source, world_position: Vector2, interact_if_reachable := true, pick_radius := WORLD_PICK_RADIUS
) -> bool:
	var ctx: InputContext = _input_context(source)
	var entity = ctx.entities.get_interactable_at_world(world_position, pick_radius)
	if not entity:
		return false
	if ActorRules.is_combat_target_entity(entity):
		return false
	ctx.close_open_overlay_panel.call(false)
	var delta: Vector2 = entity.global_position - ctx.player.global_position
	ctx.player.set_facing_direction(delta)
	var target_index: int = ctx.index_of_target_id.call(
		ctx.get_nearby_entities.call(), entity.get_entity_id()
	)
	ctx._select_target(entity.get_entity_id(), target_index)
	if ctx._target_cycle_index() < 0:
		_begin_auto_interaction(ctx, entity, delta.length())
		ctx.refresh_hud.call()
		return true
	if interact_if_reachable:
		ctx.handle_interact_requested.call()
	else:
		ctx.event_bus.post_message("Targeting %s." % entity.get_display_name())
		ctx.refresh_hud.call()
	return true


static func target_entity(source, entity_id: String) -> bool:
	var ctx: InputContext = _input_context(source)
	var entity = ctx.entities.get_entity(entity_id)
	if not entity:
		ctx.event_bus.post_message("Target is no longer available.")
		ctx.refresh_hud.call()
		return false
	ctx.close_open_overlay_panel.call(false)
	var delta: Vector2 = entity.global_position - ctx.player.global_position
	ctx.player.set_facing_direction(delta)
	var target_index: int = ctx.index_of_target_id.call(ctx.get_nearby_entities.call(), entity_id)
	ctx._select_target(entity.get_entity_id(), target_index)
	if ctx._target_cycle_index() < 0:
		_begin_auto_interaction(ctx, entity, delta.length())
	else:
		ctx.event_bus.post_message("Targeting %s." % entity.get_display_name())
	ctx.refresh_hud.call()
	return true


static func move_to_world(source, world_position: Vector2) -> bool:
	var ctx: InputContext = _input_context(source)
	if ctx.player.global_position.distance_to(world_position) <= AUTO_MOVE_ARRIVAL_DISTANCE:
		return false
	if not ctx._can_stand_at(world_position):
		ctx.event_bus.post_message("Can't get there.")
		return true
	ctx.player.set_facing_direction(world_position - ctx.player.global_position)
	_begin_auto_move(ctx, world_position)
	ctx.close_open_overlay_panel.call(false)
	ctx._clear_target()
	ctx.event_bus.post_message("Moving.")
	ctx.refresh_hud.call()
	return true


static func update_auto_interaction(source, delta_seconds: float) -> void:
	var ctx: InputContext = _input_context(source)
	var manual_move := _manual_move_vector(ctx)
	if manual_move.length() > 0.05:
		var cancelled_route := ctx._has_auto_interaction() or ctx._has_auto_move()
		var unlocked_target := _clear_manual_target_lock(ctx)
		ctx.player.set_facing_direction(manual_move)
		_clear_auto_interaction(ctx)
		_clear_auto_move(ctx)
		if cancelled_route or unlocked_target:
			ctx.refresh_hud.call()
		return
	if not ctx._has_auto_interaction():
		update_auto_move(ctx, delta_seconds)
		return
	var entity = ctx.entities.get_entity(ctx._auto_interact_target_id())
	if not entity:
		_clear_auto_interaction(ctx)
		return
	var delta: Vector2 = entity.global_position - ctx.player.global_position
	ctx.player.set_facing_direction(delta)
	var target_index: int = ctx.index_of_target_id.call(
		ctx.get_nearby_entities.call(), entity.get_entity_id()
	)
	ctx._select_target(entity.get_entity_id(), target_index)
	if ctx._target_cycle_index() >= 0:
		_clear_auto_interaction(ctx)
		ctx.interact_entity.call(entity)
		return
	_follow_auto_path_or_direction(ctx, entity.global_position, delta, delta_seconds)
	entity = ctx.entities.get_entity(ctx._auto_interact_target_id())
	if not entity or not is_instance_valid(entity):
		_clear_auto_interaction(ctx)
		return
	_track_auto_interaction_progress(ctx, entity, delta_seconds)


static func update_auto_move(source, delta_seconds: float) -> void:
	var ctx: InputContext = _input_context(source)
	if not ctx._has_auto_move():
		return
	var move_target := _current_auto_move_target(ctx)
	var delta: Vector2 = move_target - ctx.player.global_position
	if delta.length() <= AUTO_MOVE_ARRIVAL_DISTANCE:
		if ctx._auto_move_path_index() < ctx._auto_move_path().size() - 1:
			ctx._advance_auto_move_path()
		else:
			_clear_auto_move(ctx)
			ctx.refresh_hud.call()
		return
	ctx.player.try_move(delta, delta_seconds)
	_track_auto_move_progress(ctx, delta.length(), delta_seconds)


static func cancel_auto_interaction(source) -> void:
	var ctx: InputContext = _input_context(source)
	if not ctx._has_auto_interaction():
		return
	_clear_auto_interaction(ctx)
	ctx._clear_manual_target_lock()
	ctx.event_bus.post_message("Stopped.")
	ctx.refresh_hud.call()


static func cancel_auto_move(source) -> void:
	var ctx: InputContext = _input_context(source)
	if not ctx._has_auto_move():
		return
	_clear_auto_move(ctx)
	ctx.event_bus.post_message("Stopped.")
	ctx.refresh_hud.call()


static func _handle_pointer_event(ctx: InputContext, event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_world := _screen_to_world(ctx, event.position)
		return target_world(ctx, mouse_world) or move_to_world(ctx, mouse_world)
	if event is InputEventScreenTouch and event.pressed:
		var touch_world := _screen_to_world(ctx, event.position)
		return (
			target_world(ctx, touch_world, true, WORLD_TOUCH_PICK_RADIUS)
			or move_to_world(ctx, touch_world)
		)
	return false


static func _input_context(source) -> InputContext:
	return source if source is InputContext else InputContext.new(source)


static func _screen_to_world(ctx: InputContext, screen_position: Vector2) -> Vector2:
	return ctx.get_viewport.call().get_canvas_transform().affine_inverse() * screen_position


static func _begin_auto_interaction(ctx: InputContext, entity, _distance: float) -> void:
	_clear_auto_move(ctx)
	if ctx.entities:
		ctx.entities.set_action_hints({})
	_set_auto_interaction_path(ctx, entity)
	ctx._begin_auto_interaction(
		entity.get_entity_id(), _auto_interaction_progress_distance(ctx, entity)
	)
	ctx.event_bus.post_message("Moving to %s." % entity.get_display_name())


static func _clear_auto_interaction(ctx: InputContext) -> void:
	ctx._clear_auto_interaction_state()
	ctx._clear_auto_move_path()


static func _begin_auto_move(ctx: InputContext, world_position: Vector2) -> void:
	_clear_auto_interaction(ctx)
	if ctx.entities:
		ctx.entities.set_action_hints({})
	_set_auto_path(ctx, world_position)
	ctx._begin_auto_move(world_position, ctx.player.global_position.distance_to(world_position))


static func _clear_auto_move(ctx: InputContext) -> void:
	ctx._clear_auto_move_state()
	ctx._clear_auto_move_path()


static func _set_auto_path(ctx: InputContext, world_position: Vector2) -> void:
	ctx._set_auto_move_path(
		MainPathfinder.path_to(ctx.can_stand_at, ctx.player.global_position, world_position)
	)


static func _set_auto_interaction_path(ctx: InputContext, entity) -> void:
	var radius: float = ctx.entities.get_interaction_radius(entity)
	var stop_distance := maxf(AUTO_MOVE_ARRIVAL_DISTANCE, radius - 4.0)
	ctx._set_auto_move_path(
		MainPathfinder.approach_path_to(
			ctx.can_stand_at, ctx.player.global_position, entity.global_position, stop_distance
		)
	)


static func _current_auto_move_target(ctx: InputContext) -> Vector2:
	if (
		ctx._auto_move_path().is_empty()
		or ctx._auto_move_path_index() < 0
		or ctx._auto_move_path_index() >= ctx._auto_move_path().size()
	):
		return ctx._auto_move_destination()
	return ctx._auto_move_path()[ctx._auto_move_path_index()]


static func _follow_auto_path_or_direction(
	ctx: InputContext, destination: Vector2, fallback_delta: Vector2, delta_seconds: float
) -> void:
	if ctx._auto_move_path().is_empty():
		ctx.player.try_move(fallback_delta, delta_seconds)
		return
	var target := _current_auto_move_target(ctx)
	if ctx.player.global_position.distance_to(target) <= AUTO_MOVE_ARRIVAL_DISTANCE:
		if ctx._auto_move_path_index() < ctx._auto_move_path().size() - 1:
			ctx._advance_auto_move_path()
			target = _current_auto_move_target(ctx)
		else:
			target = destination
	ctx.player.try_move(target - ctx.player.global_position, delta_seconds)


static func _manual_move_active(ctx: InputContext) -> bool:
	return _manual_move_vector(ctx).length() > 0.05


static func _manual_move_vector(ctx: InputContext) -> Vector2:
	if ctx.player and ctx.player.has_method("get_move_input_vector"):
		return ctx.player.get_move_input_vector()
	return Vector2.ZERO


static func _clear_manual_target_lock(ctx: InputContext) -> bool:
	if not ctx._manual_target_locked():
		return false
	ctx._clear_target()
	if ctx.hud and ctx.hud.is_target_picker_visible():
		ctx.hud.hide_target_picker()
	return true


static func _track_auto_interaction_progress(
	ctx: InputContext, entity, delta_seconds: float
) -> void:
	var current_distance := _auto_interaction_progress_distance(ctx, entity)
	if current_distance < ctx._auto_interact_previous_distance() - 0.5:
		ctx._set_auto_interact_previous_distance(current_distance)
		ctx._reset_auto_interact_stuck_time()
		return
	if ctx._add_auto_interact_stuck_time(delta_seconds) >= AUTO_INTERACT_STUCK_SECONDS:
		_clear_auto_interaction(ctx)
		ctx.event_bus.post_message("Can't reach %s." % entity.get_display_name())
	ctx._set_auto_interact_previous_distance(
		minf(ctx._auto_interact_previous_distance(), current_distance)
	)


static func _auto_interaction_progress_distance(ctx: InputContext, entity) -> float:
	if not ctx._auto_move_path().is_empty():
		return ctx.player.global_position.distance_to(_current_auto_move_target(ctx))
	return ctx.player.global_position.distance_to(entity.global_position)


static func _track_auto_move_progress(
	ctx: InputContext, distance_before_move: float, delta_seconds: float
) -> void:
	var current_distance: float = ctx.player.global_position.distance_to(ctx._auto_move_destination())
	if current_distance < ctx._auto_move_previous_distance() - 0.5:
		ctx._set_auto_move_previous_distance(current_distance)
		ctx._reset_auto_move_stuck_time()
		return
	if ctx._add_auto_move_stuck_time(delta_seconds) >= AUTO_INTERACT_STUCK_SECONDS:
		_clear_auto_move(ctx)
		ctx.event_bus.post_message("Can't get there.")
		ctx.refresh_hud.call()
	ctx._set_auto_move_previous_distance(
		minf(ctx._auto_move_previous_distance(), distance_before_move)
	)

