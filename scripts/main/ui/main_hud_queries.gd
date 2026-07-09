class_name MainHudQueries
extends RefCounted

const ObjectInteractionRules = preload("res://scripts/core/object_interaction_rules.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")
const CombatManagerScript = preload("res://scripts/managers/actors/combat_manager.gd")
const ShopManagerScript = preload("res://scripts/managers/content/shop_manager.gd")
const PoiInteraction = preload("res://scripts/main/actions/poi_interaction.gd")
const SystemsActionIds = preload("res://scripts/main/actions/systems_action_ids.gd")

var chunks
var combat
var condition_evaluator
var content
var equipment
var entities
var factions
var inventory
var player
var progression
var quests
var shops


class Dependencies:
	var chunks
	var combat
	var condition_evaluator
	var content
	var equipment
	var entities
	var factions
	var inventory
	var player
	var progression
	var quests
	var shops

	func _init(values: Dictionary = {}) -> void:
		chunks = values.get("chunks")
		combat = values.get("combat")
		condition_evaluator = values.get("condition_evaluator")
		content = values.get("content")
		equipment = values.get("equipment")
		entities = values.get("entities")
		factions = values.get("factions")
		inventory = values.get("inventory")
		player = values.get("player")
		progression = values.get("progression")
		quests = values.get("quests")
		shops = values.get("shops")


func setup(dependencies: Dependencies) -> void:
	chunks = dependencies.chunks
	combat = dependencies.combat
	condition_evaluator = dependencies.condition_evaluator
	content = dependencies.content
	equipment = dependencies.equipment
	entities = dependencies.entities
	factions = dependencies.factions
	inventory = dependencies.inventory
	player = dependencies.player
	progression = dependencies.progression
	quests = dependencies.quests
	shops = dependencies.shops


func inventory_text() -> String:
	if inventory.items.is_empty():
		return "empty"
	var parts: Array[String] = []
	for item_id in _sorted_inventory_ids():
		var item: Dictionary = content.get_item(item_id)
		var count: int = inventory.get_count(item_id)
		if count > 0:
			parts.append("%s x%d" % [String(item.get("name", item_id)), count])
	return "empty" if parts.is_empty() else ", ".join(parts)


func inventory_details_text() -> String:
	if inventory.items.is_empty():
		return ""
	var lines: Array[String] = []
	for item_id in _sorted_inventory_ids():
		var item: Dictionary = content.get_item(item_id)
		var count: int = inventory.get_count(item_id)
		if count <= 0:
			continue
		var name := String(item.get("name", item_id))
		var description := String(item.get("description", ""))
		lines.append(
			(
				"%s x%d" % [name, count]
				if description.is_empty()
				else "%s x%d: %s" % [name, count, description]
			)
		)
	return "\n".join(lines)


func inventory_actions_data() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	for item_id in _sorted_inventory_ids():
		var item: Dictionary = content.get_item(item_id)
		var has_use := not VariantFields.array(item.get("effects_on_use", [])).is_empty()
		var slot := String(item.get("equipment_slot", ""))
		var count: int = inventory.get_count(item_id)
		if item.is_empty() or count <= 0 or (not has_use and slot.is_empty()):
			continue
		var item_name := String(item.get("name", item_id))
		if has_use:
			actions.append({
				"id": SystemsActionIds.use_item(item_id),
				"item_id": item_id,
				"text": "Use %s" % item_name,
				"count": count
			})
		if not slot.is_empty():
			var equipped_item_id: String = equipment.get_equipped_item(slot)
			var action_id := (
				SystemsActionIds.unequip_slot(slot)
				if equipped_item_id == item_id
				else SystemsActionIds.equip_item(item_id)
			)
			var action_text := (
				"Unequip %s" % item_name if equipped_item_id == item_id else "Equip %s" % item_name
			)
			actions.append({"id": action_id, "item_id": item_id, "text": action_text})
	return actions


