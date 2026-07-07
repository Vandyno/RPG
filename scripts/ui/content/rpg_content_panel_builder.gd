class_name RpgContentPanelBuilder
extends RefCounted

const RpgPortraitSilhouette = preload(
	"res://scripts/ui/controls/display/rpg_portrait_silhouette.gd"
)


class BuildContext:
	var root: Control
	var new_panel: Callable
	var add_margin: Callable
	var new_label: Callable
	var new_button: Callable
	var close_callback: Callable
	var portrait_style: Callable
	var hud_margin: float

	func _init(
		p_root: Control,
		p_new_panel: Callable,
		p_add_margin: Callable,
		p_new_label: Callable,
		p_new_button: Callable,
		p_close_callback: Callable,
		p_portrait_style: Callable,
		p_hud_margin: float
	) -> void:
		root = p_root
		new_panel = p_new_panel
		add_margin = p_add_margin
		new_label = p_new_label
		new_button = p_new_button
		close_callback = p_close_callback
		portrait_style = p_portrait_style
		hud_margin = p_hud_margin


class LayoutRequest:
	var content_panel: PanelContainer
	var identity_panel: PanelContainer
	var portrait_panel: Panel
	var right_stack: VBoxContainer
	var choice_panel: PanelContainer
	var preview_panel: PanelContainer
	var title_label: Label
	var kind_label: Label
	var body_label: Label
	var preview_title_label: Label
	var preview_reward_label: Label
	var choice_list: VBoxContainer
	var viewport_size: Vector2
	var compact: bool
	var hud_margin: float


static func build(context: BuildContext) -> Dictionary:
	if not context or not context.root:
		return {}
	var panel := _build_panel_frame(context)
	var outer := _build_dialogue_row(panel, context.add_margin)
	var nodes := {"panel": panel}
	_merge_nodes(nodes, _build_identity_section(outer, context))
	_merge_nodes(nodes, _build_text_section(outer, context))
	_merge_nodes(nodes, _build_choice_section(outer, context))
	_merge_nodes(nodes, _build_preview_section(outer, context))
	return nodes


static func _merge_nodes(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		target[key] = source[key]


static func _build_panel_frame(context: BuildContext) -> PanelContainer:
	var panel: PanelContainer = context.new_panel.call("ContentPanel")
	panel.name = "ContentPanel"
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = context.hud_margin
	panel.offset_top = -266
	panel.offset_right = -context.hud_margin
	panel.offset_bottom = -12
	panel.visible = false
	panel.z_index = 70
	context.root.add_child(panel)
	return panel


static func _build_dialogue_row(panel: PanelContainer, add_margin: Callable) -> HBoxContainer:
	var outer := HBoxContainer.new()
	outer.name = "ContentDialogueRow"
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 8)
	add_margin.call(panel, outer, 10)
	return outer


static func _build_identity_section(outer: HBoxContainer, context: BuildContext) -> Dictionary:
	var identity_panel: PanelContainer = context.new_panel.call("ContentIdentityPanel")
	identity_panel.custom_minimum_size = Vector2(188, 0)
	identity_panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	outer.add_child(identity_panel)

	var identity_stack := VBoxContainer.new()
	identity_stack.add_theme_constant_override("separation", 6)
	context.add_margin.call(identity_panel, identity_stack, 10)

	var portrait_panel := Panel.new()
	portrait_panel.name = "ContentPortrait"
	portrait_panel.custom_minimum_size = Vector2(70, 70)
	portrait_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait_panel.visible = true
	context.portrait_style.call(portrait_panel)
	identity_stack.add_child(portrait_panel)

	var portrait_label: Label = context.new_label.call(20)
	portrait_label.name = "ContentPortraitInitials"
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait_label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.78))
	portrait_panel.add_child(portrait_label)
	_add_portrait_art(portrait_panel)

	var title_label: Label = context.new_label.call(22)
	title_label.name = "ContentTitle"
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	identity_stack.add_child(title_label)

	var kind_label: Label = context.new_label.call(14)
	kind_label.name = "ContentKind"
	kind_label.add_theme_color_override("font_color", Color(0.86, 0.70, 0.42))
	identity_stack.add_child(kind_label)
	return {
		"identity_panel": identity_panel,
		"portrait_panel": portrait_panel,
		"portrait_label": portrait_label,
		"title_label": title_label,
		"kind_label": kind_label
	}


