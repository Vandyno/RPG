extends GutTest


func test_build_creates_hidden_quick_action_panel() -> void:
	var root := Control.new()
	add_child_autofree(root)
	var context := RpgContextActionPanelBuilder.BuildContext.new(
		root,
		Callable(self, "_new_panel"),
		Callable(self, "_add_margin"),
		Callable(self, "_new_label")
	)

	var nodes := RpgContextActionPanelBuilder.build(context)

	var panel := nodes["panel"] as PanelContainer
	var buttons := nodes["buttons"] as HFlowContainer
	assert_not_null(panel)
	assert_not_null(buttons)
	assert_eq(panel.name, "ContextActionPanel")
	assert_false(panel.visible)
	assert_eq(panel.z_index, 55)
	assert_eq(panel.anchor_left, 1.0)
	assert_eq(buttons.name, "ContextActionButtons")
	assert_not_null(panel.find_child("QuickActionTitle", true, false))


func test_refresh_builds_action_cards_and_emits_callback() -> void:
	var buttons := _quick_action_container()
	var selected: Array[Dictionary] = []
	var request := _refresh_request(
		buttons,
		func(action_id: String, context_mode: bool) -> void:
			selected.append({"action_id": action_id, "context_mode": context_mode})
	)
	request.actions = [
		"invalid",
		{},
		{"id": "dialogue:harrow", "text": "Talk"},
		{"id": "trade:shop_crossroads_peddler", "text": "Trade"},
	]
	request.title_text = "Harrow Venn"
	request.context_mode = true

	assert_eq(RpgContextActionPanelBuilder.refresh(request), 2)

	var frame := buttons.get_parent().get_parent()
	var title := frame.find_child("QuickActionTitle", false, false) as Label
	var talk := buttons.get_child(0) as RpgContentChoiceButton
	var trade := buttons.get_child(1) as RpgContentChoiceButton
	assert_eq(title.text, "Harrow Venn")
	assert_eq(talk.text, "Talk\nDialogue")
	assert_eq(talk.choice_icon, "dialogue")
	assert_eq(talk.choice_subtitle, "Dialogue")
	assert_eq(talk.get_meta("action_id"), "dialogue:harrow")
	assert_true(bool(talk.get_meta("context_mode")))
	assert_true(bool(talk.get_meta("styled_recommended")))
	assert_eq(trade.choice_icon, "trade")
	assert_false(bool(trade.get_meta("styled_recommended")))

	talk.pressed.emit()

	assert_eq(selected, [{"action_id": "dialogue:harrow", "context_mode": true}])


func test_refresh_reuses_bound_buttons_and_hides_stale_actions() -> void:
	var buttons := _quick_action_container()
	var selected: Array[Dictionary] = []
	var request := _refresh_request(
		buttons,
		func(action_id: String, context_mode: bool) -> void:
			selected.append({"action_id": action_id, "context_mode": context_mode})
	)
	request.actions = [
		{"id": "poi:sharpen", "text": "Sharpen Road Hatchet"},
		{"id": "guard", "text": "Guard"},
	]
	request.context_mode = false
	request.compact = true

	assert_eq(RpgContextActionPanelBuilder.refresh(request), 2)
	request.actions = [{"id": "poi:sharpen", "text": "Sharpen Road Hatchet"}]
	assert_eq(RpgContextActionPanelBuilder.refresh(request), 1)

	var sharpen := buttons.get_child(0) as RpgContentChoiceButton
	var stale := buttons.get_child(1) as RpgContentChoiceButton
	assert_true(sharpen.visible)
	assert_false(stale.visible)
	assert_eq(sharpen.custom_minimum_size, Vector2(104, 50))
	assert_eq(sharpen.choice_icon, "service")

	sharpen.pressed.emit()

	assert_eq(selected, [{"action_id": "poi:sharpen", "context_mode": false}])


func test_title_text_prefers_useful_context_names() -> void:
	assert_eq(
		RpgContextActionPanelBuilder.title_text({"nearby": "Rest Bridge Campfire"}, true),
		"Rest Bridge Campfire"
	)
	assert_eq(
		RpgContextActionPanelBuilder.title_text(
			{
				"nearby": "Nothing nearby",
				"nearby_targets": [{"name": "Road Notice", "selected": true}]
			},
			true
		),
		"Road Notice"
	)
	assert_eq(RpgContextActionPanelBuilder.title_text({"nearby": "none"}, true), "Nearby Actions")
	assert_eq(RpgContextActionPanelBuilder.title_text({}, false), "Combat Actions")


func test_apply_layout_sets_desktop_and_compact_bounds() -> void:
	var panel := PanelContainer.new()
	add_child_autofree(panel)
	var buttons := HFlowContainer.new()
	panel.add_child(buttons)
	var request := RpgContextActionPanelBuilder.LayoutRequest.new()
	request.panel = panel
	request.buttons = buttons
	request.visible_count = 4
	request.viewport_size = Vector2(1152, 648)
	request.compact = false
	request.hud_margin = 18.0

	RpgContextActionPanelBuilder.apply_layout(request)

	assert_eq(panel.offset_right, -18.0)
	assert_eq(panel.offset_left, -538.0)
	assert_eq(panel.offset_bottom, -270.0)

	request.viewport_size = Vector2(640, 360)
	request.compact = true
	RpgContextActionPanelBuilder.apply_layout(request)

	assert_gte(panel.offset_left, -640.0 + 18.0)
	assert_lte(panel.offset_right, -18.0)
	assert_eq(panel.offset_bottom, -74.0)
	assert_eq(buttons.get_theme_constant("h_separation"), 5)


func _quick_action_container() -> HFlowContainer:
	var frame := VBoxContainer.new()
	add_child_autofree(frame)
	var title := Label.new()
	title.name = "QuickActionTitle"
	frame.add_child(title)
	var scroll := ScrollContainer.new()
	frame.add_child(scroll)
	var buttons := HFlowContainer.new()
	scroll.add_child(buttons)
	return buttons


func _refresh_request(
	buttons: HFlowContainer, action_callback: Callable
) -> RpgContextActionPanelBuilder.RefreshRequest:
	var request := RpgContextActionPanelBuilder.RefreshRequest.new()
	request.container = buttons
	request.new_button = Callable(self, "_new_button")
	request.row_style = Callable(self, "_style_button")
	request.action_callback = action_callback
	return request


func _new_panel(panel_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	return panel


func _add_margin(panel: PanelContainer, child: Control, margin_size: int) -> void:
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_%s" % side, margin_size)
	panel.add_child(margin)
	margin.add_child(child)


func _new_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _new_button(_text: String, _size: Vector2) -> Button:
	return Button.new()


func _style_button(button: Button, recommended: bool) -> void:
	button.set_meta("styled_recommended", recommended)
