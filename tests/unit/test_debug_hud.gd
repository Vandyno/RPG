extends GutTest

const DebugHud = preload("res://scripts/ui/debug_hud.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")


func test_hud_renders_mobile_friendly_status_prompt_and_content_card() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := DebugHud.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_sample_state"))

	assert_eq(int(hud.health_bar.value), 76)
	assert_eq(int(hud.health_bar.max_value), 100)
	assert_eq(hud.health_bar.tooltip_text, "Health: 76/100")
	assert_eq(hud.health_label.text, "Health 76/100")
	assert_true(hud.status_label.text.contains("Briarwatch Crossroads"))
	assert_true(hud.status_label.text.contains("Day 1, 16:00"))
	assert_false(hud.status_label.text.contains("Inventory: Old Toolbox x1"))
	assert_false(hud.status_label.text.contains("Tile (0, 0)"))
	assert_true(hud.status_label.text.contains("Quest: The Missing Tools"))
	assert_true(hud.status_label.text.contains("Goal: Return the toolbox to Harrow Venn."))
	assert_true(hud.status_label.text.contains("Next: E 5.0t Harrow Venn"))
	assert_true(hud.prompt_label.text.begins_with("Read\nRoad Notice"))
	assert_true(hud.prompt_label.text.contains("Road Notice"))
	assert_true(hud.prompt_label.text.contains("Readable: Briarwatch Road Notice"))
	assert_eq(hud.primary_action_button.text, "Read")
	var move_vectors: Array[Vector2] = []
	hud.move_vector_changed.connect(
		func(direction: Vector2) -> void: move_vectors.append(direction)
	)
	hud.set_touch_move_vector(Vector2(2.0, 0.0))
	hud.set_touch_move_vector(Vector2.ZERO)
	assert_eq(move_vectors.size(), 2)
	assert_eq(move_vectors[0], Vector2.RIGHT)
	assert_eq(move_vectors[1], Vector2.ZERO)
	assert_eq(hud.get_touch_move_vector(), Vector2.ZERO)
	var cycle_target_presses: Array[String] = []
	hud.cycle_target_pressed.connect(func() -> void: cycle_target_presses.append("next"))
	var next_target_button := hud.root.get_node("ActionButtons/TargetButton") as Button
	assert_not_null(next_target_button)
	assert_eq(next_target_button.text, "Next")
	assert_eq(next_target_button.tooltip_text, "Next target: Harrow Venn. Hold for target list.")
	next_target_button.pressed.emit()
	assert_eq(cycle_target_presses, ["next"])
	assert_false(hud.is_target_picker_visible())
	var hold_timer := next_target_button.get_node("HoldActionTimer") as Timer
	next_target_button.button_down.emit()
	hold_timer.timeout.emit()
	assert_true(hud.is_target_picker_visible())
	next_target_button.button_up.emit()
	next_target_button.pressed.emit()
	assert_eq(cycle_target_presses, ["next"])
	hud.hide_target_picker()
	assert_false(hud.is_target_picker_visible())

	var selected_targets: Array[String] = []
	var used_targets: Array[String] = []
	hud.target_selected.connect(func(entity_id: String) -> void: selected_targets.append(entity_id))
	hud.target_used.connect(func(entity_id: String) -> void: used_targets.append(entity_id))
	hud.toggle_target_picker()
	assert_true(hud.is_target_picker_visible())
	assert_eq(hud.primary_action_button.text, "Read")
	assert_eq(next_target_button.text, "Close")
	assert_eq(next_target_button.tooltip_text, "Close targets")
	assert_eq(hud.target_list.get_child_count(), 4)
	assert_true((hud.target_list.get_child(0) as Label).text.contains("3 targets"))
	assert_true((hud.target_list.get_child(0) as Label).text.contains("NPC 1"))
	var npc_target := _button_containing(hud.target_list, "Harrow Venn")
	assert_not_null(npc_target)
	assert_true(npc_target.text.contains("NPC"))
	assert_true(npc_target.text.contains("E 5.0t"))
	var selected_target := hud.target_list.get_child(1) as Button
	assert_true(selected_target.text.begins_with("> Readable  Road Notice"))
	assert_true(selected_target.text.contains("N 5.0t"))
	selected_target.pressed.emit()
	assert_eq(used_targets, ["object_road_notice"])
	assert_eq(selected_targets, [])
	npc_target.pressed.emit()
	assert_eq(used_targets, ["object_road_notice", "npc_harrow_venn_world"])
	assert_eq(selected_targets, [])
	hud.hide_target_picker()
	assert_false(hud.is_target_picker_visible())
	assert_eq(hud.primary_action_button.text, "Read")
	assert_eq(next_target_button.text, "Next")
	var combat_actions: Array[String] = []
	hud.combat_action_selected.connect(
		func(action_id: String) -> void: combat_actions.append(action_id)
	)
	hud._refresh_context_actions(
		{"combat_actions": [{"id": "attack", "text": "Attack"}, {"id": "guard", "text": "Guard"}]}
	)
	assert_true(hud.context_action_panel.visible)
	(hud.context_action_buttons.get_child(0) as Button).pressed.emit()
	(hud.context_action_buttons.get_child(1) as Button).pressed.emit()
	assert_eq(combat_actions, ["attack", "guard"])
	hud._refresh_context_actions({"combat_actions": []})
	assert_false(hud.context_action_panel.visible)

	assert_false(hud.is_systems_panel_visible())
	for child in hud.root.get_node("ActionButtons").get_children():
		if child is Button and child.text == "Menu":
			child.pressed.emit()
	assert_true(hud.is_systems_panel_visible())
	assert_eq(hud.primary_action_button.text, "Close")
	hud.hide_systems_panel()
	assert_false(hud.is_systems_panel_visible())
	assert_eq(hud.primary_action_button.text, "Read")
	hud.toggle_systems()
	assert_eq(hud.get_systems_tab(), "inventory")
	assert_eq(hud.primary_action_button.text, "Close")
	assert_null(_button_containing(hud.action_buttons, "Save"))
	assert_null(_button_containing(hud.action_buttons, "Load"))
	assert_null(_button_containing(hud.action_buttons, "HUD"))
	assert_true(hud.systems_body_label.text.contains("Old Toolbox x1"))
	assert_true(hud.systems_body_label.text.contains("Weapon: Road Hatchet"))
	assert_true(hud.systems_body_label.text.contains("Items:"))
	assert_true(hud.systems_body_label.text.contains("A heavy wooden toolbox"))
	assert_eq(hud.systems_scroll.get_child(0), hud.systems_body_label)
	var selected_items: Array[String] = []
	hud.inventory_item_selected.connect(
		func(item_id: String) -> void: selected_items.append(item_id)
	)
	assert_true(hud.systems_action_list.visible)
	assert_true(
		(hud.systems_action_list.get_child(0) as Button).text.contains("Use Roadside Draught")
	)
	(hud.systems_action_list.get_child(0) as Button).pressed.emit()
	assert_eq(selected_items, ["use:item_roadside_draught"])
	assert_eq(hud.systems_tabs.get_child_count(), 6)
	assert_true(hud.systems_tab_buttons["inventory"].button_pressed)

	hud.set_systems_tab("character")
	assert_true(hud.systems_tab_buttons["character"].button_pressed)
	assert_true(hud.systems_body_label.text.contains("Character"))
	assert_true(hud.systems_body_label.text.contains("Might 1"))
	assert_true(hud.systems_action_list.visible)
	var train_button := _button_containing(hud.systems_action_list, "Train Might")
	assert_not_null(train_button)
	train_button.pressed.emit()
	assert_eq(selected_items, ["use:item_roadside_draught", "train:might"])

	hud.set_systems_tab("trade")
	assert_true(hud.systems_tab_buttons["trade"].button_pressed)
	assert_true(hud.systems_body_label.text.contains("Crossroads Peddler"))
	assert_true(hud.systems_action_list.visible)
	var buy_button := _button_containing(hud.systems_action_list, "Buy Roadside Draught")
	assert_not_null(buy_button)
	buy_button.pressed.emit()
	assert_eq(
		selected_items, ["use:item_roadside_draught", "train:might", "buy:item_roadside_draught"]
	)

	hud.set_systems_tab("quests")
	assert_true(hud.systems_tab_buttons["quests"].button_pressed)
	assert_true(hud.systems_action_list.visible)
	var target_button := _button_containing(hud.systems_action_list, "Target Harrow Venn")
	assert_not_null(target_button)
	assert_false(target_button.disabled)
	assert_true(hud.systems_body_label.text.contains("Quests"))
	assert_true(hud.systems_body_label.text.contains("Active:"))
	assert_true(hud.systems_body_label.text.contains("Routes:"))
	assert_true(hud.systems_body_label.text.contains("E 5.0t Harrow Venn"))
	target_button.pressed.emit()

	hud.set_systems_tab("map")
	assert_true(hud.systems_tab_buttons["map"].button_pressed)
	assert_true(hud.systems_body_label.text.contains("Map"))
	assert_true(hud.systems_body_label.text.contains("Now: Day 1, 16:00"))
	assert_true(hud.systems_body_label.text.contains("Known places: Briarwatch Crossroads"))
	assert_true(hud.systems_body_label.text.contains("Place Notes:"))
	assert_true(hud.systems_body_label.text.contains("Briarwatch road meets the old trade track"))
	assert_true(hud.systems_body_label.text.contains("Quest Routes:"))
	assert_true(hud.systems_body_label.text.contains("SE 5.7t Old Toolbox"))
	assert_true(hud.systems_body_label.text.contains("Nearby:"))
	assert_true(hud.systems_action_list.visible)

	hud.set_systems_tab("journal")
	assert_true(hud.systems_tab_buttons["journal"].button_pressed)
	assert_true(hud.systems_body_label.text.contains("Journal"))
	assert_true(hud.systems_body_label.text.contains("Phase: Afternoon"))
	assert_true(hud.systems_body_label.text.contains("Reputation:"))
	assert_true(hud.systems_body_label.text.contains("Recent Events:"))
	assert_true(hud.systems_action_list.visible)
	var wait_button := _button_containing(hud.systems_action_list, "Wait 1h")
	assert_not_null(wait_button)
	wait_button.pressed.emit()
	var save_button := _button_containing(hud.systems_action_list, "Save Game")
	var load_button := _button_containing(hud.systems_action_list, "Load Game")
	assert_not_null(save_button)
	assert_not_null(load_button)
	save_button.pressed.emit()
	load_button.pressed.emit()
	assert_eq(
		selected_items,
		[
			"use:item_roadside_draught",
			"train:might",
			"buy:item_roadside_draught",
			"target:npc_harrow_venn_world",
			"wait:1",
			"save:game",
			"load:game"
		]
	)

	bus.post_message("Saved.")
	assert_true(hud.log_label.text.contains("Saved."))
	hud.set_systems_tab("log")
	assert_true(hud.systems_tab_buttons["journal"].button_pressed)
	assert_eq(hud.get_systems_tab(), "journal")
	assert_true(hud.systems_body_label.text.contains("Journal"))
	assert_true(hud.systems_body_label.text.contains("- Saved."))

	var selected_choices: Array[String] = []
	hud.content_choice_selected.connect(
		func(choice_id: String) -> void: selected_choices.append(choice_id)
	)
	hud.show_content_card(
		"Road Notice",
		"Boundary stones are not to be moved.",
		[{"id": "accept", "text": "Accept"}, {"id": "decline", "text": "Decline"}]
	)
	assert_false(hud.is_systems_panel_visible())
	assert_true(hud.is_content_card_visible())
	assert_eq(hud.primary_action_button.text, "Close")
	assert_eq(hud.content_kind_label.text, "Notice")
	assert_eq(hud.content_title_label.text, "Road Notice")
	assert_true(hud.content_body_label.text.contains("Boundary stones"))
	assert_eq(hud.content_scroll.get_child(0), hud.content_body_label)
	assert_true(hud.content_choice_list.visible)
	assert_eq(hud.content_choice_list.get_child_count(), 2)
	(hud.content_choice_list.get_child(0) as Button).pressed.emit()
	assert_eq(selected_choices, ["accept"])

	var close_events: Array[String] = []
	hud.content_card_closed.connect(func() -> void: close_events.append("closed"))
	hud.hide_content_card()
	assert_false(hud.is_content_card_visible())
	assert_eq(hud.primary_action_button.text, "Read")
	hud.hide_content_card()
	assert_eq(close_events, ["closed"])

	assert_false(hud.debug_panel.visible)
	hud.toggle_debug()
	assert_true(hud.debug_panel.visible)


