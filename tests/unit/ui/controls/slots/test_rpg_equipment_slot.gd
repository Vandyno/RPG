extends GutTest

const RpgEquipmentSlot = preload("res://scripts/ui/controls/slots/rpg_equipment_slot.gd")


func test_setup_slot_normalizes_and_stores_slot_metadata() -> void:
	var slot := RpgEquipmentSlot.new()
	add_child_autofree(slot)

	slot.setup_slot("Ring")

	assert_eq(slot.slot_id, "ring_1")
	assert_eq(slot.get_meta("slot_id"), "ring_1")


func test_can_drop_data_accepts_inventory_items_matching_slot() -> void:
	var slot := RpgEquipmentSlot.new()
	add_child_autofree(slot)
	slot.setup_slot("right_hand")

	assert_true(
		slot._can_drop_data(
			Vector2.ZERO,
			{"type": "inventory_item", "item_id": "item_training_sword", "equipment_slot": "right_hand"}
		)
	)


func test_can_drop_data_rejects_non_inventory_missing_or_wrong_slot_data() -> void:
	var slot := RpgEquipmentSlot.new()
	add_child_autofree(slot)
	slot.setup_slot("chest")

	assert_false(slot._can_drop_data(Vector2.ZERO, "bad"))
	assert_false(
		slot._can_drop_data(
			Vector2.ZERO,
			{"type": "loot_item", "item_id": "item_smith_apron", "equipment_slot": "chest"}
		)
	)
	assert_false(
		slot._can_drop_data(
			Vector2.ZERO, {"type": "inventory_item", "item_id": "", "equipment_slot": "chest"}
		)
	)
	assert_false(
		slot._can_drop_data(
			Vector2.ZERO,
			{"type": "inventory_item", "item_id": "item_training_sword", "equipment_slot": "right_hand"}
		)
	)


func test_can_drop_data_accepts_any_ring_item_in_ring_slot() -> void:
	var slot := RpgEquipmentSlot.new()
	add_child_autofree(slot)
	slot.setup_slot("ring_2")

	assert_true(
		slot._can_drop_data(
			Vector2.ZERO,
			{"type": "inventory_item", "item_id": "item_ring", "equipment_slot": "ring_1"}
		)
	)


func test_drop_data_emits_item_dropped_only_for_valid_drop() -> void:
	var slot := RpgEquipmentSlot.new()
	add_child_autofree(slot)
	slot.setup_slot("left_hand")
	var drops: Array[String] = []
	slot.item_dropped.connect(
		func(slot_id: String, item_id: String) -> void: drops.append("%s:%s" % [slot_id, item_id])
	)

	slot._drop_data(
		Vector2.ZERO,
		{"type": "inventory_item", "item_id": "item_buckler", "equipment_slot": "left_hand"}
	)
	slot._drop_data(
		Vector2.ZERO,
		{"type": "inventory_item", "item_id": "item_sword", "equipment_slot": "right_hand"}
	)

	assert_eq(drops, ["left_hand:item_buckler"])
