extends GutTest

const CaptureSystemsMenu = preload("res://scripts/tools/capture/capture_systems_menu.gd")


class InventoryStub:
	extends RefCounted

	var added: Array[String] = []

	func add_item(item_id: String, count: int) -> void:
		added.append("%s:%d" % [item_id, count])


class EquipmentStub:
	extends RefCounted

	var equipped: Array[String] = []

	func equip_item_to_slot(item_id: String, slot_id: String) -> void:
		equipped.append("%s:%s" % [slot_id, item_id])


class SpellsStub:
	extends RefCounted

	var assignments: Array[String] = []

	func assign_spell_to_slot(spell_id: String, slot_id: String) -> void:
		assignments.append("%s:%s" % [slot_id, spell_id])


class QuestsStub:
	extends RefCounted

	var started: Array[String] = []

	func start_quest(quest_id: String) -> void:
		started.append(quest_id)


class ProgressionStub:
	extends RefCounted

	var experience := 0

	func add_experience(amount: int) -> void:
		experience += amount


class WorldStateStub:
	extends RefCounted

	var locations: Array[String] = []

	func discover_location(location_id: String) -> void:
		locations.append(location_id)


class PlayerStub:
	extends RefCounted

	var tile := Vector2i.ZERO

	func set_global_tile(next_tile: Vector2i) -> void:
		tile = next_tile


class HudStub:
	extends RefCounted

	var layout_sizes: Array[Vector2] = []
	var shown_tabs: Array[String] = []

	func _apply_layout_for_size(size: Vector2) -> void:
		layout_sizes.append(size)

	func show_systems_panel(tab_id: String) -> void:
		shown_tabs.append(tab_id)


class MainStub:
	extends RefCounted

	var inventory = InventoryStub.new()
	var equipment = EquipmentStub.new()
	var spells = SpellsStub.new()
	var quests = QuestsStub.new()
	var progression = ProgressionStub.new()
	var world_state = WorldStateStub.new()
	var player = PlayerStub.new()
	var hud = HudStub.new()
	var selected_target_id := ""
	var manual_target_locked := false
	var update_nearby_calls := 0

	func _update_nearby() -> void:
		update_nearby_calls += 1


func test_capture_config_uses_defaults_and_reads_args() -> void:
	assert_eq(
		CaptureSystemsMenu.capture_config([]),
		{
			"width": CaptureSystemsMenu.DEFAULT_WIDTH,
			"height": CaptureSystemsMenu.DEFAULT_HEIGHT,
			"output_path": CaptureSystemsMenu.DEFAULT_OUTPUT_PATH,
			"tab_id": CaptureSystemsMenu.DEFAULT_TAB_ID
		}
	)
	assert_eq(
		CaptureSystemsMenu.capture_config(["900", "500", "res://reports/trade.png", "trade"]),
		{
			"width": 900,
			"height": 500,
			"output_path": "res://reports/trade.png",
			"tab_id": "trade"
		}
	)


func test_seed_player_facing_menu_state_adds_representative_menu_data() -> void:
	var main := MainStub.new()

	CaptureSystemsMenu.seed_player_facing_menu_state(main)

	assert_eq(main.inventory.added[0], "item_old_toolbox:1")
	assert_true(main.inventory.added.has("item_gold_coin:25"))
	assert_eq(
		main.equipment.equipped,
		["right_hand:item_road_hatchet", "left_hand:item_traveler_buckler"]
	)
	assert_eq(main.spells.assignments, ["ability_1:spell_fire_blast"])
	assert_eq(main.quests.started, ["quest_missing_tools"])
	assert_eq(main.progression.experience, 12)
	assert_eq(main.world_state.locations, ["location_briarwatch_crossroads"])


func test_prepare_main_for_capture_applies_layout_and_opens_requested_tab() -> void:
	var main := MainStub.new()

	CaptureSystemsMenu.prepare_main_for_capture(main, 960, 540, "character")

	assert_eq(main.hud.layout_sizes, [Vector2(960, 540)])
	assert_eq(main.hud.shown_tabs, ["character"])
	assert_eq(main.update_nearby_calls, 0)


func test_prepare_main_for_capture_sets_trade_context_for_trade_tab() -> void:
	var main := MainStub.new()

	CaptureSystemsMenu.prepare_main_for_capture(main, 960, 540, "trade")

	assert_eq(main.player.tile, CaptureSystemsMenu.TRADE_PLAYER_TILE)
	assert_eq(main.selected_target_id, CaptureSystemsMenu.TRADE_TARGET_ID)
	assert_true(main.manual_target_locked)
	assert_eq(main.update_nearby_calls, 1)
	assert_eq(main.hud.shown_tabs, ["trade"])
