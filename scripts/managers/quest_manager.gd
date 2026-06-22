class_name QuestManager
extends Node

var event_bus
var content
var quests: Dictionary = {}


func setup(bus, content_database) -> void:
	event_bus = bus
	content = content_database


func start_quest(quest_id: String) -> bool:
	if quest_id.is_empty():
		return false
	var definition: Dictionary = content.get_quest(quest_id)
	if definition.is_empty():
		return false
	var existing_state := _state_name(_quest_state_data(quest_id))
	if quests.has(quest_id) and existing_state != "inactive":
		return false
	var first_stage := String(definition.get("start_stage", "started"))
	quests[quest_id] = {
		"state": "active",
		"stage": first_stage,
		"objectives": _stage_objectives(definition, first_stage)
	}
	_emit_quest_changed(quest_id)
	return true


func set_stage(quest_id: String, stage_id: String) -> bool:
	var definition: Dictionary = content.get_quest(quest_id) if not quest_id.is_empty() else {}
	var stages := _dictionary_field(definition.get("stages", {}))
	var can_set := (
		not quest_id.is_empty()
		and not stage_id.is_empty()
		and not definition.is_empty()
		and stages.has(stage_id)
	)
	if can_set and not quests.has(quest_id):
		can_set = start_quest(quest_id)
	if not can_set or not quests.has(quest_id):
		return false
	var current_state := _state_name(_quest_state_data(quest_id))
	if ["completed", "failed"].has(current_state):
		return false
	if _quest_state_data(quest_id).is_empty():
		quests[quest_id] = {}
	quests[quest_id]["state"] = "active"
	quests[quest_id]["stage"] = stage_id
	quests[quest_id]["objectives"] = _stage_objectives(definition, stage_id)
	_emit_quest_changed(quest_id)
	return true


func complete_quest(quest_id: String) -> bool:
	var current_state := _state_name(_quest_state_data(quest_id))
	if quests.has(quest_id) and current_state == "completed":
		return false
	if quests.has(quest_id) and current_state == "failed":
		return false
	if not quests.has(quest_id) or _quest_state_data(quest_id).is_empty():
		start_quest(quest_id)
	if not quests.has(quest_id):
		return false
	quests[quest_id]["state"] = "completed"
	quests[quest_id]["stage"] = "completed"
	quests[quest_id]["objectives"] = {}
	_emit_quest_changed(quest_id)
	return true


func fail_quest(quest_id: String) -> bool:
	if (
		quests.has(quest_id)
		and ["completed", "failed"].has(_state_name(_quest_state_data(quest_id)))
	):
		return false
	var definition: Dictionary = content.get_quest(quest_id)
	if definition.is_empty():
		return false
	quests[quest_id] = {"state": "failed", "stage": "failed", "objectives": {}}
	_emit_quest_changed(quest_id)
	return true


func get_quest_state(quest_id: String) -> String:
	if not quests.has(quest_id):
		return "inactive"
	return _state_name(_quest_state_data(quest_id))


func get_active_summary() -> Array[String]:
	var lines: Array[String] = []
	for quest_id in quests:
		var key := String(quest_id)
		if key.is_empty():
			continue
		var state := _quest_state_data(key)
		var state_name := _state_name(state)
		var definition: Dictionary = content.get_quest(key)
		if definition.is_empty():
			continue
		if state_name == "active":
			var title := String(definition.get("title", key))
			var objectives := _dictionary_field(state.get("objectives", {}))
			if objectives.is_empty():
				var stage_id := _valid_or_start_stage(definition, String(state.get("stage", "")))
				objectives = _stage_objectives(definition, stage_id)
			for objective_id in objectives:
				var objective_text := _objective_text(objectives[objective_id])
				if not objective_text.is_empty():
					lines.append("%s: %s" % [title, objective_text])
		elif state_name == "completed":
			lines.append("%s: complete" % String(definition.get("title", key)))
		elif state_name == "failed":
			lines.append("%s: failed" % String(definition.get("title", key)))
	return lines


