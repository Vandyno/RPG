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
const DIRECTIONS := [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP]
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
const LABELED_VARIANTS_PER_PAGE := 6
const LABELED_PAGE_SUFFIXES := ["a", "b", "c", "d", "e", "f"]
const POPULATION_COLUMNS := 24
const HUNDRED_COLUMNS := 10
const HUNDRED_ROWS := 10


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir := _string_arg(args, 0, "res://reports/people_iterations_v8")
	var width := _positive_arg(args, 1, 1600)
	var height := _positive_arg(args, 2, 768)
	var page_filter := _string_arg(args, 3, "")
	var round_label := _round_label(output_dir)

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
		printerr("Could not create people crowd output dir: %s" % error_string(make_error))
		quit(1)
		return

	var pages := _labeled_pages(content)
	pages.append({"name": "round_02_small_scale_rows.png", "mode": "small"})
	pages.append({"name": "round_03_mixed_crowd.png", "mode": "crowd"})
	pages.append({"name": "round_04_people_families.png", "mode": "families"})
	pages.append({"name": "round_05_turnaround.png", "mode": "turnaround"})
	pages.append({"name": "round_05b_16_direction_turnaround.png", "mode": "sixteen_turnaround"})
	pages.append({"name": "round_06_population_stress.png", "mode": "population"})
	pages.append_array(_hundred_pages())
	pages.append_array(_sixteen_people_zoom_pages())
	pages.append_array(_sixteen_people_detail_pages(content))
	pages = _filter_pages(pages, page_filter)
	for page_data in pages:
		var page := _build_page(content, page_data, width, height, round_label)
		viewport.add_child(page)
		var image: Image = await _capture_viewport_image(viewport)
		if image == null:
			printerr(
				"Could not capture people crowd image. Run this script without --headless."
			)
			quit(1)
			return
		var output_path := absolute_dir.path_join(String(page_data["name"]))
		var error := _save_png_image(image, output_path)
		viewport.remove_child(page)
		page.queue_free()
		await process_frame
		if error != OK:
			printerr("Could not save people crowd capture: %s" % error_string(error))
			quit(1)
			return
	quit()


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


func _filter_pages(pages: Array[Dictionary], page_filter: String) -> Array[Dictionary]:
	if page_filter.is_empty():
		return pages
	var filtered: Array[Dictionary] = []
	for page_data in pages:
		var name := String(page_data.get("name", ""))
		var mode := String(page_data.get("mode", ""))
		if name.contains(page_filter) or mode == page_filter:
			filtered.append(page_data)
	if filtered.is_empty():
		printerr("No people crowd capture pages matched filter: %s" % page_filter)
		quit(1)
		return filtered
	return filtered


func _build_page(
	content: ContentDatabase, page_data: Dictionary, width: int, height: int, round_label: String
) -> Control:
	var mode := String(page_data["mode"])
	var variant_start := int(page_data.get("variant_start", 0))
	var variant_count := int(page_data.get("variant_count", -1))
	var page_people_id := String(page_data.get("people_id", ""))
	var page := Control.new()
	page.size = Vector2(width, height)
	var bg := ColorRect.new()
	bg.color = Color(0.91, 0.89, 0.84)
	bg.size = page.size
	page.add_child(bg)
	var total_variants := _total_variant_count(content)
	match mode:
		"turnaround":
			_add_header(
				page,
				"%s Turnaround" % round_label,
				"One representative per people facing front, side, and back."
			)
			_add_turnaround(page, content)
		"sixteen_turnaround":
			_add_header(
				page,
				"%s 16-Direction Turnaround" % round_label,
				"One representative per people in every snapped avatar facing bucket."
			)
			_add_sixteen_turnaround(page, content)
		"sixteen_people_zoom":
			var definition := content.get_people(page_people_id)
			var display_name := String(definition.get("display_name", page_people_id))
			_add_header(
				page,
				"%s %s 16-Direction Zoom" % [round_label, display_name],
				"Every reusable %s archetype in every snapped avatar facing bucket."
				% display_name
			)
			_add_people_sixteen_zoom(page, content, page_people_id)
		"sixteen_people_detail":
			var definition := content.get_people(page_people_id)
			var display_name := String(definition.get("display_name", page_people_id))
			_add_header(
				page,
				"%s %s 16-Direction Detail" % [round_label, display_name],
				"Large angle proof for selected %s archetypes in every snapped bucket."
				% display_name
			)
			_add_people_sixteen_detail(page, content, page_people_id, variant_start, variant_count)
		"families":
			_add_header(
				page,
				"%s People Families" % round_label,
				"Three representative archetypes per people for quick visual review."
			)
			_add_people_families(page, content)
		"small":
			_add_header(
				page,
				"%s Small-Scale Rows" % round_label,
				"All %d archetypes at reduced game-read scale." % total_variants
			)
			_add_small_rows(page, content, height)
		"crowd":
			_add_header(
				page,
				"%s Mixed Crowd" % round_label,
				"All %d archetypes mixed without cards or labels." % total_variants
			)
			_add_mixed_crowd(page, content, height)
		"population":
			_add_header(
				page,
				"%s Population Stress" % round_label,
				"%d generated NPC looks: archetype, facing, motion, and equipment mixed."
				% [PEOPLE_ORDER.size() * POPULATION_COLUMNS]
			)
			_add_population_stress(page, content, height)
		"hundred":
			var definition := content.get_people(page_people_id)
			var display_name := String(definition.get("display_name", page_people_id))
			_add_header(
				page,
				"%s %s Hundred" % [round_label, display_name],
				"100 generated %s looks from archetypes, markings, motion, and equipment."
				% display_name
			)
			_add_people_hundred(page, content, page_people_id, height)
		_:
			var range_text := ""
			if variant_count > 0:
				var variant_end := variant_start + _visible_variant_count(
					content, variant_start, variant_count
				)
				range_text = " %02d-%02d" % [variant_start + 1, variant_end]
			_add_header(
				page,
				"%s Archetypes%s" % [round_label, range_text],
				"Every people variant rendered together."
			)
			_add_labeled_grid(page, content, height, variant_start, variant_count)
	return page


