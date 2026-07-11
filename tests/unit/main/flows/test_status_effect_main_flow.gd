extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_removed_consumable_pickup_is_not_spawned() -> void:
	var main := Main.new()
	add_child_autofree(main)

	assert_null(main.entities.get_entity("pickup_roadside_draught"))
	assert_false(main.content.has_item("item_roadside_draught"))
	assert_false(main.content.has_item("item_river_mint"))
