extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")

const DEFAULT_WIDTH := 1152
const DEFAULT_HEIGHT := 648
const DEFAULT_OUTPUT_PATH := "res://reports/target_panel.png"


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var config := capture_config(OS.get_cmdline_user_args())
	var width := int(config["width"])
	var height := int(config["height"])
	var output_path := String(config["output_path"])
	if not await CaptureSheetHelper.capture_main_scene_png(
		self,
		root,
		Main,
		width,
		height,
		output_path,
		"target panel",
		Callable(self, "prepare_main_for_capture")
	):
		return


static func capture_config(args: Array) -> Dictionary:
	return CaptureSheetHelper.image_capture_config(
		args, DEFAULT_WIDTH, DEFAULT_HEIGHT, DEFAULT_OUTPUT_PATH
	)


static func prepare_main_for_capture(main, width: int, height: int) -> void:
	main.hud._apply_layout_for_size(Vector2(width, height))
	main.hud.toggle_target_picker()
