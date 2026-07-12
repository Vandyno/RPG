extends GutTest

const ScheduleResolver = preload("res://scripts/core/schedule_resolver.gd")


func test_start_based_blocks_wrap_at_midnight_and_report_next_transition() -> void:
	var profile := {
		"id": "test",
		"weekday_blocks": [
			{"id": "day", "start": "08:00", "activity": "work"},
			{"id": "sleep", "start": "22:30", "activity": "sleep"}
		]
	}

	var before_wake := ScheduleResolver.resolve(profile, 30, 2)
	assert_eq(before_wake["activity"], "sleep")
	assert_eq(before_wake["minutes_until_transition"], 450)

	var late := ScheduleResolver.resolve(profile, 23 * 60 + 59, 2)
	assert_eq(late["activity"], "sleep")
	assert_eq(late["next_transition_minute"], 480)
	assert_eq(late["minutes_until_transition"], 481)


func test_deterministic_pool_choice_is_stable_per_npc_day_and_block() -> void:
	var choices: Array = ["inn", "square", "home"]
	var first = ScheduleResolver.choose_deterministic(choices, "npc", 4, 2)
	assert_eq(first, ScheduleResolver.choose_deterministic(choices, "npc", 4, 2))
	assert_ne(first, ScheduleResolver.choose_deterministic(choices, "other", 4, 2))


func test_full_day_validation_rejects_duplicate_or_missing_time_coverage() -> void:
	var errors := ScheduleResolver.validate_full_day(
		{"id": "bad", "weekday_blocks": [{"start": "08:00", "activity": "work"}]}
	)
	assert_true(errors.is_empty())
	assert_true(ScheduleResolver.validate_full_day({"id": "empty", "weekday_blocks": []}).size() > 0)


func test_personal_override_moves_and_replaces_one_block_without_copying_profile() -> void:
	var profile := {
		"id": "override_test",
		"weekday_blocks": [
			{"id": "work", "start": "08:00", "activity": "work", "destination": "shop"},
			{"id": "sleep", "start": "22:00", "activity": "sleep", "destination": "home"}
		]
	}
	var overrides: Array = [{"block_id": "work", "start": "10:00", "activity": "eat", "destination": "inn"}]
	assert_eq(ScheduleResolver.resolve(profile, 9 * 60, 1, overrides)["activity"], "sleep")
	var current := ScheduleResolver.resolve(profile, 10 * 60, 1, overrides)
	assert_eq(current["activity"], "eat")
	assert_eq(current["destination"], "inn")


func test_weekend_blocks_replace_weekday_routine_and_preserve_authored_actions() -> void:
	var profile := {
		"id": "weekend_test",
		"weekday_blocks": [
			{"id": "weekday", "start": "08:00", "activity": "work"},
			{"id": "sleep", "start": "22:00", "activity": "sleep"}
		],
		"weekend_blocks": [
			{"id": "late_wake", "start": "10:00", "activity": "relax", "action_pool": ["visit", "wander"]},
			{"id": "weekend_sleep", "start": "23:00", "activity": "sleep"}
		]
	}
	assert_eq(ScheduleResolver.resolve(profile, 9 * 60, 1)["activity"], "work")
	var weekend := ScheduleResolver.resolve(profile, 9 * 60, 6)
	assert_eq(weekend["activity"], "sleep")
	var active_weekend := ScheduleResolver.resolve(profile, 10 * 60, 6)
	assert_eq(active_weekend["activity"], "relax")
	assert_eq(active_weekend["action_pool"], ["visit", "wander"])
	assert_true(ScheduleResolver.validate_full_day(profile, 6).is_empty())


func test_weather_overrides_change_only_authored_blocks_and_keep_personal_precedence() -> void:
	var profile := {
		"id": "weather_test",
		"weekday_blocks": [
			{"id": "farm", "start": "08:00", "activity": "work", "destination": "field"},
			{"id": "sleep", "start": "22:00", "activity": "sleep", "destination": "home"}
		],
		"weather_overrides": {
			"rain": [{"block_id": "farm", "destination": "home", "action": "sort seed indoors"}]
		}
	}
	var rainy := ScheduleResolver.resolve(profile, 9 * 60, 1, [], "farmer", "rain")
	assert_eq(rainy["activity"], "work")
	assert_eq(rainy["destination"], "home")
	assert_eq(rainy["action"], "sort seed indoors")
	var personal := ScheduleResolver.resolve(
		profile,
		9 * 60,
		1,
		[{"block_id": "farm", "destination": "barn", "action": "check animals"}],
		"farmer",
		"rain"
	)
	assert_eq(personal["destination"], "barn")
	assert_eq(personal["action"], "check animals")
