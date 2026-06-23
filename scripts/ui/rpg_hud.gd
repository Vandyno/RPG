class_name RpgHud
extends HudShell
signal aim_action_released(action_id: String, direction: Vector2)
const RpgSystemsRowBuilder = preload("res://scripts/ui/rpg_systems_row_builder.gd")
const RpgSystemsTextBuilder = preload("res://scripts/ui/rpg_systems_text_builder.gd")
const RpgContentPanelBuilder = preload("res://scripts/ui/rpg_content_panel_builder.gd")
const RpgContentChoiceBuilder = preload("res://scripts/ui/rpg_content_choice_builder.gd")
const RpgContextActionPanelBuilder = preload("res://scripts/ui/rpg_context_action_panel_builder.gd")
const RpgActionClusterBuilder = preload("res://scripts/ui/rpg_action_cluster_builder.gd")
const RpgMovePadBuilder = preload("res://scripts/ui/rpg_move_pad_builder.gd")
const RpgStatusTextBuilder = preload("res://scripts/ui/rpg_status_text_builder.gd")
const RpgSystemsCharacterPaneBuilder = preload(
	"res://scripts/ui/rpg_systems_character_pane_builder.gd"
)
const RpgTargetPanelBuilder = preload("res://scripts/ui/rpg_target_panel_builder.gd")
const RpgInventoryItemButton = preload("res://scripts/ui/rpg_inventory_item_button.gd")
const RpgEquipmentSlot = preload("res://scripts/ui/rpg_equipment_slot.gd")
const RpgSpellSlotPanelBuilder = preload("res://scripts/ui/rpg_spell_slot_panel_builder.gd")
const NAV_BUTTON_SIZE := Vector2(92, 58)
const COMPACT_NAV_BUTTON_SIZE := Vector2(44, 46)
const LOCATION_BANNER_WIDTH := 344.0
const LOCATION_BANNER_HEIGHT := 54.0
const STATUS_PANEL_SIZE := Vector2(318, 116)
const COMPACT_STATUS_PANEL_SIZE := Vector2(180, 88)
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
var systems_detail_title_label: Label
var systems_detail_label: Label
var systems_nav: VBoxContainer
var systems_frame: MarginContainer
var systems_main_row: HBoxContainer
var systems_left_panel: PanelContainer
var systems_center_panel: PanelContainer
var systems_detail_panel: PanelContainer
var systems_character_panel: PanelContainer
var systems_character_nodes := {}
var systems_detail_equipment_panel: PanelContainer
var systems_detail_equipment_nodes := {}
var systems_spell_slot_panel: PanelContainer
var systems_spell_slot_buttons := {}
var systems_category_row: HFlowContainer
var systems_item_list: VBoxContainer
var systems_selected_row_id := ""
var systems_active_category := "all"
var content_identity_panel: PanelContainer
var content_portrait_panel: Panel
var content_portrait_label: Label
var content_right_stack: VBoxContainer
var content_choice_panel: PanelContainer
var content_preview_panel: PanelContainer
var content_preview_title_label: Label
var content_preview_label: Label
var content_preview_reward_label: Label
var content_close_button: Button
var ability_slot_buttons := {}
func _build_ui() -> void:
	super._build_ui()
	_build_location_banner()
	_build_top_nav()
	_apply_responsive_layout()
	refresh()
func _apply_layout_for_size(viewport_size: Vector2) -> void:
	super._apply_layout_for_size(viewport_size)

func refresh() -> void:
	super.refresh()
	var state := _state_snapshot()
	_refresh_player_status(state)
	_sync_content_overlay_chrome()
	if not location_banner_label:
		return
	location_banner_label.text = _rpg_location_name(state)
func toggle_debug() -> void:
	visible_debug = false
	if debug_panel:
		debug_panel.visible = false
