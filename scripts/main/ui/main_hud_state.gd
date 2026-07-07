class_name MainHudState
extends RefCounted

const LocationTextBuilder = preload("res://scripts/ui/text/location_text_builder.gd")
const QuestTargetTextBuilder = preload("res://scripts/ui/text/quest_target_text_builder.gd")
const PrimaryActionTextBuilder = preload("res://scripts/ui/text/primary_action_text_builder.gd")
const MainContextActions = preload("res://scripts/main/actions/main_context_actions.gd")
const PoiInteraction = preload("res://scripts/main/actions/poi_interaction.gd")
const ObjectInteractionRules = preload("res://scripts/core/object_interaction_rules.gd")
const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")


class HudContext:
	var active_transfer_name: String
	var active_transfer_owner_id: String
	var auto_interact_target_id: String
	var auto_move_active: bool
	var chunks
	var condition_evaluator
	var content
	var context_actions_context
	var entities
	var equipment
	var factions
	var inventory
	var player
	var progression
	var quests
	var spells
	var statuses
	var time
	var world_state
	var get_nearby_entity: Callable
	var inventory_actions_data: Callable
	var inventory_details_text: Callable
	var inventory_text: Callable
	var nearby_targets_data: Callable
	var progression_actions_data: Callable
	var shop_id_for_entity: Callable
	var target_detail_text: Callable
	var trade_actions_data: Callable
	var trade_text: Callable

	func _init(main) -> void:
		active_transfer_name = String(main.active_transfer_name)
		active_transfer_owner_id = String(main.active_transfer_owner_id)
		auto_interact_target_id = String(main.auto_interact_target_id)
		auto_move_active = bool(main.auto_move_active)
		chunks = main.chunks
		condition_evaluator = main.condition_evaluator
		content = main.content
		context_actions_context = MainContextActions.context(main)
		entities = main.entities
		equipment = main.equipment
		factions = main.factions
		inventory = main.inventory
		player = main.player
		progression = main.progression
		quests = main.quests
		spells = main.spells
		statuses = main.statuses
		time = main.time
		world_state = main.world_state
		get_nearby_entity = Callable(main, "_get_nearby_entity")
		inventory_actions_data = Callable(main, "_inventory_actions_data")
		inventory_details_text = Callable(main, "_inventory_details_text")
		inventory_text = Callable(main, "_inventory_text")
		nearby_targets_data = Callable(main, "_nearby_targets_data")
		progression_actions_data = Callable(main, "_progression_actions_data")
		shop_id_for_entity = Callable(main, "_shop_id_for_entity")
		target_detail_text = Callable(main, "_target_detail_text")
		trade_actions_data = Callable(main, "_trade_actions_data")
		trade_text = Callable(main, "_trade_text")


static func context(main) -> HudContext:
	return HudContext.new(main)


