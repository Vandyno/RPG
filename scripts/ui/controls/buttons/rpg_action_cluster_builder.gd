class_name RpgActionClusterBuilder
extends RefCounted

const RpgAimJoystick = preload("res://scripts/ui/controls/input/rpg_aim_joystick.gd")
const RpgIconButton = preload("res://scripts/ui/controls/buttons/rpg_icon_button.gd")
const SpellSlots = preload("res://scripts/core/spell_slots.gd")


class BuildContext:
	var root: Control
	var aim_action: Callable
	var held_action: Callable


class LayoutRequest:
	var cluster: Control
	var primary: Button
	var compact: bool
	var primary_style: Callable


static func build(context: BuildContext) -> Dictionary:
	if not context or not context.root:
		return {}
	var cluster := Control.new()
	cluster.name = "CombatJoystickCluster"
	cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cluster.anchor_left = 1.0
	cluster.anchor_right = 1.0
	cluster.anchor_top = 1.0
	cluster.anchor_bottom = 1.0
	cluster.offset_left = -300
	cluster.offset_top = -252
	cluster.offset_right = -12
	cluster.offset_bottom = -12
	context.root.add_child(cluster)

	var utility_row := HBoxContainer.new()
	utility_row.name = "UtilityButtonStack"
	utility_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	utility_row.alignment = BoxContainer.ALIGNMENT_END
	utility_row.add_theme_constant_override("separation", 6)
	cluster.add_child(utility_row)

	var utility_buttons := {}
	for data in [
		{"id": "weapon_swap", "text": "Swap", "tooltip": "Equip last main hand weapon"},
		{"id": "sneak", "text": "Sneak", "tooltip": "Toggle sneak"},
		{"id": "menu", "text": "Menu", "tooltip": "Open systems menu"}
	]:
		var utility := _utility_button(
			String(data["text"]), String(data["id"]), String(data["tooltip"]), Vector2(56, 56)
		)
		utility_row.add_child(utility)
		utility_buttons[String(data["id"])] = utility

	var ability_stack := Control.new()
	ability_stack.name = "AbilityButtonStack"
	ability_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cluster.add_child(ability_stack)

	var ability_buttons := {}
	for slot_id in SpellSlots.SLOTS:
		var ability := _aim_joystick(
			_slot_index_text(slot_id), slot_id, "Assigned spell", Vector2(56, 56), false
		)
		ability.name = "%sButton" % slot_id.to_pascal_case()
		ability.set_meta("ability_slot", slot_id)
		if context.aim_action.is_valid():
			ability.aimed.connect(context.aim_action)
		if context.held_action.is_valid():
			ability.aim_held.connect(context.held_action)
		ability_stack.add_child(ability)
		ability_buttons[slot_id] = ability

	var primary := _aim_joystick("Attack", "attack", "Aim attack", Vector2(156, 156), false)
	primary.name = "InteractButton"
	primary.set_meta("action_role", "primary")
	primary.center_label = ""
	primary.footer_label = "Attack"
	if context.aim_action.is_valid():
		primary.aimed.connect(context.aim_action)
	if context.held_action.is_valid():
		primary.aim_held.connect(context.held_action)
	cluster.add_child(primary)

	return {
		"cluster": cluster,
		"ability_buttons": ability_buttons,
		"utility_buttons": utility_buttons,
		"primary": primary
	}


static func apply_layout(request: LayoutRequest) -> void:
	if not request:
		return
	var cluster := request.cluster
	if not cluster:
		return
	var compact := request.compact
	var cluster_size := Vector2(218, 176) if compact else Vector2(284, 228)
	cluster.offset_left = -cluster_size.x - 12
	cluster.offset_top = -cluster_size.y - 12
	cluster.offset_right = -12
	cluster.offset_bottom = -12
	cluster.custom_minimum_size = cluster_size
	cluster.size = cluster_size

	var utility_row := cluster.find_child("UtilityButtonStack", true, false) as HBoxContainer
	if utility_row:
		utility_row.position = Vector2(72, 0) if compact else Vector2(96, 0)
		utility_row.size = Vector2(146, 38) if compact else Vector2(188, 48)
		utility_row.add_theme_constant_override("separation", 5 if compact else 6)
		for nested in utility_row.get_children():
			if nested is Button:
				nested.custom_minimum_size = Vector2(42, 36) if compact else Vector2(56, 48)
				nested.size = nested.custom_minimum_size
				nested.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				nested.add_theme_font_size_override("font_size", 8 if compact else 10)
				_apply_utility_style(nested, compact)
				if nested is RpgIconButton:
					var icon := String(nested.get_meta("action_kind", ""))
					(nested as RpgIconButton).set_compact(compact)
					(nested as RpgIconButton).setup_icon(icon, "top")

	var ability_stack := cluster.find_child("AbilityButtonStack", true, false) as Control
	if ability_stack:
		ability_stack.position = Vector2.ZERO
		ability_stack.size = cluster_size
		var ability_positions := (
			[Vector2(32, 32), Vector2(8, 84), Vector2(32, 128)]
			if compact
			else [Vector2(44, 48), Vector2(16, 112), Vector2(44, 170)]
		)
		var index := 0
		for nested in ability_stack.get_children():
			if nested is Button:
				nested.custom_minimum_size = Vector2(46, 46) if compact else Vector2(58, 58)
				nested.size = nested.custom_minimum_size
				if index < ability_positions.size():
					nested.position = ability_positions[index]
				index += 1
				nested.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
				nested.add_theme_font_size_override("font_size", 8 if compact else 10)
				_apply_command_style(nested, false, compact)

	if request.primary:
		request.primary.position = Vector2(78, 40) if compact else Vector2(102, 58)
		request.primary.custom_minimum_size = Vector2(136, 136) if compact else Vector2(170, 170)
		request.primary.size = request.primary.custom_minimum_size
		request.primary.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		request.primary.add_theme_font_size_override("font_size", 11 if compact else 15)
		request.primary_style.call(request.primary)
		_apply_command_style(request.primary, true, compact)


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
	joystick.show_direction_markers = true
	joystick.tooltip_text = tooltip
	joystick.focus_mode = Control.FOCUS_NONE
	joystick.set_meta("action_kind", action_kind)
	joystick.set_meta("action_role", "secondary")
	joystick.set_meta("action_input", "aim_drag")
	joystick.set_meta("action_shape", "aim_joystick_ability")
	return joystick


static func _utility_button(
	text: String, action_kind: String, tooltip: String, size: Vector2
) -> Button:
	var button := RpgIconButton.new()
	button.name = "%sButton" % action_kind.to_pascal_case()
	button.text = text
	button.custom_minimum_size = size
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	button.setup_icon(action_kind, "top")
	button.set_meta("action_kind", action_kind)
	button.set_meta("action_role", "utility")
	button.set_meta("action_shape", "round_utility")
	return button


static func _slot_index_text(slot_id: String) -> String:
	return SpellSlots.short_label(slot_id)


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
