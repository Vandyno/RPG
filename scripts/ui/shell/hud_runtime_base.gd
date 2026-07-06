class_name HudRuntimeBase
extends CanvasLayer

signal interact_pressed
signal cycle_target_pressed
signal target_selected(entity_id: String)
signal target_used(entity_id: String)
signal content_choice_selected(choice_id: String)
signal content_card_closed
signal inventory_item_selected(item_id: String)
signal combat_action_selected(action_id: String)
signal context_action_selected(action_id: String)
signal save_pressed
signal load_pressed
signal move_vector_changed(direction: Vector2)
signal systems_panel_closed
signal systems_tab_changed(tab_id: String)

const BUTTON_SIZE := Vector2(58, 58)
const UiActionButtons = preload("res://scripts/ui/shell/ui_action_buttons.gd")
const ButtonTextFormatter = preload("res://scripts/ui/text/button_text_formatter.gd")
const ContentCardPresenter = preload("res://scripts/ui/shell/content_card_presenter.gd")
const HudLayoutMetrics = preload("res://scripts/ui/shell/hud_layout_metrics.gd")
const HudTextBuilder = preload("res://scripts/ui/text/hud_text_builder.gd")
const MESSAGE_MIN_WIDTH := 160.0
const MOVE_PAD_SIZE := Vector2(166, 160)
const COMPACT_MOVE_PAD_SIZE := Vector2(128, 128)
const COMPACT_MOVE_BUTTON_SIZE := Vector2(42, 42)
const MOVE_KNOB_SIZE := Vector2(20, 20)
const HUD_MARGIN := 12.0
const MAX_MESSAGE_LOG := 24
const CONTEXT_ACTION_BUTTON_SIZE := Vector2(140, 52)
const CONTEXT_ACTION_H_SEPARATION := 8.0
const CONTEXT_ACTION_V_SEPARATION := 8.0
const CONTEXT_ACTION_MARGIN := 6.0
const HOLD_ACTIONS := ["move_up", "move_down", "move_left", "move_right"]
const SYSTEMS_TAB_IDS := ["inventory", "spells", "character", "trade", "quests", "journal"]
const PANEL_COLOR := Color(0.06, 0.08, 0.07, 0.78)
const PANEL_BORDER := Color(0.86, 0.78, 0.58, 0.38)

var event_bus
var get_state: Callable
var message_log: Array[String] = []
var visible_debug := false
var root: Control
var status_panel: PanelContainer
var prompt_panel: PanelContainer
var message_panel: PanelContainer
var status_label: Label
var health_label: Label
var health_bar: ProgressBar
var prompt_label: Label
var log_label: Label
var target_panel: PanelContainer
var target_scroll: ScrollContainer
var target_list: VBoxContainer
var context_action_panel: PanelContainer
var context_action_buttons: HFlowContainer
var debug_panel: PanelContainer
var debug_label: Label
var systems_panel: PanelContainer
var systems_tabs: HBoxContainer
var systems_scroll: ScrollContainer
var systems_body_label: Label
var systems_action_list: Container
var systems_tab_buttons: Dictionary = {}
var systems_active_tab := "inventory"
var content_panel: PanelContainer
var content_scroll: ScrollContainer
var content_kind_label: Label
var content_title_label: Label
var content_body_label: Label
var content_choice_list: VBoxContainer
var move_pad: Control
var move_knob: Control
var action_buttons: Control
var primary_action_button: Button
var target_action_button: Button
var move_pad_size := MOVE_PAD_SIZE
var touch_move_vector := Vector2.ZERO
var held_actions: Dictionary = {}
var visible_context_action_count := 0
var applied_layout_size := Vector2.ZERO


func setup(bus, state_provider: Callable) -> void:
	event_bus = bus
	get_state = state_provider
	_build_ui()
	event_bus.message_posted.connect(_on_message_posted)
	event_bus.player_tile_changed.connect(
		func(_tile: Vector2i, _chunk: Vector2i) -> void: refresh()
	)
	event_bus.chunks_changed.connect(func(_chunks: Array) -> void: refresh())
	event_bus.quest_changed.connect(func(_quest_id: String, _state: Dictionary) -> void: refresh())
	event_bus.item_count_changed.connect(func(_item_id: String, _count: int) -> void: refresh())
	event_bus.equipment_changed.connect(func(_equipped: Dictionary) -> void: refresh())
	event_bus.faction_reputation_changed.connect(
		func(_faction_id: String, _reputation: int) -> void: refresh()
	)
	event_bus.progression_changed.connect(
		func(_level: int, _experience: int, _next_level: int, _skill_points: int) -> void:
			refresh()
	)
	event_bus.status_effects_changed.connect(func(_active_statuses: Dictionary) -> void: refresh())
	event_bus.time_changed.connect(
		func(_day: int, _hour: int, _minute: int, _phase: String) -> void: refresh()
	)
	event_bus.world_flag_changed.connect(func(_flag_id: String, _value: bool) -> void: refresh())
	event_bus.player_health_changed.connect(func(_health: int, _max_health: int) -> void: refresh())
	event_bus.combat_resolved.connect(func(_result: Dictionary) -> void: refresh())
	refresh()


