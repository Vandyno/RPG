class_name ContentQuestValidator
extends RefCounted

const Schema = preload("res://scripts/data/content_schema_validator.gd")


static func validate(content, errors: Array[String]) -> void:
	_validate_quests(content, errors)
	_validate_factions(content, errors)
	_validate_dialogues(content, errors)
	_validate_npcs(content, errors)


static func _validate_quests(content, errors: Array[String]) -> void:
	for quest_id in content.quests:
		var quest: Dictionary = content.quests[quest_id]
		Schema.validate_keyed_id(quest, String(quest_id), "Quest", errors)
		if String(quest.get("title", "")).is_empty():
			errors.append("Quest %s is missing title." % quest_id)
		var start_stage := String(quest.get("start_stage", ""))
		var stages_value: Variant = quest.get("stages", {})
		var stages: Dictionary = Schema.dictionary_field(stages_value)
		if not stages_value is Dictionary or stages.is_empty():
			errors.append("Quest %s must have at least one stage." % quest_id)
		if start_stage.is_empty():
			errors.append("Quest %s is missing start_stage." % quest_id)
		elif not stages.has(start_stage):
			errors.append("Quest %s references missing start_stage %s." % [quest_id, start_stage])
		_validate_quest_stages(content, String(quest_id), stages, errors)
		Schema.validate_effect_list(content, quest, "rewards", "quest %s" % quest_id, errors)


static func _validate_quest_stages(
	content, quest_id: String, stages: Dictionary, errors: Array[String]
) -> void:
	for stage_id in stages:
		var stage_key := String(stage_id)
		var stage_owner := "Quest %s stage %s" % [quest_id, stage_key]
		if stage_key.is_empty():
			errors.append("Quest %s has stage with missing id." % quest_id)
		var stage_value: Variant = stages[stage_id]
		if not stage_value is Dictionary:
			errors.append("%s must be a dictionary." % stage_owner)
			continue
		_validate_quest_objectives(content, stage_value, stage_owner, errors)


static func _validate_quest_objectives(
	content, stage: Dictionary, stage_owner: String, errors: Array[String]
) -> void:
	var objectives_value: Variant = stage.get("objectives", {})
	var objectives: Dictionary = Schema.dictionary_field(objectives_value)
	if not objectives_value is Dictionary or objectives.is_empty():
		errors.append("%s must have at least one objective." % stage_owner)
		return
	for objective_id in objectives:
		var objective_key := String(objective_id)
		if objective_key.is_empty():
			errors.append("%s has objective with missing id." % stage_owner)
		var objective_value: Variant = objectives[objective_id]
		var objective_text: String = Schema.objective_text(objective_value)
		if objective_text.is_empty():
			errors.append("%s objective %s is missing text." % [stage_owner, objective_key])
		var target_id: String = Schema.objective_target_id(objective_value)
		if not target_id.is_empty() and not Schema.world_object_id_exists(content, target_id):
			errors.append(
				"%s objective %s references missing target %s."
				% [stage_owner, objective_key, target_id]
			)


static func _validate_factions(content, errors: Array[String]) -> void:
	for faction_id in content.factions:
		var faction: Dictionary = content.factions[faction_id]
		Schema.validate_keyed_id(faction, String(faction_id), "Faction", errors)
		if String(faction.get("name", "")).is_empty():
			errors.append("Faction %s is missing name." % faction_id)
		if String(faction.get("description", "")).is_empty():
			errors.append("Faction %s is missing description." % faction_id)
		Schema.validate_optional_bounded_number(
			faction, "starting_reputation", "Faction %s" % faction_id, -100.0, 100.0, errors
		)