func show_content_card(title: String, body: String, choices: Array = [], kind: String = "") -> void:
	super.show_content_card(title, body, choices, kind)
	RpgContentPanelBuilder.apply_mode(
		content_portrait_label, content_choice_panel, content_close_button, title, choices, kind
	)
	_refresh_content_preview(choices, kind)
	var layout_size := applied_layout_size if applied_layout_size != Vector2.ZERO else root.size
	_layout_content_panel(layout_size, layout_size.x < 980.0 or layout_size.y < 540.0)
	_sync_content_overlay_chrome()
func hide_content_card() -> void:
	super.hide_content_card()
	_sync_content_overlay_chrome()
func show_systems_panel(tab_id: String = "") -> void:
	var normalized_tab := _normalize_systems_tab(tab_id)
	if normalized_tab != systems_active_tab:
		systems_active_category = _default_category_for_tab(normalized_tab)
	super.show_systems_panel(tab_id)
func set_systems_tab(tab_id: String) -> void:
	var normalized_tab := _normalize_systems_tab(tab_id)
	if normalized_tab != systems_active_tab:
		systems_active_category = _default_category_for_tab(normalized_tab)
	super.set_systems_tab(tab_id)
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
	_add_systems_tab("inventory", "I\nInventory")
	_add_systems_tab("spells", "S\nSpells")
	_add_systems_tab("character", "C\nCharacter")
	_add_systems_tab("quests", "Q\nQuests")
	_add_systems_tab("map", "M\nMap")
	_add_systems_tab("journal", "J\nJournal")
	_add_systems_tab("trade", "T\nTrade")

	systems_center_panel = _new_panel("SystemsContentPanel")
	systems_center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	systems_main_row.add_child(systems_center_panel)

	var center_stack := VBoxContainer.new()
	center_stack.name = "SystemsCenterStack"
	center_stack.add_theme_constant_override("separation", 8)
	_add_margin(systems_center_panel, center_stack, 12)

	systems_category_row = HFlowContainer.new()
	systems_category_row.name = "SystemsCategoryRow"
	systems_category_row.add_theme_constant_override("separation", 6)
	center_stack.add_child(systems_category_row)

	systems_scroll = ScrollContainer.new()
	systems_scroll.name = "SystemsScroll"
	systems_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	systems_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	center_stack.add_child(systems_scroll)

	systems_item_list = VBoxContainer.new()
	systems_item_list.name = "SystemsItemList"
	systems_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	systems_item_list.add_theme_constant_override("separation", 8)
	systems_scroll.add_child(systems_item_list)

	systems_body_label = _new_label(15)
	systems_body_label.name = "SystemsBody"
	systems_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	systems_body_label.visible = false
	center_stack.add_child(systems_body_label)

	systems_action_list = systems_item_list

	systems_detail_panel = _new_panel("SystemsDetailPanel")
	systems_detail_panel.custom_minimum_size = Vector2(232, 0)
	systems_main_row.add_child(systems_detail_panel)

	var detail_stack := VBoxContainer.new()
	detail_stack.add_theme_constant_override("separation", 8)
	_add_margin(systems_detail_panel, detail_stack, 12)

	systems_detail_title_label = _new_label(17)
	systems_detail_title_label.text = "Details"
	detail_stack.add_child(systems_detail_title_label)

	systems_detail_label = _new_label(14)
	systems_detail_label.name = "SystemsDetail"
	systems_detail_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_stack.add_child(systems_detail_label)

	systems_detail_equipment_panel = PanelContainer.new()
	systems_detail_equipment_panel.name = "SystemsDetailEquipmentPanel"
	detail_stack.add_child(systems_detail_equipment_panel)
	systems_detail_equipment_nodes = RpgSystemsCharacterPaneBuilder.build_equipment_only(
		systems_detail_equipment_panel, Callable(self, "_add_margin")
	)
	for slot in (systems_detail_equipment_nodes.get("equipment_slots", {}) as Dictionary).values():
		if slot is RpgEquipmentSlot:
			slot.item_dropped.connect(_on_equipment_slot_item_dropped)

	var spell_slot_nodes := RpgSpellSlotPanelBuilder.build(
		detail_stack, Callable(self, "_new_panel"), Callable(self, "_add_margin"),
		Callable(self, "_apply_button_style"), Callable(self, "_on_spell_slot_dropped")
	)
	systems_spell_slot_panel = spell_slot_nodes["panel"]
	systems_spell_slot_buttons = spell_slot_nodes["buttons"]

	systems_character_panel = _new_panel("SystemsCharacterPanel")
	systems_character_panel.custom_minimum_size = Vector2(210, 0)
	systems_main_row.add_child(systems_character_panel)

	systems_character_nodes = RpgSystemsCharacterPaneBuilder.build(
		systems_character_panel, Callable(self, "_new_label"), Callable(self, "_new_button"),
		Callable(self, "_add_margin"), Callable(self, "_apply_portrait_style")
	)
	for slot in (systems_character_nodes.get("equipment_slots", {}) as Dictionary).values():
		if slot is RpgEquipmentSlot:
			slot.item_dropped.connect(_on_equipment_slot_item_dropped)

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

	_add_nav_button("Q\nQuests", func() -> void: show_systems_panel("quests"))
	_add_nav_button("J\nJournal", func() -> void: show_systems_panel("journal"))
	_add_nav_button("M\nMap", func() -> void: show_systems_panel("map"))
	_add_nav_button("=\nMenu", toggle_systems)

