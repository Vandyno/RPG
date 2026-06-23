class_name RpgActionClusterBuilder
extends RefCounted

const HoldActionButton = preload("res://scripts/ui/hold_action_button.gd")


static func build(
	root: Control,
	new_button: Callable,
	open_inventory: Callable,
	cycle_target: Callable,
	open_target_picker: Callable,
	primary_action: Callable,
	open_menu: Callable
) -> Dictionary:
	var cluster := HBoxContainer.new()
	cluster.name = "ActionButtons"
	cluster.anchor_left = 1.0
	cluster.anchor_right = 1.0
	cluster.anchor_top = 1.0
	cluster.anchor_bottom = 1.0
	cluster.alignment = BoxContainer.ALIGNMENT_END
	cluster.offset_left = -544
	cluster.offset_top = -76
	cluster.offset_right = -12
	cluster.offset_bottom = -12
	cluster.add_theme_constant_override("separation", 8)
	root.add_child(cluster)

	var inventory: Button = _command_button(
		new_button, "Inventory", "inventory", "Open inventory", Vector2(92, 58)
	)
	inventory.pressed.connect(open_inventory)
	cluster.add_child(inventory)

	var target: Button = _command_button(
		new_button, "Target", "target", "Cycle or hold for target list", Vector2(92, 58)
	)
	HoldActionButton.bind(target, cycle_target, open_target_picker)
	cluster.add_child(target)

	var primary: Button = _command_button(
		new_button, "Interact", "primary", "Use current action", Vector2(136, 58)
	)
	primary.name = "InteractButton"
	primary.set_meta("action_role", "primary")
	primary.pressed.connect(primary_action)
	cluster.add_child(primary)

	var menu: Button = _command_button(
		new_button, "Menu", "menu", "Open systems menu", Vector2(82, 58)
	)
	menu.pressed.connect(open_menu)
	cluster.add_child(menu)

	return {
		"cluster": cluster,
		"inventory": inventory,
		"target": target,
		"primary": primary,
		"menu": menu
	}


static func apply_layout(
	cluster: HBoxContainer,
	primary: Button,
	compact: bool,
	fallback_size: Vector2,
	primary_style: Callable
) -> void:
	if not cluster:
		return
	cluster.add_theme_constant_override("separation", 6 if compact else 8)
	var sizes := {
		"InventoryButton": Vector2(66, 58) if compact else Vector2(82, 68),
		"TargetButton": Vector2(66, 58) if compact else Vector2(82, 68),
		"InteractButton": Vector2(98, 66) if compact else Vector2(124, 88),
		"SystemsButton": Vector2(58, 58) if compact else Vector2(74, 68)
	}
	for child in cluster.get_children():
		if child is Button:
			child.custom_minimum_size = sizes.get(child.name, fallback_size)
			child.size_flags_vertical = Control.SIZE_SHRINK_END
			child.add_theme_font_size_override("font_size", 12 if compact else 15)
			if child == primary:
				child.add_theme_font_size_override("font_size", 14 if compact else 16)
				primary_style.call(child)
				_apply_command_style(child, true, compact)
			else:
				_apply_command_style(child, false, compact)


static func _command_button(
	new_button: Callable, text: String, action_kind: String, tooltip: String, size: Vector2
) -> Button:
	var button := new_button.call(text, size) as Button
	button.name = {
		"inventory": "InventoryButton",
		"target": "TargetButton",
		"menu": "SystemsButton"
	}.get(action_kind, "%sButton" % action_kind.capitalize())
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.set_meta("action_kind", action_kind)
	button.set_meta("action_role", "secondary")
	button.set_meta("action_shape", "round_secondary")
	return button


static func _apply_command_style(button: Button, primary: bool, compact: bool) -> void:
	var radius := 30 if compact else 36
	var border := Color(0.86, 0.70, 0.42, 0.78)
	var base := Color(0.035, 0.032, 0.026, 0.94)
	if primary:
		radius = 34 if compact else 44
		border = Color(0.94, 0.76, 0.42, 0.95)
		base = Color(0.075, 0.068, 0.050, 0.98)
		button.set_meta("action_shape", "round_primary")
	else:
		button.set_meta("action_shape", "round_secondary")
	button.add_theme_color_override(
		"font_color", Color(1.0, 0.92, 0.74) if primary else Color(0.96, 0.90, 0.78)
	)
	button.add_theme_stylebox_override("normal", _round_style(base, border, radius))
	button.add_theme_stylebox_override(
		"hover",
		_round_style(
			Color(0.13, 0.12, 0.075, 0.98) if primary else Color(0.10, 0.13, 0.08, 0.96),
			border,
			radius
		)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_round_style(
			Color(0.19, 0.17, 0.09, 0.98) if primary else Color(0.16, 0.20, 0.10, 0.98),
			Color(1.0, 0.86, 0.48, 1.0),
			radius
		)
	)
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func _round_style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	return style
