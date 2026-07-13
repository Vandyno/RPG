extends GutTest

const VerifySpawnSlicePublicInput = preload(
	"res://scripts/tools/verify/verify_spawn_slice_public_input.gd"
)


class EntityStub:
	extends RefCounted

	var global_position := Vector2(40, 50)


class EntitiesStub:
	extends RefCounted

	var entities := {}

	func get_entity(entity_id: String):
		return entities.get(entity_id)


class PlayerStub:
	extends RefCounted

	var world_layer := "surface"
	var world_positions: Array[Vector2] = []
	var facing_values: Array[Vector2] = []

	func set_world_position(position: Vector2) -> void:
		world_positions.append(position)

	func set_facing_direction(direction: Vector2) -> void:
		facing_values.append(direction)


class HudStub:
	extends RefCounted

	var systems_visible := false

	func is_systems_panel_visible() -> bool:
		return systems_visible


class MainStub:
	extends RefCounted

	var entities := EntitiesStub.new()
	var player := PlayerStub.new()
	var hud := HudStub.new()
	var hud_state := {}

	func get_hud_state() -> Dictionary:
		return hud_state


func test_spawn_slice_verifier_keeps_public_input_contract_constants() -> void:
	assert_eq(VerifySpawnSlicePublicInput.VERIFY_SIZE, Vector2i(1152, 648))
	assert_eq(VerifySpawnSlicePublicInput.FORGE_DOOR_ID, "object_harrow_forge_door")
	assert_eq(VerifySpawnSlicePublicInput.FORGE_EXIT_ID, "object_harrow_forge_exit")
	assert_eq(
		VerifySpawnSlicePublicInput.FORGE_LAYER,
		"interior:structure_briarwatch_harrow_forge"
	)
	assert_eq(VerifySpawnSlicePublicInput.HARROW_ID, "npc_harrow_venn_world")
	assert_eq(VerifySpawnSlicePublicInput.HARROW_ACCEPT_TEXT, "I'll find it.")
	assert_eq(VerifySpawnSlicePublicInput.MISSING_TOOLS_QUEST_ID, "quest_missing_tools")
	assert_eq(VerifySpawnSlicePublicInput.TOWN_SQUARE_ID, "poi_briarwatch_square")
	assert_eq(VerifySpawnSlicePublicInput.JOB_BOARD_TITLE, "Warden's Job Board")
	assert_eq(VerifySpawnSlicePublicInput.ROAD_PATROL_JOB_TEXT, "Take Road Patrol Job")
	assert_eq(
		VerifySpawnSlicePublicInput.ROAD_PATROL_QUEST_ID,
		"quest_briarwatch_road_patrol"
	)
	assert_eq(VerifySpawnSlicePublicInput.ROAD_CACHE_ID, "object_road_cache")
	assert_eq(VerifySpawnSlicePublicInput.ROAD_CACHE_GOLD_BUTTON, "TransferTake_ItemGoldCoin")


func test_move_near_positions_player_left_of_entity_and_faces_right() -> void:
	var main := MainStub.new()
	var entity := EntityStub.new()
	main.entities.entities["target"] = entity

	assert_true(VerifySpawnSlicePublicInput.move_near(main, "target"))

	assert_eq(main.player.world_positions, [entity.global_position + Vector2(-8, 0)])
	assert_eq(main.player.facing_values, [Vector2.RIGHT])
	assert_false(VerifySpawnSlicePublicInput.move_near(main, "missing"))


func test_layer_and_transfer_open_helpers_read_main_state() -> void:
	var main := MainStub.new()
	main.player.world_layer = VerifySpawnSlicePublicInput.FORGE_LAYER

	assert_true(VerifySpawnSlicePublicInput.player_is_in_layer(
		main,
		VerifySpawnSlicePublicInput.FORGE_LAYER
	))
	assert_false(VerifySpawnSlicePublicInput.player_is_in_layer(main, "surface"))
	assert_false(VerifySpawnSlicePublicInput.transfer_inventory_is_open(main))

	main.hud.systems_visible = true
	main.hud_state = {"transfer_open": true}

	assert_true(VerifySpawnSlicePublicInput.transfer_inventory_is_open(main))

	main.hud_state = {"transfer_open": false}

	assert_false(VerifySpawnSlicePublicInput.transfer_inventory_is_open(main))
