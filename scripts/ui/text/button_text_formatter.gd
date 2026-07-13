class_name ButtonTextFormatter
extends RefCounted

const TextUtil = preload("res://scripts/core/text_util.gd")

const PRIMARY_BUTTON_LINE_CHARS := 13


static func primary_action_label(value: String) -> String:
	if _is_short_button_text(value):
		return value
	return _two_line_button_text(value)


static func compact_primary_action_label(action: String, target: String) -> String:
	if target.is_empty() or target == "none" or ["Close", "Explore", "Stop"].has(action):
		return primary_action_label(action)
	if not _is_short_button_text(action):
		return primary_action_label(action)
	return "%s\n%s" % [action, _compact_target_label(target)]


static func compact_target_label(value: String) -> String:
	return _compact_target_label(value)


static func _is_short_button_text(value: String) -> bool:
	return value.length() <= PRIMARY_BUTTON_LINE_CHARS and not value.contains(" ")


static func _two_line_button_text(value: String) -> String:
	var words := value.split(" ", false)
	if words.size() <= 1:
		return TextUtil.ellipsized(value, PRIMARY_BUTTON_LINE_CHARS)
	var lines: Array[String] = ["", ""]
	var line_index := 0
	for word in words:
		var next := word if lines[line_index].is_empty() else "%s %s" % [lines[line_index], word]
		if next.length() <= PRIMARY_BUTTON_LINE_CHARS:
			lines[line_index] = next
			continue
		if line_index == 0:
			line_index = 1
			lines[line_index] = word
			continue
		lines[line_index] = TextUtil.ellipsized(lines[line_index], PRIMARY_BUTTON_LINE_CHARS)
		break
	if lines[1].is_empty():
		return TextUtil.ellipsized(lines[0], PRIMARY_BUTTON_LINE_CHARS)
	return "%s\n%s" % [lines[0], TextUtil.ellipsized(lines[1], PRIMARY_BUTTON_LINE_CHARS)]


static func _compact_target_label(value: String) -> String:
	if value.length() <= PRIMARY_BUTTON_LINE_CHARS:
		return value
	var words := value.split(" ", false)
	if words.size() > 1:
		var last_word := String(words[words.size() - 1])
		if last_word.length() <= PRIMARY_BUTTON_LINE_CHARS:
			return last_word
	return TextUtil.ellipsized(value, PRIMARY_BUTTON_LINE_CHARS)
