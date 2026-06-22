class_name RpgHud
extends DebugHud

const NAV_BUTTON_SIZE := Vector2(92, 58)
const COMPACT_NAV_BUTTON_SIZE := Vector2(64, 46)
const LOCATION_BANNER_WIDTH := 344.0
const LOCATION_BANNER_HEIGHT := 54.0
const STATUS_PANEL_SIZE := Vector2(318, 116)
const COMPACT_STATUS_PANEL_SIZE := Vector2(238, 88)
const SYSTEMS_PANEL_MIN_SIZE := Vector2(600, 328)

var location_banner_panel: PanelContainer
var location_banner_label: Label
var top_nav_panel: PanelContainer
var top_nav_buttons: HBoxContainer
var portrait_panel: Panel
var level_badge_label: Label
var systems_title_label: Label
var systems_subtitle_label: Label
var systems_resources_label: Label
var systems_detail_label: Label
var systems_character_label: Label
var systems_nav: VBoxContainer
var systems_frame: MarginContainer
var systems_main_row: HBoxContainer
var systems_left_panel: PanelContainer
var systems_center_panel: PanelContainer
var systems_detail_panel: PanelContainer
var systems_character_panel: PanelContainer
var systems_bottom_panel: PanelContainer


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


func _build_systems_panel() -> void:
	systems_panel = _new_panel("SystemsPanel")
	_apply_modal_panel_style(systems_panel)
	systems_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	systems_panel.z_index = 100
	systems_panel.visible = false
	root.add_child(systems_panel)

	systems_frame = MarginContainer.new()
	systems_frame.name = "SystemsFrame"
	_set_margin_constants(systems_frame, 16)
	systems_panel.add_child(systems_frame)

	var outer := VBoxContainer.new()
	outer.name = "SystemsOuter"
	outer.add_theme_constant_override("separation", 10)
	systems_frame.add_child(outer)

	_build_systems_top_bar(outer)
	_build_systems_body(outer)
	_build_systems_bottom_bar(outer)
	_refresh_systems_tabs()


func _build_systems_top_bar(parent: BoxContainer) -> void:
	var top_bar := HBoxContainer.new()
	top_bar.name = "SystemsTopBar"
	top_bar.add_theme_constant_override("separation", 12)
	parent.add_child(top_bar)

	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override("separation", 2)
	top_bar.add_child(title_stack)

	systems_title_label = _new_label(26)
	systems_title_label.name = "SystemsTitle"
	title_stack.add_child(systems_title_label)

	systems_subtitle_label = _new_label(15)
	systems_subtitle_label.name = "SystemsSubtitle"
	systems_subtitle_label.add_theme_color_override("font_color", Color(0.82, 0.74, 0.60))
	title_stack.add_child(systems_subtitle_label)

	systems_resources_label = _new_label(17)
	systems_resources_label.name = "SystemsResources"
	systems_resources_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	systems_resources_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	systems_resources_label.custom_minimum_size = Vector2(270, 48)
	top_bar.add_child(systems_resources_label)

	var close := _new_button("X", Vector2(54, 48))
	close.name = "SystemsCloseButton"
	close.tooltip_text = "Close menu"
	close.pressed.connect(hide_systems_panel)
	top_bar.add_child(close)


func _build_systems_body(parent: BoxContainer) -> void:
	systems_main_row = HBoxContainer.new()
	systems_main_row.name = "SystemsMainRow"
	systems_main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	systems_main_row.add_theme_constant_override("separation", 10)
	parent.add_child(systems_main_row)

	systems_left_panel = _new_panel("SystemsNavPanel")
	systems_left_panel.custom_minimum_size = Vector2(176, 0)
	systems_main_row.add_child(systems_left_panel)

	systems_nav = VBoxContainer.new()
	systems_nav.name = "SystemsNav"
	systems_nav.add_theme_constant_override("separation", 8)
	_add_margin(systems_left_panel, systems_nav, 10)
	systems_tabs = HBoxContainer.new()
	systems_tabs.name = "SystemsTabs"
	systems_tabs.visible = false
	systems_nav.add_child(systems_tabs)
	_add_systems_tab("inventory", "Inventory")
	_add_systems_tab("character", "Character")
	_add_systems_tab("quests", "Quests")
	_add_systems_tab("map", "Map")
	_add_systems_tab("journal", "Journal")
	_add_systems_tab("trade", "Trade")

	systems_center_panel = _new_panel("SystemsContentPanel")
	systems_center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	systems_main_row.add_child(systems_center_panel)

	systems_scroll = ScrollContainer.new()
	systems_scroll.name = "SystemsScroll"
	systems_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	systems_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_add_margin(systems_center_panel, systems_scroll, 12)

	systems_body_label = _new_label(15)
	systems_body_label.name = "SystemsBody"
	systems_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	systems_scroll.add_child(systems_body_label)

	systems_detail_panel = _new_panel("SystemsDetailPanel")
	systems_detail_panel.custom_minimum_size = Vector2(232, 0)
	systems_main_row.add_child(systems_detail_panel)

	var detail_stack := VBoxContainer.new()
	detail_stack.add_theme_constant_override("separation", 8)
	_add_margin(systems_detail_panel, detail_stack, 12)

	var detail_title := _new_label(17)
	detail_title.text = "Details"
	detail_stack.add_child(detail_title)

	systems_detail_label = _new_label(14)
	systems_detail_label.name = "SystemsDetail"
	systems_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_stack.add_child(systems_detail_label)

	systems_character_panel = _new_panel("SystemsCharacterPanel")
	systems_character_panel.custom_minimum_size = Vector2(210, 0)
	systems_main_row.add_child(systems_character_panel)

	var character_stack := VBoxContainer.new()
	character_stack.add_theme_constant_override("separation", 8)
	_add_margin(systems_character_panel, character_stack, 12)

	var character_title := _new_label(17)
	character_title.text = "Adventurer"
	character_stack.add_child(character_title)

	systems_character_label = _new_label(14)
	systems_character_label.name = "SystemsCharacter"
	systems_character_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_stack.add_child(systems_character_label)


