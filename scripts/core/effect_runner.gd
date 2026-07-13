class_name EffectRunner
extends RefCounted

const VariantFields = preload("res://scripts/core/variant_fields.gd")

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
var equipment
var feedback_suppression_depth := 0


class Dependencies:
	var world_state
	var quests
	var inventory
	var content
	var player
	var factions
	var progression
	var time
	var statuses
	var event_bus
	var equipment

	func _init(values: Dictionary = {}) -> void:
		world_state = values.get("world_state")
		quests = values.get("quests")
		inventory = values.get("inventory")
		content = values.get("content")
		player = values.get("player")
		factions = values.get("factions")
		progression = values.get("progression")
		time = values.get("time")
		statuses = values.get("statuses")
		event_bus = values.get("event_bus")
		equipment = values.get("equipment")


func setup(dependencies: Dependencies) -> void:
	world_state = dependencies.world_state
	quests = dependencies.quests
	inventory = dependencies.inventory
	content = dependencies.content
	player = dependencies.player
	factions = dependencies.factions
	progression = dependencies.progression
	time = dependencies.time
	statuses = dependencies.statuses
	event_bus = dependencies.event_bus
	equipment = dependencies.equipment


func set_equipment(equipment_manager) -> void:
	equipment = equipment_manager


func set_player(player_node) -> void:
	player = player_node


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
		"repair_equipment":
			applied = _apply_repair_equipment(effect)
	if applied and _should_emit_feedback(emit_feedback):
		_post_effect_feedback(effect, before)
	return applied


func describe_effects(effects_value: Variant) -> String:
	var parts: Array[String] = []
	for effect in VariantFields.array(effects_value):
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
	if faction_id.is_empty() or not VariantFields.is_number(amount_value) or not factions:
		return false
	return factions.change_reputation(faction_id, int(amount_value))


func _apply_add_experience(effect: Dictionary) -> bool:
	var amount_value: Variant = effect.get("amount", 0)
	if not VariantFields.is_number(amount_value) or not progression:
		return false
	return progression.add_experience(int(amount_value))


func _apply_advance_time(effect: Dictionary) -> bool:
	if not time:
		return false
	var minutes_value: Variant = effect.get("minutes", 0)
	var hours_value: Variant = effect.get("hours", 0)
	var minutes := VariantFields.int_value(minutes_value, 0)
	var hours := VariantFields.int_value(hours_value, 0)
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


func _apply_repair_equipment(effect: Dictionary) -> bool:
	if not equipment or not inventory or not equipment.has_method("repair_equipped"):
		return false
	var cost := VariantFields.positive_int_field(effect, "cost", 0)
	if cost <= 0 or equipment.damaged_equipped_count() <= 0:
		return false
	if not inventory.has_item("item_gold_coin", cost):
		return false
	if not inventory.remove_item("item_gold_coin", cost):
		return false
	return int(equipment.repair_equipped()) > 0


func _apply_quest_rewards(quest_id: String) -> void:
	if not content:
		return
	var quest: Dictionary = content.get_quest(quest_id)
	feedback_suppression_depth += 1
	for reward in VariantFields.array(quest.get("rewards", [])):
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
		"repair_equipment":
			text = "Equipped gear repaired."
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
	var before_items := VariantFields.dictionary(before.get("items", {}))
	var previous := VariantFields.int_value(before_items.get(item_id, 0), 0)
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
	if not VariantFields.is_number(amount_value):
		return ""
	var amount := int(amount_value)
	if amount <= 0:
		return ""
	var previous_level := VariantFields.int_value(before.get("level", 0), 0)
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
			if VariantFields.is_number(amount_value) and int(amount_value) > 0:
				return "XP +%d" % int(amount_value)
	return ""


func _reputation_effect_description(effect: Dictionary) -> String:
	var faction_id := String(effect.get("faction_id", ""))
	var amount_value: Variant = effect.get("amount", 0)
	if faction_id.is_empty() or not VariantFields.is_number(amount_value):
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


func _positive_count(source: Dictionary, field_id: String = "count") -> int:
	if not source.has(field_id):
		return 1 if field_id == "count" else 0
	var value: Variant = source.get(field_id, 1)
	if not VariantFields.is_number(value):
		return 0
	return int(value)
