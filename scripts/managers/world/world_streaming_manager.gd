class_name WorldStreamingManager
extends Node2D

const GridMath = preload("res://scripts/core/grid_math.gd")
const ChunkRendererScript = preload("res://scripts/world/chunk_renderer.gd")

var event_bus: EventBus
var chunk_manager
var active_radius := 2
var active_chunks: Dictionary = {}
var current_center_chunk := Vector2i(999999, 999999)
var current_layer := "surface"


func setup(bus: EventBus, chunks) -> void:
	event_bus = bus
	chunk_manager = chunks


func set_layer(layer: String) -> void:
	var next_layer := "surface" if layer.is_empty() else layer
	if current_layer == next_layer:
		return
	current_layer = next_layer
	current_center_chunk = Vector2i(999999, 999999)


func update_center(global_tile: Vector2i, layer: String = "") -> void:
	if not layer.is_empty():
		set_layer(layer)
	var center := GridMath.tile_to_chunk(global_tile)
	if center == current_center_chunk:
		return
	current_center_chunk = center
	_reload_window(center)


func get_loaded_chunk_keys() -> Array:
	var keys := active_chunks.keys()
	keys.sort()
	return keys


func _reload_window(center: Vector2i) -> void:
	var needed: Dictionary = {}
	for y in range(center.y - active_radius, center.y + active_radius + 1):
		for x in range(center.x - active_radius, center.x + active_radius + 1):
			var chunk_coord := Vector2i(x, y)
			var key := GridMath.chunk_key(chunk_coord, current_layer)
			needed[key] = chunk_coord
			if not active_chunks.has(key):
				var renderer := ChunkRendererScript.new()
				renderer.name = "Chunk_%s_%d_%d" % [current_layer.replace(":", "_"), x, y]
				add_child(renderer)
				renderer.setup(chunk_manager.get_chunk_data(chunk_coord, current_layer))
				active_chunks[key] = renderer
	for key in active_chunks.keys():
		if not needed.has(key):
			active_chunks[key].queue_free()
			active_chunks.erase(key)
	if event_bus:
		event_bus.chunks_changed.emit(get_loaded_chunk_keys())
