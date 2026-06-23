class_name RpgNavigationTextBuilder
extends RefCounted


static func friendly_navigation(navigation: String) -> String:
	var clean := navigation.strip_edges()
	var tokens := clean.split(" ", false)
	if tokens.size() < 2:
		return clean
	var direction := String(tokens[0])
	var distance := String(tokens[1])
	if not _direction_words().has(direction) or not distance.ends_with("t"):
		return clean
	var tile_text := distance.trim_suffix("t")
	if not tile_text.is_valid_float():
		return clean
	var count := _format_tile_count(float(tile_text))
	var plural := "tile" if count == "1" else "tiles"
	var result := "%s %s %s" % [count, plural, _direction_words()[direction]]
	if tokens.size() > 2:
		result = "%s to %s" % [result, " ".join(tokens.slice(2))]
	return result


static func friendly_route_line(line: String) -> String:
	var clean := line.strip_edges()
	var separator := clean.find(":")
	if separator < 0:
		return friendly_navigation(clean)
	var title := clean.substr(0, separator).strip_edges()
	var route := clean.substr(separator + 1).strip_edges()
	var friendly := friendly_navigation(route)
	return "%s: %s" % [title, friendly] if not friendly.is_empty() else title


static func friendly_route_lines(value: String) -> String:
	var lines: Array[String] = []
	for raw_line in value.split("\n", false):
		var line := raw_line.strip_edges()
		if not line.is_empty():
			lines.append(friendly_route_line(line))
	return "\n".join(lines)


static func _format_tile_count(value: float) -> String:
	var rounded := roundf(value)
	if is_equal_approx(value, rounded):
		return str(int(rounded))
	return "%.1f" % value


static func _direction_words() -> Dictionary:
	return {
		"N": "north",
		"NE": "northeast",
		"E": "east",
		"SE": "southeast",
		"S": "south",
		"SW": "southwest",
		"W": "west",
		"NW": "northwest"
	}
