class_name VerifyInputHelper
extends RefCounted


static func real_click_button(tree: SceneTree, root: Node, button: Button) -> void:
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


static func settle_main(tree: SceneTree, main, root_size: Vector2i) -> void:
	if main.hud:
		main.hud._apply_layout_for_size(Vector2(root_size))
		main.hud.refresh()
	await tree.process_frame
	await tree.process_frame


static func world_click_entity(tree: SceneTree, main, entity_id: String) -> bool:
	var entity = main.entities.get_entity(entity_id)
	if not entity:
		return false
	var world_position: Vector2 = entity.global_position
	main.player.set_world_position(world_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	await settle_main(tree, main, tree.root.size)
	var screen_position: Vector2 = main.get_viewport().get_canvas_transform() * world_position
	await push_motion(tree, main.get_viewport(), screen_position)
	await _push_unhandled_click(tree, main, screen_position)
	return true


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


static func push_key(tree: SceneTree, viewport: Viewport, keycode: Key) -> void:
	var press := InputEventKey.new()
	press.keycode = keycode
	press.pressed = true
	viewport.push_input(press)
	await tree.process_frame

	var release := InputEventKey.new()
	release.keycode = keycode
	release.pressed = false
	viewport.push_input(release)
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
	if not parent:
		return null
	for child in parent.get_children():
		if child is Button and child.visible and child.name == button_name:
			return child
		var descendant := find_button(child, button_name)
		if descendant:
			return descendant
	return null


static func button_containing(parent: Node, text: String) -> Button:
	if not parent:
		return null
	for child in parent.get_children():
		if child is Button and child.visible and String(child.text).contains(text):
			return child
		var descendant := button_containing(child, text)
		if descendant:
			return descendant
	return null


static func button_with_action_prefix(parent: Node, action_prefix: String) -> Button:
	if not parent:
		return null
	for child in parent.get_children():
		if (
			child is Button
			and child.visible
			and String(child.get_meta("action_id", "")).begins_with(action_prefix)
		):
			return child
		var descendant := button_with_action_prefix(child, action_prefix)
		if descendant:
			return descendant
	return null


static func _push_unhandled_click(tree: SceneTree, main, screen_position: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	press.position = screen_position
	press.global_position = screen_position
	main._unhandled_input(press)
	await tree.process_frame

	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.button_mask = 0
	release.pressed = false
	release.position = screen_position
	release.global_position = screen_position
	main._unhandled_input(release)
	await tree.process_frame