func _add_turnaround(page: Control, content: ContentDatabase) -> void:
	var left := 48.0
	var top := 116.0
	var cell_width := 740.0
	var cell_height := 196.0
	var direction_defs := [
		{"label": "front", "direction": Vector2.DOWN},
		{"label": "side", "direction": Vector2.RIGHT},
		{"label": "back", "direction": Vector2.UP}
	]
	for index in PEOPLE_ORDER.size():
		var people_id := String(PEOPLE_ORDER[index])
		var definition := content.get_people(people_id)
		var origin := Vector2(
			left + float(index % 2) * cell_width, top + float(index / 2) * cell_height
		)
		_add_label(
			page,
			String(definition.get("display_name", people_id)),
			origin,
			Vector2(132, 24),
			15,
			Color(0.08, 0.07, 0.06)
		)
		var variants: Array = content.get_people_visual_model(people_id).get("variants", [])
		if variants.is_empty():
			continue
		var variant: Dictionary = variants[0]
		for column in direction_defs.size():
			var entry: Dictionary = direction_defs[column]
			var x := origin.x + 170.0 + float(column) * 132.0
			_add_avatar(
				page,
				content,
				people_id,
				variant,
				Vector2(x, origin.y + 88.0),
				1.35,
				entry["direction"]
			)
			_add_label(
				page,
				String(entry["label"]),
				Vector2(x - 42.0, origin.y + 108.0),
				Vector2(84, 18),
				8,
				Color(0.16, 0.13, 0.10)
			)


func _add_sixteen_turnaround(page: Control, content: ContentDatabase) -> void:
	var left := maxf(96.0, page.size.x * 0.07)
	var top := maxf(118.0, page.size.y * 0.15)
	var row_height := (page.size.y - top - 58.0) / float(PEOPLE_ORDER.size())
	var col_width := (page.size.x - left - 44.0) / float(SIXTEEN_DIRECTIONS.size())
	var avatar_scale := minf(row_height / 98.0, col_width / 84.0) * 1.04
	for row in PEOPLE_ORDER.size():
		var people_id := String(PEOPLE_ORDER[row])
		var definition := content.get_people(people_id)
		var variants: Array = content.get_people_visual_model(people_id).get("variants", [])
		_add_label(
			page,
			String(definition.get("display_name", people_id)),
			Vector2(24.0, top + row * row_height + 26.0),
			Vector2(96.0, 24.0),
			13,
			Color(0.08, 0.07, 0.06)
		)
		if variants.is_empty():
			continue
		var variant: Dictionary = variants[0]
		for column in SIXTEEN_DIRECTIONS.size():
			var x := left + float(column) * col_width
			var y := top + float(row) * row_height + 58.0
			var direction: Vector2 = SIXTEEN_DIRECTIONS[column]
			_add_avatar(page, content, people_id, variant, Vector2(x, y), avatar_scale, direction)
			if row == 0:
				_add_label(
					page,
					"%02d" % column,
					Vector2(x - 16.0, top - 22.0),
					Vector2(32.0, 16.0),
					7,
					Color(0.20, 0.16, 0.12)
				)


