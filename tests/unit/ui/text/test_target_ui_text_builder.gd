extends GutTest

const TargetUiTextBuilder = preload("res://scripts/ui/text/target_ui_text_builder.gd")


func test_action_button_text_uses_next_target_and_picker_state() -> void:
	var targets := [
		{"id": "notice", "name": "Road Notice", "selected": true},
		{"id": "harrow", "name": "Harrow Venn"}
	]

	assert_eq(TargetUiTextBuilder.action_button_text(targets, false, false), "Next")
	assert_eq(TargetUiTextBuilder.action_button_text(targets, true, false), "Next\nHarrow Venn")
	assert_eq(TargetUiTextBuilder.action_button_text(targets, true, true), "Close")


func test_action_button_tooltip_names_next_target_when_available() -> void:
	var targets := [
		{"id": "notice", "name": "Road Notice", "selected": true},
		{"id": "harrow", "name": "Harrow Venn"}
	]

	assert_eq(
		TargetUiTextBuilder.action_button_tooltip(targets, false),
		"Next target: Harrow Venn. Hold for target list."
	)
	assert_eq(TargetUiTextBuilder.action_button_tooltip([targets[0]], false), "Hold for target list.")
	assert_eq(TargetUiTextBuilder.action_button_tooltip(targets, true), "Close targets")


func test_summary_label_counts_valid_targets_by_kind_in_seen_order() -> void:
	var targets := [
		{"id": "notice", "kind": "readable"},
		{"id": "harrow", "kind": "npc"},
		{"id": "maera", "kind": "npc"},
		{"id": "", "kind": "door"},
		"bad"
	]

	assert_eq(TargetUiTextBuilder.summary_label(targets), "3 targets: Readable 1, NPC 2")
	assert_eq(TargetUiTextBuilder.summary_label([]), "")


func test_next_target_name_wraps_selected_target_and_filters_bad_entries() -> void:
	var targets := [
		{"id": "notice", "name": "Road Notice"},
		"bad",
		{"id": "", "name": "Blank"},
		{"id": "harrow", "name": "Harrow Venn", "selected": true}
	]

	assert_eq(TargetUiTextBuilder.next_target_name(targets), "Road Notice")
