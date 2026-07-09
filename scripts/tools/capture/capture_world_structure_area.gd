extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var output_dir := CaptureSheetHelper.string_arg(args, 0, "res://reports/world_structure_mockup")
	var width := CaptureSheetHelper.positive_arg(args, 1, 1152)
	var height := CaptureSheetHelper.positive_arg(args, 2, 648)
	var absolute_dir := ProjectSettings.globalize_path(output_dir)
	DirAccess.make_dir_recursive_absolute(absolute_dir)

	root.size = Vector2i(width, height)
	var viewport := CaptureSheetHelper.create_viewport(root, width, height)
	var main := Main.new()
	viewport.add_child(main)
	await process_frame
	await process_frame

	main.player.set_global_tile(Vector2i(3, 3))
	main.player.set_facing_direction(Vector2.RIGHT)
	main.selected_target_id = ""
	main.manual_target_locked = false
	main._sync_camera_to_player()
	await _settle(main)
	if not await _save_viewport_image(viewport, output_dir.path_join("surface_overview.png")):
		return

	var door = main.entities.get_entity("object_harrow_forge_door")
	if not door:
		printerr("Could not find Harrow forge door.")
		quit(1)
		return
	main.player.set_world_position(door.global_position + Vector2(-24.0, 18.0))
	main.player.set_facing_direction((door.global_position - main.player.global_position).normalized())
	main.selected_target_id = "object_harrow_forge_door"
	main.manual_target_locked = true
	main._update_nearby()
	main._sync_camera_to_player()
	await _settle(main)
	if not await _save_viewport_image(viewport, output_dir.path_join("surface_forge_entrance.png")):
		return

	main._interact_portal(door)
	await _settle(main)
	if not await _save_viewport_image(viewport, output_dir.path_join("forge_interior.png")):
		return

	print("Wrote world structure captures to %s" % absolute_dir)
	quit()


func _settle(main) -> void:
	if main and main.has_method("_sync_camera_to_player"):
		main._sync_camera_to_player()
	await process_frame
	await process_frame
	await process_frame


func _save_viewport_image(viewport: SubViewport, output_path: String) -> bool:
	var image: Image = await CaptureSheetHelper.capture_viewport_image(self, viewport)
	if image == null:
		printerr("Could not capture world structure image. Run without --headless.")
		quit(1)
		return false
	var error := CaptureSheetHelper.save_png_image(image, output_path)
	if error != OK:
		printerr("Could not save world structure capture: %s" % error_string(error))
		quit(1)
		return false
	return true
