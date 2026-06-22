extends RefCounted


static func refresh(
	container: Container,
	actions: Array,
	owner: Object,
	signal_id: String,
	meta_id: String,
	min_size: Vector2,
	font_size: int,
	empty_text := ""
) -> bool:
	var button_index := 0
	for action in actions:
		if not action is Dictionary:
			continue
		var action_id := String(action.get("id", ""))
		var text := String(action.get("text", ""))
		if action_id.is_empty() or text.is_empty():
			continue
		var button := _button(container, button_index, owner, signal_id, meta_id, min_size)
		button.text = text
		button.disabled = false
		button.set_meta("signal_id", signal_id)
		button.set_meta("meta_id", meta_id)
		button.set_meta(meta_id, action_id)
		button.visible = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", font_size)
		button_index += 1
	if button_index <= 0 and not empty_text.is_empty():
		var empty := _button(container, 0, owner, signal_id, meta_id, min_size)
		empty.text = empty_text
		empty.disabled = true
		empty.visible = true
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.add_theme_font_size_override("font_size", font_size)
		button_index = 1
	for index in range(button_index, container.get_child_count()):
		container.get_child(index).visible = false
	return button_index > 0


static func valid_action_count(actions: Array) -> int:
	var count := 0
	for action in actions:
		if not action is Dictionary:
			continue
		if String(action.get("id", "")).is_empty() or String(action.get("text", "")).is_empty():
			continue
		count += 1
	return count


static func wrapped_panel_height(
	panel_width: float,
	action_count: int,
	button_size: Vector2,
	separation: Vector2,
	margin: float,
	base_height: float,
	top: float,
	reserved_bottom: float,
	outer_margin: float,
	viewport_height: float
) -> float:
	if action_count <= 0:
		return base_height
	var inner_width := maxf(1.0, panel_width - margin * 2.0)
	var columns := maxi(
		1, int(floor((inner_width + separation.x) / (button_size.x + separation.x)))
	)
	var rows := int(ceil(float(action_count) / float(columns)))
	var wrapped_height := margin * 2.0 + button_size.y * float(rows)
	wrapped_height += separation.y * float(maxi(0, rows - 1))
	var max_height := maxf(base_height, viewport_height - top - reserved_bottom - outer_margin)
	return minf(maxf(base_height, wrapped_height), max_height)


static func _button(
	container: Container,
	index: int,
	owner: Object,
	signal_id: String,
	meta_id: String,
	min_size: Vector2
) -> Button:
	if index < container.get_child_count():
		var existing = container.get_child(index)
		if existing is Button:
			return existing
	var button := Button.new()
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", 15)
	button.set_meta("signal_id", signal_id)
	button.set_meta("meta_id", meta_id)
	button.pressed.connect(func() -> void: _emit(owner, button))
	container.add_child(button)
	return button


static func _emit(owner: Object, button: Button) -> void:
	var signal_id := String(button.get_meta("signal_id", ""))
	var meta_id := String(button.get_meta("meta_id", ""))
	owner.emit_signal(signal_id, String(button.get_meta(meta_id, "")))
