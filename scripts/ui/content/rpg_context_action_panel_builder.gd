class_name RpgContextActionPanelBuilder
extends RefCounted

const RpgContentChoiceButton = preload(
	"res://scripts/ui/controls/buttons/rpg_content_choice_button.gd"
)


class BuildContext:
	var root: Control
	var new_panel: Callable
	var add_margin: Callable
	var new_label: Callable

	func _init(
		p_root: Control, p_new_panel: Callable, p_add_margin: Callable, p_new_label: Callable
	) -> void:
		root = p_root
		new_panel = p_new_panel
		add_margin = p_add_margin
		new_label = p_new_label


class RefreshRequest:
	var container: HFlowContainer
	var actions: Array
	var new_button: Callable
	var row_style: Callable
	var action_callback: Callable
	var title_text: String
	var context_mode: bool
	var compact: bool


class LayoutRequest:
	var panel: PanelContainer
	var buttons: HFlowContainer
	var visible_count: int
	var viewport_size: Vector2
	var compact: bool
	var hud_margin: float


static func build(context: BuildContext) -> Dictionary:
	if not context or not context.root:
		return {}
	var root := context.root
	var new_panel := context.new_panel
	var add_margin := context.add_margin
	var new_label := context.new_label
	var panel: PanelContainer = new_panel.call("ContextActionPanel")
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.visible = false
	panel.z_index = 55
	root.add_child(panel)

	var stack := VBoxContainer.new()
	stack.name = "QuickActionFrame"
	stack.add_theme_constant_override("separation", 7)
	add_margin.call(panel, stack, 9)

	var title := new_label.call(13) as Label
	title.name = "QuickActionTitle"
	title.text = "Actions"
	title.add_theme_color_override("font_color", Color(0.86, 0.70, 0.42))
	stack.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.name = "ContextActionScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)

	var buttons := HFlowContainer.new()
	buttons.name = "ContextActionButtons"
	buttons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buttons.add_theme_constant_override("h_separation", 7)
	buttons.add_theme_constant_override("v_separation", 7)
	scroll.add_child(buttons)

	return {"panel": panel, "buttons": buttons}


static func refresh(request: RefreshRequest) -> int:
	if not request or not request.container:
		return 0
	var container := request.container
	_refresh_title(container, request.title_text)
	var button_index := 0
	for action in request.actions:
		if not action is Dictionary:
			continue
		var action_id := String(action.get("id", ""))
		var text := String(action.get("text", ""))
		if action_id.is_empty() or text.is_empty():
			continue
		var button := _button(container, button_index, request.new_button)
		var subtitle := _subtitle(action_id, text)
		button.text = "%s\n%s" % [text, subtitle]
		button.disabled = false
		button.visible = true
		button.custom_minimum_size = Vector2(104, 50) if request.compact else Vector2(150, 58)
		button.add_theme_font_size_override("font_size", 10 if request.compact else 12)
		request.row_style.call(button, _is_recommended(action_id, text))
		if button is RpgContentChoiceButton:
			(button as RpgContentChoiceButton).set_choice_card(
				_action_icon(action_id, text), text, subtitle
			)
		button.set_meta("action_id", action_id)
		button.set_meta("context_mode", request.context_mode)
		_bind_button(button, request.action_callback)
		button_index += 1
	for index in range(button_index, container.get_child_count()):
		container.get_child(index).visible = false
	return button_index


static func title_text(state: Dictionary, context_mode: bool) -> String:
	if not context_mode:
		return "Combat Actions"
	var nearby := String(state.get("nearby", "")).strip_edges()
	if _is_useful_title(nearby):
		return nearby
	var targets_value = state.get("nearby_targets", [])
	if targets_value is Array:
		for target in targets_value:
			if target is Dictionary and bool(target.get("selected", false)):
				var name := String(target.get("name", "")).strip_edges()
				if _is_useful_title(name):
					return name
	return "Nearby Actions"


