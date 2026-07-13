class_name CaptureSheetHelper
extends RefCounted

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
const DEFAULT_PEOPLE_ORDER := [
	"people_human",
	"people_tanglekin",
	"people_tuskfolk",
	"people_mirefolk",
	"people_ravenfolk",
	"people_rootborn"
]


static func string_arg(args: PackedStringArray, index: int, fallback: String) -> String:
	if index >= args.size() or args[index].is_empty():
		return fallback
	return args[index]


static func positive_arg(args: PackedStringArray, index: int, fallback: int) -> int:
	if index >= args.size() or not args[index].is_valid_int():
		return fallback
	return maxi(1, int(args[index]))


static func capture_config(
	args: PackedStringArray,
	default_output_dir: String,
	default_width: int,
	default_height: int,
	filter_fields: Array[String] = []
) -> Dictionary:
	var config := {
		"output_dir": string_arg(args, 0, default_output_dir),
		"width": positive_arg(args, 1, default_width),
		"height": positive_arg(args, 2, default_height)
	}
	for index in filter_fields.size():
		config[filter_fields[index]] = string_arg(args, index + 3, "")
	return config


static func image_capture_config(
	args: PackedStringArray,
	default_width: int,
	default_height: int,
	default_output_path: String,
	extra_fields: Array[String] = [],
	extra_defaults: Dictionary = {}
) -> Dictionary:
	var config := {
		"width": positive_arg(args, 0, default_width),
		"height": positive_arg(args, 1, default_height),
		"output_path": string_arg(args, 2, default_output_path)
	}
	for index in extra_fields.size():
		var field_id := extra_fields[index]
		config[field_id] = string_arg(args, index + 3, String(extra_defaults.get(field_id, "")))
	return config


static func create_viewport(root: Window, width: int, height: int) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, height)
	viewport.disable_3d = true
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	return viewport


static func add_main_scene(root: Window, main_script, width: int, height: int):
	root.size = Vector2i(width, height)
	var main = main_script.new()
	root.add_child(main)
	return main


static func wait_process_frames(tree: SceneTree, frame_count: int) -> void:
	for _index in frame_count:
		await tree.process_frame


static func capture_main_scene_png(
	tree: SceneTree,
	root: Window,
	main_script,
	width: int,
	height: int,
	output_path: String,
	label: String,
	prepare: Callable,
	prepare_args: Array = [],
	settle_frames: int = 2,
	prepare_error_message: String = ""
) -> bool:
	var main = add_main_scene(root, main_script, width, height)
	await wait_process_frames(tree, 2)
	if main.has_method("begin_new_game"):
		main.begin_new_game()
		var creator = main.get("debug_character_creator")
		if creator and creator.has_method("apply_to_player"):
			creator.apply_to_player()
		await wait_process_frames(tree, 1)
	var prepare_result = prepare.callv([main, width, height] + prepare_args)
	if prepare_result is bool and not bool(prepare_result):
		if not prepare_error_message.is_empty():
			printerr(prepare_error_message)
		tree.quit(1)
		return false
	await wait_process_frames(tree, settle_frames)
	if not save_root_png_or_quit(tree, root, output_path, label):
		return false
	tree.quit()
	return true


static func save_root_png(root: Window, output_path: String) -> Error:
	var image := root.get_texture().get_image()
	return image.save_png(output_path)


static func save_root_png_or_quit(
	tree: SceneTree, root: Window, output_path: String, label: String
) -> bool:
	var error := save_root_png(root, output_path)
	if error == OK:
		return true
	printerr("Could not save %s capture: %s" % [label, error_string(error)])
	tree.quit(1)
	return false


static func create_page(
	width: int, height: int, background_color: Color = Color(0.10, 0.12, 0.10)
) -> Control:
	var page := Control.new()
	page.size = Vector2(width, height)
	var background := ColorRect.new()
	background.color = background_color
	background.size = page.size
	page.add_child(background)
	return page


static func add_sheet_header(page: Control, title: String, note: String, width: int) -> void:
	add_label(page, title, Vector2(34, 22), Vector2(width - 68, 34), 24, Color(0.95, 0.91, 0.78))
	add_label(page, note, Vector2(36, 58), Vector2(width - 72, 24), 13, Color(0.72, 0.72, 0.62))


static func ensure_content_loaded(tree: SceneTree, content, label: String) -> bool:
	var errors := content_load_errors(content)
	if errors.is_empty():
		return true
	for error in errors:
		printerr("%s content load failed: %s" % [label, String(error)])
	tree.quit(1)
	return false


static func content_load_errors(content) -> Array:
	return content.load_all()


static func capture_viewport_image(tree: SceneTree, viewport: SubViewport) -> Image:
	viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	for _frame in 2:
		await tree.process_frame
		await RenderingServer.frame_post_draw
	var texture := viewport.get_texture()
	if texture == null:
		return null
	var image := texture.get_image()
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	return image


static func save_png_image(image: Image, output_path: String) -> Error:
	var buffer := image.save_png_to_buffer()
	if buffer.is_empty():
		return ERR_CANT_CREATE
	var file := FileAccess.open(output_path, FileAccess.WRITE)
	if not file:
		return FileAccess.get_open_error()
	file.store_buffer(buffer)
	return OK


static func add_grid(
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
		add_rule(
			page,
			Vector2(left, top + float(row) * cell_height),
			Vector2(cell_width * float(columns), 1.0),
			Color(0.28, 0.31, 0.24)
		)
	for column in columns + 1:
		add_rule(
			page,
			Vector2(left + float(column) * cell_width, top),
			Vector2(1.0, cell_height * float(rows)),
			Color(0.28, 0.31, 0.24)
		)


static func add_rule(page: Control, position: Vector2, size: Vector2, color: Color) -> void:
	var rule := ColorRect.new()
	rule.position = position
	rule.size = size
	rule.color = color
	page.add_child(rule)


static func add_label(
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


static func add_direction_row_labels(page: Control, top: float, cell_height: float) -> void:
	for row in DIRECTION_LABELS.size():
		add_label(
			page,
			"%02d %s" % [row, String(DIRECTION_LABELS[row])],
			Vector2(18.0, top + float(row) * cell_height + cell_height * 0.36),
			Vector2(62.0, 20.0),
			11,
			Color(0.79, 0.76, 0.63),
			HORIZONTAL_ALIGNMENT_RIGHT
		)


static func filtered_people(people_filter: String) -> Array[String]:
	var people: Array[String] = []
	for people_id in DEFAULT_PEOPLE_ORDER:
		if (
			people_filter.is_empty()
			or people_id == people_filter
			or people_id.ends_with(people_filter)
		):
			people.append(people_id)
	return people


static func people_display_name(content, people_id: String) -> String:
	var people: Dictionary = content.get_people(people_id)
	return String(people.get("display_name", people_id))
