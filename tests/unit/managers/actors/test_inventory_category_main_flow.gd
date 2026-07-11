extends GutTest

const Main = preload("res://scripts/main/main.gd")
const RpgSystemsRowBuilder = preload("res://scripts/ui/systems/rows/rpg_systems_row_builder.gd")
const RpgSystemsRowPresentation = preload(
	"res://scripts/ui/systems/rows/rpg_systems_row_presentation.gd"
)


func test_seed_weapon_pickup_feeds_inventory_weapon_tab() -> void:
	var main := Main.new()
	add_child_autofree(main)
	var hatchet = main.entities.get_entity("pickup_road_hatchet")
	assert_not_null(hatchet)
	main.player.set_world_position(hatchet.global_position)
	main._update_nearby()

	_select_entity(main, "pickup_road_hatchet")
	main._handle_interact_requested()

	assert_eq(main.inventory.get_count("item_road_hatchet"), 1)
	assert_true(
		RpgSystemsRowPresentation.hidden_text(
			RpgSystemsRowBuilder.rows(main.get_hud_state(), "inventory", [], "weapons")
		).contains("Road Hatchet")
	)
	assert_null(main.entities.get_entity("pickup_road_hatchet"))


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
