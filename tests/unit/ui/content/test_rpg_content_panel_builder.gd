extends GutTest


func test_build_creates_dialogue_panel_sections_and_close_button() -> void:
	var close_calls: Array[int] = [0]
	var nodes := _build_panel(func() -> void: close_calls[0] += 1)

	var panel := nodes["panel"] as PanelContainer
	var identity := nodes["identity_panel"] as PanelContainer
	var portrait := nodes["portrait_panel"] as Panel
	var title := nodes["title_label"] as Label
	var choices := nodes["choice_list"] as VBoxContainer
	var close := nodes["close_button"] as Button

	assert_eq(panel.name, "ContentPanel")
	assert_false(panel.visible)
	assert_eq(panel.z_index, 70)
	assert_eq(panel.offset_left, 18.0)
	assert_eq(panel.offset_right, -18.0)
	assert_not_null(identity)
	assert_true(bool(portrait.get_meta("portrait_styled")))
	assert_not_null(portrait.find_child("ContentPortraitSilhouette", true, false))
	assert_eq(title.name, "ContentTitle")
	assert_eq(choices.name, "ContentChoices")
	assert_eq(close.name, "ContentCloseButton")

	close.pressed.emit()

	assert_eq(close_calls[0], 1)


func test_apply_mode_uses_choice_panel_when_choices_exist() -> void:
	var nodes := _build_panel(func() -> void: pass)
	var request := RpgContentPanelBuilder.ApplyModeRequest.new()
	request.portrait_label = nodes["portrait_label"]
	request.choice_panel = nodes["choice_panel"]
	request.close_button = nodes["close_button"]
	request.kind = "dialogue"
	request.choices = [{"id": "ask", "text": "Ask about tools"}]

	RpgContentPanelBuilder.apply_mode(request)

	var portrait_label := nodes["portrait_label"] as Label
	var choice_panel := nodes["choice_panel"] as PanelContainer
	var close := nodes["close_button"] as Button
	var art := portrait_label.get_parent().find_child(
		"ContentPortraitSilhouette", true, false
	) as RpgPortraitSilhouette
	assert_false(portrait_label.visible)
	assert_eq(art.identity_kind, "person")
	assert_true(choice_panel.visible)
	assert_false(close.visible)
	assert_eq(close.text, "Leave")
	assert_eq(close.tooltip_text, "Leave conversation")
	assert_eq(close.get_parent(), choice_panel.get_parent())


func test_apply_mode_moves_close_button_to_identity_when_no_choices_exist() -> void:
	var nodes := _build_panel(func() -> void: pass)
	var request := RpgContentPanelBuilder.ApplyModeRequest.new()
	request.portrait_label = nodes["portrait_label"]
	request.choice_panel = nodes["choice_panel"]
	request.close_button = nodes["close_button"]
	request.kind = "readable"
	request.choices = []

	RpgContentPanelBuilder.apply_mode(request)

	var portrait_label := nodes["portrait_label"] as Label
	var choice_panel := nodes["choice_panel"] as PanelContainer
	var close := nodes["close_button"] as Button
	var art := portrait_label.get_parent().find_child(
		"ContentPortraitSilhouette", true, false
	) as RpgPortraitSilhouette
	assert_eq(art.identity_kind, "readable")
	assert_false(choice_panel.visible)
	assert_true(close.visible)
	assert_eq(close.text, "Close")
	assert_eq(close.tooltip_text, "Close panel")
	assert_eq(close.get_parent(), portrait_label.get_parent().get_parent())


func test_apply_layout_switches_between_desktop_and_compact_structure() -> void:
	var nodes := _build_panel(func() -> void: pass)
	var choice_panel := nodes["choice_panel"] as PanelContainer
	var choice_list := nodes["choice_list"] as VBoxContainer
	var preview_panel := nodes["preview_panel"] as PanelContainer
	choice_panel.visible = true
	choice_list.add_child(Button.new())
	var request := _layout_request(nodes, false, Vector2(1152, 648))

	RpgContentPanelBuilder.apply_layout(request)

	var content_panel := nodes["panel"] as PanelContainer
	var right_stack := nodes["right_stack"] as VBoxContainer
	var portrait_panel := nodes["portrait_panel"] as Panel
	var choice_scroll := choice_panel.find_child(
		"ContentChoiceScroll", true, false
	) as ScrollContainer
	var reward_label := nodes["preview_reward_label"] as Label
	assert_eq(content_panel.offset_top, -266.0)
	assert_eq(content_panel.offset_bottom, -12.0)
	assert_eq(preview_panel.get_parent().name, "ContentDialogueRow")
	assert_eq(right_stack.custom_minimum_size, Vector2(286, 0))
	assert_eq(portrait_panel.custom_minimum_size, Vector2(70, 70))
	assert_eq(choice_scroll.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_SHOW_NEVER)
	assert_eq((choice_list.get_child(0) as Button).custom_minimum_size, Vector2(0, 46))
	assert_true(reward_label.visible)

	request.compact = true
	request.viewport_size = Vector2(640, 360)
	RpgContentPanelBuilder.apply_layout(request)

	assert_eq(content_panel.offset_top, -328.0)
	assert_eq(content_panel.offset_bottom, -8.0)
	assert_eq(preview_panel.get_parent(), right_stack)
	assert_eq(right_stack.get_child(0), preview_panel)
	assert_eq(right_stack.custom_minimum_size, Vector2(190, 0))
	assert_eq(portrait_panel.custom_minimum_size, Vector2(34, 34))
	assert_eq(choice_scroll.vertical_scroll_mode, ScrollContainer.SCROLL_MODE_AUTO)
	assert_eq((choice_list.get_child(0) as Button).custom_minimum_size, Vector2(0, 48))
	assert_false(reward_label.visible)


func _build_panel(close_callback: Callable) -> Dictionary:
	var root := Control.new()
	add_child_autofree(root)
	var context := RpgContentPanelBuilder.BuildContext.new(
		{
			"root": root,
			"new_panel": Callable(self, "_new_panel"),
			"add_margin": Callable(self, "_add_margin"),
			"new_label": Callable(self, "_new_label"),
			"new_button": Callable(self, "_new_button"),
			"close_callback": close_callback,
			"portrait_style": Callable(self, "_style_portrait"),
			"hud_margin": 18.0
		}
	)
	return RpgContentPanelBuilder.build(context)


func _layout_request(
	nodes: Dictionary, compact: bool, viewport_size: Vector2
) -> RpgContentPanelBuilder.LayoutRequest:
	var request := RpgContentPanelBuilder.LayoutRequest.new()
	request.content_panel = nodes["panel"]
	request.identity_panel = nodes["identity_panel"]
	request.portrait_panel = nodes["portrait_panel"]
	request.right_stack = nodes["right_stack"]
	request.choice_panel = nodes["choice_panel"]
	request.preview_panel = nodes["preview_panel"]
	request.title_label = nodes["title_label"]
	request.kind_label = nodes["kind_label"]
	request.body_label = nodes["body_label"]
	request.preview_title_label = nodes["preview_title_label"]
	request.preview_reward_label = nodes["preview_reward_label"]
	request.choice_list = nodes["choice_list"]
	request.compact = compact
	request.viewport_size = viewport_size
	request.hud_margin = 18.0
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


func _new_button(button_text: String, size: Vector2) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = size
	return button


func _style_portrait(portrait: Panel) -> void:
	portrait.set_meta("portrait_styled", true)
