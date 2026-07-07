class_name MainInventoryTransfer
extends RefCounted

const ActorRules = preload("res://scripts/core/actor_rules.gd")
const ObjectInteractionRules = preload("res://scripts/core/object_interaction_rules.gd")
const PickpocketRules = preload("res://scripts/core/pickpocket_rules.gd")

class TransferContext:
	var chunks
	var condition_evaluator
	var content
	var entities
	var event_bus
	var hud
	var inventory
	var player
	var active_content_choices: Dictionary
	var seeded_inventory_owner_ids: Dictionary
	var _transfer_owner_id: Callable
	var _transfer_source: Callable
	var _set_transfer: Callable
	var _clear_transfer: Callable
	var _apply_effect: Callable
	var _refresh_hud: Callable
	var _update_nearby: Callable

	func _init(main) -> void:
		chunks = main.chunks
		condition_evaluator = main.condition_evaluator
		content = main.content
		entities = main.entities
		event_bus = main.event_bus
		hud = main.hud
		inventory = main.inventory
		player = main.player
		active_content_choices = main.active_content_choices
		seeded_inventory_owner_ids = main.seeded_inventory_owner_ids
		_transfer_owner_id = func() -> String:
			return String(main.active_transfer_owner_id)
		_transfer_source = func() -> Dictionary:
			return {
				"entity_id": String(main.active_transfer_source_id),
				"kind": String(main.active_transfer_source_kind),
				"global_tile": main.active_transfer_source_tile,
				"access_mode": String(main.active_transfer_access_mode)
			}
		_set_transfer = func(owner_id: String, display_name: String, source: Dictionary) -> void:
			main.active_transfer_owner_id = owner_id
			main.active_transfer_name = display_name
			main.active_transfer_source_id = String(source.get("entity_id", ""))
			main.active_transfer_source_kind = String(source.get("kind", ""))
			var source_tile: Variant = source.get("global_tile", Vector2i.ZERO)
			main.active_transfer_source_tile = (
				source_tile if source_tile is Vector2i else Vector2i.ZERO
			)
			main.active_transfer_access_mode = String(source.get("access_mode", ""))
		_clear_transfer = Callable(main, "_clear_active_transfer")
		_apply_effect = Callable(main, "apply_effect")
		_refresh_hud = Callable(main, "_refresh_hud")
		_update_nearby = Callable(main, "_update_nearby")

	func transfer_owner_id() -> String:
		return String(_transfer_owner_id.call())

	func transfer_source() -> Dictionary:
		return _transfer_source.call()

	func set_transfer(owner_id: String, display_name: String, source: Dictionary = {}) -> void:
		_set_transfer.call(owner_id, display_name, source)

	func clear_transfer(should_refresh_hud: bool = true) -> void:
		if _clear_transfer.is_valid():
			_clear_transfer.call(should_refresh_hud)
			return
		_set_transfer.call("", "", {})
		if should_refresh_hud:
			refresh_hud()

	func apply_effect(effect: Dictionary) -> bool:
		return bool(_apply_effect.call(effect))

	func refresh_hud() -> void:
		_refresh_hud.call()

	func update_nearby() -> void:
		_update_nearby.call()


static func context(main) -> TransferContext:
	return TransferContext.new(main)


static func open(ctx: TransferContext, entity) -> void:
	var entity_id: String = entity.get_entity_id()
	var owner_id := _loot_owner_id(entity)
	var was_open: bool = ctx.chunks.is_object_opened(entity_id, entity.global_tile)
	var opened: bool = was_open
	if not was_open:
		opened = _seed_loot_owner_from_open_effects(ctx, owner_id, entity.data)
		opened = opened or _owner_has_items(ctx, owner_id)
		ctx.chunks.mark_object_opened(entity_id, entity.global_tile)
	ctx.set_transfer(
		owner_id, entity.get_display_name(), _transfer_source_from_entity(entity, "object")
	)
	if opened:
		_post_message(ctx, "Opened %s." % entity.get_display_name())
	else:
		_post_message(ctx, "%s is empty." % entity.get_display_name())
	_show_inventory_panel(ctx)
	ctx.update_nearby()


