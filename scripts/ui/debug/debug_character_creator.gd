# gdlint:disable=max-file-lines
class_name DebugCharacterCreator
extends CanvasLayer

signal appearance_applied(profile: Dictionary)

const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")

const PEOPLE_IDS := [
	"people_human",
	"people_tanglekin",
	"people_tuskfolk",
	"people_mirefolk",
	"people_ravenfolk",
	"people_rootborn"
]
const GEAR_PRESETS := [
	{"id": "none", "label": "No gear", "equipped": {}},
	{"id": "apron", "label": "Smith apron", "equipped": {"chest": "item_smith_apron"}},
	{"id": "sword", "label": "Sword", "equipped": {"right_hand": "item_training_sword"}},
	{
		"id": "sword_buckler",
		"label": "Sword + buckler",
		"equipped": {"right_hand": "item_training_sword", "left_hand": "item_traveler_buckler"}
	},
	{"id": "bow", "label": "Bow", "equipped": {"right_hand": "item_hunting_bow"}}
]

var content
var player
var root: Control
var panel: PanelContainer
var people_label: Label
var variant_label: Label
var seed_edit: LineEdit
var jitter_check: CheckBox
var gear_label: Label
var facing_label: Label
var message_label: Label
var preview_area: Control
var preview_avatar: HumanoidAvatar2D
var current_people_index := 0
var current_variant_index := 0
var current_gear_index := 0
var current_facing_index := 0


func setup(content_database, player_node) -> void:
	content = content_database
	player = player_node
	layer = 80
	_build_ui()
	set_open(false)
	_refresh_all()


func is_open() -> bool:
	return root and root.visible


func set_open(value: bool) -> void:
	if root:
		root.visible = value
		if value:
			_refresh_all()


func toggle_open() -> void:
	set_open(not is_open())


func get_current_people_id() -> String:
	return PEOPLE_IDS[current_people_index]


func get_current_variant_id() -> String:
	var ids := _variant_ids()
	if current_variant_index <= 0 or current_variant_index > ids.size():
		return ""
	return ids[current_variant_index - 1]


func get_current_gear_id() -> String:
	var preset: Dictionary = GEAR_PRESETS[current_gear_index]
	return String(preset.get("id", ""))


func select_people(people_id: String) -> bool:
	var index := PEOPLE_IDS.find(people_id)
	if index < 0:
		return false
	current_people_index = index
	current_variant_index = 0
	_refresh_all()
	return true


func select_variant(variant_id: String) -> bool:
	if variant_id.is_empty():
		current_variant_index = 0
		_refresh_all()
		return true
	var ids := _variant_ids()
	var index := ids.find(variant_id)
	if index < 0:
		return false
	current_variant_index = index + 1
	_refresh_all()
	return true


func apply_to_player() -> bool:
	if not player or not player.has_method("set_humanoid_profile"):
		return false
	var profile := _current_profile()
	profile["character_id"] = "char_player"
	profile["inventory_owner_id"] = "char_player"
	profile["equipment_owner_id"] = "char_player"
	profile["spellbook_owner_id"] = "char_player"
	profile["loadout_id"] = "loadout_player"
	var existing: Dictionary = player.humanoid_profile if player.humanoid_profile is Dictionary else {}
	for field_id in ["faction_id", "state", "level", "stats", "derived_bonuses", "corpse_entity_id"]:
		if existing.has(field_id):
			profile[field_id] = existing[field_id]
	player.set_humanoid_profile(profile)
	message_label.text = "Applied to player."
	appearance_applied.emit(profile)
	return true