func _add_people_sixteen_zoom(page: Control, content: ContentDatabase, people_id: String) -> void:
	var model := content.get_people_visual_model(people_id)
	var variants: Array = model.get("variants", [])
	if variants.is_empty():
		return
	var left := maxf(180.0, page.size.x * 0.09)
	var top := maxf(142.0, page.size.y * 0.10)
	var bottom_padding := 70.0
	var right_padding := 54.0
	var row_height := (page.size.y - top - bottom_padding) / float(variants.size())
	var col_width := (page.size.x - left - right_padding) / float(SIXTEEN_DIRECTIONS.size())
	var avatar_scale := minf(row_height / 98.0, col_width / 84.0) * 0.98
	for column in SIXTEEN_DIRECTIONS.size():
		var x := left + float(column) * col_width
		_add_label(
			page,
			"%02d" % column,
			Vector2(x - 20.0, top - 28.0),
			Vector2(40.0, 18.0),
			9,
			Color(0.20, 0.16, 0.12)
		)
	for row in variants.size():
		var variant: Dictionary = variants[row]
		var y := top + float(row) * row_height + row_height * 0.55
		_add_label(
			page,
			String(variant.get("display_name", variant.get("id", ""))),
			Vector2(24.0, y - 16.0),
			Vector2(left - 48.0, 34.0),
			11,
			Color(0.08, 0.07, 0.06)
		)
		for column in SIXTEEN_DIRECTIONS.size():
			var x := left + float(column) * col_width
			var direction: Vector2 = SIXTEEN_DIRECTIONS[column]
			_add_avatar(page, content, people_id, variant, Vector2(x, y), avatar_scale, direction)


func _add_people_sixteen_detail(
	page: Control,
	content: ContentDatabase,
	people_id: String,
	variant_start: int,
	variant_count: int
) -> void:
	var model := content.get_people_visual_model(people_id)
	var variants: Array = model.get("variants", [])
	if variants.is_empty():
		return
	var visible_count := _visible_variant_count(content, variant_start, variant_count)
	visible_count = mini(visible_count, variants.size() - variant_start)
	var left := maxf(210.0, page.size.x * 0.08)
	var top := maxf(168.0, page.size.y * 0.13)
	var bottom_padding := 92.0
	var right_padding := 64.0
	var row_height := (page.size.y - top - bottom_padding) / float(visible_count)
	var col_width := (page.size.x - left - right_padding) / float(SIXTEEN_DIRECTIONS.size())
	var avatar_scale := minf(row_height / 126.0, col_width / 86.0) * 1.25
	for column in SIXTEEN_DIRECTIONS.size():
		var x := left + float(column) * col_width
		_add_label(
			page,
			"%02d" % column,
			Vector2(x - 22.0, top - 34.0),
			Vector2(44.0, 20.0),
			11,
			Color(0.20, 0.16, 0.12)
		)
	for row in visible_count:
		var variant: Dictionary = variants[variant_start + row]
		var y := top + float(row) * row_height + row_height * 0.55
		_add_label(
			page,
			String(variant.get("display_name", variant.get("id", ""))),
			Vector2(24.0, y - 24.0),
			Vector2(left - 52.0, 48.0),
			14,
			Color(0.08, 0.07, 0.06)
		)
		for column in SIXTEEN_DIRECTIONS.size():
			var x := left + float(column) * col_width
			var direction: Vector2 = SIXTEEN_DIRECTIONS[column]
			_add_avatar(page, content, people_id, variant, Vector2(x, y), avatar_scale, direction)


func _add_people_families(page: Control, content: ContentDatabase) -> void:
	var left := 48.0
	var top := 116.0
	var cell_width := 740.0
	var cell_height := 196.0
	for index in PEOPLE_ORDER.size():
		var people_id := String(PEOPLE_ORDER[index])
		var definition := content.get_people(people_id)
		var origin := Vector2(left + float(index % 2) * cell_width, top + float(index / 2) * cell_height)
		_add_label(
			page,
			String(definition.get("display_name", people_id)),
			origin,
			Vector2(130, 24),
			16,
			Color(0.08, 0.07, 0.06)
		)
		var variants: Array = content.get_people_visual_model(people_id).get("variants", [])
		for variant_index in mini(3, variants.size()):
			var variant: Dictionary = variants[variant_index]
			var x := origin.x + 166.0 + float(variant_index) * 130.0
			_add_avatar(page, content, people_id, variant, Vector2(x, origin.y + 88.0), 1.45, Vector2.DOWN)
			_add_label(
				page,
				String(variant.get("display_name", "")),
				Vector2(x - 54.0, origin.y + 112.0),
				Vector2(108, 24),
				7,
				Color(0.16, 0.13, 0.10)
			)


