extends SceneTree

const GRID_SIZE := 4
const FRAME_SIZE := Vector2i(64, 64)
const FRAME_COUNT := 16
const HAIR_ANCHOR := Vector2i(32, 18)
const MAX_HAIR_SIZE := Vector2i(14, 7)

# Eight cardinal/diagonal source views are reused for their neighboring
# half-directions. Exact 16-cell output remains compatible with FacingBuckets.
const SOURCE_FRAMES := [0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		printerr("Usage: pack_generated_hair_grid.gd -- <input.png> <output.png>")
		quit(1)
		return
	var source := Image.new()
	var load_error := source.load(String(args[0]))
	if load_error != OK:
		printerr("Could not load hair source: %s" % error_string(load_error))
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	var strip := Image.create(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	strip.fill(Color.TRANSPARENT)
	for frame_index in FRAME_COUNT:
		var hair := _extract_cell(source, SOURCE_FRAMES[frame_index])
		_neutralize_for_hair_tint(hair)
		var paste_position := Vector2i(
			frame_index * FRAME_SIZE.x + HAIR_ANCHOR.x - hair.get_width() / 2,
			HAIR_ANCHOR.y - hair.get_height()
		)
		strip.blit_rect(hair, Rect2i(Vector2i.ZERO, hair.get_size()), paste_position)
	var output_path := String(args[1])
	var make_error := DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	if make_error != OK:
		printerr("Could not create hair output directory: %s" % error_string(make_error))
		quit(1)
		return
	var save_error := strip.save_png(output_path)
	if save_error != OK:
		printerr("Could not save hair strip: %s" % error_string(save_error))
		quit(1)
		return
	print("Wrote generated hair strip to %s" % output_path)
	quit()


static func _extract_cell(source: Image, source_index: int) -> Image:
	var column := source_index % GRID_SIZE
	var row := source_index / GRID_SIZE
	var x0 := int(floor(float(column) * source.get_width() / GRID_SIZE))
	var x1 := int(floor(float(column + 1) * source.get_width() / GRID_SIZE))
	var y0 := int(floor(float(row) * source.get_height() / GRID_SIZE))
	var y1 := int(floor(float(row + 1) * source.get_height() / GRID_SIZE))
	var cell := source.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
	# Chroma removal intentionally leaves a soft matte. Remove low-alpha haze so
	# the used rectangle follows the opaque hair instead of the whole source cell.
	for y in cell.get_height():
		for x in cell.get_width():
			var pixel := cell.get_pixel(x, y)
			if pixel.a < 0.50:
				cell.set_pixel(x, y, Color.TRANSPARENT)
	var used := cell.get_used_rect()
	if used.size == Vector2i.ZERO:
		return Image.create(1, 1, false, Image.FORMAT_RGBA8)
	var hair := cell.get_region(used)
	var fit_scale := minf(
		float(MAX_HAIR_SIZE.x) / float(hair.get_width()),
		float(MAX_HAIR_SIZE.y) / float(hair.get_height())
	)
	var target_size := Vector2i(
		maxi(1, int(round(hair.get_width() * fit_scale))),
		maxi(1, int(round(hair.get_height() * fit_scale)))
	)
	hair.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	return hair


static func _neutralize_for_hair_tint(image: Image) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a <= 0.001:
				continue
			image.set_pixel(x, y, Color(0.88, 0.88, 0.88, pixel.a))
