class_name MainFlowInputHelper
extends RefCounted

const MainInputRouter = preload("res://scripts/main/input/main_input_router.gd")
const HudClickHelper = preload("res://tests/unit/ui/helpers/hud_click_helper.gd")


static func target_entity(main, entity_id: String, tree: SceneTree, interact := true) -> bool:
	var entity = main.entities.get_entity(entity_id)
	if not entity:
		return false
	var target_position: Vector2 = entity.global_position
	main.player.set_world_position(target_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	var targeted := MainInputRouter.target_entity(main, entity_id)
	await settle(main, tree)
	if targeted and interact:
		interact_action(main)
		await settle(main, tree)
	return targeted


static func interact_action(main) -> void:
	_action(main, "interact")


static func cycle_target_action(main) -> void:
	_action(main, "cycle_target")


static func save_action(main) -> void:
	_action(main, "save_game")


static func load_action(main) -> void:
	_action(main, "load_game")


static func _action(main, action_id: String) -> void:
	var event := InputEventAction.new()
	event.action = action_id
	event.pressed = true
	MainInputRouter.handle_event(main, event)


static func click(button: Button, tree: SceneTree) -> void:
	await HudClickHelper.click(button, tree)


static func drag(control: Control, offset: Vector2, tree: SceneTree) -> void:
	await HudClickHelper.drag(control, offset, tree)


static func world_click(main, world_position: Vector2, tree: SceneTree) -> void:
	await settle(main, tree)
	var screen_position: Vector2 = main.get_viewport().get_canvas_transform() * world_position
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = screen_position
	press.pressed = true
	main._unhandled_input(press)
	await tree.process_frame
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = screen_position
	release.pressed = false
	main._unhandled_input(release)
	await settle(main, tree)


static func enter_forge(main, tree: SceneTree) -> bool:
	var door = main.entities.get_entity("object_harrow_forge_door")
	if not door:
		return false
	var door_position: Vector2 = door.global_position
	main.player.set_world_position(door_position + Vector2(-12.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	await world_click(main, door_position, tree)
	return main.player.world_layer == "interior:structure_briarwatch_harrow_forge"


static func enter_forge_direct(main) -> bool:
	var door = main.entities.get_entity("object_harrow_forge_door")
	if not door:
		return main.player.world_layer == "interior:structure_briarwatch_harrow_forge"
	main._interact_portal(door)
	return main.player.world_layer == "interior:structure_briarwatch_harrow_forge"


static func exit_forge(main, tree: SceneTree) -> bool:
	var door = main.entities.get_entity("object_harrow_forge_exit")
	if not door:
		return false
	var door_position: Vector2 = door.global_position
	main.player.set_world_position(door_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	await world_click(main, door_position, tree)
	return main.player.world_layer == "surface"


static func exit_forge_direct(main) -> bool:
	var door = main.entities.get_entity("object_harrow_forge_exit")
	if not door:
		return main.player.world_layer == "surface"
	main._interact_portal(door)
	return main.player.world_layer == "surface"


static func enter_town_hall_direct(main) -> bool:
	var door = main.entities.get_entity("object_briarwatch_town_hall_door")
	if not door:
		return main.player.world_layer == "interior:structure_briarwatch_town_hall"
	main._interact_portal(door)
	return main.player.world_layer == "interior:structure_briarwatch_town_hall"


static func exit_town_hall_direct(main) -> bool:
	var door = main.entities.get_entity("object_briarwatch_town_hall_exit")
	if not door:
		return main.player.world_layer == "surface"
	main._interact_portal(door)
	return main.player.world_layer == "surface"


static func settle(main, tree: SceneTree) -> void:
	if main.hud:
		main.hud._apply_layout_for_size(Vector2(1152, 648))
		main.hud.refresh()
	await tree.process_frame
	await tree.process_frame


static func button_containing(container: Node, text: String) -> Button:
	if not container:
		return null
	for child in container.get_children():
		if child is Button and child.visible and String(child.text).contains(text):
			return child
		var descendant := button_containing(child, text)
		if descendant:
			return descendant
	return null


static func label_containing(container: Node, text: String) -> Label:
	if not container:
		return null
	for child in container.get_children():
		if child is Label and child.visible and String(child.text).contains(text):
			return child
		var descendant := label_containing(child, text)
		if descendant:
			return descendant
	return null
