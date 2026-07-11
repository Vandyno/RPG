extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainFlowInputHelper = preload("res://tests/unit/main/flows/main_flow_input_helper.gd")


func test_forge_portal_door_real_click_enters_and_exits_interior() -> void:
	var main := Main.new()
	add_child_autofree(main)

	var entrance = main.entities.get_entity("object_harrow_forge_door")
	assert_not_null(entrance)
	main.player.set_world_position(entrance.global_position + Vector2(-12.0, 0.0))
	main.player.set_facing_direction(Vector2.RIGHT)
	await MainFlowInputHelper.world_click(main, entrance.global_position, get_tree())

	assert_eq(main.player.world_layer, "interior:structure_briarwatch_harrow_forge")
	assert_eq(main.player.global_tile, Vector2i(5, 6))
	assert_null(main.entities.get_entity("object_harrow_forge_door"))
	var exit = main.entities.get_entity("object_harrow_forge_exit")
	assert_not_null(exit)
	assert_null(main.entities.get_entity("poi_harrow_forge"))
	assert_null(main.entities.get_entity("poi_harrow_forge_hearth"))
	assert_true(main.hud.log_label.text.contains("Entered Harrow's Forge."))

	await MainFlowInputHelper.world_click(main, exit.global_position, get_tree())

	assert_eq(main.player.world_layer, "surface")
	assert_eq(main.player.global_tile, Vector2i(8, 1))
	assert_not_null(main.entities.get_entity("object_harrow_forge_door"))
	assert_null(main.entities.get_entity("object_harrow_forge_exit"))
	assert_true(main.hud.log_label.text.contains("Stepped back into Briarwatch."))
