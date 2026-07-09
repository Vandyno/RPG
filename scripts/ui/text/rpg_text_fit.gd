class_name RpgTextFit
extends RefCounted


static func ellipsize(value: String, font: Font, font_size: int, max_width: float) -> String:
	if line_width(value, font, font_size) <= max_width:
		return value
	var suffix := "..."
	var suffix_width := line_width(suffix, font, font_size)
	if suffix_width >= max_width:
		return suffix
	var best := ""
	for index in range(1, value.length() + 1):
		var candidate := value.substr(0, index).strip_edges()
		if line_width(candidate, font, font_size) + suffix_width > max_width:
			break
		best = candidate
	return "%s%s" % [best, suffix]


static func line_width(value: String, font: Font, font_size: int) -> float:
	return font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
