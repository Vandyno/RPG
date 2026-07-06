extends GutTest

const Main = preload("res://scripts/main/main.gd")
const RpgSystemsRowBuilder = preload("res://scripts/ui/rpg_systems_row_builder.gd")


func test_seed_ingredient_pickup_feeds_inventory_ingredient_tab() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var mint = main.entities.get_entity("pickup_river_mint")
	assert_not_null(mint)
	main.player.set_world_position(mint.global_position)
	main._update_nearby()

	_select_entity(main, "pickup_river_mint")
	main._handle_interact_requested()

	assert_eq(main.inventory.get_count("item_river_mint"), 2)
	assert_true(
		RpgSystemsRowBuilder.hidden_text(
			RpgSystemsRowBuilder.rows(main.get_hud_state(), "inventory", [], "ingredients")
		).contains("River Mint")
	)
	assert_null(main.entities.get_entity("pickup_river_mint"))


func _select_entity(main, entity_id: String) -> void:
	var target = main.entities.get_entity(entity_id)
	if target:
		main.player.set_world_position(target.global_position + Vector2(-8.0, 0.0))
		main.player.set_facing_direction(Vector2.RIGHT)
		main._update_nearby()
	for _i in range(24):
		var entity = main._get_nearby_entity()
		if entity and entity.get_entity_id() == entity_id:
			return
		main._handle_cycle_target_requested()
	fail_test("Could not select nearby entity: %s" % entity_id)