static func _build_text_section(outer: HBoxContainer, context: BuildContext) -> Dictionary:
	var text_panel: PanelContainer = context.new_panel.call("ContentTextPanel")
	text_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(text_panel)

	var scroll := ScrollContainer.new()
	scroll.name = "ContentScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	context.add_margin.call(text_panel, scroll, 10)

	var body_label: Label = context.new_label.call(17)
	body_label.name = "ContentBody"
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.clip_text = true
	body_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(body_label)
	return {"text_panel": text_panel, "scroll": scroll, "body_label": body_label}


static func _build_choice_section(outer: HBoxContainer, context: BuildContext) -> Dictionary:
	var right_stack := VBoxContainer.new()
	right_stack.name = "ContentRightStack"
	right_stack.custom_minimum_size = Vector2(286, 0)
	right_stack.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_stack.add_theme_constant_override("separation", 8)
	outer.add_child(right_stack)

	var choice_panel: PanelContainer = context.new_panel.call("ContentChoicePanel")
	choice_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_stack.add_child(choice_panel)

	var choice_scroll := ScrollContainer.new()
	choice_scroll.name = "ContentChoiceScroll"
	choice_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choice_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	context.add_margin.call(choice_panel, choice_scroll, 8)

	var choice_list := VBoxContainer.new()
	choice_list.name = "ContentChoices"
	choice_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_list.add_theme_constant_override("separation", 6)
	choice_scroll.add_child(choice_list)

	var close: Button = context.new_button.call("Leave", Vector2(0, 46))
	close.name = "ContentCloseButton"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.pressed.connect(context.close_callback)
	right_stack.add_child(close)
	return {
		"right_stack": right_stack,
		"choice_panel": choice_panel,
		"choice_list": choice_list,
		"close_button": close
	}


static func _build_preview_section(outer: HBoxContainer, context: BuildContext) -> Dictionary:
	var preview_panel: PanelContainer = context.new_panel.call("ContentPreviewPanel")
	preview_panel.custom_minimum_size = Vector2(220, 0)
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_panel.visible = false
	outer.add_child(preview_panel)

	var preview_stack := VBoxContainer.new()
	preview_stack.name = "ContentPreviewStack"
	preview_stack.add_theme_constant_override("separation", 7)
	context.add_margin.call(preview_panel, preview_stack, 8)

	var preview_title_label: Label = context.new_label.call(15)
	preview_title_label.name = "ContentPreviewTitle"
	preview_title_label.add_theme_color_override("font_color", Color(0.78, 1.0, 0.56))
	preview_stack.add_child(preview_title_label)

	var preview_label: Label = context.new_label.call(13)
	preview_label.name = "ContentPreview"
	preview_label.text = "Choose a response or close."
	preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_label.add_theme_color_override("font_color", Color(0.82, 0.74, 0.60))
	preview_stack.add_child(preview_label)

	var preview_reward_label: Label = context.new_label.call(13)
	preview_reward_label.name = "ContentPreviewRewards"
	preview_reward_label.add_theme_color_override("font_color", Color(0.96, 0.84, 0.54))
	preview_stack.add_child(preview_reward_label)
	return {
		"preview_panel": preview_panel,
		"preview_title_label": preview_title_label,
		"preview_label": preview_label,
		"preview_reward_label": preview_reward_label
	}


static func apply_layout(request: LayoutRequest) -> void:
	if not request or not request.content_panel:
		return
	_apply_panel_frame_layout(request)
	_place_preview_panel(
		request.content_panel, request.right_stack, request.preview_panel, request.compact
	)
	_apply_text_panel_layout(request)
	_apply_identity_layout(request)
	_apply_choice_column_layout(request)
	_apply_preview_layout(request)
	_apply_text_sizing(request)
	_apply_choice_button_sizing(request)


