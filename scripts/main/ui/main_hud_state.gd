class_name MainHudState
extends RefCounted

const LocationTextBuilder = preload("res://scripts/ui/text/location_text_builder.gd")
const QuestTargetTextBuilder = preload("res://scripts/ui/text/quest_target_text_builder.gd")
const MainContextActions = preload("res://scripts/main/actions/main_context_actions.gd")
const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")
const SpellSlots = preload("res://scripts/core/spell_slots.gd")


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
	var hud_queries
	var inventory
	var nearby
	var nearby_targets: Array
	var player
	var primary_action: String
	var progression
	var quests
	var shop_id: String
	var spells
	var statuses
	var time
	var world_state

	func _init(values: Dictionary) -> void:
		active_transfer_name = String(values.get("active_transfer_name", ""))
		active_transfer_owner_id = String(values.get("active_transfer_owner_id", ""))
		auto_interact_target_id = String(values.get("auto_interact_target_id", ""))
		auto_move_active = bool(values.get("auto_move_active", false))
		chunks = values.get("chunks")
		condition_evaluator = values.get("condition_evaluator")
		content = values.get("content")
		context_actions_context = values.get("context_actions_context")
		entities = values.get("entities")
		equipment = values.get("equipment")
		factions = values.get("factions")
		hud_queries = values.get("hud_queries")
		inventory = values.get("inventory")
		nearby = values.get("nearby")
		nearby_targets = _typed_dictionary_array(values.get("nearby_targets", []))
		player = values.get("player")
		primary_action = String(values.get("primary_action", "Explore"))
		progression = values.get("progression")
		quests = values.get("quests")
		shop_id = String(values.get("shop_id", ""))
		spells = values.get("spells")
		statuses = values.get("statuses")
		time = values.get("time")
		world_state = values.get("world_state")

	func _typed_dictionary_array(value: Variant) -> Array:
		var result: Array = []
		if not value is Array:
			return result
		for entry in value:
			if entry is Dictionary:
				result.append(entry)
		return result


static func context(values: Dictionary) -> HudContext:
	return HudContext.new(values)


static func build(ctx: HudContext) -> Dictionary:
	var auto_target = ctx.entities.get_entity(ctx.auto_interact_target_id)
	var displayed = auto_target if auto_target else ctx.nearby
	var shop_id: String = ctx.shop_id
	var target_name := "Destination" if ctx.auto_move_active else _target_name(displayed)
	var target_detail := "Moving" if ctx.auto_move_active else _target_detail(ctx, displayed)
	var inventory_summary := String(ctx.hud_queries.inventory_text())
	var inventory_items := _inventory_items_data(ctx)
	var inventory_details := String(ctx.hud_queries.inventory_details_text())
	var inventory_actions = ctx.hud_queries.inventory_actions_data()
	var transfer_open := not ctx.active_transfer_owner_id.is_empty()
	var transfer_target := {
		"owner_id": ctx.active_transfer_owner_id,
		"name": ctx.active_transfer_name
	}
	var transfer_target_items := _inventory_items_for_owner(ctx, ctx.active_transfer_owner_id)
	var trade_summary := String(ctx.hud_queries.trade_text(shop_id))
	var trade_actions: Array = ctx.hud_queries.trade_actions_data(shop_id)
	var trade_stock_rows: Array = ctx.hud_queries.trade_stock_rows_data(shop_id)
	var progression_summary := String(ctx.progression.get_summary())
	var progression_details := String(ctx.progression.get_details())
	var progression_actions: Array = ctx.hud_queries.progression_actions_data()
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
	var system_tabs := _system_tabs(
		_inventory_tab(
			inventory_summary,
			inventory_items,
			inventory_details,
			inventory_actions,
			transfer_open,
			transfer_target,
			transfer_target_items
		),
		_character_tab(
			player_health,
			player_mana,
			progression_summary,
			progression_details,
			equipment_summary,
			status_summary,
			status_details,
			progression_actions
		),
		_trade_tab(trade_summary, trade_actions, trade_stock_rows),
		_quests_tab(active_quests, quest_directions, quest_target_actions),
		_journal_tab(
			time_summary,
			time_actions,
			faction_summary,
			location_names,
			location_details
		)
	)
	return {
		"player_health": player_health,
		"player_health_value": ctx.player.health,
		"player_max_health": ctx.player.max_health,
		"player_mana": player_mana,
		"player_mana_value": ctx.player.mana,
		"player_max_mana": ctx.player.max_mana,
		"player_sneaking": ctx.player.is_sneaking,
		"nearby": target_name,
		"primary_action": ctx.primary_action,
		"target_detail": target_detail,
		"nearby_targets": ctx.nearby_targets,
		"context_actions": MainContextActions.secondary(ctx.context_actions_context, ctx.nearby),
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
		"trade_stock_rows": trade_stock_rows,
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
		"system_tabs": system_tabs
	}


static func _system_tabs(
	inventory_tab: Dictionary,
	character_tab: Dictionary,
	trade_tab: Dictionary,
	quests_tab: Dictionary,
	journal_tab: Dictionary
) -> Dictionary:
	return {
		"inventory": inventory_tab,
		"character": character_tab,
		"trade": trade_tab,
		"quests": quests_tab,
		"journal": journal_tab
	}


static func _inventory_tab(
	summary: String,
	items: Array,
	details: String,
	actions: Array,
	transfer_open: bool,
	transfer_target: Dictionary,
	transfer_target_items: Array
) -> Dictionary:
	return {
		"summary": summary,
		"items": items,
		"details": details,
		"actions": actions,
		"transfer":
		{
			"open": transfer_open,
			"target": transfer_target,
			"player_items": items,
			"target_items": transfer_target_items
		}
	}


static func _character_tab(
	health: String,
	mana: String,
	progression: String,
	progression_details: String,
	equipment: String,
	statuses: String,
	status_details: String,
	actions: Array
) -> Dictionary:
	return {
		"health": health,
		"mana": mana,
		"progression": progression,
		"progression_details": progression_details,
		"equipment": equipment,
		"statuses": statuses,
		"status_details": status_details,
		"actions": actions
	}


static func _trade_tab(summary: String, actions: Array, stock_rows: Array) -> Dictionary:
	return {"summary": summary, "actions": actions, "stock_rows": stock_rows}


static func _quests_tab(quests: Array, directions: String, actions: Array) -> Dictionary:
	return {"quests": quests, "directions": directions, "actions": actions}


static func _journal_tab(
	time: String,
	actions: Array,
	factions: String,
	locations: String,
	location_details: String
) -> Dictionary:
	return {
		"time": time,
		"actions": actions,
		"factions": factions,
		"locations": locations,
		"location_details": location_details
	}


static func _target_name(entity) -> String:
	return entity.get_display_name() if entity else "none"


static func _target_detail(ctx: HudContext, entity) -> String:
	return String(ctx.hud_queries.target_detail_text(entity)) if entity else ""


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
	return SpellSlots.label(slot_id)


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
