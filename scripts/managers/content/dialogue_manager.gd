class_name DialogueManager
extends Node

var content
var condition_evaluator
var effect_runner


func setup(content_database, conditions, effects) -> void:
	content = content_database
	condition_evaluator = conditions
	effect_runner = effects


func resolve_dialogue(dialogue_id: String, fallback_speaker: String = "Speaker") -> Dictionary:
	return _resolve_dialogue(dialogue_id, fallback_speaker, true)


func preview_dialogue(dialogue_id: String, fallback_speaker: String = "Speaker") -> Dictionary:
	return _resolve_dialogue(dialogue_id, fallback_speaker, false)


func _resolve_dialogue(
	dialogue_id: String, fallback_speaker: String = "Speaker", apply_line_effects: bool = true
) -> Dictionary:
	var dialogue: Dictionary = content.get_dialogue(dialogue_id) if content else {}
	if dialogue.is_empty():
		return {}
	for line in _array_field(dialogue.get("lines", [])):
		if not line is Dictionary:
			continue
		var conditions := _array_field(line.get("conditions", []))
		if condition_evaluator and not condition_evaluator.evaluate_all(conditions):
			continue
		if apply_line_effects:
			for effect in _array_field(line.get("effects", [])):
				if effect is Dictionary and effect_runner:
					effect_runner.apply(effect)
		return {
			"speaker": String(line.get("speaker", fallback_speaker)),
			"text": String(line.get("text", "")),
			"line_id": String(line.get("id", "")),
			"effects": _array_field(line.get("effects", [])).duplicate(true),
			"choices": _available_choices(line)
		}
	return {}


func apply_choice(choice: Dictionary) -> Dictionary:
	if choice.is_empty():
		return {}
	for effect in _array_field(choice.get("effects", [])):
		if effect is Dictionary and effect_runner:
			effect_runner.apply(effect)
	return {
		"choice_id": String(choice.get("id", "")),
		"text": String(choice.get("text", "")),
		"response": String(choice.get("response", ""))
	}


func _available_choices(line: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for choice in _array_field(line.get("choices", [])):
		if not choice is Dictionary:
			continue
		var conditions := _array_field(choice.get("conditions", []))
		if condition_evaluator and not condition_evaluator.evaluate_all(conditions):
			continue
		result.append(choice.duplicate(true))
	return result


func _array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []
