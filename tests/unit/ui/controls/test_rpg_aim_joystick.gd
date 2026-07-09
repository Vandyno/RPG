extends GutTest

const RpgAimJoystick = preload("res://scripts/ui/controls/input/rpg_aim_joystick.gd")


func test_aim_joystick_emits_held_direction_while_dragging() -> void:
	var joystick := RpgAimJoystick.new()
	add_child_autofree(joystick)
	joystick.action_id = "ability_1"
	var held_events: Array[Dictionary] = []
	joystick.aim_held.connect(
		func(action_id: String, direction: Vector2, delta: float) -> void:
			held_events.append({"action_id": action_id, "direction": direction, "delta": delta})
	)

	joystick._start_aim(Vector2.ZERO)
	joystick.aim_vector = Vector2.UP
	joystick._process(0.25)

	assert_eq(held_events.size(), 1)
	assert_eq(held_events[0]["action_id"], "ability_1")
	assert_eq(held_events[0]["direction"], Vector2.UP)
	assert_eq(held_events[0]["delta"], 0.25)
