# Test-only legacy shell retained for old HUD layout/input coverage.
extends "res://scripts/ui/shell/hud_shell.gd"

const HoldActionButton = preload("res://scripts/ui/shell/hold_action_button.gd")
const SystemsActionBuilder = preload("res://scripts/ui/systems/systems_action_builder.gd")
const TargetUiTextBuilder = preload("res://scripts/ui/text/target_ui_text_builder.gd")
const TouchControlStyle = preload("res://scripts/ui/shell/touch_control_style.gd")


func _build_status_panel() -> void:
	status_panel = _new_panel("StatusPanel")
	status_panel.offset_left = 12
	status_panel.offset_top = 12
	status_panel.offset_right = 330
	status_panel.offset_bottom = 148
	root.add_child(status_panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 5)
	_add_margin(status_panel, stack, 10)

	status_label = _new_label(15)
	stack.add_child(status_label)

	health_label = _new_label(13)
	stack.add_child(health_label)

	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(0, 10)
	health_bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.02, 0.03, 0.025, 0.82)
	background.border_color = PANEL_BORDER
	background.set_border_width_all(1)
	background.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("background", background)
	stack.add_child(health_bar)


func _build_target_panel() -> void:
	target_panel = _new_panel("TargetPanel")
	target_panel.anchor_left = 1.0
	target_panel.anchor_right = 1.0
	target_panel.offset_left = -332
	target_panel.offset_top = 112
	target_panel.offset_right = -12
	target_panel.offset_bottom = 344
	target_panel.visible = false
	root.add_child(target_panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	_add_margin(target_panel, stack, 12)

	var title := _new_label(16)
	title.text = "Targets"
	stack.add_child(title)

	target_scroll = ScrollContainer.new()
	target_scroll.name = "TargetScroll"
	target_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(target_scroll)

	target_list = VBoxContainer.new()
	target_list.name = "TargetList"
	target_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_list.add_theme_constant_override("separation", 6)
	target_scroll.add_child(target_list)


func _build_context_action_panel() -> void:
	context_action_panel = _new_panel("ContextActionPanel")
	context_action_panel.anchor_left = 1.0
	context_action_panel.anchor_right = 1.0
	context_action_panel.offset_left = -252
	context_action_panel.offset_top = 112
	context_action_panel.offset_right = -12
	context_action_panel.offset_bottom = 168
	context_action_panel.visible = false
	root.add_child(context_action_panel)

	var scroll := ScrollContainer.new()
	scroll.name = "ContextActionScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_add_margin(context_action_panel, scroll, int(CONTEXT_ACTION_MARGIN))

	context_action_buttons = HFlowContainer.new()
	context_action_buttons.name = "ContextActionButtons"
	context_action_buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	context_action_buttons.add_theme_constant_override(
		"h_separation", int(CONTEXT_ACTION_H_SEPARATION)
	)
	context_action_buttons.add_theme_constant_override(
		"v_separation", int(CONTEXT_ACTION_V_SEPARATION)
	)
	scroll.add_child(context_action_buttons)


func _build_systems_panel() -> void:
	systems_panel = _new_panel("SystemsPanel")
	systems_panel.anchor_left = 1.0
	systems_panel.anchor_right = 1.0
	systems_panel.offset_left = -372
	systems_panel.offset_top = 114
	systems_panel.offset_right = -12
	systems_panel.offset_bottom = 406
	systems_panel.visible = false
	root.add_child(systems_panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	_add_margin(systems_panel, stack, 12)

	systems_tabs = HBoxContainer.new()
	systems_tabs.name = "SystemsTabs"
	systems_tabs.add_theme_constant_override("separation", 4)
	stack.add_child(systems_tabs)
	_add_systems_tab("inventory", "Items")
	_add_systems_tab("character", "Hero")
	_add_systems_tab("trade", "Trade")
	_add_systems_tab("quests", "Quest")
	_add_systems_tab("journal", "Log")

	var close := _new_button("X", Vector2(42, 40))
	close.name = "SystemsCloseButton"
	close.tooltip_text = "Close menu"
	close.pressed.connect(hide_systems_panel)
	systems_tabs.add_child(close)

	systems_scroll = ScrollContainer.new()
	systems_scroll.name = "SystemsScroll"
	systems_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	systems_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(systems_scroll)

	systems_body_label = _new_label(14)
	systems_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	systems_scroll.add_child(systems_body_label)

	systems_action_list = VBoxContainer.new()
	systems_action_list.name = "SystemsActions"
	systems_action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	systems_action_list.add_theme_constant_override("separation", 6)
	stack.add_child(systems_action_list)
	_refresh_systems_tabs()


func _add_systems_tab(tab_id: String, text: String) -> void:
	var button := _new_button(text, Vector2(44, 40))
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: set_systems_tab(tab_id))
	systems_tabs.add_child(button)
	systems_tab_buttons[tab_id] = button


func _refresh_systems_tabs() -> void:
	super._refresh_systems_tabs()
	for button in systems_tab_buttons.values():
		if button is Button:
			button.add_theme_font_size_override("font_size", 12)


func _build_touch_controls() -> void:
	move_pad = Panel.new()
	move_pad.name = "MovePad"
	_apply_panel_style(move_pad)
	move_pad.anchor_top = 1.0
	move_pad.anchor_bottom = 1.0
	move_pad.offset_left = 18
	move_pad.offset_top = -172
	move_pad.offset_right = 184
	move_pad.offset_bottom = -12
	move_pad.mouse_filter = Control.MOUSE_FILTER_STOP
	move_pad.gui_input.connect(_on_move_pad_gui_input)
	root.add_child(move_pad)

	move_knob = ColorRect.new()
	move_knob.name = "MoveKnob"
	move_knob.color = Color(0.86, 0.78, 0.58, 0.55)
	move_knob.custom_minimum_size = MOVE_KNOB_SIZE
	move_knob.size = MOVE_KNOB_SIZE
	move_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_pad.add_child(move_knob)

	_add_hold_button(move_pad, "move_up", Vector2(54, 6))
	_add_hold_button(move_pad, "move_left", Vector2(6, 54))
	_add_hold_button(move_pad, "move_right", Vector2(102, 54))
	_add_hold_button(move_pad, "move_down", Vector2(54, 102))
	_update_move_knob()

	action_buttons = HBoxContainer.new()
	action_buttons.name = "ActionButtons"
	action_buttons.anchor_left = 1.0
	action_buttons.anchor_right = 1.0
	action_buttons.anchor_top = 1.0
	action_buttons.anchor_bottom = 1.0
	action_buttons.offset_left = -544
	action_buttons.offset_top = -76
	action_buttons.offset_right = -12
	action_buttons.offset_bottom = -12
	action_buttons.add_theme_constant_override("separation", 8)
	root.add_child(action_buttons)

	primary_action_button = _new_button("Interact", Vector2(118, 58))
	primary_action_button.name = "InteractButton"
	primary_action_button.pressed.connect(func() -> void: interact_pressed.emit())
	action_buttons.add_child(primary_action_button)

	target_action_button = _new_button("Next", Vector2(82, 58))
	target_action_button.name = "TargetButton"
	HoldActionButton.bind(
		target_action_button,
		func() -> void: cycle_target_pressed.emit(),
		func() -> void:
			if not is_target_picker_visible():
				toggle_target_picker()
	)
	action_buttons.add_child(target_action_button)

	var systems := _new_button("Menu", Vector2(92, 58))
	systems.name = "SystemsButton"
	systems.pressed.connect(toggle_systems)
	action_buttons.add_child(systems)


func _add_hold_button(parent: Control, action: String, position: Vector2) -> void:
	var button := _new_button(TouchControlStyle.direction_label(action), BUTTON_SIZE)
	button.name = "%sButton" % action.to_pascal_case()
	button.position = position
	button.tooltip_text = TouchControlStyle.direction_tooltip(action)
	TouchControlStyle.apply_direction_button_style(button, PANEL_BORDER)
	button.button_down.connect(func() -> void: _press_hold_action(action))
	button.button_up.connect(func() -> void: _release_hold_action(action))
	parent.add_child(button)


func _build_content_panel() -> void:
	var nodes := ContentCardPresenter.build(
		ContentCardPresenter.BuildContext.new(
			root,
			Callable(self, "_new_panel"),
			Callable(self, "_add_margin"),
			Callable(self, "_new_label"),
			Callable(self, "_new_button"),
			Callable(self, "hide_content_card")
		)
	)
	content_panel = nodes["panel"]
	content_kind_label = nodes["kind_label"]
	content_title_label = nodes["title_label"]
	content_scroll = nodes["scroll"]
	content_body_label = nodes["body_label"]
	content_choice_list = nodes["choice_list"]


func _refresh_target_action_button(state: Dictionary) -> void:
	if not target_action_button:
		return
	var compact := applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0
	var targets := _array_field(state.get("nearby_targets", []))
	var picker_visible := target_panel and target_panel.visible
	target_action_button.text = TargetUiTextBuilder.action_button_text(
		targets, compact, picker_visible
	)
	target_action_button.tooltip_text = TargetUiTextBuilder.action_button_tooltip(
		targets, picker_visible
	)


func _refresh_target_picker(state: Dictionary) -> void:
	if not target_list or not target_panel.visible:
		return
	for child in target_list.get_children():
		target_list.remove_child(child)
		child.queue_free()
	var targets := _array_field(state.get("nearby_targets", []))
	if targets.is_empty():
		var empty := _new_label(14)
		empty.text = "No targets nearby."
		target_list.add_child(empty)
		return
	var summary := TargetUiTextBuilder.summary_label(targets)
	if not summary.is_empty():
		var summary_label := _new_label(13)
		summary_label.text = summary
		target_list.add_child(summary_label)
	for target_data in targets:
		if not target_data is Dictionary:
			continue
		var entity_id := String(target_data.get("id", ""))
		if entity_id.is_empty():
			continue
		target_list.add_child(_target_button(target_data, entity_id))


func _target_button(target_data: Dictionary, entity_id: String) -> Button:
	var name := String(target_data.get("name", entity_id))
	var kind_label := TargetUiTextBuilder.kind_label(String(target_data.get("kind", "object")))
	var detail := String(target_data.get("detail", ""))
	var navigation := String(target_data.get("navigation", ""))
	var title := "%s  %s" % [kind_label, name] if not kind_label.is_empty() else name
	var lines: Array[String] = [title]
	if not navigation.is_empty():
		lines.append(navigation)
	if not detail.is_empty():
		lines.append(detail)
	if bool(target_data.get("selected", false)):
		lines[0] = "> %s" % lines[0]
	var button := _new_button("\n".join(lines), Vector2(0, 72))
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(func() -> void: target_used.emit(entity_id))
	return button


func _refresh_content_choices(choices: Array) -> void:
	if not content_choice_list:
		return
	content_choice_list.visible = ContentCardPresenter.refresh_choices(
		content_choice_list, choices, self
	)


func _refresh_systems_actions(state: Dictionary) -> void:
	if not systems_action_list:
		return
	var actions := SystemsActionBuilder.actions_for_tab(state, systems_active_tab)
	systems_action_list.visible = UiActionButtons.refresh(
		UiActionButtons.RefreshRequest.new(
			systems_action_list,
			actions,
			self,
			"inventory_item_selected",
			"item_id",
			Vector2(0, 50),
			14
		)
	)


func _refresh_context_actions(state: Dictionary) -> void:
	if not context_action_buttons:
		return
	if _has_open_overlay_panel():
		visible_context_action_count = 0
		context_action_panel.visible = false
		return
	var signal_id := "combat_action_selected"
	var actions := _array_field(state.get("combat_actions", []))
	if state.has("context_actions"):
		actions = _array_field(state.get("context_actions", []))
		signal_id = "context_action_selected"
	visible_context_action_count = UiActionButtons.valid_action_count(actions)
	var layout_size := applied_layout_size if applied_layout_size != Vector2.ZERO else root.size
	_set_overlay_panel_layout(layout_size, layout_size.x < 980.0 or layout_size.y < 540.0)
	context_action_panel.visible = UiActionButtons.refresh(
		UiActionButtons.RefreshRequest.new(
			context_action_buttons,
			actions,
			self,
			signal_id,
			"action_id",
			CONTEXT_ACTION_BUTTON_SIZE,
			13
		)
	)
