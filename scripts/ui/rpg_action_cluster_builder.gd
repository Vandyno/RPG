class_name RpgActionClusterBuilder
extends RefCounted

const HoldActionButton = preload("res://scripts/ui/hold_action_button.gd")
const RpgAimJoystick = preload("res://scripts/ui/rpg_aim_joystick.gd")


static func build(
	root: Control,
	new_button: Callable,
	open_inventory: Callable,
	cycle_target: Callable,
	open_target_picker: Callable,
	_primary_action: Callable,
	aim_action: Callable,
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

	var ability_stack := VBoxContainer.new()
	ability_stack.name = "AbilityButtonStack"
	ability_stack.add_theme_constant_override("separation", 5)
	ability_stack.custom_minimum_size = Vector2(72, 100)
	ability_stack.size_flags_vertical = Control.SIZE_SHRINK_END
	cluster.add_child(ability_stack)

	var ability_buttons := {}
	for slot_id in ["ability_1", "ability_2", "ability_3"]:
		var ability := _aim_joystick(
			_slot_index_text(slot_id), slot_id, "Assigned spell", Vector2(56, 56), false
		)
		ability.name = "%sButton" % slot_id.to_pascal_case()
		ability.set_meta("ability_slot", slot_id)
		ability.aimed.connect(aim_action)
		ability_stack.add_child(ability)
		ability_buttons[slot_id] = ability

	var primary := _aim_joystick("Attack", "attack", "Aim attack", Vector2(136, 58), false)
	primary.name = "InteractButton"
	primary.set_meta("action_role", "primary")
	primary.aimed.connect(aim_action)
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
		"ability_buttons": ability_buttons,
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
	cluster.offset_top = -196 if compact else -228
	cluster.offset_bottom = -32 if compact else -12
	var sizes := {
		"InventoryButton": Vector2(54, 50) if compact else Vector2(76, 64),
		"TargetButton": Vector2(54, 50) if compact else Vector2(76, 64),
		"InteractButton": Vector2(86, 86) if compact else Vector2(112, 112),
		"SystemsButton": Vector2(50, 50) if compact else Vector2(68, 64)
	}
	for child in cluster.get_children():
		if child is Button:
			child.custom_minimum_size = sizes.get(child.name, fallback_size)
			child.size_flags_vertical = Control.SIZE_SHRINK_END
			child.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			child.add_theme_font_size_override("font_size", 10 if compact else 14)
			if child == primary:
				child.add_theme_font_size_override("font_size", 12 if compact else 15)
				primary_style.call(child)
				_apply_command_style(child, true, compact)
			else:
				_apply_command_style(child, false, compact)
		elif child is VBoxContainer:
			child.add_theme_constant_override("separation", 4 if compact else 6)
			child.custom_minimum_size = Vector2(52, 164) if compact else Vector2(64, 204)
			for nested in child.get_children():
				if nested is Button:
					nested.custom_minimum_size = Vector2(52, 52) if compact else Vector2(64, 64)
					nested.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
					nested.add_theme_font_size_override("font_size", 9 if compact else 10)
					_apply_command_style(nested, false, compact)


static func refresh_ability_buttons(buttons: Dictionary, slots: Dictionary) -> void:
	for slot_id in buttons:
		var button := buttons[slot_id] as Button
		var slot_data := slots.get(slot_id, {}) as Dictionary
		var spell_name := String(slot_data.get("name", ""))
		var cost := int(slot_data.get("mana_cost", 0))
		if spell_name.is_empty():
			button.text = _slot_index_text(String(slot_id))
			button.tooltip_text = "Empty ability slot"
			button.set_meta("spell_id", "")
		else:
			button.text = "%s\n%d" % [_short_spell_label(spell_name), cost]
			button.tooltip_text = "Cast %s" % spell_name
			button.set_meta("spell_id", String(slot_data.get("spell_id", "")))


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


static func _aim_joystick(
	text: String, action_kind: String, tooltip: String, size: Vector2, emit_press: bool
) -> RpgAimJoystick:
	var joystick := RpgAimJoystick.new()
	joystick.text = text
	joystick.custom_minimum_size = size
	joystick.action_id = action_kind
	joystick.emit_press_on_release = emit_press
	joystick.tooltip_text = tooltip
	joystick.focus_mode = Control.FOCUS_NONE
	joystick.set_meta("action_kind", action_kind)
	joystick.set_meta("action_role", "secondary")
	joystick.set_meta("action_shape", "round_secondary")
	return joystick


static func _slot_index_text(slot_id: String) -> String:
	return {"ability_1": "I", "ability_2": "II", "ability_3": "III"}.get(slot_id, "")


static func _short_spell_label(spell_name: String) -> String:
	var parts := spell_name.split(" ", false)
	return String(parts[0]) if not parts.is_empty() else spell_name


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
	var font_color := Color(1.0, 0.92, 0.74) if primary else Color(0.96, 0.90, 0.78)
	if button is RpgAimJoystick:
		font_color = Color.TRANSPARENT
	button.add_theme_color_override("font_color", font_color)
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
