class_name RpgTransferItemButton
extends Button

var item_name := ""
var item_count := 0
var action_label := ""
var destination_label := ""
var value := 0
var weight := 0.0


func set_transfer_data(item: Dictionary, verb: String, destination: String) -> void:
	item_name = String(item.get("name", item.get("item_id", "Item")))
	item_count = maxi(0, int(item.get("count", 0)))
	action_label = verb
	destination_label = destination
	value = maxi(0, int(item.get("value", 0)))
	weight = maxf(0.0, float(item.get("weight", 0.0)))
	text = "%s x%d %s to %s" % [item_name, item_count, action_label, destination_label]
	clip_text = false
	add_theme_color_override("font_color", Color.TRANSPARENT)
	add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	add_theme_color_override("font_focus_color", Color.TRANSPARENT)
	queue_redraw()


func _draw() -> void:
	var font := get_theme_default_font()
	if not font:
		return
	var selected := button_pressed or is_hovered()
	var border := Color(0.96, 0.78, 0.42, 0.92) if selected else Color(0.66, 0.50, 0.28, 0.72)
	var fill := Color(0.075, 0.070, 0.055, 0.96) if selected else Color(0.035, 0.032, 0.026, 0.94)
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect.grow(-0.5), fill, true)
	draw_rect(rect.grow(-0.5), border, false, 1.25)
	var icon_rect := Rect2(Vector2(10, 10), Vector2(40, size.y - 20))
	draw_rect(icon_rect, Color(0.015, 0.014, 0.012, 0.72), true)
	draw_rect(icon_rect, border, false, 1.0)
	_draw_item_icon(icon_rect, border)
	var text_x := icon_rect.end.x + 12.0
	var title_width := maxf(0.0, size.x - text_x - 102.0)
	draw_string(
		font, Vector2(text_x, 28), item_name, HORIZONTAL_ALIGNMENT_LEFT,
		title_width, 16, Color(0.98, 0.92, 0.78, 0.98)
	)
	var meta := "Count %d" % item_count
	if weight > 0.0:
		meta += "   %.1f wt" % weight
	if value > 0:
		meta += "   %dg" % value
	draw_string(
		font, Vector2(text_x, size.y - 14), meta, HORIZONTAL_ALIGNMENT_LEFT,
		size.x - text_x - 18.0, 12, Color(0.82, 0.74, 0.60, 0.96)
	)
	var pill_rect := Rect2(Vector2(size.x - 88.0, 15.0), Vector2(72.0, 26.0))
	draw_rect(pill_rect, Color(0.12, 0.11, 0.075, 0.98), true)
	draw_rect(pill_rect, border, false, 1.0)
	draw_string(
		font, pill_rect.position + Vector2(0.0, 18.0), action_label,
		HORIZONTAL_ALIGNMENT_CENTER, pill_rect.size.x, 12,
		Color(1.0, 0.88, 0.58, 0.98)
	)
	draw_string(
		font, Vector2(size.x - 88.0, size.y - 14), destination_label,
		HORIZONTAL_ALIGNMENT_RIGHT, 72.0, 10, Color(0.70, 0.64, 0.52, 0.92)
	)


func _draw_item_icon(rect: Rect2, color: Color) -> void:
	var center := rect.get_center()
	draw_line(center + Vector2(-6, 5), center + Vector2(7, -7), color, 2.0)
	draw_circle(center + Vector2(-5, 6), 3.0, color)
	draw_circle(center + Vector2(7, -7), 2.0, color.lightened(0.12))
