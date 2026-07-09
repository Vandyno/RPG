extends GutTest

const HoldActionButton = preload("res://scripts/ui/shell/hold_action_button.gd")


func test_bind_routes_short_press_to_press_action() -> void:
	var button := Button.new()
	add_child_autofree(button)
	var pressed: Array[String] = []
	var held: Array[String] = []

	HoldActionButton.bind(
		button,
		func() -> void: pressed.append("press"),
		func() -> void: held.append("hold")
	)
	button.button_down.emit()
	button.button_up.emit()
	button.pressed.emit()

	assert_eq(pressed, ["press"])
	assert_eq(held, [])


func test_bind_routes_hold_once_and_suppresses_followup_press() -> void:
	var button := Button.new()
	add_child_autofree(button)
	var pressed: Array[String] = []
	var held: Array[String] = []

	HoldActionButton.bind(
		button,
		func() -> void: pressed.append("press"),
		func() -> void: held.append("hold")
	)
	var timer := button.get_node("HoldActionTimer") as Timer
	button.button_down.emit()
	timer.timeout.emit()
	button.button_up.emit()
	button.pressed.emit()

	assert_eq(pressed, [])
	assert_eq(held, ["hold"])


func test_finish_hold_ignores_timeout_after_release() -> void:
	var held: Array[String] = []
	var state := {"holding": false, "held": false}

	HoldActionButton._finish_hold(state, func() -> void: held.append("hold"))

	assert_eq(held, [])
	assert_false(bool(state["held"]))
