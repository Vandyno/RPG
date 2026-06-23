class_name RpgAimJoystick
extends Button

signal aimed(action_id: String, direction: Vector2)

var action_id := ""
var emit_press_on_release := false
var drag_origin := Vector2.ZERO
var aim_vector := Vector2.ZERO
var dragging := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_aim(event.position)
		else:
			_finish_aim(event.position)
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		aim_vector = _direction_from(event.position)
		queue_redraw()
		accept_event()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.34
	var knob := center + aim_vector * radius
	draw_circle(center, radius, Color(0.02, 0.018, 0.014, 0.64))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.84, 0.66, 0.36, 0.82), 2.0)
	if aim_vector.length() > 0.05:
		draw_line(center, knob, Color(1.0, 0.80, 0.40, 0.78), 2.0)
	draw_circle(knob, radius * 0.32, Color(0.90, 0.73, 0.40, 0.72))


func _start_aim(position: Vector2) -> void:
	dragging = true
	drag_origin = position
	aim_vector = Vector2.ZERO
	button_pressed = true
	queue_redraw()


func _finish_aim(position: Vector2) -> void:
	if not dragging:
		return
	aim_vector = _direction_from(position)
	dragging = false
	button_pressed = false
	aimed.emit(action_id, aim_vector)
	if emit_press_on_release:
		pressed.emit()
	aim_vector = Vector2.ZERO
	queue_redraw()


func _direction_from(position: Vector2) -> Vector2:
	var delta := position - drag_origin
	return delta.normalized() if delta.length() > 8.0 else Vector2.ZERO
