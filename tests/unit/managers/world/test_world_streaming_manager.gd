extends GutTest

const EventBus = preload("res://scripts/core/event_bus.gd")
const WorldStreamingManager = preload("res://scripts/managers/world/world_streaming_manager.gd")


class ChunkManagerStub:
	extends RefCounted

	var requests: Array[String] = []

	func get_chunk_data(chunk_coord: Vector2i, layer: String) -> Dictionary:
		requests.append("%s:%d:%d" % [layer, chunk_coord.x, chunk_coord.y])
		return {"chunk_coord": [chunk_coord.x, chunk_coord.y], "layer": layer, "tiles": []}


func test_update_center_loads_window_and_emits_sorted_chunk_keys() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var chunks := ChunkManagerStub.new()
	var streamer := WorldStreamingManager.new()
	add_child_autofree(streamer)
	streamer.active_radius = 0
	streamer.setup(bus, chunks)
	var emitted: Array = []
	bus.chunks_changed.connect(func(keys: Array) -> void: emitted.append(keys))

	streamer.update_center(Vector2i.ZERO)

	assert_eq(chunks.requests, ["surface:0:0"])
	assert_eq(streamer.get_loaded_chunk_keys(), ["surface:0:0"])
	assert_eq(emitted, [["surface:0:0"]])


func test_update_center_does_not_reload_when_center_chunk_is_unchanged() -> void:
	var chunks := ChunkManagerStub.new()
	var streamer := WorldStreamingManager.new()
	add_child_autofree(streamer)
	streamer.active_radius = 0
	streamer.setup(null, chunks)

	streamer.update_center(Vector2i.ZERO)
	streamer.update_center(Vector2i(1, 1))

	assert_eq(chunks.requests, ["surface:0:0"])
	assert_eq(streamer.get_loaded_chunk_keys(), ["surface:0:0"])


func test_update_center_replaces_chunks_when_center_moves() -> void:
	var chunks := ChunkManagerStub.new()
	var streamer := WorldStreamingManager.new()
	add_child_autofree(streamer)
	streamer.active_radius = 0
	streamer.setup(null, chunks)

	streamer.update_center(Vector2i.ZERO)
	streamer.update_center(Vector2i(16, 0))

	assert_eq(chunks.requests, ["surface:0:0", "surface:1:0"])
	assert_eq(streamer.get_loaded_chunk_keys(), ["surface:1:0"])


func test_layer_change_resets_center_and_loads_layer_specific_keys() -> void:
	var chunks := ChunkManagerStub.new()
	var streamer := WorldStreamingManager.new()
	add_child_autofree(streamer)
	streamer.active_radius = 0
	streamer.setup(null, chunks)

	streamer.update_center(Vector2i.ZERO)
	streamer.update_center(Vector2i.ZERO, "interior:test_house")

	assert_eq(streamer.current_layer, "interior:test_house")
	assert_eq(streamer.get_loaded_chunk_keys(), ["interior:test_house:0:0"])
	assert_eq(chunks.requests, ["surface:0:0", "interior:test_house:0:0"])


func test_set_layer_uses_surface_for_blank_layer() -> void:
	var streamer := WorldStreamingManager.new()
	add_child_autofree(streamer)
	streamer.current_layer = "interior:test_house"

	streamer.set_layer("")

	assert_eq(streamer.current_layer, "surface")
	assert_eq(streamer.current_center_chunk, Vector2i(999999, 999999))
