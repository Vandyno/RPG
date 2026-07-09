extends GutTest

const RpgSpellSlot = preload("res://scripts/ui/controls/slots/rpg_spell_slot.gd")


func test_setup_slot_stores_slot_id_and_metadata() -> void:
	var slot := RpgSpellSlot.new()
	add_child_autofree(slot)

	slot.setup_slot("ability_1")

	assert_eq(slot.slot_id, "ability_1")
	assert_eq(slot.get_meta("slot_id"), "ability_1")


func test_can_drop_data_accepts_spell_payloads_with_spell_id() -> void:
	var slot := RpgSpellSlot.new()
	add_child_autofree(slot)

	assert_true(
		slot._can_drop_data(Vector2.ZERO, {"type": "spell", "spell_id": "spell_fire_blast"})
	)


func test_can_drop_data_rejects_invalid_payloads() -> void:
	var slot := RpgSpellSlot.new()
	add_child_autofree(slot)

	assert_false(slot._can_drop_data(Vector2.ZERO, "bad"))
	assert_false(slot._can_drop_data(Vector2.ZERO, {"type": "inventory_item", "spell_id": "x"}))
	assert_false(slot._can_drop_data(Vector2.ZERO, {"type": "spell", "spell_id": ""}))


func test_drop_data_emits_spell_dropped_only_for_valid_spell_payload() -> void:
	var slot := RpgSpellSlot.new()
	add_child_autofree(slot)
	slot.setup_slot("ability_2")
	var drops: Array[String] = []
	slot.spell_dropped.connect(
		func(slot_id: String, spell_id: String) -> void: drops.append("%s:%s" % [slot_id, spell_id])
	)

	slot._drop_data(Vector2.ZERO, {"type": "spell", "spell_id": "spell_fire_blast"})
	slot._drop_data(Vector2.ZERO, {"type": "spell", "spell_id": ""})

	assert_eq(drops, ["ability_2:spell_fire_blast"])
