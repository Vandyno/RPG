class_name RpgInventoryItemButton
extends Button

const RpgIconDrawer = preload("res://scripts/ui/controls/display/rpg_icon_drawer.gd")

const DRAG_THRESHOLD := 6.0

var drag_start := Vector2.ZERO
var drag_pointer_down := false


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
	_draw_badge_icon(icon_rect, icon, icon_color)
	var text_x := icon_rect.end.x + 12.0
	var right_pad := 12.0
	var meta_width := 0.0
	if not meta.is_empty():
		meta_width = clampf(size.x * 0.18, 34.0, 72.0)
	var title_width := maxf(0.0, size.x - text_x - right_pad - meta_width - 8.0)
	var detail_width := maxf(0.0, size.x - text_x - right_pad)
	draw_string(
		font,
		Vector2(text_x, 28),
		title,
		HORIZONTAL_ALIGNMENT_LEFT,
		title_width,
		title_size,
		Color(0.86, 1.0, 0.58, 0.98) if selected else Color(0.98, 0.92, 0.78, 0.98)
	)
	if not meta.is_empty():
		draw_string(
			font,
			Vector2(size.x - right_pad - meta_width, 28),
			meta,
			HORIZONTAL_ALIGNMENT_RIGHT,
			meta_width,
			meta_size,
			Color(0.82, 0.70, 0.50, 0.95)
		)
	if not detail.is_empty():
		draw_string(
			font,
			Vector2(text_x, size.y - 12),
			detail,
			HORIZONTAL_ALIGNMENT_LEFT,
			detail_width,
			meta_size,
			Color(0.92, 0.86, 0.72, 0.94)
		)


func _get_drag_data(_at_position: Vector2) -> Variant:
	var payload := _drag_payload()
	if payload.is_empty():
		return null
	var preview := _drag_preview()
	_apply_drag_preview(preview)
	return payload


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		drag_pointer_down = event.pressed
		drag_start = event.position
	elif event is InputEventMouseMotion and drag_pointer_down:
		_try_force_drag(event.position)
	elif event is InputEventScreenTouch:
		drag_pointer_down = event.pressed
		drag_start = event.position
	elif event is InputEventScreenDrag and drag_pointer_down:
		_try_force_drag(event.position)


func _try_force_drag(position: Vector2) -> void:
	if position.distance_to(drag_start) < DRAG_THRESHOLD:
		return
	var payload := _drag_payload()
	if payload.is_empty():
		return
	drag_pointer_down = false
	force_drag(payload, _drag_preview())


func _drag_payload() -> Dictionary:
	var spell_id := String(get_meta("spell_id", ""))
	if not spell_id.is_empty():
		return {"type": "spell", "spell_id": spell_id}
	var item_id := String(get_meta("item_id", ""))
	var equipment_slot := String(get_meta("equipment_slot", ""))
	if item_id.is_empty() or equipment_slot.is_empty():
		return {}
	return {
		"type": "inventory_item",
		"item_id": item_id,
		"equipment_slot": equipment_slot
	}


func _drag_preview() -> Label:
	var preview := Label.new()
	preview.text = _preview_text()
	preview.add_theme_font_size_override("font_size", 14)
	return preview


func _preview_text() -> String:
	var lines := text.split("\n", false)
	return lines[0] if not lines.is_empty() else String(get_meta("item_id", "Item"))


func _apply_drag_preview(preview: Control) -> void:
	if get_viewport().gui_is_dragging():
		set_drag_preview(preview)
	else:
		preview.free()


func _draw_badge_icon(rect: Rect2, icon: String, color: Color) -> void:
	var center := rect.get_center()
	var radius := minf(rect.size.x, rect.size.y) * 0.28
	match icon:
		"W":
			_draw_weapon_icon(center, radius, color)
		"A":
			_draw_armour_icon(center, radius, color)
		"G":
			_draw_ingredient_icon(center, radius, color)
		"Q":
			RpgIconDrawer.draw_icon(self, "quest", center, radius, color)
		"S":
			RpgIconDrawer.draw_icon(self, "spell", center, radius, color)
		"M":
			RpgIconDrawer.draw_icon(self, "map", center, radius, color)
		"J":
			RpgIconDrawer.draw_icon(self, "journal", center, radius, color)
		"T":
			RpgIconDrawer.draw_icon(self, "trade", center, radius, color)
		"H":
			_draw_vitals_icon(center, radius, color)
		_:
			RpgIconDrawer.draw_icon(self, "item", center, radius, color)


func _draw_weapon_icon(center: Vector2, radius: float, color: Color) -> void:
	draw_line(center + Vector2(-radius, radius), center + Vector2(radius, -radius), color, 3.0)
	draw_line(
		center + Vector2(-radius * 0.35, radius * 0.35),
		center + Vector2(0.2, radius),
		color,
		2.0
	)
	draw_circle(center + Vector2(radius * 0.82, -radius * 0.82), radius * 0.16, color)


func _draw_armour_icon(center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array([
		center + Vector2(0, -radius),
		center + Vector2(radius * 0.78, -radius * 0.45),
		center + Vector2(radius * 0.62, radius * 0.55),
		center + Vector2(0, radius),
		center + Vector2(-radius * 0.62, radius * 0.55),
		center + Vector2(-radius * 0.78, -radius * 0.45)
	])
	draw_polyline(points, color, 2.2, true)
	draw_line(
		center + Vector2(0, -radius * 0.7),
		center + Vector2(0, radius * 0.65),
		color,
		1.4
	)


func _draw_ingredient_icon(center: Vector2, radius: float, color: Color) -> void:
	draw_arc(center, radius * 0.72, PI * 0.08, PI * 1.42, 28, color, 2.0)
	draw_line(center, center + Vector2(radius * 0.55, radius * 0.85), color, 2.0)
	draw_line(
		center + Vector2(radius * 0.18, radius * 0.22),
		center + Vector2(radius * 0.76, 0),
		color,
		1.6
	)


func _draw_vitals_icon(center: Vector2, radius: float, color: Color) -> void:
	draw_line(center + Vector2(-radius, 0), center + Vector2(-radius * 0.35, 0), color, 2.0)
	draw_line(
		center + Vector2(-radius * 0.35, 0),
		center + Vector2(-radius * 0.12, -radius * 0.55),
		color,
		2.0
	)
	draw_line(
		center + Vector2(-radius * 0.12, -radius * 0.55),
		center + Vector2(radius * 0.20, radius * 0.55),
		color,
		2.0
	)
	draw_line(
		center + Vector2(radius * 0.20, radius * 0.55),
		center + Vector2(radius * 0.42, 0),
		color,
		2.0
	)
	draw_line(center + Vector2(radius * 0.42, 0), center + Vector2(radius, 0), color, 2.0)


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
