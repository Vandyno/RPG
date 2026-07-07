# gdlint:disable=class-definitions-order
class_name MainInputRouter
extends RefCounted

const MainContextActions = preload("res://scripts/main/actions/main_context_actions.gd")
const MainPathfinder = preload("res://scripts/main/input/main_pathfinder.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")

const AUTO_INTERACT_STUCK_SECONDS := 0.7
const AUTO_MOVE_ARRIVAL_DISTANCE := 8.0
const WORLD_PICK_RADIUS := 36.0
const WORLD_TOUCH_PICK_RADIUS := 48.0


class InputContext:
	var entities
	var event_bus
	var hud
	var condition_evaluator
	var content
	var dialogues
	var player
	var world_state
	var _main

	var auto_interact_target_id: String:
		get:
			return String(_main.auto_interact_target_id)
		set(value):
			_main.auto_interact_target_id = value
	var auto_interact_previous_distance: float:
		get:
			return float(_main.auto_interact_previous_distance)
		set(value):
			_main.auto_interact_previous_distance = value
	var auto_interact_stuck_seconds: float:
		get:
			return float(_main.auto_interact_stuck_seconds)
		set(value):
			_main.auto_interact_stuck_seconds = value
	var auto_move_active: bool:
		get:
			return bool(_main.auto_move_active)
		set(value):
			_main.auto_move_active = value
	var auto_move_destination: Vector2:
		get:
			return _main.auto_move_destination
		set(value):
			_main.auto_move_destination = value
	var auto_move_previous_distance: float:
		get:
			return float(_main.auto_move_previous_distance)
		set(value):
			_main.auto_move_previous_distance = value
	var auto_move_stuck_seconds: float:
		get:
			return float(_main.auto_move_stuck_seconds)
		set(value):
			_main.auto_move_stuck_seconds = value
	var auto_move_path: Array:
		get:
			return _main.auto_move_path
		set(value):
			_main.auto_move_path = value
	var auto_move_path_index: int:
		get:
			return int(_main.auto_move_path_index)
		set(value):
			_main.auto_move_path_index = value
	var manual_target_locked: bool:
		get:
			return bool(_main.manual_target_locked)
		set(value):
			_main.manual_target_locked = value
	var selected_target_id: String:
		get:
			return String(_main.selected_target_id)
		set(value):
			_main.selected_target_id = value
	var target_cycle_index: int:
		get:
			return int(_main.target_cycle_index)
		set(value):
			_main.target_cycle_index = value

	func _init(main) -> void:
		_main = main
		entities = main.entities
		event_bus = main.event_bus
		hud = main.hud
		condition_evaluator = main.get("condition_evaluator")
		content = main.get("content")
		dialogues = main.get("dialogues")
		player = main.player
		world_state = main.get("world_state")

	func get_viewport():
		return _main.get_viewport()

	func toggle_debug_character_creator() -> void:
		_main.toggle_debug_character_creator()

	func _close_open_overlay_panel(consume_action: bool = true) -> bool:
		return bool(_main._close_open_overlay_panel(consume_action))

	func _get_nearby_entity():
		return _main._get_nearby_entity()

	func _get_nearby_entities() -> Array:
		return _main._get_nearby_entities()

	func _handle_context_action_selected(action_id: String) -> void:
		_main._handle_context_action_selected(action_id)

	func _handle_cycle_target_requested() -> void:
		_main._handle_cycle_target_requested()

	func _handle_interact_requested() -> void:
		_main._handle_interact_requested()

	func _handle_load_requested() -> void:
		_main._handle_load_requested()

	func _handle_save_requested() -> void:
		_main._handle_save_requested()

	func _index_of_target_id(targets: Array, entity_id: String) -> int:
		return int(_main._index_of_target_id(targets, entity_id))

	func _interact() -> void:
		_main._interact()

	func _refresh_hud() -> void:
		_main._refresh_hud()


static func context(main) -> InputContext:
	return InputContext.new(main)


static func handle_event(source, event: InputEvent) -> void:
	var ctx: InputContext = _input_context(source)
	if event is InputEventKey and event.echo:
		return
	if _handle_pointer_event(ctx, event):
		return
	if event.is_action_pressed("interact"):
		ctx._handle_interact_requested()
	elif event.is_action_pressed("save_game"):
		ctx._handle_save_requested()
	elif event.is_action_pressed("load_game"):
		ctx._handle_load_requested()
	elif event.is_action_pressed("toggle_debug"):
		ctx.hud.toggle_debug()
	elif event.is_action_pressed("toggle_character_creator"):
		ctx.toggle_debug_character_creator()
	elif event.is_action_pressed("toggle_systems"):
		ctx.hud.toggle_systems()
	elif event.is_action_pressed("cycle_target"):
		ctx._handle_cycle_target_requested()


