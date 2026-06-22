class_name RpgHud
extends DebugHud

const NAV_BUTTON_SIZE := Vector2(92, 58)
const COMPACT_NAV_BUTTON_SIZE := Vector2(64, 46)
const LOCATION_BANNER_WIDTH := 344.0
const LOCATION_BANNER_HEIGHT := 54.0
const STATUS_PANEL_SIZE := Vector2(318, 116)
const COMPACT_STATUS_PANEL_SIZE := Vector2(238, 88)

var location_banner_panel: PanelContainer
var location_banner_label: Label
var top_nav_panel: PanelContainer
var top_nav_buttons: HBoxContainer
var portrait_panel: Panel
var level_badge_label: Label


func _build_ui() -> void:
	super._build_ui()
	_build_location_banner()
	_build_top_nav()
	_apply_responsive_layout()
	refresh()


func refresh() -> void:
	super.refresh()
	var state := _state_snapshot()
	_refresh_player_status(state)
	if not location_banner_label:
		return
	location_banner_label.text = _rpg_location_name(state)


func _refresh_health_bar(state: Dictionary) -> void:
	super._refresh_health_bar(state)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.64, 0.08, 0.06, 0.96)
	fill.border_color = Color(0.96, 0.74, 0.42, 0.55)
	fill.set_border_width_all(1)
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	health_bar.add_theme_stylebox_override("fill", fill)


func _build_status_panel() -> void:
	status_panel = _new_panel("StatusPanel")
	status_panel.offset_left = 12
	status_panel.offset_top = 12
	status_panel.offset_right = 330
	status_panel.offset_bottom = 128
	root.add_child(status_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_add_margin(status_panel, row, 10)

	portrait_panel = Panel.new()
	portrait_panel.name = "PortraitPanel"
	portrait_panel.custom_minimum_size = Vector2(74, 74)
	portrait_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_portrait_style(portrait_panel)
	row.add_child(portrait_panel)

	level_badge_label = _new_label(15)
	level_badge_label.name = "LevelBadge"
	level_badge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_badge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_badge_label.position = Vector2(52, 52)
	level_badge_label.size = Vector2(26, 26)
	_apply_badge_style(level_badge_label)
	portrait_panel.add_child(level_badge_label)

	var stack := VBoxContainer.new()
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stack.add_theme_constant_override("separation", 5)
	row.add_child(stack)

	status_label = _new_label(16)
	status_label.name = "PlayerStatus"
	status_label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.78))
	stack.add_child(status_label)

	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(0, 12)
	health_bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.02, 0.018, 0.014, 0.92)
	background.border_color = PANEL_BORDER
	background.set_border_width_all(1)
	background.corner_radius_top_left = 3
	background.corner_radius_top_right = 3
	background.corner_radius_bottom_left = 3
	background.corner_radius_bottom_right = 3
	health_bar.add_theme_stylebox_override("background", background)
	stack.add_child(health_bar)

	health_label = _new_label(13)
	health_label.name = "HealthValue"
	health_label.add_theme_color_override("font_color", Color(0.95, 0.84, 0.70))
	stack.add_child(health_label)


func _build_location_banner() -> void:
	location_banner_panel = _new_panel("LocationBanner")
	location_banner_panel.anchor_left = 0.5
	location_banner_panel.anchor_right = 0.5
	location_banner_panel.offset_left = -LOCATION_BANNER_WIDTH * 0.5
	location_banner_panel.offset_right = LOCATION_BANNER_WIDTH * 0.5
	location_banner_panel.offset_top = HUD_MARGIN
	location_banner_panel.offset_bottom = HUD_MARGIN + LOCATION_BANNER_HEIGHT
	root.add_child(location_banner_panel)

	location_banner_label = _new_label(24)
	location_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location_banner_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_add_margin(location_banner_panel, location_banner_label, 8)


func _build_top_nav() -> void:
	top_nav_panel = _new_panel("TopNavPanel")
	top_nav_panel.anchor_left = 1.0
	top_nav_panel.anchor_right = 1.0
	root.add_child(top_nav_panel)

	top_nav_buttons = HBoxContainer.new()
	top_nav_buttons.name = "TopNavButtons"
	top_nav_buttons.add_theme_constant_override("separation", 6)
	_add_margin(top_nav_panel, top_nav_buttons, 8)

	_add_nav_button("Quests", func() -> void: show_systems_panel("quests"))
	_add_nav_button("Journal", func() -> void: show_systems_panel("journal"))
	_add_nav_button("Map", func() -> void: show_systems_panel("map"))
	_add_nav_button("Menu", toggle_systems)


func _add_nav_button(text: String, callback: Callable) -> void:
	var button := _new_button(text, NAV_BUTTON_SIZE)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	top_nav_buttons.add_child(button)


func _set_overlay_panel_layout(viewport_size: Vector2, compact: bool) -> void:
	super._set_overlay_panel_layout(viewport_size, compact)
	if prompt_panel:
		prompt_panel.visible = false
	_layout_top_nav(viewport_size, compact)
	_layout_location_banner(viewport_size, compact)