func _add_labeled_grid(
	page: Control, content: ContentDatabase, height: int, variant_start: int, variant_count: int
) -> void:
	var top := 82.0
	var left := 126.0
	var visible_count := _visible_variant_count(content, variant_start, variant_count)
	var col_width := minf(178.0, (page.size.x - left - 44.0) / float(visible_count))
	var row_height := minf(90.0, (float(height) - top - 130.0) / float(PEOPLE_ORDER.size()))
	for row in PEOPLE_ORDER.size():
		var people_id := String(PEOPLE_ORDER[row])
		var definition := content.get_people(people_id)
		_add_label(
			page,
			String(definition.get("display_name", people_id)),
			Vector2(34, top + row * row_height + 30),
			Vector2(110, 24),
			16,
			Color(0.08, 0.07, 0.06)
		)
		var variants: Array = content.get_people_visual_model(people_id).get("variants", [])
		for offset in visible_count:
			var variant_index := variant_start + offset
			if variant_index >= variants.size():
				continue
			var variant: Dictionary = variants[variant_index]
			var x := left + offset * col_width
			var y := top + row * row_height
			_add_avatar(page, content, people_id, variant, Vector2(x + 46, y + 50), 1.0, Vector2.DOWN)
			_add_label(
				page,
				String(variant.get("display_name", "")),
				Vector2(x, y + 66),
				Vector2(130, 18),
				7,
				Color(0.16, 0.13, 0.10)
			)


func _add_small_rows(page: Control, content: ContentDatabase, height: int) -> void:
	var top := 76.0
	var left := 126.0
	var col_width := minf(164.0, (page.size.x - left - 44.0) / float(_max_variant_count(content)))
	var row_height := minf(92.0, (float(height) - top - 124.0) / float(PEOPLE_ORDER.size()))
	for row in PEOPLE_ORDER.size():
		var people_id := String(PEOPLE_ORDER[row])
		var definition := content.get_people(people_id)
		_add_label(
			page,
			String(definition.get("display_name", people_id)),
			Vector2(34, top + row * row_height + 36),
			Vector2(110, 24),
			15,
			Color(0.08, 0.07, 0.06)
		)
		var variants: Array = content.get_people_visual_model(people_id).get("variants", [])
		for column in variants.size():
			var variant: Dictionary = variants[column]
			var direction: Vector2 = DIRECTIONS[(row + column) % DIRECTIONS.size()]
			var position := Vector2(left + column * col_width + 46, top + row * row_height + 52)
			_add_avatar(page, content, people_id, variant, position, 0.92, direction)


func _add_mixed_crowd(page: Control, content: ContentDatabase, height: int) -> void:
	var index := 0
	var columns := 16
	var row_count := ceili(float(_total_variant_count(content)) / float(columns))
	var row_gap := minf(96.0, (float(height) - 218.0) / maxf(1.0, float(row_count - 1)))
	for row in PEOPLE_ORDER.size():
		var people_id := String(PEOPLE_ORDER[row])
		var variants: Array = content.get_people_visual_model(people_id).get("variants", [])
		for column in variants.size():
			var variant: Dictionary = variants[column]
			var grid_x := float(index % columns)
			var grid_y := float(index / columns)
			var wave := sin(float(index) * 1.7)
			var x := 70.0 + grid_x * 94.0 + wave * 7.0
			var y := 122.0 + grid_y * row_gap + cos(float(index) * 1.3) * 6.0
			var direction: Vector2 = DIRECTIONS[index % DIRECTIONS.size()]
			_add_avatar(page, content, people_id, variant, Vector2(x, y), 1.08, direction)
			index += 1


