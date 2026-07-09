class_name MainHudState
extends RefCounted

const LocationTextBuilder = preload("res://scripts/ui/text/location_text_builder.gd")
const QuestTargetTextBuilder = preload("res://scripts/ui/text/quest_target_text_builder.gd")
const MainContextActions = preload("res://scripts/main/actions/main_context_actions.gd")
const SystemsActionIds = preload("res://scripts/main/actions/systems_action_ids.gd")
const EquipmentSlots = preload("res://scripts/core/equipment_slots.gd")
const SpellSlots = preload("res://scripts/core/spell_slots.gd")


class HudDataSources:
	var content
	var entities
	var inventory
	var equipment
	var spells
	var progression
	var quests
	var statuses
	var factions
	var time

	func _init(
		content_value,
		entities_value,
		inventory_value,
		equipment_value,
		spells_value,
		progression_value,
		quests_value,
		statuses_value,
		factions_value,
		time_value
	) -> void:
		content = content_value
		entities = entities_value
		inventory = inventory_value
		equipment = equipment_value
		spells = spells_value
		progression = progression_value
		quests = quests_value
		statuses = statuses_value
		factions = factions_value
		time = time_value


class HudUiServices:
	var hud_queries
	var context_actions_context
	var world_state

	func _init(hud_queries_value, context_actions_context_value, world_state_value) -> void:
		hud_queries = hud_queries_value
		context_actions_context = context_actions_context_value
		world_state = world_state_value


class HudSnapshot:
	var active_transfer_name: String
	var active_transfer_owner_id: String
	var auto_interact_target_id: String
	var auto_move_active: bool
	var current_location_name: String
	var nearby
	var nearby_targets: Array
	var player
	var primary_action: String
	var shop_id: String

	func _init(
		active_transfer_name_value: String,
		active_transfer_owner_id_value: String,
		auto_interact_target_id_value: String,
		auto_move_active_value: bool,
		current_location_name_value: String,
		nearby_value,
		nearby_targets_value: Array,
		player_value,
		primary_action_value: String,
		shop_id_value: String
	) -> void:
		active_transfer_name = active_transfer_name_value
		active_transfer_owner_id = active_transfer_owner_id_value
		auto_interact_target_id = auto_interact_target_id_value
		auto_move_active = auto_move_active_value
		current_location_name = current_location_name_value
		nearby = nearby_value
		nearby_targets = _typed_dictionary_array(nearby_targets_value)
		player = player_value
		primary_action = primary_action_value
		shop_id = shop_id_value

	func _typed_dictionary_array(value: Variant) -> Array:
		var result: Array = []
		if not value is Array:
			return result
		for entry in value:
			if entry is Dictionary:
				result.append(entry)
		return result


class HudContext:
	var active_transfer_name: String
	var active_transfer_owner_id: String
	var auto_interact_target_id: String
	var auto_move_active: bool
	var content
	var context_actions_context
	var current_location_name: String
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

	func _init(sources: HudDataSources, services: HudUiServices, snapshot: HudSnapshot) -> void:
		active_transfer_name = snapshot.active_transfer_name
		active_transfer_owner_id = snapshot.active_transfer_owner_id
		auto_interact_target_id = snapshot.auto_interact_target_id
		auto_move_active = snapshot.auto_move_active
		content = sources.content
		context_actions_context = services.context_actions_context
		current_location_name = snapshot.current_location_name
		entities = sources.entities
		equipment = sources.equipment
		factions = sources.factions
		hud_queries = services.hud_queries
		inventory = sources.inventory
		nearby = snapshot.nearby
		nearby_targets = snapshot.nearby_targets
		player = snapshot.player
		primary_action = snapshot.primary_action
		progression = sources.progression
		quests = sources.quests
		shop_id = snapshot.shop_id
		spells = sources.spells
		statuses = sources.statuses
		time = sources.time
		world_state = services.world_state


static func context(values: Dictionary) -> HudContext:
	return HudContext.new(
		HudDataSources.new(
			values.get("content"),
			values.get("entities"),
			values.get("inventory"),
			values.get("equipment"),
			values.get("spells"),
			values.get("progression"),
			values.get("quests"),
			values.get("statuses"),
			values.get("factions"),
			values.get("time")
		),
		HudUiServices.new(
			values.get("hud_queries"),
			values.get("context_actions_context"),
			values.get("world_state")
		),
		HudSnapshot.new(
			String(values.get("active_transfer_name", "")),
			String(values.get("active_transfer_owner_id", "")),
			String(values.get("auto_interact_target_id", "")),
			bool(values.get("auto_move_active", false)),
			String(values.get("current_location_name", "")),
			values.get("nearby"),
			values.get("nearby_targets", []),
			values.get("player"),
			String(values.get("primary_action", "Explore")),
			String(values.get("shop_id", ""))
		)
	)


