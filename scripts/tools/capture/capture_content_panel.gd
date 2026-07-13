extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")

const DEFAULT_WIDTH := 1152
const DEFAULT_HEIGHT := 648
const DEFAULT_OUTPUT_PATH := "res://reports/content_panel.png"
const DEFAULT_MODE := "dialogue"


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var config := capture_config(OS.get_cmdline_user_args())
	var width := int(config["width"])
	var height := int(config["height"])
	var output_path := String(config["output_path"])
	var mode := String(config["mode"])
	if not await CaptureSheetHelper.capture_main_scene_png(
		self,
		root,
		Main,
		width,
		height,
		output_path,
		"content panel",
		Callable(self, "prepare_main_for_capture"),
		[mode]
	):
		return


static func capture_config(args: Array) -> Dictionary:
	return CaptureSheetHelper.image_capture_config(
		args, DEFAULT_WIDTH, DEFAULT_HEIGHT, DEFAULT_OUTPUT_PATH, ["mode"], {"mode": DEFAULT_MODE}
	)


static func prepare_main_for_capture(main, width: int, height: int, mode: String) -> void:
	main.hud._apply_layout_for_size(Vector2(width, height))
	show_fixture(main, mode)


static func show_fixture(main, mode: String) -> void:
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
