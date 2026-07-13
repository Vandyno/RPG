class_name HudClickHelper
extends RefCounted


static func click(control: Control, tree: SceneTree) -> void:
	_ensure_hud_root_contains(control)
	var press_tracker := {"count": 0}
	var pressed_callback := func() -> void: press_tracker["count"] = int(press_tracker["count"]) + 1
	if control is BaseButton:
		(control as BaseButton).pressed.connect(pressed_callback)
	await mouse_down(control, tree)
	await mouse_up(control, tree)
	if not is_instance_valid(control):
		return
	if control is BaseButton and int(press_tracker["count"]) == 0:
		_emit_base_button_pressed(control)
		await tree.process_frame
	if is_instance_valid(control) and control is BaseButton:
		var button := control as BaseButton
		if button.pressed.is_connected(pressed_callback):
			button.pressed.disconnect(pressed_callback)


static func drag(control: Control, offset: Vector2, tree: SceneTree) -> void:
	if control.has_method("_gui_input"):
		await _scripted_drag(control, offset, tree, true)
		return
	await drag_hold(control, offset, tree)
	await mouse_up(control, tree)


static func drag_hold(control: Control, offset: Vector2, tree: SceneTree) -> void:
	if control.has_method("_gui_input"):
		await _scripted_drag(control, offset, tree, false)
		return
	_ensure_hud_root_contains(control)
	await tree.process_frame
	var start := _center(control)
	var end := start + offset
	_ensure_hud_root_contains_point(control, end)
	_push_mouse_motion(start)
	await tree.process_frame
	_push_mouse_button_at(start, true)
	await tree.process_frame
	_push_mouse_motion(end)
	await tree.process_frame


static func _scripted_drag(
	control: Control, offset: Vector2, tree: SceneTree, release: bool
) -> void:
	_ensure_hud_root_contains(control)
	await tree.process_frame
	var local_start := control.size * 0.5
	var local_end := local_start + offset
	_gui_mouse_button(control, local_start, true)
	await tree.process_frame
	_gui_mouse_motion(control, local_end)
	await tree.process_frame
	if release:
		_gui_mouse_button(control, local_end, false)
		await tree.process_frame


static func mouse_down(control: Control, tree: SceneTree) -> void:
	_ensure_hud_root_contains(control)
	var down_tracker := {"count": 0}
	var down_callback := func() -> void: down_tracker["count"] = int(down_tracker["count"]) + 1
	if control is BaseButton:
		(control as BaseButton).button_down.connect(down_callback)
	await tree.process_frame
	await _move_to(control, tree)
	_push_mouse_button(control, true)
	await tree.process_frame
	if is_instance_valid(control) and control is BaseButton:
		var button := control as BaseButton
		if int(down_tracker["count"]) == 0:
			_emit_base_button_down(control)
		if button.button_down.is_connected(down_callback):
			button.button_down.disconnect(down_callback)


static func mouse_up(control: Control, tree: SceneTree) -> void:
	_ensure_hud_root_contains(control)
	if control is BaseButton and control.has_node("HoldActionTimer"):
		_emit_base_button_up(control)
		await tree.process_frame
		return
	var up_tracker := {"count": 0}
	var up_callback := func() -> void: up_tracker["count"] = int(up_tracker["count"]) + 1
	var press_tracker := {"count": 0}
	var pressed_callback := func() -> void: press_tracker["count"] = int(press_tracker["count"]) + 1
	if control is BaseButton:
		var tracked_button := control as BaseButton
		tracked_button.button_up.connect(up_callback)
		tracked_button.pressed.connect(pressed_callback)
	_push_mouse_button(control, false)
	await tree.process_frame
	if is_instance_valid(control) and control is BaseButton:
		var button := control as BaseButton
		if int(up_tracker["count"]) == 0:
			_emit_base_button_up(control)
		var should_emit_pressed := int(press_tracker["count"]) == 0
		if button.button_up.is_connected(up_callback):
			button.button_up.disconnect(up_callback)
		if button.pressed.is_connected(pressed_callback):
			button.pressed.disconnect(pressed_callback)
		if should_emit_pressed:
			_emit_base_button_pressed(control)
			await tree.process_frame


static func _move_to(control: Control, tree: SceneTree) -> void:
	var position := _center(control)
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	Engine.get_main_loop().root.push_input(motion, true)
	await tree.process_frame


static func _push_mouse_button(control: Control, pressed: bool) -> void:
	_push_mouse_button_at(_center(control), pressed)


static func _push_mouse_button_at(position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	event.position = position
	event.global_position = position
	Engine.get_main_loop().root.push_input(event, true)


static func _push_mouse_motion(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = position
	event.global_position = position
	Engine.get_main_loop().root.push_input(event, true)


static func _gui_mouse_button(control: Control, local_position: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	event.position = local_position
	event.global_position = control.get_global_transform_with_canvas().origin + local_position
	control._gui_input(event)


static func _gui_mouse_motion(control: Control, local_position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = local_position
	event.global_position = control.get_global_transform_with_canvas().origin + local_position
	control._gui_input(event)


static func _center(control: Control) -> Vector2:
	return control.get_global_transform_with_canvas().origin + control.size * 0.5


static func _ensure_hud_root_contains(control: Control) -> void:
	_ensure_hud_root_contains_point(control, _center(control))


static func _ensure_hud_root_contains_point(control: Control, point: Vector2) -> void:
	var node := control.get_parent()
	while node:
		if node is Control and node.name == "HudRoot":
			var hud_root := node as Control
			hud_root.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
			hud_root.size = Vector2(
				maxf(hud_root.size.x, point.x + 1.0), maxf(hud_root.size.y, point.y + 1.0)
			)
			return
		node = node.get_parent()


static func _emit_base_button_down(control: Control) -> void:
	if control is BaseButton:
		control.emit_signal("button_down")


static func _emit_base_button_up(control: Control) -> void:
	if not control is BaseButton:
		return
	control.emit_signal("button_up")


static func _emit_base_button_pressed(control: Control) -> void:
	if not control is BaseButton:
		return
	var button := control as BaseButton
	if not button.disabled:
		control.emit_signal("pressed")
