extends GutTest

const RpgSpellSlot = preload("res://scripts/ui/controls/slots/rpg_spell_slot.gd")
const RpgSpellSlotPanelBuilder = preload(
	"res://scripts/ui/systems/panes/rpg_spell_slot_panel_builder.gd"
)


func test_build_returns_empty_without_context_or_parent() -> void:
	assert_true(RpgSpellSlotPanelBuilder.build(null).is_empty())
	var context := RpgSpellSlotPanelBuilder.BuildContext.new()

	assert_true(RpgSpellSlotPanelBuilder.build(context).is_empty())


func test_build_creates_panel_title_and_three_drop_slots() -> void:
	var parent := VBoxContainer.new()
	add_child_autofree(parent)
	var styled_slots: Array[String] = []
	var drops: Array[String] = []

	var nodes := RpgSpellSlotPanelBuilder.build(_build_context(
		parent,
		func(slot: Button) -> void: styled_slots.append(slot.name),
		func(slot_id: String, spell_id: String) -> void:
			drops.append("%s:%s" % [slot_id, spell_id])
	))

	assert_eq((nodes["panel"] as PanelContainer).name, "SystemsSpellSlotsPanel")
	assert_eq(parent.get_child_count(), 1)
	assert_eq((parent.find_child("SystemsSpellSlotTitle", true, false) as Label).text,
		"Ability Slots"
	)
	var buttons: Dictionary = nodes["buttons"]
	assert_eq(buttons.keys(), ["ability_1", "ability_2", "ability_3"])
	assert_eq(styled_slots, ["", "", ""])
	for slot_id in buttons:
		var slot := buttons[slot_id] as RpgSpellSlot
		assert_eq(slot.slot_id, slot_id)
		assert_eq(slot.custom_minimum_size, Vector2(0, 50))
		assert_eq(slot.focus_mode, Control.FOCUS_NONE)
		assert_eq(slot.mouse_filter, Control.MOUSE_FILTER_STOP)

	(buttons["ability_2"] as RpgSpellSlot)._drop_data(
		Vector2.ZERO,
		{"type": "spell", "spell_id": "spell_mend"}
	)

	assert_eq(drops, ["ability_2:spell_mend"])


func test_refresh_updates_empty_and_assigned_slot_labels() -> void:
	var buttons := {
		"ability_1": _slot_button(),
		"ability_2": _slot_button(),
		"ability_3": _slot_button()
	}
	var request := RpgSpellSlotPanelBuilder.RefreshRequest.new()
	request.buttons = buttons
	request.slots = {
		"ability_1": {"slot_label": "Ability I", "name": "Ember"},
		"ability_2": {"slot_label": "Ability II", "name": ""},
	}

	RpgSpellSlotPanelBuilder.refresh(request)

	assert_eq((buttons["ability_1"] as Button).text, "Ability I\nEmber")
	assert_eq((buttons["ability_2"] as Button).text, "Ability II\nEmpty")
	assert_eq((buttons["ability_3"] as Button).text, "ability_3\nEmpty")


func test_refresh_ignores_missing_request() -> void:
	RpgSpellSlotPanelBuilder.refresh(null)

	assert_true(true)


func _build_context(
	parent: BoxContainer, button_style: Callable, drop_callback: Callable
) -> RpgSpellSlotPanelBuilder.BuildContext:
	var context := RpgSpellSlotPanelBuilder.BuildContext.new()
	context.parent = parent
	context.new_panel = func(panel_name: String) -> PanelContainer:
		var panel := PanelContainer.new()
		panel.name = panel_name
		return panel
	context.add_margin = func(panel: PanelContainer, child: Control, _margin: int) -> void:
		panel.add_child(child)
	context.button_style = button_style
	context.drop_callback = drop_callback
	return context


func _slot_button() -> Button:
	var button := Button.new()
	add_child_autofree(button)
	return button