func _add_population_stress(page: Control, content: ContentDatabase, height: int) -> void:
	var left := 112.0
	var top := 108.0
	var col_width := minf(55.0, (page.size.x - left - 168.0) / float(POPULATION_COLUMNS))
	var row_height := minf(94.0, (float(height) - top - 48.0) / float(PEOPLE_ORDER.size()))
	for row in PEOPLE_ORDER.size():
		var people_id := String(PEOPLE_ORDER[row])
		var definition := content.get_people(people_id)
		var variants: Array = content.get_people_visual_model(people_id).get("variants", [])
		_add_label(
			page,
			String(definition.get("display_name", people_id)),
			Vector2(34, top + row * row_height + 26.0),
			Vector2(110, 24),
			14,
			Color(0.08, 0.07, 0.06)
		)
		if variants.is_empty():
			continue
		for column in POPULATION_COLUMNS:
			var variant: Dictionary = variants[(column * 5 + row * 3) % variants.size()]
			var direction: Vector2 = DIRECTIONS[(column + row) % DIRECTIONS.size()]
			var equipped := _equipment_for_population_index(row, column)
			var position := Vector2(
				left + column * col_width + 20.0 + sin(float(column + row) * 0.8) * 2.5,
				top + row * row_height + 52.0
			)
			var sneaking := (column + row) % 7 == 0
			_add_population_avatar(
				page, content, people_id, variant, equipped, position, 0.78, direction, sneaking
			)


func _add_people_hundred(
	page: Control, content: ContentDatabase, people_id: String, height: int
) -> void:
	var variants: Array = content.get_people_visual_model(people_id).get("variants", [])
	if variants.is_empty():
		return
	var left := 120.0
	var top := 114.0
	var cell_width := minf(136.0, (page.size.x - left - 80.0) / float(HUNDRED_COLUMNS))
	var cell_height := minf(58.0, (float(height) - top - 34.0) / float(HUNDRED_ROWS))
	for row in HUNDRED_ROWS:
		for column in HUNDRED_COLUMNS:
			var look_index := row * HUNDRED_COLUMNS + column
			var variant: Dictionary = variants[(look_index * 7 + row * 3) % variants.size()]
			var direction: Vector2 = DIRECTIONS[(look_index + row) % DIRECTIONS.size()]
			var equipped := _equipment_for_population_index(row, look_index)
			var position := Vector2(
				left + column * cell_width + 26.0 + sin(float(look_index) * 0.9) * 3.0,
				top + row * cell_height + 34.0 + cos(float(column) * 0.7) * 2.0
			)
			var sneaking := look_index % 9 == 0
			_add_population_avatar(
				page, content, people_id, variant, equipped, position, 0.82, direction, sneaking
			)


func _add_avatar(
	page: Control,
	content: ContentDatabase,
	people_id: String,
	variant: Dictionary,
	position: Vector2,
	scale: float,
	direction: Vector2
) -> void:
	var variant_id := String(variant.get("id", ""))
	var profile := content.get_people_visual_variant_profile(
		people_id, variant_id, "crowd_%s" % variant_id
	)
	var avatar := HumanoidAvatar2D.new()
	avatar.position = position
	avatar.scale = Vector2(scale, scale)
	avatar.setup(profile)
	avatar.set_facing_direction(direction)
	page.add_child(avatar)


func _add_population_avatar(
	page: Control,
	content: ContentDatabase,
	people_id: String,
	variant: Dictionary,
	equipped: Dictionary,
	position: Vector2,
	scale: float,
	direction: Vector2,
	sneaking: bool
) -> void:
	var variant_id := String(variant.get("id", ""))
	var profile := content.get_people_visual_variant_profile(
		people_id, variant_id, "population_%s" % variant_id
	)
	var avatar := HumanoidAvatar2D.new()
	avatar.position = position
	avatar.scale = Vector2(scale, scale)
	avatar.setup(profile, equipped, content)
	avatar.set_facing_direction(direction)
	avatar.set_locomotion(true, sneaking, 0.12 + float(int(position.x) % 5) * 0.03)
	page.add_child(avatar)


func _equipment_for_population_index(row: int, column: int) -> Dictionary:
	var equipped := {}
	match (row * 3 + column) % 6:
		0:
			equipped["weapon"] = "item_training_sword"
		1:
			equipped["weapon"] = "item_road_hatchet"
		2:
			equipped["weapon"] = "item_hunting_bow"
		3:
			equipped["weapon"] = "item_test_polearm"
	if (row + column) % 4 == 0:
		equipped["offhand"] = "item_traveler_buckler"
	return equipped


