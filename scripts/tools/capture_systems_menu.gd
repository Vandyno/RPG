extends SceneTree

const Main = preload("res://scripts/main/main.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var width := _positive_arg(args, 0, 1152)
	var height := _positive_arg(args, 1, 648)
	var output_path := _string_arg(args, 2, "res://reports/systems_menu.png")
	var tab_id := _string_arg(args, 3, "inventory")

	root.size = Vector2i(width, height)
	var main := Main.new()
	root.add_child(main)
	await process_frame
	await process_frame

	if tab_id == "trade":
		main.player.set_global_tile(Vector2i(3, -5))
		main.selected_target_id = "npc_maera_pike_world"
		main.manual_target_locked = true
		main._update_nearby()
	main.hud._apply_layout_for_size(Vector2(width, height))
	main.hud.show_systems_panel(tab_id)
	await process_frame
	await process_frame

	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		printerr("Could not save systems menu capture: %s" % error_string(error))
		quit(1)
		return
	quit()


func _positive_arg(args: PackedStringArray, index: int, fallback: int) -> int:
	if index >= args.size() or not args[index].is_valid_int():
		return fallback
	return maxi(1, int(args[index]))


func _string_arg(args: PackedStringArray, index: int, fallback: String) -> String:
	if index >= args.size() or args[index].is_empty():
		return fallback
	return args[index]
