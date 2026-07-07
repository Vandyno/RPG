extends SceneTree

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const DirectionalAttack = preload("res://scripts/core/directional_attack.gd")
const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")
const ActorWeaponAttackAction = preload("res://scripts/world/actor_weapon_attack_action.gd")

const PEOPLE_ORDER := [
	"people_human",
	"people_tanglekin",
	"people_tuskfolk",
	"people_mirefolk",
	"people_ravenfolk",
	"people_rootborn"
]
const DIRECTION_LABELS := [
	"E",
	"ESE",
	"SE",
	"SSE",
	"S",
	"SSW",
	"SW",
	"WSW",
	"W",
	"WNW",
	"NW",
	"NNW",
	"N",
	"NNE",
	"NE",
	"ENE"
]
const SIXTEEN_DIRECTIONS := [
	Vector2.RIGHT,
	Vector2(0.9239, 0.3827),
	Vector2(0.7071, 0.7071),
	Vector2(0.3827, 0.9239),
	Vector2.DOWN,
	Vector2(-0.3827, 0.9239),
	Vector2(-0.7071, 0.7071),
	Vector2(-0.9239, 0.3827),
	Vector2.LEFT,
	Vector2(-0.9239, -0.3827),
	Vector2(-0.7071, -0.7071),
	Vector2(-0.3827, -0.9239),
	Vector2.UP,
	Vector2(0.3827, -0.9239),
	Vector2(0.7071, -0.7071),
	Vector2(0.9239, -0.3827)
]
const PROGRESS_STEPS := [0.0, 0.125, 0.25, 0.375, 0.5, 0.625, 0.75, 0.875, 1.0]
const ATTACK_SHEETS := [
	{"id": "punch", "title": "Punch", "item_id": ""},
	{"id": "sword", "title": "Training Sword", "item_id": "item_training_sword"},
	{"id": "polearm", "title": "Test Polearm", "item_id": "item_test_polearm"},
	{"id": "bow", "title": "Hunting Bow", "item_id": "item_hunting_bow"}
]


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir := _string_arg(args, 0, "res://reports/attack_animation_16dir")
	var width := _positive_arg(args, 1, 1440)
	var height := _positive_arg(args, 2, 1900)
	var people_filter := _string_arg(args, 3, "")
	var attack_filter := _string_arg(args, 4, "")

	var content := ContentDatabase.new()
	root.add_child(content)
	content.load_all()

	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, height)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(viewport)

	var absolute_dir := ProjectSettings.globalize_path(output_dir)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if make_error != OK:
		printerr("Could not create attack animation output dir: %s" % error_string(make_error))
		quit(1)
		return

	var wrote_count := 0
	for people_id in _filtered_people(people_filter):
		for attack_data in _filtered_attacks(attack_filter):
			var page := _build_sheet(content, people_id, attack_data, width, height)
			viewport.add_child(page)
			var image: Image = await _capture_viewport_image(viewport)
			if image == null:
				printerr("Could not capture attack animation image. Run without --headless.")
				quit(1)
				return
			var output_path := absolute_dir.path_join(_sheet_file_name(people_id, attack_data))
			var error := _save_png_image(image, output_path)
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