func progression_actions_data() -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if progression.skill_points <= 0:
		return actions
	for stat_id in progression.get_trainable_stat_ids():
		actions.append(
			{
				"id": SystemsActionIds.train_stat(stat_id),
				"text": "Train %s" % progression.get_stat_label(stat_id),
				"count": progression.skill_points
			}
		)
	return actions


func trade_text(shop_id: String) -> String:
	if shop_id.is_empty():
		return "No trader selected."
	var shop_name := String(shops.get_shop_name(shop_id))
	if shop_name.is_empty():
		return "No shop available."
	var lines: Array[String] = [shop_name]
	lines.append(_shop_hours_text(shop_id))
	if not shops.is_shop_open(shop_id):
		lines.append("Closed now.")
	lines.append(
		"Gold: %d" % inventory.get_count(ShopManagerScript.CURRENCY_ITEM_ID)
		if inventory
		else "Gold: 0"
	)
	lines.append("")
	lines.append("Stock:")
	for stock_entry in shops.get_stock_entries(shop_id):
		lines.append(
			"- %s: %dg" % [
				String(stock_entry.get("name", stock_entry.get("item_id", ""))),
				int(stock_entry.get("price", 0))
			]
		)
	var sellable: Array = shops.get_sellable_entries(shop_id)
	lines.append("")
	if sellable.is_empty():
		lines.append("Sell: none")
	else:
		lines.append("Sell:")
		for sell_entry in sellable:
			lines.append("- %s" % _sell_action_text(sell_entry))
	return "\n".join(lines)


func trade_actions_data(shop_id: String) -> Array[Dictionary]:
	var actions: Array[Dictionary] = []
	if shop_id.is_empty() or not shops.is_shop_open(shop_id):
		return actions
	for stock_entry in shops.get_stock_entries(shop_id):
		var item_id := String(stock_entry.get("item_id", ""))
		if item_id.is_empty():
			continue
		actions.append({
			"id": SystemsActionIds.buy_item(item_id),
			"item_id": item_id,
			"text": _buy_action_text(stock_entry)
		})
	for sell_entry in shops.get_sellable_entries(shop_id):
		var item_id := String(sell_entry.get("item_id", ""))
		if item_id.is_empty():
			continue
		actions.append({
			"id": SystemsActionIds.sell_item(item_id),
			"item_id": item_id,
			"text": _sell_action_text(sell_entry)
		})
	return actions


func trade_stock_rows_data(shop_id: String) -> Array[Dictionary]:
	if shop_id.is_empty():
		return []
	var rows: Array[Dictionary] = []
	var shop_open: bool = shops.is_shop_open(shop_id)
	for stock_entry in shops.get_stock_entries(shop_id):
		var item_id := String(stock_entry.get("item_id", ""))
		if item_id.is_empty():
			continue
		rows.append({
			"item_id": item_id,
			"name": String(stock_entry.get("name", item_id)),
			"price": int(stock_entry.get("price", 0)),
			"action_id": SystemsActionIds.buy_item(item_id) if shop_open else "",
			"available": shop_open,
			"merchant_name": String(stock_entry.get("merchant_name", "Merchant"))
		})
	return rows


func nearby_entities_text(nearby_entities: Array, selected_target_id: String) -> String:
	if nearby_entities.is_empty():
		return "none"
	var names: Array[String] = []
	for entity in nearby_entities:
		var name: String = entity.get_display_name()
		names.append("*%s*" % name if entity.get_entity_id() == selected_target_id else name)
	return ", ".join(names)


func nearby_targets_data(
	nearby_entities: Array, selected_target_id: String, player_position: Vector2
) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for entity in nearby_entities:
		targets.append(
			{
				"id": entity.get_entity_id(),
				"kind": entity.get_kind(),
				"name": entity.get_display_name(),
				"detail": target_detail_text(entity),
				"navigation": entities.get_navigation_hint(player_position, entity),
				"selected": entity.get_entity_id() == selected_target_id
			}
		)
	return targets


