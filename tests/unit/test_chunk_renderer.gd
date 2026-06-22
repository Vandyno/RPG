extends GutTest

const ChunkRenderer = preload("res://scripts/world/chunk_renderer.gd")
const GridMath = preload("res://scripts/core/grid_math.gd")


func test_renderer_setup_uses_chunk_coord_when_valid() -> void:
	var renderer := ChunkRenderer.new()
	add_child_autofree(renderer)

	renderer.setup({"chunk_coord": [2, -1], "tiles": []})

	assert_eq(
		renderer.position, GridMath.tile_to_world(GridMath.chunk_origin_tile(Vector2i(2, -1)))
	)


func test_renderer_ignores_malformed_chunk_and_tile_data() -> void:
	var renderer := ChunkRenderer.new()
	add_child_autofree(renderer)

	renderer.setup(
		{
			"chunk_coord": "bad",
			"tiles":
			[
				"bad tile",
				{"tile": "bad", "kind": "water"},
				{"tile": [0], "kind": "road"},
				{"tile": ["0", 0], "kind": "water"},
				{"tile": [0, 0], "kind": "grass"}
			]
		}
	)

	await wait_process_frames(2)

	assert_eq(renderer.position, Vector2.ZERO)
	assert_eq(renderer.chunk_data.get("tiles", []).size(), 5)


func test_renderer_falls_back_for_non_numeric_chunk_coord() -> void:
	var renderer := ChunkRenderer.new()
	add_child_autofree(renderer)

	renderer.setup({"chunk_coord": ["2", 0], "tiles": []})

	assert_eq(renderer.position, Vector2.ZERO)