func _add_nav_button(text: String, callback: Callable) -> void:
	var button := _new_button(text, NAV_BUTTON_SIZE)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	top_nav_buttons.add_child(button)

func _build_target_panel() -> void:
	var nodes := RpgTargetPanelBuilder.build(
		root, Callable(self, "_new_panel"), Callable(self, "_add_margin"),
		Callable(self, "_new_label"), Callable(self, "_new_button"),
		Callable(self, "hide_target_picker")
	)
	target_panel = nodes["panel"]
	target_scroll = nodes["scroll"]
	target_list = nodes["list"]

func _build_context_action_panel() -> void:
	var nodes := RpgContextActionPanelBuilder.build(
		root, Callable(self, "_new_panel"), Callable(self, "_add_margin"),
		Callable(self, "_new_label")
	)
	context_action_panel = nodes["panel"]
	context_action_buttons = nodes["buttons"]

func _build_touch_controls() -> void:
	var move_nodes := RpgMovePadBuilder.build(
		root, Callable(self, "_on_move_pad_gui_input"), MOVE_KNOB_SIZE
	)
	move_pad = move_nodes["move_pad"]
	move_knob = move_nodes["move_knob"]
	_update_move_knob()

	var aim_action := func(action_id: String, direction: Vector2) -> void:
		aim_action_released.emit(action_id, direction)
	var action_nodes := RpgActionClusterBuilder.build(root, aim_action)
	action_buttons = action_nodes["cluster"]
	primary_action_button = action_nodes["primary"]
	ability_slot_buttons = action_nodes["ability_buttons"]
	var utility_buttons := action_nodes["utility_buttons"] as Dictionary
	(utility_buttons["inventory"] as Button).pressed.connect(
		func() -> void: show_systems_panel("inventory")
	)
	target_action_button = utility_buttons["target"] as Button
	HoldActionButton.bind(
		target_action_button,
		Callable(self, "_press_target_control"),
		Callable(self, "_hold_target_control")
	)
func _build_content_panel() -> void:
	var nodes := RpgContentPanelBuilder.build(
		root,
		Callable(self, "_new_panel"),
		Callable(self, "_add_margin"),
		Callable(self, "_new_label"),
		Callable(self, "_new_button"),
		Callable(self, "hide_content_card"),
		Callable(self, "_apply_portrait_style"),
		HUD_MARGIN
	)
	content_panel = nodes["panel"]
	content_identity_panel = nodes["identity_panel"]
	content_portrait_panel = nodes["portrait_panel"]
	content_portrait_label = nodes["portrait_label"]
	content_right_stack = nodes["right_stack"]
	content_choice_panel = nodes["choice_panel"]
	content_preview_panel = nodes["preview_panel"]
	content_preview_title_label = nodes["preview_title_label"]
	content_preview_label = nodes["preview_label"]
	content_preview_reward_label = nodes["preview_reward_label"]
	content_close_button = nodes["close_button"]
	content_kind_label = nodes["kind_label"]
	content_title_label = nodes["title_label"]
	content_scroll = nodes["scroll"]
	content_body_label = nodes["body_label"]
	content_choice_list = nodes["choice_list"]