func target_detail_text(entity) -> String:
	if ActorRules.is_combat_target_entity(entity):
		return _hostile_actor_detail_text(entity)
	var detail := "Object"
	match entity.get_kind():
		"readable":
			detail = _readable_detail_text(entity)
		"pickup":
			detail = _pickup_detail_text(entity)
		"container":
			detail = ObjectInteractionRules.container_detail(entity, chunks, condition_evaluator)
		"door":
			detail = ObjectInteractionRules.access_detail(
				entity, chunks, condition_evaluator, "Door"
			)
		"poi":
			detail = PoiInteraction.detail(entity)
		"npc":
			detail = _npc_detail_text(entity)
		"body":
			detail = "Body: loot"
		"rest":
			detail = _rest_detail_text(entity)
	return detail


func shop_id_for_entity(entity) -> String:
	if not entity:
		return ""
	if entity.get_kind() == "poi":
		return String(entity.data.get("shop_id", ""))
	if entity.get_kind() != "npc":
		return ""
	var npc: Dictionary = content.get_npc(String(entity.data.get("npc_id", "")))
	return String(npc.get("shop_id", ""))


func _sorted_inventory_ids() -> Array:
	var item_ids: Array = inventory.items.keys()
	item_ids.sort()
	return item_ids


func _readable_detail_text(entity) -> String:
	var readable: Dictionary = content.get_readable(String(entity.data.get("readable_id", "")))
	return "Readable: %s" % String(readable.get("title", entity.get_display_name()))


func _pickup_detail_text(entity) -> String:
	var item_id := String(entity.data.get("item_id", ""))
	var item: Dictionary = content.get_item(item_id)
	var count := VariantFields.positive_int_field(entity.data, "count", 1)
	return "Pickup: %s x%d" % [String(item.get("name", item_id)), count]


func _npc_detail_text(entity) -> String:
	var npc: Dictionary = content.get_npc(String(entity.data.get("npc_id", "")))
	var quest_id := String(npc.get("quest_id", ""))
	var faction_id := String(npc.get("faction", ""))
	var parts: Array[String] = [String(npc.get("role", "NPC"))]
	if not quest_id.is_empty():
		parts.append("quest %s" % quests.get_quest_state(quest_id))
	if not faction_id.is_empty():
		var faction: Dictionary = content.get_faction(faction_id)
		parts.append(
			"%s %+d" % [String(faction.get("name", faction_id)), factions.get_reputation(faction_id)]
		)
	if not String(npc.get("shop_id", "")).is_empty():
		parts.append("trader")
	return ", ".join(parts)


func _hostile_actor_detail_text(entity) -> String:
	var health: int = combat.get_entity_health(entity)
	var max_health := VariantFields.positive_int_field(
		entity.data, "max_health", CombatManagerScript.DEFAULT_MAX_HEALTH
	)
	var attack_damage := VariantFields.non_negative_int_field(
		entity.data, "attack_damage", CombatManagerScript.DEFAULT_ENEMY_DAMAGE
	)
	return (
		"Hostile HP %d/%d, counter %d"
		% [health, max_health, attack_damage]
	)


func _rest_detail_text(entity) -> String:
	var heal_amount := VariantFields.positive_int_field(entity.data, "heal_amount", player.max_health)
	var rest_hours := VariantFields.positive_int_field(entity.data, "rest_hours", 8)
	return "Rest: heals %d, advances %dh" % [heal_amount, rest_hours]


func _shop_hours_text(shop_id: String) -> String:
	var hours: Dictionary = shops.get_shop_hours(shop_id)
	if hours.is_empty():
		return "Hours: always open"
	return "Hours: %02d:00-%02d:00" % [
		int(hours.get("open_hour", 0)),
		int(hours.get("close_hour", 0))
	]


func _buy_action_text(stock_entry: Dictionary) -> String:
	return "Buy %s (%dg)" % [
		String(stock_entry.get("name", stock_entry.get("item_id", ""))),
		int(stock_entry.get("price", 0))
	]


func _sell_action_text(sell_entry: Dictionary) -> String:
	return "Sell %s (+%dg)" % [
		String(sell_entry.get("name", sell_entry.get("item_id", ""))),
		int(sell_entry.get("price", 0))
	]
