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
	assert_true(
		manager.assign_spell_to_owner_slot("char_test_raider", "spell_fire_blast", "ability_2")
	)
	assert_eq(
		manager.get_assigned_spell_for_owner("char_test_raider", "ability_2"), "spell_fire_blast"
	)
	assert_eq(manager.get_assigned_spell("ability_2"), "")
	assert_eq(
		manager.get_save_data(),
		{
			"assigned": {"ability_1": "spell_fire_blast"},
			"owner_loadouts":
			[
				{"owner_id": "char_test_raider", "assigned": {"ability_2": "spell_fire_blast"}}
			]
		}
	)
	assert_eq(changes.back(), {"ability_1": "spell_fire_blast"})

	manager.load_save_data(
		{"assigned": {"ability_2": "spell_fire_blast", "ability_9": "spell_fire_blast"}}
	)
	assert_eq(manager.get_assigned_spell("ability_1"), "")
	assert_eq(manager.get_assigned_spell("ability_2"), "spell_fire_blast")
	manager.load_save_data(
		{
			"assigned": {"ability_1": "spell_fire_blast"},
			"owner_loadouts":
			[{"owner_id": "char_test_raider", "assigned": {"ability_3": "spell_fire_blast"}}]
		}
	)
	assert_eq(manager.get_assigned_spell("ability_1"), "spell_fire_blast")
	assert_eq(
		manager.get_assigned_spell_for_owner("char_test_raider", "ability_3"), "spell_fire_blast"
	)


func test_owner_spell_getter_does_not_create_owner_state() -> void:
	var manager := SpellManager.new()
	add_child_autofree(manager)
	manager.setup(null, null)

	assert_eq(manager.get_assigned_spell_for_owner("char_missing", "ability_1"), "")
	assert_false(manager.assigned_by_owner_id.has("char_missing"))

	manager.assign_spell_to_owner_slot("char_missing", "spell_missing", "ability_1")
	assert_false(manager.assigned_by_owner_id.has("char_missing"))
