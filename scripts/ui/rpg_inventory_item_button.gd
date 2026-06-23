class_name RpgInventoryItemButton
extends Button


func _get_drag_data(_at_position: Vector2) -> Variant:
	var item_id := String(get_meta("item_id", ""))
	var equipment_slot := String(get_meta("equipment_slot", ""))
	if item_id.is_empty() or equipment_slot.is_empty():
		return null
	var preview := Label.new()
	preview.text = _preview_text()
	preview.add_theme_font_size_override("font_size", 14)
	set_drag_preview(preview)
	return {
		"type": "inventory_item",
		"item_id": item_id,
		"equipment_slot": equipment_slot
	}


func _preview_text() -> String:
	var lines := text.split("\n", false)
	return lines[0] if not lines.is_empty() else String(get_meta("item_id", "Item"))
