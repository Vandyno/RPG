class_name RpgTransferPaneBuilder
extends RefCounted

const RpgTransferItemButton = preload(
	"res://scripts/ui/controls/buttons/rpg_transfer_item_button.gd"
)
const SystemsTabState = preload("res://scripts/ui/systems/systems_tab_state.gd")


class RefreshRequest:
	var container: BoxContainer
	var state: Dictionary
	var category: String
	var action_selected: Callable
	var compact: bool


static func refresh(request: RefreshRequest) -> void:
	if not request or not request.container:
		return
	_clear_children(request.container)
	var inventory_tab := SystemsTabState.inventory(request.state)
	var transfer: Dictionary = inventory_tab.get("transfer", {})
	var target: Dictionary = transfer.get("target", {})
	var target_name := String(target.get("name", "Container"))
	var target_short := "Body" if target_name.ends_with(" Body") else "Target"
	var panes: BoxContainer = VBoxContainer.new() if request.compact else HBoxContainer.new()
	panes.name = "TransferInventoryPanes"
	panes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panes.custom_minimum_size = Vector2(0, 300 if request.compact else 360)
	panes.add_theme_constant_override("separation", 10)
	request.container.add_child(panes)
	_add_side(
		panes, "TransferPlayerInventory", "Your Inventory",
		_array_field(transfer.get("player_items", [])), "put", target_short,
		request.category, request.action_selected
	)
	_add_side(
		panes, "TransferTargetInventory", target_name,
		_array_field(transfer.get("target_items", [])), "take", "Pack",
		request.category, request.action_selected
	)


static func _add_side(
	parent: BoxContainer,
	node_name: String,
	title: String,
	items: Array,
	action: String,
	other_side: String,
	category: String,
	action_selected: Callable
) -> void:
	var panel := PanelContainer.new()
	panel.name = node_name
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(0, 168)
	panel.add_theme_stylebox_override("panel", _panel_style())
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	_add_margin(panel, stack, 10)
	var heading := Label.new()
	heading.name = "%sTitle" % node_name
	heading.text = title
	heading.add_theme_font_size_override("font_size", 17)
	heading.add_theme_color_override("font_color", Color(0.98, 0.92, 0.78))
	stack.add_child(heading)
	var added := false
	for item in items:
		if item is Dictionary and _matches_category(item, category):
			_add_item_button(stack, item, action, other_side, action_selected)
			added = true
	if not added:
		var empty := Label.new()
		empty.name = "%sEmpty" % node_name
		empty.text = "Nothing here."
		empty.add_theme_color_override("font_color", Color(0.82, 0.74, 0.60))
		stack.add_child(empty)


static func _add_item_button(
	parent: BoxContainer,
	item: Dictionary,
	action: String,
	other_side: String,
	action_selected: Callable
) -> void:
	var item_id := String(item.get("item_id", ""))
	var item_name := String(item.get("name", item_id))
	var count := maxi(0, int(item.get("count", 0)))
	if item_id.is_empty() or count <= 0:
		return
	var verb := "Take" if action == "take" else "Put"
	var action_id := "%s:%s" % [action, item_id]
	var button := RpgTransferItemButton.new()
	button.name = "Transfer%s_%s" % [verb, item_id.to_pascal_case()]
	button.tooltip_text = "%s %s" % [verb, item_name]
	button.custom_minimum_size = Vector2(0, 74)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.set_meta("action_id", action_id)
	button.set_transfer_data(item, verb, other_side)
	button.pressed.connect(func() -> void: action_selected.call(action_id), CONNECT_DEFERRED)
	parent.add_child(button)


static func _item_meta(item: Dictionary, other_side: String) -> String:
	var parts: Array[String] = []
	var weight := maxf(0.0, float(item.get("weight", 0.0)))
	var value := maxi(0, int(item.get("value", 0)))
	if weight > 0.0:
		parts.append("%.1f wt" % weight)
	if value > 0:
		parts.append("%dg" % value)
	parts.append("to %s" % other_side)
	return "   ".join(parts)


static func _matches_category(item: Dictionary, category: String) -> bool:
	if category.is_empty() or category == "all":
		return true
	var item_type := String(item.get("type", ""))
	var tags := _array_field(item.get("tags", []))
	match category:
		"weapons":
			return item_type == "weapon" or tags.has("weapon")
		"armour":
			return tags.has("armour") or tags.has("armor")
		"ingredients":
			return item_type == "ingredient" or tags.has("ingredient")
		"quest":
			return item_type == "quest_item" or tags.has("quest")
		"misc":
			return not (
				item_type == "weapon"
				or item_type == "ingredient"
				or item_type == "quest_item"
				or tags.has("weapon")
				or tags.has("armour")
				or tags.has("armor")
				or tags.has("ingredient")
				or tags.has("quest")
			)
	return true


static func _add_margin(parent: PanelContainer, child: Control, value: int) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", value)
	margin.add_theme_constant_override("margin_top", value)
	margin.add_theme_constant_override("margin_right", value)
	margin.add_theme_constant_override("margin_bottom", value)
	parent.add_child(margin)
	margin.add_child(child)


static func _clear_children(container: Node) -> void:
	for index in range(container.get_child_count() - 1, -1, -1):
		var child := container.get_child(index)
		container.remove_child(child)
		child.free()


static func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.023, 0.018, 0.94)
	style.border_color = Color(0.72, 0.56, 0.32, 0.78)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


static func _row_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.032, 0.026, 0.94)
	style.border_color = Color(0.66, 0.50, 0.28, 0.72)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


static func _action_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.13, 0.075, 0.98) if selected else Color(0.10, 0.09, 0.06, 0.98)
	style.border_color = Color(0.96, 0.78, 0.42, 0.92)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
