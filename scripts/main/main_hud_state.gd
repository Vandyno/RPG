class_name MainHudState
extends RefCounted

const LocationTextBuilder = preload("res://scripts/ui/location_text_builder.gd")
const QuestTargetTextBuilder = preload("res://scripts/ui/quest_target_text_builder.gd")
const PrimaryActionTextBuilder = preload("res://scripts/ui/primary_action_text_builder.gd")
const MainContextActions = preload("res://scripts/main/main_context_actions.gd")
const PoiInteraction = preload("res://scripts/main/poi_interaction.gd")
const ObjectInteractionRules = preload("res://scripts/core/object_interaction_rules.gd")
const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")


static func build(main) -> Dictionary:
	var nearby = main._get_nearby_entity()
	var auto_target = main.entities.get_entity(main.auto_interact_target_id)
	var displayed = auto_target if auto_target else nearby
	var shop_id: String = main._shop_id_for_entity(nearby)
	var target_name := "Destination" if main.auto_move_active else _target_name(displayed)
	var target_detail := "Moving" if main.auto_move_active else _target_detail(main, displayed)
	return {
		"player_health": "%d/%d" % [main.player.health, main.player.max_health],
		"player_health_value": main.player.health,
		"player_max_health": main.player.max_health,
		"player_mana": "%d/%d" % [int(roundf(main.player.mana)), int(roundf(main.player.max_mana))],
		"player_mana_value": main.player.mana,
		"player_max_mana": main.player.max_mana,
		"player_sneaking": main.player.is_sneaking,
		"nearby": target_name,
		"primary_action": _primary_action(main, nearby, auto_target),
		"target_detail": target_detail,
		"nearby_targets": main._nearby_targets_data(),
		"context_actions": MainContextActions.secondary(main, nearby),
		"inventory": main._inventory_text(),
		"inventory_items": _inventory_items_data(main),
		"inventory_details": main._inventory_details_text(),
		"inventory_actions": main._inventory_actions_data(),
		"transfer_open": not String(main.active_transfer_owner_id).is_empty(),
		"transfer_target": {
			"owner_id": String(main.active_transfer_owner_id),
			"name": String(main.active_transfer_name)
		},
		"transfer_player_items": _inventory_items_data(main),
		"transfer_target_items": _inventory_items_for_owner(main, String(main.active_transfer_owner_id)),
		"spells": _spells_data(main),
		"spell_slots": _spell_slots_data(main),
		"trade": main._trade_text(shop_id),
		"trade_actions": main._trade_actions_data(shop_id),
		"equipment": main.equipment.get_summary(),
		"equipment_slots": _equipment_slots_data(main),
		"factions": main.factions.get_summary(),
		"progression": main.progression.get_summary(),
		"progression_details": main.progression.get_details(),
		"progression_actions": main._progression_actions_data(),
		"statuses": main.statuses.get_summary(),
		"status_details": main.statuses.get_details(),
		"time": main.time.get_summary(),
		"time_actions": [{"id": "wait:1", "text": "Wait 1h"}, {"id": "wait:8", "text": "Wait 8h"}],
		"time_details": main.time.get_details(),
		"locations": LocationTextBuilder.names(main.world_state.discovered_locations, main.content),
		"location_details":
		LocationTextBuilder.details(main.world_state.discovered_locations, main.content),
		"quest_directions":
		QuestTargetTextBuilder.directions(main.quests, main.entities, main.player.global_position),
		"quest_target_actions": _quest_target_actions(main),
		"quests": main.quests.get_active_summary()
	}


static func _primary_action(_main, nearby, auto_target) -> String:
	if _main.auto_move_active or auto_target:
		return "Stop"
	var preferred := MainContextActions.preferred_primary(_main, nearby)
	if not preferred.is_empty():
		return String(preferred.get("text", "Interact"))
	if nearby and ["container", "door"].has(nearby.get_kind()):
		return ObjectInteractionRules.access_action_text(
			nearby, _main.chunks, _main.condition_evaluator
		)
	if nearby and nearby.get_kind() == "poi":
		return PoiInteraction.primary_action_text(nearby)
	return PrimaryActionTextBuilder.for_kind(nearby.get_kind()) if nearby else "Explore"


static func _target_name(entity) -> String:
	return entity.get_display_name() if entity else "none"


static func _target_detail(main, entity) -> String:
	return main._target_detail_text(entity) if entity else ""


