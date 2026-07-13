extends GutTest

const RpgEquipmentSlot = preload("res://scripts/ui/controls/slots/rpg_equipment_slot.gd")
const RpgSystemsCharacterPaneBuilder = preload(
	"res://scripts/ui/systems/panes/rpg_systems_character_pane_builder.gd"
)


func test_build_returns_empty_without_context_or_panel() -> void:
	assert_true(RpgSystemsCharacterPaneBuilder.build(null).is_empty())
	var context := RpgSystemsCharacterPaneBuilder.BuildContext.new()
	assert_true(RpgSystemsCharacterPaneBuilder.build(context).is_empty())


func test_build_creates_character_scroll_header_health_equipment_and_rows() -> void:
	var panel := PanelContainer.new()
	add_child_autofree(panel)
	var styled_portraits: Array[String] = []

	var nodes := RpgSystemsCharacterPaneBuilder.build(
		_build_context(panel, func(portrait: Control) -> void: styled_portraits.append(portrait.name))
	)

	assert_eq((nodes["scroll"] as ScrollContainer).name, "SystemsCharacterScroll")
	assert_eq((nodes["subtitle"] as Label).name, "SystemsCharacterSubtitle")
	assert_eq((nodes["health_bar"] as ProgressBar).name, "SystemsCharacterHealthBar")
	assert_eq((nodes["equipment_grid"] as GridContainer).name, "SystemsEquipmentSlots")
	assert_eq((nodes["rows"] as VBoxContainer).name, "SystemsCharacterRows")
	assert_eq((nodes["hidden_label"] as Label).name, "SystemsCharacter")
	assert_eq(styled_portraits, ["SystemsCharacterPortrait"])
	assert_true((nodes["equipment_slots"] as Dictionary).has("right_hand"))
	assert_true((nodes["equipment_slots"] as Dictionary)["right_hand"] is RpgEquipmentSlot)
	assert_not_null(panel.find_child("SystemsCharacterPortraitSilhouette", true, false))


func test_build_equipment_only_creates_detail_grid_and_marks_detail_only() -> void:
	var panel := PanelContainer.new()
	add_child_autofree(panel)
	var context := RpgSystemsCharacterPaneBuilder.EquipmentOnlyContext.new()
	context.panel = panel
	context.add_margin = _add_margin

	var nodes := RpgSystemsCharacterPaneBuilder.build_equipment_only(context)

	assert_same(nodes["panel"], panel)
	assert_true(bool(nodes["detail_only"]))
	assert_eq((nodes["equipment_scroll"] as ScrollContainer).name, "SystemsDetailEquipmentScroll")
	assert_eq((nodes["equipment_grid"] as GridContainer).name, "SystemsDetailEquipmentSlots")
	assert_true((nodes["equipment_slots"] as Dictionary).has("chest"))


func test_slot_label_size_and_health_helpers_cover_compact_and_detail_modes() -> void:
	assert_eq(
		RpgSystemsCharacterPaneBuilder._slot_display_label("right_hand", "Right Hand", true),
		"R Hand"
	)
	assert_eq(RpgSystemsCharacterPaneBuilder._slot_display_label("necklace", "Necklace", true), "Neck")
	assert_eq(RpgSystemsCharacterPaneBuilder._slot_display_label("boots", "Boots", false), "Boots")
	assert_eq(RpgSystemsCharacterPaneBuilder._equipment_slot_size(true, false), Vector2(72, 52))
	assert_eq(RpgSystemsCharacterPaneBuilder._equipment_slot_size(false, true), Vector2(0, 38))
	assert_eq(RpgSystemsCharacterPaneBuilder._equipment_slot_size(false, false), Vector2(0, 44))
	assert_eq(RpgSystemsCharacterPaneBuilder._health_values("Health 76/100"), Vector2(76, 100))
	assert_eq(RpgSystemsCharacterPaneBuilder._health_values("bad"), Vector2(0, 1))


func test_refresh_updates_subtitle_health_equipment_slots_and_character_rows() -> void:
	var panel := PanelContainer.new()
	add_child_autofree(panel)
	var nodes := RpgSystemsCharacterPaneBuilder.build(_build_context(panel, func(_p) -> void: pass))
	var styled: Array[String] = []
	var request := RpgSystemsCharacterPaneBuilder.RefreshRequest.new()
	request.nodes = nodes
	request.state = {
		"progression": "Level 3",
		"player_health": "Health 76/100",
		"equipment_slots":
		{
			"right_hand": {"label": "Right Hand", "item_name": "Road Hatchet"},
			"left_hand": {"label": "Left Hand", "item_name": ""},
		},
		"equipment": "Weapon: Road Hatchet\nOffhand: empty\nBody: empty",
		"statuses": "none",
	}
	request.row_style = func(button: Button, active: bool) -> void:
		styled.append("%s:%s" % [button.name, active])
	request.compact = true

	RpgSystemsCharacterPaneBuilder.refresh(request)

	assert_eq((nodes["subtitle"] as Label).text, "Level 3")
	assert_eq((nodes["health_bar"] as ProgressBar).value, 76.0)
	assert_eq((nodes["health_bar"] as ProgressBar).max_value, 100.0)
	assert_eq((nodes["equipment_grid"] as GridContainer).columns, 2)
	var slots: Dictionary = nodes["equipment_slots"]
	assert_eq((slots["right_hand"] as Button).text, "R Hand\nRoad Hatchet")
	assert_eq((slots["left_hand"] as Button).text, "L Hand\nEmpty")
	assert_true(styled.has("EquipmentSlot_RightHand:true"))
	assert_true((nodes["rows"] as VBoxContainer).get_child_count() > 0)


func test_refresh_ignores_missing_request_and_missing_rows() -> void:
	RpgSystemsCharacterPaneBuilder.refresh(null)
	var request := RpgSystemsCharacterPaneBuilder.RefreshRequest.new()
	request.nodes = {}
	request.state = {}
	request.row_style = func(_button: Button, _active: bool) -> void: pass

	RpgSystemsCharacterPaneBuilder.refresh(request)

	assert_true(true)


func _build_context(
	panel: PanelContainer, portrait_style: Callable
) -> RpgSystemsCharacterPaneBuilder.BuildContext:
	var context := RpgSystemsCharacterPaneBuilder.BuildContext.new()
	context.panel = panel
	context.new_label = _new_label
	context.new_button = _new_button
	context.add_margin = _add_margin
	context.portrait_style = portrait_style
	return context


func _new_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _new_button(text: String, size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = size
	return button


func _add_margin(panel: PanelContainer, child: Control, _margin: int) -> void:
	panel.add_child(child)
