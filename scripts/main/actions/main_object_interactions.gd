class_name MainObjectInteractions
extends RefCounted

const ObjectInteractionRules = preload("res://scripts/core/object_interaction_rules.gd")
const ActorRules = preload("res://scripts/core/actor_rules.gd")
const MainInventoryTransfer = preload("res://scripts/main/actions/main_inventory_transfer.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")


class InteractionContext:
	var active_content_choices: Dictionary
	var chunks
	var condition_evaluator
	var content
	var crime
	var entities
	var event_bus
	var hud
	var inventory
	var inventory_transfer_context
	var player
	var readables
	var streamer
	var time
	var world_query
	var _apply_effect: Callable
	var _clear_active_transfer: Callable
	var _clear_target_state: Callable
	var _sync_camera_to_player: Callable
	var _update_nearby: Callable

	func _init(main) -> void:
		active_content_choices = main.active_content_choices
		chunks = main.chunks
		condition_evaluator = main.condition_evaluator
		content = main.content
		crime = main.get("crime")
		entities = main.entities
		event_bus = main.event_bus
		hud = main.hud
		inventory = main.inventory
		inventory_transfer_context = MainInventoryTransfer.context(main)
		player = main.player
		readables = main.readables
		streamer = main.streamer
		time = main.time
		world_query = main.world_query
		_apply_effect = Callable(main, "apply_effect")
		_clear_active_transfer = Callable(main, "_clear_active_transfer")
		_clear_target_state = Callable(main, "clear_target_state")
		_sync_camera_to_player = Callable(main, "_sync_camera_to_player")
		_update_nearby = Callable(main, "_update_nearby")

	func apply_effect(effect: Dictionary) -> bool:
		return bool(_apply_effect.call(effect))

	func clear_active_transfer(close_panel := false) -> void:
		_clear_active_transfer.call(close_panel)

	func clear_target_state() -> void:
		_clear_target_state.call()

	func sync_camera_to_player() -> void:
		_sync_camera_to_player.call()

	func update_nearby() -> void:
		_update_nearby.call()


static func context(main) -> InteractionContext:
	return InteractionContext.new(main)


static func interact_readable(ctx: InteractionContext, entity: WorldEntity) -> void:
	var readable_id := String(entity.data.get("readable_id", ""))
	var readable: Dictionary = ctx.readables.read_readable(readable_id)
	if readable.is_empty():
		ctx.event_bus.post_message("The writing is too weathered to read.")
		return
	var title := String(readable.get("title", "Readable"))
	var body := String(readable.get("body", ""))
	ctx.active_content_choices.clear()
	if ctx.hud:
		ctx.hud.show_content_card(title, body, [], "readable")
	ctx.event_bus.post_message("Read %s." % title)


static func interact_pickup(ctx: InteractionContext, entity: WorldEntity) -> void:
	var item_id := String(entity.data.get("item_id", ""))
	var count := VariantFields.positive_int_field(entity.data, "count", 1)
	var pickup_effects := VariantFields.array(entity.data.get("effects_on_pickup", []))
	if not ctx.inventory.add_item(item_id, count):
		ctx.event_bus.post_message("Could not pick up %s." % entity.get_display_name())
		return
	ctx.entities.remove_entity(entity.get_entity_id())
	var item: Dictionary = ctx.content.get_item(item_id)
	ctx.event_bus.post_message("Picked up %s." % String(item.get("name", item_id)))
	for effect in pickup_effects:
		if effect is Dictionary:
			ctx.apply_effect(effect)
	ctx.update_nearby()


static func interact_container(ctx: InteractionContext, entity: WorldEntity) -> void:
	var entity_id: String = entity.get_entity_id()
	var locked_text := ObjectInteractionRules.access_locked_text(
		entity.data, ctx.condition_evaluator
	)
	if not locked_text.is_empty():
		ctx.event_bus.post_message(locked_text)
		return
	if ["container", "body"].has(entity.get_kind()) or ActorRules.is_dead_actor_data(entity.data):
		MainInventoryTransfer.open(ctx.inventory_transfer_context, entity)
		return
	if entity.get_kind() == "door" and not VariantFields.portal_data(entity).is_empty():
		interact_portal(ctx, entity)
		return
	var layer := VariantFields.entity_layer(entity)
	if ctx.chunks.is_object_opened(entity_id, entity.global_tile, layer):
		ctx.event_bus.post_message("%s is already open." % entity.get_display_name())
		return
	var opened := false
	for effect in VariantFields.array(entity.data.get("effects_on_open", [])):
		if effect is Dictionary and ctx.apply_effect(effect):
			opened = true
	ctx.chunks.mark_object_opened(entity_id, entity.global_tile, layer)
	if opened:
		ctx.event_bus.post_message("Opened %s." % entity.get_display_name())
	else:
		ctx.event_bus.post_message("%s is empty." % entity.get_display_name())
	ctx.update_nearby()


static func interact_portal(ctx: InteractionContext, entity: WorldEntity) -> void:
	if bool(entity.data.get("jail_exit", false)) and ctx.crime and ctx.crime.is_player_jailed():
		ctx.event_bus.post_message(
			"The lockup door remains barred. Serve the sentence at the prisoner cot."
		)
		return
	var portal := VariantFields.portal_data(entity)
	var display_name := entity.get_display_name()
	var message := String(portal.get("message", "Moved through %s." % display_name))
	var target_layer := String(portal.get("target_layer", "surface"))
	var target_tile := VariantFields.vector2i_from_pair(
		portal.get("target_tile", []), ctx.player.global_tile
	)
	if ctx.world_query and not ctx.world_query.is_walkable(target_tile, target_layer):
		ctx.event_bus.post_message("The way through is blocked.")
		return
	ctx.clear_active_transfer(false)
	ctx.clear_target_state()
	if ctx.hud:
		ctx.hud.hide_target_picker()
	ctx.player.set_world_layer(target_layer)
	ctx.player.set_global_tile(target_tile)
	var facing := VariantFields.vector2_from_pair(portal.get("target_facing", []), Vector2.ZERO)
	if facing.length() > 0.01:
		ctx.player.set_facing_direction(facing)
	if ctx.world_query:
		ctx.world_query.set_layer(ctx.player.world_layer)
	if ctx.streamer:
		ctx.streamer.update_center(ctx.player.global_tile, ctx.player.world_layer)
	ctx.sync_camera_to_player()
	ctx.event_bus.post_message(message)
	ctx.update_nearby()


static func interact_rest(ctx: InteractionContext, entity: WorldEntity) -> void:
	var before: int = ctx.player.health
	var heal_amount := VariantFields.positive_int_field(
		entity.data, "heal_amount", ctx.player.max_health
	)
	var rest_hours := VariantFields.positive_int_field(entity.data, "rest_hours", 8)
	ctx.player.heal(heal_amount)
	var time_summary := "now"
	if ctx.time:
		ctx.time.advance_hours(rest_hours)
		time_summary = ctx.time.get_summary()
	if ctx.player.health == before:
		ctx.event_bus.post_message(
			"%s is warm. You rest until %s." % [entity.get_display_name(), time_summary]
		)
		return
	ctx.event_bus.post_message(
		(
			"Rested at %s until %s. Health %d/%d."
			% [
				entity.get_display_name(),
				time_summary,
				ctx.player.health,
				ctx.player.max_health
			]
		)
	)