func test_landscape_hud_layout_keeps_core_controls_separated() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := DebugHud.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_sample_state"))

	await wait_process_frames(2)

	var screen_rect: Rect2 = hud.root.get_global_rect()
	assert_gte(
		screen_rect.size.x, float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	)
	assert_gte(
		screen_rect.size.y,
		float(ProjectSettings.get_setting("display/window/size/viewport_height"))
	)
	var status_rect: Rect2 = hud.root.get_node("StatusPanel").get_global_rect()
	var prompt_rect: Rect2 = hud.root.get_node("PromptPanel").get_global_rect()
	var message_rect: Rect2 = hud.root.get_node("MessagePanel").get_global_rect()
	var move_rect: Rect2 = hud.root.get_node("MovePad").get_global_rect()
	var actions_rect: Rect2 = hud.root.get_node("ActionButtons").get_global_rect()

	assert_true(_rect_inside(status_rect, screen_rect), "Status panel should stay on screen.")
	assert_true(_rect_inside(prompt_rect, screen_rect), "Prompt panel should stay on screen.")
	assert_true(_rect_inside(message_rect, screen_rect), "Message strip should stay on screen.")
	assert_true(_rect_inside(move_rect, screen_rect), "Touch move pad should stay on screen.")
	assert_true(_rect_inside(actions_rect, screen_rect), "Action buttons should stay on screen.")
	assert_false(status_rect.intersects(prompt_rect), "Top panels should not overlap.")
	assert_false(message_rect.intersects(move_rect), "Message strip should not overlap move pad.")
	assert_false(message_rect.intersects(actions_rect), "Message strip should not overlap actions.")
	assert_false(move_rect.intersects(actions_rect), "Touch move pad should not overlap actions.")


