extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainSystemsActions = preload("res://scripts/main/actions/main_systems_actions.gd")


func test_consumable_applies_visible_status_that_modifies_next_attacks() -> void:
	var main := Main.new()
	add_child_autofree(main)

	_select_entity(main, "pickup_roadside_draught")
	main._handle_interact_requested()
	assert_eq(main.inventory.get_count("item_roadside_draught"), 1)

	main.hud.toggle_systems()
	var use_button := _button_containing(main.hud.systems_action_list, "Use Roadside Draught")
	assert_not_null(use_button)
	use_button.pressed.emit()

	assert_eq(main.inventory.get_count("item_roadside_draught"), 0)
	assert_eq(main.statuses.get_remaining_charges("status_road_focus"), 2)
	assert_true(main.hud.status_label.text.contains("Road Focus"))
	main.hud.set_systems_tab("character")
	assert_true(main.hud.systems_body_label.text.contains("Road Focus"))
	main.hud.hide_systems_panel()

	_equip_hatchet(main)
	var enemy = main.entities.get_entity("npc_road_thug")
	assert_not_null(enemy)
	main.player.set_world_position(enemy.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.RIGHT)

	assert_eq(main.combat.health_by_entity_id["npc_road_thug"], 3)
	assert_eq(main.statuses.get_remaining_charges("status_road_focus"), 1)
	assert_true(main.hud.log_label.text.contains("hits Road Thug for 9"))


func _select_entity(main, entity_id: String) -> void:
	var target = main.entities.get_entity(entity_id)
	if target:
		main.player.set_world_position(target.global_position + Vector2(-8.0, 0.0))
		main.player.set_facing_direction(Vector2.RIGHT)
		main._update_nearby()
	for _i in range(32):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)


func _button_containing(container: Node, text: String) -> Button:
	for child in container.get_children():
		if child is Button and child.text.contains(text):
			return child
	return null


func _equip_hatchet(main) -> void:
	if not main.inventory.has_item("item_road_hatchet"):
		main.inventory.add_item("item_road_hatchet", 1)
	main.equipment.equip_item_to_slot("item_road_hatchet", "right_hand")
