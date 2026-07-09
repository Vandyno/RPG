extends GutTest

const UiActionButtons = preload("res://scripts/ui/shell/ui_action_buttons.gd")


class SignalOwner:
	extends Node

	signal action_selected(action_id: String)


func test_refresh_rejects_incomplete_requests() -> void:
	var container := VBoxContainer.new()
	add_child_autofree(container)
	var owner := SignalOwner.new()
	add_child_autofree(owner)

	assert_false(UiActionButtons.refresh(null))
	assert_false(UiActionButtons.refresh(UiActionButtons.RefreshRequest.new()))
	assert_false(
		UiActionButtons.refresh(
			UiActionButtons.RefreshRequest.new(
				{
					"container": container,
					"owner": owner,
					"signal_id": "",
					"meta_id": "action_id"
				}
			)
		)
	)


func test_refresh_builds_valid_action_buttons_and_emits_meta_id() -> void:
	var container := VBoxContainer.new()
	add_child_autofree(container)
	var owner := SignalOwner.new()
	add_child_autofree(owner)
	var selected: Array[String] = []
	owner.action_selected.connect(func(action_id: String) -> void: selected.append(action_id))

	assert_true(
		UiActionButtons.refresh(
			UiActionButtons.RefreshRequest.new(
				{
					"container": container,
					"actions":
					[
						{"id": "ask", "text": "Ask"},
						"bad",
						{"id": "", "text": "Ignored"},
						{"id": "accept", "text": "Accept"},
					],
					"owner": owner,
					"signal_id": "action_selected",
					"meta_id": "action_id",
					"min_size": Vector2(12, 34),
					"font_size": 17
				}
			)
		)
	)

	assert_eq(container.get_child_count(), 2)
	var ask := container.get_child(0) as Button
	var accept := container.get_child(1) as Button
	assert_eq(ask.text, "Ask")
	assert_eq(ask.custom_minimum_size, Vector2(12, 34))
	assert_eq(ask.get_theme_font_size("font_size"), 17)
	assert_eq(ask.get_meta("signal_id"), "action_selected")
	assert_eq(ask.get_meta("meta_id"), "action_id")
	assert_eq(ask.get_meta("action_id"), "ask")
	assert_eq(accept.text, "Accept")

	accept.pressed.emit()
	assert_eq(selected, ["accept"])


func test_refresh_reuses_buttons_and_hides_stale_children() -> void:
	var container := VBoxContainer.new()
	add_child_autofree(container)
	var owner := SignalOwner.new()
	add_child_autofree(owner)
	var first := _request(container, owner, [{"id": "one", "text": "One"}])
	var second := _request(
		container,
		owner,
		[
			{"id": "one", "text": "One again"},
			{"id": "two", "text": "Two"},
		]
	)
	var third := _request(container, owner, [{"id": "two", "text": "Two only"}])

	assert_true(UiActionButtons.refresh(first))
	var original := container.get_child(0)
	assert_true(UiActionButtons.refresh(second))
	assert_same(container.get_child(0), original)
	assert_eq(container.get_child_count(), 2)

	assert_true(UiActionButtons.refresh(third))
	assert_eq((container.get_child(0) as Button).text, "Two only")
	assert_true(container.get_child(0).visible)
	assert_false(container.get_child(1).visible)


func test_refresh_can_show_disabled_empty_button() -> void:
	var container := VBoxContainer.new()
	add_child_autofree(container)
	var owner := SignalOwner.new()
	add_child_autofree(owner)
	var request := _request(container, owner, [])
	request.empty_text = "No actions"

	assert_true(UiActionButtons.refresh(request))

	var empty := container.get_child(0) as Button
	assert_eq(empty.text, "No actions")
	assert_true(empty.disabled)


func test_valid_action_count_counts_only_complete_dictionary_actions() -> void:
	assert_eq(
		UiActionButtons.valid_action_count(
			[
				{"id": "one", "text": "One"},
				{"id": "", "text": "Missing id"},
				{"id": "missing_text"},
				"bad",
				{"id": "two", "text": "Two"},
			]
		),
		2
	)


func test_wrapped_panel_height_respects_base_rows_and_viewport_cap() -> void:
	var metrics := UiActionButtons.WrappedPanelMetrics.new(
		{
			"panel_width": 300.0,
			"action_count": 4,
			"button_size": Vector2(100, 40),
			"separation": Vector2(8, 6),
			"margin": 12.0,
			"base_height": 70.0,
			"top": 10.0,
			"reserved_bottom": 20.0,
			"outer_margin": 5.0,
			"viewport_height": 200.0
		}
	)

	assert_eq(UiActionButtons.wrapped_panel_height(null), 0.0)
	metrics.action_count = 0
	assert_eq(UiActionButtons.wrapped_panel_height(metrics), 70.0)
	metrics.action_count = 4
	assert_eq(UiActionButtons.wrapped_panel_height(metrics), 110.0)
	metrics.action_count = 20
	assert_eq(UiActionButtons.wrapped_panel_height(metrics), 165.0)


func _request(
	container: Container, owner: Object, actions: Array
) -> UiActionButtons.RefreshRequest:
	return UiActionButtons.RefreshRequest.new(
		{
			"container": container,
			"actions": actions,
			"owner": owner,
			"signal_id": "action_selected",
			"meta_id": "action_id",
			"min_size": Vector2(0, 40),
			"font_size": 15
		}
	)
