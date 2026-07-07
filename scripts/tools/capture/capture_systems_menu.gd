extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args := OS.get_cmdline_user_args()
	var width := CaptureSheetHelper.positive_arg(args, 0, 1152)
	var height := CaptureSheetHelper.positive_arg(args, 1, 648)
	var output_path := CaptureSheetHelper.string_arg(args, 2, "res://reports/systems_menu.png")
	var tab_id := CaptureSheetHelper.string_arg(args, 3, "inventory")

	root.size = Vector2i(width, height)
	var main := Main.new()
	root.add_child(main)
	await process_frame
	await process_frame

	_seed_player_facing_menu_state(main)
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


func _seed_player_facing_menu_state(main) -> void:
	if not main.inventory:
		return
	main.inventory.add_item("item_old_toolbox", 1)
	main.inventory.add_item("item_road_hatchet", 1)
	main.inventory.add_item("item_traveler_buckler", 1)
	main.inventory.add_item("item_river_mint", 2)
	main.inventory.add_item("item_roadside_draught", 1)
	main.inventory.add_item("item_gold_coin", 25)
	if main.equipment:
		main.equipment.equip_item_to_slot("item_road_hatchet", "right_hand")
		main.equipment.equip_item_to_slot("item_traveler_buckler", "left_hand")
	if main.spells:
		main.spells.assign_spell_to_slot("spell_fire_blast", "ability_1")
	if main.quests:
		main.quests.start_quest("quest_missing_tools")
	if main.progression:
		main.progression.add_experience(12)
	if main.world_state:
		main.world_state.discover_location("location_briarwatch_crossroads")
