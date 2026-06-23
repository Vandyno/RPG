extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
func test_spell_slots_assign_sanitize_and_save() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.spells = {
		"spell_fire_blast": {"id": "spell_fire_blast", "name": "Fire Blast", "mana_cost": 5}
	}
	var manager := SpellManager.new()
	add_child_autofree(manager)
	manager.setup(bus, content)

	var changes: Array[Dictionary] = []
	bus.spell_slots_changed.connect(func(assigned: Dictionary) -> void: changes.append(assigned))

	assert_true(manager.assign_spell_to_slot("spell_fire_blast", "ability_1"))
	assert_false(manager.assign_spell_to_slot("missing", "ability_2"))
	assert_eq(manager.get_assigned_spell("ability_1"), "spell_fire_blast")
	assert_eq(manager.get_save_data(), {"assigned": {"ability_1": "spell_fire_blast"}})
	assert_eq(changes.back(), {"ability_1": "spell_fire_blast"})

	manager.load_save_data(
		{"assigned": {"ability_2": "spell_fire_blast", "ability_9": "spell_fire_blast"}}
	)
	assert_eq(manager.get_assigned_spell("ability_1"), "")
	assert_eq(manager.get_assigned_spell("ability_2"), "spell_fire_blast")
