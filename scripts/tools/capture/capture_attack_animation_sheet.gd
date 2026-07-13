extends SceneTree

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")
const DirectionalAttack = preload("res://scripts/core/directional_attack.gd")
const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")
const ActorWeaponAttackAction = preload("res://scripts/world/actor_weapon_attack_action.gd")

const DIRECTION_LABELS := CaptureSheetHelper.DIRECTION_LABELS
const SIXTEEN_DIRECTIONS := CaptureSheetHelper.SIXTEEN_DIRECTIONS
const DEFAULT_OUTPUT_DIR := "res://reports/attack_animation_16dir"
const DEFAULT_WIDTH := 1440
const DEFAULT_HEIGHT := 1900
const PROGRESS_STEPS := [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0]
const ATTACK_SHEETS := [
	{"id": "punch", "title": "Punch", "item_id": ""},
	{"id": "hatchet", "title": "Road Hatchet", "item_id": "item_road_hatchet"},
	{"id": "sword", "title": "Training Sword", "item_id": "item_training_sword"},
	{
		"id": "sword_buckler",
		"title": "Training Sword + Buckler",
		"item_id": "item_training_sword",
		"offhand_item_id": "item_traveler_buckler"
	},
	{"id": "polearm", "title": "Test Polearm", "item_id": "item_test_polearm"},
	{"id": "bow", "title": "Hunting Bow", "item_id": "item_hunting_bow"}
]


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var config := capture_config(OS.get_cmdline_user_args())
	var output_dir := String(config["output_dir"])
	var width := int(config["width"])
	var height := int(config["height"])
	var people_filter := String(config["people_filter"])
	var attack_filter := String(config["attack_filter"])

	var content := ContentDatabase.new()
	root.add_child(content)
	if not CaptureSheetHelper.ensure_content_loaded(self, content, "Attack animation capture"):
		return

	var viewport := CaptureSheetHelper.create_viewport(root, width, height)

	var absolute_dir := ProjectSettings.globalize_path(output_dir)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if make_error != OK:
		printerr("Could not create attack animation output dir: %s" % error_string(make_error))
		quit(1)
		return

	var wrote_count := 0
	for people_id in CaptureSheetHelper.filtered_people(people_filter):
		for attack_data in _filtered_attacks(attack_filter):
			var page := _build_sheet(content, people_id, attack_data, width, height)
			viewport.add_child(page)
			var image: Image = await CaptureSheetHelper.capture_viewport_image(self, viewport)
			if image == null:
				printerr("Could not capture attack animation image. Run without --headless.")
				quit(1)
				return
			var output_path := absolute_dir.path_join(sheet_file_name(people_id, attack_data))
			var error := CaptureSheetHelper.save_png_image(image, output_path)
			viewport.remove_child(page)
			page.queue_free()
			await process_frame
			if error != OK:
				printerr("Could not save attack animation capture: %s" % error_string(error))
				quit(1)
				return
			wrote_count += 1
	print("Wrote %d attack animation capture sheets to %s" % [wrote_count, absolute_dir])
	quit()


static func capture_config(args: Array) -> Dictionary:
	return CaptureSheetHelper.capture_config(
		args, DEFAULT_OUTPUT_DIR, DEFAULT_WIDTH, DEFAULT_HEIGHT, ["people_filter", "attack_filter"]
	)


func _build_sheet(
	content: ContentDatabase, people_id: String, attack_data: Dictionary, width: int, height: int
) -> Control:
	var page := CaptureSheetHelper.create_page(width, height)
	var attack := _attack_for_sheet(content, attack_data)
	var title := (
		"%s - %s 16-direction attack animation"
		% [CaptureSheetHelper.people_display_name(content, people_id), String(attack_data["title"])]
	)
	var note := "Rows are snapped avatar facings. Columns are attack progress 0-100%."
	CaptureSheetHelper.add_sheet_header(page, title, note, width)
	CaptureSheetHelper.add_label(
		page,
		(
			"shape %s | range %.1f | width %.1f"
			% [
				String(attack.get("shape", "")),
				float(attack.get("range_pixels", 0.0)),
				float(attack.get("width_pixels", 0.0))
			]
		),
		Vector2(36, 80),
		Vector2(width - 72, 24),
		12,
		Color(0.56, 0.62, 0.55)
	)

	var left := 88.0
	var top := 122.0
	var right_padding := 28.0
	var bottom_padding := 28.0
	var cell_width := (float(width) - left - right_padding) / float(PROGRESS_STEPS.size())
	var cell_height := (float(height) - top - bottom_padding) / float(SIXTEEN_DIRECTIONS.size())
	CaptureSheetHelper.add_grid(
		page, left, top, cell_width, cell_height, PROGRESS_STEPS.size(), SIXTEEN_DIRECTIONS.size()
	)
	_add_column_labels(page, left, top, cell_width)
	CaptureSheetHelper.add_direction_row_labels(page, top, cell_height)
	_add_attack_avatars(
		page, content, people_id, attack_data, attack, left, top, cell_width, cell_height
	)
	return page


