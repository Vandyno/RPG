extends SceneTree

const Main = preload("res://scripts/main/main.gd")
const CaptureSheetHelper = preload("res://scripts/tools/capture/capture_sheet_helper.gd")

const DEFAULT_WIDTH := 1152
const DEFAULT_HEIGHT := 648
const DEFAULT_OUTPUT_PATH := "res://reports/systems_menu.png"
const DEFAULT_TAB_ID := "inventory"
const TRADE_PLAYER_TILE := Vector2i(3, -5)
const TRADE_TARGET_ID := "npc_maera_pike_world"


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var config := capture_config(OS.get_cmdline_user_args())
	var width := int(config["width"])
	var height := int(config["height"])
	var output_path := String(config["output_path"])
	var tab_id := String(config["tab_id"])
	if not await CaptureSheetHelper.capture_main_scene_png(
		self,
		root,
		Main,
		width,
		height,
		output_path,
		"systems menu",
		Callable(self, "prepare_main_for_capture"),
		[tab_id]
	):
		return


static func capture_config(args: Array) -> Dictionary:
	return CaptureSheetHelper.image_capture_config(
		args, DEFAULT_WIDTH, DEFAULT_HEIGHT, DEFAULT_OUTPUT_PATH, ["tab_id"], {"tab_id": DEFAULT_TAB_ID}
	)


static func prepare_main_for_capture(main, width: int, height: int, tab_id: String) -> void:
	seed_player_facing_menu_state(main)
	if tab_id == "trade":
		prepare_trade_context(main)
	main.hud._apply_layout_for_size(Vector2(width, height))
	main.hud.show_systems_panel(tab_id)


static func prepare_trade_context(main) -> void:
	main.player.set_global_tile(TRADE_PLAYER_TILE)
	main.selected_target_id = TRADE_TARGET_ID
	main.manual_target_locked = true
	main._update_nearby()


static func seed_player_facing_menu_state(main) -> void:
	if not main.inventory:
		return
	main.inventory.add_item("item_old_toolbox", 1)
	main.inventory.add_item("item_road_hatchet", 1)
	main.inventory.add_item("item_traveler_buckler", 1)
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
