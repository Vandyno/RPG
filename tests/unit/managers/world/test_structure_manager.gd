extends GutTest

const GridMath = preload("res://scripts/core/grid_math.gd")
const ContentDatabase = preload("res://scripts/data/content_database.gd")
const StructureManager = preload("res://scripts/managers/world/structure_manager.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")


class ContentStub:
	extends ContentDatabase

	func structure_archetype_ids() -> Array[String]:
		return ["house", "bad_size"]

	func get_structure_archetype(archetype_id: String) -> Dictionary:
		if archetype_id == "house":
			return {
				"name": "House",
				"size": [3, 2],
				"visual_style": "timber",
				"terrain_rows": ["ab.", "c.."],
				"tile_kinds": {"a": "wood_floor", "b": "wood_wall", "c": "water"},
				"anchors": {"door": [1, 0]}
			}
		return {"size": [0, 0]}

	func world_structure_entries() -> Array[Dictionary]:
		return [
			{
				"id": "structure_house",
				"archetype_id": "house",
				"name": "Road House",
				"origin_tile": [4, -2],
				"world_layer": "",
				"seed": "seed_house"
			},
			{"id": "bad_size", "archetype_id": "bad_size", "origin_tile": [0, 0]},
			{"id": "missing_archetype", "archetype_id": "missing", "origin_tile": [0, 0]},
			{"id": "", "archetype_id": "house", "origin_tile": [0, 0]}
		]


func test_setup_resolves_structures_indexes_tiles_layers_and_anchors() -> void:
	var manager := StructureManager.new()
	add_child_autofree(manager)
	var content := ContentStub.new()
	add_child_autofree(content)

	manager.setup(content)

	assert_true(manager.has_structure("structure_house"))
	assert_false(manager.has_structure("missing_archetype"))
	var structure := manager.get_structure("structure_house")
	assert_eq(structure["name"], "Road House")
	assert_eq(structure["world_layer"], "surface")
	assert_eq(structure["origin_tile"], Vector2i(4, -2))
	assert_eq(structure["size"], Vector2i(3, 2))
	assert_eq(structure["bounds"], Rect2i(Vector2i(4, -2), Vector2i(3, 2)))
	assert_eq(manager.get_anchor_tile("structure_house", "door"), Vector2i(5, -2))
	assert_eq(manager.get_anchor_tile("missing", "door"), Vector2i.ZERO)
	assert_eq(manager.get_tile_kind(Vector2i(4, -2)), "wood_floor")
	assert_eq(manager.get_tile_kind(Vector2i(5, -2)), "wood_wall")
	assert_eq(manager.get_tile_kind(Vector2i(4, -1)), "water")
	assert_eq(manager.get_tile_kind(Vector2i(6, -2)), "")
	assert_true(manager.has_tile_override(Vector2i(4, -2)))
	assert_false(manager.has_tile_override(Vector2i(6, -2)))
	assert_true(manager.is_walkable_tile(Vector2i(4, -2)))
	assert_false(manager.is_walkable_tile(Vector2i(5, -2)))
	assert_false(manager.is_walkable_tile(Vector2i(4, -1)))
	assert_false(manager.is_walkable_tile(Vector2i(6, -2)))


func test_get_structure_returns_duplicate_and_chunk_visual_data() -> void:
	var manager := StructureManager.new()
	add_child_autofree(manager)
	var content := ContentStub.new()
	add_child_autofree(content)
	manager.setup(content)

	var copy := manager.get_structure("structure_house")
	copy["name"] = "Changed"

	assert_eq(manager.get_structure("structure_house")["name"], "Road House")
	var chunk_structures := manager.get_structures_for_chunk(
		GridMath.tile_to_chunk(Vector2i(4, -2)),
		"surface"
	)
	assert_eq(chunk_structures.size(), 1)
	assert_eq(
		chunk_structures[0],
		{
			"id": "structure_house",
			"name": "Road House",
			"world_layer": "surface",
			"origin_tile": [4, -2],
			"size": [3, 2],
			"visual_style": "timber",
			"seed": "seed_house",
			"anchors": {"door": [1, 0]}
		}
	)
	assert_eq(manager.get_structures_for_chunk(Vector2i(99, 99), "surface"), [])
	assert_eq(manager.get_structures_for_chunk(GridMath.tile_to_chunk(Vector2i(4, -2)), "other"), [])


func test_clear_and_helper_parsers_handle_invalid_values() -> void:
	var manager := StructureManager.new()
	add_child_autofree(manager)
	var content := ContentStub.new()
	add_child_autofree(content)
	manager.setup(content)

	manager.clear()

	assert_false(manager.has_structure("structure_house"))
	assert_eq(manager.get_structure("structure_house"), {})
	assert_eq(VariantFields.vector2i_from_pair([1.2, -3], Vector2i.ZERO), Vector2i(1, -3))
	assert_eq(VariantFields.vector2i_from_pair(["bad", 1], Vector2i(9, 9)), Vector2i(9, 9))
	assert_eq(VariantFields.array("bad"), [])
	assert_eq(VariantFields.dictionary("bad"), {})
	assert_true(VariantFields.is_number(1))
	assert_true(VariantFields.is_number(1.5))
	assert_false(VariantFields.is_number("1"))
