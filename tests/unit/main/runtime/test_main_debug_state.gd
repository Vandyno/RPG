extends GutTest


func test_debug_state_merges_hud_state_with_runtime_details() -> void:
	var main := DebugMainStub.new()

	var state := MainDebugState.build(main)

	assert_eq(state["health"], "100/100")
	assert_eq(state["player_world"], "(96.5, 128.3)")
	assert_eq(state["player_tile"], "(3, 4)")
	assert_eq(state["player_chunk"], "(0, 0)")
	assert_eq(state["terrain"], "road")
	assert_eq(state["loaded_chunk_count"], 2)
	assert_eq(state["nearby_all"], "Harrow Venn")
	assert_eq(state["navigation"], "North road")
	assert_eq(state["flags"], "flag_a, flag_b")


func test_debug_state_uses_none_when_no_world_flags_exist() -> void:
	var main := DebugMainStub.new()
	main.world_state.flags = {}

	assert_eq(MainDebugState.build(main)["flags"], "none")


class DebugMainStub:
	extends RefCounted

	var player := DebugPlayerStub.new()
	var chunks := DebugChunksStub.new()
	var streamer := DebugStreamerStub.new()
	var entities := DebugEntitiesStub.new()
	var world_state := DebugWorldStateStub.new()

	func get_hud_state() -> Dictionary:
		return {"health": "100/100"}

	func _nearby_entities_text() -> String:
		return "Harrow Venn"


class DebugPlayerStub:
	extends RefCounted

	var position := Vector2(96.5, 128.25)
	var global_position := Vector2(96.5, 128.25)
	var global_tile := Vector2i(3, 4)


class DebugChunksStub:
	extends RefCounted

	func get_tile_kind(_tile: Vector2i) -> String:
		return "road"


class DebugStreamerStub:
	extends RefCounted

	func get_loaded_chunk_keys() -> Array[String]:
		return ["0,0", "1,0"]


class DebugEntitiesStub:
	extends RefCounted

	func get_navigation_summary(_position: Vector2) -> String:
		return "North road"


class DebugWorldStateStub:
	extends RefCounted

	var flags := {"flag_a": true, "flag_b": false}
