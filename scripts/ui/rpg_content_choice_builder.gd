class_name RpgContentChoiceBuilder
extends RefCounted


static func refresh(
	container: VBoxContainer,
	choices: Array,
	new_button: Callable,
	row_style: Callable,
	owner: Object,
	compact: bool
) -> bool:
	var button_index := 0
	for choice in choices:
		if not choice is Dictionary:
			continue
		var choice_id := String(choice.get("id", ""))
		var text := String(choice.get("text", ""))
		if choice_id.is_empty() or text.is_empty():
			continue
		var button := _button(container, button_index, new_button)
		button.text = _button_text(choice)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.disabled = false
		button.visible = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 46) if compact else Vector2(0, 58)
		button.add_theme_font_size_override("font_size", 12 if compact else 14)
		button.set_meta("choice_id", choice_id)
		row_style.call(button, _is_recommended(choice))
		_bind_button(button, owner)
		button_index += 1
	for index in range(button_index, container.get_child_count()):
		container.get_child(index).visible = false
	return button_index > 0


static func preview_text(choices: Array, kind: String) -> String:
	var choice := _preview_choice(choices)
	if choice.is_empty():
		return "%s - close when finished." % _kind_text(kind)
	var explicit := String(choice.get("preview", ""))
	if not explicit.is_empty():
		return explicit
	var lines: Array[String] = [String(choice.get("text", ""))]
	var subtitle := _subtitle(choice)
	if not subtitle.is_empty():
		lines.append(subtitle)
	var response := String(choice.get("response", ""))
	if not response.is_empty():
		lines.append(_shorten(response, 94))
	return "\n".join(lines)


static func preview_title(choices: Array, kind: String) -> String:
	var choice := _preview_choice(choices)
	if choice.is_empty():
		return _kind_text(kind)
	for effect in _array_field(choice.get("effects", [])):
		if not effect is Dictionary:
			continue
		var effect_type := String(effect.get("type", ""))
		if effect_type.ends_with("_quest") or effect_type == "set_quest_stage":
			return "Quest: %s" % _title_from_id(String(effect.get("quest_id", "")))
	return "Action Preview"


static func preview_rewards(choices: Array) -> String:
	var choice := _preview_choice(choices)
	if choice.is_empty():
		return ""
	var parts: Array[String] = []
	for effect in _array_field(choice.get("effects", [])):
		if not effect is Dictionary:
			continue
		var text := _effect_text(effect)
		if not text.is_empty():
			parts.append(text)
	return "\n".join(parts)


static func _button(container: VBoxContainer, index: int, new_button: Callable) -> Button:
	if index < container.get_child_count():
		var existing := container.get_child(index)
		if existing is Button:
			return existing
	var button := new_button.call("", Vector2(0, 58)) as Button
	button.focus_mode = Control.FOCUS_NONE
	container.add_child(button)
	return button


static func _bind_button(button: Button, owner: Object) -> void:
	if bool(button.get_meta("content_choice_bound", false)):
		return
	button.set_meta("content_choice_bound", true)
	button.pressed.connect(
		func() -> void:
			owner.emit_signal("content_choice_selected", String(button.get_meta("choice_id", "")))
	)


static func _button_text(choice: Dictionary) -> String:
	var subtitle := _subtitle(choice)
	if subtitle.is_empty():
		return String(choice.get("text", ""))
	return "%s\n%s" % [String(choice.get("text", "")), subtitle]


static func _subtitle(choice: Dictionary) -> String:
	var explicit := String(choice.get("subtitle", ""))
	if not explicit.is_empty():
		return explicit
	var effects := _effect_summary(choice.get("effects", []))
	if not effects.is_empty():
		return effects
	var text := String(choice.get("text", "")).to_lower()
	var choice_id := String(choice.get("id", "")).to_lower()
	if text == "leave" or choice_id == "leave":
		return "End conversation."
	if text.contains("ask"):
		return "Learn more before acting."
	if text.contains("forge") or text.contains("service") or text.contains("sharpen"):
		return "Use local services."
	if text.contains("trade"):
		return "Open merchant services."
	if text.contains("not right now"):
		return "Decline for now."
	if not String(choice.get("response", "")).is_empty():
		return "Hear the response."
	return "Choose this response."


static func _effect_summary(effects_value: Variant) -> String:
	var parts: Array[String] = []
	for effect in _array_field(effects_value):
		if not effect is Dictionary:
			continue
		var text := _effect_text(effect)
		if not text.is_empty():
			parts.append(text)
	return ", ".join(parts)


static func _effect_text(effect: Dictionary) -> String:
	match String(effect.get("type", "")):
		"start_quest":
			return "Starts quest"
		"set_quest_stage":
			return "Updates quest"
		"complete_quest":
			return "Completes quest"
		"add_item":
			return "Gain item"
		"remove_item":
			return "Spend item"
		"change_reputation":
			return "Changes reputation"
		"add_experience":
			var amount: Variant = effect.get("amount", 0)
			return "XP +%d" % int(amount) if amount is int or amount is float else "Gain XP"
		"apply_status":
			return "Applies status"
		"advance_time":
			return "Time passes"
	return ""


static func _preview_choice(choices: Array) -> Dictionary:
	for choice in choices:
		if choice is Dictionary and _is_recommended(choice):
			return choice
	for choice in choices:
		if choice is Dictionary and not String(choice.get("id", "")).is_empty():
			return choice
	return {}


static func _is_recommended(choice: Dictionary) -> bool:
	var text := String(choice.get("text", "")).to_lower()
	return (
		not _array_field(choice.get("effects", [])).is_empty()
		or text.begins_with("turn in")
		or text.begins_with("report")
		or text.begins_with("take")
		or text.begins_with("accept")
	)


static func _kind_text(kind: String) -> String:
	match kind:
		"dialogue":
			return "Dialogue"
		"readable":
			return "Readable"
		"place":
			return "Place"
		"response":
			return "Result"
	return "Notice"


static func _shorten(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return "%s..." % text.substr(0, maxi(0, max_chars - 3)).strip_edges()


static func _title_from_id(value: String) -> String:
	var cleaned := value.strip_edges()
	if cleaned.begins_with("quest_"):
		cleaned = cleaned.substr(6)
	if cleaned.is_empty():
		return "Quest"
	var words: Array[String] = []
	for part in cleaned.split("_", false):
		words.append(part.capitalize())
	return " ".join(words)


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
