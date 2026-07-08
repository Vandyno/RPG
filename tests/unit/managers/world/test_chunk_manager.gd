extends GutTest

const ChunkManager = preload("res://scripts/managers/world/chunk_manager.gd")

const INVALID_TERRAIN_PATH := "user://invalid_terrain.json"
const ARRAY_TERRAIN_PATH := "user://array_terrain.json"


func after_each() -> void:
	if FileAccess.file_exists(INVALID_TERRAIN_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(INVALID_TERRAIN_PATH))
	if FileAccess.file_exists(ARRAY_TERRAIN_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(ARRAY_TERRAIN_PATH))


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


func test_authored_terrain_file_loader_reports_json_parse_line_and_message() -> void:
	_write_user_file(INVALID_TERRAIN_PATH, "{\n  bad\n")
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)

	var errors := chunks.load_authored_terrain(INVALID_TERRAIN_PATH)

	assert_eq(errors.size(), 1)
	assert_true(errors[0].contains("Invalid JSON at %s line " % INVALID_TERRAIN_PATH))
	assert_true(errors[0].contains("Expected"))


func test_authored_terrain_file_loader_keeps_dictionary_shape_error() -> void:
	_write_user_file(ARRAY_TERRAIN_PATH, "[]")
	var chunks := ChunkManager.new()
	add_child_autofree(chunks)

	var errors := chunks.load_authored_terrain(ARRAY_TERRAIN_PATH)

	assert_eq(errors, ["Expected dictionary JSON at %s" % ARRAY_TERRAIN_PATH])


func _write_user_file(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert_not_null(file)
	file.store_string(text)
