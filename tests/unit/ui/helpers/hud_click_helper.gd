class_name HudClickHelper
extends RefCounted


static func click(control: Control, tree: SceneTree) -> void:
	_ensure_hud_root_contains(control)
	await mouse_down(control, tree)
	await mouse_up(control, tree)


static func drag(control: Control, offset: Vector2, tree: SceneTree) -> void:
	_ensure_hud_root_contains(control)
	await tree.process_frame
	var local_start := control.size * 0.5
	var local_end := local_start + offset
	_gui_mouse_button(control, local_start, true)
	await tree.process_frame
	_gui_mouse_motion(control, local_end)
	await tree.process_frame
	_gui_mouse_button(control, local_end, false)
	await tree.process_frame


static func mouse_down(control: Control, tree: SceneTree) -> void:
	_ensure_hud_root_contains(control)
	await tree.process_frame
	await _move_to(control, tree)
	_push_mouse_button(control, true)
	_emit_base_button_down(control)
	await tree.process_frame


static func mouse_up(control: Control, tree: SceneTree) -> void:
	_ensure_hud_root_contains(control)
	_push_mouse_button(control, false)
	_emit_base_button_up(control)
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
	var point := _center(control)
	var node := control.get_parent()
	while node:
		if node is Control and node.name == "HudRoot":
			var hud_root := node as Control
			hud_root.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
			hud_root.size = Vector2(
				maxf(hud_root.size.x, point.x + 1.0),
				maxf(hud_root.size.y, point.y + 1.0)
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
	var button := control as BaseButton
	if not button.disabled:
		control.emit_signal("pressed")
