extends SceneTree

const GRID_SIZE := 4
const FRAME_SIZE := Vector2i(64, 64)
const FRAME_COUNT := 16

const LAYER_CONFIG := {
	"torso": {"anchor": Vector2i(32, 30), "max_size": Vector2i(18, 15)},
	"waist_hips": {"anchor": Vector2i(32, 38), "max_size": Vector2i(18, 11)},
	"left_hand": {"anchor": Vector2i(20, 34), "max_size": Vector2i(7, 8)},
	"right_hand": {"anchor": Vector2i(44, 34), "max_size": Vector2i(7, 8)},
	"left_foot": {"anchor": Vector2i(24, 42), "max_size": Vector2i(10, 9)},
	"right_foot": {"anchor": Vector2i(40, 42), "max_size": Vector2i(10, 9)},
	"chest": {"anchor": Vector2i(32, 30), "max_size": Vector2i(18, 20)}
}

const TORSO_SOURCE_FRAMES := [
	[2, false], [3, false], [15, false], [13, false], [12, false], [13, true], [15, true],
	[3, true], [2, true], [8, false], [5, false], [6, false], [4, false], [6, true],
	[5, true], [8, true]
]

const CHEST_SOURCE_FRAMES := [
	[3, false], [0, false], [15, false], [13, false], [14, false], [13, true], [15, true],
	[0, true], [3, true], [5, false], [6, false], [7, false], [6, false], [7, true],
	[6, true], [5, true]
]


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 3:
		printerr("Usage: pack_generated_body_layer_grid.gd -- <input.png> <output.png> <slot>")
		quit(1)
		return
	var slot_id := String(args[2])
	if not LAYER_CONFIG.has(slot_id):
		printerr("Unknown body layer slot: %s" % slot_id)
		quit(1)
		return
	var source := Image.new()
	var load_error := source.load(String(args[0]))
	if load_error != OK:
		printerr("Could not load layer source: %s" % error_string(load_error))
		quit(1)
		return
	source.convert(Image.FORMAT_RGBA8)
	var config: Dictionary = LAYER_CONFIG[slot_id]
	var strip := Image.create(FRAME_SIZE.x * FRAME_COUNT, FRAME_SIZE.y, false, Image.FORMAT_RGBA8)
	strip.fill(Color.TRANSPARENT)
	for frame_index in FRAME_COUNT:
		var source_index := frame_index
		var mirror := false
		if slot_id == "torso" or slot_id == "waist_hips" or slot_id == "chest":
			var source_specs: Array = CHEST_SOURCE_FRAMES if slot_id == "chest" else TORSO_SOURCE_FRAMES
			var source_spec: Array = source_specs[frame_index]
			source_index = int(source_spec[0])
			mirror = bool(source_spec[1])
		var layer := _extract_cell(source, source_index, config["max_size"], slot_id)
		if mirror:
			layer.flip_x()
		var anchor: Vector2i = config["anchor"]
		var paste_position := Vector2i(
			frame_index * FRAME_SIZE.x + anchor.x - layer.get_width() / 2,
			anchor.y - layer.get_height() / 2
		)
		strip.blit_rect(layer, Rect2i(Vector2i.ZERO, layer.get_size()), paste_position)
	var output_path := String(args[1])
	var make_error := DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
	if make_error != OK:
		printerr("Could not create layer output directory: %s" % error_string(make_error))
		quit(1)
		return
	var save_error := strip.save_png(output_path)
	if save_error != OK:
		printerr("Could not save body layer strip: %s" % error_string(save_error))
		quit(1)
		return
	print("Wrote generated %s strip to %s" % [slot_id, output_path])
	quit()


static func _extract_cell(
	source: Image, source_index: int, max_size: Vector2i, slot_id: String
) -> Image:
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
	if slot_id == "waist_hips":
		var waist_start := int(round(float(used.size.y) * 0.52))
		used.position.y += waist_start
		used.size.y = maxi(1, used.size.y - waist_start)
	var layer := cell.get_region(used)
	var fit_scale := minf(
		float(max_size.x) / float(layer.get_width()),
		float(max_size.y) / float(layer.get_height())
	)
	var target_size := Vector2i(
		maxi(1, int(round(layer.get_width() * fit_scale))),
		maxi(1, int(round(layer.get_height() * fit_scale)))
	)
	layer.resize(target_size.x, target_size.y, Image.INTERPOLATE_LANCZOS)
	if slot_id != "chest":
		_flatten_ink_fill(layer)
	if slot_id == "torso":
		_remove_torso_neck(layer)
	return layer


static func _flatten_ink_fill(layer: Image) -> void:
	for y in layer.get_height():
		for x in layer.get_width():
			var pixel := layer.get_pixel(x, y)
			if pixel.a <= 0.001:
				continue
			var value := 0.12 if pixel.get_luminance() < 0.55 else 0.92
			layer.set_pixel(x, y, Color(value, value, value, pixel.a))


static func _remove_torso_neck(layer: Image) -> void:
	var center_x := layer.get_width() / 2
	var neck_half_width := maxi(1, layer.get_width() / 7)
	var neck_height := maxi(1, layer.get_height() / 4)
	for y in neck_height:
		for x in range(center_x - neck_half_width, center_x + neck_half_width + 1):
			if x >= 0 and x < layer.get_width():
				layer.set_pixel(x, y, Color.TRANSPARENT)