func _build_ui() -> void:
	root = Control.new()
	root.name = "DebugCharacterCreatorRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var shade := ColorRect.new()
	shade.name = "DebugCharacterCreatorShade"
	shade.color = Color(0.0, 0.0, 0.0, 0.20)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)

	panel = PanelContainer.new()
	panel.name = "DebugCharacterCreatorPanel"
	panel.position = Vector2(24.0, 44.0)
	panel.custom_minimum_size = Vector2(430.0, 560.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 8)
	margin.add_child(rows)

	var title := Label.new()
	title.text = "Debug Character Creator (P)"
	title.add_theme_font_size_override("font_size", 20)
	rows.add_child(title)

	people_label = _value_label()
	rows.add_child(
		_stepper_row(
			"People",
			people_label,
			"CreatorPrevPeopleButton",
			"CreatorNextPeopleButton",
			func() -> void: _cycle_people(-1),
			func() -> void: _cycle_people(1)
		)
	)

	variant_label = _value_label()
	rows.add_child(
		_stepper_row(
			"Variant",
			variant_label,
			"CreatorPrevVariantButton",
			"CreatorNextVariantButton",
			func() -> void: _cycle_variant(-1),
			func() -> void: _cycle_variant(1)
		)
	)

	var seed_row := HBoxContainer.new()
	seed_row.add_theme_constant_override("separation", 8)
	var seed_title := Label.new()
	seed_title.text = "Seed"
	seed_title.custom_minimum_size = Vector2(72.0, 0.0)
	seed_row.add_child(seed_title)
	seed_edit = LineEdit.new()
	seed_edit.name = "CreatorSeedEdit"
	seed_edit.text = "debug"
	seed_edit.custom_minimum_size = Vector2(180.0, 34.0)
	seed_edit.text_changed.connect(func(_text: String) -> void: _refresh_preview())
	seed_row.add_child(seed_edit)
	jitter_check = CheckBox.new()
	jitter_check.name = "CreatorJitterCheck"
	jitter_check.text = "Jitter"
	jitter_check.toggled.connect(func(_value: bool) -> void: _refresh_preview())
	seed_row.add_child(jitter_check)
	rows.add_child(seed_row)

	gear_label = _value_label()
	rows.add_child(
		_stepper_row(
			"Gear",
			gear_label,
			"CreatorPrevGearButton",
			"CreatorNextGearButton",
			func() -> void: _cycle_gear(-1),
			func() -> void: _cycle_gear(1)
		)
	)

	facing_label = _value_label()
	rows.add_child(
		_stepper_row(
			"Facing",
			facing_label,
			"CreatorPrevFacingButton",
			"CreatorNextFacingButton",
			func() -> void: _cycle_facing(-1),
			func() -> void: _cycle_facing(1)
		)
	)

	preview_area = PanelContainer.new()
	preview_area.name = "CreatorPreviewArea"
	preview_area.custom_minimum_size = Vector2(390.0, 230.0)
	preview_area.add_theme_stylebox_override("panel", _preview_style())
	rows.add_child(preview_area)

	preview_avatar = HumanoidAvatar2D.new()
	preview_avatar.name = "CreatorPreviewAvatar"
	preview_avatar.position = Vector2(195.0, 160.0)
	preview_avatar.scale = Vector2(3.0, 3.0)
	preview_area.add_child(preview_avatar)

	message_label = Label.new()
	message_label.name = "CreatorMessageLabel"
	message_label.text = ""
	rows.add_child(message_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	actions.add_child(_button("Apply", "CreatorApplyButton", func() -> void: apply_to_player()))
	actions.add_child(_button("Close", "CreatorCloseButton", func() -> void: set_open(false)))
	rows.add_child(actions)


func _stepper_row(
	title_text: String,
	value_label: Label,
	prev_name: String,
	next_name: String,
	prev_callback: Callable,
	next_callback: Callable
) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = title_text
	title.custom_minimum_size = Vector2(72.0, 0.0)
	row.add_child(title)
	row.add_child(_button("<", prev_name, prev_callback))
	value_label.custom_minimum_size = Vector2(196.0, 0.0)
	row.add_child(value_label)
	row.add_child(_button(">", next_name, next_callback))
	return row


func _button(text: String, node_name: String, callback: Callable) -> Button:
	var button := Button.new()
	button.name = node_name
	button.text = text
	button.custom_minimum_size = Vector2(58.0, 34.0)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button


func _value_label() -> Label:
	var label := Label.new()
	label.clip_text = true
	return label


func _cycle_people(step: int) -> void:
	current_people_index = posmod(current_people_index + step, PEOPLE_IDS.size())
	current_variant_index = 0
	message_label.text = ""
	_refresh_all()


func _cycle_variant(step: int) -> void:
	current_variant_index = posmod(current_variant_index + step, _variant_count())
	message_label.text = ""
	_refresh_all()


func _cycle_gear(step: int) -> void:
	current_gear_index = posmod(current_gear_index + step, GEAR_PRESETS.size())
	message_label.text = ""
	_refresh_all()


func _cycle_facing(step: int) -> void:
	current_facing_index = posmod(
		current_facing_index + step, preview_avatar.get_facing_bucket_count()
	)
	_refresh_preview()


func _refresh_all() -> void:
	if not root:
		return
	people_label.text = _people_display_name(get_current_people_id())
	variant_label.text = _variant_display_name()
	var preset: Dictionary = GEAR_PRESETS[current_gear_index]
	gear_label.text = String(preset.get("label", ""))
	_refresh_preview()


func _refresh_preview() -> void:
	if not preview_avatar:
		return
	var profile := _current_profile()
	preview_avatar.set_profile(profile)
	preview_avatar.set_equipped_items(_current_gear(), content)
	preview_avatar.set_facing_direction(_facing_direction())
	facing_label.text = preview_avatar.get_facing_bucket_id()


func _current_profile() -> Dictionary:
	var people_id := get_current_people_id()
	var options := {}
	var variant_id := get_current_variant_id()
	if not variant_id.is_empty():
		options["variant_id"] = variant_id
	if jitter_check and jitter_check.button_pressed:
		options["proportion_jitter"] = true
		options["jitter_strength"] = 0.03
	var seed := "debug"
	if seed_edit and not seed_edit.text.strip_edges().is_empty():
		seed = seed_edit.text.strip_edges()
	return content.get_generated_people_profile(people_id, "debug_creator_preview", seed, options)


func _current_gear() -> Dictionary:
	var preset: Dictionary = GEAR_PRESETS[current_gear_index]
	return Dictionary(preset.get("equipped", {})).duplicate(true)


func _variant_ids() -> Array[String]:
	var result: Array[String] = []
	if not content:
		return result
	var model: Dictionary = content.get_people_visual_model(get_current_people_id())
	for variant_value in Array(model.get("variants", [])):
		if variant_value is Dictionary:
			var variant_id := String(variant_value.get("id", ""))
			if not variant_id.is_empty():
				result.append(variant_id)
	return result


func _variant_count() -> int:
	return maxi(1, _variant_ids().size() + 1)


func _variant_display_name() -> String:
	var variant_id := get_current_variant_id()
	if variant_id.is_empty():
		return "Seeded: %s" % (seed_edit.text if seed_edit else "debug")
	var variant: Dictionary = content.get_people_visual_variant(get_current_people_id(), variant_id)
	return String(variant.get("display_name", variant_id))


func _people_display_name(people_id: String) -> String:
	if content:
		var definition: Dictionary = content.get_people(people_id)
		if definition.has("display_name"):
			return String(definition.get("display_name", people_id))
	return people_id


func _facing_direction() -> Vector2:
	var count: int = preview_avatar.get_facing_bucket_count() if preview_avatar else 16
	var angle := PI * 0.5 + TAU * float(current_facing_index) / float(count)
	return Vector2.from_angle(angle)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.02, 0.018, 0.94)
	style.border_color = Color(0.92, 0.70, 0.28, 0.86)
	style.set_border_width_all(2)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style


func _preview_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.06, 0.86)
	style.border_color = Color(0.92, 0.70, 0.28, 0.45)
	style.set_border_width_all(1)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	return style
