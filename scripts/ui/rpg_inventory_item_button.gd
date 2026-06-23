class_name RpgInventoryItemButton
extends Button


func set_card_data(row: Dictionary) -> void:
	set_meta("card_icon", _card_icon(row))
	set_meta("card_title", String(row.get("title", "")))
	set_meta("card_meta", String(row.get("meta", "")))
	set_meta("card_detail", String(row.get("subtitle", "")))
	add_theme_color_override("font_color", Color.TRANSPARENT)
	add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	add_theme_color_override("font_focus_color", Color.TRANSPARENT)
	queue_redraw()


func _draw() -> void:
	var title := String(get_meta("card_title", ""))
	if title.is_empty():
		return
	var icon := String(get_meta("card_icon", "I"))
	var meta := String(get_meta("card_meta", ""))
	var detail := String(get_meta("card_detail", ""))
	var selected := bool(get_meta("card_selected", false))
	var font := get_theme_default_font()
	var title_size := 15 if size.y < 76.0 else 17
	var meta_size := 11 if size.y < 76.0 else 13
	var icon_rect := Rect2(Vector2(10, 10), Vector2(42, maxf(40.0, size.y - 20.0)))
	var icon_color := Color(0.77, 1.0, 0.52, 0.95) if selected else Color(0.94, 0.78, 0.46, 0.92)
	draw_rect(icon_rect, Color(0.03, 0.027, 0.021, 0.55), true)
	draw_rect(icon_rect, icon_color, false, 1.3)
	draw_string(
		font, icon_rect.position + Vector2(0, icon_rect.size.y * 0.60), icon,
		HORIZONTAL_ALIGNMENT_CENTER, icon_rect.size.x, title_size, icon_color
	)
	var text_x := icon_rect.end.x + 12.0
	var text_width := maxf(0.0, size.x - text_x - 12.0)
	draw_string(font, Vector2(text_x, 28), title, HORIZONTAL_ALIGNMENT_LEFT, text_width, title_size,
		Color(0.86, 1.0, 0.58, 0.98) if selected else Color(0.98, 0.92, 0.78, 0.98))
	if not meta.is_empty():
		draw_string(font, Vector2(text_x, 48), meta, HORIZONTAL_ALIGNMENT_LEFT, text_width, meta_size,
			Color(0.82, 0.70, 0.50, 0.95))
	if not detail.is_empty():
		draw_string(font, Vector2(text_x, size.y - 12), detail, HORIZONTAL_ALIGNMENT_LEFT, text_width,
			meta_size, Color(0.92, 0.86, 0.72, 0.94))


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


func _card_icon(row: Dictionary) -> String:
	var text := "%s %s %s %s" % [
		String(row.get("meta", "")),
		String(row.get("equipment_slot", "")),
		String(row.get("title", "")),
		String(row.get("subtitle", ""))
	]
	var lower := text.to_lower()
	var icon := "I"
	if lower.contains("weapon"):
		icon = "W"
	elif lower.contains("armour") or lower.contains("armor") or lower.contains("shield"):
		icon = "A"
	elif lower.contains("ingredient"):
		icon = "G"
	elif lower.contains("quest"):
		icon = "Q"
	elif lower.contains("spell") or lower.contains("cost") or lower.contains("school"):
		icon = "S"
	elif lower.contains("map") or lower.contains("route") or lower.contains("known"):
		icon = "M"
	elif lower.contains("journal") or lower.contains("log") or lower.contains("time"):
		icon = "J"
	elif (
		lower.contains("trade") or lower.contains("merchant") or lower.contains("shop")
		or lower.contains("buy ") or lower.contains("sell")
	):
		icon = "T"
	elif lower.contains("vitals") or lower.contains("health"):
		icon = "H"
	return icon
