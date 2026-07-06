class_name ContentCardPresenter
extends RefCounted

const UiActionButtons = preload("res://scripts/ui/shell/ui_action_buttons.gd")


static func build(
	root: Control,
	new_panel: Callable,
	add_margin: Callable,
	new_label: Callable,
	new_button: Callable,
	close_callback: Callable
) -> Dictionary:
	var panel: PanelContainer = new_panel.call("ContentPanel")
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -280
	panel.offset_top = -164
	panel.offset_right = 280
	panel.offset_bottom = 164
	panel.visible = false
	root.add_child(panel)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 10)
	add_margin.call(panel, stack, 16)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	stack.add_child(header)

	var kind_label: Label = new_label.call(12)
	kind_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kind_label.add_theme_color_override("font_color", Color(0.86, 0.78, 0.58, 0.92))
	header.add_child(kind_label)

	var close: Button = new_button.call("Close", Vector2(84, 42))
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(close_callback)
	header.add_child(close)

	var title_label: Label = new_label.call(20)
	stack.add_child(title_label)

	var scroll := ScrollContainer.new()
	scroll.name = "ContentScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)

	var body_label: Label = new_label.call(16)
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(body_label)

	var choice_list := VBoxContainer.new()
	choice_list.name = "ContentChoices"
	choice_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_list.add_theme_constant_override("separation", 6)
	stack.add_child(choice_list)

	return {
		"panel": panel,
		"kind_label": kind_label,
		"title_label": title_label,
		"scroll": scroll,
		"body_label": body_label,
		"choice_list": choice_list
	}


static func kind_text(kind: String) -> String:
	match kind:
		"dialogue":
			return "Dialogue"
		"readable":
			return "Readable"
		"place":
			return "Place"
		"response":
			return "Result"
		_:
			return "Notice"


static func refresh_choices(choice_list: VBoxContainer, choices: Array, owner: Object) -> bool:
	return UiActionButtons.refresh(
		UiActionButtons.RefreshRequest.new(
			choice_list,
			choices,
			owner,
			"content_choice_selected",
			"choice_id",
			Vector2(0, 50),
			14
		)
	)
