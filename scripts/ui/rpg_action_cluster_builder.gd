class_name RpgActionClusterBuilder
extends RefCounted

const RpgAimJoystick = preload("res://scripts/ui/rpg_aim_joystick.gd")


static func build(
	root: Control,
	aim_action: Callable
) -> Dictionary:
	var cluster := Control.new()
	cluster.name = "CombatJoystickCluster"
	cluster.anchor_left = 1.0
	cluster.anchor_right = 1.0
	cluster.anchor_top = 1.0
	cluster.anchor_bottom = 1.0
	cluster.offset_left = -300
	cluster.offset_top = -252
	cluster.offset_right = -12
	cluster.offset_bottom = -12
	root.add_child(cluster)

	var utility_row := HBoxContainer.new()
	utility_row.name = "UtilityButtonStack"
	utility_row.alignment = BoxContainer.ALIGNMENT_END
	utility_row.add_theme_constant_override("separation", 6)
	cluster.add_child(utility_row)

	var utility_buttons := {}
	for data in [
		{"id": "inventory", "text": "Inv", "tooltip": "Inventory"},
		{"id": "target", "text": "Target", "tooltip": "Cycle target. Hold for target list."},
		{"id": "menu", "text": "Menu", "tooltip": "Open systems menu"}
	]:
		var utility := _utility_button(
			String(data["text"]), String(data["id"]), String(data["tooltip"]), Vector2(56, 56)
		)
		utility_row.add_child(utility)
		utility_buttons[String(data["id"])] = utility

	var ability_stack := VBoxContainer.new()
	ability_stack.name = "AbilityButtonStack"
	ability_stack.add_theme_constant_override("separation", 8)
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

	var primary := _aim_joystick("Attack", "attack", "Aim attack", Vector2(156, 156), false)
	primary.name = "InteractButton"
	primary.set_meta("action_role", "primary")
	primary.center_label = ""
	primary.footer_label = "Attack"
	primary.aimed.connect(aim_action)
	cluster.add_child(primary)

	return {
		"cluster": cluster,
		"ability_buttons": ability_buttons,
		"utility_buttons": utility_buttons,
		"primary": primary
	}


static func apply_layout(
	cluster: Control,
	primary: Button,
	compact: bool,
	_fallback_size: Vector2,
	primary_style: Callable
) -> void:
	if not cluster:
		return
	var cluster_size := Vector2(220, 210) if compact else Vector2(310, 276)
	cluster.offset_left = -cluster_size.x - 12
	cluster.offset_top = -cluster_size.y - (22 if compact else 12)
	cluster.offset_right = -12
	cluster.offset_bottom = -22 if compact else -12
	cluster.custom_minimum_size = cluster_size
	cluster.size = cluster_size

	var utility_row := cluster.find_child("UtilityButtonStack", true, false) as HBoxContainer
	if utility_row:
		utility_row.position = Vector2(64, 0) if compact else Vector2(82, 0)
		utility_row.size = Vector2(156, 40) if compact else Vector2(228, 52)
		utility_row.add_theme_constant_override("separation", 5 if compact else 6)
		for nested in utility_row.get_children():
			if nested is Button:
				nested.custom_minimum_size = Vector2(44, 36) if compact else Vector2(68, 48)
				nested.size = nested.custom_minimum_size
				nested.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				nested.add_theme_font_size_override("font_size", 8 if compact else 10)
				_apply_utility_style(nested, compact)

	var ability_stack := cluster.find_child("AbilityButtonStack", true, false) as VBoxContainer
	if ability_stack:
		ability_stack.position = Vector2(4, 44) if compact else Vector2(0, 42)
		ability_stack.size = Vector2(58, 166) if compact else Vector2(72, 220)
		ability_stack.add_theme_constant_override("separation", 8 if compact else 10)
		for nested in ability_stack.get_children():
			if nested is Button:
				nested.custom_minimum_size = Vector2(50, 50) if compact else Vector2(64, 64)
				nested.size = nested.custom_minimum_size
				nested.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				nested.add_theme_font_size_override("font_size", 8 if compact else 10)
				_apply_command_style(nested, false, compact)

	if primary:
		primary.position = Vector2(82, 72) if compact else Vector2(102, 80)
		primary.custom_minimum_size = Vector2(126, 126) if compact else Vector2(170, 170)
		primary.size = primary.custom_minimum_size
		primary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		primary.add_theme_font_size_override("font_size", 11 if compact else 15)
		primary_style.call(primary)
		_apply_command_style(primary, true, compact)


