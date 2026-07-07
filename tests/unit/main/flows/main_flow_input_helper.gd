class_name MainFlowInputHelper
extends RefCounted

const MainInputRouter = preload("res://scripts/main/input/main_input_router.gd")
const HudClickHelper = preload("res://tests/unit/ui/hud_click_helper.gd")


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
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	MainInputRouter.handle_event(main, event)


static func click(button: Button, tree: SceneTree) -> void:
	await HudClickHelper.click(button, tree)


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
