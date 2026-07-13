# gdlint:disable=max-file-lines
class_name DebugCharacterCreator
extends CanvasLayer

signal appearance_applied(profile: Dictionary)
signal creation_confirmed(profile: Dictionary)
signal creation_cancelled

const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")
const HumanoidFacePartLibrary = preload(
	"res://scripts/characters/humanoid_face_part_library.gd"
)

const PEOPLE_IDS := [
	"people_human",
	"people_tanglekin",
	"people_tuskfolk",
	"people_mirefolk",
	"people_ravenfolk",
	"people_rootborn"
]
const FACE_DETAIL_PART_IDS := ["brows", "noses", "mouths", "facial_marks"]
const BODY_PART_IDS := [
	"body_height", "shoulder_width", "torso_width", "waist_width", "head_size",
	"hand_size", "foot_size"
]
const BODY_SCALE_VALUES := [0.80, 0.90, 1.00, 1.10, 1.20]
const HUMAN_HAIR_IDS := [
	"hair_short_waves", "hair_close_crop", "hair_side_part", "hair_tied_back",
	"hair_wide_curls", "hair_shaved_crown"
]
const PEOPLE_STYLE_OPTIONS := {
	"people_tanglekin": ["Plain brow", "Brow tuft"],
	"people_tuskfolk": ["Broad tusks", "Small tusks"],
	"people_mirefolk": ["Dry hands", "Webbed hands"],
	"people_ravenfolk": ["Low crest", "High crest"],
	"people_rootborn": ["Leaf crown", "Branch crown"]
}
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
var eye_label: Label
var face_part_label: Label
var face_value_label: Label
var body_part_label: Label
var body_value_label: Label
var style_label: Label
var seed_edit: LineEdit
var jitter_check: CheckBox
var gear_label: Label
var facing_label: Label
var message_label: Label
var preview_area: Control
var preview_avatar: HumanoidAvatar2D
var advanced_rows: Array[Control] = []
var gear_row: Control
var player_facing_mode := false
var onboarding_mode := false
var apply_button: Button
var current_people_index := 0
var current_variant_index := 0
var current_eye_index := 0
var current_face_part_index := 0
var face_value_indices: Dictionary = {}
var current_body_part_index := 0
var body_overrides: Dictionary = {}
var current_style_index := 0
var current_gear_index := 0
var current_facing_index := 0
var public_preview_equipment: Dictionary = {}


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
	player_facing_mode = false
	onboarding_mode = false
	set_open(not is_open())


func open_character_appearance() -> void:
	player_facing_mode = true
	onboarding_mode = false
	_sync_from_player_profile()
	set_open(true)


func set_public_preview_equipment(equipped_by_slot: Dictionary) -> void:
	public_preview_equipment = equipped_by_slot.duplicate(true)
	_refresh_preview()


func begin_new_character() -> void:
	player_facing_mode = true
	onboarding_mode = true
	current_people_index = 0
	current_variant_index = 0
	current_eye_index = 0
	current_face_part_index = 0
	face_value_indices.clear()
	current_body_part_index = 0
	body_overrides.clear()
	current_style_index = 0
	current_gear_index = 0
	public_preview_equipment.clear()
	set_open(true)


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


func get_current_eye_id() -> String:
	var eye_ids := _eye_ids()
	if eye_ids.is_empty():
		return ""
	return eye_ids[posmod(current_eye_index, eye_ids.size())]


func get_current_face_part_id() -> String:
	return FACE_DETAIL_PART_IDS[current_face_part_index]


func get_current_face_value_id() -> String:
	var ids := _face_value_ids(get_current_face_part_id())
	if ids.is_empty():
		return ""
	var index := int(face_value_indices.get(get_current_face_part_id(), -1))
	if index < 0:
		return HumanoidFacePartLibrary.default_id(
			get_current_people_id(), get_current_face_part_id()
		)
	return ids[posmod(index, ids.size())]


