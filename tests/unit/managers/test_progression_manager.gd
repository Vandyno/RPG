extends GutTest

const EventBus = preload("res://scripts/core/event_bus.gd")
const ProgressionManager = preload("res://scripts/managers/progression_manager.gd")


func test_progression_adds_xp_levels_up_and_emits_changes() -> void:
	var bus := EventBus.new()
	add_child_autofree(bus)
	var changes: Array[Dictionary] = []
	bus.progression_changed.connect(
		func(level: int, experience: int, next_level: int, skill_points: int) -> void:
			changes.append(
				{
					"level": level,
					"experience": experience,
					"next_level": next_level,
					"skill_points": skill_points
				}
			)
	)
	var progression := ProgressionManager.new()
	add_child_autofree(progression)
	progression.setup(bus)

	assert_true(progression.add_experience(19))
	assert_eq(progression.level, 1)
	assert_eq(progression.experience, 19)
	assert_eq(progression.skill_points, 0)
	assert_eq(progression.get_player_damage_bonus(), 0)

	assert_true(progression.add_experience(1))
	assert_eq(progression.level, 2)
	assert_eq(progression.experience, 0)
	assert_eq(progression.skill_points, 1)
	assert_eq(progression.experience_to_next_level(), 40)
	assert_eq(progression.get_player_damage_bonus(), 1)
	assert_false(progression.spend_point("old_stat"))
	assert_eq(progression.skill_points, 1)
	assert_eq(progression.get_stat_rank("old_stat"), 0)
	assert_true(progression.get_trainable_stat_ids().is_empty())
	assert_true(progression.get_summary().contains("Level 2"))
	assert_gt(changes.size(), 1)
	assert_eq(changes.back()["level"], 2)


func test_progression_rejects_invalid_xp_and_sanitizes_save_data() -> void:
	var progression := ProgressionManager.new()
	add_child_autofree(progression)

	assert_false(progression.add_experience(0))
	assert_eq(
		progression.get_save_data(),
		{"level": 1, "experience": 0, "skill_points": 0}
	)

	progression.load_save_data(
		{
			"level": 3,
			"experience": 999,
			"skill_points": -5,
			"stats": {"legacy": 2}
		}
	)

	assert_eq(progression.level, 3)
	assert_eq(progression.experience, 59)
	assert_eq(progression.skill_points, 0)
	assert_eq(progression.get_stat_rank("legacy"), 0)
	assert_eq(progression.guarded_counter_multiplier(0.5), 0.5)
	assert_true(progression.is_level_at_least(2))
	assert_false(progression.is_level_at_least(4))

	progression.load_save_data({"level": "high", "experience": "lots", "skill_points": "many"})

	assert_eq(progression.level, 1)
	assert_eq(progression.experience, 0)
	assert_eq(progression.skill_points, 0)
	assert_eq(progression.get_stat_rank("legacy"), 0)


func test_progression_has_no_trainable_stats_yet() -> void:
	var progression := ProgressionManager.new()
	add_child_autofree(progression)
	progression.load_save_data({"level": 2, "skill_points": 2})

	assert_true(progression.get_trainable_stat_ids().is_empty())
	assert_false(progression.spend_point("old_stat"))
	assert_eq(progression.skill_points, 2)
	assert_almost_eq(progression.guarded_counter_multiplier(0.5), 0.5, 0.001)
	assert_false(progression.get_details().contains("old_stat"))
