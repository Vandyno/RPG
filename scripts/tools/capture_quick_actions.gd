extends SceneTree

const Main = preload("res://scripts/main/main.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var width := _positive_arg(args, 0, 1152)
	var height := _positive_arg(args, 1, 648)
	var output_path := _string_arg(args, 2, "res://reports/quick_actions.png")

	root.size = Vector2i(width, height)
	var main := Main.new()
	root.add_child(main)
	await process_frame
	await process_frame

	main.set_process(false)
	main.hud._apply_layout_for_size(Vector2(width, height))
	main.hud._refresh_context_actions(
		{
			"context_actions": [
				{"id": "dialogue:accept", "text": "I'll find it."},
				{"id": "poi:sharpen", "text": "Sharpen Road Hatchet"},
				{"id": "trade:shop_crossroads_peddler", "text": "Trade"}
			]
		}
	)
	await process_frame

	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		printerr("Could not save quick actions capture: %s" % error_string(error))
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
