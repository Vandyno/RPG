extends SceneTree

const GRID_SIZE := 4
const FRAME_SIZE := Vector2i(64, 64)
const FRAME_COUNT := 16
const FACE_ANCHOR := Vector2i(32, 19)
const MAX_FACE_SIZE := Vector2i(10, 9)

# Source cell plus optional mirror. Negative source means the face is hidden.
# The five rear buckets match HumanoidAvatar2D's existing back-face cutoff.
const SOURCE_FRAMES := [
	[0, false],
	[1, false],
	[2, false],
	[3, false],
	[4, false],
	[5, false],
	[6, false],
	[7, false],
	[0, true],
	[0, true],
	[-1, false],
	[-1, false],
	[-1, false],
	[-1, false],
	[-1, false],
	[0, false]
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("Usage: pack_generated_face_grid.gd -- <input.png> <output.png>")
		quit(1)
		return
	var source := Image.new()
	var load_error := source.load(String(args[0]))
	if load_error != OK:
		printerr("Could not load face source: %s" % error_string(load_error))
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	var strip := Image.create(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	strip.fill(Color.TRANSPARENT)
	for frame_index in FRAME_COUNT:
		var source_spec: Array = SOURCE_FRAMES[frame_index]
		var source_index := int(source_spec[0])
		if source_index < 0:
			continue
		var face := _extract_cell(source, source_index)
		if bool(source_spec[1]):
			face.flip_x()
		var paste_position := Vector2i(
			frame_index * FRAME_SIZE.x + FACE_ANCHOR.x - face.get_width() / 2,
			FACE_ANCHOR.y - face.get_height() / 2
		)
		strip.blit_rect(face, Rect2i(Vector2i.ZERO, face.get_size()), paste_position)
	var output_path := String(args[1])
	var make_error := DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	if make_error != OK:
		printerr("Could not create face output directory: %s" % error_string(make_error))
		quit(1)
		return
	var save_error := strip.save_png(output_path)
	if save_error != OK:
		printerr("Could not save face strip: %s" % error_string(save_error))
		quit(1)
		return
	print("Wrote generated face strip to %s" % output_path)
	quit()


static func _extract_cell(source: Image, source_index: int) -> Image:
	var column := source_index % GRID_SIZE
	var row := source_index / GRID_SIZE
	var x0 := int(floor(float(column) * source.get_width() / GRID_SIZE))
	var x1 := int(floor(float(column + 1) * source.get_width() / GRID_SIZE))
	var y0 := int(floor(float(row) * source.get_height() / GRID_SIZE))
	var y1 := int(floor(float(row + 1) * source.get_height() / GRID_SIZE))
	var cell := source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
	for y in cell.get_height():
		for x in cell.get_width():
			var pixel := cell.get_pixel(x, y)
			if pixel.a < 0.50:
				cell.set_pixel(x, y, Color.TRANSPARENT)
	var used := cell.get_used_rect()
	if used.size == Vector2i.ZERO:
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	var face := cell.get_region(used)
	var fit_scale := minf(
		float(MAX_FACE_SIZE.x) / float(face.get_width()),
		float(MAX_FACE_SIZE.y) / float(face.get_height())
	)
	var target_size := Vector2i(
		maxi(1, int(round(face.get_width() * fit_scale))),
		maxi(1, int(round(face.get_height() * fit_scale)))
	)
	face.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	for y in face.get_height():
		for x in face.get_width():
			var pixel := face.get_pixel(x, y)
			if pixel.a < 0.35:
				face.set_pixel(x, y, Color.TRANSPARENT)
			else:
				face.set_pixel(x, y, Color(0.12, 0.07, 0.04, pixel.a))
	return face