static func _quest_target_actions(main) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var seen: Dictionary = {}
	for objective in main.quests.get_active_objectives_data():
		var target_id := String(objective.get("target_id", ""))
		if target_id.is_empty() or seen.has(target_id):
			continue
		var entity = main.entities.get_entity(target_id)
		if not entity:
			continue
		seen[target_id] = true
		actions.append({"id": "target:%s" % target_id, "text": "Target %s" % entity.get_display_name()})
	return actions


static func _inventory_items_data(main) -> Array[Dictionary]:
	return _inventory_items_for_owner(main, "char_player")


static func _inventory_items_for_owner(main, owner_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if owner_id.is_empty():
		return entries
	for item_id in _sorted_owner_inventory_ids(main, owner_id):
		var item: Dictionary = main.content.get_item(item_id)
		var count: int = main.inventory.get_count_for_owner(owner_id, item_id)
		if item.is_empty() or count <= 0:
			continue
		entries.append({
			"item_id": item_id,
			"name": String(item.get("name", item_id)),
			"count": count,
			"type": String(item.get("type", "")),
			"tags": _array_field(item.get("tags", [])),
			"equipment_slot": String(item.get("equipment_slot", "")),
			"value": maxi(0, int(item.get("value", 0))),
			"weight": maxf(0.0, float(item.get("weight", 0.0))),
			"description": String(item.get("description", ""))
		})
	return entries


static func _sorted_owner_inventory_ids(main, owner_id: String) -> Array:
	var source: Dictionary = main.inventory.get_items_for_owner(owner_id)
	var item_ids: Array = source.keys()
	item_ids.sort()
	return item_ids


static func _equipment_slots_data(main) -> Dictionary:
	var slots := {}
	for slot in EquipmentSlots.SLOTS:
		var item_id: String = main.equipment.get_equipped_item(slot)
		var item: Dictionary = main.content.get_item(item_id)
		slots[slot] = {
			"slot": slot,
			"label": EquipmentSlots.label(slot),
			"item_id": item_id,
			"item_name": String(item.get("name", ""))
		}
	return slots


static func _spells_data(main) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var spell_ids: Array = main.content.spells.keys()
	spell_ids.sort_custom(
		func(a, b) -> bool:
			var spell_a: Dictionary = main.content.get_spell(String(a))
			var spell_b: Dictionary = main.content.get_spell(String(b))
			var school_a := String(spell_a.get("school", ""))
			var school_b := String(spell_b.get("school", ""))
			if school_a == school_b:
				return String(spell_a.get("name", a)) < String(spell_b.get("name", b))
			return school_a < school_b
	)
	for spell_id in spell_ids:
		var spell: Dictionary = main.content.get_spell(String(spell_id))
		if spell.is_empty():
			continue
		entries.append(_spell_data(main, String(spell_id), spell))
	return entries


static func _spell_slots_data(main) -> Dictionary:
	var slots := {}
	for slot in main.spells.SLOTS:
		var spell_id: String = main.spells.get_assigned_spell(slot)
		var spell: Dictionary = main.content.get_spell(spell_id)
		slots[slot] = _spell_data(main, spell_id, spell)
		slots[slot]["slot"] = slot
		slots[slot]["slot_label"] = _spell_slot_label(slot)
	return slots


static func _spell_data(main, spell_id: String, spell: Dictionary) -> Dictionary:
	var assigned := _assigned_spell_slot(main, spell_id)
	return {
		"spell_id": spell_id,
		"name": String(spell.get("name", "")),
		"school": String(spell.get("school", "")),
		"icon": String(spell.get("icon", "")),
		"mana_cost": int(spell.get("mana_cost", 0)),
		"mana_drain_per_second": float(
			spell.get("mana_drain_per_second", spell.get("mana_cost", 0))
		),
		"range": String(spell.get("range", "")),
		"behavior": String(spell.get("behavior", "")),
		"assigned_slot": assigned,
		"assigned_label": _spell_slot_label(assigned)
	}


static func _assigned_spell_slot(main, spell_id: String) -> String:
	if spell_id.is_empty():
		return ""
	for slot in main.spells.SLOTS:
		if main.spells.get_assigned_spell(slot) == spell_id:
			return slot
	return ""


static func _spell_slot_label(slot_id: String) -> String:
	return {"ability_1": "Ability I", "ability_2": "Ability II", "ability_3": "Ability III"}.get(
		slot_id, ""
	)


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
