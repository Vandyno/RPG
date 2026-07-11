extends GutTest

const ContentDatabase = preload("res://scripts/data/content_database.gd")
const EventBus = preload("res://scripts/core/event_bus.gd")
const StatusEffectManager = preload("res://scripts/managers/actors/status_effect_manager.gd")


func test_status_effects_apply_summarize_consume_and_save() -> void:
	var systems := _make_manager()
	var manager: StatusEffectManager = systems["manager"]
	var messages: Array = systems["messages"]
	var changes: Array = systems["changes"]

	assert_true(manager.apply_status("status_test_focus"))
	assert_eq(manager.get_remaining_charges("status_test_focus"), 2)
	assert_eq(manager.get_player_damage_bonus(), 3)
	assert_true(manager.get_summary().contains("Test Focus (2 attacks)"))
	assert_true(messages.back().contains("Test Focus"))
	assert_eq(changes.size(), 2)

	manager.consume_attack_charge()
	assert_eq(manager.get_remaining_charges("status_test_focus"), 1)
	manager.consume_attack_charge()
	assert_eq(manager.get_summary(), "none")
	assert_eq(manager.get_player_damage_bonus(), 0)
	assert_eq(manager.get_save_data(), {"active": []})


func test_status_effects_reject_unknown_and_sanitize_loaded_state() -> void:
	var systems := _make_manager()
	var manager: StatusEffectManager = systems["manager"]

	assert_false(manager.apply_status("missing_status"))
	manager.load_save_data(
		{
			"active":
			[
				{"status_id": "status_test_focus", "charges": 3},
				{"status_id": "missing_status", "charges": 3},
				{"status_id": "status_test_focus", "charges": 0},
				{"status_id": "status_test_focus", "charges": "many"},
				"bad"
			]
		}
	)

	assert_eq(manager.get_remaining_charges("status_test_focus"), 3)
	assert_eq(
		manager.get_save_data(), {"active": [{"status_id": "status_test_focus", "charges": 3}]}
	)


func _make_manager() -> Dictionary:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var content := ContentDatabase.new()
	add_child_autofree(content)
	content.load_all()
	content.status_effects = {
		"status_test_focus": {"name": "Test Focus", "attack_charges": 2, "damage_bonus": 3}
	}
	var messages: Array[String] = []
	var changes: Array[Dictionary] = []
	bus.message_posted.connect(func(text: String) -> void: messages.append(text))
	bus.status_effects_changed.connect(func(active: Dictionary) -> void: changes.append(active))
	var manager := StatusEffectManager.new()
	add_child_autofree(manager)
	manager.setup(bus, content)
	return {"manager": manager, "messages": messages, "changes": changes}