func _exit_tree() -> void:
	_release_all_held_actions()
	if touch_move_vector != Vector2.ZERO:
		set_touch_move_vector(Vector2.ZERO)


func refresh() -> void:
	if not get_state.is_valid():
		return
	var state := _state_snapshot()
	if status_label:
		status_label.text = HudTextBuilder.status_text(state)
	if health_bar and health_label:
		_refresh_health_bar(state)
	if prompt_label:
		prompt_label.text = HudTextBuilder.prompt_text(state)
	_refresh_primary_action_button(state)
	_refresh_target_action_button(state)
	var compact := applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0
	if log_label:
		log_label.text = HudTextBuilder.message_text(message_log, compact)
	if debug_label:
		debug_label.text = HudTextBuilder.debug_text(state)
	if systems_body_label:
		systems_body_label.text = HudTextBuilder.systems_text(state, systems_active_tab, message_log)
	_refresh_systems_actions(state)
	_refresh_context_actions(state)
	_refresh_target_picker(state)


func toggle_debug() -> void:
	visible_debug = not visible_debug
	if debug_panel:
		debug_panel.visible = visible_debug


func toggle_systems() -> void:
	if not systems_panel:
		return
	if content_panel:
		hide_content_card()
	if target_panel:
		target_panel.visible = false
	var was_visible := systems_panel.visible
	systems_panel.visible = not systems_panel.visible
	if was_visible and not systems_panel.visible:
		systems_panel_closed.emit()
	refresh()


func show_systems_panel(tab_id: String = "") -> void:
	if not systems_panel:
		return
	if content_panel:
		hide_content_card()
	if target_panel:
		target_panel.visible = false
	systems_panel.visible = true
	var normalized_tab := _normalize_systems_tab(tab_id)
	if SYSTEMS_TAB_IDS.has(normalized_tab):
		var previous_tab := systems_active_tab
		systems_active_tab = normalized_tab
		_refresh_systems_tabs()
		if previous_tab != systems_active_tab:
			systems_tab_changed.emit(systems_active_tab)
	refresh()


func hide_systems_panel() -> void:
	if systems_panel:
		var was_visible := systems_panel.visible
		systems_panel.visible = false
		if was_visible:
			systems_panel_closed.emit()
		refresh()


func is_systems_panel_visible() -> bool:
	return systems_panel != null and systems_panel.visible


func toggle_target_picker() -> void:
	if not target_panel:
		return
	if content_panel:
		hide_content_card()
	if systems_panel:
		systems_panel.visible = false
	target_panel.visible = not target_panel.visible
	refresh()


func hide_target_picker() -> void:
	if target_panel:
		target_panel.visible = false
		refresh()


func is_target_picker_visible() -> bool:
	return target_panel != null and target_panel.visible


func set_systems_tab(tab_id: String) -> void:
	var normalized_tab := _normalize_systems_tab(tab_id)
	if not SYSTEMS_TAB_IDS.has(normalized_tab):
		return
	var previous_tab := systems_active_tab
	systems_active_tab = normalized_tab
	_refresh_systems_tabs()
	if previous_tab != systems_active_tab:
		systems_tab_changed.emit(systems_active_tab)
	refresh()


func get_systems_tab() -> String:
	return systems_active_tab


func show_content_card(title: String, body: String, choices: Array = [], kind: String = "") -> void:
	if not content_panel:
		return
	if systems_panel:
		systems_panel.visible = false
	if target_panel:
		target_panel.visible = false
	if context_action_panel:
		context_action_panel.visible = false
	if content_kind_label:
		content_kind_label.text = ContentCardPresenter.kind_text(kind)
	if content_title_label:
		content_title_label.text = title
	if content_body_label:
		content_body_label.text = body
	_refresh_content_choices(choices)
	content_panel.visible = true
	refresh()


