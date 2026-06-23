class_name RpgSystemsCharacterPaneBuilder
extends RefCounted

const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")
const RpgEquipmentSlot = preload("res://scripts/ui/rpg_equipment_slot.gd")
const RpgPortraitSilhouette = preload("res://scripts/ui/rpg_portrait_silhouette.gd")


static func build(
	panel: PanelContainer,
	new_label: Callable,
	new_button: Callable,
	add_margin: Callable,
	portrait_style: Callable
) -> Dictionary:
	var scroll := ScrollContainer.new()
	scroll.name = "SystemsCharacterScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_margin.call(panel, scroll, 12)

	var stack := VBoxContainer.new()
	stack.name = "SystemsCharacterStack"
	stack.add_theme_constant_override("separation", 8)
	stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(stack)

	var header := HBoxContainer.new()
	header.name = "SystemsCharacterHeader"
	header.add_theme_constant_override("separation", 8)
	stack.add_child(header)

	var portrait := Panel.new()
	portrait.name = "SystemsCharacterPortrait"
	portrait.custom_minimum_size = Vector2(52, 52)
	portrait_style.call(portrait)
	header.add_child(portrait)

	var portrait_label: Label = new_label.call(18)
	portrait_label.name = "SystemsCharacterPortraitInitials"
	portrait_label.text = ""
	portrait_label.visible = false
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.add_child(portrait_label)
	_add_portrait_art(portrait)

	var title_stack := VBoxContainer.new()
	title_stack.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_stack)

	var title: Label = new_label.call(17)
	title.name = "SystemsCharacterTitle"
	title.text = "Adventurer"
	title_stack.add_child(title)

	var subtitle: Label = new_label.call(12)
	subtitle.name = "SystemsCharacterSubtitle"
	subtitle.add_theme_color_override("font_color", Color(0.82, 0.74, 0.60))
	title_stack.add_child(subtitle)

	var health_bar := ProgressBar.new()
	health_bar.name = "SystemsCharacterHealthBar"
	health_bar.custom_minimum_size = Vector2(0, 12)
	health_bar.show_percentage = false
	_style_health_bar(health_bar)
	stack.add_child(health_bar)

	var equipment_grid := GridContainer.new()
	equipment_grid.name = "SystemsEquipmentSlots"
	equipment_grid.columns = 3
	equipment_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_grid.add_theme_constant_override("h_separation", 6)
	equipment_grid.add_theme_constant_override("v_separation", 6)
	stack.add_child(equipment_grid)

	var equipment_slots := _build_equipment_slots(equipment_grid)

	var rows := VBoxContainer.new()
	rows.name = "SystemsCharacterRows"
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 7)
	stack.add_child(rows)

	var hidden_label: Label = new_label.call(14)
	hidden_label.name = "SystemsCharacter"
	hidden_label.visible = false
	stack.add_child(hidden_label)

	return {
		"portrait_label": portrait_label,
		"subtitle": subtitle,
		"health_bar": health_bar,
		"equipment_grid": equipment_grid,
		"equipment_slots": equipment_slots,
		"scroll": scroll,
		"rows": rows,
		"hidden_label": hidden_label,
		"new_button": new_button
	}


static func _add_portrait_art(parent: Control) -> void:
	var art := RpgPortraitSilhouette.new()
	art.name = "SystemsCharacterPortraitSilhouette"
	art.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(art)


static func build_equipment_only(panel: PanelContainer, add_margin: Callable) -> Dictionary:
	var stack := VBoxContainer.new()
	stack.name = "SystemsDetailEquipmentStack"
	stack.add_theme_constant_override("separation", 5)
	add_margin.call(panel, stack, 8)

	var title := Label.new()
	title.name = "SystemsDetailEquipmentTitle"
	title.text = "Equipment"
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", Color(0.88, 0.72, 0.42, 0.95))
	stack.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.name = "SystemsDetailEquipmentScroll"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(scroll)

	var equipment_grid := GridContainer.new()
	equipment_grid.name = "SystemsDetailEquipmentSlots"
	equipment_grid.columns = 3
	equipment_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipment_grid.add_theme_constant_override("h_separation", 6)
	equipment_grid.add_theme_constant_override("v_separation", 6)
	scroll.add_child(equipment_grid)

	return {
		"equipment_grid": equipment_grid,
		"equipment_scroll": scroll,
		"equipment_slots": _build_equipment_slots(equipment_grid),
		"panel": panel,
		"detail_only": true
	}


static func refresh(
	nodes: Dictionary, state: Dictionary, row_style: Callable, compact := false
) -> void:
	var rows: VBoxContainer = nodes.get("rows")
	var health_bar: ProgressBar = nodes.get("health_bar")
	var subtitle: Label = nodes.get("subtitle")
	if subtitle:
		subtitle.text = String(state.get("progression", "Level 1"))
	_refresh_health_bar(health_bar, String(state.get("player_health", "Health 0/0")))
	_layout_equipment_grid(nodes, compact)
	_refresh_equipment_slots(nodes, state, row_style, compact)
	if not rows:
		return
	var rows_data := RpgSystemsTextBuilder.character_rows(state)
	for index in range(rows_data.size()):
		var row := rows_data[index]
		var button := _row_button(nodes, index)
		button.text = "%s\n%s" % [String(row.get("title", "")), String(row.get("value", ""))]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 58)
		button.add_theme_font_size_override("font_size", 13)
		row_style.call(button, false)
		button.visible = true
	for index in range(rows_data.size(), rows.get_child_count()):
		rows.get_child(index).visible = false


