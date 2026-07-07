extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const MainSystemsActions = preload("res://scripts/main/actions/main_systems_actions.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var width := _positive_arg(args, 0, 1152)
	var height := _positive_arg(args, 1, 648)
	var output_path := _string_arg(args, 2, "res://reports/body_loot_transfer.png")

	root.size = Vector2i(width, height)
	var main := Main.new()
	root.add_child(main)
	await process_frame
	await process_frame

	_defeat_hostile_actor(main)
	var body = main.entities.get_entity("body_npc_road_thug")
	if not body:
		printerr("Body was not created.")
		quit(1)
		return
	main.player.set_world_position(body.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	main.selected_target_id = body.get_entity_id()
	main.manual_target_locked = true
	main._update_nearby()
	main._handle_interact_requested()
	main.hud._apply_layout_for_size(Vector2(width, height))
	main.hud.set_systems_tab("inventory")
	await process_frame
	await process_frame

	var image := root.get_texture().get_image()
	var error := image.save_png(output_path)
	if error != OK:
		printerr("Could not save body loot capture: %s" % error_string(error))
		quit(1)
		return
	quit()


func _defeat_hostile_actor(main) -> void:
	var actor = main.entities.get_entity("npc_road_thug")
	main.player.set_world_position(actor.global_position + Vector2(-8.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	for _index in range(8):
		if not main.entities.get_entity("npc_road_thug"):
			return
		MainSystemsActions.handle_aim(MainSystemsActions.aim_context(main), "attack", Vector2.RIGHT)


func _positive_arg(args: PackedStringArray, index: int, fallback: int) -> int:
	if index >= args.size() or not args[index].is_valid_int():
		return fallback
	return maxi(1, int(args[index]))


func _string_arg(args: PackedStringArray, index: int, fallback: String) -> String:
	if index >= args.size() or args[index].is_empty():
		return fallback
	return args[index]
