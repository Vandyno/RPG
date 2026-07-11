extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")

const DEFAULT_OUTPUT_DIR := "res://reports/world_structure_mockup"
const DEFAULT_WIDTH := 1152
const DEFAULT_HEIGHT := 648
const FORGE_DOOR_ID := "object_harrow_forge_door"
const TOWN_HALL_DOOR_ID := "object_briarwatch_town_hall_door"


func _initialize() -> void:
	_capture.call_deferred()


# gdlint:disable=max-returns
func _capture() -> void:
	var config := capture_config(OS.get_cmdline_user_args())
	var output_dir := String(config["output_dir"])
	var width := int(config["width"])
	var height := int(config["height"])
	var absolute_dir := ProjectSettings.globalize_path(output_dir)
	var make_error := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if make_error != OK:
		printerr("Could not create output directory %s: %s" % [absolute_dir, error_string(make_error)])
		quit(1)
		return

	root.size = Vector2i(width, height)
	var viewport := CaptureSheetHelper.create_viewport(root, width, height)
	var main := Main.new()
	viewport.add_child(main)
	await process_frame
	await process_frame
	main.begin_new_game()
	main.debug_character_creator.apply_to_player()
	await process_frame

	prepare_surface_overview(main)
	await _settle(main)
	if not await _save_viewport_image(viewport, output_dir.path_join("surface_overview.png")):
		return
	prepare_outside_gate_armour(main)
	await _settle(main, false)
	if not await _save_viewport_image(viewport, output_dir.path_join("outside_gate_armour.png")):
		return
	main.set_process(true)

	var town_hall_door = main.entities.get_entity(TOWN_HALL_DOOR_ID)
	if not town_hall_door:
		printerr("Could not find Briarwatch town hall door.")
		quit(1)
		return
	prepare_town_hall_entrance(main, town_hall_door)
	await _settle(main)
	if not await _save_viewport_image(viewport, output_dir.path_join("town_hall_entrance.png")):
		return

	main._interact_portal(town_hall_door)
	await _settle(main)
	if not await _save_viewport_image(viewport, output_dir.path_join("town_hall_interior.png")):
		return

	var town_hall_exit = main.entities.get_entity("object_briarwatch_town_hall_exit")
	if not town_hall_exit:
		printerr("Could not find Briarwatch town hall exit.")
		quit(1)
		return
	main._interact_portal(town_hall_exit)
	await _settle(main)

	var door = main.entities.get_entity(FORGE_DOOR_ID)
	if not door:
		printerr("Could not find Harrow forge door.")
		quit(1)
		return
	prepare_forge_entrance(main, door)
	await _settle(main)
	if not await _save_viewport_image(viewport, output_dir.path_join("surface_forge_entrance.png")):
		return

	main._interact_portal(door)
	await _settle(main)
	if not await _save_viewport_image(viewport, output_dir.path_join("forge_interior.png")):
		return

	print("Wrote world structure captures to %s" % absolute_dir)
	quit()
# gdlint:enable=max-returns


static func capture_config(args: Array) -> Dictionary:
	return CaptureSheetHelper.capture_config(args, DEFAULT_OUTPUT_DIR, DEFAULT_WIDTH, DEFAULT_HEIGHT)


static func prepare_surface_overview(main) -> void:
	main.player.set_global_tile(Vector2i(3, 3))
	main.player.set_facing_direction(Vector2.RIGHT)
	main.selected_target_id = ""
	main.manual_target_locked = false
	main._sync_camera_to_player()


static func prepare_outside_gate_armour(main) -> void:
	main.selected_target_id = ""
	main.manual_target_locked = false
	main.set_process(false)
	main.camera.global_position = GridMath.tile_to_world(Vector2i(-18, 0))
	main.camera.reset_smoothing()


static func prepare_forge_entrance(main, door) -> void:
	main.player.set_world_position(door.global_position + Vector2(-24.0, 18.0))
	main.player.set_facing_direction((door.global_position - main.player.global_position).normalized())
	main.selected_target_id = FORGE_DOOR_ID
	main.manual_target_locked = true
	main._update_nearby()
	main._sync_camera_to_player()


static func prepare_town_hall_entrance(main, door) -> void:
	main.player.set_world_position(door.global_position + Vector2(-24.0, 18.0))
	main.player.set_facing_direction((door.global_position - main.player.global_position).normalized())
	main.selected_target_id = TOWN_HALL_DOOR_ID
	main.manual_target_locked = true
	main._update_nearby()
	main._sync_camera_to_player()


func _settle(main, sync_camera: bool = true) -> void:
	if sync_camera and main and main.has_method("_sync_camera_to_player"):
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
