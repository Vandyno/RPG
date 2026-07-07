extends GutTest


func test_equipment_drawer_handles_empty_avatar_visuals() -> void:
	var avatar := HumanoidAvatar2D.new()
	var proportions := HumanoidProfile.DEFAULT_PROPORTIONS.duplicate(true)

	HumanoidEquipmentDrawer.draw_all_layers(avatar, proportions)
	HumanoidEquipmentDrawer.draw_body_layers(avatar, proportions)

	assert_true(avatar.equipped_visuals.is_empty())
	avatar.free()


func test_equipment_drawer_owns_apron_draw_mode_policy() -> void:
	var avatar := HumanoidAvatar2D.new()

	avatar.set_facing_direction(Vector2.UP)
	assert_eq(HumanoidEquipmentDrawer._apron_draw_mode(avatar), "back")

	avatar.set_facing_direction(Vector2.RIGHT)
	assert_eq(HumanoidEquipmentDrawer._apron_draw_mode(avatar), "side")

	avatar.set_facing_direction(Vector2.DOWN)
	assert_eq(HumanoidEquipmentDrawer._apron_draw_mode(avatar), "front")
	avatar.free()