func select_people(people_id: String) -> bool:
	var index := PEOPLE_IDS.find(people_id)
	if index < 0:
		return false
	current_people_index = index
	current_variant_index = 0
	current_eye_index = 0
	current_face_part_index = 0
	face_value_indices.clear()
	current_body_part_index = 0
	body_overrides.clear()
	current_style_index = 0
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
	message_label.text = "Character ready." if onboarding_mode else "Applied to player."
	appearance_applied.emit(profile)
	if onboarding_mode:
		set_open(false)
		creation_confirmed.emit(profile)
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
	panel.position = Vector2(24.0, 12.0)
	panel.custom_minimum_size = Vector2(430.0, 620.0)
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
	title.text = "Character Appearance"
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

	eye_label = _value_label()
	rows.add_child(
		_stepper_row(
			"Eyes",
			eye_label,
			"CreatorPrevEyesButton",
			"CreatorNextEyesButton",
			func() -> void: _cycle_eyes(-1),
			func() -> void: _cycle_eyes(1)
		)
	)

	face_part_label = _value_label()
	rows.add_child(
		_stepper_row(
			"Face part",
			face_part_label,
			"CreatorPrevFacePartButton",
			"CreatorNextFacePartButton",
			func() -> void: _cycle_face_part(-1),
			func() -> void: _cycle_face_part(1)
		)
	)

	face_value_label = _value_label()
	rows.add_child(
		_stepper_row(
			"Face value",
			face_value_label,
			"CreatorPrevFaceValueButton",
			"CreatorNextFaceValueButton",
			func() -> void: _cycle_face_value(-1),
			func() -> void: _cycle_face_value(1)
		)
	)

	body_part_label = _value_label()
	rows.add_child(
		_stepper_row(
			"Body part",
			body_part_label,
			"CreatorPrevBodyPartButton",
			"CreatorNextBodyPartButton",
			func() -> void: _cycle_body_part(-1),
			func() -> void: _cycle_body_part(1)
		)
	)

	body_value_label = _value_label()
	rows.add_child(
		_stepper_row(
			"Body value",
			body_value_label,
			"CreatorPrevBodyValueButton",
			"CreatorNextBodyValueButton",
			func() -> void: _cycle_body_value(-1),
			func() -> void: _cycle_body_value(1)
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

	style_label = _value_label()
	rows.add_child(
		_stepper_row(
			"Style",
			style_label,
			"CreatorPrevStyleButton",
			"CreatorNextStyleButton",
			func() -> void: _cycle_style(-1),
			func() -> void: _cycle_style(1)
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
	advanced_rows.append(seed_row)

	gear_label = _value_label()
	gear_row = _stepper_row(
		"Gear",
		gear_label,
		"CreatorPrevGearButton",
		"CreatorNextGearButton",
		func() -> void: _cycle_gear(-1),
		func() -> void: _cycle_gear(1)
	)
	rows.add_child(gear_row)

	facing_label = _value_label()
	var facing_row := _stepper_row(
		"Facing",
		facing_label,
		"CreatorPrevFacingButton",
		"CreatorNextFacingButton",
		func() -> void: _cycle_facing(-1),
		func() -> void: _cycle_facing(1)
	)
	rows.add_child(facing_row)
	advanced_rows.append(facing_row)

	preview_area = PanelContainer.new()
	preview_area.name = "CreatorPreviewArea"
	preview_area.custom_minimum_size = Vector2(390.0, 130.0)
	preview_area.add_theme_stylebox_override("panel", _preview_style())
	rows.add_child(preview_area)

	preview_avatar = HumanoidAvatar2D.new()
	preview_avatar.name = "CreatorPreviewAvatar"
	preview_avatar.position = Vector2(195.0, 96.0)
	preview_avatar.scale = Vector2(3.0, 3.0)
	preview_area.add_child(preview_avatar)

	message_label = Label.new()
	message_label.name = "CreatorMessageLabel"
	message_label.text = ""
	rows.add_child(message_label)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	apply_button = _button("Apply", "CreatorApplyButton", func() -> void: apply_to_player())
	actions.add_child(apply_button)
	actions.add_child(_button("Close", "CreatorCloseButton", _close_pressed))
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
	current_eye_index = 0
	current_face_part_index = 0
	face_value_indices.clear()
	message_label.text = ""
	_refresh_all()


func _sync_from_player_profile() -> void:
	if not player:
		return
	var profile: Variant = player.get("humanoid_profile")
	if not profile is Dictionary:
		return
	var people_id := String(profile.get("people_id", ""))
	var people_index := PEOPLE_IDS.find(people_id)
	if people_index < 0:
		return
	current_people_index = people_index
	current_variant_index = 0
	current_eye_index = 0
	current_face_part_index = 0
	face_value_indices.clear()
	var appearance: Dictionary = profile.get("appearance", {})
	var variant_id := String(appearance.get("visual_model_id", ""))
	var variant_index := _variant_ids().find(variant_id)
	if variant_index >= 0:
		current_variant_index = variant_index + 1
	var eye_id := HumanoidFacePartLibrary.resolve_id(
		people_id, "eyes", String(appearance.get("eye_id", ""))
	)
	var eye_index := _eye_ids().find(eye_id)
	if eye_index >= 0:
		current_eye_index = eye_index
	for part_id in FACE_DETAIL_PART_IDS:
		var field_id := _appearance_field_for_face_part(part_id)
		var part_value := HumanoidFacePartLibrary.resolve_id(
			people_id, part_id, String(appearance.get(field_id, ""))
		)
		var part_index := _face_value_ids(part_id).find(part_value)
		if part_index >= 0:
			face_value_indices[part_id] = part_index
	body_overrides.clear()
	var proportions: Dictionary = appearance.get("proportions", {})
	for field_id in BODY_PART_IDS:
		if proportions.has(field_id):
			body_overrides[field_id] = float(proportions[field_id])
	current_style_index = _style_index_for_appearance(appearance)


func _cycle_variant(step: int) -> void:
	current_variant_index = posmod(current_variant_index + step, _variant_count())
	message_label.text = ""
	_refresh_all()


func _cycle_eyes(step: int) -> void:
	var eye_ids := _eye_ids()
	if eye_ids.is_empty():
		return
	current_eye_index = posmod(current_eye_index + step, eye_ids.size())
	message_label.text = ""
	_refresh_all()


func _cycle_face_part(step: int) -> void:
	current_face_part_index = posmod(current_face_part_index + step, FACE_DETAIL_PART_IDS.size())
	message_label.text = ""
	_refresh_all()


func _cycle_face_value(step: int) -> void:
	var part_id := get_current_face_part_id()
	var ids := _face_value_ids(part_id)
	if ids.is_empty():
		return
	var current_index := int(face_value_indices.get(part_id, -1))
	if current_index < 0:
		current_index = ids.find(
			HumanoidFacePartLibrary.default_id(get_current_people_id(), part_id)
		)
	face_value_indices[part_id] = posmod(current_index + step, ids.size())
	message_label.text = ""
	_refresh_all()


func _cycle_body_part(step: int) -> void:
	current_body_part_index = posmod(current_body_part_index + step, BODY_PART_IDS.size())
	message_label.text = ""
	_refresh_all()


func _cycle_body_value(step: int) -> void:
	var field_id := _current_body_part_id()
	var current_index := BODY_SCALE_VALUES.find(_body_value(field_id))
	if current_index < 0:
		current_index = BODY_SCALE_VALUES.find(1.0)
	body_overrides[field_id] = BODY_SCALE_VALUES[
		posmod(current_index + step, BODY_SCALE_VALUES.size())
	]
	message_label.text = ""
	_refresh_all()


func _cycle_style(step: int) -> void:
	var options := _style_options()
	if options.size() <= 1:
		return
	current_style_index = posmod(current_style_index + step, options.size())
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
	eye_label.text = _eye_display_name()
	face_part_label.text = _face_part_display_name()
	face_value_label.text = _face_value_display_name()
	body_part_label.text = _body_part_display_name()
	body_value_label.text = _body_value_display_name()
	style_label.text = _style_display_name()
	var preset: Dictionary = GEAR_PRESETS[current_gear_index]
	gear_label.text = String(preset.get("label", ""))
	_refresh_presentation_mode()
	_refresh_preview()


func _refresh_presentation_mode() -> void:
	for row in advanced_rows:
		row.visible = false
	if gear_row:
		gear_row.visible = not player_facing_mode
	if panel:
		panel.custom_minimum_size.y = 600.0 if player_facing_mode else 640.0
	if apply_button:
		apply_button.text = "Begin game" if onboarding_mode else "Apply"


func _close_pressed() -> void:
	var was_onboarding := onboarding_mode
	set_open(false)
	if was_onboarding:
		creation_cancelled.emit()


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
	var profile: Dictionary = content.get_generated_people_profile(
		people_id, "debug_creator_preview", seed, options
	)
	var appearance: Dictionary = Dictionary(profile.get("appearance", {})).duplicate(true)
	appearance["eye_id"] = get_current_eye_id()
	for part_id in FACE_DETAIL_PART_IDS:
		var field_id := _appearance_field_for_face_part(part_id)
		appearance[field_id] = _selected_face_value(part_id)
	var proportions: Dictionary = Dictionary(appearance.get("proportions", {})).duplicate(true)
	for field_id in body_overrides:
		proportions[field_id] = float(body_overrides[field_id])
	appearance["proportions"] = proportions
	_apply_style(appearance)
	profile["appearance"] = appearance
	return profile


func _eye_display_name() -> String:
	return HumanoidFacePartLibrary.display_name(get_current_eye_id())


func _eye_ids() -> Array[String]:
	return HumanoidFacePartLibrary.part_ids(get_current_people_id(), "eyes")


func _face_value_ids(part_id: String) -> Array[String]:
	return HumanoidFacePartLibrary.part_ids(get_current_people_id(), part_id)


func _selected_face_value(part_id: String) -> String:
	var ids := _face_value_ids(part_id)
	if ids.is_empty():
		return ""
	var index := int(face_value_indices.get(part_id, -1))
	if index < 0:
		return HumanoidFacePartLibrary.default_id(get_current_people_id(), part_id)
	return ids[posmod(index, ids.size())]


func _appearance_field_for_face_part(part_id: String) -> String:
	return {
		"brows": "brow_id",
		"noses": "nose_id",
		"mouths": "mouth_id",
		"facial_marks": "facial_mark_id"
	}.get(part_id, "")


func _face_part_display_name() -> String:
	return {
		"brows": "Brows",
		"noses": "Nose",
		"mouths": "Mouth",
		"facial_marks": "Facial mark"
	}.get(get_current_face_part_id(), "Face part")


func _face_value_display_name() -> String:
	return HumanoidFacePartLibrary.display_name(get_current_face_value_id())


func _current_body_part_id() -> String:
	return BODY_PART_IDS[current_body_part_index]


func _body_value(field_id: String) -> float:
	if body_overrides.has(field_id):
		return float(body_overrides[field_id])
	return 1.0


func _body_part_display_name() -> String:
	return {
		"body_height": "Height",
		"shoulder_width": "Shoulders",
		"torso_width": "Torso",
		"waist_width": "Waist",
		"head_size": "Head",
		"hand_size": "Hands",
		"foot_size": "Feet"
	}.get(_current_body_part_id(), "Body")


func _body_value_display_name() -> String:
	var value := _body_value(_current_body_part_id())
	if value <= 0.85:
		return "Small"
	if value <= 0.95:
		return "Narrow"
	if value >= 1.15:
		return "Large"
	if value >= 1.05:
		return "Broad"
	return "Average"


func _style_options() -> Array[String]:
	var options: Array[String] = []
	var source_options: Array = (
		HUMAN_HAIR_IDS
		if get_current_people_id() == "people_human"
		else PEOPLE_STYLE_OPTIONS.get(get_current_people_id(), [])
	)
	for option in source_options:
		options.append(String(option))
	return options


func _style_display_name() -> String:
	var options := _style_options()
	if options.is_empty():
		return "Built-in"
	var style_id := options[posmod(current_style_index, options.size())]
	if get_current_people_id() == "people_human":
		return style_id.trim_prefix("hair_").replace("_", " ").capitalize()
	return style_id


func _style_index_for_appearance(appearance: Dictionary) -> int:
	if get_current_people_id() == "people_human":
		var hair_index := HUMAN_HAIR_IDS.find(String(appearance.get("hair_id", "")))
		return maxi(0, hair_index)
	var feature_ids: Array = appearance.get("feature_ids", [])
	var feature_id: String = {
		"people_tanglekin": "feature_tanglekin_brow_tuft",
		"people_tuskfolk": "feature_tusks_small",
		"people_mirefolk": "feature_mirefolk_webbed_hands",
		"people_ravenfolk": "feature_ravenfolk_head_crest",
		"people_rootborn": "feature_rootborn_branch_crown"
	}.get(get_current_people_id(), "")
	return 1 if feature_ids.has(feature_id) else 0


func _apply_style(appearance: Dictionary) -> void:
	var people_id := get_current_people_id()
	if people_id == "people_human":
		var styles := _style_options()
		appearance["hair_id"] = styles[posmod(current_style_index, styles.size())]
		return
	var style_index := posmod(current_style_index, _style_options().size())
	match people_id:
		"people_tanglekin":
			appearance["feature_ids"] = (
				["feature_tanglekin_tail", "feature_tanglekin_grasping_hands", "feature_tanglekin_muzzle"]
				if style_index == 0
				else [
					"feature_tanglekin_tail",
					"feature_tanglekin_grasping_hands",
					"feature_tanglekin_muzzle",
					"feature_tanglekin_brow_tuft"
				]
			)
		"people_tuskfolk":
			appearance["feature_ids"] = [
				"feature_tusks_broad" if style_index == 0 else "feature_tusks_small"
			]
		"people_mirefolk":
			appearance["feature_ids"] = (
				["feature_mirefolk_high_eyes"]
				if style_index == 0
				else ["feature_mirefolk_high_eyes", "feature_mirefolk_webbed_hands"]
			)
		"people_ravenfolk":
			appearance["feature_ids"] = [
				"feature_ravenfolk_body_feathers",
				"feature_ravenfolk_beak",
				"feature_ravenfolk_tail_feathers"
			]
			if style_index == 1:
				appearance["feature_ids"].append("feature_ravenfolk_head_crest")
		"people_rootborn":
			appearance["feature_ids"] = [
				"feature_rootborn_bark_marks",
				"feature_rootborn_leaf_crown"
			]
			if style_index == 1:
				appearance["feature_ids"].append("feature_rootborn_branch_crown")


func _current_gear() -> Dictionary:
	if player_facing_mode:
		return public_preview_equipment.duplicate(true)
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
		if player_facing_mode:
			return "Default"
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
