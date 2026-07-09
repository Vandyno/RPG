extends GutTest

const VerifyBodyLootTransferClick = preload(
	"res://scripts/tools/verify/verify_body_loot_transfer_click.gd"
)


class EntityStub:
	extends RefCounted

	var global_position := Vector2(30, 40)
	var entity_id := "body_npc_road_thug"

	func get_entity_id() -> String:
		return entity_id


class PlayerStub:
	extends RefCounted

	var world_positions: Array[Vector2] = []
	var facing_values: Array[Vector2] = []

	func set_world_position(position: Vector2) -> void:
		world_positions.append(position)

	func set_facing_direction(direction: Vector2) -> void:
		facing_values.append(direction)


class HudStub:
	extends RefCounted

	var layout_sizes: Array[Vector2] = []
	var tabs: Array[String] = []

	func _apply_layout_for_size(size: Vector2) -> void:
		layout_sizes.append(size)

	func set_systems_tab(tab_id: String) -> void:
		tabs.append(tab_id)


class MainStub:
	extends RefCounted

	var player := PlayerStub.new()
	var hud := HudStub.new()
	var selected_target_id := ""
	var manual_target_locked := false
	var update_nearby_calls := 0
	var interact_calls := 0

	func _update_nearby() -> void:
		update_nearby_calls += 1

	func _handle_interact_requested() -> void:
		interact_calls += 1


func test_body_loot_transfer_verifier_keeps_viewport_target_and_button_contract() -> void:
	assert_eq(VerifyBodyLootTransferClick.VERIFY_SIZE, Vector2i(1152, 648))
	assert_eq(VerifyBodyLootTransferClick.ROAD_THUG_ID, "npc_road_thug")
	assert_eq(VerifyBodyLootTransferClick.ROAD_THUG_BODY_ID, "body_npc_road_thug")
	assert_eq(VerifyBodyLootTransferClick.ROAD_CACHE_ID, "object_road_cache")
	assert_eq(VerifyBodyLootTransferClick.PEOPLE_TEST_ID, "npc_people_test_human")
	assert_eq(VerifyBodyLootTransferClick.PEOPLE_TEST_BODY_ID, "body_npc_people_test_human")
	assert_eq(
		VerifyBodyLootTransferClick.expected_transfer_button_names(),
		[
			"TransferTake_ItemHuntingBow",
			"TransferPut_ItemHuntingBow",
			"TransferTake_ItemGoldCoin",
			"TransferPut_ItemGoldCoin",
			"TransferTake_ItemTrainingSword",
		]
	)


func test_open_transfer_target_positions_player_locks_target_and_opens_inventory() -> void:
	var main := MainStub.new()
	var entity := EntityStub.new()

	VerifyBodyLootTransferClick._open_transfer_target(main, entity, Vector2i(960, 540))

	assert_eq(main.player.world_positions, [entity.global_position + Vector2(-8, 0)])
	assert_eq(main.player.facing_values, [Vector2.RIGHT])
	assert_eq(main.selected_target_id, "body_npc_road_thug")
	assert_true(main.manual_target_locked)
	assert_eq(main.update_nearby_calls, 1)
	assert_eq(main.interact_calls, 1)
	assert_eq(main.hud.layout_sizes, [Vector2(960, 540)])
	assert_eq(main.hud.tabs, ["inventory"])
