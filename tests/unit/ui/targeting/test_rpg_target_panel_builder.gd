extends GutTest

const RpgTargetPanelBuilder = preload("res://scripts/ui/targeting/rpg_target_panel_builder.gd")


func test_target_text_cleans_detail_and_formats_navigation() -> void:
	var text := RpgTargetPanelBuilder._target_text(
		{
			"id": "notice",
			"name": "Road Notice",
			"kind": "readable",
			"detail": "Readable: Road Notice",
			"navigation": "NE 2t town gate"
		},
		false
	)

	assert_eq(text, "Road Notice\nRead\n2 tiles northeast to town gate")


func test_refresh_builds_target_buttons_and_routes_pressed_entity_id() -> void:
	var list := VBoxContainer.new()
	add_child_autofree(list)
	var selected: Array[String] = []
	var request := RpgTargetPanelBuilder.RefreshRequest.new(
		list,
		[
			{"id": "notice", "name": "Road Notice", "kind": "readable", "selected": true},
			"bad",
			{"id": "", "name": "Blank"},
			{"id": "harrow", "name": "Harrow Venn", "kind": "npc"}
		],
		func(_size: int) -> Label: return Label.new(),
		func(text: String, _size: Vector2) -> Button:
			var button := Button.new()
			button.text = text
			return button,
		func(button: Button, is_selected: bool) -> void:
			button.set_meta("styled_selected", is_selected),
		func(entity_id: String) -> void:
			selected.append(entity_id),
		false
	)

	RpgTargetPanelBuilder.refresh(request)
	var first := list.get_child(0) as Button
	var second := list.get_child(1) as Button
	first.pressed.emit()
	second.pressed.emit()

	assert_eq(list.get_child_count(), 2)
	assert_eq(first.name, "TargetRow_Notice")
	assert_true(bool(first.get_meta("selected_target")))
	assert_true(bool(first.get_meta("styled_selected")))
	assert_eq(second.name, "TargetRow_Harrow")
	assert_eq(selected, ["notice", "harrow"])


func test_refresh_shows_empty_label_when_no_targets() -> void:
	var list := VBoxContainer.new()
	add_child_autofree(list)
	var request := RpgTargetPanelBuilder.RefreshRequest.new(
		list,
		[],
		func(_size: int) -> Label: return Label.new(),
		func(_text: String, _size: Vector2) -> Button: return Button.new(),
		Callable(),
		Callable(),
		false
	)

	RpgTargetPanelBuilder.refresh(request)

	assert_eq(list.get_child_count(), 1)
	assert_eq((list.get_child(0) as Label).text, "No reachable targets.")


func test_apply_layout_sets_compact_panel_bounds_and_title_state() -> void:
	var panel := PanelContainer.new()
	var stack := VBoxContainer.new()
	var title := Label.new()
	var subtitle := Label.new()
	var list := VBoxContainer.new()
	add_child_autofree(panel)
	add_child_autofree(list)
	title.name = "TargetTitle"
	subtitle.name = "TargetSubtitle"
	stack.add_child(title)
	stack.add_child(subtitle)
	panel.add_child(stack)

	RpgTargetPanelBuilder.apply_layout(panel, list, Vector2(360.0, 420.0), true, 12.0)

	assert_eq(panel.anchor_left, 0.0)
	assert_eq(panel.offset_left, 12.0)
	assert_eq(panel.offset_right, 348.0)
	assert_false(subtitle.visible)
	assert_eq(list.get_theme_constant("separation"), 7)
