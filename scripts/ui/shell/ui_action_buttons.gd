class_name UiActionButtons
extends RefCounted


class RefreshRequest:
	var container: Container
	var actions: Array
	var owner: Object
	var signal_id: String
	var meta_id: String
	var min_size: Vector2
	var font_size: int
	var empty_text: String

	func _init(
		p_container: Container,
		p_actions: Array,
		p_owner: Object,
		p_signal_id: String,
		p_meta_id: String,
		p_min_size: Vector2,
		p_font_size: int,
		p_empty_text: String = ""
	) -> void:
		container = p_container
		actions = p_actions
		owner = p_owner
		signal_id = p_signal_id
		meta_id = p_meta_id
		min_size = p_min_size
		font_size = p_font_size
		empty_text = p_empty_text


class WrappedPanelMetrics:
	var panel_width: float
	var action_count: int
	var button_size: Vector2
	var separation: Vector2
	var margin: float
	var base_height: float
	var top: float
	var reserved_bottom: float
	var outer_margin: float
	var viewport_height: float

	func _init(
		p_panel_width: float,
		p_action_count: int,
		p_button_size: Vector2,
		p_separation: Vector2,
		p_margin: float,
		p_base_height: float,
		p_top: float,
		p_reserved_bottom: float,
		p_outer_margin: float,
		p_viewport_height: float
	) -> void:
		panel_width = p_panel_width
		action_count = p_action_count
		button_size = p_button_size
		separation = p_separation
		margin = p_margin
		base_height = p_base_height
		top = p_top
		reserved_bottom = p_reserved_bottom
		outer_margin = p_outer_margin
		viewport_height = p_viewport_height


static func refresh(request: RefreshRequest) -> bool:
	if (
		not request
		or not request.container
		or not request.owner
		or request.signal_id.is_empty()
		or request.meta_id.is_empty()
	):
		return false
	var button_index := 0
	for action in request.actions:
		if not action is Dictionary:
			continue
		var action_id := String(action.get("id", ""))
		var text := String(action.get("text", ""))
		if action_id.is_empty() or text.is_empty():
			continue
		var button := _button(
			request.container,
			button_index,
			request.owner,
			request.signal_id,
			request.meta_id,
			request.min_size
		)
		button.text = text
		button.disabled = false
		button.set_meta("signal_id", request.signal_id)
		button.set_meta("meta_id", request.meta_id)
		button.set_meta(request.meta_id, action_id)
		button.visible = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", request.font_size)
		button_index += 1
	if button_index <= 0 and not request.empty_text.is_empty():
		var empty := _button(
			request.container,
			0,
			request.owner,
			request.signal_id,
			request.meta_id,
			request.min_size
		)
		empty.text = request.empty_text
		empty.disabled = true
		empty.visible = true
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.add_theme_font_size_override("font_size", request.font_size)
		button_index = 1
	for index in range(button_index, request.container.get_child_count()):
		request.container.get_child(index).visible = false
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


static func wrapped_panel_height(metrics: WrappedPanelMetrics) -> float:
	if not metrics:
		return 0.0
	if metrics.action_count <= 0:
		return metrics.base_height
	var inner_width := maxf(1.0, metrics.panel_width - metrics.margin * 2.0)
	var columns := maxi(
		1,
		int(
			floor(
				(inner_width + metrics.separation.x)
				/ (metrics.button_size.x + metrics.separation.x)
			)
		)
	)
	var rows := int(ceil(float(metrics.action_count) / float(columns)))
	var wrapped_height := metrics.margin * 2.0 + metrics.button_size.y * float(rows)
	wrapped_height += metrics.separation.y * float(maxi(0, rows - 1))
	var max_height := maxf(
		metrics.base_height,
		metrics.viewport_height - metrics.top - metrics.reserved_bottom - metrics.outer_margin
	)
	return minf(maxf(metrics.base_height, wrapped_height), max_height)


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