func test_hud_layout_adapts_to_narrow_landscape_widths() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := DebugHud.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_sample_state"))

	hud._apply_layout_for_size(Vector2(960, 540))
	var message_width := hud.message_panel.offset_right - hud.message_panel.offset_left
	assert_true(hud.message_panel.visible)
	assert_gte(message_width, DebugHud.MESSAGE_MIN_WIDTH)
	assert_eq(hud.message_panel.offset_top, 12.0)
	assert_eq(hud.message_panel.offset_bottom, 64.0)
	assert_lte(hud.message_panel.offset_right, 948.0)
	assert_false(
		_rect_for_top_left_panel(hud.message_panel).intersects(
			_rect_for_top_left_panel(hud.status_panel)
		)
	)

	hud._apply_layout_for_size(Vector2(860, 484))
	assert_true(hud.message_panel.visible)
	assert_gte(
		hud.message_panel.offset_right - hud.message_panel.offset_left, DebugHud.MESSAGE_MIN_WIDTH
	)
	assert_eq(hud.message_panel.offset_top, 12.0)
	assert_eq(hud.message_panel.offset_bottom, 64.0)
	assert_lte(hud.message_panel.offset_right, 848.0)

	hud._apply_layout_for_size(Vector2(640, 360))
	var compact_status_rect := _rect_for_top_left_panel(hud.status_panel)
	var compact_interact := _button_with_text(hud.action_buttons, "Read\nRoad Notice")
	var compact_target := hud.root.get_node("ActionButtons/TargetButton") as Button
	assert_not_null(compact_interact)
	assert_eq(compact_target.text, "Next\nHarrow Venn")
	assert_eq(compact_interact.custom_minimum_size, Vector2(92, 52))
	assert_eq(hud.status_label.get_theme_font_size("font_size"), 12)
	assert_false(hud.health_label.visible)
	assert_lte(compact_status_rect.size.y, 100.0)
	assert_true(
		_rect_inside(compact_status_rect, Rect2(Vector2.ZERO, Vector2(640, 360))),
		"Active-quest status panel should stay on screen."
	)
	assert_true(hud.message_panel.visible)
	assert_gte(
		hud.message_panel.offset_right - hud.message_panel.offset_left,
		DebugHud.MESSAGE_MIN_WIDTH
	)
	assert_eq(hud.message_panel.offset_top, 12.0)
	assert_eq(hud.message_panel.offset_bottom, 64.0)
	assert_false(
		_rect_for_top_left_panel(hud.message_panel).intersects(compact_status_rect),
		"Compact message strip should use the top-right lane beside status."
	)
	assert_eq(hud.log_label.autowrap_mode, TextServer.AUTOWRAP_OFF)
	assert_gt(640.0 + hud.action_buttons.offset_left, hud.move_pad.offset_right)
	assert_eq(hud.action_buttons.offset_top, -68.0)
	var prompt_rect := _rect_for_right_anchored_panel(hud.prompt_panel, Vector2(640, 360))
	assert_false(hud.prompt_panel.visible)
	assert_lte(prompt_rect.size.x, 204.0)
	assert_lte(prompt_rect.size.y, 76.0)
	assert_eq(hud.prompt_label.get_theme_font_size("font_size"), 16)

	hud.toggle_target_picker()
	var target_rect := _rect_for_right_anchored_panel(hud.target_panel, Vector2(640, 360))
	assert_true(
		_rect_inside(target_rect, Rect2(Vector2.ZERO, Vector2(640, 360))),
		"Target picker should fit compact landscape when opened."
	)
	assert_false(
		target_rect.intersects(
			_rect_for_bottom_right_anchored_panel(hud.action_buttons, Vector2(640, 360))
		)
	)
	assert_lte(
		hud.target_list.get_combined_minimum_size().x,
		target_rect.size.x - 24.0,
		"Target rows should fit within compact panel margins."
	)
	hud.hide_target_picker()
	hud._refresh_context_actions(
		{"combat_actions": [{"id": "attack", "text": "Attack"}, {"id": "guard", "text": "Guard"}]}
	)
	var context_rect := _rect_for_right_anchored_panel(hud.context_action_panel, Vector2(640, 360))
	assert_true(
		_rect_inside(context_rect, Rect2(Vector2.ZERO, Vector2(640, 360))),
		"Context action panel should fit compact landscape."
	)
	hud._refresh_context_actions({"combat_actions": []})

	var context_actions: Array[String] = []
	hud.context_action_selected.connect(
		func(action_id: String) -> void: context_actions.append(action_id)
	)
	hud._refresh_context_actions(
		{
			"context_actions":
			[
				{"id": "dialogue:accept", "text": "I'll find it."},
				{"id": "trade:shop_crossroads_peddler", "text": "Trade"},
				{"id": "poi:sharpen", "text": "Sharpen Road Hatchet"}
			]
		}
	)
	var multi_context_rect := _rect_for_right_anchored_panel(
		hud.context_action_panel, Vector2(640, 360)
	)
	assert_true(
		_rect_inside(multi_context_rect, Rect2(Vector2.ZERO, Vector2(640, 360))),
		"Multi-action context panel should fit compact landscape."
	)
	assert_lte(
		hud.context_action_buttons.get_combined_minimum_size().x,
		multi_context_rect.size.x - 12.0,
		"Context action buttons should wrap within compact panel margins."
	)
	assert_eq(
		(hud.context_action_buttons.get_child(0) as Button).custom_minimum_size,
		DebugHud.CONTEXT_ACTION_BUTTON_SIZE
	)
	assert_gte(DebugHud.CONTEXT_ACTION_BUTTON_SIZE.y, 50.0)
	(hud.context_action_buttons.get_child(0) as Button).pressed.emit()
	assert_eq(context_actions, ["dialogue:accept"])
	hud._refresh_context_actions(
		{
			"context_actions":
			[
				{"id": "dialogue:accept", "text": "I'll find it."},
				{"id": "trade:shop_crossroads_peddler", "text": "Trade"},
				{"id": "poi:sharpen", "text": "Sharpen Road Hatchet"},
				{"id": "poi:job", "text": "Take Road Patrol Job"},
				{"id": "line:turn_in", "text": "Turn In"}
			]
		}
	)
	var wrapped_context_rect := _rect_for_right_anchored_panel(
		hud.context_action_panel, Vector2(640, 360)
	)
	assert_gte(
		wrapped_context_rect.size.y,
		154.0,
		"Five compact context actions should get enough height for three wrapped rows."
	)
	assert_true(
		_rect_inside(wrapped_context_rect, Rect2(Vector2.ZERO, Vector2(640, 360))),
		"Wrapped context action panel should stay on screen."
	)
	assert_false(
		wrapped_context_rect.intersects(
			_rect_for_bottom_right_anchored_panel(hud.action_buttons, Vector2(640, 360))
		),
		"Wrapped context actions should not overlap bottom controls."
	)
	var context_scroll := (
		hud.context_action_panel.find_child("ContextActionScroll", true, false) as ScrollContainer
	)
	assert_not_null(context_scroll)
	assert_eq(context_scroll.get_child(0), hud.context_action_buttons)
	hud._refresh_context_actions(
		{
			"context_actions":
			[
				{"id": "dialogue:accept", "text": "I'll find it."},
				{"id": "trade:shop_crossroads_peddler", "text": "Trade"},
				{"id": "poi:sharpen", "text": "Sharpen Road Hatchet"},
				{"id": "poi:job", "text": "Take Road Patrol Job"},
				{"id": "line:turn_in", "text": "Turn In"},
				{"id": "poi:repair", "text": "Repair Gear"},
				{"id": "poi:rumor", "text": "Ask Rumors"},
				{"id": "poi:blessing", "text": "Seek Blessing"}
			]
		}
	)
	var overflow_context_rect := _rect_for_right_anchored_panel(
		hud.context_action_panel, Vector2(640, 360)
	)
	assert_true(
		_rect_inside(overflow_context_rect, Rect2(Vector2.ZERO, Vector2(640, 360))),
		"Overflow context action panel should stay on screen."
	)
	assert_false(
		overflow_context_rect.intersects(
			_rect_for_bottom_right_anchored_panel(hud.action_buttons, Vector2(640, 360))
		),
		"Overflow context actions should stay above bottom controls."
	)
	assert_true((hud.context_action_buttons.get_child(7) as Button).visible)
	(hud.context_action_buttons.get_child(7) as Button).pressed.emit()
	assert_eq(context_actions, ["dialogue:accept", "poi:blessing"])
	hud._refresh_context_actions({"context_actions": []})

	hud.toggle_systems()
	var systems_rect := _rect_for_right_anchored_panel(hud.systems_panel, Vector2(640, 360))
	assert_true(
		_rect_inside(systems_rect, Rect2(Vector2.ZERO, Vector2(640, 360))),
		"Systems panel should fit compact landscape when opened."
	)
	assert_lte(
		hud.systems_tabs.get_combined_minimum_size().x,
		systems_rect.size.x - 24.0,
		"Systems tabs should fit within the compact panel margins."
	)

	hud.show_content_card("Road Notice", "Boundary stones are not to be moved.")
	var content_rect := _rect_for_right_anchored_panel(hud.content_panel, Vector2(640, 360))
	assert_true(
		_rect_inside(content_rect, Rect2(Vector2.ZERO, Vector2(640, 360))),
		"Content panel should fit compact landscape when opened."
	)
	assert_false(
		content_rect.intersects(_center_play_rect(Vector2(640, 360))),
		"Content panel should leave the centered play space visible."
	)
	hud._refresh_context_actions(
		{"combat_actions": [{"id": "attack", "text": "Attack"}, {"id": "guard", "text": "Guard"}]}
	)
	assert_false(hud.context_action_panel.visible)


