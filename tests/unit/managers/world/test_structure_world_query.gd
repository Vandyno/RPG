extends GutTest

const ContentDatabaseScript = preload("res://scripts/data/content_database.gd")
const ChunkManagerScript = preload("res://scripts/managers/world/chunk_manager.gd")
const StructureManagerScript = preload("res://scripts/managers/world/structure_manager.gd")
const WorldQueryScript = preload("res://scripts/world/world_query.gd")


func test_structure_content_loads_and_validates() -> void:
	var content := ContentDatabaseScript.new()
	add_child_autofree(content)

	assert_eq(content.load_all(), [])
	assert_true(content.has_structure_archetype("archetype_briarwatch_forge_exterior"))
	assert_true(content.has_structure_archetype("archetype_briarwatch_forge_interior"))
	assert_true(content.has_structure_archetype("archetype_briarwatch_town_hall_exterior"))
	assert_true(content.has_structure_archetype("archetype_briarwatch_town_hall_interior"))
	assert_eq(content.validate_all(), [])


func test_world_query_uses_structure_collision_and_interior_layers() -> void:
	var query := _new_query()

	assert_eq(query.get_tile_kind(Vector2i(8, 0), "surface"), "wood_floor")
	assert_true(query.is_walkable(Vector2i(8, 0), "surface"))
	assert_eq(query.get_tile_kind(Vector2i(6, -2), "surface"), "wood_wall")
	assert_false(query.is_walkable(Vector2i(6, -2), "surface"))
	assert_eq(query.get_tile_kind(Vector2i(5, 7), "surface"), "wood_floor")
	assert_true(query.is_walkable(Vector2i(5, 7), "surface"))
	assert_eq(query.get_tile_kind(Vector2i(1, 4), "surface"), "wood_wall")
	assert_false(query.is_walkable(Vector2i(1, 4), "surface"))
	assert_eq(
		query.get_tile_kind(Vector2i(3, 4), "interior:structure_briarwatch_harrow_forge"),
		"wood_floor"
	)
	assert_true(query.is_walkable(Vector2i(3, 4), "interior:structure_briarwatch_harrow_forge"))
	assert_eq(
		query.get_tile_kind(Vector2i(2, 2), "interior:structure_briarwatch_town_hall"),
		"wood_floor"
	)
	assert_true(query.is_walkable(Vector2i(2, 2), "interior:structure_briarwatch_town_hall"))
	assert_eq(
		query.get_tile_kind(Vector2i(20, 20), "interior:structure_briarwatch_harrow_forge"),
		"stone_wall"
	)
	assert_false(
		query.is_walkable(Vector2i(20, 20), "interior:structure_briarwatch_harrow_forge")
	)


func test_chunk_data_includes_structure_visuals_on_their_own_layer() -> void:
	var query := _new_query()
	var surface_chunk: Dictionary = query.get_chunk_data(Vector2i(0, -1), "surface")
	var town_hall_surface_chunk: Dictionary = query.get_chunk_data(Vector2i.ZERO, "surface")
	var interior_chunk: Dictionary = query.get_chunk_data(
		Vector2i.ZERO, "interior:structure_briarwatch_harrow_forge"
	)

	assert_eq(surface_chunk["id"], "surface:0:-1")
	assert_true(_chunk_has_visual_style(surface_chunk, "forge_exterior"))
	assert_true(_chunk_has_visual_style(town_hall_surface_chunk, "town_hall_exterior"))
	assert_eq(interior_chunk["id"], "interior:structure_briarwatch_harrow_forge:0:0")
	assert_true(_chunk_has_visual_style(interior_chunk, "forge_interior"))
	var town_hall_interior_chunk: Dictionary = query.get_chunk_data(
		Vector2i.ZERO, "interior:structure_briarwatch_town_hall"
	)
	assert_true(_chunk_has_visual_style(town_hall_interior_chunk, "town_hall_interior"))


func _new_query() -> WorldQuery:
	var content := ContentDatabaseScript.new()
	add_child_autofree(content)
	content.load_all()
	var chunks := ChunkManagerScript.new()
	add_child_autofree(chunks)
	chunks.load_world_terrain(content.get_world_terrain())
	var structures := StructureManagerScript.new()
	add_child_autofree(structures)
	structures.setup(content)
	var query := WorldQueryScript.new()
	query.setup(chunks, structures)
	return query


func _chunk_has_visual_style(chunk: Dictionary, style: String) -> bool:
	for structure in chunk.get("structures", []):
		if structure is Dictionary and String(structure.get("visual_style", "")) == style:
			return true
	return false