func _add_header(page: Control, title: String, note: String) -> void:
	_add_label(page, title, Vector2(34, 26), Vector2(900, 34), 24, Color(0.08, 0.07, 0.06))
	_add_label(page, note, Vector2(36, 64), Vector2(1050, 24), 12, Color(0.28, 0.25, 0.22))


func _add_label(
	parent: Control, text: String, position: Vector2, size: Vector2, font_size: int, color: Color
) -> void:
	var label := Label.new()
	label.position = position
	label.size = size
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


func _positive_arg(args: PackedStringArray, index: int, fallback: int) -> int:
	if index >= args.size() or not args[index].is_valid_int():
		return fallback
	return maxi(1, int(args[index]))


func _string_arg(args: PackedStringArray, index: int, fallback: String) -> String:
	if index >= args.size() or args[index].is_empty():
		return fallback
	return args[index]


func _round_label(output_dir: String) -> String:
	var basename := output_dir.get_file()
	if basename.begins_with("people_iterations_"):
		return basename.replace("people_iterations_", "")
	return basename


func _labeled_pages(content: ContentDatabase) -> Array[Dictionary]:
	var pages: Array[Dictionary] = []
	var max_count := _max_variant_count(content)
	var page_count := ceili(float(max_count) / float(LABELED_VARIANTS_PER_PAGE))
	for page_index in page_count:
		var variant_start := page_index * LABELED_VARIANTS_PER_PAGE
		var variant_end := mini(max_count, variant_start + LABELED_VARIANTS_PER_PAGE)
		var suffix := _labeled_page_suffix(page_index)
		pages.append(
			{
				"name":
				"round_01%s_variants_%02d_%02d_labeled.png"
				% [suffix, variant_start + 1, variant_end],
				"mode": "labeled",
				"variant_start": variant_start,
				"variant_count": LABELED_VARIANTS_PER_PAGE
			}
		)
	return pages


func _labeled_page_suffix(page_index: int) -> String:
	if page_index < LABELED_PAGE_SUFFIXES.size():
		return String(LABELED_PAGE_SUFFIXES[page_index])
	return "_%02d" % [page_index + 1]


func _hundred_pages() -> Array[Dictionary]:
	var pages: Array[Dictionary] = []
	for people_id in PEOPLE_ORDER:
		var clean_id := String(people_id).replace("people_", "")
		pages.append(
			{
				"name": "round_07_%s_hundred.png" % clean_id,
				"mode": "hundred",
				"people_id": String(people_id)
			}
		)
	return pages


func _sixteen_people_zoom_pages() -> Array[Dictionary]:
	var pages: Array[Dictionary] = []
	for people_id in PEOPLE_ORDER:
		var clean_id := String(people_id).replace("people_", "")
		pages.append(
			{
				"name": "round_08_%s_16_zoom.png" % clean_id,
				"mode": "sixteen_people_zoom",
				"people_id": String(people_id)
			}
		)
	return pages


func _sixteen_people_detail_pages(content: ContentDatabase) -> Array[Dictionary]:
	var pages: Array[Dictionary] = []
	var variants_per_page := 4
	for people_id in PEOPLE_ORDER:
		var variants: Array = content.get_people_visual_model(String(people_id)).get("variants", [])
		var clean_id := String(people_id).replace("people_", "")
		var page_count := ceili(float(maxi(1, variants.size())) / float(variants_per_page))
		for page_index in page_count:
			var variant_start := page_index * variants_per_page
			var variant_end := mini(variants.size(), variant_start + variants_per_page)
			pages.append(
				{
					"name":
					"round_09_%s_16_detail_%02d_%02d.png"
					% [clean_id, variant_start + 1, variant_end],
					"mode": "sixteen_people_detail",
					"people_id": String(people_id),
					"variant_start": variant_start,
					"variant_count": variants_per_page
				}
			)
	return pages


func _total_variant_count(content: ContentDatabase) -> int:
	var total := 0
	for people_id in PEOPLE_ORDER:
		total += Array(content.get_people_visual_model(String(people_id)).get("variants", [])).size()
	return total


func _max_variant_count(content: ContentDatabase) -> int:
	var result := 1
	for people_id in PEOPLE_ORDER:
		var variants: Array = content.get_people_visual_model(String(people_id)).get("variants", [])
		result = maxi(result, variants.size())
	return result


func _visible_variant_count(
	content: ContentDatabase, variant_start: int, variant_count: int
) -> int:
	var max_count := _max_variant_count(content)
	if variant_count <= 0:
		return max_count
	return maxi(1, mini(variant_count, max_count - variant_start))