func _build_systems_bottom_bar(parent: BoxContainer) -> void:
	systems_bottom_panel = _new_panel("SystemsBottomBar")
	systems_bottom_panel.custom_minimum_size = Vector2(0, 72)
	parent.add_child(systems_bottom_panel)

	var scroll := ScrollContainer.new()
	scroll.name = "SystemsActionScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_add_margin(systems_bottom_panel, scroll, 8)

	systems_action_list = VBoxContainer.new()
	systems_action_list.name = "SystemsActions"
	systems_action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	systems_action_list.add_theme_constant_override("separation", 6)
	scroll.add_child(systems_action_list)


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


func _add_systems_tab(tab_id: String, text: String) -> void:
	var button := _new_button(text, Vector2(150, 54))
	button.toggle_mode = true
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(func() -> void: set_systems_tab(tab_id))
	if systems_nav:
		systems_nav.add_child(button)
	elif systems_tabs:
		systems_tabs.add_child(button)
	systems_tab_buttons[tab_id] = button


func _refresh_systems_tabs() -> void:
	for tab_id in systems_tab_buttons:
		var button: Button = systems_tab_buttons[tab_id]
		var active := String(tab_id) == systems_active_tab
		button.button_pressed = active
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_color_override(
			"font_color",
			Color(0.78, 1.0, 0.56) if active else Color(0.96, 0.90, 0.78)
		)


func _set_overlay_panel_layout(viewport_size: Vector2, compact: bool) -> void:
	super._set_overlay_panel_layout(viewport_size, compact)
	if prompt_panel:
		prompt_panel.visible = false
	_layout_systems_panel(viewport_size, compact)
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


func _layout_systems_panel(_viewport_size: Vector2, compact: bool) -> void:
	if not systems_panel or not systems_frame:
		return
	systems_panel.anchor_left = 0.0
	systems_panel.anchor_right = 1.0
	systems_panel.anchor_top = 0.0
	systems_panel.anchor_bottom = 1.0
	systems_panel.offset_left = HUD_MARGIN
	systems_panel.offset_top = HUD_MARGIN
	systems_panel.offset_right = -HUD_MARGIN
	systems_panel.offset_bottom = -HUD_MARGIN
	_set_margin_constants(systems_frame, 8 if compact else 16)

	if systems_main_row:
		systems_main_row.add_theme_constant_override("separation", 6 if compact else 10)
	if systems_left_panel:
		systems_left_panel.custom_minimum_size = Vector2(116, 0) if compact else Vector2(176, 0)
	if systems_detail_panel:
		systems_detail_panel.visible = not compact
		systems_detail_panel.custom_minimum_size = Vector2(232, 0)
	if systems_character_panel:
		systems_character_panel.visible = not compact
		systems_character_panel.custom_minimum_size = Vector2(210, 0)
	if systems_resources_label:
		systems_resources_label.custom_minimum_size = Vector2(168, 40) if compact else Vector2(270, 48)
		systems_resources_label.add_theme_font_size_override("font_size", 12 if compact else 17)
	if systems_title_label:
		systems_title_label.add_theme_font_size_override("font_size", 20 if compact else 26)
	if systems_subtitle_label:
		systems_subtitle_label.add_theme_font_size_override("font_size", 11 if compact else 15)
	for button in systems_tab_buttons.values():
		if button is Button:
			button.custom_minimum_size = Vector2(96, 40) if compact else Vector2(150, 54)
			button.add_theme_font_size_override("font_size", 11 if compact else 15)
	if systems_bottom_panel:
		systems_bottom_panel.custom_minimum_size = Vector2(0, 58) if compact else Vector2(0, 72)


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
	_refresh_systems_chrome(state)


