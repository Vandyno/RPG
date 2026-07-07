extends GutTest


func test_equipment_drawer_routes_each_layer_to_avatar() -> void:
	var avatar := EquipmentAvatarStub.new()
	var proportions := {"height": 1.0}

	HumanoidEquipmentDrawer.draw_back_layer(avatar, proportions, "cloak")
	HumanoidEquipmentDrawer.draw_boot_layer(avatar, proportions)
	HumanoidEquipmentDrawer.draw_leg_layer(avatar, proportions)
	HumanoidEquipmentDrawer.draw_chest_layer(avatar, proportions)
	HumanoidEquipmentDrawer.draw_head_layer(avatar, proportions)

	assert_eq(
		avatar.calls,
		[
			"back:cloak",
			"boots",
			"legs",
			"chest",
			"head",
		]
	)
	assert_eq(avatar.last_proportions, proportions)


class EquipmentAvatarStub:
	extends RefCounted

	var calls: Array[String] = []
	var last_proportions := {}

	func _draw_back_equipment_layer(proportions: Dictionary, layer_id: String) -> void:
		last_proportions = proportions
		calls.append("back:%s" % layer_id)

	func _draw_boot_equipment_layer(proportions: Dictionary) -> void:
		last_proportions = proportions
		calls.append("boots")

	func _draw_leg_equipment_layer(proportions: Dictionary) -> void:
		last_proportions = proportions
		calls.append("legs")

	func _draw_chest_equipment_layer(proportions: Dictionary) -> void:
		last_proportions = proportions
		calls.append("chest")

	func _draw_head_equipment_layer(proportions: Dictionary) -> void:
		last_proportions = proportions
		calls.append("head")