func _build_sheet(
	content: ContentDatabase, people_id: String, attack_data: Dictionary, width: int, height: int
) -> Control:
	var page := Control.new()
	page.size = Vector2(width, height)
	var background := ColorRect.new()
	background.color = Color(0.10, 0.12, 0.10)
	background.size = page.size
	page.add_child(background)

	var attack := _attack_for_sheet(content, attack_data)
	var title := (
		"%s - %s 16-direction attack animation"
		% [_people_display_name(content, people_id), String(attack_data["title"])]
	)
	var note := "Rows are snapped avatar facings. Columns are attack progress 0-100%."
	_add_label(page, title, Vector2(34, 22), Vector2(width - 68, 34), 24, Color(0.95, 0.91, 0.78))
	_add_label(page, note, Vector2(36, 58), Vector2(width - 72, 24), 13, Color(0.72, 0.72, 0.62))
	_add_label(
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
	_add_grid(
		page, left, top, cell_width, cell_height, PROGRESS_STEPS.size(), SIXTEEN_DIRECTIONS.size()
	)
	_add_column_labels(page, left, top, cell_width)
	_add_row_labels(page, top, cell_height)
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


func _equipment_for_attack(attack_data: Dictionary) -> Dictionary:
	var item_id := String(attack_data.get("item_id", ""))
	if item_id.is_empty():
		return {}
	return {"right_hand": item_id}


func _add_grid(
	page: Control,
	left: float,
	top: float,
	cell_width: float,
	cell_height: float,
	columns: int,
	rows: int
) -> void:
	var area := ColorRect.new()
	area.position = Vector2(left, top)
	area.size = Vector2(cell_width * float(columns), cell_height * float(rows))
	area.color = Color(0.16, 0.18, 0.15)
	page.add_child(area)
	for row in rows + 1:
		_add_rule(
			page,
			Vector2(left, top + float(row) * cell_height),
			Vector2(cell_width * float(columns), 1.0),
			Color(0.28, 0.31, 0.24)
		)
	for column in columns + 1:
		_add_rule(
			page,
			Vector2(left + float(column) * cell_width, top),
			Vector2(1.0, cell_height * float(rows)),
			Color(0.28, 0.31, 0.24)
		)


func _add_column_labels(page: Control, left: float, top: float, cell_width: float) -> void:
	for column in PROGRESS_STEPS.size():
		var progress := int(round(float(PROGRESS_STEPS[column]) * 100.0))
		_add_label(
			page,
			"%d%%" % progress,
			Vector2(left + float(column) * cell_width, top - 26.0),
			Vector2(cell_width, 20.0),
			11,
			Color(0.79, 0.76, 0.63),
			HORIZONTAL_ALIGNMENT_CENTER
		)


func _add_row_labels(page: Control, top: float, cell_height: float) -> void:
	for row in DIRECTION_LABELS.size():
		_add_label(
			page,
			"%02d %s" % [row, String(DIRECTION_LABELS[row])],
			Vector2(18.0, top + float(row) * cell_height + cell_height * 0.36),
			Vector2(62.0, 20.0),
			11,
			Color(0.79, 0.76, 0.63),
			HORIZONTAL_ALIGNMENT_RIGHT
		)


func _add_rule(page: Control, position: Vector2, size: Vector2, color: Color) -> void:
	var rule := ColorRect.new()
	rule.position = position
	rule.size = size
	rule.color = color
	page.add_child(rule)


func _add_label(
	parent: Control,
	text: String,
	position: Vector2,
	size: Vector2,
	font_size: int,
	color: Color,
	alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT
) -> void:
	var label := Label.new()
	label.position = position
	label.size = size
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


func _capture_viewport_image(viewport: SubViewport) -> Image:
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await process_frame
	await process_frame
	var texture := viewport.get_texture()
	if texture == null:
		return null
	return texture.get_image()


func _save_png_image(image: Image, output_path: String) -> Error:
	var buffer := image.save_png_to_buffer()
	if buffer.is_empty():
		return ERR_CANT_CREATE
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_buffer(buffer)
	return OK


func _filtered_people(people_filter: String) -> Array[String]:
	var people: Array[String] = []
	for people_id in PEOPLE_ORDER:
		if (
			people_filter.is_empty()
			or people_id == people_filter
			or people_id.ends_with(people_filter)
		):
			people.append(people_id)
	return people


func _filtered_attacks(attack_filter: String) -> Array[Dictionary]:
	var attacks: Array[Dictionary] = []
	for attack_data in ATTACK_SHEETS:
		var attack_id := String(attack_data["id"])
		if attack_filter.is_empty() or attack_filter == attack_id:
			attacks.append(attack_data)
	return attacks


func _sheet_file_name(people_id: String, attack_data: Dictionary) -> String:
	var people_name := people_id.replace("people_", "")
	return "%s_%s_16dir_animation.png" % [people_name, String(attack_data["id"])]


func _people_display_name(content: ContentDatabase, people_id: String) -> String:
	var people: Dictionary = content.get_people(people_id)
	return String(people.get("display_name", people_id))


func _positive_arg(args: PackedStringArray, index: int, fallback: int) -> int:
	if index >= args.size() or not args[index].is_valid_int():
		return fallback
	return maxi(1, int(args[index]))


func _string_arg(args: PackedStringArray, index: int, fallback: String) -> String:
	if index >= args.size() or args[index].is_empty():
		return fallback
	return args[index]
