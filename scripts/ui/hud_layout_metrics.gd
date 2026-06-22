class_name HudLayoutMetrics
extends RefCounted


static func status_panel(
	viewport_size: Vector2, line_count: int, margin: float, compact: bool
) -> Dictionary:
	var width := minf(318.0, maxf(260.0, viewport_size.x * 0.50))
	var base_height := (40.0 + float(line_count) * 13.5) if compact else 136.0
	var per_extra_line := 0.0 if compact else 17.0
	var height := base_height + maxf(0.0, float(line_count - 4)) * per_extra_line
	if compact:
		height = minf(height, 100.0)
	height = minf(viewport_size.y - margin * 2.0, height)
	return {
		"width": width,
		"height": height,
		"status_font_size": 12 if compact else 15,
		"show_health_label": not compact
	}


static func button_row_width(container: Container, separation: float) -> float:
	var width := 0.0
	var count := 0
	for child in container.get_children():
		if child is Control and child.visible:
			width += child.custom_minimum_size.x
			count += 1
	return width + separation * float(maxi(0, count - 1))


static func apply_log_label(label: Label, compact: bool) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF if compact else TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 12 if compact else 14)