func hide_content_card() -> void:
	if not content_panel or not content_panel.visible:
		return
	content_panel.visible = false
	content_card_closed.emit()
	refresh()


func is_content_card_visible() -> bool:
	return content_panel != null and content_panel.visible


func set_touch_move_vector(direction: Vector2) -> void:
	var next_direction := direction.limit_length(1.0)
	if touch_move_vector.is_equal_approx(next_direction):
		return
	touch_move_vector = next_direction
	move_vector_changed.emit(touch_move_vector)
	_update_move_knob()


func get_touch_move_vector() -> Vector2:
	return touch_move_vector


func _state_snapshot() -> Dictionary:
	var state: Variant = get_state.call()
	if state is Dictionary:
		return state
	return {}


func _build_ui() -> void:
	root = Control.new()
	root.name = "HudRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.resized.connect(_apply_responsive_layout)
	add_child(root)


func _build_status_panel() -> void:
	pass


func _build_prompt_panel() -> void:
	prompt_panel = _new_panel("PromptPanel")
	prompt_panel.anchor_left = 1.0
	prompt_panel.anchor_right = 1.0
	prompt_panel.offset_left = -252
	prompt_panel.offset_top = 12
	prompt_panel.offset_right = -12
	prompt_panel.offset_bottom = 104
	prompt_panel.visible = false
	root.add_child(prompt_panel)
	prompt_label = _new_label(20)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_add_margin(prompt_panel, prompt_label, 12)


func _build_message_panel() -> void:
	message_panel = _new_panel("MessagePanel")
	message_panel.anchor_top = 1.0
	message_panel.anchor_bottom = 1.0
	message_panel.offset_left = 188
	message_panel.offset_top = -94
	message_panel.offset_right = 596
	message_panel.offset_bottom = -12
	root.add_child(message_panel)
	log_label = _new_label(14)
	_add_margin(message_panel, log_label, 10)


func _build_target_panel() -> void:
	pass


func _build_context_action_panel() -> void:
	pass


func _build_debug_panel() -> void:
	debug_panel = _new_panel("DebugPanel")
	debug_panel.visible = visible_debug
	debug_panel.offset_left = 12
	debug_panel.offset_top = 132
	debug_panel.offset_right = 392
	debug_panel.offset_bottom = 326
	root.add_child(debug_panel)
	debug_label = _new_label(13)
	_add_margin(debug_panel, debug_label, 10)


func _build_systems_panel() -> void:
	pass


func _build_touch_controls() -> void:
	pass


func _build_content_panel() -> void:
	pass


func _refresh_health_bar(state: Dictionary) -> void:
	var max_health := maxi(1, _non_negative_int_field(state, "player_max_health", 1))
	var health := clampi(
		_non_negative_int_field(state, "player_health_value", max_health), 0, max_health
	)
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.tooltip_text = "Health: %d/%d" % [health, max_health]
	health_label.text = "Health %d/%d" % [health, max_health]
	var ratio := float(health) / float(max_health)
	var fill_color := Color(0.24, 0.78, 0.38)
	if ratio <= 0.3:
		fill_color = Color(0.88, 0.20, 0.16)
	elif ratio <= 0.6:
		fill_color = Color(0.92, 0.68, 0.22)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(3)
	health_bar.add_theme_stylebox_override("fill", fill)


func _apply_responsive_layout() -> void:
	if not root:
		return
	var viewport_size := root.size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(
			float(ProjectSettings.get_setting("display/window/size/viewport_width")),
			float(ProjectSettings.get_setting("display/window/size/viewport_height"))
		)
	_apply_layout_for_size(viewport_size)


func _apply_layout_for_size(viewport_size: Vector2) -> void:
	applied_layout_size = viewport_size
	var compact_actions := viewport_size.x < 980.0 or viewport_size.y < 540.0
	_set_status_panel_layout(viewport_size, compact_actions)
	_set_move_pad_layout(compact_actions)
	_set_action_button_layout(compact_actions)
	_set_overlay_panel_layout(viewport_size, compact_actions)
	if action_buttons is HBoxContainer:
		var action_width := HudLayoutMetrics.button_row_width(
			action_buttons, 5.0 if compact_actions else 8.0
		)
		if not compact_actions:
			action_width = maxf(action_width, 532.0)
		action_buttons.offset_left = -action_width - HUD_MARGIN
		action_buttons.offset_right = -HUD_MARGIN
		action_buttons.offset_top = -68 if compact_actions else -76
	if message_panel:
		_layout_message_panel(viewport_size, compact_actions)
	refresh()


