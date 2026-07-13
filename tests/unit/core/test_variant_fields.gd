extends GutTest

const VariantFields = preload("res://scripts/core/variant_fields.gd")
const WorldEntity = preload("res://scripts/world/world_entity.gd")


func test_collection_and_entity_fields_fallback_safely() -> void:
	var entity := WorldEntity.new()
	add_child_autofree(entity)
	entity.setup({"world_layer": "", "portal": "bad"})

	assert_eq(VariantFields.array("bad"), [])
	assert_eq(VariantFields.dictionary("bad"), {})
	assert_eq(VariantFields.portal_data(entity), {})
	assert_eq(VariantFields.entity_layer(entity), "surface")


func test_numeric_pair_fields_accept_numbers_and_reject_malformed_values() -> void:
	assert_eq(VariantFields.numeric_pair([1.8, -2]), [1.8, -2])
	assert_eq(VariantFields.numeric_pair(["bad", 1]), [])
	assert_eq(VariantFields.vector2i_from_pair([1.8, -2], Vector2i.ZERO), Vector2i(1, -2))
	assert_eq(VariantFields.vector2i_from_pair(["bad", 1], Vector2i(9, 9)), Vector2i(9, 9))
	assert_eq(VariantFields.vector2_from_pair([1, 2.5], Vector2.ZERO), Vector2(1, 2.5))
	assert_eq(VariantFields.vector2_from_pair(["bad"], Vector2.ONE), Vector2.ONE)


func test_scalar_fields_clamp_or_fallback_by_expected_range() -> void:
	assert_eq(VariantFields.positive_int_field({"count": -4}, "count", 3), 1)
	assert_eq(VariantFields.positive_int_field({"count": "bad"}, "count", 3), 3)
	assert_eq(VariantFields.non_negative_int_field({"count": -4}, "count", 3), 0)
	assert_eq(VariantFields.non_negative_int("bad", 3), 3)
	assert_eq(VariantFields.int_value("bad", 3), 3)
	assert_eq(VariantFields.int_value(4.8, 3), 4)
	assert_almost_eq(VariantFields.positive_float("bad", -2.0), 0.01, 0.001)
	assert_almost_eq(VariantFields.positive_float_at_least(0.5, 2.0, 1.0), 1.0, 0.001)
	assert_almost_eq(VariantFields.non_negative_float(-2.0, 3.0), 0.0, 0.001)
	assert_true(VariantFields.is_number(1.0))
	assert_false(VariantFields.is_number("1"))
