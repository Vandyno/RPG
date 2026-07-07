extends GutTest

const SpellSlots = preload("res://scripts/core/spell_slots.gd")


func test_spell_slots_expose_supported_ids_and_labels() -> void:
	assert_eq(SpellSlots.SLOTS, ["ability_1", "ability_2", "ability_3"])
	assert_eq(SpellSlots.DEFAULT_SLOT, "ability_1")
	assert_true(SpellSlots.is_supported("ability_2"))
	assert_false(SpellSlots.is_supported("ability_9"))
	assert_eq(SpellSlots.label("ability_3"), "Ability III")
	assert_eq(SpellSlots.short_label("ability_3"), "III")
	assert_eq(SpellSlots.label("missing"), "")
	assert_eq(SpellSlots.short_label("missing"), "")