static func _validate_dialogues(content, errors: Array[String]) -> void:
	for dialogue_id in content.dialogues:
		var dialogue: Dictionary = content.dialogues[dialogue_id]
		Schema.validate_keyed_id(dialogue, String(dialogue_id), "Dialogue", errors)
		var lines: Array = Schema.array_field(dialogue.get("lines", []))
		if lines.is_empty():
			errors.append("Dialogue %s must have at least one line." % dialogue_id)
		var seen_line_ids: Dictionary = {}
		for line in lines:
			if not line is Dictionary:
				errors.append("Dialogue %s has malformed line." % dialogue_id)
				continue
			var line_id := String(line.get("id", ""))
			var owner := "Dialogue %s line %s" % [dialogue_id, line_id]
			if line_id.is_empty():
				errors.append("Dialogue %s has line with missing id." % dialogue_id)
			elif seen_line_ids.has(line_id):
				errors.append("Dialogue %s has duplicate line id %s." % [dialogue_id, line_id])
			seen_line_ids[line_id] = true
			if String(line.get("speaker", "")).is_empty():
				errors.append("%s is missing speaker." % owner)
			if String(line.get("text", "")).is_empty():
				errors.append("%s is missing text." % owner)
			Schema.validate_condition_list(content, line, "conditions", owner, errors)
			Schema.validate_effect_list(content, line, "effects", owner, errors)
			_validate_dialogue_choices(content, line, owner, errors)


static func _validate_dialogue_choices(
	content, line: Dictionary, owner: String, errors: Array[String]
) -> void:
	if not line.has("choices"):
		return
	var choices_value: Variant = line.get("choices", [])
	if not choices_value is Array:
		errors.append("%s choices must be an array." % owner)
		return
	var seen_choice_ids: Dictionary = {}
	for choice in choices_value:
		if not choice is Dictionary:
			errors.append("%s choices has malformed choice." % owner)
			continue
		var choice_id := String(choice.get("id", ""))
		var choice_owner := "%s choice %s" % [owner, choice_id]
		if choice_id.is_empty():
			errors.append("%s has choice with missing id." % owner)
		elif seen_choice_ids.has(choice_id):
			errors.append("%s has duplicate choice id %s." % [owner, choice_id])
		seen_choice_ids[choice_id] = true
		if String(choice.get("text", "")).is_empty():
			errors.append("%s is missing text." % choice_owner)
		Schema.validate_condition_list(content, choice, "conditions", choice_owner, errors)
		Schema.validate_effect_list(content, choice, "effects", choice_owner, errors)


static func _validate_npcs(content, errors: Array[String]) -> void:
	for npc_id in content.npcs:
		var npc: Dictionary = content.npcs[npc_id]
		Schema.validate_keyed_id(npc, String(npc_id), "NPC", errors)
		if String(npc.get("name", "")).is_empty():
			errors.append("NPC %s is missing name." % npc_id)
		var quest_id := String(npc.get("quest_id", ""))
		if not quest_id.is_empty() and not content.quests.has(quest_id):
			errors.append("NPC %s references missing quest %s." % [npc_id, quest_id])
		var faction_id := String(npc.get("faction", ""))
		if not faction_id.is_empty() and not content.factions.has(faction_id):
			errors.append("NPC %s references missing faction %s." % [npc_id, faction_id])
		var dialogue_id := String(npc.get("dialogue_id", ""))
		if not content.dialogues.has(dialogue_id):
			errors.append("NPC %s references missing dialogue %s." % [npc_id, dialogue_id])
		var shop_id := String(npc.get("shop_id", ""))
		if not shop_id.is_empty() and not content.shops.has(shop_id):
			errors.append("NPC %s references missing shop %s." % [npc_id, shop_id])
		var profile_id := String(npc.get("character_profile_id", ""))
		if profile_id.is_empty():
			errors.append("NPC %s is missing character_profile_id." % npc_id)
		elif not content.character_profiles.has(profile_id):
			errors.append("NPC %s references missing character profile %s." % [npc_id, profile_id])
		Schema.validate_condition_list(content, npc, "completion_conditions", "NPC %s" % npc_id, errors)
		Schema.validate_effect_list(content, npc, "completion_effects", "NPC %s" % npc_id, errors)