static func target_world(
	source, world_position: Vector2, interact_if_reachable := true, pick_radius := WORLD_PICK_RADIUS
) -> bool:
	var ctx: InputContext = _input_context(source)
	var entity = ctx.entities.get_interactable_at_world(world_position, pick_radius)
	if not entity:
		return false
	if ActorRules.is_combat_target_entity(entity):
		return false
	ctx._close_open_overlay_panel(false)
	var delta: Vector2 = entity.global_position - ctx.player.global_position
	ctx.player.set_facing_direction(delta)
	ctx.selected_target_id = entity.get_entity_id()
	ctx.manual_target_locked = true
	ctx.target_cycle_index = ctx._index_of_target_id(
		ctx._get_nearby_entities(), ctx.selected_target_id
	)
	if ctx.target_cycle_index < 0:
		_begin_auto_interaction(ctx, entity, delta.length())
		ctx._refresh_hud()
		return true
	if interact_if_reachable:
		ctx._handle_interact_requested()
	else:
		ctx.event_bus.post_message("Targeting %s." % entity.get_display_name())
		ctx._refresh_hud()
	return true


static func target_entity(source, entity_id: String) -> bool:
	var ctx: InputContext = _input_context(source)
	var entity = ctx.entities.get_entity(entity_id)
	if not entity:
		ctx.event_bus.post_message("Target is no longer available.")
		ctx._refresh_hud()
		return false
	ctx._close_open_overlay_panel(false)
	var delta: Vector2 = entity.global_position - ctx.player.global_position
	ctx.player.set_facing_direction(delta)
	ctx.selected_target_id = entity.get_entity_id()
	ctx.manual_target_locked = true
	ctx.target_cycle_index = ctx._index_of_target_id(ctx._get_nearby_entities(), entity_id)
	if ctx.target_cycle_index < 0:
		_begin_auto_interaction(ctx, entity, delta.length())
	else:
		ctx.event_bus.post_message("Targeting %s." % entity.get_display_name())
	ctx._refresh_hud()
	return true


static func move_to_world(source, world_position: Vector2) -> bool:
	var ctx: InputContext = _input_context(source)
	if ctx.player.global_position.distance_to(world_position) <= AUTO_MOVE_ARRIVAL_DISTANCE:
		return false
	if not ctx.player._can_stand_at(world_position):
		ctx.event_bus.post_message("Can't get there.")
		return true
	ctx.player.set_facing_direction(world_position - ctx.player.global_position)
	_begin_auto_move(ctx, world_position)
	ctx._close_open_overlay_panel(false)
	ctx.selected_target_id = ""
	ctx.manual_target_locked = false
	ctx.target_cycle_index = 0
	ctx.event_bus.post_message("Moving.")
	ctx._refresh_hud()
	return true


static func handle_interact_requested(source) -> void:
	var ctx: InputContext = _input_context(source)
	if not String(ctx.auto_interact_target_id).is_empty():
		cancel_auto_interaction(ctx)
		return
	if ctx.auto_move_active:
		cancel_auto_move(ctx)
		return
	if ctx.hud and ctx.hud.is_target_picker_visible():
		ctx.hud.hide_target_picker()
	elif ctx._close_open_overlay_panel():
		return
	var preferred: Dictionary = MainContextActions.preferred_primary(
		MainContextActions.action_list_context(ctx), ctx._get_nearby_entity()
	)
	if not preferred.is_empty():
		ctx._handle_context_action_selected(String(preferred.get("id", "")))
		return
	ctx._interact()


