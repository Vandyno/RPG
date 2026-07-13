extends GutTest

const RpgIconButton = preload("res://scripts/ui/controls/buttons/rpg_icon_button.gd")
const RpgSystemsPanelPresenter = preload(
	"res://scripts/ui/systems/panes/rpg_systems_panel_presenter.gd"
)


func test_apply_layout_ignores_missing_panel_or_frame() -> void:
	RpgSystemsPanelPresenter.apply_layout(null)
	var request := RpgSystemsPanelPresenter.LayoutRequest.new()
	request.panel = PanelContainer.new()
	add_child_autofree(request.panel)

	RpgSystemsPanelPresenter.apply_layout(request)

	assert_true(true)


func test_apply_layout_sets_desktop_inventory_panel_sizes_and_text() -> void:
	var request := _layout_request(false, "inventory")
	var margins: Array[int] = []
	request.set_margin_constants = func(_frame: MarginContainer, margin: int) -> void:
		margins.append(margin)

	RpgSystemsPanelPresenter.apply_layout(request)

	assert_eq(request.panel.anchor_right, 1.0)
	assert_eq(request.panel.anchor_bottom, 1.0)
	assert_eq(request.panel.offset_left, 12.0)
	assert_eq(request.panel.offset_right, -12.0)
	assert_eq(margins, [16])
	assert_eq(request.main_row.get_theme_constant("separation"), 10)
	assert_eq(request.left_panel.custom_minimum_size, Vector2(176, 0))
	assert_eq(request.detail_panel.custom_minimum_size, Vector2(220, 0))
	assert_true(request.detail_panel.visible)
	assert_true(request.character_panel.visible)
	assert_false(request.detail_equipment_panel.visible)
	assert_false(request.spell_slot_panel.visible)
	assert_eq(request.resources_label.custom_minimum_size, Vector2(270, 48))
	assert_eq(request.resources_label.get_theme_font_size("font_size"), 17)
	assert_eq(request.title_label.get_theme_font_size("font_size"), 26)
	assert_eq(request.subtitle_label.get_theme_font_size("font_size"), 15)
	assert_eq((request.tab_buttons["inventory"] as Button).custom_minimum_size, Vector2(150, 54))
	assert_eq(request.item_list.get_theme_constant("separation"), 8)


func test_apply_layout_sets_compact_character_detail_equipment_mode() -> void:
	var request := _layout_request(true, "character")
	var margins: Array[int] = []
	request.set_margin_constants = func(_frame: MarginContainer, margin: int) -> void:
		margins.append(margin)

	RpgSystemsPanelPresenter.apply_layout(request)

	assert_eq(margins, [8])
	assert_eq(request.left_panel.custom_minimum_size, Vector2(112, 0))
	assert_eq(request.detail_panel.custom_minimum_size, Vector2(184, 0))
	assert_false(request.character_panel.visible)
	assert_true(request.detail_equipment_panel.visible)
	assert_eq(request.detail_equipment_panel.custom_minimum_size, Vector2(0, 156))
	assert_eq(request.detail_equipment_panel.size_flags_vertical, Control.SIZE_EXPAND_FILL)
	assert_eq(request.detail_label.size_flags_vertical, Control.SIZE_SHRINK_BEGIN)
	assert_eq(request.resources_label.custom_minimum_size, Vector2(168, 40))
	assert_eq(request.title_label.get_theme_font_size("font_size"), 20)
	assert_eq((request.tab_buttons["inventory"] as Button).custom_minimum_size, Vector2(92, 38))
	assert_eq(request.item_list.get_theme_constant("separation"), 6)


func test_apply_layout_shows_spell_slots_only_on_spells_tab() -> void:
	var request := _layout_request(false, "spells")

	RpgSystemsPanelPresenter.apply_layout(request)

	assert_true(request.spell_slot_panel.visible)
	assert_false(request.character_panel.visible)
	assert_false(request.detail_equipment_panel.visible)
	assert_eq(request.detail_label.size_flags_vertical, Control.SIZE_EXPAND_FILL)


func test_refresh_tabs_marks_active_button_and_preserves_icon_buttons() -> void:
	var inventory := Button.new()
	var spells := RpgIconButton.new()
	inventory.toggle_mode = true
	spells.toggle_mode = true
	add_child_autofree(inventory)
	add_child_autofree(spells)
	var buttons := {"inventory": inventory, "spells": spells}

	RpgSystemsPanelPresenter.refresh_tabs(buttons, "spells")

	assert_false(inventory.button_pressed)
	assert_false(bool(inventory.get_meta("nav_selected", true)))
	assert_true(spells.button_pressed)
	assert_true(bool(spells.get_meta("nav_selected", false)))
	assert_eq(inventory.get_theme_font_size("font_size"), 15)
	assert_eq(spells.get_theme_font_size("font_size"), 15)


func test_tab_defaults_detail_titles_and_character_tab_detection() -> void:
	assert_eq(RpgSystemsPanelPresenter.default_category_for_tab("inventory"), "all")
	assert_eq(RpgSystemsPanelPresenter.default_category_for_tab("character"), "overview")
	assert_eq(RpgSystemsPanelPresenter.default_category_for_tab("quests"), "active")
	assert_eq(RpgSystemsPanelPresenter.default_category_for_tab("journal"), "recent")
	assert_eq(RpgSystemsPanelPresenter.default_category_for_tab("trade"), "stock")
	assert_eq(RpgSystemsPanelPresenter.default_category_for_tab("unknown"), "all")
	assert_eq(RpgSystemsPanelPresenter.detail_title("spells"), "Spell Details")
	assert_eq(RpgSystemsPanelPresenter.detail_title("unknown"), "Details")
	assert_true(RpgSystemsPanelPresenter.is_character_tab("inventory"))
	assert_true(RpgSystemsPanelPresenter.is_character_tab("character"))
	assert_false(RpgSystemsPanelPresenter.is_character_tab("spells"))


func _layout_request(compact: bool, active_tab: String) -> RpgSystemsPanelPresenter.LayoutRequest:
	var request := RpgSystemsPanelPresenter.LayoutRequest.new()
	var root := Node.new()
	add_child_autofree(root)
	request.panel = PanelContainer.new()
	request.frame = MarginContainer.new()
	request.main_row = HBoxContainer.new()
	request.left_panel = PanelContainer.new()
	request.detail_panel = PanelContainer.new()
	request.character_panel = PanelContainer.new()
	request.detail_equipment_panel = PanelContainer.new()
	request.detail_label = Label.new()
	request.spell_slot_panel = PanelContainer.new()
	request.resources_label = Label.new()
	request.title_label = Label.new()
	request.subtitle_label = Label.new()
	request.item_list = VBoxContainer.new()
	request.tab_buttons = {"inventory": Button.new()}
	for node in [
		request.panel,
		request.frame,
		request.main_row,
		request.left_panel,
		request.detail_panel,
		request.character_panel,
		request.detail_equipment_panel,
		request.detail_label,
		request.spell_slot_panel,
		request.resources_label,
		request.title_label,
		request.subtitle_label,
		request.item_list,
		request.tab_buttons["inventory"]
	]:
		root.add_child(node)
	request.active_tab = active_tab
	request.compact = compact
	request.hud_margin = 12.0
	request.set_margin_constants = func(_frame: MarginContainer, _margin: int) -> void: pass
	return request
