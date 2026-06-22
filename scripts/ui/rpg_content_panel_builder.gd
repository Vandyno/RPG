class_name RpgContentPanelBuilder
extends RefCounted


static func build(
	root: Control,
	new_panel: Callable,
	add_margin: Callable,
	new_label: Callable,
	new_button: Callable,
	close_callback: Callable,
	portrait_style: Callable,
	hud_margin: float
) -> Dictionary:
	var panel: PanelContainer = new_panel.call("ContentPanel")
	panel.name = "ContentPanel"
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = hud_margin
	panel.offset_top = -214
	panel.offset_right = -hud_margin
	panel.offset_bottom = -12
	panel.visible = false
	panel.z_index = 70
	root.add_child(panel)

	var outer := HBoxContainer.new()
	outer.name = "ContentDialogueRow"
	outer.add_theme_constant_override("separation", 8)
	add_margin.call(panel, outer, 10)

	var identity_panel: PanelContainer = new_panel.call("ContentIdentityPanel")
	identity_panel.custom_minimum_size = Vector2(188, 0)
	outer.add_child(identity_panel)

	var identity_stack := VBoxContainer.new()
	identity_stack.add_theme_constant_override("separation", 6)
	add_margin.call(identity_panel, identity_stack, 10)

	var portrait_panel := Panel.new()
	portrait_panel.name = "ContentPortrait"
	portrait_panel.custom_minimum_size = Vector2(70, 70)
	portrait_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_panel.visible = true
	portrait_style.call(portrait_panel)
	identity_stack.add_child(portrait_panel)

	var portrait_label: Label = new_label.call(20)
	portrait_label.name = "ContentPortraitInitials"
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.78))
	portrait_panel.add_child(portrait_label)

	var title_label: Label = new_label.call(22)
	title_label.name = "ContentTitle"
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity_stack.add_child(title_label)

	var kind_label: Label = new_label.call(14)
	kind_label.name = "ContentKind"
	kind_label.add_theme_color_override("font_color", Color(0.86, 0.70, 0.42))
	identity_stack.add_child(kind_label)

	var text_panel: PanelContainer = new_panel.call("ContentTextPanel")
	text_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(text_panel)

	var scroll := ScrollContainer.new()
	scroll.name = "ContentScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_margin.call(text_panel, scroll, 10)

	var body_label: Label = new_label.call(17)
	body_label.name = "ContentBody"
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(body_label)

	var right_stack := VBoxContainer.new()
	right_stack.name = "ContentRightStack"
	right_stack.custom_minimum_size = Vector2(286, 0)
	right_stack.add_theme_constant_override("separation", 8)
	outer.add_child(right_stack)

	var choice_panel: PanelContainer = new_panel.call("ContentChoicePanel")
	choice_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_stack.add_child(choice_panel)

	var choice_scroll := ScrollContainer.new()
	choice_scroll.name = "ContentChoiceScroll"
	choice_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_margin.call(choice_panel, choice_scroll, 8)

	var choice_list := VBoxContainer.new()
	choice_list.name = "ContentChoices"
	choice_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_list.add_theme_constant_override("separation", 6)
	choice_scroll.add_child(choice_list)

	var close: Button = new_button.call("Leave", Vector2(0, 46))
	close.name = "ContentCloseButton"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.pressed.connect(close_callback)
	right_stack.add_child(close)

	var preview_panel: PanelContainer = new_panel.call("ContentPreviewPanel")
	preview_panel.custom_minimum_size = Vector2(220, 0)
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_panel.visible = false
	outer.add_child(preview_panel)

	var preview_label: Label = new_label.call(13)
	preview_label.name = "ContentPreview"
	preview_label.text = "Choose a response or close."
	preview_label.add_theme_color_override("font_color", Color(0.82, 0.74, 0.60))
	add_margin.call(preview_panel, preview_label, 8)

	return {
		"panel": panel,
		"identity_panel": identity_panel,
		"portrait_panel": portrait_panel,
		"text_panel": text_panel,
		"right_stack": right_stack,
		"choice_panel": choice_panel,
		"preview_panel": preview_panel,
		"preview_label": preview_label,
		"portrait_label": portrait_label,
		"kind_label": kind_label,
		"title_label": title_label,
		"scroll": scroll,
		"body_label": body_label,
		"choice_list": choice_list
	}


static func apply_layout(
	content_panel: PanelContainer,
	identity_panel: PanelContainer,
	portrait_panel: Panel,
	right_stack: VBoxContainer,
	choice_panel: PanelContainer,
	preview_panel: PanelContainer,
	title_label: Label,
	kind_label: Label,
	body_label: Label,
	choice_list: VBoxContainer,
	viewport_size: Vector2,
	compact: bool,
	hud_margin: float
) -> void:
	if not content_panel:
		return
	content_panel.anchor_left = 0.0
	content_panel.anchor_right = 1.0
	content_panel.anchor_top = 1.0
	content_panel.anchor_bottom = 1.0
	content_panel.offset_left = hud_margin
	content_panel.offset_right = -hud_margin
	content_panel.offset_bottom = -8 if compact else -12
	content_panel.offset_top = -276 if compact else -214
	content_panel.custom_minimum_size = (
		Vector2(maxf(0.0, viewport_size.x - hud_margin * 2.0), 268)
		if compact
		else Vector2.ZERO
	)
	if content_panel.offset_top < -viewport_size.y + hud_margin:
		content_panel.offset_top = -viewport_size.y + hud_margin
	if identity_panel:
		identity_panel.visible = true
		identity_panel.custom_minimum_size = Vector2(92, 0) if compact else Vector2(188, 0)
	if portrait_panel:
		portrait_panel.visible = true
		portrait_panel.custom_minimum_size = Vector2(46, 46) if compact else Vector2(70, 70)
	if right_stack:
		right_stack.custom_minimum_size = Vector2(232, 0) if compact else Vector2(286, 0)
	if choice_panel:
		choice_panel.custom_minimum_size = Vector2(232, 0) if compact else Vector2(0, 0)
	if preview_panel and compact:
		preview_panel.visible = false
	elif preview_panel:
		preview_panel.custom_minimum_size = Vector2(220, 0)
	if title_label:
		title_label.add_theme_font_size_override("font_size", 18 if compact else 22)
	if kind_label:
		kind_label.add_theme_font_size_override("font_size", 14 if compact else 14)
	if body_label:
		body_label.add_theme_font_size_override("font_size", 22 if compact else 17)
	if choice_list:
		choice_list.add_theme_constant_override("separation", 4 if compact else 6)
		for child in choice_list.get_children():
			if child is Button:
				child.custom_minimum_size = Vector2(0, 46) if compact else Vector2(0, 46)
				child.add_theme_font_size_override("font_size", 14 if compact else 14)
