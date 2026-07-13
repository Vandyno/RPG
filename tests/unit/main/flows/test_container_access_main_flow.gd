extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainFlowInputHelper = preload("res://tests/unit/main/flows/main_flow_input_helper.gd")


func test_container_open_conditions_gate_loot_until_unlocked() -> void:
	var main := Main.new()
	add_child_autofree(main)
	assert_true(MainFlowInputHelper.enter_town_hall_direct(main))

	assert_true(
		await MainFlowInputHelper.target_entity(
			main, "object_sealed_strongbox", get_tree(), false
		)
	)
	assert_eq(main.get_debug_state()["target_detail"], "Container: locked")
	assert_eq(main.get_debug_state()["primary_action"], "Locked")
	assert_true(await MainFlowInputHelper.target_entity(main, "object_sealed_strongbox", get_tree()))
	assert_eq(main.inventory.get_count("item_gold_coin"), 0)
	assert_false(main.chunks.is_object_opened("object_sealed_strongbox", Vector2i(9, 5)))
	assert_true(main.hud.log_label.text.contains("strongbox seal matches"))

	assert_true(await MainFlowInputHelper.target_entity(main, "object_road_notice", get_tree()))
	main.hud.hide_content_card()
	assert_true(
		await MainFlowInputHelper.target_entity(
			main, "object_sealed_strongbox", get_tree(), false
		)
	)
	assert_eq(main.get_debug_state()["target_detail"], "Container: closed")
	assert_eq(main.get_debug_state()["primary_action"], "Open")
	assert_true(await MainFlowInputHelper.target_entity(main, "object_sealed_strongbox", get_tree()))

	assert_true(main.hud.is_systems_panel_visible())
	assert_eq(main.hud.get_systems_tab(), "inventory")
	assert_true(main.get_hud_state()["transfer_open"])
	assert_not_null(main.hud.systems_item_list.find_child("TransferPlayerInventory", true, false))
	assert_not_null(main.hud.systems_item_list.find_child("TransferTargetInventory", true, false))
	assert_not_null(
		MainFlowInputHelper.label_containing(main.hud.systems_item_list, "Your Inventory")
	)
	assert_not_null(
		MainFlowInputHelper.label_containing(main.hud.systems_item_list, "Warden's Strongbox")
	)
	assert_eq(main.inventory.get_count("item_gold_coin"), 0)
	assert_eq(main.inventory.get_count_for_owner("loot:object_sealed_strongbox", "item_gold_coin"), 5)
	assert_not_null(main.hud.systems_item_list.find_child("TransferTake_ItemGoldCoin", true, false))

	await MainFlowInputHelper.click(
		main.hud.systems_item_list.find_child("TransferTake_ItemGoldCoin", true, false) as Button,
		get_tree()
	)
	assert_eq(main.inventory.get_count("item_gold_coin"), 1)
	assert_eq(main.inventory.get_count_for_owner("loot:object_sealed_strongbox", "item_gold_coin"), 4)

	await MainFlowInputHelper.click(
		main.hud.systems_item_list.find_child("TransferPut_ItemGoldCoin", true, false) as Button,
		get_tree()
	)
	assert_eq(main.inventory.get_count("item_gold_coin"), 0)
	assert_eq(main.inventory.get_count_for_owner("loot:object_sealed_strongbox", "item_gold_coin"), 5)
	assert_true(
		main.chunks.is_object_opened(
			"object_sealed_strongbox", Vector2i(9, 5), "interior:structure_briarwatch_town_hall"
		)
	)
	assert_eq(main.get_debug_state()["target_detail"], "Container: opened")
	assert_eq(main.get_debug_state()["primary_action"], "Opened")


func _button_containing(container: Node, text: String) -> Button:
	for child in container.get_children():
		if child is Button and child.visible and (child as Button).text.contains(text):
			return child
		var descendant := _button_containing(child, text)
		if descendant:
			return descendant
	return null


func _label_containing(container: Node, text: String) -> Label:
	for child in container.get_children():
		if child is Label and child.visible and (child as Label).text.contains(text):
			return child
		var descendant := _label_containing(child, text)
		if descendant:
			return descendant
	return null


func _select_entity(main, entity_id: String) -> void:
	var target = main.entities.get_entity(entity_id)
	if target:
		main.player.set_world_position(target.global_position + Vector2(-8.0, 0.0))
		main.player.set_facing_direction(Vector2.RIGHT)
		main._update_nearby()
	for _i in range(24):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			return
		MainFlowInputHelper.cycle_target_action(main)
	fail_test("Could not select nearby entity: %s" % entity_id)
