class_name RpgSpellSlotPanelBuilder
extends RefCounted

const RpgSpellSlot = preload("res://scripts/ui/rpg_spell_slot.gd")
const SLOT_IDS := ["ability_1", "ability_2", "ability_3"]


static func build(
	parent: BoxContainer,
	new_panel: Callable,
	add_margin: Callable,
	button_style: Callable,
	drop_callback: Callable
) -> Dictionary:
	var panel: PanelContainer = new_panel.call("SystemsSpellSlotsPanel")
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	add_margin.call(panel, stack, 8)
	var buttons := {}
	for slot_id in SLOT_IDS:
		var slot := RpgSpellSlot.new()
		slot.setup_slot(slot_id)
		slot.custom_minimum_size = Vector2(0, 44)
		slot.focus_mode = Control.FOCUS_NONE
		slot.spell_dropped.connect(drop_callback)
		button_style.call(slot)
		stack.add_child(slot)
		buttons[slot_id] = slot
	return {"panel": panel, "buttons": buttons}


static func refresh(buttons: Dictionary, slots: Dictionary) -> void:
	for slot_id in buttons:
		var slot := buttons[slot_id] as Button
		var slot_data := slots.get(slot_id, {}) as Dictionary
		var label := String(slot_data.get("slot_label", slot_id))
		var name := String(slot_data.get("name", ""))
		slot.text = "%s\nEmpty" % label if name.is_empty() else "%s\n%s" % [label, name]
