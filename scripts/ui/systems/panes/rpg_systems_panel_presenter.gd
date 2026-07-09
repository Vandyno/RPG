class_name RpgSystemsPanelPresenter
extends RefCounted

const RpgIconButton = preload("res://scripts/ui/controls/buttons/rpg_icon_button.gd")


class LayoutRequest:
	extends RefCounted

	var panel: PanelContainer
	var frame: MarginContainer
	var main_row: HBoxContainer
	var left_panel: PanelContainer
	var detail_panel: PanelContainer
	var character_panel: PanelContainer
	var detail_equipment_panel: PanelContainer
	var detail_label: Label
	var spell_slot_panel: PanelContainer
	var resources_label: Label
	var title_label: Label
	var subtitle_label: Label
	var item_list: VBoxContainer
	var tab_buttons: Dictionary = {}
	var active_tab := "inventory"
	var compact := false
	var hud_margin := 12.0
	var set_margin_constants: Callable


static func apply_layout(request: LayoutRequest) -> void:
	if not request or not request.panel or not request.frame:
		return
	request.panel.anchor_left = 0.0
	request.panel.anchor_right = 1.0
	request.panel.anchor_top = 0.0
	request.panel.anchor_bottom = 1.0
	request.panel.offset_left = request.hud_margin
	request.panel.offset_top = request.hud_margin
	request.panel.offset_right = -request.hud_margin
	request.panel.offset_bottom = -request.hud_margin
	request.set_margin_constants.call(request.frame, 8 if request.compact else 16)

	if request.main_row:
		request.main_row.add_theme_constant_override("separation", 6 if request.compact else 10)
	if request.left_panel:
		request.left_panel.custom_minimum_size = (
			Vector2(112, 0) if request.compact else Vector2(176, 0)
		)
	if request.detail_panel:
		request.detail_panel.visible = true
		request.detail_panel.custom_minimum_size = (
			Vector2(184, 0) if request.compact else Vector2(220, 0)
		)
	var char_tab := is_character_tab(request.active_tab)
	var show_character_panel := char_tab and not request.compact
	if request.spell_slot_panel:
		request.spell_slot_panel.visible = request.active_tab == "spells"
	if request.detail_equipment_panel:
		request.detail_equipment_panel.visible = char_tab and not show_character_panel
		request.detail_equipment_panel.custom_minimum_size = (
			Vector2(0, 156) if request.compact else Vector2(0, 176)
		)
		request.detail_equipment_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if request.detail_label:
		request.detail_label.size_flags_vertical = (
			Control.SIZE_SHRINK_BEGIN
			if request.detail_equipment_panel and request.detail_equipment_panel.visible
			else Control.SIZE_EXPAND_FILL
		)
	if request.character_panel:
		request.character_panel.visible = show_character_panel
		request.character_panel.custom_minimum_size = Vector2(210, 0)
	if request.resources_label:
		request.resources_label.custom_minimum_size = (
			Vector2(168, 40) if request.compact else Vector2(270, 48)
		)
		request.resources_label.add_theme_font_size_override(
			"font_size", 12 if request.compact else 17
		)
	if request.title_label:
		request.title_label.add_theme_font_size_override("font_size", 20 if request.compact else 26)
	if request.subtitle_label:
		request.subtitle_label.add_theme_font_size_override(
			"font_size", 11 if request.compact else 15
		)
	for button in request.tab_buttons.values():
		if button is Button:
			button.custom_minimum_size = Vector2(92, 38) if request.compact else Vector2(150, 54)
			button.add_theme_font_size_override("font_size", 11 if request.compact else 15)
		if button is RpgIconButton:
			(button as RpgIconButton).set_compact(request.compact)
	if request.item_list:
		request.item_list.add_theme_constant_override("separation", 6 if request.compact else 8)


static func refresh_tabs(tab_buttons: Dictionary, active_tab: String) -> void:
	for tab_id in tab_buttons:
		var button: Button = tab_buttons[tab_id]
		var active := String(tab_id) == active_tab
		button.button_pressed = active
		button.add_theme_font_size_override("font_size", 15)
		button.set_meta("nav_selected", active)
		if button is RpgIconButton:
			(button as RpgIconButton).setup_icon(String(tab_id), "left")
			continue
		button.add_theme_color_override(
			"font_color", Color(0.78, 1.0, 0.56) if active else Color(0.96, 0.90, 0.78)
		)
		button.queue_redraw()


static func default_category_for_tab(tab_id: String) -> String:
	return (
		{
			"inventory": "all",
			"spells": "all",
			"character": "overview",
			"quests": "active",
			"journal": "recent",
			"trade": "stock"
		}
		. get(tab_id, "all")
	)


static func detail_title(active_tab: String) -> String:
	return (
		{
			"inventory": "Item Details",
			"spells": "Spell Details",
			"character": "Character Details",
			"quests": "Quest Details",
			"journal": "Journal Details",
			"trade": "Trade Details"
		}
		. get(active_tab, "Details")
	)


static func is_character_tab(tab_id: String) -> bool:
	return ["inventory", "character"].has(tab_id)