static func _apply_panel_frame_layout(request: LayoutRequest) -> void:
	var content_panel := request.content_panel
	var viewport_size := request.viewport_size
	var compact := request.compact
	var hud_margin := request.hud_margin
	content_panel.anchor_left = 0.0
	content_panel.anchor_right = 1.0
	content_panel.anchor_top = 1.0
	content_panel.anchor_bottom = 1.0
	content_panel.offset_left = hud_margin
	content_panel.offset_right = -hud_margin
	content_panel.offset_bottom = -8 if compact else -12
	content_panel.offset_top = -328 if compact else -266
	content_panel.custom_minimum_size = (
		Vector2(maxf(0.0, viewport_size.x - hud_margin * 2.0), 320) if compact else Vector2.ZERO
	)
	if content_panel.offset_top < -viewport_size.y + hud_margin:
		content_panel.offset_top = -viewport_size.y + hud_margin


static func _apply_text_panel_layout(request: LayoutRequest) -> void:
	var text_panel := (
		request.content_panel.find_child("ContentTextPanel", true, false) as PanelContainer
	)
	if not text_panel:
		return
	text_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_panel.size_flags_stretch_ratio = 1.0


static func _apply_identity_layout(request: LayoutRequest) -> void:
	if request.identity_panel:
		request.identity_panel.visible = true
		request.identity_panel.custom_minimum_size = (
			Vector2(108, 0) if request.compact else Vector2(188, 0)
		)
	if request.portrait_panel:
		request.portrait_panel.visible = true
		request.portrait_panel.custom_minimum_size = (
			Vector2(34, 34) if request.compact else Vector2(70, 70)
		)


static func _apply_choice_column_layout(request: LayoutRequest) -> void:
	var choice_panel := request.choice_panel
	var right_stack := request.right_stack
	var has_choices := choice_panel and choice_panel.visible
	if right_stack:
		right_stack.visible = has_choices
		right_stack.custom_minimum_size = (
			(Vector2(190, 0) if request.compact else Vector2(286, 0))
			if has_choices
			else Vector2.ZERO
		)
		right_stack.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL if request.compact and has_choices else Control.SIZE_SHRINK_END
		)
		right_stack.size_flags_stretch_ratio = (
			(0.72 if request.compact else 1.0) if has_choices else 0.0
		)
	if choice_panel:
		choice_panel.custom_minimum_size = Vector2(190, 0) if request.compact else Vector2(0, 0)
	var choice_scroll := (
		choice_panel.find_child("ContentChoiceScroll", true, false) as ScrollContainer
		if choice_panel else null
	)
	if choice_scroll:
		choice_scroll.vertical_scroll_mode = (
			ScrollContainer.SCROLL_MODE_AUTO
			if request.compact
			else ScrollContainer.SCROLL_MODE_SHOW_NEVER
		)


static func _apply_preview_layout(request: LayoutRequest) -> void:
	var preview_panel := request.preview_panel
	if not preview_panel:
		return
	if request.choice_panel and not request.choice_panel.visible:
		preview_panel.visible = false
	preview_panel.custom_minimum_size = Vector2(190, 30) if request.compact else Vector2(220, 0)
	preview_panel.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN if request.compact else Control.SIZE_EXPAND_FILL
	)


