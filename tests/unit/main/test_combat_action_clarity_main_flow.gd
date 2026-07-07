extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainSystemsActions = preload("res://scripts/main/actions/main_systems_actions.gd")


func test_hostile_actor_has_no_interaction_quick_action_panel() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_stand_by_hostile_actor(main, "npc_road_thug")

	assert_false(main.hud.context_action_panel.visible)
	assert_ne(main.selected_target_id, "npc_road_thug")
	assert_null(_visible_button_containing(main.hud.context_action_buttons, "Attack"))
	assert_null(_visible_button_containing(main.hud.context_action_buttons, "Guard"))


func test_hostile_actor_context_stays_hidden_after_directional_attack() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_equip_hatchet(main)
	_stand_by_hostile_actor(main, "npc_road_thug")

	assert_false(main.hud.context_action_panel.visible)

	MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.RIGHT)

	assert_eq(main.combat.health_by_entity_id["npc_road_thug"], 6)
	assert_false(main.hud.context_action_panel.visible)
	assert_null(_visible_button_containing(main.hud.context_action_buttons, "Guard"))


func _stand_by_hostile_actor(main, entity_id: String) -> void:
	var target = main.entities.get_entity(entity_id)
	assert_not_null(target)
	main.player.set_world_position(target.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	main._update_nearby()


func _equip_hatchet(main) -> void:
	if not main.inventory.has_item("item_road_hatchet"):
		main.inventory.add_item("item_road_hatchet", 1)
	main.equipment.equip_item_to_slot("item_road_hatchet", "right_hand")


func _visible_button_containing(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.visible and child.text.contains(text):
			return child
	return null