func _add_attack_avatars(
	page: Control,
	content: ContentDatabase,
	people_id: String,
	attack_data: Dictionary,
	attack: Dictionary,
	left: float,
	top: float,
	cell_width: float,
	cell_height: float
) -> void:
	var profile := _profile_for_people(content, people_id)
	var equipped := _equipment_for_attack(attack_data)
	for row in SIXTEEN_DIRECTIONS.size():
		var direction: Vector2 = SIXTEEN_DIRECTIONS[row]
		for column in PROGRESS_STEPS.size():
			var progress := float(PROGRESS_STEPS[column])
			var avatar := HumanoidAvatar2D.new()
			avatar.position = Vector2(
				left + float(column) * cell_width + cell_width * 0.5,
				top + float(row) * cell_height + cell_height * 0.60
			)
			avatar.scale = Vector2(2.0, 2.0)
			avatar.setup(profile, equipped, content)
			avatar.set_facing_direction(direction)
			if String(attack.get("shape", "")) != "projectile":
				avatar.set_attack_pose(attack, direction, progress)
			page.add_child(avatar)
			_add_projectile_action_if_needed(page, avatar, attack, direction, progress)


func _add_projectile_action_if_needed(
	page: Control, avatar: HumanoidAvatar2D, attack: Dictionary, direction: Vector2, progress: float
) -> void:
	if String(attack.get("shape", "")) != "projectile":
		return
	if progress <= 0.55:
		avatar.set_attack_pose(attack, direction, clampf(progress / 0.55, 0.0, 1.0))
		return
	var release_progress := clampf((progress - 0.55) / 0.45, 0.0, 1.0)
	var release_attack := attack.duplicate(true)
	release_attack["released"] = true
	release_attack["charge_ratio"] = 1.0
	var action := ActorWeaponAttackAction.new()
	page.add_child(action)
	action.setup(
		{
			"source_actor": avatar,
			"direction": direction,
			"attack": release_attack,
			"resolve_immediately": false
		}
	)
	action.age = action.duration * release_progress
	avatar.set_attack_pose(release_attack, direction, release_progress)
	action.queue_redraw()


func _profile_for_people(content: ContentDatabase, people_id: String) -> Dictionary:
	var variants: Array = content.get_people_visual_model(people_id).get("variants", [])
	if variants.is_empty():
		return content.get_generated_people_profile(people_id, "capture_%s" % people_id)
	var variant: Dictionary = variants[0]
	var variant_id := String(variant.get("id", ""))
	return content.get_people_visual_variant_profile(
		people_id, variant_id, "capture_%s" % people_id
	)


func _attack_for_sheet(content: ContentDatabase, attack_data: Dictionary) -> Dictionary:
	var item_id := String(attack_data.get("item_id", ""))
	if item_id.is_empty():
		return DirectionalAttack.weapon_attack_from_item({})
	return DirectionalAttack.weapon_attack_for_item(content, item_id)


static func _equipment_for_attack(attack_data: Dictionary) -> Dictionary:
	var item_id := String(attack_data.get("item_id", ""))
	if item_id.is_empty():
		return {}
	var equipment := {"right_hand": item_id}
	var offhand_item_id := String(attack_data.get("offhand_item_id", ""))
	if not offhand_item_id.is_empty():
		equipment["left_hand"] = offhand_item_id
	return equipment


static func _add_column_labels(page: Control, left: float, top: float, cell_width: float) -> void:
	for column in PROGRESS_STEPS.size():
		var progress := int(round(float(PROGRESS_STEPS[column]) * 100.0))
		CaptureSheetHelper.add_label(
			page,
			"%d%%" % progress,
			Vector2(left + float(column) * cell_width, top - 26.0),
			Vector2(cell_width, 20.0),
			11,
			Color(0.79, 0.76, 0.63),
			HORIZONTAL_ALIGNMENT_CENTER
		)


static func _filtered_attacks(attack_filter: String) -> Array[Dictionary]:
	var attacks: Array[Dictionary] = []
	for attack_data in ATTACK_SHEETS:
		var attack_id := String(attack_data["id"])
		if attack_filter.is_empty() or attack_filter == attack_id:
			attacks.append(attack_data)
	return attacks


static func sheet_file_name(people_id: String, attack_data: Dictionary) -> String:
	var people_name := people_id.replace("people_", "")
	return "%s_%s_16dir_animation.png" % [people_name, String(attack_data["id"])]
