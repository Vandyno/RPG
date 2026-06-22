extends GutTest

const Main = preload("res://scripts/main/main.gd")


func test_unselected_world_hints_name_short_targets_when_they_fit() -> void:
	var main := Main.new()
	add_child_autofree(main)

	main._handle_target_selected("object_sealed_strongbox")
	main._update_nearby()

	var named_hint_count := 0
	for entity in main.entities.entities_by_id.values():
		if entity.action_hint_selected or not entity.action_hint_visible:
			continue
		if entity.action_hint_text.contains(entity.get_display_name()):
			named_hint_count += 1

	assert_gt(named_hint_count, 0)