func _layout_message_panel(viewport_size: Vector2, compact: bool) -> void:
	var message_left := HUD_MARGIN
	var message_right := viewport_size.x - HUD_MARGIN
	if compact:
		message_panel.anchor_top = 0.0
		message_panel.anchor_bottom = 0.0
		if status_panel:
			message_left = status_panel.offset_right + HUD_MARGIN
		message_panel.offset_top = HUD_MARGIN
		message_panel.offset_bottom = 64.0
	else:
		message_panel.anchor_top = 1.0
		message_panel.anchor_bottom = 1.0
		var action_left := (
			viewport_size.x + action_buttons.offset_left if action_buttons else message_right
		)
		message_left = move_pad.offset_right + HUD_MARGIN if move_pad else HUD_MARGIN
		message_right = action_left - HUD_MARGIN
		message_panel.offset_top = -94
		message_panel.offset_bottom = -12
	message_panel.offset_left = message_left
	message_panel.offset_right = message_right
	message_panel.visible = message_right - message_left >= MESSAGE_MIN_WIDTH
	HudLayoutMetrics.apply_log_label(log_label, compact)


func _set_status_panel_layout(viewport_size: Vector2, compact: bool) -> void:
	if not status_panel or not status_label:
		return
	var line_count := status_label.text.count("\n") + 1
	var metrics := HudLayoutMetrics.status_panel(viewport_size, line_count, HUD_MARGIN, compact)
	status_panel.offset_left = HUD_MARGIN
	status_panel.offset_top = HUD_MARGIN
	status_panel.offset_right = HUD_MARGIN + float(metrics.get("width", 318.0))
	status_panel.offset_bottom = HUD_MARGIN + float(metrics.get("height", 136.0))
	status_label.add_theme_font_size_override("font_size", int(metrics.get("status_font_size", 15)))
	if health_label:
		health_label.visible = bool(metrics.get("show_health_label", true))


func _set_overlay_panel_layout(viewport_size: Vector2, compact: bool) -> void:
	if prompt_panel:
		var prompt_width := minf(240.0 if not compact else 204.0, viewport_size.x - HUD_MARGIN * 2.0)
		prompt_panel.visible = not compact
		prompt_panel.offset_left = -prompt_width - HUD_MARGIN
		prompt_panel.offset_right = -HUD_MARGIN
		prompt_panel.offset_top = HUD_MARGIN
		prompt_panel.offset_bottom = 88.0 if compact else 104.0
		if prompt_label:
			prompt_label.add_theme_font_size_override("font_size", 16 if compact else 20)
	if systems_panel:
		var right_panel_width := minf(360.0, maxf(180.0, viewport_size.x - HUD_MARGIN * 2.0))
		systems_panel.offset_left = -right_panel_width - HUD_MARGIN
		systems_panel.offset_right = -HUD_MARGIN
		var systems_top := 108.0 if compact else 114.0
		var systems_bottom := (
			viewport_size.y - HUD_MARGIN if compact else minf(406.0, viewport_size.y - HUD_MARGIN)
		)
		if systems_bottom - systems_top < 132.0:
			systems_top = maxf(HUD_MARGIN, systems_bottom - 132.0)
		systems_panel.offset_top = systems_top
		systems_panel.offset_bottom = systems_bottom
	if content_panel:
		_layout_content_panel(viewport_size, compact)
	if debug_panel:
		var debug_bottom := minf(326.0, viewport_size.y - HUD_MARGIN)
		var debug_top := 132.0
		if debug_bottom - debug_top < 120.0:
			debug_top = maxf(HUD_MARGIN, debug_bottom - 120.0)
		debug_panel.offset_top = debug_top
		debug_panel.offset_bottom = debug_bottom
	if target_panel:
		var target_width := minf(320.0, maxf(220.0, viewport_size.x - HUD_MARGIN * 2.0))
		target_panel.offset_left = -target_width - HUD_MARGIN
		target_panel.offset_right = -HUD_MARGIN
		var target_top := 108.0 if compact else 112.0
		var target_bottom := (
			viewport_size.y - 80.0 if compact else minf(344.0, viewport_size.y - HUD_MARGIN)
		)
		if target_bottom - target_top < 132.0:
			target_top = maxf(HUD_MARGIN, target_bottom - 132.0)
		target_panel.offset_top = target_top
		target_panel.offset_bottom = target_bottom
	if context_action_panel:
		_layout_context_action_panel(viewport_size, compact)


