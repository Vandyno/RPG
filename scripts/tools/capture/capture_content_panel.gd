extends SceneTree

const Main = preload("res://scripts/main/main.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var width := _positive_arg(args, 0, 1152)
	var height := _positive_arg(args, 1, 648)
	var output_path := _string_arg(args, 2, "res://reports/content_panel.png")
	var mode := _string_arg(args, 3, "dialogue")

	root.size = Vector2i(width, height)
	var main := Main.new()
	root.add_child(main)
	await process_frame
	await process_frame

	main.hud._apply_layout_for_size(Vector2(width, height))
	_show_fixture(main, mode)
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


func _show_fixture(main, mode: String) -> void:
	match mode:
		"readable":
			main.hud.show_content_card(
				"Road Notice",
				(
					"Road wardens report loose stones near the west road. Keep carts slow by the "
					+ "bridge and report missing tools to Harrow Venn at the forge."
				),
				[],
				"readable"
			)
		"place":
			main.hud.show_content_card(
				"Briarwatch Square",
				(
					"A compact town green beside the river bridge. The forge, market stall, "
					+ "road notice, and job board all face the crossing."
				),
				[
					{"id": "inspect_jobs", "text": "Inspect Job Board"},
					{"id": "take_patrol", "text": "Take Road Patrol Job", "subtitle": "Starts a local task."}
				],
				"place"
			)
		"result":
			main.hud.show_content_card(
				"Road Patrol Complete",
				"You mark the last road post and return to the square with fresh notes for the wardens.",
				[],
				"response"
			)
		_:
			main.hud.show_content_card(
				"Harrow Venn",
				"Evening. You look like someone who gets their hands dirty.\n\nWhat can I do for you?",
				[
					{"id": "ask_tools", "text": "Ask about tools"},
					{
						"id": "turn_in_toolbox",
						"text": "Turn in Toolbox",
						"effects": [
							{"type": "complete_quest", "quest_id": "quest_missing_tools"},
							{"type": "add_experience", "amount": 120}
						],
						"response": "Harrow weighs the old toolbox in both hands and nods."
					},
					{
						"id": "forge_services",
						"text": "Forge Services",
						"subtitle": "Craft, repair, and improve gear."
					}
				],
				"dialogue"
			)
