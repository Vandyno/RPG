extends GutTest


func test_debug_state_merges_hud_state_with_runtime_details() -> void:
	var main := DebugMainStub.new()

	var state := MainDebugState.build(main)

	assert_eq(state["health"], "100/100")
	assert_eq(state["player_world"], "(96.5, 128.3)")
	assert_eq(state["player_layer"], "surface")
	assert_eq(state["player_tile"], "(3, 4)")
	assert_eq(state["player_chunk"], "(0, 0)")
	assert_eq(state["terrain"], "road")
	assert_eq(state["loaded_chunk_count"], 2)
	assert_eq(state["nearby_all"], "Harrow Venn")
	assert_eq(main.hud_queries.selected_target_id, "npc_harrow")
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
	var world_query := DebugWorldQueryStub.new()
	var streamer := DebugStreamerStub.new()
	var entities := DebugEntitiesStub.new()
	var hud_queries := DebugHudQueriesStub.new()
	var world_state := DebugWorldStateStub.new()
	var selected_target_id := "npc_harrow"

	func get_hud_state() -> Dictionary:
		return {"health": "100/100"}

	func _ranked_nearby_entities() -> Array:
		return [DebugEntityStub.new("npc_harrow", "Harrow Venn")]


class DebugPlayerStub:
	extends RefCounted

	var position := Vector2(96.5, 128.25)
	var global_position := Vector2(96.5, 128.25)
	var global_tile := Vector2i(3, 4)
	var world_layer := "surface"


class DebugChunksStub:
	extends RefCounted

	func get_tile_kind(_tile: Vector2i) -> String:
		return "road"


class DebugWorldQueryStub:
	extends RefCounted

	func get_tile_kind(_tile: Vector2i, _layer: String) -> String:
		return "road"


class DebugStreamerStub:
	extends RefCounted

	func get_loaded_chunk_keys() -> Array[String]:
		return ["0,0", "1,0"]


class DebugEntitiesStub:
	extends RefCounted

	func get_navigation_summary(_position: Vector2) -> String:
		return "North road"


class DebugHudQueriesStub:
	extends RefCounted

	var selected_target_id := ""

	func nearby_entities_text(entities: Array, selected_target_id: String) -> String:
		self.selected_target_id = selected_target_id
		return entities[0].get_display_name()


class DebugEntityStub:
	extends RefCounted

	var entity_id := ""
	var display_name := ""

	func _init(p_entity_id: String, p_display_name: String) -> void:
		entity_id = p_entity_id
		display_name = p_display_name

	func get_entity_id() -> String:
		return entity_id

	func get_display_name() -> String:
		return display_name


class DebugWorldStateStub:
	extends RefCounted

	var flags := {"flag_a": true, "flag_b": false}