func _refresh_systems_chrome(state: Dictionary) -> void:
	if not systems_title_label:
		return
	systems_title_label.text = _rpg_location_name(state)
	systems_subtitle_label.text = "%s - %s" % [
		_systems_title(systems_active_tab),
		_systems_subtitle(systems_active_tab)
	]
	systems_resources_label.text = _systems_resource_text(state)
	systems_detail_label.text = _systems_detail_text(state, systems_active_tab)
	systems_character_label.text = _systems_character_text(state)


func _refresh_systems_actions(state: Dictionary) -> void:
	if not systems_action_list:
		return
	var actions := SystemsActionBuilder.actions_for_tab(state, systems_active_tab)
	systems_action_list.visible = UiActionButtons.refresh(
		systems_action_list, actions, self, "inventory_item_selected", "item_id",
		Vector2(0, 48), 14, "No actions"
	)


func _systems_title(tab_id: String) -> String:
	return {
		"inventory": "Inventory",
		"character": "Character",
		"quests": "Quests",
		"map": "Map",
		"journal": "Journal",
		"trade": "Trade"
	}.get(tab_id, "Menu")


func _systems_subtitle(tab_id: String) -> String:
	return {
		"inventory": "Gear, supplies, and valuables.",
		"character": "Training, health, equipment, and effects.",
		"quests": "Active work and nearby objectives.",
		"map": "Known places, routes, and nearby leads.",
		"journal": "Time, reputation, and recent events.",
		"trade": "Buy and sell with the selected merchant."
	}.get(tab_id, "Briarwatch")


func _systems_resource_text(state: Dictionary) -> String:
	var inventory := String(state.get("inventory", "empty"))
	var gold := _count_named_entry(inventory, "Gold Coin")
	var time := String(state.get("time", "Day 1, 08:00"))
	return "Gold %d     %s" % [gold, _short_time(time)]


func _systems_detail_text(state: Dictionary, tab_id: String) -> String:
	var detail := ""
	match tab_id:
		"inventory":
			detail = _first_non_empty(
				String(state.get("inventory_details", "")),
				"No carried item details yet."
			)
		"character":
			detail = _first_non_empty(
				String(state.get("progression_details", "")),
				String(state.get("progression", "Level 1"))
			)
		"quests":
			detail = _quest_detail_text(state)
		"map":
			detail = _first_non_empty(
				String(state.get("location_details", "")),
				String(state.get("locations", "No known places."))
			)
		"journal":
			detail = _first_non_empty(String(state.get("factions", "")), "No reputation notes.")
		"trade":
			detail = _first_non_empty(String(state.get("trade", "")), "No trader selected.")
	return detail


func _systems_character_text(state: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append(String(state.get("player_health", "Health unknown")))
	lines.append(String(state.get("progression", "Level 1")))
	lines.append("")
	lines.append(String(state.get("equipment", "Weapon: empty\nOffhand: empty\nBody: empty")))
	var statuses := String(state.get("statuses", "none"))
	if statuses != "none":
		lines.append("")
		lines.append("Effects: %s" % statuses)
	return "\n".join(lines)


func _quest_detail_text(state: Dictionary) -> String:
	var quests := _array_field(state.get("quests", []))
	if quests.is_empty():
		return "No active quests."
	var lines: Array[String] = []
	for quest in quests:
		lines.append(String(quest))
	var directions := String(state.get("quest_directions", "none"))
	if directions != "none" and not directions.is_empty():
		lines.append("")
		lines.append(directions)
	return "\n".join(lines)


func _first_non_empty(value: String, fallback: String) -> String:
	var stripped := value.strip_edges()
	if stripped.is_empty() or stripped == "none":
		return fallback
	return stripped


func _short_time(time: String) -> String:
	var phase_start := time.find(" (")
	if phase_start >= 0:
		time = time.substr(0, phase_start)
	return time.replace("Day ", "D")


func _count_named_entry(summary: String, item_name: String) -> int:
	for raw_part in summary.split(",", false):
		var part := raw_part.strip_edges()
		if not part.begins_with(item_name):
			continue
		var marker := part.rfind("x")
		if marker >= 0 and marker + 1 < part.length():
			return maxi(0, int(part.substr(marker + 1)))
	return 0


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


func _apply_modal_panel_style(panel: Control) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.023, 0.019, 0.96)
	style.border_color = Color(0.86, 0.68, 0.38, 0.82)
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


func _set_margin_constants(margin: MarginContainer, value: int) -> void:
	margin.add_theme_constant_override("margin_left", value)
	margin.add_theme_constant_override("margin_top", value)
	margin.add_theme_constant_override("margin_right", value)
	margin.add_theme_constant_override("margin_bottom", value)
