class_name EffectRunner
extends RefCounted

var world_state
var quests
var inventory
var factions
var progression
var content
var player
var time
var statuses
var event_bus
var feedback_suppression_depth := 0


func setup(
	world_state_manager,
	quest_manager,
	inventory_manager,
	content_database = null,
	player_controller = null,
	faction_manager = null,
	progression_manager = null,
	time_manager = null,
	status_effect_manager = null,
	feedback_event_bus = null
) -> void:
	world_state = world_state_manager
	quests = quest_manager
	inventory = inventory_manager
	content = content_database
	player = player_controller
	factions = faction_manager
	progression = progression_manager
	time = time_manager
	statuses = status_effect_manager
	event_bus = feedback_event_bus


func apply(effect: Dictionary, emit_feedback: bool = true) -> bool:
	var effect_type := String(effect.get("type", ""))
	var before := _feedback_snapshot() if _should_emit_feedback(emit_feedback) else {}
	var applied := false
	match effect_type:
		"set_flag":
			applied = _apply_set_flag(effect)
		"start_quest":
			applied = _apply_start_quest(effect)
		"set_quest_stage":
			applied = _apply_set_quest_stage(effect)
		"complete_quest":
			applied = _apply_complete_quest(effect)
		"fail_quest":
			applied = _apply_fail_quest(effect)
		"add_item":
			applied = _apply_add_item(effect)
		"remove_item":
			applied = _apply_remove_item(effect)
		"discover_location":
			applied = _apply_discover_location(effect)
		"heal_player":
			applied = _apply_heal_player(effect)
		"change_reputation":
			applied = _apply_change_reputation(effect)
		"add_experience":
			applied = _apply_add_experience(effect)
		"advance_time":
			applied = _apply_advance_time(effect)
		"apply_status":
			applied = _apply_status(effect)
	if applied and _should_emit_feedback(emit_feedback):
		_post_effect_feedback(effect, before)
	return applied


func describe_effects(effects_value: Variant) -> String:
	var parts: Array[String] = []
	for effect in _array_field(effects_value):
		if effect is Dictionary:
			var text := _effect_description(effect)
			if not text.is_empty():
				parts.append(text)
	return ", ".join(parts)


func _apply_set_flag(effect: Dictionary) -> bool:
	var flag_id := String(effect.get("flag_id", ""))
	if flag_id.is_empty() or not world_state:
		return false
	if effect.has("value") and not effect["value"] is bool:
		return false
	world_state.set_flag(flag_id, bool(effect.get("value", true)))
	return true


func _apply_start_quest(effect: Dictionary) -> bool:
	var quest_id := String(effect.get("quest_id", ""))
	if quest_id.is_empty() or not quests:
		return false
	return quests.start_quest(quest_id)


func _apply_set_quest_stage(effect: Dictionary) -> bool:
	var quest_id := String(effect.get("quest_id", ""))
	var stage := String(effect.get("stage", ""))
	if quest_id.is_empty() or stage.is_empty() or not quests:
		return false
	return quests.set_stage(quest_id, stage)


func _apply_complete_quest(effect: Dictionary) -> bool:
	var quest_id := String(effect.get("quest_id", ""))
	if quest_id.is_empty() or not quests:
		return false
	var completed: bool = quests.complete_quest(quest_id)
	if completed:
		_apply_quest_rewards(quest_id)
	return completed


func _apply_fail_quest(effect: Dictionary) -> bool:
	var quest_id := String(effect.get("quest_id", ""))
	if quest_id.is_empty() or not quests:
		return false
	return quests.fail_quest(quest_id)


func _apply_add_item(effect: Dictionary) -> bool:
	var item_id := String(effect.get("item_id", ""))
	var count := _positive_count(effect)
	if item_id.is_empty() or count <= 0 or not inventory:
		return false
	return inventory.add_item(item_id, count)


func _apply_remove_item(effect: Dictionary) -> bool:
	var item_id := String(effect.get("item_id", ""))
	var count := _positive_count(effect)
	if item_id.is_empty() or count <= 0 or not inventory:
		return false
	return inventory.remove_item(item_id, count)


func _apply_discover_location(effect: Dictionary) -> bool:
	var location_id := String(effect.get("location_id", ""))
	if location_id.is_empty() or not world_state:
		return false
	return world_state.discover_location(location_id)


func _apply_heal_player(effect: Dictionary) -> bool:
	var amount := _positive_count(effect, "amount")
	if amount <= 0 or not player:
		return false
	var before: int = player.health
	player.heal(amount)
	return player.health > before


func _apply_change_reputation(effect: Dictionary) -> bool:
	var faction_id := String(effect.get("faction_id", ""))
	var amount_value: Variant = effect.get("amount", 0)
	if faction_id.is_empty() or not _is_number(amount_value) or not factions:
		return false
	return factions.change_reputation(faction_id, int(amount_value))


func _apply_add_experience(effect: Dictionary) -> bool:
	var amount_value: Variant = effect.get("amount", 0)
	if not _is_number(amount_value) or not progression:
		return false
	return progression.add_experience(int(amount_value))


func _apply_advance_time(effect: Dictionary) -> bool:
	if not time:
		return false
	var minutes_value: Variant = effect.get("minutes", 0)
	var hours_value: Variant = effect.get("hours", 0)
	var minutes := int(minutes_value) if _is_number(minutes_value) else 0
	var hours := int(hours_value) if _is_number(hours_value) else 0
	if minutes <= 0 and hours <= 0:
		return false
	return time.advance_minutes(minutes + hours * 60)


