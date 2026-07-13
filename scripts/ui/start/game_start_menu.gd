class_name GameStartMenu
extends CanvasLayer

signal new_game_pressed
signal continue_pressed

var root: Control
var panel: PanelContainer
var continue_button: Button
var status_label: Label


func setup(can_continue: bool) -> void:
	layer = 100
	_build()
	show_menu(can_continue)


func show_menu(can_continue: bool) -> void:
	if not root:
		return
	root.visible = true
	continue_button.disabled = not can_continue
	status_label.text = (
		"Continue your last journey."
		if can_continue
		else "No saved journey yet. Begin a new one."
	)


func hide_menu() -> void:
	if root:
		root.visible = false


func set_status(message: String) -> void:
	if status_label:
		status_label.text = message


func _build() -> void:
	root = Control.new()
	root.name = "GameStartMenuRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)

	var shade := ColorRect.new()
	shade.color = Color(0.008, 0.012, 0.010, 0.94)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(shade)

	panel = PanelContainer.new()
	panel.name = "GameStartMenuPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-190, -170)
	panel.size = Vector2(380, 340)
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 12)
	margin.add_child(stack)

	var title := Label.new()
	title.name = "GameStartTitle"
	title.text = "BRIARWATCH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.94, 0.77, 0.38))
	stack.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "A quiet road. A hard country."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_color_override("font_color", Color(0.78, 0.72, 0.62))
	stack.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size.y = 18
	stack.add_child(spacer)

	var new_game := _button("New Game", "TitleNewGameButton")
	new_game.pressed.connect(func() -> void: new_game_pressed.emit())
	stack.add_child(new_game)

	continue_button = _button("Continue", "TitleContinueButton")
	continue_button.pressed.connect(func() -> void: continue_pressed.emit())
	stack.add_child(continue_button)

	status_label = Label.new()
	status_label.name = "TitleStatusLabel"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.add_theme_color_override("font_color", Color(0.73, 0.68, 0.58))
	stack.add_child(status_label)


func _button(text: String, node_name: String) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.11, 0.09, 0.055, 0.98)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.22, 0.16, 0.08, 1.0)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.34, 0.23, 0.10, 1.0)))
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.022, 0.015, 0.98)
	style.border_color = Color(0.86, 0.65, 0.27, 0.92)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	return style


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.86, 0.65, 0.27, 0.58)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style
