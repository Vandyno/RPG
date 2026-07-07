class_name MainInventoryTransfer
extends RefCounted

const ActorRules = preload("res://scripts/core/actor_rules.gd")

class TransferContext:
	var chunks
	var content
	var entities
	var event_bus
	var hud
	var inventory
	var active_content_choices: Dictionary
	var seeded_inventory_owner_ids: Dictionary
	var _transfer_owner_id: Callable
	var _set_transfer: Callable
	var _apply_effect: Callable
	var _refresh_hud: Callable
	var _update_nearby: Callable

	func _init(main) -> void:
		chunks = main.chunks
		content = main.content
		entities = main.entities
		event_bus = main.event_bus
		hud = main.hud
		inventory = main.inventory
		active_content_choices = main.active_content_choices
		seeded_inventory_owner_ids = main.seeded_inventory_owner_ids
		_transfer_owner_id = func() -> String:
			return String(main.active_transfer_owner_id)
		_set_transfer = func(owner_id: String, display_name: String) -> void:
			main.active_transfer_owner_id = owner_id
			main.active_transfer_name = display_name
		_apply_effect = Callable(main, "apply_effect")
		_refresh_hud = Callable(main, "_refresh_hud")
		_update_nearby = Callable(main, "_update_nearby")

	func transfer_owner_id() -> String:
		return String(_transfer_owner_id.call())

	func set_transfer(owner_id: String, display_name: String) -> void:
		_set_transfer.call(owner_id, display_name)

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
	ctx.set_transfer(owner_id, entity.get_display_name())
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
	ctx.set_transfer(owner_id, entity.get_display_name())
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