static func build(ctx: HudContext) -> Dictionary:
	var nearby = ctx.get_nearby_entity.call()
	var auto_target = ctx.entities.get_entity(ctx.auto_interact_target_id)
	var displayed = auto_target if auto_target else nearby
	var shop_id: String = String(ctx.shop_id_for_entity.call(nearby))
	var target_name := "Destination" if ctx.auto_move_active else _target_name(displayed)
	var target_detail := "Moving" if ctx.auto_move_active else _target_detail(ctx, displayed)
	var inventory_summary := String(ctx.inventory_text.call())
	var inventory_items := _inventory_items_data(ctx)
	var inventory_details := String(ctx.inventory_details_text.call())
	var inventory_actions = ctx.inventory_actions_data.call()
	var transfer_open := not ctx.active_transfer_owner_id.is_empty()
	var transfer_target := {
		"owner_id": ctx.active_transfer_owner_id,
		"name": ctx.active_transfer_name
	}
	var transfer_target_items := _inventory_items_for_owner(ctx, ctx.active_transfer_owner_id)
	var trade_summary := String(ctx.trade_text.call(shop_id))
	var trade_actions: Array = ctx.trade_actions_data.call(shop_id)
	var progression_summary := String(ctx.progression.get_summary())
	var progression_details := String(ctx.progression.get_details())
	var progression_actions: Array = ctx.progression_actions_data.call()
	var status_summary := String(ctx.statuses.get_summary())
	var status_details := String(ctx.statuses.get_details())
	var time_summary := String(ctx.time.get_summary())
	var time_actions := [{"id": "wait:1", "text": "Wait 1h"}, {"id": "wait:8", "text": "Wait 8h"}]
	var location_names := LocationTextBuilder.names(ctx.world_state.discovered_locations, ctx.content)
	var location_details := LocationTextBuilder.details(
		ctx.world_state.discovered_locations, ctx.content
	)
	var quest_directions := QuestTargetTextBuilder.directions(
		ctx.quests, ctx.entities, ctx.player.global_position
	)
	var quest_target_actions := _quest_target_actions(ctx)
	var active_quests: Array = ctx.quests.get_active_summary()
	var player_health := "%d/%d" % [ctx.player.health, ctx.player.max_health]
	var player_mana := "%d/%d" % [
		int(roundf(ctx.player.mana)), int(roundf(ctx.player.max_mana))
	]
	var equipment_summary := String(ctx.equipment.get_summary())
	var faction_summary := String(ctx.factions.get_summary())
	return {
		"player_health": player_health,
		"player_health_value": ctx.player.health,
		"player_max_health": ctx.player.max_health,
		"player_mana": player_mana,
		"player_mana_value": ctx.player.mana,
		"player_max_mana": ctx.player.max_mana,
		"player_sneaking": ctx.player.is_sneaking,
		"nearby": target_name,
		"primary_action": _primary_action(ctx, nearby, auto_target),
		"target_detail": target_detail,
		"nearby_targets": ctx.nearby_targets_data.call(),
		"context_actions": MainContextActions.secondary(ctx.context_actions_context, nearby),
		"inventory": inventory_summary,
		"inventory_items": inventory_items,
		"inventory_details": inventory_details,
		"inventory_actions": inventory_actions,
		"transfer_open": transfer_open,
		"transfer_target": transfer_target,
		"transfer_player_items": inventory_items,
		"transfer_target_items": transfer_target_items,
		"spells": _spells_data(ctx),
		"spell_slots": _spell_slots_data(ctx),
		"trade": trade_summary,
		"trade_actions": trade_actions,
		"equipment": equipment_summary,
		"equipment_slots": _equipment_slots_data(ctx),
		"factions": faction_summary,
		"progression": progression_summary,
		"progression_details": progression_details,
		"progression_actions": progression_actions,
		"statuses": status_summary,
		"status_details": status_details,
		"time": time_summary,
		"time_actions": time_actions,
		"time_details": ctx.time.get_details(),
		"locations": location_names,
		"location_details": location_details,
		"quest_directions": quest_directions,
		"quest_target_actions": quest_target_actions,
		"quests": active_quests,
		"system_tabs": _system_tabs({
			"inventory_summary": inventory_summary,
			"inventory_items": inventory_items,
			"inventory_details": inventory_details,
			"inventory_actions": inventory_actions,
			"transfer_open": transfer_open,
			"transfer_target": transfer_target,
			"transfer_target_items": transfer_target_items,
			"player_health": player_health,
			"player_mana": player_mana,
			"progression": progression_summary,
			"progression_details": progression_details,
			"progression_actions": progression_actions,
			"equipment": equipment_summary,
			"statuses": status_summary,
			"status_details": status_details,
			"trade": trade_summary,
			"trade_actions": trade_actions,
			"quests": active_quests,
			"quest_directions": quest_directions,
			"quest_target_actions": quest_target_actions,
			"time": time_summary,
			"time_actions": time_actions,
			"factions": faction_summary,
			"locations": location_names,
			"location_details": location_details
		})
	}


static func _primary_action(ctx: HudContext, nearby, auto_target) -> String:
	if ctx.auto_move_active or auto_target:
		return "Stop"
	var preferred := MainContextActions.preferred_primary(ctx.context_actions_context, nearby)
	if not preferred.is_empty():
		return String(preferred.get("text", "Interact"))
	if nearby and ["container", "door"].has(nearby.get_kind()):
		return ObjectInteractionRules.access_action_text(
			nearby, ctx.chunks, ctx.condition_evaluator
		)
	if nearby and nearby.get_kind() == "poi":
		return PoiInteraction.primary_action_text(nearby)
	return PrimaryActionTextBuilder.for_kind(nearby.get_kind()) if nearby else "Explore"