static func refresh_ability_buttons(buttons: Dictionary, slots: Dictionary) -> void:
	for slot_id in buttons:
		var button := buttons[slot_id] as Button
		var slot_data := slots.get(slot_id, {}) as Dictionary
		var spell_name := String(slot_data.get("name", ""))
		var spell_icon := String(slot_data.get("icon", ""))
		var cost := int(slot_data.get("mana_cost", 0))
		if spell_name.is_empty():
			button.text = _slot_index_text(String(slot_id))
			button.tooltip_text = "Empty ability slot"
			button.set_meta("spell_id", "")
			button.set_meta("ability_empty", true)
			_set_ability_joystick_labels(button, _slot_index_text(String(slot_id)), "", true)
		else:
			button.text = "%s\n%d" % [_short_spell_label(spell_name), cost]
			button.tooltip_text = "Cast %s" % spell_name
			button.set_meta("spell_id", String(slot_data.get("spell_id", "")))
			button.set_meta("ability_empty", false)
			_set_ability_joystick_labels(button, _spell_icon(spell_icon, spell_name), str(cost), false)


static func _aim_joystick(
	text: String, action_kind: String, tooltip: String, size: Vector2, emit_press: bool
) -> RpgAimJoystick:
	var joystick := RpgAimJoystick.new()
	joystick.text = text
	joystick.center_label = text
	joystick.footer_label = ""
	joystick.use_text_as_footer = false
	joystick.custom_minimum_size = size
	joystick.action_id = action_kind
	joystick.emit_press_on_release = emit_press
	joystick.require_direction = true
	joystick.tooltip_text = tooltip
	joystick.focus_mode = Control.FOCUS_NONE
	joystick.set_meta("action_kind", action_kind)
	joystick.set_meta("action_role", "secondary")
	joystick.set_meta("action_shape", "round_secondary")
	return joystick


static func _utility_button(
	text: String, action_kind: String, tooltip: String, size: Vector2
) -> Button:
	var button := Button.new()
	button.name = "%sButton" % action_kind.to_pascal_case()
	button.text = text
	button.custom_minimum_size = size
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.set_meta("action_kind", action_kind)
	button.set_meta("action_role", "utility")
	button.set_meta("action_shape", "round_utility")
	return button


static func _slot_index_text(slot_id: String) -> String:
	return {"ability_1": "I", "ability_2": "II", "ability_3": "III"}.get(slot_id, "")


static func _short_spell_label(spell_name: String) -> String:
	var parts := spell_name.split(" ", false)
	return String(parts[0]) if not parts.is_empty() else spell_name


static func _spell_icon(icon: String, spell_name: String) -> String:
	if not icon.strip_edges().is_empty():
		return icon.strip_edges()
	var label := _short_spell_label(spell_name)
	return label.left(1).to_upper()


static func _set_ability_joystick_labels(
	button: Button, center_label: String, footer_label: String, empty_slot: bool
) -> void:
	if button is RpgAimJoystick:
		var joystick := button as RpgAimJoystick
		joystick.center_label = center_label
		joystick.footer_label = footer_label
		joystick.empty_slot = empty_slot


static func _apply_command_style(button: Button, primary: bool, compact: bool) -> void:
	if button is RpgAimJoystick:
		_apply_joystick_style(button as RpgAimJoystick, primary)
		return
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


static func _apply_joystick_style(button: RpgAimJoystick, primary: bool) -> void:
	button.set_meta("action_shape", "aim_joystick_primary" if primary else "aim_joystick_ability")
	button.add_theme_color_override("font_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_hover_color", Color.TRANSPARENT)
	button.add_theme_color_override("font_pressed_color", Color.TRANSPARENT)
	button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())


static func _apply_utility_style(button: Button, compact: bool) -> void:
	button.set_meta("action_shape", "round_utility")
	button.add_theme_color_override("font_color", Color(0.96, 0.90, 0.78))
	button.add_theme_stylebox_override(
		"normal",
		_round_style(
			Color(0.035, 0.032, 0.026, 0.94),
			Color(0.76, 0.62, 0.38, 0.72),
			22 if compact else 28
		)
	)
	button.add_theme_stylebox_override(
		"hover",
		_round_style(
			Color(0.10, 0.12, 0.075, 0.96),
			Color(0.86, 0.70, 0.42, 0.86),
			22 if compact else 28
		)
	)
	button.add_theme_stylebox_override(
		"pressed",
		_round_style(
			Color(0.16, 0.18, 0.09, 0.98),
			Color(1.0, 0.86, 0.48, 1.0),
			22 if compact else 28
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
