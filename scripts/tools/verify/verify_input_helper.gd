class_name VerifyInputHelper
extends RefCounted


static func click_button(tree: SceneTree, root: Node, button: Button) -> void:
	var button_name := String(button.name)
	await reveal_button(tree, button)
	button = find_button(root, button_name)
	if not button:
		return
	var viewport: Viewport = button.get_viewport()
	var position := button.get_global_rect().get_center()
	await push_motion(tree, viewport, position)
	button = find_button(root, button_name)
	if button:
		viewport = button.get_viewport()
		position = button.get_global_rect().get_center()
	await push_click(tree, viewport, position)


static func push_click(tree: SceneTree, viewport: Viewport, position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = position
	press.global_position = position
	viewport.push_input(press, true)
	await tree.process_frame

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.button_mask = 0
	release.pressed = false
	release.position = position
	release.global_position = position
	viewport.push_input(release, true)
	await tree.process_frame


static func push_motion(tree: SceneTree, viewport: Viewport, position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.global_position = position
	motion.button_mask = 0
	viewport.push_input(motion, true)
	await tree.process_frame


static func reveal_button(tree: SceneTree, button: Button) -> void:
	var parent := button.get_parent()
	while parent:
		if parent is ScrollContainer:
			parent.ensure_control_visible(button)
			await tree.process_frame
			await tree.process_frame
			return
		parent = parent.get_parent()


static func find_button(parent: Node, button_name: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.visible and child.name == button_name:
			return child
		var descendant := find_button(child, button_name)
		if descendant:
			return descendant
	return null