static func update_auto_interaction(source, delta_seconds: float) -> void:
	var ctx: InputContext = _input_context(source)
	var manual_move := _manual_move_vector(ctx)
	if manual_move.length() > 0.05:
		var cancelled_route: bool = (
			not String(ctx.auto_interact_target_id).is_empty() or ctx.auto_move_active
		)
		var unlocked_target := _clear_manual_target_lock(ctx)
		ctx.player.set_facing_direction(manual_move)
		_clear_auto_interaction(ctx)
		_clear_auto_move(ctx)
		if cancelled_route or unlocked_target:
			ctx._refresh_hud()
		return
	if String(ctx.auto_interact_target_id).is_empty():
		update_auto_move(ctx, delta_seconds)
		return
	var entity = ctx.entities.get_entity(ctx.auto_interact_target_id)
	if not entity:
		_clear_auto_interaction(ctx)
		return
	var delta: Vector2 = entity.global_position - ctx.player.global_position
	ctx.player.set_facing_direction(delta)
	ctx.selected_target_id = entity.get_entity_id()
	ctx.manual_target_locked = true
	ctx.target_cycle_index = ctx._index_of_target_id(
		ctx._get_nearby_entities(), ctx.selected_target_id
	)
	if ctx.target_cycle_index >= 0:
		_clear_auto_interaction(ctx)
		ctx._handle_interact_requested()
		return
	_follow_auto_path_or_direction(ctx, entity.global_position, delta, delta_seconds)
	entity = ctx.entities.get_entity(ctx.auto_interact_target_id)
	if not entity or not is_instance_valid(entity):
		_clear_auto_interaction(ctx)
		return
	_track_auto_interaction_progress(ctx, entity, delta_seconds)


static func update_auto_move(source, delta_seconds: float) -> void:
	var ctx: InputContext = _input_context(source)
	if not ctx.auto_move_active:
		return
	var move_target := _current_auto_move_target(ctx)
	var delta: Vector2 = move_target - ctx.player.global_position
	if delta.length() <= AUTO_MOVE_ARRIVAL_DISTANCE:
		if ctx.auto_move_path_index < ctx.auto_move_path.size() - 1:
			ctx.auto_move_path_index += 1
		else:
			_clear_auto_move(ctx)
			ctx._refresh_hud()
		return
	ctx.player.try_move(delta, delta_seconds)
	_track_auto_move_progress(ctx, delta.length(), delta_seconds)


static func cancel_auto_interaction(source) -> void:
	var ctx: InputContext = _input_context(source)
	if String(ctx.auto_interact_target_id).is_empty():
		return
	_clear_auto_interaction(ctx)
	ctx.manual_target_locked = false
	ctx.event_bus.post_message("Stopped.")
	ctx._refresh_hud()


static func cancel_auto_move(source) -> void:
	var ctx: InputContext = _input_context(source)
	if not ctx.auto_move_active:
		return
	_clear_auto_move(ctx)
	ctx.event_bus.post_message("Stopped.")
	ctx._refresh_hud()


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
	return ctx.get_viewport().get_canvas_transform().affine_inverse() * screen_position


static func _begin_auto_interaction(ctx: InputContext, entity, _distance: float) -> void:
	_clear_auto_move(ctx)
	if ctx.entities:
		ctx.entities.set_action_hints({})
	_set_auto_interaction_path(ctx, entity)
	ctx.auto_interact_target_id = entity.get_entity_id()
	ctx.auto_interact_previous_distance = _auto_interaction_progress_distance(ctx, entity)
	ctx.auto_interact_stuck_seconds = 0.0
	ctx.event_bus.post_message("Moving to %s." % entity.get_display_name())


static func _clear_auto_interaction(ctx: InputContext) -> void:
	ctx.auto_interact_target_id = ""
	ctx.auto_interact_previous_distance = INF
	ctx.auto_interact_stuck_seconds = 0.0
	ctx.auto_move_path = []
	ctx.auto_move_path_index = 0


static func _begin_auto_move(ctx: InputContext, world_position: Vector2) -> void:
	_clear_auto_interaction(ctx)
	if ctx.entities:
		ctx.entities.set_action_hints({})
	ctx.auto_move_active = true
	ctx.auto_move_destination = world_position
	_set_auto_path(ctx, world_position)
	ctx.auto_move_previous_distance = ctx.player.global_position.distance_to(world_position)
	ctx.auto_move_stuck_seconds = 0.0


static func _clear_auto_move(ctx: InputContext) -> void:
	ctx.auto_move_active = false
	ctx.auto_move_destination = Vector2.ZERO
	ctx.auto_move_previous_distance = INF
	ctx.auto_move_stuck_seconds = 0.0
	ctx.auto_move_path = []
	ctx.auto_move_path_index = 0


static func _set_auto_path(ctx: InputContext, world_position: Vector2) -> void:
	ctx.auto_move_path = MainPathfinder.path_to(ctx, ctx.player.global_position, world_position)
	ctx.auto_move_path_index = 0


