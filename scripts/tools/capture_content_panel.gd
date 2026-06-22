extends SceneTree

const Main = preload("res://scripts/main/main.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var width := _positive_arg(args, 0, 1152)
	var height := _positive_arg(args, 1, 648)
	var output_path := _string_arg(args, 2, "res://reports/content_panel.png")

	root.size = Vector2i(width, height)
	var main := Main.new()
	root.add_child(main)
	await process_frame
	await process_frame

	main.hud._apply_layout_for_size(Vector2(width, height))
	main.hud.show_content_card(
		"Harrow Venn",
		"Evening. You look like someone who gets their hands dirty.\n\nWhat can I do for you?",
		[
			{"id": "ask_tools", "text": "Ask about tools"},
			{"id": "turn_in_toolbox", "text": "Turn in Toolbox"},
			{"id": "forge_services", "text": "Forge Services"},
			{"id": "leave", "text": "Leave"}
		],
		"dialogue"
	)
	await process_frame
	await process_frame

	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		printerr("Could not save content panel capture: %s" % error_string(error))
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