static func open_pickpocket(ctx: TransferContext, entity) -> void:
	var owner_id := _humanoid_owner_id(entity)
	if owner_id.is_empty():
		_post_message(ctx, "No pockets to pick.")
		ctx.refresh_hud()
		return
	_seed_owner_from_entity_inventory_once(ctx, owner_id, entity.data)
	ctx.set_transfer(
		owner_id, entity.get_display_name(), _transfer_source_from_entity(entity, "pickpocket")
	)
	_clear_content_choices(ctx)
	_hide_content_card(ctx)
	_show_inventory_panel(ctx)
	_post_message(ctx, "Pickpocketing %s." % entity.get_display_name())
	ctx.update_nearby()


static func take_item(ctx: TransferContext, item_id: String) -> void:
	var owner_id := ctx.transfer_owner_id()
	if owner_id.is_empty():
		_post_message(ctx, "No open container.")
		ctx.refresh_hud()
		return
	var access := _active_transfer_access_result(ctx, owner_id)
	if not bool(access.get("allowed", false)):
		_clear_inaccessible_transfer(ctx, String(access.get("reason", "")))
		return
	var item: Dictionary = ctx.content.get_item(item_id)
	var item_name := String(item.get("name", item_id))
	if item.is_empty():
		_post_message(ctx, "Could not take that item.")
		ctx.refresh_hud()
		return
	if not ctx.inventory.has_item_for_owner(owner_id, item_id, 1):
		_post_message(ctx, "%s has none left." % item_name)
		ctx.refresh_hud()
		return
	if not ctx.inventory.can_add_item_to_owner("char_player", item_id, 1):
		_post_message(ctx, "No room for %s." % item_name)
		ctx.refresh_hud()
		return
	if not ctx.inventory.transfer_item(owner_id, "char_player", item_id, 1):
		_post_message(ctx, "Could not take %s." % item_name)
		ctx.refresh_hud()
		return
	_refresh_equipment_for_owner(ctx, owner_id)
	_post_message(ctx, "Took %s." % item_name)
	ctx.refresh_hud()


static func put_item(ctx: TransferContext, item_id: String) -> void:
	var owner_id := ctx.transfer_owner_id()
	if owner_id.is_empty():
		_post_message(ctx, "No open container.")
		ctx.refresh_hud()
		return
	var access := _active_transfer_access_result(ctx, owner_id)
	if not bool(access.get("allowed", false)):
		_clear_inaccessible_transfer(ctx, String(access.get("reason", "")))
		return
	var item: Dictionary = ctx.content.get_item(item_id)
	var item_name := String(item.get("name", item_id))
	if item.is_empty():
		_post_message(ctx, "Could not put that item away.")
		ctx.refresh_hud()
		return
	if not ctx.inventory.has_item_for_owner("char_player", item_id, 1):
		_post_message(ctx, "You have no %s." % item_name)
		ctx.refresh_hud()
		return
	if not ctx.inventory.can_add_item_to_owner(owner_id, item_id, 1):
		_post_message(ctx, "%s will not fit." % item_name)
		ctx.refresh_hud()
		return
	if not ctx.inventory.transfer_item("char_player", owner_id, item_id, 1):
		_post_message(ctx, "Could not put %s away." % item_name)
		ctx.refresh_hud()
		return
	_refresh_equipment_for_owner(ctx, owner_id)
	_post_message(ctx, "Put %s." % item_name)
	ctx.refresh_hud()


static func _seed_loot_owner_from_open_effects(
	ctx: TransferContext, owner_id: String, data: Dictionary
) -> bool:
	var opened := false
	for effect in _array_field(data.get("effects_on_open", [])):
		if not effect is Dictionary:
			continue
		if String(effect.get("type", "")) == "add_item":
			var item_id := String(effect.get("item_id", ""))
			var count: int = _positive_int_field(effect, "count", 1)
			if ctx.inventory.add_item_to_owner(owner_id, item_id, count):
				opened = true
			continue
		if ctx.apply_effect(effect):
			opened = true
	return opened


static func _loot_owner_id(entity) -> String:
	var owner_id := ActorRules.inventory_owner_id(entity.data)
	if not owner_id.is_empty():
		return owner_id
	return "loot:%s" % entity.get_entity_id()


static func _humanoid_owner_id(entity) -> String:
	if not ActorRules.is_living_humanoid_data(entity.data):
		return ""
	return ActorRules.inventory_owner_id(entity.data)


static func _transfer_source_from_entity(entity, access_mode: String) -> Dictionary:
	return {
		"entity_id": entity.get_entity_id(),
		"kind": entity.get_kind(),
		"global_tile": entity.global_tile,
		"access_mode": access_mode
	}


