extends GutTest

const MainInputRouter = preload("res://scripts/main/input/main_input_router.gd")


class EventBusStub:
	var messages: Array[String] = []

	func post_message(message: String) -> void:
		messages.append(message)


class HudStub:
	var target_picker_visible := false
	var hidden_target_picker := false

	func is_target_picker_visible() -> bool:
		return target_picker_visible

	func hide_target_picker() -> void:
		hidden_target_picker = true
		target_picker_visible = false


class PlayerStub:
	var global_position := Vector2.ZERO
	var external_move_vector := Vector2.ZERO
	var facing_direction := Vector2.ZERO
	var can_stand := true

	func _can_stand_at(_world_position: Vector2) -> bool:
		return can_stand

	func set_facing_direction(direction: Vector2) -> void:
		facing_direction = direction

	func try_move(delta: Vector2, _delta_seconds: float) -> void:
		global_position += delta.limit_length(8.0)


class EntitiesStub:
	var hints_cleared := false

	func get_entity(_entity_id: String):
		return null

	func get_interactable_at_world(_world_position: Vector2, _pick_radius: float):
		return null

	func set_action_hints(hints: Dictionary) -> void:
		hints_cleared = hints.is_empty()


class MainStub:
	var auto_interact_target_id := "target"
	var auto_interact_previous_distance := 10.0
	var auto_interact_stuck_seconds := 1.0
	var auto_move_active := true
	var auto_move_destination := Vector2(64, 0)
	var auto_move_previous_distance := 64.0
	var auto_move_stuck_seconds := 1.0
	var auto_move_path = [Vector2(32, 0), Vector2(64, 0)]
	var auto_move_path_index := 0
	var manual_target_locked := true
	var selected_target_id := "target"
	var target_cycle_index := 2
	var event_bus := EventBusStub.new()
	var hud := HudStub.new()
	var player := PlayerStub.new()
	var entities := EntitiesStub.new()
	var refreshed := 0

	func _refresh_hud() -> void:
		refreshed += 1

	func _close_open_overlay_panel(_refresh := true) -> bool:
		return false


func test_cancel_auto_interaction_clears_route_and_refreshes() -> void:
	var main := MainStub.new()

	MainInputRouter.cancel_auto_interaction(main)

	assert_eq(main.auto_interact_target_id, "")
	assert_false(main.manual_target_locked)
	assert_eq(main.auto_move_path, [])
	assert_eq(main.event_bus.messages, ["Stopped."])
	assert_eq(main.refreshed, 1)


func test_target_entity_missing_reports_stale_target() -> void:
	var main := MainStub.new()

	assert_false(MainInputRouter.target_entity(main, "missing"))
	assert_eq(main.event_bus.messages, ["Target is no longer available."])
	assert_eq(main.refreshed, 1)


func test_move_to_world_rejects_unstandable_destination() -> void:
	var main := MainStub.new()
	main.player.can_stand = false

	assert_true(MainInputRouter.move_to_world(main, Vector2(96, 0)))
	assert_eq(main.event_bus.messages, ["Can't get there."])
	assert_eq(main.auto_move_path_index, 0)


func test_manual_move_cancels_auto_routes_and_target_lock() -> void:
	var main := MainStub.new()
	main.player.external_move_vector = Vector2.RIGHT

	MainInputRouter.update_auto_interaction(main, 0.1)

	assert_eq(main.auto_interact_target_id, "")
	assert_false(main.auto_move_active)
	assert_false(main.manual_target_locked)
	assert_eq(main.selected_target_id, "")
	assert_eq(main.player.facing_direction, Vector2.RIGHT)
	assert_eq(main.refreshed, 1)