func test_touch_pad_gui_input_emits_clamped_move_and_release() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := DebugHud.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_sample_state"))
	var move_vectors: Array[Vector2] = []
	hud.move_vector_changed.connect(
		func(direction: Vector2) -> void: move_vectors.append(direction)
	)

	var press := InputEventMouseButton.new()
	press.pressed = true
	press.position = Vector2(DebugHud.MOVE_PAD_SIZE.x, DebugHud.MOVE_PAD_SIZE.y * 0.5)
	hud._on_move_pad_gui_input(press)

	assert_eq(move_vectors.size(), 1)
	assert_eq(move_vectors[0], Vector2.RIGHT)
	assert_eq(hud.get_touch_move_vector(), Vector2.RIGHT)

	var release := InputEventMouseButton.new()
	release.pressed = false
	release.position = press.position
	hud._on_move_pad_gui_input(release)

	assert_eq(move_vectors.size(), 2)
	assert_eq(move_vectors[1], Vector2.ZERO)
	assert_eq(hud.get_touch_move_vector(), Vector2.ZERO)


func test_hud_message_log_is_bounded_to_latest_entries() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := DebugHud.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_sample_state"))

	for index in range(DebugHud.MAX_MESSAGE_LOG + 5):
		bus.post_message("Message %d" % index)

	assert_eq(hud.message_log.size(), DebugHud.MAX_MESSAGE_LOG)
	assert_eq(hud.message_log[0], "Message 5")
	assert_true(hud.log_label.text.contains("Message %d" % (DebugHud.MAX_MESSAGE_LOG + 4)))
	assert_false(hud.log_label.text.contains("Message 5"))

	hud.toggle_systems()
	hud.set_systems_tab("journal")

	assert_true(hud.systems_body_label.text.contains("Message 5"))
	assert_true(hud.systems_body_label.text.contains("Message %d" % (DebugHud.MAX_MESSAGE_LOG + 4)))
	assert_false(hud.systems_body_label.text.contains("Message 4"))


