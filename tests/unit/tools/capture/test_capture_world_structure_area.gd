extends GutTest

const CaptureWorldStructureArea = preload(
	"res://scripts/tools/capture/capture_world_structure_area.gd"
)


class PlayerStub:
	extends RefCounted

	var global_position := Vector2.ZERO
	var global_tiles: Array[Vector2i] = []
	var world_positions: Array[Vector2] = []
	var facing_values: Array[Vector2] = []

	func set_global_tile(tile: Vector2i) -> void:
		global_tiles.append(tile)

	func set_world_position(position: Vector2) -> void:
		global_position = position
		world_positions.append(position)

	func set_facing_direction(direction: Vector2) -> void:
		facing_values.append(direction)


class MainStub:
	extends RefCounted

	var player := PlayerStub.new()
	var selected_target_id := "old_target"
	var manual_target_locked := true
	var sync_calls := 0
	var update_nearby_calls := 0

	func _sync_camera_to_player() -> void:
		sync_calls += 1

	func _update_nearby() -> void:
		update_nearby_calls += 1


class DoorStub:
	extends RefCounted

	var global_position := Vector2(100, 70)


func test_capture_config_uses_defaults_and_reads_args() -> void:
	assert_eq(
		CaptureWorldStructureArea.capture_config([]),
		{
			"output_dir": CaptureWorldStructureArea.DEFAULT_OUTPUT_DIR,
			"width": CaptureWorldStructureArea.DEFAULT_WIDTH,
			"height": CaptureWorldStructureArea.DEFAULT_HEIGHT
		}
	)
	assert_eq(
		CaptureWorldStructureArea.capture_config(["res://reports/world", "900", "500"]),
		{"output_dir": "res://reports/world", "width": 900, "height": 500}
	)


func test_prepare_surface_overview_positions_player_and_clears_target() -> void:
	var main := MainStub.new()

	CaptureWorldStructureArea.prepare_surface_overview(main)

	assert_eq(main.player.global_tiles, [Vector2i(3, 3)])
	assert_eq(main.player.facing_values, [Vector2.RIGHT])
	assert_eq(main.selected_target_id, "")
	assert_false(main.manual_target_locked)
	assert_eq(main.sync_calls, 1)


func test_prepare_forge_entrance_positions_player_targets_door_and_updates_nearby() -> void:
	var main := MainStub.new()
	var door := DoorStub.new()

	CaptureWorldStructureArea.prepare_forge_entrance(main, door)

	assert_eq(main.player.world_positions, [Vector2(76, 88)])
	assert_true(main.player.facing_values[0].is_equal_approx(Vector2(24, -18).normalized()))
	assert_eq(main.selected_target_id, CaptureWorldStructureArea.FORGE_DOOR_ID)
	assert_true(main.manual_target_locked)
	assert_eq(main.update_nearby_calls, 1)
	assert_eq(main.sync_calls, 1)
