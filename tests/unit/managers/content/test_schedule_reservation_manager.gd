extends GutTest

const ScheduleReservationManager = preload("res://scripts/managers/content/schedule_reservation_manager.gd")


func test_exclusive_anchor_reservation_expires_and_round_trips() -> void:
	var manager := ScheduleReservationManager.new()
	assert_true(manager.reserve("counter", "npc_a", 100, 20))
	assert_true(manager.is_reserved("counter"))
	assert_false(manager.is_reserved("counter", "npc_a"))
	assert_false(manager.reserve("counter", "npc_b", 110, 20))

	var saved := manager.get_save_data()
	var restored := ScheduleReservationManager.new()
	restored.load_save_data(saved)
	assert_true(restored.is_reserved("counter"))
	restored.prune(120)
	assert_false(restored.is_reserved("counter"))