static func _row_button(nodes: Dictionary, index: int) -> Button:
	var rows: VBoxContainer = nodes.get("rows")
	if index < rows.get_child_count():
		var existing := rows.get_child(index)
		if existing is Button:
			return existing
	var new_button: Callable = nodes.get("new_button")
	var button := new_button.call("", Vector2(0, 58)) as Button
	button.name = "SystemsCharacterRow_%d" % index
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_child(button)
	return button


static func _build_equipment_slots(parent: GridContainer) -> Dictionary:
	var slots := {}
	var layout := [
		"", "head", "necklace",
		"left_hand", "chest", "right_hand",
		"ring_1", "legs", "ring_2",
		"gloves", "boots", "back"
	]
	for slot_id in layout:
		if slot_id.is_empty():
			var spacer := Control.new()
			spacer.custom_minimum_size = Vector2(0, 34)
			parent.add_child(spacer)
			continue
		var slot := RpgEquipmentSlot.new()
		slot.name = "EquipmentSlot_%s" % slot_id.to_pascal_case()
		slot.setup_slot(slot_id)
		slot.text = "%s\nEmpty" % EquipmentSlots.label(slot_id)
		slot.alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.custom_minimum_size = Vector2(0, 44)
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.focus_mode = Control.FOCUS_NONE
		parent.add_child(slot)
		slots[slot_id] = slot
	return slots


static func _refresh_equipment_slots(
	nodes: Dictionary, state: Dictionary, row_style: Callable, compact: bool
) -> void:
	var slots: Dictionary = nodes.get("equipment_slots", {})
	var data: Dictionary = state.get("equipment_slots", {})
	for slot_id in slots:
		var slot: RpgEquipmentSlot = slots[slot_id]
		var entry: Dictionary = data.get(slot_id, {})
		var label := String(entry.get("label", EquipmentSlots.label(slot_id)))
		var detail_only := bool(nodes.get("detail_only", false))
		var display_label := _slot_display_label(String(slot_id), label, compact or detail_only)
		var item_name := String(entry.get("item_name", ""))
		slot.text = "%s\n%s" % [display_label, "Empty" if item_name.is_empty() else item_name]
		slot.tooltip_text = "%s equipment slot" % label
		slot.custom_minimum_size = _equipment_slot_size(compact, detail_only)
		slot.add_theme_font_size_override("font_size", 10 if compact else 9 if detail_only else 11)
		row_style.call(slot, not item_name.is_empty())


static func _layout_equipment_grid(nodes: Dictionary, compact: bool) -> void:
	var grid := nodes.get("equipment_grid") as GridContainer
	if not grid:
		return
	grid.columns = 2 if compact else 3
	grid.add_theme_constant_override("h_separation", 5 if compact else 4)
	grid.add_theme_constant_override("v_separation", 5 if compact else 4)


static func _equipment_slot_size(compact: bool, detail_only: bool) -> Vector2:
	if compact:
		return Vector2(72, 52)
	if detail_only:
		return Vector2(0, 38)
	return Vector2(0, 44)


static func _slot_display_label(slot_id: String, fallback: String, compact: bool) -> String:
	if not compact:
		return fallback
	match EquipmentSlots.normalize(slot_id):
		"left_hand":
			return "L Hand"
		"right_hand":
			return "R Hand"
		"necklace":
			return "Neck"
		"ring_1":
			return "Ring 1"
		"ring_2":
			return "Ring 2"
	return fallback


static func _refresh_health_bar(health_bar: ProgressBar, health_text: String) -> void:
	if not health_bar:
		return
	var values := _health_values(health_text)
	health_bar.max_value = values.y
	health_bar.value = values.x
	health_bar.tooltip_text = "Health: %d/%d" % [int(values.x), int(values.y)]


static func _style_health_bar(health_bar: ProgressBar) -> void:
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.02, 0.018, 0.014, 0.92)
	background.border_color = Color(0.86, 0.78, 0.58, 0.38)
	background.set_border_width_all(1)
	background.corner_radius_top_left = 3
	background.corner_radius_top_right = 3
	background.corner_radius_bottom_left = 3
	background.corner_radius_bottom_right = 3
	health_bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.64, 0.08, 0.06, 0.96)
	fill.border_color = Color(0.96, 0.74, 0.42, 0.55)
	fill.set_border_width_all(1)
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	health_bar.add_theme_stylebox_override("fill", fill)


static func _health_values(text: String) -> Vector2:
	var marker := text.rfind(" ")
	var value_text := text.substr(marker + 1) if marker >= 0 else text
	var parts := value_text.split("/", false)
	if parts.size() != 2:
		return Vector2(0, 1)
	return Vector2(maxf(0.0, float(parts[0])), maxf(1.0, float(parts[1])))
