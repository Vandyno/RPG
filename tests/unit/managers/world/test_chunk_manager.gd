extends GutTest

const ChunkManager = preload("res://scripts/managers/world/chunk_manager.gd")


func test_chunk_manager_constructor_does_not_load_authored_terrain() -> void:
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)

	assert_eq(chunks.authored_areas, [])


func test_world_terrain_data_drives_region_order_and_fallback() -> void:
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	chunks.load_world_terrain(
		{
			"areas":
			[
				{
					"id": "test_area",
					"bounds": {"min": [10, 10], "max": [13, 13]},
					"default_kind": "forest",
					"regions":
					[
						{
							"id": "pond",
							"kind": "water",
							"rect": {"position": [11, 11], "size": [2, 2]}
						},
						{"id": "bridge_tile", "kind": "bridge", "tiles": [[12, 12]]}
					]
				}
			]
		}
	)

	assert_eq(chunks.get_tile_kind(Vector2i(10, 10)), "forest")
	assert_eq(chunks.get_tile_kind(Vector2i(11, 11)), "water")
	assert_eq(chunks.get_tile_kind(Vector2i(12, 12)), "bridge")
	assert_eq(chunks.get_tile_kind(Vector2i(20, 0)), "road")


func test_authored_terrain_file_loader_returns_boundary_errors() -> void:
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)

	var errors := chunks.load_authored_terrain("user://missing_terrain.json")

	assert_eq(errors, ["Missing authored terrain file: user://missing_terrain.json"])
