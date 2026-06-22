extends GutTest

const EventBus = preload("res://scripts/core/event_bus.gd")
const TimeManager = preload("res://scripts/managers/time_manager.gd")


func test_time_advances_across_day_boundaries_and_emits_changes() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var changes: Array[Dictionary] = []
	bus.time_changed.connect(
		func(day: int, hour: int, minute: int, phase: String) -> void:
			changes.append({"day": day, "hour": hour, "minute": minute, "phase": phase})
	)
	var time := TimeManager.new()
	add_child_autofree(time)
	time.setup(bus)

	assert_eq(time.get_summary(), "Day 1, 08:00 (Morning)")
	assert_true(time.advance_minutes(9 * 60 + 30))
	assert_eq(time.day, 1)
	assert_eq(time.get_time_label(), "17:30")
	assert_eq(time.get_phase(), "Evening")
	assert_true(time.is_phase("evening"))
	assert_true(time.is_hour_between(17, 18))
	assert_false(time.is_hour_between(18, 6))
	assert_true(time.advance_hours(8))
	assert_eq(time.day, 2)
	assert_eq(time.get_time_label(), "01:30")
	assert_eq(time.get_phase(), "Night")
	assert_true(time.is_phase("Night"))
	assert_true(time.is_hour_between(18, 6))
	assert_false(time.is_hour_between(8, 18))
	assert_gt(changes.size(), 2)
	assert_eq(changes.back()["day"], 2)


func test_time_rejects_invalid_advances_and_sanitizes_save_data() -> void:
	var time := TimeManager.new()
	add_child_autofree(time)

	assert_false(time.advance_minutes(0))
	assert_false(time.advance_hours(-1))
	assert_eq(time.get_save_data(), {"day": 1, "minute_of_day": 480})

	time.load_save_data({"day": -3, "minute_of_day": 9999})
	assert_eq(time.day, 1)
	assert_eq(time.get_time_label(), "23:59")

	time.load_save_data({"day": 4, "minute_of_day": "late"})
	assert_eq(time.day, 4)
	assert_eq(time.get_time_label(), "23:59")