func _set_action_button_layout(compact: bool) -> void:
	RpgActionClusterBuilder.apply_layout(
		action_buttons, primary_action_button, compact, BUTTON_SIZE,
		Callable(self, "_apply_primary_action_style")
	)

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
	_layout_content_panel(viewport_size, compact)
	RpgContextActionPanelBuilder.apply_layout(
		context_action_panel, context_action_buttons, visible_context_action_count,
		viewport_size, compact, HUD_MARGIN
	)
	RpgTargetPanelBuilder.apply_layout(target_panel, target_list, viewport_size, compact, HUD_MARGIN)
	_layout_top_nav(viewport_size, compact)
	_layout_location_banner(viewport_size, compact)
	_layout_message_panel(viewport_size, compact)

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

func _layout_message_panel(viewport_size: Vector2, compact: bool) -> void:
	if not compact or not message_panel or not move_pad or not action_buttons:
		return
	var action_left := viewport_size.x + action_buttons.offset_left
	message_panel.anchor_top = 1.0
	message_panel.anchor_bottom = 1.0
	message_panel.offset_top = -62.0
	message_panel.offset_bottom = -12.0
	message_panel.offset_left = move_pad.offset_right + HUD_MARGIN
	message_panel.offset_right = action_left - HUD_MARGIN
	message_panel.visible = message_panel.offset_right - message_panel.offset_left >= MESSAGE_MIN_WIDTH
func _layout_location_banner(viewport_size: Vector2, compact: bool) -> void:
	if not location_banner_panel:
		return
	var nav_left := viewport_size.x + top_nav_panel.offset_left
	var left_bound := status_panel.offset_right + HUD_MARGIN
	var right_bound := nav_left - HUD_MARGIN
	var available_width := right_bound - left_bound
	location_banner_panel.visible = available_width >= 140.0
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
	top_nav_panel.visible = true
	var button_size := COMPACT_NAV_BUTTON_SIZE if compact else NAV_BUTTON_SIZE
	for child in top_nav_buttons.get_children():
		if child is Button:
			child.custom_minimum_size = button_size
			child.add_theme_font_size_override("font_size", 11 if compact else 14)
	var separation := 4.0 if compact else 6.0
	top_nav_buttons.add_theme_constant_override("separation", int(separation))
	var count := float(top_nav_buttons.get_child_count())
	var width := button_size.x * count + separation * maxf(count - 1.0, 0.0) + 16.0
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
		systems_left_panel.custom_minimum_size = Vector2(92, 0) if compact else Vector2(176, 0)
	if systems_detail_panel:
		systems_detail_panel.visible = true
		systems_detail_panel.custom_minimum_size = Vector2(184, 0) if compact else Vector2(220, 0)
	var char_tab := ["inventory", "character"].has(systems_active_tab)
	# Right pane stays disabled until the systems layout can fit it without clipping.
	var show_character_panel := false
	if systems_spell_slot_panel:
		systems_spell_slot_panel.visible = systems_active_tab == "spells"
	if systems_detail_equipment_panel:
		systems_detail_equipment_panel.visible = char_tab and not show_character_panel
		systems_detail_equipment_panel.custom_minimum_size = Vector2(0, 156 if compact else 176)
		systems_detail_equipment_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if systems_detail_label:
		systems_detail_label.size_flags_vertical = (
			Control.SIZE_SHRINK_BEGIN if systems_detail_equipment_panel.visible
			else Control.SIZE_EXPAND_FILL
		)
	if systems_character_panel:
		systems_character_panel.visible = show_character_panel
		systems_character_panel.custom_minimum_size = Vector2(280 if show_character_panel else 210, 0)
	if systems_resources_label:
		systems_resources_label.custom_minimum_size = Vector2(168, 40) if compact else Vector2(270, 48)
		systems_resources_label.add_theme_font_size_override("font_size", 12 if compact else 17)
	if systems_title_label:
		systems_title_label.add_theme_font_size_override("font_size", 20 if compact else 26)
	if systems_subtitle_label:
		systems_subtitle_label.add_theme_font_size_override("font_size", 11 if compact else 15)
	for button in systems_tab_buttons.values():
		if button is Button:
			button.custom_minimum_size = Vector2(72, 38) if compact else Vector2(150, 54)
			button.add_theme_font_size_override("font_size", 11 if compact else 15)
	if systems_item_list:
		systems_item_list.add_theme_constant_override("separation", 6 if compact else 8)