func test_hud_releases_held_move_actions_when_removed() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := DebugHud.new()
	add_child(hud)
	hud.setup(bus, Callable(self, "_sample_state"))
	var up_button := _button_with_text(hud.move_pad, "Up")
	assert_not_null(up_button)

	up_button.button_down.emit()
	assert_true(Input.is_action_pressed("move_up"))

	hud.queue_free()
	await wait_process_frames(1)

	assert_false(Input.is_action_pressed("move_up"))


func test_hud_refresh_tolerates_non_dictionary_state_provider() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := DebugHud.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_non_dictionary_state"))

	assert_eq(hud.health_label.text, "Health 1/1")
	assert_false(hud.status_label.text.contains("Quest: none"))
	assert_eq(hud.prompt_label.text, "Explore")
	hud._apply_layout_for_size(Vector2(640, 360))
	var compact_status_rect := _rect_for_top_left_panel(hud.status_panel)
	assert_lte(compact_status_rect.size.y, 70.0)
	assert_false(hud.health_label.visible)

	bus.post_message("Still responsive.")

	assert_true(hud.log_label.text.contains("Still responsive."))


func test_hud_refresh_sanitizes_malformed_state_fields() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var hud := DebugHud.new()
	add_child_autofree(hud)
	hud.setup(bus, Callable(self, "_malformed_state"))

	assert_eq(hud.health_label.text, "Health 1/1")
	assert_false(hud.status_label.text.contains("Quest: none"))
	assert_true(hud.debug_label.text.contains("Loaded chunks: 0"))
	hud.toggle_systems()
	hud.set_systems_tab("quests")

	assert_true(hud.systems_body_label.text.contains("No active quests."))
	hud.set_systems_tab("journal")
	assert_true(hud.systems_body_label.text.contains("Recent Events:"))
	assert_true(hud.systems_body_label.text.contains("none"))
	hud.toggle_target_picker()
	assert_true(hud.target_list.get_child(0) is Label)
	assert_true((hud.target_list.get_child(0) as Label).text.contains("No targets nearby."))


