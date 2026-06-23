class_name RpgContextActionPanelBuilder
extends RefCounted


static func build(
	root: Control,
	new_panel: Callable,
	add_margin: Callable,
	new_label: Callable
) -> Dictionary:
	var panel: PanelContainer = new_panel.call("ContextActionPanel")
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.visible = false
	panel.z_index = 55
	root.add_child(panel)

	var stack := VBoxContainer.new()
	stack.name = "QuickActionFrame"
	stack.add_theme_constant_override("separation", 7)
	add_margin.call(panel, stack, 9)

	var title := new_label.call(13) as Label
	title.name = "QuickActionTitle"
	title.text = "Quick Actions"
	title.add_theme_color_override("font_color", Color(0.86, 0.70, 0.42))
	stack.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.name = "ContextActionScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)

	var buttons := HFlowContainer.new()
	buttons.name = "ContextActionButtons"
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_theme_constant_override("h_separation", 7)
	buttons.add_theme_constant_override("v_separation", 7)
	scroll.add_child(buttons)

	return {"panel": panel, "buttons": buttons}


static func refresh(
	container: HFlowContainer,
	actions: Array,
	new_button: Callable,
	row_style: Callable,
	action_callback: Callable,
	context_mode: bool,
	compact: bool
) -> int:
	var button_index := 0
	for action in actions:
		if not action is Dictionary:
			continue
		var action_id := String(action.get("id", ""))
		var text := String(action.get("text", ""))
		if action_id.is_empty() or text.is_empty():
			continue
		var button := _button(container, button_index, new_button)
		button.text = text
		button.disabled = false
		button.visible = true
		button.custom_minimum_size = Vector2(142, 52) if compact else Vector2(150, 50)
		button.add_theme_font_size_override("font_size", 12 if compact else 13)
		row_style.call(button, _is_recommended(action_id, text))
		button.set_meta("action_id", action_id)
		button.set_meta("context_mode", context_mode)
		_bind_button(button, action_callback)
		button_index += 1
	for index in range(button_index, container.get_child_count()):
		container.get_child(index).visible = false
	return button_index


static func apply_layout(
	panel: PanelContainer,
	buttons: HFlowContainer,
	visible_count: int,
	viewport_size: Vector2,
	compact: bool,
	hud_margin: float
) -> void:
	if not panel:
		return
	var width := minf(520.0, viewport_size.x - hud_margin * 2.0)
	if compact:
		width = minf(480.0, viewport_size.x - 152.0)
	var bottom_gap := 210.0 if not compact else 164.0
	var row_count := ceili(float(maxi(1, visible_count)) / 3.0)
	var height := 44.0 + float(row_count) * (59.0 if compact else 57.0)
	height = clampf(height, 104.0 if compact else 104.0, 184.0 if compact else 172.0)
	panel.offset_left = -width - hud_margin
	panel.offset_right = -hud_margin
	panel.offset_bottom = -bottom_gap
	panel.offset_top = panel.offset_bottom - height
	if panel.offset_top < -viewport_size.y + hud_margin:
		panel.offset_top = -viewport_size.y + hud_margin
	if buttons:
		buttons.add_theme_constant_override("h_separation", 6 if compact else 7)
		buttons.add_theme_constant_override("v_separation", 6 if compact else 7)


static func _button(container: HFlowContainer, index: int, new_button: Callable) -> Button:
	if index < container.get_child_count():
		var existing := container.get_child(index)
		if existing is Button:
			return existing
	var button := new_button.call("", Vector2(150, 50)) as Button
	button.focus_mode = Control.FOCUS_NONE
	container.add_child(button)
	return button


static func _bind_button(button: Button, action_callback: Callable) -> void:
	if bool(button.get_meta("quick_action_bound", false)):
		return
	button.set_meta("quick_action_bound", true)
	button.pressed.connect(
		func() -> void:
			action_callback.call(
				String(button.get_meta("action_id", "")),
				bool(button.get_meta("context_mode", false))
			)
	)


static func _is_recommended(action_id: String, text: String) -> bool:
	return (
		action_id.begins_with("dialogue:")
		or action_id.begins_with("line:")
		or action_id.begins_with("poi:")
		or text == "Guard"
		or text.begins_with("Turn In")
	)