func _layout_content_panel(viewport_size: Vector2, compact: bool) -> void:
	RpgContentPanelBuilder.apply_layout(
		content_panel, content_identity_panel, content_portrait_panel, content_right_stack,
		content_choice_panel, content_preview_panel, content_title_label, content_kind_label,
		content_body_label, content_preview_title_label, content_preview_reward_label,
		content_choice_list, viewport_size, compact, HUD_MARGIN
	)
	if content_portrait_label:
		content_portrait_label.add_theme_font_size_override("font_size", 12 if compact else 20)

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
	var level := RpgSystemsTextBuilder.level_from_progression(progression_text)
	level_badge_label.text = str(level)
	status_label.text = "\n".join(RpgStatusTextBuilder.lines(
		state, progression_text, applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0
	))
	health_label.text = "Health %d/%d" % [
		int(health_bar.value),
		int(health_bar.max_value)
	]
	_refresh_systems_chrome(state)

func _refresh_target_action_button(state: Dictionary) -> void:
	super._refresh_target_action_button(state)
	if not target_action_button:
		return
	target_action_button.text = "X\nClose" if is_target_picker_visible() else "T\nTarget"
	target_action_button.add_theme_font_size_override(
		"font_size", 12 if applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0 else 15
	)

func _press_target_control() -> void:
	if is_target_picker_visible():
		toggle_target_picker()
	else:
		cycle_target_pressed.emit()

func _hold_target_control() -> void:
	if not is_target_picker_visible():
		toggle_target_picker()

func _refresh_systems_chrome(state: Dictionary) -> void:
	if not systems_title_label:
		return
	systems_title_label.text = _rpg_location_name(state)
	systems_subtitle_label.text = "%s - %s" % [
		RpgSystemsTextBuilder.title(systems_active_tab),
		RpgSystemsTextBuilder.subtitle(systems_active_tab)
	]
	systems_resources_label.text = RpgSystemsTextBuilder.resource_text(state)
	if systems_detail_title_label:
		systems_detail_title_label.text = _systems_detail_title()
	_refresh_systems_rows(state)
	RpgSystemsCharacterPaneBuilder.refresh(
		systems_character_nodes, state, Callable(self, "_apply_row_button_style"),
		applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0
	)
	RpgSystemsCharacterPaneBuilder.refresh(
		systems_detail_equipment_nodes, state, Callable(self, "_apply_row_button_style"),
		applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0
	)
	var spell_value: Variant = state.get("spell_slots", {})
	var spell_slots: Dictionary = spell_value if spell_value is Dictionary else {}
	RpgSpellSlotPanelBuilder.refresh(systems_spell_slot_buttons, spell_slots)
	RpgActionClusterBuilder.refresh_ability_buttons(ability_slot_buttons, spell_slots)
	if systems_spell_slot_panel:
		systems_spell_slot_panel.visible = systems_active_tab == "spells"
	if systems_detail_equipment_panel:
		var char_tab := ["inventory", "character"].has(systems_active_tab)
		var show_character_panel := false
		systems_detail_equipment_panel.visible = char_tab and not show_character_panel
