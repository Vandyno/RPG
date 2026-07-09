extends GutTest

const RpgTransferItemButton = preload(
	"res://scripts/ui/controls/buttons/rpg_transfer_item_button.gd"
)
const RpgTransferPaneBuilder = preload(
	"res://scripts/ui/systems/panes/rpg_transfer_pane_builder.gd"
)


func test_refresh_ignores_missing_request_or_container() -> void:
	RpgTransferPaneBuilder.refresh(null)
	var request := RpgTransferPaneBuilder.RefreshRequest.new()

	RpgTransferPaneBuilder.refresh(request)

	assert_true(true)


func test_refresh_builds_wide_transfer_panes_with_valid_item_buttons() -> void:
	var container := VBoxContainer.new()
	add_child_autofree(container)
	container.add_child(Label.new())
	var selected_actions: Array[String] = []

	RpgTransferPaneBuilder.refresh(_refresh_request(
		container,
		_transfer_state(),
		"all",
		false,
		func(action_id: String) -> void: selected_actions.append(action_id)
	))

	assert_eq(container.get_child_count(), 1)
	var panes := container.get_child(0)
	assert_true(panes is HBoxContainer)
	assert_eq(panes.name, "TransferInventoryPanes")
	assert_eq((panes as Control).custom_minimum_size, Vector2(0, 360))
	assert_eq(panes.get_child_count(), 2)
	assert_eq((container.find_child("TransferPlayerInventoryTitle", true, false) as Label).text,
		"Your Inventory"
	)
	assert_eq((container.find_child("TransferTargetInventoryTitle", true, false) as Label).text,
		"Bandit Body"
	)
	var put_button := _transfer_button(container, "TransferPut_ItemApple")
	var take_button := _transfer_button(container, "TransferTake_ItemGoldCoin")
	assert_eq(put_button.get_meta("action_id"), "put:item_apple")
	assert_eq(take_button.get_meta("action_id"), "take:item_gold_coin")
	assert_eq(put_button.item_name, "Apple")
	assert_eq(put_button.item_count, 2)
	assert_eq(put_button.action_label, "Put")
	assert_eq(put_button.destination_label, "Body")
	assert_eq(take_button.action_label, "Take")
	assert_eq(take_button.destination_label, "Pack")


func test_refresh_uses_compact_vertical_layout_and_category_empty_state() -> void:
	var container := VBoxContainer.new()
	add_child_autofree(container)

	RpgTransferPaneBuilder.refresh(_refresh_request(
		container,
		_transfer_state(),
		"weapons",
		true,
		func(_action_id: String) -> void: pass
	))

	var panes := container.get_child(0)
	assert_true(panes is VBoxContainer)
	assert_eq((panes as Control).custom_minimum_size, Vector2(0, 300))
	assert_not_null(container.find_child("TransferPlayerInventoryEmpty", true, false))
	assert_not_null(container.find_child("TransferTargetInventoryEmpty", true, false))
	assert_null(container.find_child("TransferPut_ItemApple", true, false))
	assert_null(container.find_child("TransferTake_ItemGoldCoin", true, false))


func test_item_button_skips_missing_id_and_non_positive_counts() -> void:
	var stack := VBoxContainer.new()
	add_child_autofree(stack)

	RpgTransferPaneBuilder._add_item_button(
		stack,
		{"name": "Nameless", "count": 1},
		"take",
		"Pack",
		func(_action_id: String) -> void: pass
	)
	RpgTransferPaneBuilder._add_item_button(
		stack,
		{"item_id": "item_empty", "name": "Empty", "count": 0},
		"take",
		"Pack",
		func(_action_id: String) -> void: pass
	)

	assert_eq(stack.get_child_count(), 0)


func test_category_and_meta_helpers_cover_edges() -> void:
	assert_true(RpgTransferPaneBuilder._matches_category({"type": "ingredient"}, "all"))
	assert_true(RpgTransferPaneBuilder._matches_category({"type": "ingredient"}, ""))
	assert_true(RpgTransferPaneBuilder._matches_category({"type": "ingredient"}, "ingredients"))
	assert_false(RpgTransferPaneBuilder._matches_category({"type": "ingredient"}, "weapons"))
	assert_eq(
		RpgTransferPaneBuilder._item_meta({"weight": 1.5, "value": 7}, "Pack"),
		"1.5 wt   7g   to Pack"
	)
	assert_eq(RpgTransferPaneBuilder._item_meta({"weight": -2, "value": -4}, "Body"), "to Body")
	assert_true(RpgTransferPaneBuilder._panel_style() is StyleBoxFlat)
	assert_true(RpgTransferPaneBuilder._row_style() is StyleBoxFlat)
	assert_true(RpgTransferPaneBuilder._action_style(true) is StyleBoxFlat)
	assert_true(RpgTransferPaneBuilder._action_style(false) is StyleBoxFlat)


func _refresh_request(
	container: BoxContainer,
	state: Dictionary,
	category: String,
	compact: bool,
	action_selected: Callable
) -> RpgTransferPaneBuilder.RefreshRequest:
	var request := RpgTransferPaneBuilder.RefreshRequest.new()
	request.container = container
	request.state = state
	request.category = category
	request.compact = compact
	request.action_selected = action_selected
	return request


func _transfer_state() -> Dictionary:
	return {
		"transfer_open": true,
		"transfer_target": {"name": "Bandit Body"},
		"transfer_player_items": [
			{
				"item_id": "item_apple",
				"name": "Apple",
				"count": 2,
				"type": "ingredient",
				"weight": 0.1,
				"value": 1
			},
			{"item_id": "item_empty", "name": "Empty", "count": 0}
		],
		"transfer_target_items": [
			{
				"item_id": "item_gold_coin",
				"name": "Gold Coin",
				"count": 4,
				"type": "misc",
				"value": 4
			},
			"not an item"
		]
	}


func _transfer_button(container: Node, button_name: String) -> RpgTransferItemButton:
	return container.find_child(button_name, true, false) as RpgTransferItemButton
