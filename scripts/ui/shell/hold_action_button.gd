class_name HoldActionButton
extends RefCounted


static func bind(
	button: BaseButton,
	press_action: Callable,
	hold_action: Callable,
	hold_seconds := 0.35
) -> void:
	var timer := Timer.new()
	timer.name = "HoldActionTimer"
	timer.one_shot = true
	timer.wait_time = hold_seconds
	button.add_child(timer)
	var state := {"holding": false, "held": false}
	button.button_down.connect(func() -> void: _start_hold(timer, state))
	button.button_up.connect(func() -> void: _stop_hold(timer, state))
	timer.timeout.connect(func() -> void: _finish_hold(state, hold_action))
	button.pressed.connect(func() -> void: _press(state, press_action))


static func _start_hold(timer: Timer, state: Dictionary) -> void:
	state["holding"] = true
	state["held"] = false
	timer.start()


static func _stop_hold(timer: Timer, state: Dictionary) -> void:
	state["holding"] = false
	if not timer.is_stopped():
		timer.stop()


static func _finish_hold(state: Dictionary, hold_action: Callable) -> void:
	if not bool(state.get("holding", false)):
		return
	state["held"] = true
	hold_action.call()


static func _press(state: Dictionary, press_action: Callable) -> void:
	if bool(state.get("held", false)):
		state["held"] = false
		return
	press_action.call()