func _sample_state() -> Dictionary:
	return {
		"player_world": "(8.0, 8.0)",
		"player_tile": "(0, 0)",
		"player_chunk": "(0, 0)",
		"player_health": "76/100",
		"player_health_value": 76,
		"player_max_health": 100,
		"terrain": "road",
		"loaded_chunk_count": 25,
		"nearby": "Road Notice",
		"target_kind": "readable",
		"primary_action": "Read",
		"target_detail": "Readable: Briarwatch Road Notice",
		"nearby_all": "Road Notice, Harrow Venn, Old Toolbox",
		"navigation": "N 5.0t Road Notice\nE 5.0t Harrow Venn\nSE 5.7t Old Toolbox",
		"nearby_targets":
		[
			{
				"id": "object_road_notice",
				"kind": "readable",
				"name": "Road Notice",
				"detail": "Readable: Briarwatch Road Notice",
				"navigation": "N 5.0t",
				"selected": true
			},
			{
				"id": "npc_harrow_venn_world",
				"kind": "npc",
				"name": "Harrow Venn",
				"detail": "Frontier blacksmith, quest inactive",
				"navigation": "E 5.0t",
				"selected": false
			},
			{
				"id": "pickup_old_toolbox",
				"kind": "pickup",
				"name": "Old Toolbox",
				"detail": "Pickup: Old Toolbox x1",
				"navigation": "SE 5.7t",
				"selected": false
			}
		],
		"inventory": "Old Toolbox x1",
		"inventory_details":
		"Old Toolbox x1: A heavy wooden toolbox stamped with Harrow Venn's maker's mark.",
		"inventory_actions":
		[
			{"id": "use:item_roadside_draught", "text": "Use Roadside Draught"},
			{"id": "equip:item_road_hatchet", "text": "Equip Road Hatchet"}
		],
		"equipment": "Weapon: Road Hatchet\nOffhand: empty\nBody: empty",
		"factions": "Marches of Velcor +5",
		"progression": "Level 2  XP 10/40  Points 1",
		"progression_details":
		(
			"Level: 2\nXP: 10/40\nUnspent points: 1\n"
			+ "Might 1: +1 attack damage\nGrit 0: -5% guarded counter damage\n"
			+ "Damage bonus: +2\nGuard multiplier: 50%"
		),
		"progression_actions":
		[{"id": "train:might", "text": "Train Might"}, {"id": "train:grit", "text": "Train Grit"}],
		"time": "Day 1, 16:00 (Afternoon)",
		"time_actions": [{"id": "wait:1", "text": "Wait 1h"}, {"id": "wait:8", "text": "Wait 8h"}],
		"time_details": "Time: 16:00\nDay: 1\nPhase: Afternoon",
		"trade": "Crossroads Peddler\nGold: 25\n\nStock:\n- Roadside Draught: 8g\n\nSell: none",
		"trade_actions": [{"id": "buy:item_roadside_draught", "text": "Buy Roadside Draught (8g)"}],
		"flags": "flag_test",
		"locations": "Briarwatch Crossroads",
		"location_details":
		(
			"Briarwatch Crossroads - Marches of Velcor\n"
			+ "A worn crossroads where the Briarwatch road meets the old trade track."
		),
		"quest_directions": "The Missing Tools: E 5.0t Harrow Venn",
		"quest_target_actions":
		[{"id": "target:npc_harrow_venn_world", "text": "Target Harrow Venn"}],
		"quests": ["The Missing Tools: Return the toolbox to Harrow Venn."]
	}


