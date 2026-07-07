extends SceneTree

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const HumanoidAvatar2D = preload("res://scripts/characters/humanoid_avatar_2d.gd")

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
const IDLE_LOADOUTS := [
	{"id": "unarmed", "title": "Unarmed", "equipment": {}},
	{"id": "sword", "title": "Sword", "equipment": {"right_hand": "item_training_sword"}},
	{"id": "polearm", "title": "Polearm", "equipment": {"right_hand": "item_test_polearm"}},
	{"id": "bow", "title": "Bow", "equipment": {"right_hand": "item_hunting_bow"}}
]


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir := _string_arg(args, 0, "res://reports/idle_16dir")
	var width := _positive_arg(args, 1, 980)
	var height := _positive_arg(args, 2, 1500)
	var people_filter := _string_arg(args, 3, "")

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
		printerr("Could not create idle direction output dir: %s" % error_string(make_error))
		quit(1)
		return

	var wrote_count := 0
	for people_id in _filtered_people(people_filter):
		var page := _build_sheet(content, people_id, width, height)
		viewport.add_child(page)
		var image: Image = await _capture_viewport_image(viewport)
		if image == null:
			printerr("Could not capture idle direction image. Run without --headless.")
			quit(1)
			return
		var output_path := absolute_dir.path_join(_sheet_file_name(people_id))
		var error := _save_png_image(image, output_path)
		viewport.remove_child(page)
		page.queue_free()
		await process_frame
		if error != OK:
			printerr("Could not save idle direction capture: %s" % error_string(error))
			quit(1)
			return
		wrote_count += 1
	print("Wrote %d idle direction capture sheets to %s" % [wrote_count, absolute_dir])
	quit()


func _build_sheet(content: ContentDatabase, people_id: String, width: int, height: int) -> Control:
	var page := Control.new()
	page.size = Vector2(width, height)
	var background := ColorRect.new()
	background.color = Color(0.10, 0.12, 0.10)
	background.size = page.size
	page.add_child(background)

	var title := (
		"%s - 16-direction idle held-item reference" % _people_display_name(content, people_id)
	)
	var note := "Rows are snapped avatar facings. Columns are resting loadouts."
	_add_label(page, title, Vector2(34, 22), Vector2(width - 68, 34), 24, Color(0.95, 0.91, 0.78))
	_add_label(page, note, Vector2(36, 58), Vector2(width - 72, 24), 13, Color(0.72, 0.72, 0.62))

	var left := 88.0
	var top := 112.0
	var right_padding := 28.0
	var bottom_padding := 28.0
	var columns := IDLE_LOADOUTS.size()
	var rows := SIXTEEN_DIRECTIONS.size()
	var cell_width := (float(width) - left - right_padding) / float(columns)
	var cell_height := (float(height) - top - bottom_padding) / float(rows)
	_add_grid(page, left, top, cell_width, cell_height, columns, rows)
	_add_column_labels(page, left, top, cell_width)
	_add_row_labels(page, top, cell_height)
	_add_idle_avatars(page, content, people_id, left, top, cell_width, cell_height)
	return page


func _add_idle_avatars(
	page: Control,
	content: ContentDatabase,
	people_id: String,
	left: float,
	top: float,
	cell_width: float,
	cell_height: float
) -> void:
	var profile := _profile_for_people(content, people_id)
	for row in SIXTEEN_DIRECTIONS.size():
		var direction: Vector2 = SIXTEEN_DIRECTIONS[row]
		for column in IDLE_LOADOUTS.size():
			var loadout: Dictionary = IDLE_LOADOUTS[column]
			var avatar := HumanoidAvatar2D.new()
			avatar.position = Vector2(
				left + float(column) * cell_width + cell_width * 0.5,
				top + float(row) * cell_height + cell_height * 0.62
			)
			avatar.scale = Vector2(2.0, 2.0)
			avatar.setup(profile, loadout.get("equipment", {}), content)
			avatar.set_facing_direction(direction)
			page.add_child(avatar)


func _profile_for_people(content: ContentDatabase, people_id: String) -> Dictionary:
	var variants: Array = content.get_people_visual_model(people_id).get("variants", [])
	if variants.is_empty():
		return content.get_generated_people_profile(people_id, "idle_capture_%s" % people_id)
	var variant: Dictionary = variants[0]
	var variant_id := String(variant.get("id", ""))
	return content.get_people_visual_variant_profile(
		people_id, variant_id, "idle_capture_%s" % people_id
	)


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
	for column in IDLE_LOADOUTS.size():
		var loadout: Dictionary = IDLE_LOADOUTS[column]
		_add_label(
			page,
			String(loadout["title"]),
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


func _sheet_file_name(people_id: String) -> String:
	return "%s_idle_16dir.png" % people_id.replace("people_", "")


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
