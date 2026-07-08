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


static func string_arg(args: PackedStringArray, index: int, fallback: String) -> String:
	if index >= args.size() or args[index].is_empty():
		return fallback
	return args[index]


static func positive_arg(args: PackedStringArray, index: int, fallback: int) -> int:
	if index >= args.size() or not args[index].is_valid_int():
		return fallback
	return maxi(1, int(args[index]))


static func create_viewport(root: Window, width: int, height: int) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(width, height)
	viewport.disable_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	root.add_child(viewport)
	return viewport


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
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await tree.process_frame
	await tree.process_frame
	var texture := viewport.get_texture()
	if texture == null:
		return null
	return texture.get_image()


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
