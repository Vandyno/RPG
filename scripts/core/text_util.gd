class_name TextUtil
extends RefCounted


static func ellipsized(value: String, max_chars: int) -> String:
	if value.length() <= max_chars:
		return value
	if max_chars <= 3:
		return value.substr(0, max_chars)
	return "%s..." % value.substr(0, max_chars - 3)
