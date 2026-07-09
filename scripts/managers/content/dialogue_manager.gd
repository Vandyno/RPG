class_name DialogueManager
extends Node

var content: ContentDatabase
var condition_evaluator: ConditionEvaluator
var effect_runner: EffectRunner


func setup(
	content_database: ContentDatabase, conditions: ConditionEvaluator, effects: EffectRunner
) -> void:
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
		var effects_failed := false
		if apply_line_effects:
			effects_failed = _apply_effects(_array_field(line.get("effects", [])))
		return {
			"speaker": String(line.get("speaker", fallback_speaker)),
			"text": String(line.get("text", "")),
			"line_id": String(line.get("id", "")),
			"effects": _array_field(line.get("effects", [])).duplicate(true),
			"effects_failed": effects_failed,
			"choices": _available_choices(line)
		}
	return {}


func apply_choice(choice: Dictionary) -> Dictionary:
	if choice.is_empty():
		return {}
	var effects_failed := _apply_effects(_array_field(choice.get("effects", [])))
	return {
		"choice_id": String(choice.get("id", "")),
		"text": String(choice.get("text", "")),
		"response": String(choice.get("response", "")),
		"open_shop_id": String(choice.get("open_shop_id", "")),
		"effects_failed": effects_failed
	}


func _apply_effects(effects: Array) -> bool:
	var failed := false
	for effect in effects:
		if effect is Dictionary:
			failed = not effect_runner or not effect_runner.apply(effect) or failed
	return failed


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