static func _active_transfer_access_result(ctx: TransferContext, owner_id: String) -> Dictionary:
	var source := ctx.transfer_source()
	var entity_id := String(source.get("entity_id", ""))
	if entity_id.is_empty():
		return _blocked_transfer("Transfer source is gone.")
	var entity = _transfer_source_entity(ctx, entity_id)
	if not entity:
		return _blocked_transfer("Transfer source is gone.")
	if String(source.get("kind", "")) != entity.get_kind():
		return _blocked_transfer("Transfer source changed.")
	var source_tile: Variant = source.get("global_tile", null)
	if source_tile is Vector2i and entity.global_tile != source_tile:
		return _blocked_transfer("Transfer source moved.")
	if not _transfer_source_is_nearby(ctx, entity):
		return _blocked_transfer("That is no longer within reach.")
	match String(source.get("access_mode", "")):
		"object":
			if _loot_owner_id(entity) != owner_id:
				return _blocked_transfer("Transfer source changed.")
			var locked_text := ObjectInteractionRules.access_locked_text(
				entity.data, ctx.condition_evaluator
			)
			if not locked_text.is_empty():
				return _blocked_transfer(locked_text)
			return {"allowed": true, "reason": ""}
		"pickpocket":
			if _humanoid_owner_id(entity) != owner_id:
				return _blocked_transfer("No pockets to pick.")
			var result := PickpocketRules.access_result(
				entity, ctx.player.global_position, ctx.player.is_sneaking
			)
			if bool(result.get("allowed", false)):
				return {"allowed": true, "reason": ""}
			return _blocked_transfer(String(result.get("reason", "Cannot pickpocket.")))
	return _blocked_transfer("Transfer source is gone.")


static func _blocked_transfer(reason: String) -> Dictionary:
	return {"allowed": false, "reason": reason}


static func _transfer_source_entity(ctx: TransferContext, entity_id: String):
	if ctx.entities and ctx.entities.has_method("get_entity"):
		return ctx.entities.get_entity(entity_id)
	return null


static func _transfer_source_is_nearby(ctx: TransferContext, entity) -> bool:
	if not ctx.player or not ctx.entities or not ctx.entities.has_method("get_interactables_world"):
		return false
	for candidate in ctx.entities.get_interactables_world(ctx.player.global_position):
		if candidate and candidate.get_entity_id() == entity.get_entity_id():
			return true
	return false


static func _clear_inaccessible_transfer(ctx: TransferContext, reason: String) -> void:
	ctx.clear_transfer(false)
	_post_message(ctx, reason if not reason.is_empty() else "Transfer is no longer available.")
	ctx.refresh_hud()


static func _seed_owner_from_entity_inventory_once(
	ctx: TransferContext, owner_id: String, data: Dictionary
) -> void:
	if owner_id.is_empty():
		return
	if ctx.seeded_inventory_owner_ids.has(owner_id):
		return
	ctx.seeded_inventory_owner_ids[owner_id] = true
	for entry in _array_field(data.get("inventory", [])):
		if not entry is Dictionary:
			continue
		var item_id := String(entry.get("item_id", ""))
		var count: int = _positive_int_field(entry, "count", 1)
		ctx.inventory.add_item_to_owner(owner_id, item_id, count)


static func _owner_has_items(ctx: TransferContext, owner_id: String) -> bool:
	if owner_id.is_empty() or not ctx.inventory or not ctx.inventory.has_method("get_items_for_owner"):
		return false
	return not ctx.inventory.get_items_for_owner(owner_id).is_empty()


static func _post_message(ctx: TransferContext, message: String) -> void:
	if ctx.event_bus:
		ctx.event_bus.post_message(message)


static func _show_inventory_panel(ctx: TransferContext) -> void:
	if ctx.hud:
		ctx.hud.show_systems_panel("inventory")


static func _hide_content_card(ctx: TransferContext) -> void:
	if ctx.hud:
		ctx.hud.hide_content_card()


static func _clear_content_choices(ctx: TransferContext) -> void:
	ctx.active_content_choices.clear()


static func _refresh_equipment_for_owner(ctx: TransferContext, owner_id: String) -> void:
	if ctx.entities and ctx.entities.has_method("refresh_equipment_for_owner"):
		ctx.entities.refresh_equipment_for_owner(owner_id)


static func _positive_int_field(source: Dictionary, field_id: String, fallback: int) -> int:
	var value = int(source.get(field_id, fallback))
	return value if value > 0 else fallback


static func _array_field(value: Variant) -> Array:
	return value if value is Array else []
