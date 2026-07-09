extends GutTest


class ChoiceOwner:
	extends Node

	signal content_choice_selected(choice_id: String)


func test_refresh_builds_choice_cards_and_close_action() -> void:
	var container := VBoxContainer.new()
	add_child_autofree(container)
	var owner := ChoiceOwner.new()
	add_child_autofree(owner)
	var selected: Array[String] = []
	var close_calls: Array[int] = [0]
	owner.content_choice_selected.connect(func(choice_id: String) -> void: selected.append(choice_id))

	var request := _request(container, owner, false, func() -> void: close_calls[0] += 1)
	request.choices = [
		"not a choice",
		{},
		{"id": "accept", "text": "Accept", "effects": [{"type": "start_quest"}]},
	]
	request.close_text = "Leave"

	assert_true(RpgContentChoiceBuilder.refresh(request))
	assert_eq(container.get_child_count(), 2)

	var accept := container.get_child(0) as RpgContentChoiceButton
	var close := container.get_child(1) as RpgContentChoiceButton
	assert_eq(accept.text, "Accept\nStarts quest")
	assert_eq(accept.choice_icon, "quest")
	assert_eq(accept.choice_subtitle, "Starts quest")
	assert_eq(accept.get_meta("choice_id"), "accept")
	assert_false(bool(accept.get_meta("content_close_choice")))
	assert_true(bool(accept.get_meta("choice_recommended")))
	assert_true(bool(accept.get_meta("styled_recommended")))
	assert_eq(accept.custom_minimum_size, Vector2(0, 44))
	assert_eq(close.text, "Leave")
	assert_eq(close.choice_title, "Leave")
	assert_true(close.centered)
	assert_true(bool(close.get_meta("content_close_choice")))

	accept.pressed.emit()
	close.pressed.emit()

	assert_eq(selected, ["accept"])
	assert_eq(close_calls[0], 1)


func test_refresh_reuses_buttons_and_hides_stale_rows() -> void:
	var container := VBoxContainer.new()
	add_child_autofree(container)
	var owner := ChoiceOwner.new()
	add_child_autofree(owner)
	var selected: Array[String] = []
	owner.content_choice_selected.connect(func(choice_id: String) -> void: selected.append(choice_id))
	var request := _request(container, owner, true, Callable())
	request.choices = [
		{"id": "ask", "text": "Ask about tools", "response": "Try Harrow."},
		{"id": "trade:shop", "text": "Trade"},
	]

	assert_true(RpgContentChoiceBuilder.refresh(request))
	request.choices = [{"id": "ask", "text": "Ask about tools", "response": "Try Harrow."}]
	assert_true(RpgContentChoiceBuilder.refresh(request))

	var ask := container.get_child(0) as RpgContentChoiceButton
	var stale := container.get_child(1) as RpgContentChoiceButton
	assert_true(ask.visible)
	assert_false(stale.visible)
	assert_eq(ask.custom_minimum_size, Vector2(0, 46))

	ask.pressed.emit()
	assert_eq(selected, ["ask"])


func test_preview_text_prefers_recommended_choice_and_effect_rewards() -> void:
	var choices := [
		{"id": "ask", "text": "Ask about tools", "response": "Look near the forge."},
		{
			"id": "turn_in",
			"text": "Turn in Toolbox",
			"effects":
			[
				{"type": "complete_quest", "quest_id": "quest_missing_tools"},
				{"type": "add_experience", "amount": 25},
			]
		},
	]

	assert_eq(RpgContentChoiceBuilder.preview_title(choices, "dialogue"), "Quest: Missing Tools")
	assert_eq(
		RpgContentChoiceBuilder.preview_text(choices, "dialogue"),
		"Turn in Toolbox\nCompletes quest, XP +25"
	)
	assert_eq(RpgContentChoiceBuilder.preview_rewards(choices), "Completes quest\nXP +25")
	assert_eq(RpgContentChoiceBuilder.preview_compact_rewards(choices), "Completes quest, XP +25")


func test_preview_fallbacks_are_player_facing() -> void:
	assert_eq(RpgContentChoiceBuilder.preview_title([], "readable"), "Readable")
	assert_eq(
		RpgContentChoiceBuilder.preview_text([], "readable"),
		"Readable - close when finished."
	)
	assert_eq(RpgContentChoiceBuilder.preview_compact_text([], "place"), "Place ready.")


func _request(
	container: VBoxContainer, owner: Object, compact: bool, close_callback: Callable
) -> RpgContentChoiceBuilder.RefreshRequest:
	var request := RpgContentChoiceBuilder.RefreshRequest.new()
	request.container = container
	request.new_button = _new_button
	request.row_style = _style_button
	request.owner = owner
	request.compact = compact
	request.close_callback = close_callback
	return request


func _new_button(_text: String, _size: Vector2) -> Button:
	return Button.new()


func _style_button(button: Button, recommended: bool) -> void:
	button.set_meta("styled_recommended", recommended)
