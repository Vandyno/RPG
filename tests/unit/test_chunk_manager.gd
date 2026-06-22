extends GutTest

const ChunkManager = preload("res://scripts/managers/chunk_manager.gd")


func test_authored_terrain_file_drives_region_order_and_fallback() -> void:
	var path := "user://test_world_terrain.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file)
	file.store_string(
		JSON.stringify(
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
	)
	file.close()

	var chunks := ChunkManager.new()
	add_child_autofree(chunks)
	chunks.load_authored_terrain(path)

	assert_eq(chunks.get_tile_kind(Vector2i(10, 10)), "forest")
	assert_eq(chunks.get_tile_kind(Vector2i(11, 11)), "water")
	assert_eq(chunks.get_tile_kind(Vector2i(12, 12)), "bridge")
	assert_eq(chunks.get_tile_kind(Vector2i(20, 0)), "road")
