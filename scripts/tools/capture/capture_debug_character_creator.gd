extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")

const WIDTH := 1152
const HEIGHT := 648
const OUTPUT_PATH := "res://reports/character_appearance/soft_eyes.png"


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	root.size = Vector2i(WIDTH, HEIGHT)
	var viewport := CaptureSheetHelper.create_viewport(root, WIDTH, HEIGHT)
	var main := Main.new()
	viewport.add_child(main)
	await process_frame
	await process_frame
	main.begin_new_game()
	main.debug_character_creator.current_eye_index = 1
	main.debug_character_creator._refresh_all()
	for _frame_index in 8:
		await process_frame

	var image: Image = await CaptureSheetHelper.capture_viewport_image(self, viewport)
	if image == null:
		printerr("Could not capture character appearance panel.")
		quit(1)
		return
	var absolute_path := ProjectSettings.globalize_path(OUTPUT_PATH)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if make_error != OK:
		printerr("Could not create character appearance capture directory: %s" % error_string(make_error))
		quit(1)
		return
	var save_error := CaptureSheetHelper.save_png_image(image, absolute_path)
	if save_error != OK:
		printerr("Could not save character appearance capture: %s" % error_string(save_error))
		quit(1)
		return
	print("Wrote character appearance capture to %s" % absolute_path)
	quit()