static func _apply_text_sizing(request: LayoutRequest) -> void:
	if request.title_label:
		request.title_label.add_theme_font_size_override("font_size", 12 if request.compact else 22)
	if request.kind_label:
		request.kind_label.add_theme_font_size_override("font_size", 10 if request.compact else 14)
	if request.body_label:
		request.body_label.custom_minimum_size = Vector2.ZERO
		request.body_label.add_theme_font_size_override("font_size", 16 if request.compact else 17)
	if request.preview_title_label:
		request.preview_title_label.add_theme_font_size_override(
			"font_size", 10 if request.compact else 15
		)
	var preview_label := (
		request.preview_panel.find_child("ContentPreview", true, false) as Label
		if request.preview_panel else null
	)
	if preview_label:
		preview_label.visible = true
		preview_label.add_theme_font_size_override("font_size", 10 if request.compact else 13)
		if request.compact:
			preview_label.custom_minimum_size = Vector2(0, 18)
	if request.preview_reward_label:
		request.preview_reward_label.visible = not request.compact
		request.preview_reward_label.add_theme_font_size_override(
			"font_size", 10 if request.compact else 13
		)
		if request.compact:
			request.preview_reward_label.custom_minimum_size = Vector2.ZERO


static func _apply_choice_button_sizing(request: LayoutRequest) -> void:
	if not request.choice_list:
		return
	request.choice_list.add_theme_constant_override("separation", 4 if request.compact else 6)
	for child in request.choice_list.get_children():
		if child is Button:
			child.custom_minimum_size = Vector2(0, 48) if request.compact else Vector2(0, 46)
			child.add_theme_font_size_override("font_size", 12 if request.compact else 14)


static func _place_preview_panel(
	content_panel: PanelContainer,
	right_stack: VBoxContainer,
	preview_panel: PanelContainer,
	compact: bool
) -> void:
	if not content_panel or not right_stack or not preview_panel:
		return
	var dialogue_row := content_panel.find_child("ContentDialogueRow", true, false) as HBoxContainer
	if not dialogue_row:
		return
	var target_parent: Node = right_stack if compact else dialogue_row
	if preview_panel.get_parent() != target_parent:
		preview_panel.get_parent().remove_child(preview_panel)
		target_parent.add_child(preview_panel)
	if compact:
		right_stack.move_child(preview_panel, 0)
	else:
		dialogue_row.move_child(preview_panel, dialogue_row.get_child_count() - 1)


static func apply_mode(
	portrait_label: Label,
	choice_panel: PanelContainer,
	close_button: Button,
	_title: String,
	choices: Array,
	kind: String
) -> void:
	var normalized := kind.to_lower()
	if portrait_label:
		portrait_label.text = ""
		portrait_label.visible = false
		_set_identity_art_kind(portrait_label, normalized)
	if close_button:
		var has_choices := _has_valid_choices(choices)
		close_button.text = "Leave" if normalized == "dialogue" else "Close"
		close_button.tooltip_text = (
			"Leave conversation" if normalized == "dialogue" else "Close panel"
		)
		_place_close_button(portrait_label, choice_panel, close_button, has_choices)
		close_button.visible = not has_choices
	if choice_panel:
		choice_panel.visible = _has_valid_choices(choices)


static func _place_close_button(
	portrait_label: Label, choice_panel: PanelContainer, close_button: Button, has_choices: bool
) -> void:
	var target_parent: Node = choice_panel.get_parent() if has_choices and choice_panel else null
	if not has_choices and portrait_label and portrait_label.get_parent():
		target_parent = portrait_label.get_parent().get_parent()
	if not target_parent or close_button.get_parent() == target_parent:
		return
	close_button.get_parent().remove_child(close_button)
	target_parent.add_child(close_button)


static func _add_portrait_art(parent: Control) -> void:
	var art := RpgPortraitSilhouette.new()
	art.name = "ContentPortraitSilhouette"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(art)


static func _set_identity_art_kind(portrait_label: Label, kind: String) -> void:
	if not portrait_label or not portrait_label.get_parent():
		return
	var art := portrait_label.get_parent().find_child(
		"ContentPortraitSilhouette", true, false
	) as RpgPortraitSilhouette
	if not art:
		return
	art.set_identity_kind("person" if kind == "dialogue" else kind)


static func _has_valid_choices(choices: Array) -> bool:
	for choice in choices:
		if choice is Dictionary:
			var choice_id := String(choice.get("id", ""))
			var text := String(choice.get("text", ""))
			if not choice_id.is_empty() and not text.is_empty():
				return true
	return false
