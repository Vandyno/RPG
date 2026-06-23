class_name RpgInventoryItemButton
extends Button


func _get_drag_data(_at_position: Vector2) -> Variant:
	var spell_id := String(get_meta("spell_id", ""))
	if not spell_id.is_empty():
		var spell_preview := Label.new()
		spell_preview.text = _preview_text()
		spell_preview.add_theme_font_size_override("font_size", 14)
		_apply_drag_preview(spell_preview)
		return {"type": "spell", "spell_id": spell_id}
	var item_id := String(get_meta("item_id", ""))
	var equipment_slot := String(get_meta("equipment_slot", ""))
	if item_id.is_empty() or equipment_slot.is_empty():
		return null
	var preview := Label.new()
	preview.text = _preview_text()
	preview.add_theme_font_size_override("font_size", 14)
	_apply_drag_preview(preview)
	return {
		"type": "inventory_item",
		"item_id": item_id,
		"equipment_slot": equipment_slot
	}


func _preview_text() -> String:
	var lines := text.split("\n", false)
	return lines[0] if not lines.is_empty() else String(get_meta("item_id", "Item"))


func _apply_drag_preview(preview: Control) -> void:
	if get_viewport().gui_is_dragging():
		set_drag_preview(preview)
	else:
		preview.free()
