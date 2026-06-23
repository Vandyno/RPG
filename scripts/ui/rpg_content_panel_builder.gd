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
	panel.offset_top = -246
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
	choice_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
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

	var preview_stack := VBoxContainer.new()
	preview_stack.name = "ContentPreviewStack"
	preview_stack.add_theme_constant_override("separation", 7)
	add_margin.call(preview_panel, preview_stack, 8)

	var preview_title_label: Label = new_label.call(15)
	preview_title_label.name = "ContentPreviewTitle"
	preview_title_label.add_theme_color_override("font_color", Color(0.78, 1.0, 0.56))
	preview_stack.add_child(preview_title_label)

	var preview_label: Label = new_label.call(13)
	preview_label.name = "ContentPreview"
	preview_label.text = "Choose a response or close."
	preview_label.add_theme_color_override("font_color", Color(0.82, 0.74, 0.60))
	preview_stack.add_child(preview_label)

	var preview_reward_label: Label = new_label.call(13)
	preview_reward_label.name = "ContentPreviewRewards"
	preview_reward_label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.54))
	preview_stack.add_child(preview_reward_label)

	return {
		"panel": panel,
		"identity_panel": identity_panel,
		"portrait_panel": portrait_panel,
		"text_panel": text_panel,
		"right_stack": right_stack,
		"choice_panel": choice_panel,
		"preview_panel": preview_panel,
		"preview_title_label": preview_title_label,
		"preview_label": preview_label,
		"preview_reward_label": preview_reward_label,
		"close_button": close,
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
	preview_title_label: Label,
	preview_reward_label: Label,
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
	content_panel.offset_top = -328 if compact else -246
	content_panel.custom_minimum_size = (
		Vector2(maxf(0.0, viewport_size.x - hud_margin * 2.0), 320)
		if compact
		else Vector2.ZERO
	)
	if content_panel.offset_top < -viewport_size.y + hud_margin:
		content_panel.offset_top = -viewport_size.y + hud_margin
	if identity_panel:
		identity_panel.visible = true
		identity_panel.custom_minimum_size = Vector2(74, 0) if compact else Vector2(188, 0)
	if portrait_panel:
		portrait_panel.visible = true
		portrait_panel.custom_minimum_size = Vector2(38, 38) if compact else Vector2(70, 70)
	if right_stack:
		right_stack.custom_minimum_size = Vector2(154, 0) if compact else Vector2(286, 0)
	if choice_panel:
		choice_panel.custom_minimum_size = Vector2(154, 0) if compact else Vector2(0, 0)
	if preview_panel:
		preview_panel.custom_minimum_size = Vector2(154, 0) if compact else Vector2(220, 0)
	if title_label:
		title_label.add_theme_font_size_override("font_size", 10 if compact else 22)
	if kind_label:
		kind_label.add_theme_font_size_override("font_size", 11 if compact else 14)
	if body_label:
		body_label.add_theme_font_size_override("font_size", 16 if compact else 17)
	if preview_title_label:
		preview_title_label.add_theme_font_size_override("font_size", 10 if compact else 15)
	var preview_label := preview_panel.find_child("ContentPreview", true, false) as Label
	if preview_label:
		preview_label.add_theme_font_size_override("font_size", 10 if compact else 13)
	if preview_reward_label:
		preview_reward_label.add_theme_font_size_override("font_size", 10 if compact else 13)
	if choice_list:
		choice_list.add_theme_constant_override("separation", 4 if compact else 6)
		for child in choice_list.get_children():
			if child is Button:
				child.custom_minimum_size = Vector2(0, 46) if compact else Vector2(0, 46)
				child.add_theme_font_size_override("font_size", 11 if compact else 14)


static func apply_mode(
	portrait_label: Label,
	choice_panel: PanelContainer,
	close_button: Button,
	title: String,
	choices: Array,
	kind: String
) -> void:
	var normalized := kind.to_lower()
	if portrait_label:
		portrait_label.text = _identity_text(title, normalized)
	if close_button:
		close_button.text = "Leave" if normalized == "dialogue" else "Close"
		close_button.tooltip_text = "Leave conversation" if normalized == "dialogue" else "Close panel"
		close_button.visible = not _has_valid_choices(choices)
	if choice_panel:
		choice_panel.visible = _has_valid_choices(choices)


static func _identity_text(title: String, kind: String) -> String:
	match kind:
		"dialogue":
			return _initials_for_title(title)
		"readable":
			return "R"
		"place":
			return "P"
		"response":
			return "OK"
	return _initials_for_title(title)


static func _initials_for_title(title: String) -> String:
	var parts := title.strip_edges().split(" ", false)
	var letters: Array[String] = []
	for part in parts:
		var clean := String(part).strip_edges()
		if clean.is_empty():
			continue
		letters.append(clean.substr(0, 1).to_upper())
		if letters.size() >= 2:
			break
	return "?" if letters.is_empty() else "".join(letters)


static func _has_valid_choices(choices: Array) -> bool:
	for choice in choices:
		if choice is Dictionary:
			var choice_id := String(choice.get("id", ""))
			var text := String(choice.get("text", ""))
			if not choice_id.is_empty() and not text.is_empty():
				return true
	return false
