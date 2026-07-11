extends SceneTree

const AtlasPreview = preload("res://scripts/tools/atlas/atlas_preview.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")
const WorldAtlasValidator = preload("res://scripts/data/world_atlas_validator.gd")

const ATLAS_PATH := "res://data/world_atlas_proposal.json"
const DEFAULT_OUTPUT_PATH := "res://reports/world_atlas/atlas_preview.png"
const DEFAULT_WIDTH := 1536
const DEFAULT_HEIGHT := 1024


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var config := capture_config(OS.get_cmdline_user_args())
	var atlas := WorldAtlasValidator.load_atlas(ATLAS_PATH)
	var warnings := WorldAtlasValidator.validate(atlas)
	var output_path := String(config["output_path"])
	var absolute_path := ProjectSettings.globalize_path(output_path)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if make_error != OK:
		printerr("Could not create atlas output directory: %s" % error_string(make_error))
		quit(1)
		return
	root.size = Vector2i(config["width"], config["height"])
	var viewport := CaptureSheetHelper.create_viewport(root, config["width"], config["height"])
	var preview := AtlasPreview.new()
	preview.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport.add_child(preview)
	preview.setup(atlas, warnings)
	await process_frame
	await process_frame
	var image: Image = await CaptureSheetHelper.capture_viewport_image(self, viewport)
	if image == null:
		printerr("Could not capture atlas preview")
		quit(1)
		return
	var save_error := CaptureSheetHelper.save_png_image(image, output_path)
	if save_error != OK:
		printerr("Could not save atlas preview: %s" % error_string(save_error))
		quit(1)
		return
	for warning in warnings:
		printerr(warning)
	print("Wrote atlas preview to %s (%d validation warnings)" % [absolute_path, warnings.size()])
	quit(0 if warnings.is_empty() else 2)


static func capture_config(args: Array) -> Dictionary:
	return {
		"output_path": String(args[0]) if args.size() > 0 else DEFAULT_OUTPUT_PATH,
		"width": maxi(int(args[1]), 640) if args.size() > 1 else DEFAULT_WIDTH,
		"height": maxi(int(args[2]), 480) if args.size() > 2 else DEFAULT_HEIGHT
	}