static func build(ctx: HudContext) -> Dictionary:
	var target_state := _target_state(ctx)
	var inventory_state := _inventory_state(ctx)
	var trade_state := _trade_state(ctx)
	var character_state := _character_state(ctx)
	var journal_state := _journal_state(ctx)
	var quest_state := _quest_state(ctx)
	var spell_state := _spell_state(ctx)
	var equipment_state := _equipment_state(ctx)
	var state := {}
	for section in [
		target_state,
		inventory_state,
		trade_state,
		character_state,
		journal_state,
		quest_state,
		spell_state,
		equipment_state
	]:
		state.merge(section)
	state["system_tabs"] = _system_tabs_from_sections(
		inventory_state,
		character_state,
		equipment_state,
		trade_state,
		quest_state,
		journal_state,
		spell_state
	)
	return state


static func _target_state(ctx: HudContext) -> Dictionary:
	var auto_target = ctx.entities.get_entity(ctx.auto_interact_target_id)
	var displayed = auto_target if auto_target else ctx.nearby
	var target_name := "Destination" if ctx.auto_move_active else _target_name(displayed)
	var target_detail := "Moving" if ctx.auto_move_active else _target_detail(ctx, displayed)
	return {
		"nearby": target_name,
		"primary_action": ctx.primary_action,
		"target_detail": target_detail,
		"nearby_targets": ctx.nearby_targets,
		"context_actions": MainContextActions.secondary(ctx.context_actions_context, ctx.nearby)
	}


static func _inventory_state(ctx: HudContext) -> Dictionary:
	var inventory_summary := String(ctx.hud_queries.inventory_text())
	var inventory_items := _inventory_items_data(ctx)
	var inventory_details := String(ctx.hud_queries.inventory_details_text())
	var inventory_actions = ctx.hud_queries.inventory_actions_data()
	var transfer_open := not ctx.active_transfer_owner_id.is_empty()
	var transfer_target := {
		"owner_id": ctx.active_transfer_owner_id, "name": ctx.active_transfer_name
	}
	var transfer_target_items := _inventory_items_for_owner(ctx, ctx.active_transfer_owner_id)
	return {
		"inventory": inventory_summary,
		"inventory_items": inventory_items,
		"inventory_details": inventory_details,
		"inventory_actions": inventory_actions,
		"transfer_open": transfer_open,
		"transfer_target": transfer_target,
		"transfer_player_items": inventory_items,
		"transfer_target_items": transfer_target_items
	}


static func _trade_state(ctx: HudContext) -> Dictionary:
	var trade_summary := String(ctx.hud_queries.trade_text(ctx.shop_id))
	var trade_actions: Array = ctx.hud_queries.trade_actions_data(ctx.shop_id)
	var trade_stock_rows: Array = ctx.hud_queries.trade_stock_rows_data(ctx.shop_id)
	return {
		"trade": trade_summary, "trade_actions": trade_actions, "trade_stock_rows": trade_stock_rows
	}


static func _character_state(ctx: HudContext) -> Dictionary:
	var progression_summary := String(ctx.progression.get_summary())
	var progression_details := String(ctx.progression.get_details())
	var progression_actions: Array = ctx.hud_queries.progression_actions_data()
	var status_summary := String(ctx.statuses.get_summary())
	var status_details := String(ctx.statuses.get_details())
	var player_health := "%d/%d" % [ctx.player.health, ctx.player.max_health]
	var player_mana := "%d/%d" % [int(roundf(ctx.player.mana)), int(roundf(ctx.player.max_mana))]
	return {
		"player_health": player_health,
		"player_health_value": ctx.player.health,
		"player_max_health": ctx.player.max_health,
		"player_mana": player_mana,
		"player_mana_value": ctx.player.mana,
		"player_max_mana": ctx.player.max_mana,
		"player_sneaking": ctx.player.is_sneaking,
		"progression": progression_summary,
		"progression_details": progression_details,
		"progression_actions": progression_actions,
		"statuses": status_summary,
		"status_details": status_details
	}