func _apply_status(effect: Dictionary) -> bool:
	var status_id := String(effect.get("status_id", ""))
	if status_id.is_empty() or not statuses:
		return false
	var charges := 0
	if effect.has("charges"):
		charges = _positive_count(effect, "charges")
		if charges <= 0:
			return false
	return statuses.apply_status(status_id, charges)


func _apply_quest_rewards(quest_id: String) -> void:
	if not content:
		return
	var quest: Dictionary = content.get_quest(quest_id)
	feedback_suppression_depth += 1
	for reward in _array_field(quest.get("rewards", [])):
		if reward is Dictionary:
			apply(reward)
	feedback_suppression_depth = maxi(0, feedback_suppression_depth - 1)


func _should_emit_feedback(emit_feedback: bool) -> bool:
	return emit_feedback and event_bus and feedback_suppression_depth <= 0


func _feedback_snapshot() -> Dictionary:
	return {
		"items": inventory.items.duplicate(true) if inventory else {},
		"level": progression.level if progression else 0,
		"experience": progression.experience if progression else 0,
		"skill_points": progression.skill_points if progression else 0
	}


func _post_effect_feedback(effect: Dictionary, before: Dictionary) -> void:
	var text := _feedback_text(effect, before)
	if not text.is_empty():
		event_bus.post_message(text)


func _feedback_text(effect: Dictionary, before: Dictionary) -> String:
	var text := ""
	match String(effect.get("type", "")):
		"start_quest":
			text = "Quest started: %s." % _quest_title(String(effect.get("quest_id", "")))
		"set_quest_stage":
			text = "Quest updated: %s." % _quest_title(String(effect.get("quest_id", "")))
		"complete_quest":
			text = _complete_quest_feedback(String(effect.get("quest_id", "")))
		"add_item", "remove_item":
			text = _item_delta_feedback(effect, before)
		"change_reputation":
			text = _effect_description(effect)
		"add_experience":
			text = _experience_feedback(effect, before)
	return text


func _complete_quest_feedback(quest_id: String) -> String:
	var title := _quest_title(quest_id)
	var quest: Dictionary = content.get_quest(quest_id) if content else {}
	var rewards := describe_effects(quest.get("rewards", []))
	if rewards.is_empty():
		return "Quest complete: %s." % title
	return "Quest complete: %s. Rewards: %s." % [title, rewards]


func _item_delta_feedback(effect: Dictionary, before: Dictionary) -> String:
	if not inventory:
		return ""
	var item_id := String(effect.get("item_id", ""))
	if item_id.is_empty():
		return ""
	var before_items := _dictionary_field(before.get("items", {}))
	var previous := _int_value(before_items.get(item_id, 0), 0)
	var current: int = inventory.get_count(item_id)
	var delta: int = current - previous
	if delta == 0:
		return ""
	var name := _item_name(item_id)
	if delta > 0:
		return "Gained %s x%d." % [name, delta]
	return "Spent %s x%d." % [name, absi(delta)]


func _experience_feedback(effect: Dictionary, before: Dictionary) -> String:
	var amount_value: Variant = effect.get("amount", 0)
	if not _is_number(amount_value):
		return ""
	var amount := int(amount_value)
	if amount <= 0:
		return ""
	var previous_level := _int_value(before.get("level", 0), 0)
	if progression and progression.level > previous_level:
		return "XP +%d. Level %d reached." % [amount, progression.level]
	return "XP +%d." % amount


func _effect_description(effect: Dictionary) -> String:
	match String(effect.get("type", "")):
		"add_item":
			return (
				"%s x%d" % [_item_name(String(effect.get("item_id", ""))), _positive_count(effect)]
			)
		"remove_item":
			return (
				"-%s x%d" % [_item_name(String(effect.get("item_id", ""))), _positive_count(effect)]
			)
		"change_reputation":
			return _reputation_effect_description(effect)
		"add_experience":
			var amount_value: Variant = effect.get("amount", 0)
			if _is_number(amount_value) and int(amount_value) > 0:
				return "XP +%d" % int(amount_value)
	return ""


func _reputation_effect_description(effect: Dictionary) -> String:
	var faction_id := String(effect.get("faction_id", ""))
	var amount_value: Variant = effect.get("amount", 0)
	if faction_id.is_empty() or not _is_number(amount_value):
		return ""
	return "%s %+d" % [_faction_name(faction_id), int(amount_value)]


func _quest_title(quest_id: String) -> String:
	var quest: Dictionary = content.get_quest(quest_id) if content else {}
	return String(quest.get("title", quest_id))


func _item_name(item_id: String) -> String:
	var item: Dictionary = content.get_item(item_id) if content else {}
	return String(item.get("name", item_id))


func _faction_name(faction_id: String) -> String:
	var faction: Dictionary = content.get_faction(faction_id) if content else {}
	return String(faction.get("name", faction_id))


func _array_field(value: Variant) -> Array:
	if value is Array:
		return value
	return []


func _dictionary_field(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value
	return {}


func _int_value(value: Variant, fallback: int) -> int:
	if not _is_number(value):
		return fallback
	return int(value)


func _positive_count(source: Dictionary, field_id: String = "count") -> int:
	if not source.has(field_id):
		return 1 if field_id == "count" else 0
	var value: Variant = source.get(field_id, 1)
	if not _is_number(value):
		return 0
	return int(value)


func _is_number(value: Variant) -> bool:
	return value is int or value is float
