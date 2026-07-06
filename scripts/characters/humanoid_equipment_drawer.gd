class_name HumanoidEquipmentDrawer
extends RefCounted


static func draw_back_layer(avatar, proportions: Dictionary, layer_id: String) -> void:
	avatar._draw_back_equipment_layer(proportions, layer_id)


static func draw_boot_layer(avatar, proportions: Dictionary) -> void:
	avatar._draw_boot_equipment_layer(proportions)


static func draw_leg_layer(avatar, proportions: Dictionary) -> void:
	avatar._draw_leg_equipment_layer(proportions)


static func draw_chest_layer(avatar, proportions: Dictionary) -> void:
	avatar._draw_chest_equipment_layer(proportions)


static func draw_head_layer(avatar, proportions: Dictionary) -> void:
	avatar._draw_head_equipment_layer(proportions)