func _layout_content_panel(viewport_size: Vector2, compact: bool) -> void:
	content_panel.anchor_left = 1.0
	content_panel.anchor_right = 1.0
	content_panel.anchor_top = 0.0
	content_panel.anchor_bottom = 0.0
	var content_width := minf(360.0, maxf(244.0, viewport_size.x * (0.38 if compact else 0.34)))
	var content_bottom := viewport_size.y - (80.0 if compact else 88.0)
	var content_top := 96.0 if compact else 112.0
	if content_bottom - content_top < 160.0:
		content_top = maxf(HUD_MARGIN, content_bottom - 160.0)
	content_panel.offset_left = -content_width - HUD_MARGIN
	content_panel.offset_right = -HUD_MARGIN
	content_panel.offset_top = content_top
	content_panel.offset_bottom = content_bottom


func _layout_context_action_panel(viewport_size: Vector2, compact: bool) -> void:
	var context_width := minf(304.0, maxf(220.0, viewport_size.x - HUD_MARGIN * 2.0))
	context_action_panel.offset_left = -context_width - HUD_MARGIN
	context_action_panel.offset_right = -HUD_MARGIN
	context_action_panel.offset_top = 106.0 if compact else 112.0
	var context_height := UiActionButtons.wrapped_panel_height(
		context_width,
		visible_context_action_count,
		CONTEXT_ACTION_BUTTON_SIZE,
		Vector2(CONTEXT_ACTION_H_SEPARATION, CONTEXT_ACTION_V_SEPARATION),
		CONTEXT_ACTION_MARGIN,
		100.0 if compact else 104.0,
		106.0 if compact else 112.0,
		80.0 if compact else HUD_MARGIN,
		HUD_MARGIN,
		viewport_size.y
	)
	context_action_panel.offset_bottom = context_action_panel.offset_top + context_height


func _set_action_button_layout(compact: bool) -> void:
	if not action_buttons:
		return
	if action_buttons is HBoxContainer:
		action_buttons.add_theme_constant_override("separation", 5 if compact else 8)
	var sizes := {
		"InteractButton": Vector2(92, 52) if compact else Vector2(118, 58),
		"TargetButton": Vector2(66, 52) if compact else Vector2(82, 58),
		"SystemsButton": Vector2(72, 52) if compact else Vector2(92, 58)
	}
	for child in action_buttons.get_children():
		if child is Button:
			child.custom_minimum_size = sizes.get(child.name, BUTTON_SIZE)
			child.add_theme_font_size_override("font_size", 13 if compact else 15)


func _set_move_pad_layout(compact: bool) -> void:
	if not move_pad:
		return
	move_pad_size = COMPACT_MOVE_PAD_SIZE if compact else MOVE_PAD_SIZE
	move_pad.offset_left = 18
	move_pad.offset_top = -move_pad_size.y - HUD_MARGIN
	move_pad.offset_right = move_pad.offset_left + move_pad_size.x
	move_pad.offset_bottom = -HUD_MARGIN
	var button_size := COMPACT_MOVE_BUTTON_SIZE if compact else BUTTON_SIZE
	var positions := _move_button_positions(compact)
	for child in move_pad.get_children():
		if child is Button:
			child.custom_minimum_size = button_size
			child.size = button_size
			child.position = positions.get(child.name, child.position)
			child.add_theme_font_size_override("font_size", 18 if compact else 20)
	_update_move_knob()


func _move_button_positions(compact: bool) -> Dictionary:
	if compact:
		return {
			"MoveUpButton": Vector2(43, 6),
			"MoveLeftButton": Vector2(6, 43),
			"MoveRightButton": Vector2(80, 43),
			"MoveDownButton": Vector2(43, 80)
		}
	return {
		"MoveUpButton": Vector2(54, 6),
		"MoveLeftButton": Vector2(6, 54),
		"MoveRightButton": Vector2(102, 54),
		"MoveDownButton": Vector2(54, 102)
	}


