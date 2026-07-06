class_name MainInputRouter
extends RefCounted

const MainContextActions = preload("res://scripts/main/actions/main_context_actions.gd")
const MainPathfinder = preload("res://scripts/main/input/main_pathfinder.gd")

const AUTO_INTERACT_STUCK_SECONDS := 0.7
const AUTO_MOVE_ARRIVAL_DISTANCE := 8.0
const WORLD_PICK_RADIUS := 36.0
const WORLD_TOUCH_PICK_RADIUS := 48.0


static func handle_event(main, event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if _handle_pointer_event(main, event):
		return
	if event.is_action_pressed("interact"):
		main._handle_interact_requested()
	elif event.is_action_pressed("save_game"):
		main._handle_save_requested()
	elif event.is_action_pressed("load_game"):
		main._handle_load_requested()
	elif event.is_action_pressed("toggle_debug"):
		main.hud.toggle_debug()
	elif event.is_action_pressed("toggle_character_creator"):
		main.toggle_debug_character_creator()
	elif event.is_action_pressed("toggle_systems"):
		main.hud.toggle_systems()
	elif event.is_action_pressed("cycle_target"):
		main._handle_cycle_target_requested()


static func target_world(
	main, world_position: Vector2, interact_if_reachable := true, pick_radius := WORLD_PICK_RADIUS
) -> bool:
	var entity = main.entities.get_interactable_at_world(world_position, pick_radius)
	if not entity:
		return false
	if entity.get_kind() == "enemy":
		return false
	main._close_open_overlay_panel(false)
	var delta: Vector2 = entity.global_position - main.player.global_position
	main.player.set_facing_direction(delta)
	main.selected_target_id = entity.get_entity_id()
	main.manual_target_locked = true
	main.target_cycle_index = main._index_of_target_id(
		main._get_nearby_entities(), main.selected_target_id
	)
	if main.target_cycle_index < 0:
		_begin_auto_interaction(main, entity, delta.length())
		main._refresh_hud()
		return true
	if interact_if_reachable:
		main._handle_interact_requested()
	else:
		main.event_bus.post_message("Targeting %s." % entity.get_display_name())
		main._refresh_hud()
	return true


static func target_entity(main, entity_id: String) -> bool:
	var entity = main.entities.get_entity(entity_id)
	if not entity:
		main.event_bus.post_message("Target is no longer available.")
		main._refresh_hud()
		return false
	main._close_open_overlay_panel(false)
	var delta: Vector2 = entity.global_position - main.player.global_position
	main.player.set_facing_direction(delta)
	main.selected_target_id = entity.get_entity_id()
	main.manual_target_locked = true
	main.target_cycle_index = main._index_of_target_id(main._get_nearby_entities(), entity_id)
	if main.target_cycle_index < 0:
		_begin_auto_interaction(main, entity, delta.length())
	else:
		main.event_bus.post_message("Targeting %s." % entity.get_display_name())
	main._refresh_hud()
	return true


static func move_to_world(main, world_position: Vector2) -> bool:
	if main.player.global_position.distance_to(world_position) <= AUTO_MOVE_ARRIVAL_DISTANCE:
		return false
	if not main.player._can_stand_at(world_position):
		main.event_bus.post_message("Can't get there.")
		return true
	main.player.set_facing_direction(world_position - main.player.global_position)
	_begin_auto_move(main, world_position)
	main._close_open_overlay_panel(false)
	main.selected_target_id = ""
	main.manual_target_locked = false
	main.target_cycle_index = 0
	main.event_bus.post_message("Moving.")
	main._refresh_hud()
	return true


static func handle_interact_requested(main) -> void:
	if not String(main.auto_interact_target_id).is_empty():
		cancel_auto_interaction(main)
		return
	if main.auto_move_active:
		cancel_auto_move(main)
		return
	if main.hud and main.hud.is_target_picker_visible():
		main.hud.hide_target_picker()
	elif main._close_open_overlay_panel():
		return
	var preferred: Dictionary = MainContextActions.preferred_primary(
		MainContextActions.context(main), main._get_nearby_entity()
	)
	if not preferred.is_empty():
		main._handle_context_action_selected(String(preferred.get("id", "")))
		return
	main._interact()


static func update_auto_interaction(main, delta_seconds: float) -> void:
	var manual_move := _manual_move_vector(main)
	if manual_move.length() > 0.05:
		var cancelled_route: bool = (
			not String(main.auto_interact_target_id).is_empty() or main.auto_move_active
		)
		var unlocked_target := _clear_manual_target_lock(main)
		main.player.set_facing_direction(manual_move)
		_clear_auto_interaction(main)
		_clear_auto_move(main)
		if cancelled_route or unlocked_target:
			main._refresh_hud()
		return
	if String(main.auto_interact_target_id).is_empty():
		update_auto_move(main, delta_seconds)
		return
	var entity = main.entities.get_entity(main.auto_interact_target_id)
	if not entity:
		_clear_auto_interaction(main)
		return
	var delta: Vector2 = entity.global_position - main.player.global_position
	main.player.set_facing_direction(delta)
	main.selected_target_id = entity.get_entity_id()
	main.manual_target_locked = true
	main.target_cycle_index = main._index_of_target_id(
		main._get_nearby_entities(), main.selected_target_id
	)
	if main.target_cycle_index >= 0:
		_clear_auto_interaction(main)
		main._handle_interact_requested()
		return
	_follow_auto_path_or_direction(main, entity.global_position, delta, delta_seconds)
	entity = main.entities.get_entity(main.auto_interact_target_id)
	if not entity or not is_instance_valid(entity):
		_clear_auto_interaction(main)
		return
	_track_auto_interaction_progress(main, entity, delta_seconds)


static func update_auto_move(main, delta_seconds: float) -> void:
	if not main.auto_move_active:
		return
	var move_target := _current_auto_move_target(main)
	var delta: Vector2 = move_target - main.player.global_position
	if delta.length() <= AUTO_MOVE_ARRIVAL_DISTANCE:
		if main.auto_move_path_index < main.auto_move_path.size() - 1:
			main.auto_move_path_index += 1
		else:
			_clear_auto_move(main)
			main._refresh_hud()
		return
	main.player.try_move(delta, delta_seconds)
	_track_auto_move_progress(main, delta.length(), delta_seconds)


static func cancel_auto_interaction(main) -> void:
	if String(main.auto_interact_target_id).is_empty():
		return
	_clear_auto_interaction(main)
	main.manual_target_locked = false
	main.event_bus.post_message("Stopped.")
	main._refresh_hud()


static func cancel_auto_move(main) -> void:
	if not main.auto_move_active:
		return
	_clear_auto_move(main)
	main.event_bus.post_message("Stopped.")
	main._refresh_hud()


static func _handle_pointer_event(main, event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mouse_world := _screen_to_world(main, event.position)
		return target_world(main, mouse_world) or move_to_world(main, mouse_world)
	if event is InputEventScreenTouch and event.pressed:
		var touch_world := _screen_to_world(main, event.position)
		return (
			target_world(main, touch_world, true, WORLD_TOUCH_PICK_RADIUS)
			or move_to_world(main, touch_world)
		)
	return false


static func _screen_to_world(main, screen_position: Vector2) -> Vector2:
	return main.get_viewport().get_canvas_transform().affine_inverse() * screen_position


static func _begin_auto_interaction(main, entity, _distance: float) -> void:
	_clear_auto_move(main)
	if main.entities:
		main.entities.set_action_hints({})
	_set_auto_interaction_path(main, entity)
	main.auto_interact_target_id = entity.get_entity_id()
	main.auto_interact_previous_distance = _auto_interaction_progress_distance(main, entity)
	main.auto_interact_stuck_seconds = 0.0
	main.event_bus.post_message("Moving to %s." % entity.get_display_name())


static func _clear_auto_interaction(main) -> void:
	main.auto_interact_target_id = ""
	main.auto_interact_previous_distance = INF
	main.auto_interact_stuck_seconds = 0.0
	main.auto_move_path = []
	main.auto_move_path_index = 0


static func _begin_auto_move(main, world_position: Vector2) -> void:
	_clear_auto_interaction(main)
	if main.entities:
		main.entities.set_action_hints({})
	main.auto_move_active = true
	main.auto_move_destination = world_position
	_set_auto_path(main, world_position)
	main.auto_move_previous_distance = main.player.global_position.distance_to(world_position)
	main.auto_move_stuck_seconds = 0.0


static func _clear_auto_move(main) -> void:
	main.auto_move_active = false
	main.auto_move_destination = Vector2.ZERO
	main.auto_move_previous_distance = INF
	main.auto_move_stuck_seconds = 0.0
	main.auto_move_path = []
	main.auto_move_path_index = 0


static func _set_auto_path(main, world_position: Vector2) -> void:
	main.auto_move_path = MainPathfinder.path_to(main, main.player.global_position, world_position)
	main.auto_move_path_index = 0


static func _set_auto_interaction_path(main, entity) -> void:
	var radius: float = main.entities.get_interaction_radius(entity)
	var stop_distance := maxf(AUTO_MOVE_ARRIVAL_DISTANCE, radius - 4.0)
	main.auto_move_path = MainPathfinder.approach_path_to(
		main, main.player.global_position, entity.global_position, stop_distance
	)
	main.auto_move_path_index = 0


static func _current_auto_move_target(main) -> Vector2:
	if (
		main.auto_move_path.is_empty()
		or main.auto_move_path_index < 0
		or main.auto_move_path_index >= main.auto_move_path.size()
	):
		return main.auto_move_destination
	return main.auto_move_path[main.auto_move_path_index]


static func _follow_auto_path_or_direction(
	main, destination: Vector2, fallback_delta: Vector2, delta_seconds: float
) -> void:
	if main.auto_move_path.is_empty():
		main.player.try_move(fallback_delta, delta_seconds)
		return
	var target := _current_auto_move_target(main)
	if main.player.global_position.distance_to(target) <= AUTO_MOVE_ARRIVAL_DISTANCE:
		if main.auto_move_path_index < main.auto_move_path.size() - 1:
			main.auto_move_path_index += 1
			target = _current_auto_move_target(main)
		else:
			target = destination
	main.player.try_move(target - main.player.global_position, delta_seconds)


static func _manual_move_active(main) -> bool:
	return _manual_move_vector(main).length() > 0.05


static func _manual_move_vector(main) -> Vector2:
	var direction: Vector2 = main.player.external_move_vector
	if Input.is_action_pressed("move_up"):
		direction.y -= 1.0
	if Input.is_action_pressed("move_down"):
		direction.y += 1.0
	if Input.is_action_pressed("move_left"):
		direction.x -= 1.0
	if Input.is_action_pressed("move_right"):
		direction.x += 1.0
	return direction.limit_length(1.0)


static func _clear_manual_target_lock(main) -> bool:
	if not main.manual_target_locked:
		return false
	main.manual_target_locked = false
	main.selected_target_id = ""
	main.target_cycle_index = 0
	if main.hud and main.hud.is_target_picker_visible():
		main.hud.hide_target_picker()
	return true


static func _track_auto_interaction_progress(main, entity, delta_seconds: float) -> void:
	var current_distance := _auto_interaction_progress_distance(main, entity)
	if current_distance < main.auto_interact_previous_distance - 0.5:
		main.auto_interact_previous_distance = current_distance
		main.auto_interact_stuck_seconds = 0.0
		return
	main.auto_interact_stuck_seconds += delta_seconds
	if main.auto_interact_stuck_seconds >= AUTO_INTERACT_STUCK_SECONDS:
		_clear_auto_interaction(main)
		main.event_bus.post_message("Can't reach %s." % entity.get_display_name())
	main.auto_interact_previous_distance = minf(
		main.auto_interact_previous_distance, current_distance
	)


static func _auto_interaction_progress_distance(main, entity) -> float:
	if not main.auto_move_path.is_empty():
		return main.player.global_position.distance_to(_current_auto_move_target(main))
	return main.player.global_position.distance_to(entity.global_position)


static func _track_auto_move_progress(
	main, distance_before_move: float, delta_seconds: float
) -> void:
	var current_distance: float = main.player.global_position.distance_to(
		main.auto_move_destination
	)
	if current_distance < main.auto_move_previous_distance - 0.5:
		main.auto_move_previous_distance = current_distance
		main.auto_move_stuck_seconds = 0.0
		return
	main.auto_move_stuck_seconds += delta_seconds
	if main.auto_move_stuck_seconds >= AUTO_INTERACT_STUCK_SECONDS:
		_clear_auto_move(main)
		main.event_bus.post_message("Can't get there.")
		main._refresh_hud()
	main.auto_move_previous_distance = minf(main.auto_move_previous_distance, distance_before_move)
