extends GutTest

const CaptureBodyLootTransfer = preload(
	"res://scripts/tools/capture/capture_body_loot_transfer.gd"
)


class BodyStub:
	extends RefCounted

	var global_position := Vector2(40, 50)
	var entity_id := "npc_road_thug"

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


class EntitiesStub:
	extends RefCounted

	var entities := {}

	func get_entity(entity_id: String):
		return entities.get(entity_id)


class MainStub:
	extends RefCounted

	var player := PlayerStub.new()
	var hud := HudStub.new()
	var entities := EntitiesStub.new()
	var selected_target_id := ""
	var manual_target_locked := false
	var update_nearby_calls := 0
	var interact_calls := 0

	func _update_nearby() -> void:
		update_nearby_calls += 1

	func _handle_interact_requested() -> void:
		interact_calls += 1


func test_capture_config_uses_defaults_and_reads_args() -> void:
	assert_eq(
		CaptureBodyLootTransfer.capture_config([]),
		{
			"width": CaptureBodyLootTransfer.DEFAULT_WIDTH,
			"height": CaptureBodyLootTransfer.DEFAULT_HEIGHT,
			"output_path": CaptureBodyLootTransfer.DEFAULT_OUTPUT_PATH
		}
	)
	assert_eq(
		CaptureBodyLootTransfer.capture_config(["900", "500", "res://reports/body.png"]),
		{"width": 900, "height": 500, "output_path": "res://reports/body.png"}
	)


func test_position_player_for_body_loot_targets_body_and_opens_inventory_transfer() -> void:
	var main := MainStub.new()
	var body := BodyStub.new()

	CaptureBodyLootTransfer.position_player_for_body_loot(main, body, 960, 540)

	assert_eq(main.player.world_positions, [body.global_position + Vector2(-8, 0)])
	assert_eq(main.player.facing_values, [Vector2.RIGHT])
	assert_eq(main.selected_target_id, "npc_road_thug")
	assert_true(main.manual_target_locked)
	assert_eq(main.update_nearby_calls, 1)
	assert_eq(main.interact_calls, 1)
	assert_eq(main.hud.layout_sizes, [Vector2(960, 540)])
	assert_eq(main.hud.tabs, ["inventory"])


func test_prepare_main_for_capture_returns_false_when_body_is_missing() -> void:
	var main := MainStub.new()

	assert_false(CaptureBodyLootTransfer.prepare_main_for_capture(main, 960, 540))


func test_defeat_hostile_actor_is_safe_when_hostile_is_missing() -> void:
	var main := MainStub.new()

	CaptureBodyLootTransfer.defeat_hostile_actor(main)

	assert_true(main.player.world_positions.is_empty())