func _refresh_systems_rows(state: Dictionary) -> void:
	if not systems_item_list:
		return
	var rows := RpgSystemsRowBuilder.rows(
		state, systems_active_tab, message_log, systems_active_category
	)
	var compact := applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0
	_refresh_category_row(systems_active_tab)
	if not RpgSystemsRowBuilder.has_id(rows, systems_selected_row_id):
		systems_selected_row_id = String(rows[0].get("id", "")) if not rows.is_empty() else ""
	for index in range(rows.size()):
		var row := rows[index]
		var button := _systems_row_button(index)
		button.name = "SystemsRow_%s" % String(row.get("id", "")).to_pascal_case()
		button.text = RpgSystemsRowBuilder.button_text(row)
		button.clip_text = false; button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y = 82 if compact else 68
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 15)
		var row_id := String(row.get("id", ""))
		var selected := row_id == systems_selected_row_id
		_apply_row_button_style(button, selected)
		button.set_meta("row_id", row_id)
		button.set_meta("action_id", String(row.get("action_id", "")))
		button.set_meta("item_id", String(row.get("item_id", "")))
		button.set_meta("spell_id", String(row.get("spell_id", "")))
		button.set_meta("equipment_slot", String(row.get("equipment_slot", "")))
		button.visible = true
	for index in range(rows.size(), systems_item_list.get_child_count()):
		systems_item_list.get_child(index).visible = false
	if rows.is_empty():
		var empty := _new_label(15)
		empty.name = "SystemsEmptyRow"
		empty.text = "Nothing to show here yet."
		empty.add_theme_color_override("font_color", Color(0.82, 0.74, 0.60))
		systems_item_list.add_child(empty)
		systems_detail_label.text = RpgSystemsTextBuilder.detail_text(state, systems_active_tab)
	else:
		var selected_row := RpgSystemsRowBuilder.selected_row(rows, systems_selected_row_id)
		systems_detail_label.text = String(selected_row.get("detail", ""))

func _systems_row_button(index: int) -> Button:
	if index < systems_item_list.get_child_count():
		var existing := systems_item_list.get_child(index)
		if existing is Button:
			return existing
	var button := RpgInventoryItemButton.new()
	button.custom_minimum_size = Vector2(0, 82 if applied_layout_size.x < 980.0 else 68)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	_apply_button_style(button)
	button.pressed.connect(
		func() -> void:
			var action_id := String(button.get_meta("action_id", ""))
			if not action_id.is_empty():
				inventory_item_selected.emit(action_id)
				return
			_select_systems_row(String(button.get_meta("row_id", "")))
	)
	systems_item_list.add_child(button)
	return button


func _refresh_category_row(tab_id: String) -> void:
	if not systems_category_row:
		return
	var labels := RpgSystemsRowBuilder.category_labels(tab_id)
	var compact := applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0
	var button_size := Vector2(80, 38) if tab_id == "inventory" else Vector2(64, 38)
	for index in range(labels.size()):
		var button: Button
		if index < systems_category_row.get_child_count():
			button = systems_category_row.get_child(index) as Button
		else:
			button = _new_button("", button_size)
			button.focus_mode = Control.FOCUS_NONE
			systems_category_row.add_child(button)
		button.text = String(labels[index])
		button.clip_text = true
		button.visible = true
		var category_id := _category_id_for_label(String(labels[index]))
		button.disabled = false
		button.button_pressed = category_id == systems_active_category
		button.set_meta("category_id", category_id)
		if not bool(button.get_meta("category_bound", false)):
			button.set_meta("category_bound", true)
			button.pressed.connect(
				func() -> void: _select_systems_category(String(button.get_meta("category_id", "")))
			)
		button.add_theme_font_size_override("font_size", 11 if compact else 13)
		button.custom_minimum_size = button_size
	for index in range(labels.size(), systems_category_row.get_child_count()):
		systems_category_row.get_child(index).visible = false