static func _set_auto_interaction_path(ctx: InputContext, entity) -> void:
	var radius: float = ctx.entities.get_interaction_radius(entity)
	var stop_distance := maxf(AUTO_MOVE_ARRIVAL_DISTANCE, radius - 4.0)
	ctx.auto_move_path = MainPathfinder.approach_path_to(
		ctx, ctx.player.global_position, entity.global_position, stop_distance
	)
	ctx.auto_move_path_index = 0


static func _current_auto_move_target(ctx: InputContext) -> Vector2:
	if (
		ctx.auto_move_path.is_empty()
		or ctx.auto_move_path_index < 0
		or ctx.auto_move_path_index >= ctx.auto_move_path.size()
	):
		return ctx.auto_move_destination
	return ctx.auto_move_path[ctx.auto_move_path_index]


static func _follow_auto_path_or_direction(
	ctx: InputContext, destination: Vector2, fallback_delta: Vector2, delta_seconds: float
) -> void:
	if ctx.auto_move_path.is_empty():
		ctx.player.try_move(fallback_delta, delta_seconds)
		return
	var target := _current_auto_move_target(ctx)
	if ctx.player.global_position.distance_to(target) <= AUTO_MOVE_ARRIVAL_DISTANCE:
		if ctx.auto_move_path_index < ctx.auto_move_path.size() - 1:
			ctx.auto_move_path_index += 1
			target = _current_auto_move_target(ctx)
		else:
			target = destination
	ctx.player.try_move(target - ctx.player.global_position, delta_seconds)


static func _manual_move_active(ctx: InputContext) -> bool:
	return _manual_move_vector(ctx).length() > 0.05


static func _manual_move_vector(ctx: InputContext) -> Vector2:
	var direction: Vector2 = ctx.player.external_move_vector
	if Input.is_action_pressed("move_up"):
		direction.y -= 1.0
	if Input.is_action_pressed("move_down"):
		direction.y += 1.0
	if Input.is_action_pressed("move_left"):
		direction.x -= 1.0
	if Input.is_action_pressed("move_right"):
		direction.x += 1.0
	return direction.limit_length(1.0)


static func _clear_manual_target_lock(ctx: InputContext) -> bool:
	if not ctx.manual_target_locked:
		return false
	ctx.manual_target_locked = false
	ctx.selected_target_id = ""
	ctx.target_cycle_index = 0
	if ctx.hud and ctx.hud.is_target_picker_visible():
		ctx.hud.hide_target_picker()
	return true


static func _track_auto_interaction_progress(
	ctx: InputContext, entity, delta_seconds: float
) -> void:
	var current_distance := _auto_interaction_progress_distance(ctx, entity)
	if current_distance < ctx.auto_interact_previous_distance - 0.5:
		ctx.auto_interact_previous_distance = current_distance
		ctx.auto_interact_stuck_seconds = 0.0
		return
	ctx.auto_interact_stuck_seconds += delta_seconds
	if ctx.auto_interact_stuck_seconds >= AUTO_INTERACT_STUCK_SECONDS:
		_clear_auto_interaction(ctx)
		ctx.event_bus.post_message("Can't reach %s." % entity.get_display_name())
	ctx.auto_interact_previous_distance = minf(
		ctx.auto_interact_previous_distance, current_distance
	)


static func _auto_interaction_progress_distance(ctx: InputContext, entity) -> float:
	if not ctx.auto_move_path.is_empty():
		return ctx.player.global_position.distance_to(_current_auto_move_target(ctx))
	return ctx.player.global_position.distance_to(entity.global_position)


static func _track_auto_move_progress(
	ctx: InputContext, distance_before_move: float, delta_seconds: float
) -> void:
	var current_distance: float = ctx.player.global_position.distance_to(
		ctx.auto_move_destination
	)
	if current_distance < ctx.auto_move_previous_distance - 0.5:
		ctx.auto_move_previous_distance = current_distance
		ctx.auto_move_stuck_seconds = 0.0
		return
	ctx.auto_move_stuck_seconds += delta_seconds
	if ctx.auto_move_stuck_seconds >= AUTO_INTERACT_STUCK_SECONDS:
		_clear_auto_move(ctx)
		ctx.event_bus.post_message("Can't get there.")
		ctx._refresh_hud()
	ctx.auto_move_previous_distance = minf(ctx.auto_move_previous_distance, distance_before_move)