static func _system_tabs(values: Dictionary) -> Dictionary:
	return {
		"inventory": {
			"summary": values.get("inventory_summary", "empty"),
			"items": values.get("inventory_items", []),
			"details": values.get("inventory_details", ""),
			"actions": values.get("inventory_actions", []),
			"transfer": {
				"open": values.get("transfer_open", false),
				"target": values.get("transfer_target", {}),
				"player_items": values.get("inventory_items", []),
				"target_items": values.get("transfer_target_items", [])
			}
		},
		"character": {
			"health": values.get("player_health", "Health unknown"),
			"mana": values.get("player_mana", "Mana unknown"),
			"progression": values.get("progression", "Level 1"),
			"progression_details": values.get("progression_details", ""),
			"equipment": values.get("equipment", "Weapon: empty\nOffhand: empty\nBody: empty"),
			"statuses": values.get("statuses", "none"),
			"status_details": values.get("status_details", ""),
			"actions": values.get("progression_actions", [])
		},
		"trade": {
			"summary": values.get("trade", "No trader selected."),
			"actions": values.get("trade_actions", [])
		},
		"quests": {
			"quests": values.get("quests", []),
			"directions": values.get("quest_directions", "none"),
			"actions": values.get("quest_target_actions", [])
		},
		"journal": {
			"time": values.get("time", "Day 1, 08:00"),
			"actions": values.get("time_actions", []),
			"factions": values.get("factions", ""),
			"locations": values.get("locations", ""),
			"location_details": values.get("location_details", "")
		}
	}


static func _target_name(entity) -> String:
	return entity.get_display_name() if entity else "none"


static func _target_detail(ctx: HudContext, entity) -> String:
	return String(ctx.target_detail_text.call(entity)) if entity else ""


static func _quest_target_actions(ctx: HudContext) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	var seen: Dictionary = {}
	for objective in ctx.quests.get_active_objectives_data():
		var target_id := String(objective.get("target_id", ""))
		if target_id.is_empty() or seen.has(target_id):
			continue
		var entity = ctx.entities.get_entity(target_id)
		if not entity:
			continue
		seen[target_id] = true
		actions.append({"id": "target:%s" % target_id, "text": "Target %s" % entity.get_display_name()})
	return actions


static func _inventory_items_data(ctx: HudContext) -> Array[Dictionary]:
	return _inventory_items_for_owner(ctx, "char_player")


static func _inventory_items_for_owner(ctx: HudContext, owner_id: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if owner_id.is_empty():
		return entries
	for item_id in _sorted_owner_inventory_ids(ctx, owner_id):
		var item: Dictionary = ctx.content.get_item(item_id)
		var count: int = ctx.inventory.get_count_for_owner(owner_id, item_id)
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


static func _sorted_owner_inventory_ids(ctx: HudContext, owner_id: String) -> Array:
	var source: Dictionary = ctx.inventory.get_items_for_owner(owner_id)
	var item_ids: Array = source.keys()
	item_ids.sort()
	return item_ids


static func _equipment_slots_data(ctx: HudContext) -> Dictionary:
	var slots := {}
	for slot in EquipmentSlots.SLOTS:
		var item_id: String = ctx.equipment.get_equipped_item(slot)
		var item: Dictionary = ctx.content.get_item(item_id)
		slots[slot] = {
			"slot": slot,
			"label": EquipmentSlots.label(slot),
			"item_id": item_id,
			"item_name": String(item.get("name", ""))
		}
	return slots


static func _spells_data(ctx: HudContext) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var spell_ids: Array = ctx.content.spell_ids()
	spell_ids.sort_custom(
		func(a, b) -> bool:
			var spell_a: Dictionary = ctx.content.get_spell(String(a))
			var spell_b: Dictionary = ctx.content.get_spell(String(b))
			var school_a := String(spell_a.get("school", ""))
			var school_b := String(spell_b.get("school", ""))
			if school_a == school_b:
				return String(spell_a.get("name", a)) < String(spell_b.get("name", b))
			return school_a < school_b
	)
	for spell_id in spell_ids:
		var spell: Dictionary = ctx.content.get_spell(String(spell_id))
		if spell.is_empty():
			continue
		entries.append(_spell_data(ctx, String(spell_id), spell))
	return entries


static func _spell_slots_data(ctx: HudContext) -> Dictionary:
	var slots := {}
	for slot in ctx.spells.SLOTS:
		var spell_id: String = ctx.spells.get_assigned_spell(slot)
		var spell: Dictionary = ctx.content.get_spell(spell_id)
		slots[slot] = _spell_data(ctx, spell_id, spell)
		slots[slot]["slot"] = slot
		slots[slot]["slot_label"] = _spell_slot_label(slot)
	return slots


static func _spell_data(ctx: HudContext, spell_id: String, spell: Dictionary) -> Dictionary:
	var assigned := _assigned_spell_slot(ctx, spell_id)
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


static func _assigned_spell_slot(ctx: HudContext, spell_id: String) -> String:
	if spell_id.is_empty():
		return ""
	for slot in ctx.spells.SLOTS:
		if ctx.spells.get_assigned_spell(slot) == spell_id:
			return slot
	return ""


static func _spell_slot_label(slot_id: String) -> String:
	return {"ability_1": "Ability I", "ability_2": "Ability II", "ability_3": "Ability III"}.get(
		slot_id, ""
	)


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
