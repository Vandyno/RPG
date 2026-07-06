class_name RpgAimJoystick
extends Button

signal aimed(action_id: String, direction: Vector2)
signal aim_held(action_id: String, direction: Vector2, delta: float)

var action_id := ""
var emit_press_on_release := false
var center_label := ""
var footer_label := ""
var empty_slot := false
var require_direction := true
var show_direction_markers := true
var use_text_as_footer := true
var drag_origin := Vector2.ZERO
var aim_vector := Vector2.ZERO
var dragging := false
var active_touch_index := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	flat = true
	set_process(false)


func _process(delta: float) -> void:
	if dragging and aim_vector.length() > 0.1:
		aim_held.emit(action_id, aim_vector, delta)


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
	elif event is InputEventScreenTouch:
		if event.pressed and active_touch_index == -1:
			active_touch_index = event.index
			_start_aim(event.position)
		elif not event.pressed and event.index == active_touch_index:
			_finish_aim(event.position)
		accept_event()
	elif event is InputEventScreenDrag and dragging and event.index == active_touch_index:
		aim_vector = _direction_from(event.position)
		queue_redraw()
		accept_event()


func _draw() -> void:
	var footer := _footer_text()
	var has_footer := not footer.is_empty()
	var center := Vector2(size.x * 0.5, size.y * (0.43 if has_footer else 0.5))
	var radius := minf(size.x, size.y) * (0.34 if has_footer else 0.38)
	var knob := center + aim_vector * radius
	var rim := Color(0.90, 0.72, 0.42, 0.92)
	var active := dragging or aim_vector.length() > 0.05
	var alpha := 0.46 if empty_slot else 0.86
	draw_circle(center, radius * 1.30, Color(0.0, 0.0, 0.0, 0.48))
	draw_circle(center, radius * 1.08, Color(0.035, 0.031, 0.024, alpha))
	draw_arc(center, radius * 1.26, 0.0, TAU, 72, Color(0.0, 0.0, 0.0, 0.62), 2.0)
	draw_arc(center, radius, 0.0, TAU, 64, rim, 2.8 if active else 2.0)
	draw_arc(center, radius * 0.63, 0.0, TAU, 48, Color(0.90, 0.72, 0.42, 0.32), 1.1)
	if show_direction_markers:
		_draw_direction_markers(center, radius, active)
	if aim_vector.length() > 0.05:
		draw_line(center, knob, Color(1.0, 0.80, 0.40, 0.78), 2.0)
	draw_circle(knob, radius * 0.40, Color(0.95, 0.78, 0.42, 0.90 if active else 0.76))
	draw_circle(knob, radius * 0.23, Color(0.08, 0.065, 0.045, 0.62))
	draw_arc(knob, radius * 0.38, 0.0, TAU, 32, Color(1.0, 0.91, 0.58, 0.72), 1.0)
	_draw_center_label(center, radius)
	_draw_footer_label(footer)


func _draw_direction_markers(center: Vector2, radius: float, active: bool) -> void:
	var marker_color := Color(1.0, 0.86, 0.50, 0.70 if active else 0.46)
	for direction: Vector2 in [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]:
		var outer: Vector2 = center + direction * radius * 0.94
		var inner: Vector2 = center + direction * radius * 0.68
		var side := Vector2(-direction.y, direction.x) * radius * 0.11
		draw_line(inner, outer, marker_color, 1.4)
		draw_line(outer, inner + side, marker_color, 1.2)
		draw_line(outer, inner - side, marker_color, 1.2)


func _draw_center_label(center: Vector2, radius: float) -> void:
	var label := center_label.strip_edges()
	if label.is_empty():
		return
	var font := get_theme_default_font()
	var font_size := 9 if size.y < 70.0 else 13
	var y := center.y + font_size * 0.36
	draw_string(
		font, Vector2(center.x - radius, y), label, HORIZONTAL_ALIGNMENT_CENTER,
		radius * 2.0, font_size, Color(1.0, 0.90, 0.60, 0.95)
	)


func _draw_footer_label(label: String) -> void:
	if label.is_empty():
		return
	var font := get_theme_default_font()
	var font_size := 8 if size.y < 70.0 else 11
	var lines := label.split("\n", false)
	var line_height := font_size + 1
	var y := size.y - float(lines.size() * line_height) - 8.0
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
	set_process(true)
	queue_redraw()


func _finish_aim(position: Vector2) -> void:
	if not dragging:
		return
	aim_vector = _direction_from(position)
	dragging = false
	active_touch_index = -1
	button_pressed = false
	set_process(false)
	if not require_direction or aim_vector.length() > 0.1:
		aimed.emit(action_id, aim_vector)
	if emit_press_on_release:
		pressed.emit()
	aim_vector = Vector2.ZERO
	queue_redraw()


func _direction_from(position: Vector2) -> Vector2:
	var delta := position - drag_origin
	return delta.normalized() if delta.length() > 8.0 else Vector2.ZERO


func _footer_text() -> String:
	var footer := footer_label.strip_edges()
	if not footer.is_empty():
		return footer
	return text.strip_edges() if use_text_as_footer else ""