func _set_status_panel_layout(_viewport_size: Vector2, compact: bool) -> void:
	var size := COMPACT_STATUS_PANEL_SIZE if compact else STATUS_PANEL_SIZE
	status_panel.offset_left = HUD_MARGIN
	status_panel.offset_top = HUD_MARGIN
	status_panel.offset_right = HUD_MARGIN + size.x
	status_panel.offset_bottom = HUD_MARGIN + size.y
	portrait_panel.custom_minimum_size = Vector2(56, 56) if compact else Vector2(74, 74)
	level_badge_label.position = Vector2(38, 38) if compact else Vector2(52, 52)
	level_badge_label.size = Vector2(24, 24) if compact else Vector2(26, 26)
	status_label.add_theme_font_size_override("font_size", 13 if compact else 16)
	health_label.add_theme_font_size_override("font_size", 11 if compact else 13)
	health_label.visible = true


func _layout_location_banner(viewport_size: Vector2, compact: bool) -> void:
	if not location_banner_panel:
		return
	location_banner_panel.visible = not compact
	if compact:
		return
	var nav_left := viewport_size.x + top_nav_panel.offset_left
	var left_bound := status_panel.offset_right + HUD_MARGIN
	var right_bound := nav_left - HUD_MARGIN
	var available_width := right_bound - left_bound
	location_banner_panel.visible = available_width >= 220.0
	if not location_banner_panel.visible:
		return
	var width := minf(LOCATION_BANNER_WIDTH, available_width)
	var center_x := left_bound + available_width * 0.5
	var anchor_offset := center_x - viewport_size.x * 0.5
	var height := LOCATION_BANNER_HEIGHT
	location_banner_panel.offset_left = anchor_offset - width * 0.5
	location_banner_panel.offset_right = anchor_offset + width * 0.5
	location_banner_panel.offset_top = HUD_MARGIN
	location_banner_panel.offset_bottom = HUD_MARGIN + height
	location_banner_label.add_theme_font_size_override("font_size", 18 if compact else 24)


func _layout_top_nav(_viewport_size: Vector2, compact: bool) -> void:
	if not top_nav_panel or not top_nav_buttons:
		return
	top_nav_panel.visible = not compact
	if compact:
		return
	var button_size := COMPACT_NAV_BUTTON_SIZE if compact else NAV_BUTTON_SIZE
	for child in top_nav_buttons.get_children():
		if child is Button:
			child.custom_minimum_size = button_size
			child.add_theme_font_size_override("font_size", 11 if compact else 14)
	var separation := 4.0 if compact else 6.0
	top_nav_buttons.add_theme_constant_override("separation", int(separation))
	var width := button_size.x * 4.0 + separation * 3.0 + 16.0
	var height := button_size.y + 16.0
	top_nav_panel.offset_left = -width - HUD_MARGIN
	top_nav_panel.offset_right = -HUD_MARGIN
	top_nav_panel.offset_top = HUD_MARGIN
	top_nav_panel.offset_bottom = HUD_MARGIN + height


func _rpg_location_name(state: Dictionary) -> String:
	var locations := String(state.get("locations", ""))
	if locations.is_empty() or locations == "none":
		return "Briarwatch"
	var first := locations.split(",", false)[0].strip_edges()
	return "Briarwatch" if first == "Briarwatch Crossroads" else first


func _refresh_player_status(state: Dictionary) -> void:
	if not status_label or not health_label or not level_badge_label:
		return
	var progression_text := String(state.get("progression", "Level 1"))
	var level := _level_from_progression(progression_text)
	level_badge_label.text = str(level)
	var lines: Array[String] = ["Adventurer", progression_text]
	var legacy_status := HudTextBuilder.status_text(state)
	var legacy_lines := legacy_status.split("\n", false)
	if legacy_lines.size() > 1:
		for index in range(1, legacy_lines.size()):
			lines.append(legacy_lines[index])
	status_label.text = "\n".join(lines)
	health_label.text = "Health %d/%d" % [
		int(health_bar.value),
		int(health_bar.max_value)
	]


func _level_from_progression(text: String) -> int:
	var expression := RegEx.new()
	if expression.compile("Level\\s+(\\d+)") != OK:
		return 1
	var result := expression.search(text)
	if not result:
		return 1
	return maxi(1, int(result.get_string(1)))


func _apply_panel_style(panel: Control) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.032, 0.026, 0.88)
	style.border_color = Color(0.78, 0.61, 0.34, 0.70)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	panel.add_theme_stylebox_override("panel", style)


func _new_button(text: String, min_size: Vector2) -> Button:
	var button := super._new_button(text, min_size)
	_apply_button_style(button)
	return button


func _apply_button_style(button: Button) -> void:
	button.add_theme_color_override("font_color", Color(0.96, 0.90, 0.78))
	button.add_theme_stylebox_override("normal", _button_style(Color(0.045, 0.043, 0.036, 0.92)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.10, 0.13, 0.08, 0.96)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.16, 0.20, 0.10, 0.98)))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.72, 0.56, 0.32, 0.68)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _apply_portrait_style(panel: Panel) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.095, 0.075, 0.96)
	style.border_color = Color(0.86, 0.70, 0.42, 0.85)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 38
	style.corner_radius_top_right = 38
	style.corner_radius_bottom_left = 38
	style.corner_radius_bottom_right = 38
	panel.add_theme_stylebox_override("panel", style)


func _apply_badge_style(label: Label) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.048, 0.038, 0.98)
	style.border_color = Color(0.86, 0.70, 0.42, 0.90)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 13
	style.corner_radius_top_right = 13
	style.corner_radius_bottom_left = 13
	style.corner_radius_bottom_right = 13
	label.add_theme_stylebox_override("normal", style)
	label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.78))