static func apply_layout(request: LayoutRequest) -> void:
	if not request:
		return
	var panel := request.panel
	var buttons := request.buttons
	var visible_count := request.visible_count
	var viewport_size := request.viewport_size
	var compact := request.compact
	var hud_margin := request.hud_margin
	if not panel:
		return
	var width := minf(520.0, viewport_size.x - hud_margin * 2.0)
	if compact:
		width = minf(320.0, viewport_size.x - hud_margin * 2.0)
		var compact_available := maxf(180.0, viewport_size.x - 380.0)
		width = minf(width, compact_available)
	var bottom_gap := 270.0 if not compact else 164.0
	var column_count := 1 if compact and width < 300.0 else 2 if compact and width < 430.0 else 3
	var row_count := ceili(float(maxi(1, visible_count)) / float(column_count))
	var height := 46.0 + float(row_count) * (65.0 if compact else 63.0)
	height = clampf(height, 112.0, 184.0)
	if compact:
		var left_bound := 196.0
		var right_bound := viewport_size.x - 230.0
		width = minf(width, maxf(180.0, right_bound - left_bound))
		var left := left_bound + maxf(0.0, right_bound - left_bound - width) * 0.5
		left = clampf(left, hud_margin, viewport_size.x - width - hud_margin)
		panel.offset_left = -viewport_size.x + left
		panel.offset_right = panel.offset_left + width
		panel.offset_bottom = -74.0
	else:
		panel.offset_left = -width - hud_margin
		panel.offset_right = -hud_margin
		panel.offset_bottom = -bottom_gap
	panel.offset_top = panel.offset_bottom - height
	if panel.offset_top < -viewport_size.y + hud_margin:
		panel.offset_top = -viewport_size.y + hud_margin
	if buttons:
		buttons.add_theme_constant_override("h_separation", 5 if compact else 7)
		buttons.add_theme_constant_override("v_separation", 5 if compact else 7)
		var frame := panel.find_child("QuickActionFrame", true, false) as VBoxContainer
		if frame:
			frame.add_theme_constant_override("separation", 5 if compact else 7)
		var margin := panel.get_child(0) as MarginContainer if panel.get_child_count() > 0 else null
		if margin:
			var margin_size := 6 if compact else 9
			margin.add_theme_constant_override("margin_left", margin_size)
			margin.add_theme_constant_override("margin_top", margin_size)
			margin.add_theme_constant_override("margin_right", margin_size)
			margin.add_theme_constant_override("margin_bottom", margin_size)


static func _button(container: HFlowContainer, index: int, new_button: Callable) -> Button:
	if index < container.get_child_count():
		var existing := container.get_child(index)
		if existing is Button:
			return existing
	var button := RpgContentChoiceButton.new()
	var styled := new_button.call("", Vector2(150, 50)) as Button
	if styled:
		RpgContentChoiceButton.copy_style_from(button, styled)
		styled.free()
	button.focus_mode = Control.FOCUS_NONE
	container.add_child(button)
	return button


static func _bind_button(button: Button, action_callback: Callable) -> void:
	if bool(button.get_meta("quick_action_bound", false)):
		return
	button.set_meta("quick_action_bound", true)
	button.pressed.connect(
		func() -> void:
			action_callback.call(
				String(button.get_meta("action_id", "")),
				bool(button.get_meta("context_mode", false))
			)
	)


static func _refresh_title(container: HFlowContainer, title_text: String) -> void:
	var frame := container.get_parent().get_parent() if container and container.get_parent() else null
	if not frame:
		return
	var title := frame.find_child("QuickActionTitle", false, false) as Label
	if title:
		title.text = title_text


static func _is_useful_title(text: String) -> bool:
	if text.is_empty():
		return false
	var lowered := text.to_lower()
	return lowered != "none" and lowered != "nothing nearby" and lowered != "destination"


static func _is_recommended(action_id: String, text: String) -> bool:
	return (
		action_id.begins_with("dialogue:")
		or action_id.begins_with("line:")
		or action_id.begins_with("poi:")
		or text == "Guard"
		or text.begins_with("Turn In")
	)


static func _subtitle(action_id: String, text: String) -> String:
	if action_id.begins_with("dialogue:") or action_id.begins_with("line:"):
		return "Dialogue"
	if action_id.begins_with("poi:"):
		return "Use nearby"
	if action_id.begins_with("trade:"):
		return "Merchant"
	if action_id.begins_with("forge:"):
		return "Service"
	if text == "Guard":
		return "Combat"
	if text.begins_with("Turn In"):
		return "Quest"
	return "Nearby"


static func _action_icon(action_id: String, text: String) -> String:
	if action_id.begins_with("dialogue:") or action_id.begins_with("line:"):
		return "dialogue"
	if action_id.begins_with("trade:"):
		return "trade"
	if action_id.begins_with("forge:") or text.contains("Sharpen"):
		return "service"
	if action_id.begins_with("poi:"):
		return "action"
	if text == "Guard":
		return "service"
	if text.begins_with("Turn In"):
		return "quest"
	return "action"
