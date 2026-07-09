extends GutTest

const ContentCardPresenter = preload("res://scripts/ui/shell/content_card_presenter.gd")


class ChoiceOwner:
	extends Node

	signal content_choice_selected(choice_id: String)


func test_build_creates_hidden_centered_content_panel() -> void:
	var root := Control.new()
	add_child_autofree(root)
	var close_calls: Array[int] = [0]

	var nodes := ContentCardPresenter.build(
		ContentCardPresenter.BuildContext.new(
			root,
			_new_panel,
			_add_margin,
			_new_label,
			_new_button,
			func() -> void: close_calls[0] += 1
		)
	)

	var panel := nodes["panel"] as PanelContainer
	var kind_label := nodes["kind_label"] as Label
	var title_label := nodes["title_label"] as Label
	var scroll := nodes["scroll"] as ScrollContainer
	var body_label := nodes["body_label"] as Label
	var choice_list := nodes["choice_list"] as VBoxContainer
	var close := panel.find_child("Close", true, false) as Button

	assert_same(root.get_child(0), panel)
	assert_eq(panel.name, "ContentPanel")
	assert_false(panel.visible)
	assert_eq(panel.anchor_left, 0.5)
	assert_eq(panel.anchor_right, 0.5)
	assert_eq(panel.anchor_top, 0.5)
	assert_eq(panel.anchor_bottom, 0.5)
	assert_eq(panel.offset_left, -280.0)
	assert_eq(panel.offset_top, -164.0)
	assert_eq(panel.offset_right, 280.0)
	assert_eq(panel.offset_bottom, 164.0)
	assert_eq(kind_label.size_flags_horizontal, Control.SIZE_EXPAND_FILL)
	assert_eq(title_label.get_theme_font_size("font_size"), 20)
	assert_eq(scroll.name, "ContentScroll")
	assert_eq(body_label.size_flags_vertical, Control.SIZE_EXPAND_FILL)
	assert_eq(choice_list.name, "ContentChoices")
	assert_eq(choice_list.get_theme_constant("separation"), 6)

	close.pressed.emit()
	assert_eq(close_calls[0], 1)


func test_build_returns_empty_for_missing_root() -> void:
	assert_true(ContentCardPresenter.build(null).is_empty())
	assert_true(
		ContentCardPresenter.build(
			ContentCardPresenter.BuildContext.new(
				null, _new_panel, _add_margin, _new_label, _new_button, Callable()
			)
		).is_empty()
	)


func test_kind_text_maps_known_content_modes_to_labels() -> void:
	assert_eq(ContentCardPresenter.kind_text("dialogue"), "Dialogue")
	assert_eq(ContentCardPresenter.kind_text("readable"), "Readable")
	assert_eq(ContentCardPresenter.kind_text("place"), "Place")
	assert_eq(ContentCardPresenter.kind_text("response"), "Result")
	assert_eq(ContentCardPresenter.kind_text("unexpected"), "Notice")


func test_refresh_choices_builds_buttons_and_routes_selected_choice() -> void:
	var choice_list := VBoxContainer.new()
	add_child_autofree(choice_list)
	var owner := ChoiceOwner.new()
	add_child_autofree(owner)
	var selected: Array[String] = []
	owner.content_choice_selected.connect(func(choice_id: String) -> void: selected.append(choice_id))

	assert_true(
		ContentCardPresenter.refresh_choices(
			choice_list,
			[
				{"id": "ask", "text": "Ask about tools"},
				{"id": "", "text": "Ignored"},
				{"id": "accept", "text": "I'll find it."},
			],
			owner
		)
	)
	assert_eq(choice_list.get_child_count(), 2)

	var ask := choice_list.get_child(0) as Button
	var accept := choice_list.get_child(1) as Button
	assert_eq(ask.text, "Ask about tools")
	assert_eq(ask.custom_minimum_size, Vector2(0, 50))
	assert_eq(ask.get_meta("choice_id"), "ask")
	assert_eq(ask.get_theme_font_size("font_size"), 14)
	assert_eq(accept.text, "I'll find it.")

	accept.pressed.emit()
	assert_eq(selected, ["accept"])


func test_refresh_choices_hides_stale_buttons_when_actions_shrink() -> void:
	var choice_list := VBoxContainer.new()
	add_child_autofree(choice_list)
	var owner := ChoiceOwner.new()
	add_child_autofree(owner)

	assert_true(
		ContentCardPresenter.refresh_choices(
			choice_list,
			[
				{"id": "ask", "text": "Ask"},
				{"id": "accept", "text": "Accept"},
			],
			owner
		)
	)
	assert_true(
		ContentCardPresenter.refresh_choices(
			choice_list, [{"id": "ask", "text": "Ask"}], owner
		)
	)

	assert_eq(choice_list.get_child_count(), 2)
	assert_true(choice_list.get_child(0).visible)
	assert_false(choice_list.get_child(1).visible)


func _new_panel(name: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = name
	return panel


func _add_margin(panel: PanelContainer, child: Control, margin: int) -> void:
	var margin_container := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin_container.add_theme_constant_override("margin_%s" % side, margin)
	panel.add_child(margin_container)
	margin_container.add_child(child)


func _new_label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _new_button(text: String, size: Vector2) -> Button:
	var button := Button.new()
	button.name = text
	button.text = text
	button.custom_minimum_size = size
	return button
