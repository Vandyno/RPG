class_name RpgContentChoiceBuilder
extends RefCounted


static func refresh(
	container: VBoxContainer,
	choices: Array,
	new_button: Callable,
	row_style: Callable,
	owner: Object,
	compact: bool,
	close_callback: Callable = Callable(),
	close_text := ""
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
		button.custom_minimum_size = Vector2(0, 46) if compact else Vector2(0, 44)
		button.add_theme_font_size_override("font_size", 10 if compact else 13)
		button.set_meta("choice_id", choice_id)
		var closes := _choice_closes(choice)
		button.set_meta("content_close_choice", closes)
		row_style.call(button, _is_recommended(choice) and not closes)
		_bind_button(button, owner, close_callback)
		button_index += 1
	if button_index > 0 and not close_text.is_empty() and not _has_close_choice(choices):
		var close := _button(container, button_index, new_button)
		close.text = close_text
		close.alignment = HORIZONTAL_ALIGNMENT_CENTER
		close.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		close.disabled = false
		close.visible = true
		close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		close.custom_minimum_size = Vector2(0, 46) if compact else Vector2(0, 44)
		close.add_theme_font_size_override("font_size", 10 if compact else 13)
		close.set_meta("choice_id", "")
		close.set_meta("content_close_choice", true)
		row_style.call(close, false)
		_bind_button(close, owner, close_callback)
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


static func preview_compact_text(choices: Array, kind: String) -> String:
	var choice := _preview_choice(choices)
	if choice.is_empty():
		return "%s ready." % _kind_text(kind)
	var explicit := String(choice.get("preview", ""))
	if not explicit.is_empty():
		return _shorten(explicit, 42)
	var subtitle := _subtitle(choice)
	return _shorten(subtitle if not subtitle.is_empty() else String(choice.get("text", "")), 42)


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


static func preview_compact_rewards(choices: Array) -> String:
	var rewards := preview_rewards(choices).replace("\n", ", ")
	return _shorten(rewards, 42)


static func _button(container: VBoxContainer, index: int, new_button: Callable) -> Button:
	if index < container.get_child_count():
		var existing := container.get_child(index)
		if existing is Button:
			return existing
	var button := new_button.call("", Vector2(0, 58)) as Button
	button.focus_mode = Control.FOCUS_NONE
	container.add_child(button)
	return button


static func _bind_button(button: Button, owner: Object, close_callback: Callable) -> void:
	if bool(button.get_meta("content_choice_bound", false)):
		return
	button.set_meta("content_choice_bound", true)
	button.pressed.connect(
		func() -> void:
			if bool(button.get_meta("content_close_choice", false)):
				if close_callback.is_valid():
					close_callback.call()
				return
			owner.emit_signal("content_choice_selected", String(button.get_meta("choice_id", "")))
	)


static func _button_text(choice: Dictionary) -> String:
	var prefix := _choice_icon(choice)
	var title := String(choice.get("text", ""))
	if _choice_closes(choice):
		return title
	var subtitle := _subtitle(choice)
	if subtitle.is_empty():
		return "%s  %s" % [prefix, title]
	return "%s  %s\n%s" % [prefix, title, subtitle]


static func _choice_icon(choice: Dictionary) -> String:
	if _choice_closes(choice):
		return "X"
	var text := String(choice.get("text", "")).to_lower()
	var choice_id := String(choice.get("id", "")).to_lower()
	if _effect_summary(choice.get("effects", [])).contains("quest") or text.begins_with("turn in"):
		return "Q"
	if text.contains("forge") or text.contains("service") or text.contains("sharpen"):
		return "S"
	if text.contains("trade") or choice_id.contains("trade"):
		return "T"
	if text.contains("ask") or not String(choice.get("response", "")).is_empty():
		return "D"
	return "A"


static func _has_close_choice(choices: Array) -> bool:
	for choice in choices:
		if not choice is Dictionary:
			continue
		if _choice_closes(choice):
			return true
	return false


static func _choice_closes(choice: Dictionary) -> bool:
	var text := String(choice.get("text", "")).to_lower()
	var choice_id := String(choice.get("id", "")).to_lower()
	return text == "leave" or text == "close" or choice_id == "leave" or choice_id == "close"


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