func _select_systems_row(row_id: String) -> void:
	if row_id.is_empty():
		return
	systems_selected_row_id = row_id
	_refresh_systems_chrome(_state_snapshot())

func _select_systems_category(category_id: String) -> void:
	if category_id.is_empty():
		return
	systems_active_category = category_id
	systems_selected_row_id = ""
	_refresh_systems_chrome(_state_snapshot())

func _on_equipment_slot_item_dropped(slot_id: String, item_id: String) -> void:
	if item_id.is_empty() or slot_id.is_empty():
		return
	inventory_item_selected.emit("equip_slot:%s:%s" % [item_id, slot_id])

func _on_spell_slot_dropped(slot_id: String, spell_id: String) -> void:
	if spell_id.is_empty() or slot_id.is_empty():
		return
	inventory_item_selected.emit("assign_spell:%s:%s" % [spell_id, slot_id])

func _category_id_for_label(label: String) -> String:
	return "restoration" if label == "Restore" else label.to_lower()

func _default_category_for_tab(tab_id: String) -> String:
	return {
		"inventory": "all",
		"spells": "all",
		"character": "overview",
		"quests": "active",
		"map": "known",
		"journal": "recent",
		"trade": "stock"
	}.get(tab_id, "all")

func _systems_detail_title() -> String:
	return {
		"inventory": "Item Details",
		"spells": "Spell Details",
		"character": "Character Details",
		"quests": "Quest Details",
		"map": "Location Details",
		"journal": "Journal Details",
		"trade": "Trade Details"
	}.get(systems_active_tab, "Details")

func _refresh_systems_actions(_state: Dictionary) -> void: pass

func _refresh_content_choices(choices: Array) -> void:
	if not content_choice_list:
		return
	content_choice_list.visible = RpgContentChoiceBuilder.refresh(
		content_choice_list,
		choices,
		Callable(self, "_new_button"),
		Callable(self, "_apply_row_button_style"),
		self,
		applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0,
		Callable(self, "hide_content_card"),
		"Leave" if content_kind_label.text == "Dialogue" else "Close"
	)

func _refresh_content_preview(choices: Array, kind: String) -> void:
	if not content_preview_label:
		return
	var compact := applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0
	if content_preview_title_label:
		content_preview_title_label.text = RpgContentChoiceBuilder.preview_title(choices, kind)
	content_preview_label.text = (
		RpgContentChoiceBuilder.preview_compact_text(choices, kind)
		if compact else RpgContentChoiceBuilder.preview_text(choices, kind)
	)
	if content_preview_reward_label:
		content_preview_reward_label.text = (
			RpgContentChoiceBuilder.preview_compact_rewards(choices)
			if compact else RpgContentChoiceBuilder.preview_rewards(choices)
		)
	if content_preview_panel:
		content_preview_panel.visible = not content_preview_label.text.is_empty()

func _refresh_target_picker(state: Dictionary) -> void:
	if not target_list or not target_panel.visible:
		return
	RpgTargetPanelBuilder.refresh(
		target_list, _array_field(state.get("nearby_targets", [])),
		Callable(self, "_new_label"), Callable(self, "_new_button"),
		Callable(self, "_apply_row_button_style"),
		func(entity_id: String) -> void: target_used.emit(entity_id),
		applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0
	)

func _refresh_context_actions(state: Dictionary) -> void:
	if not context_action_buttons:
		return
	if _has_open_overlay_panel():
		visible_context_action_count = 0
		context_action_panel.visible = false
		return
	var context_mode := state.has("context_actions")
	var actions := _array_field(state.get("context_actions" if context_mode else "combat_actions", []))
	visible_context_action_count = RpgContextActionPanelBuilder.refresh(
		context_action_buttons, actions, Callable(self, "_new_button"),
		Callable(self, "_apply_row_button_style"),
		func(action_id: String, is_context: bool) -> void: _emit_quick_action(action_id, is_context),
		RpgContextActionPanelBuilder.title_text(state, context_mode),
		context_mode,
		applied_layout_size.x < 980.0 or applied_layout_size.y < 540.0
	)
	var layout_size := applied_layout_size if applied_layout_size != Vector2.ZERO else root.size
	_set_overlay_panel_layout(layout_size, layout_size.x < 980.0 or layout_size.y < 540.0)
	context_action_panel.visible = visible_context_action_count > 0