func _refresh_primary_action_button(state: Dictionary) -> void:
	if not primary_action_button:
		return
	if String(primary_action_button.get_meta("action_kind", "")) == "attack":
		primary_action_button.text = "Attack"
		primary_action_button.tooltip_text = "Aim attack"
		return
	var action_text := String(state.get("primary_action", "Interact"))
	if _has_open_overlay_panel() and not (target_panel and target_panel.visible):
		action_text = "Close"
	var compact := applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0
	primary_action_button.text = (
		ButtonTextFormatter.compact_primary_action_label(
			action_text, String(state.get("nearby", "none"))
		)
		if compact
		else ButtonTextFormatter.primary_action_label(action_text)
	)
	primary_action_button.tooltip_text = action_text


func _refresh_target_action_button(state: Dictionary) -> void:
	if not target_action_button:
		return
	var compact := applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0
	var targets := _array_field(state.get("nearby_targets", []))
	var picker_visible := target_panel and target_panel.visible
	var suffix := ""
	if not targets.is_empty():
		suffix = "\n%s" % String((targets[0] as Dictionary).get("name", "")) if compact else ""
	target_action_button.text = "Close" if picker_visible else "Next%s" % suffix
	target_action_button.tooltip_text = "Close targets" if picker_visible else "Next target"


func _has_open_overlay_panel() -> bool:
	return (
		(content_panel and content_panel.visible)
		or (systems_panel and systems_panel.visible)
		or (target_panel and target_panel.visible)
	)


func _add_margin(panel: PanelContainer, child: Control, margin_size: int) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", margin_size)
	margin.add_theme_constant_override("margin_top", margin_size)
	margin.add_theme_constant_override("margin_right", margin_size)
	margin.add_theme_constant_override("margin_bottom", margin_size)
	panel.add_child(margin)
	margin.add_child(child)


func _new_panel(panel_name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = panel_name
	_apply_panel_style(panel)
	return panel


func _apply_panel_style(panel: Control) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = PANEL_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)


func _new_label(font_size: int) -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _new_button(text: String, min_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 15)
	return button


func _refresh_target_picker(_state: Dictionary) -> void:
	pass


func _refresh_content_choices(_choices: Array) -> void:
	pass


func _refresh_systems_actions(_state: Dictionary) -> void:
	pass


func _refresh_context_actions(_state: Dictionary) -> void:
	pass


func _refresh_systems_tabs() -> void:
	for tab_id in systems_tab_buttons:
		var button: Button = systems_tab_buttons[tab_id]
		button.button_pressed = String(tab_id) == systems_active_tab


func _on_move_pad_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			_update_touch_direction_from_local(event.position)
		else:
			set_touch_move_vector(Vector2.ZERO)
	elif event is InputEventMouseMotion and int(event.button_mask) != 0:
		_update_touch_direction_from_local(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_update_touch_direction_from_local(event.position)
		else:
			set_touch_move_vector(Vector2.ZERO)
	elif event is InputEventScreenDrag:
		_update_touch_direction_from_local(event.position)


func _update_touch_direction_from_local(local_position: Vector2) -> void:
	var center := move_pad_size * 0.5
	var radius := minf(move_pad_size.x, move_pad_size.y) * 0.5
	set_touch_move_vector((local_position - center) / radius)


func _update_move_knob() -> void:
	if not move_knob:
		return
	var center := move_pad_size * 0.5
	var radius := minf(move_pad_size.x, move_pad_size.y) * 0.27
	move_knob.position = center + touch_move_vector * radius - MOVE_KNOB_SIZE * 0.5


func _press_hold_action(action: String) -> void:
	if not HOLD_ACTIONS.has(action):
		return
	held_actions[action] = true
	Input.action_press(StringName(action))


func _release_hold_action(action: String) -> void:
	if not held_actions.has(action):
		return
	held_actions.erase(action)
	Input.action_release(StringName(action))


func _release_all_held_actions() -> void:
	for action in held_actions.keys():
		Input.action_release(StringName(action))
	held_actions.clear()


func _on_message_posted(text: String) -> void:
	message_log.append(text)
	while message_log.size() > MAX_MESSAGE_LOG:
		message_log.remove_at(0)
	refresh()


func _array_field(value: Variant) -> Array:
	return value if value is Array else []


func _normalize_systems_tab(tab_id: String) -> String:
	return {"map": "journal", "world": "journal", "log": "journal"}.get(tab_id, tab_id)


func _non_negative_int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	var value: Variant = source.get(field_id, fallback)
	if not _is_number(value):
		return maxi(0, fallback)
	return maxi(0, int(value))


func _is_number(value: Variant) -> bool:
	return value is int or value is float