func _non_dictionary_state():
	return "bad"


func _malformed_state() -> Dictionary:
	return {
		"player_health": "bad",
		"player_health_value": "seventy",
		"player_max_health": "one hundred",
		"loaded_chunk_count": "many",
		"nearby": "none",
		"quests": "bad"
	}


func _rect_inside(inner: Rect2, outer: Rect2) -> bool:
	return (
		inner.position.x >= outer.position.x
		and inner.position.y >= outer.position.y
		and inner.end.x <= outer.end.x
		and inner.end.y <= outer.end.y
	)


func _button_with_text(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text == text:
			return child
	return null


func _button_containing(parent: Node, text: String) -> Button:
	for child in parent.get_children():
		if child is Button and child.text.contains(text):
			return child
	return null


func _rect_for_right_anchored_panel(panel: Control, viewport_size: Vector2) -> Rect2:
	var left := viewport_size.x + panel.offset_left
	var right := viewport_size.x + panel.offset_right
	return Rect2(
		Vector2(left, panel.offset_top),
		Vector2(right - left, panel.offset_bottom - panel.offset_top)
	)


func _rect_for_bottom_right_anchored_panel(panel: Control, viewport_size: Vector2) -> Rect2:
	var left := viewport_size.x + panel.offset_left
	var top := viewport_size.y + panel.offset_top
	return Rect2(
		Vector2(left, top),
		Vector2(panel.offset_right - panel.offset_left, panel.offset_bottom - panel.offset_top)
	)


func _rect_for_top_left_panel(panel: Control) -> Rect2:
	return Rect2(
		Vector2(panel.offset_left, panel.offset_top),
		Vector2(panel.offset_right - panel.offset_left, panel.offset_bottom - panel.offset_top)
	)


func _center_play_rect(viewport_size: Vector2) -> Rect2:
	var size := Vector2(104.0, 104.0)
	return Rect2(viewport_size * 0.5 - size * 0.5, size)