func get_active_objectives_data() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest_id in quests:
		var key := String(quest_id)
		var state := _quest_state_data(key)
		var definition: Dictionary = content.get_quest(key) if content else {}
		if key.is_empty() or definition.is_empty() or _state_name(state) != "active":
			continue
		var stage_id := _valid_or_start_stage(definition, String(state.get("stage", "")))
		var objectives := _dictionary_field(state.get("objectives", {}))
		if objectives.is_empty():
			objectives = _stage_objectives(definition, stage_id)
		for objective_id in objectives:
			var objective_value: Variant = objectives[objective_id]
			var text := _objective_text(objective_value)
			if text.is_empty():
				continue
			result.append(
				{
					"quest_id": key,
					"title": String(definition.get("title", key)),
					"stage": stage_id,
					"objective_id": String(objective_id),
					"text": text,
					"target_id": _objective_target_id(objective_value)
				}
			)
	return result


func get_save_data() -> Dictionary:
	var result: Dictionary = {}
	for quest_id in quests:
		var key := String(quest_id)
		if key.is_empty():
			continue
		var definition: Dictionary = content.get_quest(key)
		if definition.is_empty():
			continue
		var state := _quest_state_data(key)
		match _state_name(state):
			"active":
				var stage_id := _valid_or_start_stage(definition, String(state.get("stage", "")))
				if stage_id.is_empty():
					continue
				result[key] = {
					"state": "active",
					"stage": stage_id,
					"objectives": _stage_objectives(definition, stage_id)
				}
			"completed":
				result[key] = {"state": "completed", "stage": "completed", "objectives": {}}
			"failed":
				result[key] = {"state": "failed", "stage": "failed", "objectives": {}}
	return result


func load_save_data(data: Dictionary) -> void:
	quests.clear()
	for quest_id in data:
		var key := String(quest_id)
		if key.is_empty():
			continue
		var definition: Dictionary = content.get_quest(key)
		if definition.is_empty() or not data[quest_id] is Dictionary:
			continue
		var loaded_state: Dictionary = data[quest_id]
		var state := String(loaded_state.get("state", "inactive"))
		match state:
			"active":
				var stage_id := _valid_or_start_stage(
					definition, String(loaded_state.get("stage", ""))
				)
				if stage_id.is_empty():
					continue
				quests[key] = {
					"state": "active",
					"stage": stage_id,
					"objectives": _stage_objectives(definition, stage_id)
				}
			"completed":
				quests[key] = {"state": "completed", "stage": "completed", "objectives": {}}
			"failed":
				quests[key] = {"state": "failed", "stage": "failed", "objectives": {}}


func _stage_objectives(definition: Dictionary, stage_id: String) -> Dictionary:
	var stages := _dictionary_field(definition.get("stages", {}))
	var stage := _dictionary_field(stages.get(stage_id, {}))
	var objectives := _dictionary_field(stage.get("objectives", {}))
	var result: Dictionary = {}
	for objective_id in objectives:
		var key := String(objective_id)
		var objective_value: Variant = objectives[objective_id]
		var text := _objective_text(objective_value)
		if not key.is_empty() and not text.is_empty():
			var target_id := _objective_target_id(objective_value)
			result[key] = (
				{"text": text, "target_id": target_id} if not target_id.is_empty() else text
			)
	return result


func _valid_or_start_stage(definition: Dictionary, stage_id: String) -> String:
	var stages := _dictionary_field(definition.get("stages", {}))
	if stages.has(stage_id):
		return stage_id
	var start_stage := String(definition.get("start_stage", ""))
	if stages.has(start_stage):
		return start_stage
	return ""


func _quest_state_data(quest_id: String) -> Dictionary:
	return _dictionary_field(quests.get(quest_id, {}))


func _state_name(state: Dictionary) -> String:
	var state_name := String(state.get("state", "inactive"))
	if ["active", "completed", "failed"].has(state_name):
		return state_name
	return "inactive"


func _objective_text(value: Variant) -> String:
	if value is Dictionary:
		return String(value.get("text", ""))
	return String(value)


func _objective_target_id(value: Variant) -> String:
	if value is Dictionary:
		return String(value.get("target_id", ""))
	return ""


func _emit_quest_changed(quest_id: String) -> void:
	if event_bus:
		event_bus.quest_changed.emit(quest_id, quests[quest_id].duplicate(true))


func _dictionary_field(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}