static func _journal_state(ctx: HudContext) -> Dictionary:
	var time_summary := String(ctx.time.get_summary())
	var time_actions := [
		{"id": SystemsActionIds.wait_hours(1), "text": "Wait 1h"},
		{"id": SystemsActionIds.wait_hours(8), "text": "Wait 8h"}
	]
	var location_names := LocationTextBuilder.names(
		ctx.world_state.discovered_locations, ctx.content
	)
	var location_details := LocationTextBuilder.details(
		ctx.world_state.discovered_locations, ctx.content
	)
	var faction_summary := String(ctx.factions.get_summary())
	return {
		"factions": faction_summary,
		"time": time_summary,
		"time_actions": time_actions,
		"time_details": ctx.time.get_details(),
		"locations": location_names,
		"current_location": ctx.current_location_name,
		"location_details": location_details
	}


static func _quest_state(ctx: HudContext) -> Dictionary:
	var quest_directions := QuestTargetTextBuilder.directions(
		ctx.quests, ctx.entities, ctx.player.global_position
	)
	var quest_target_actions := _quest_target_actions(ctx)
	var active_quests: Array = ctx.quests.get_active_summary()
	return {
		"quest_directions": quest_directions,
		"quest_target_actions": quest_target_actions,
		"quests": active_quests
	}


static func _spell_state(ctx: HudContext) -> Dictionary:
	return {"spells": _spells_data(ctx), "spell_slots": _spell_slots_data(ctx)}


static func _equipment_state(ctx: HudContext) -> Dictionary:
	return {
		"equipment": String(ctx.equipment.get_summary()),
		"equipment_slots": _equipment_slots_data(ctx)
	}


static func _system_tabs_from_sections(
	inventory_state: Dictionary,
	character_state: Dictionary,
	equipment_state: Dictionary,
	trade_state: Dictionary,
	quest_state: Dictionary,
	journal_state: Dictionary,
	spell_state: Dictionary
) -> Dictionary:
	var transfer_target: Dictionary = inventory_state["transfer_target"]
	return _system_tabs(
		_inventory_tab(
			inventory_state["inventory"],
			inventory_state["inventory_items"],
			inventory_state["inventory_details"],
			inventory_state["inventory_actions"],
			inventory_state["transfer_open"],
			transfer_target,
			inventory_state["transfer_target_items"]
		),
		_character_tab(
			character_state["player_health"],
			character_state["player_mana"],
			character_state["progression"],
			character_state["progression_details"],
			equipment_state["equipment"],
			character_state["statuses"],
			character_state["status_details"],
			character_state["progression_actions"]
		),
		_trade_tab(
			trade_state["trade"], trade_state["trade_actions"], trade_state["trade_stock_rows"]
		),
		_quests_tab(
			quest_state["quests"],
			quest_state["quest_directions"],
			quest_state["quest_target_actions"]
		),
		_journal_tab(
			journal_state["time"],
			journal_state["time_actions"],
			journal_state["factions"],
			journal_state["locations"],
			journal_state["location_details"]
		),
		_spells_tab(spell_state["spells"], spell_state["spell_slots"])
	)


static func _system_tabs(
	inventory_tab: Dictionary,
	character_tab: Dictionary,
	trade_tab: Dictionary,
	quests_tab: Dictionary,
	journal_tab: Dictionary,
	spells_tab: Dictionary
) -> Dictionary:
	return {
		"inventory": inventory_tab,
		"spells": spells_tab,
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


static func _spells_tab(spells: Array, spell_slots: Dictionary) -> Dictionary:
	return {"spells": spells, "spell_slots": spell_slots}


static func _quests_tab(quests: Array, directions: String, actions: Array) -> Dictionary:
	return {"quests": quests, "directions": directions, "actions": actions}


static func _journal_tab(
	time: String, actions: Array, factions: String, locations: String, location_details: String
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
		actions.append(
			{
				"id": SystemsActionIds.target_entity(target_id),
				"text": "Target %s" % entity.get_display_name()
			}
		)
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
		entries.append(
			{
				"item_id": item_id,
				"name": String(item.get("name", item_id)),
				"count": count,
				"type": String(item.get("type", "")),
				"tags": _array_field(item.get("tags", [])),
				"equipment_slot": String(item.get("equipment_slot", "")),
				"value": maxi(0, int(item.get("value", 0))),
				"weight": maxf(0.0, float(item.get("weight", 0.0))),
				"description": String(item.get("description", ""))
			}
		)
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
		"mana_drain_per_second":
		float(spell.get("mana_drain_per_second", spell.get("mana_cost", 0))),
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
