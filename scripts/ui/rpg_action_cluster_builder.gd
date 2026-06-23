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
		"InventoryButton": Vector2(78, 52) if compact else Vector2(92, 58),
		"TargetButton": Vector2(78, 52) if compact else Vector2(92, 58),
		"InteractButton": Vector2(112, 52) if compact else Vector2(136, 58),
		"SystemsButton": Vector2(72, 52) if compact else Vector2(82, 58)
	}
	for child in cluster.get_children():
		if child is Button:
			child.custom_minimum_size = sizes.get(child.name, fallback_size)
			child.add_theme_font_size_override("font_size", 12 if compact else 15)
			if child == primary:
				child.add_theme_font_size_override("font_size", 14 if compact else 16)
				primary_style.call(child)


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
	return button
