extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const MainSystemsActions = preload("res://scripts/main/actions/main_systems_actions.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")

const DEFAULT_WIDTH := 1152
const DEFAULT_HEIGHT := 648
const DEFAULT_OUTPUT_PATH := "res://reports/body_loot_transfer.png"
const HOSTILE_ID := "npc_road_thug"
const BODY_ID := HOSTILE_ID
const BODY_INTERACTION_OFFSET := Vector2(-8.0, 0.0)


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
		"body loot",
		Callable(self, "prepare_main_for_capture"),
		[],
		2,
		"Body was not created."
	):
		return


static func capture_config(args: Array) -> Dictionary:
	return CaptureSheetHelper.image_capture_config(
		args, DEFAULT_WIDTH, DEFAULT_HEIGHT, DEFAULT_OUTPUT_PATH
	)


static func prepare_main_for_capture(main, width: int, height: int) -> bool:
	defeat_hostile_actor(main)
	var body = main.entities.get_entity(BODY_ID)
	if not body:
		return false
	position_player_for_body_loot(main, body, width, height)
	return true


static func position_player_for_body_loot(main, body, width: int, height: int) -> void:
	main.player.set_world_position(body.global_position + BODY_INTERACTION_OFFSET)
	main.player.set_facing_direction(Vector2.RIGHT)
	main.selected_target_id = body.get_entity_id()
	main.manual_target_locked = true
	main._update_nearby()
	main._handle_interact_requested()
	main.hud._apply_layout_for_size(Vector2(width, height))
	main.hud.set_systems_tab("inventory")


static func defeat_hostile_actor(main) -> void:
	var actor = main.entities.get_entity(HOSTILE_ID)
	if not actor:
		return
	main.player.set_world_position(actor.global_position + BODY_INTERACTION_OFFSET)
	main.player.set_facing_direction(Vector2.RIGHT)
	for _index in range(8):
		actor = main.entities.get_entity(HOSTILE_ID)
		if actor and ActorRules.is_dead_actor_data(actor.data):
			return
		MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.RIGHT)
