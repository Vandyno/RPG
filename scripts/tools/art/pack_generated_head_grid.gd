extends SceneTree

const GRID_SIZE := 4
const FRAME_SIZE := Vector2i(64, 64)
const FRAME_COUNT := 16
const HEAD_ANCHOR := Vector2i(32, 18)
const MAX_HEAD_SIZE := Vector2i(14, 14)

# Generated 4x4 source is authored directly in FacingBuckets order.
const SOURCE_FRAMES := [
	[0, false],
	[1, false],
	[2, false],
	[3, false],
	[4, false],
	[5, false],
	[6, false],
	[7, false],
	[8, false],
	[9, false],
	[10, false],
	[11, false],
	[12, false],
	[13, false],
	[14, false],
	[15, false]
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("Usage: pack_generated_head_grid.gd -- <input.png> <output.png>")
		quit(1)
		return
	var source := Image.new()
	var load_error := source.load(String(args[0]))
	if load_error != OK:
		printerr("Could not load source: %s" % error_string(load_error))
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	var strip := Image.create(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	strip.fill(Color.TRANSPARENT)
	for frame_index in FRAME_COUNT:
		var source_spec: Array = SOURCE_FRAMES[frame_index]
		var head := _extract_cell_head(source, int(source_spec[0]))
		if bool(source_spec[1]):
			head.flip_x()
		_neutralize_for_skin_tint(head)
		var paste_position := Vector2i(
			frame_index * FRAME_SIZE.x + HEAD_ANCHOR.x - head.get_width() / 2,
			HEAD_ANCHOR.y - head.get_height() / 2
		)
		strip.blit_rect(head, Rect2i(Vector2i.ZERO, head.get_size()), paste_position)
	var output_path := String(args[1])
	var make_error := DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	if make_error != OK:
		printerr("Could not create output directory: %s" % error_string(make_error))
		quit(1)
		return
	var save_error := strip.save_png(output_path)
	if save_error != OK:
		printerr("Could not save strip: %s" % error_string(save_error))
		quit(1)
		return
	print("Wrote generated head strip to %s" % output_path)
	quit()


static func _extract_cell_head(source: Image, source_index: int) -> Image:
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
	# The generated source includes long necks. The paper-doll head piece ends at
	# the jaw, because the torso already owns the neck/shoulder transition.
	used.size.y = maxi(1, int(round(float(used.size.y) * 0.76)))
	var head := cell.get_region(used)
	var fit_scale := minf(
		float(MAX_HEAD_SIZE.x) / float(head.get_width()),
		float(MAX_HEAD_SIZE.y) / float(head.get_height())
	)
	var target_size := Vector2i(
		maxi(1, int(round(head.get_width() * fit_scale))),
		maxi(1, int(round(head.get_height() * fit_scale)))
	)
	head.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	# Generated turnarounds often add a short neck despite the prompt. Removing
	# the final two raster rows keeps the layer as skull/jaw only.
	return head.get_region(
		Rect2i(Vector2i.ZERO, Vector2i(head.get_width(), maxi(1, head.get_height() - 2)))
	)


static func _neutralize_for_skin_tint(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.001:
				continue
			# Runtime owns skin colour. Keep only ink contours and one flat fill;
			# generated lighting must not become a permanent facial identity.
			var neutral := 0.12 if pixel.get_luminance() < 0.32 else 0.92
			image.set_pixel(x, y, Color(neutral, neutral, neutral, pixel.a))
