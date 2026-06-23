class_name RpgTargetPanelBuilder
extends RefCounted


static func build(
	root: Control,
	new_panel: Callable,
	add_margin: Callable,
	new_label: Callable,
	_new_button: Callable,
	_close_callback: Callable
) -> Dictionary:
	var panel: PanelContainer = new_panel.call("TargetPanel")
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -376
	panel.offset_top = 112
	panel.offset_right = -12
	panel.offset_bottom = 374
	panel.visible = false
	panel.z_index = 60
	root.add_child(panel)

	var stack := VBoxContainer.new()
	stack.name = "TargetFrame"
	stack.add_theme_constant_override("separation", 8)
	add_margin.call(panel, stack, 10)

	var header := HBoxContainer.new()
	header.name = "TargetHeader"
	header.add_theme_constant_override("separation", 8)
	stack.add_child(header)

	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_stack.add_theme_constant_override("separation", 2)
	header.add_child(title_stack)

	var title: Label = new_label.call(18)
	title.name = "TargetTitle"
	title.text = "Focus Target"
	title_stack.add_child(title)

	var subtitle: Label = new_label.call(12)
	subtitle.name = "TargetSubtitle"
	subtitle.text = "Pick what your next command should use."
	subtitle.add_theme_color_override("font_color", Color(0.82, 0.74, 0.60))
	title_stack.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.name = "TargetScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "TargetList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)

	return {"panel": panel, "scroll": scroll, "list": list}


static func refresh(
	target_list: VBoxContainer,
	targets: Array,
	new_label: Callable,
	new_button: Callable,
	row_style: Callable,
	target_callback: Callable,
	compact: bool
) -> void:
	for child in target_list.get_children():
		target_list.remove_child(child)
		child.queue_free()
	if targets.is_empty():
		var empty: Label = new_label.call(14)
		empty.text = "No reachable targets."
		target_list.add_child(empty)
		return
	for target_data in targets:
		if not target_data is Dictionary:
			continue
		var entity_id := String(target_data.get("id", ""))
		if entity_id.is_empty():
			continue
		var button: Button = new_button.call(_target_text(target_data, compact), Vector2(0, 68))
		button.name = "TargetRow_%s" % entity_id.to_pascal_case()
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.tooltip_text = _target_tooltip(target_data)
		button.add_theme_font_size_override("font_size", 14 if compact else 13)
		button.set_meta("selected_target", bool(target_data.get("selected", false)))
		row_style.call(button, bool(target_data.get("selected", false)))
		button.pressed.connect(func() -> void: target_callback.call(entity_id))
		target_list.add_child(button)


static func apply_layout(
	target_panel: PanelContainer,
	target_list: VBoxContainer,
	viewport_size: Vector2,
	compact: bool,
	hud_margin: float
) -> void:
	if not target_panel:
		return
	var width := minf(392.0 if compact else 340.0, viewport_size.x - hud_margin * 2.0)
	target_panel.anchor_left = 0.0 if compact else 1.0
	target_panel.anchor_right = 0.0 if compact else 1.0
	target_panel.offset_left = hud_margin if compact else -width - hud_margin
	target_panel.offset_right = hud_margin + width if compact else -hud_margin
	var top := 138.0 if compact else 112.0
	var bottom := (
		viewport_size.y - hud_margin if compact else minf(430.0, viewport_size.y - 270.0)
	)
	if bottom - top < 174.0:
		top = maxf(hud_margin, bottom - 174.0)
	target_panel.offset_top = top
	target_panel.offset_bottom = bottom
	if target_list:
		target_list.add_theme_constant_override("separation", 7 if compact else 6)
	var subtitle := target_panel.find_child("TargetSubtitle", true, false) as Label
	if subtitle:
		subtitle.visible = not compact
	var title := target_panel.find_child("TargetTitle", true, false) as Label
	if title:
		title.add_theme_font_size_override("font_size", 16 if compact else 18)


static func _target_text(target_data: Dictionary, compact: bool) -> String:
	var display_name := String(target_data.get("name", target_data.get("id", "Target")))
	var name := display_name
	var kind := _kind_text(String(target_data.get("kind", "")))
	var detail := _clean_detail(String(target_data.get("detail", "")))
	if detail == display_name:
		detail = ""
	if compact:
		detail = _shorten(detail, 42)
	var navigation := _friendly_navigation(String(target_data.get("navigation", "")))
	var lines: Array[String] = [name]
	var role_line := kind
	if not detail.is_empty():
		role_line = "%s - %s" % [kind, detail] if not kind.is_empty() else detail
	if not role_line.is_empty():
		lines.append(role_line)
	if not navigation.is_empty():
		lines.append(navigation)
	return "\n".join(lines)


static func _target_tooltip(target_data: Dictionary) -> String:
	var display_name := String(target_data.get("name", target_data.get("id", "Target")))
	var kind := _kind_text(String(target_data.get("kind", "")))
	var detail := _clean_detail(String(target_data.get("detail", "")))
	var navigation := _friendly_navigation(String(target_data.get("navigation", "")))
	return "\n".join([display_name, kind, detail, navigation]).strip_edges()


static func _shorten(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return "%s..." % text.substr(0, max_chars - 3).strip_edges()


static func _clean_detail(detail: String) -> String:
	for prefix in ["Readable: ", "Rest: ", "Pickup: ", "Container: ", "Door: "]:
		if detail.begins_with(prefix):
			return detail.trim_prefix(prefix)
	return detail


static func _friendly_navigation(navigation: String) -> String:
	var clean := navigation.strip_edges()
	var tokens := clean.split(" ", false)
	if tokens.size() < 2:
		return clean
	var direction := String(tokens[0])
	var distance := String(tokens[1])
	if not _direction_words().has(direction) or not distance.ends_with("t"):
		return clean
	var tile_count := distance.trim_suffix("t")
	var plural := "tile" if is_equal_approx(float(tile_count), 1.0) else "tiles"
	return "%s %s %s" % [tile_count, plural, _direction_words()[direction]]


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


static func _kind_text(kind: String) -> String:
	match kind:
		"npc":
			return "Talk"
		"enemy":
			return "Attack"
		"readable":
			return "Read"
		"pickup":
			return "Take"
		"container":
			return "Open"
		"rest":
			return "Rest"
		"poi":
			return "Use"
		"door":
			return "Enter"
	return "Target"
