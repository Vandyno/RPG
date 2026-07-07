class_name RpgSpellSlotPanelBuilder
extends RefCounted

const RpgSpellSlot = preload("res://scripts/ui/controls/slots/rpg_spell_slot.gd")
const SpellSlots = preload("res://scripts/core/spell_slots.gd")


class BuildContext:
	var parent: BoxContainer
	var new_panel: Callable
	var add_margin: Callable
	var button_style: Callable
	var drop_callback: Callable


class RefreshRequest:
	var buttons: Dictionary
	var slots: Dictionary


static func build(context: BuildContext) -> Dictionary:
	if not context or not context.parent:
		return {}
	var panel: PanelContainer = context.new_panel.call("SystemsSpellSlotsPanel")
	context.parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 7)
	context.add_margin.call(panel, stack, 8)
	var title := Label.new()
	title.name = "SystemsSpellSlotTitle"
	title.text = "Ability Slots"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.56))
	stack.add_child(title)
	var buttons := {}
	for slot_id in SpellSlots.SLOTS:
		var slot := RpgSpellSlot.new()
		slot.setup_slot(slot_id)
		slot.custom_minimum_size = Vector2(0, 50)
		slot.focus_mode = Control.FOCUS_NONE
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.spell_dropped.connect(context.drop_callback)
		context.button_style.call(slot)
		slot.add_theme_font_size_override("font_size", 12)
		stack.add_child(slot)
		buttons[slot_id] = slot
	return {"panel": panel, "buttons": buttons}


static func refresh(request: RefreshRequest) -> void:
	if not request:
		return
	for slot_id in request.buttons:
		var slot := request.buttons[slot_id] as Button
		var slot_data := request.slots.get(slot_id, {}) as Dictionary
		var label := String(slot_data.get("slot_label", slot_id))
		var name := String(slot_data.get("name", ""))
		slot.text = "%s\nEmpty" % label if name.is_empty() else "%s\n%s" % [label, name]