func _emit_quick_action(action_id: String, context_mode: bool) -> void:
	if context_mode:
		context_action_selected.emit(action_id)
	else:
		combat_action_selected.emit(action_id)
func _sync_content_overlay_chrome() -> void:
	var content_open := is_content_card_visible()
	var overlay_open := content_open or is_target_picker_visible()
	if move_pad:
		move_pad.visible = not overlay_open
	if action_buttons:
		action_buttons.visible = not content_open
	if message_panel and overlay_open:
		message_panel.visible = false

func _apply_panel_style(panel: Control) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.032, 0.026, 0.88)
	style.border_color = Color(0.78, 0.61, 0.34, 0.70)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)


func _apply_modal_panel_style(panel: Control) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.023, 0.019, 0.96)
	style.border_color = Color(0.86, 0.68, 0.38, 0.82)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
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

func _apply_row_button_style(button: Button, selected: bool) -> void:
	var base := Color(0.045, 0.043, 0.036, 0.92)
	var border := Color(0.72, 0.56, 0.32, 0.68)
	var font := Color(0.96, 0.90, 0.78)
	if selected:
		base = Color(0.10, 0.17, 0.08, 0.96)
		border = Color(0.70, 1.0, 0.46, 0.86)
		font = Color(0.82, 1.0, 0.58)
	button.add_theme_color_override("font_color", font)
	button.add_theme_stylebox_override("normal", _button_style_with_border(base, border))
	button.add_theme_stylebox_override(
		"hover", _button_style_with_border(Color(0.12, 0.16, 0.10, 0.98), border)
	)
	button.add_theme_stylebox_override(
		"pressed", _button_style_with_border(Color(0.15, 0.20, 0.11, 0.98), border)
	)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _apply_primary_action_style(button: Button) -> void:
	var border := Color(0.92, 0.76, 0.42, 0.92)
	button.add_theme_color_override("font_color", Color(1.0, 0.92, 0.74))
	button.add_theme_stylebox_override(
		"normal", _button_style_with_border(Color(0.08, 0.075, 0.055, 0.98), border)
	)
	button.add_theme_stylebox_override(
		"hover", _button_style_with_border(Color(0.13, 0.12, 0.075, 0.98), border)
	)
	button.add_theme_stylebox_override(
		"pressed", _button_style_with_border(Color(0.19, 0.17, 0.09, 0.98), border)
	)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

func _button_style(color: Color) -> StyleBoxFlat:
	return _button_style_with_border(color, Color(0.72, 0.56, 0.32, 0.68))

func _button_style_with_border(color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border_color
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style

func _apply_portrait_style(panel: Panel) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.11, 0.095, 0.075, 0.96)
	style.border_color = Color(0.86, 0.70, 0.42, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(38)
	panel.add_theme_stylebox_override("panel", style)


func _apply_badge_style(label: Label) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.048, 0.038, 0.98)
	style.border_color = Color(0.86, 0.70, 0.42, 0.90)
	style.set_border_width_all(2)
	style.set_corner_radius_all(13)
	label.add_theme_stylebox_override("normal", style)
	label.add_theme_color_override("font_color", Color(0.96, 0.90, 0.78))


func _set_margin_constants(margin: MarginContainer, value: int) -> void:
	margin.add_theme_constant_override("margin_left", value)
	margin.add_theme_constant_override("margin_top", value)
	margin.add_theme_constant_override("margin_right", value)
	margin.add_theme_constant_override("margin_bottom", value)
