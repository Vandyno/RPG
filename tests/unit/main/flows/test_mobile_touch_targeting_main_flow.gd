extends GutTest

const Main = preload("res://scripts/main/main.gd")
const MainInputRouter = preload("res://scripts/main/input/main_input_router.gd")


func test_mobile_touch_assist_reaches_small_pickup_without_mouse_precision() -> void:
	var mouse_main := Main.new()
	add_child_autofree(mouse_main)
	var mouse_draught = mouse_main.entities.get_entity("pickup_roadside_draught")
	assert_not_null(mouse_draught)
	var near_miss: Vector2 = mouse_draught.global_position + Vector2(-45.0, 0.0)

	assert_false(MainInputRouter.target_world(mouse_main, near_miss))
	assert_false(mouse_main.inventory.has_item("item_roadside_draught"))

	var touch_main := Main.new()
	add_child_autofree(touch_main)
	var touch_draught = touch_main.entities.get_entity("pickup_roadside_draught")
	assert_not_null(touch_draught)
	near_miss = touch_draught.global_position + Vector2(-45.0, 0.0)
	touch_main.player.set_world_position(touch_draught.global_position + Vector2(-8.0, 0.0))
	touch_main._update_nearby()

	assert_true(
		MainInputRouter.target_world(
			touch_main, near_miss, true, MainInputRouter.WORLD_TOUCH_PICK_RADIUS
		)
	)
	assert_true(touch_main.inventory.has_item("item_roadside_draught"))
