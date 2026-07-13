class_name RpgDetailLabel
extends Label

const RpgTextFit = preload("res://scripts/ui/text/rpg_text_fit.gd")

const TEXT := Color(0.96, 0.90, 0.78, 0.98)
const MUTED := Color(0.78, 0.68, 0.52, 0.95)
const ACCENT := Color(0.88, 0.72, 0.42, 0.95)
const SAFE := Color(0.78, 1.0, 0.52, 0.95)


func _ready() -> void:
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_theme_color_override("font_color", Color.TRANSPARENT)


func _draw() -> void:
	var lines := _visible_lines(text)
	if lines.is_empty():
		return
	var font := get_theme_default_font()
	var title_size := 16 if size.x < 210.0 else 18
	var body_size := 12 if size.x < 210.0 else 14
	var y := 22.0
	y = _draw_title(font, lines[0], y, title_size)
	var index := 1
	while index < lines.size() and not lines[index].is_empty():
		var line := lines[index]
		var color := SAFE if _is_stat_line(line) else MUTED
		y = _draw_wrapped(font, line, y, body_size, color)
		index += 1
	y += 8.0
	index += 1
	while index < lines.size():
		y = _draw_wrapped(font, lines[index], y, body_size, TEXT)
		index += 1


func _draw_title(font: Font, value: String, y: float, font_size: int) -> float:
	for line in _fit_wrapped_lines(value, font, font_size, size.x, 2):
		draw_string(font, Vector2(0, y), line, HORIZONTAL_ALIGNMENT_LEFT, size.x, font_size, TEXT)
		y += float(font_size) + 4.0
	return y + 4.0


func _draw_wrapped(font: Font, value: String, y: float, font_size: int, color: Color) -> float:
	var words := value.split(" ", false)
	var line := ""
	for word in words:
		var candidate := word if line.is_empty() else "%s %s" % [line, word]
		if font.get_string_size(candidate, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > size.x:
			draw_string(font, Vector2(0, y), line, HORIZONTAL_ALIGNMENT_LEFT, size.x, font_size, color)
			y += float(font_size) + 5.0
			line = word
		else:
			line = candidate
	if not line.is_empty():
		draw_string(font, Vector2(0, y), line, HORIZONTAL_ALIGNMENT_LEFT, size.x, font_size, color)
		y += float(font_size) + 5.0
	return y


func _fit_wrapped_lines(
	value: String, font: Font, font_size: int, max_width: float, max_lines: int
) -> Array[String]:
	var result: Array[String] = []
	var line := ""
	for word in value.split(" ", false):
		var candidate := word if line.is_empty() else "%s %s" % [line, word]
		if RpgTextFit.line_width(candidate, font, font_size) <= max_width:
			line = candidate
			continue
		if not line.is_empty():
			result.append(line)
			if result.size() >= max_lines:
				result[result.size() - 1] = RpgTextFit.ellipsize(
					result[result.size() - 1], font, font_size, max_width
				)
				return result
		line = word
	if not line.is_empty():
		result.append(line)
	if result.size() > max_lines:
		result = result.slice(0, max_lines)
		result[result.size() - 1] = RpgTextFit.ellipsize(
			result[result.size() - 1], font, font_size, max_width
		)
	elif not result.is_empty():
		result[result.size() - 1] = RpgTextFit.ellipsize(
			result[result.size() - 1], font, font_size, max_width
		)
	return result


func _visible_lines(value: String) -> Array[String]:
	var result: Array[String] = []
	for raw in value.split("\n", false):
		result.append(raw.strip_edges())
	return result


func _is_stat_line(value: String) -> bool:
	return value.contains(":") or value.contains("Damage") or value.contains("Weight")
