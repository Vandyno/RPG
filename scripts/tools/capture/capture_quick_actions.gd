extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var width := CaptureSheetHelper.positive_arg(args, 0, 1152)
	var height := CaptureSheetHelper.positive_arg(args, 1, 648)
	var output_path := CaptureSheetHelper.string_arg(args, 2, "res://reports/quick_actions.png")

	root.size = Vector2i(width, height)
	var main := Main.new()
	root.add_child(main)
	await process_frame
	await process_frame

	main.set_process(false)
	main.hud._apply_layout_for_size(Vector2(width, height))
	main.hud._refresh_context_actions(
		{
			"nearby": "Rest Bridge Campfire",
			"nearby_targets":
			[
				{
					"id": "object_roadside_campfire",
					"name": "Rest Bridge Campfire",
					"kind": "rest",
					"detail": "Bridge campfire",
					"navigation": "Near the bridge",
					"selected": true
				}
			],
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
