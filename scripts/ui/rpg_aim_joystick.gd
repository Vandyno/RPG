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
	var has_label := not text.strip_edges().is_empty()
	var center := Vector2(size.x * 0.5, size.y * (0.39 if has_label else 0.5))
	var radius := minf(size.x, size.y) * (0.34 if has_label else 0.39)
	var knob := center + aim_vector * radius
	draw_circle(center, radius * 1.08, Color(0.0, 0.0, 0.0, 0.34))
	draw_circle(center, radius, Color(0.02, 0.018, 0.014, 0.72))
	draw_arc(center, radius, 0.0, TAU, 56, Color(0.90, 0.72, 0.42, 0.92), 2.0)
	draw_arc(center, radius * 0.58, 0.0, TAU, 48, Color(0.90, 0.72, 0.42, 0.28), 1.0)
	if aim_vector.length() > 0.05:
		draw_line(center, knob, Color(1.0, 0.80, 0.40, 0.78), 2.0)
	draw_circle(knob, radius * 0.34, Color(0.95, 0.78, 0.42, 0.82))
	draw_arc(knob, radius * 0.34, 0.0, TAU, 32, Color(1.0, 0.91, 0.58, 0.68), 1.0)
	_draw_label()


func _draw_label() -> void:
	var label := text.strip_edges()
	if label.is_empty():
		return
	var font := get_theme_default_font()
	var font_size := 8 if size.y < 70.0 else 11
	var lines := label.split("\n", false)
	var line_height := font_size + 1
	var y := size.y - float(lines.size() * line_height) - 3.0
	for index in range(lines.size()):
		draw_string(
			font,
			Vector2(0, y + float(index + 1) * line_height),
			String(lines[index]),
			HORIZONTAL_ALIGNMENT_CENTER,
			size.x,
			font_size,
			Color(1.0, 0.90, 0.68, 0.95)
		)


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
