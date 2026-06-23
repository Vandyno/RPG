class_name MainHudState
extends RefCounted

const LocationTextBuilder = preload("res://scripts/ui/location_text_builder.gd")
const QuestTargetTextBuilder = preload("res://scripts/ui/quest_target_text_builder.gd")
const PrimaryActionTextBuilder = preload("res://scripts/ui/primary_action_text_builder.gd")
const MainContextActions = preload("res://scripts/main/main_context_actions.gd")
const PoiInteraction = preload("res://scripts/main/poi_interaction.gd")
const ObjectInteractionRules = preload("res://scripts/core/object_interaction_rules.gd")


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
		"nearby": target_name,
		"primary_action": _primary_action(main, nearby, auto_target),
		"target_detail": target_detail,
		"nearby_targets": main._nearby_targets_data(),
		"combat_actions": main._combat_actions_data(nearby),
		"context_actions": MainContextActions.secondary(main, nearby),
		"inventory": main._inventory_text(),
		"inventory_items": _inventory_items_data(main),
		"inventory_details": main._inventory_details_text(),
		"inventory_actions": main._inventory_actions_data(),
		"trade": main._trade_text(shop_id),
		"trade_actions": main._trade_actions_data(shop_id),
		"equipment": main.equipment.get_summary(),
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
	var entries: Array[Dictionary] = []
	for item_id in main._sorted_inventory_ids():
		var item: Dictionary = main.content.get_item(item_id)
		var count: int = main.inventory.get_count(item_id)
		if item.is_empty() or count <= 0:
			continue
		entries.append({
			"item_id": item_id,
			"name": String(item.get("name", item_id)),
			"count": count,
			"type": String(item.get("type", "")),
			"tags": _array_field(item.get("tags", [])),
			"equipment_slot": String(item.get("equipment_slot", "")),
			"description": String(item.get("description", ""))
		})
	return entries


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
