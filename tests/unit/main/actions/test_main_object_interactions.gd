extends GutTest

const MainObjectInteractions = preload("res://scripts/main/actions/main_object_interactions.gd")
const VariantFields = preload("res://scripts/core/variant_fields.gd")


class EventBusStub:
	extends RefCounted

	var messages: Array[String] = []

	func post_message(message: String) -> void:
		messages.append(message)


class HudStub:
	extends RefCounted

	var hide_target_picker_calls := 0

	func hide_target_picker() -> void:
		hide_target_picker_calls += 1


class PlayerStub:
	extends RefCounted

	var global_tile := Vector2i(1, 1)
	var world_layer := "surface"
	var global_tiles: Array[Vector2i] = []
	var facing_values: Array[Vector2] = []

	func set_world_layer(layer: String) -> void:
		world_layer = layer

	func set_global_tile(tile: Vector2i) -> void:
		global_tile = tile
		global_tiles.append(tile)

	func set_facing_direction(direction: Vector2) -> void:
		facing_values.append(direction)


class WorldQueryStub:
	extends RefCounted

	var walkable := true
	var layers: Array[String] = []

	func is_walkable(_tile: Vector2i, _layer: String) -> bool:
		return walkable

	func set_layer(layer: String) -> void:
		layers.append(layer)


class StreamerStub:
	extends RefCounted

	var centers: Array[Dictionary] = []

	func update_center(tile: Vector2i, layer: String) -> void:
		centers.append({"tile": tile, "layer": layer})


class MainStub:
	extends RefCounted

	var active_content_choices := {}
	var chunks
	var condition_evaluator
	var content
	var entities
	var event_bus := EventBusStub.new()
	var hud := HudStub.new()
	var inventory
	var player := PlayerStub.new()
	var readables
	var streamer := StreamerStub.new()
	var time
	var world_query := WorldQueryStub.new()
	var seeded_inventory_owner_ids := {}
	var active_transfer_owner_id := ""
	var active_transfer_name := ""
	var active_transfer_source_id := ""
	var active_transfer_source_kind := ""
	var active_transfer_source_tile := Vector2i.ZERO
	var active_transfer_access_mode := ""
	var effects: Array[Dictionary] = []
	var clear_transfer_calls: Array[bool] = []
	var clear_target_calls := 0
	var sync_calls := 0
	var nearby_calls := 0
	var refresh_hud_calls := 0

	func apply_effect(effect: Dictionary) -> bool:
		effects.append(effect)
		return true

	func _clear_active_transfer(close_panel := false) -> void:
		clear_transfer_calls.append(close_panel)

	func clear_target_state() -> void:
		clear_target_calls += 1

	func _sync_camera_to_player() -> void:
		sync_calls += 1

	func _update_nearby() -> void:
		nearby_calls += 1

	func _refresh_hud() -> void:
		refresh_hud_calls += 1


func test_portal_interaction_moves_player_and_clears_target_state() -> void:
	var main := MainStub.new()
	var ctx := MainObjectInteractions.context(main)
	var entity := _entity({
		"id": "door",
		"name": "Forge Door",
		"kind": "door",
		"portal": {
			"target_layer": "interior:forge",
			"target_tile": [4, 5],
			"target_facing": [0, -1],
			"message": "Entered forge."
		}
	})

	MainObjectInteractions.interact_portal(ctx, entity)

	assert_eq(main.clear_transfer_calls, [false])
	assert_eq(main.clear_target_calls, 1)
	assert_eq(main.hud.hide_target_picker_calls, 1)
	assert_eq(main.player.world_layer, "interior:forge")
	assert_eq(main.player.global_tiles, [Vector2i(4, 5)])
	assert_eq(main.player.facing_values, [Vector2.UP])
	assert_eq(main.world_query.layers, ["interior:forge"])
	assert_eq(main.streamer.centers, [{"tile": Vector2i(4, 5), "layer": "interior:forge"}])
	assert_eq(main.sync_calls, 1)
	assert_eq(main.nearby_calls, 1)
	assert_eq(main.event_bus.messages, ["Entered forge."])


func test_portal_interaction_reports_blocked_route_without_moving() -> void:
	var main := MainStub.new()
	main.world_query.walkable = false
	var ctx := MainObjectInteractions.context(main)
	var entity := _entity({
		"id": "door",
		"name": "Forge Door",
		"kind": "door",
		"portal": {"target_layer": "interior:forge", "target_tile": [4, 5]}
	})

	MainObjectInteractions.interact_portal(ctx, entity)

	assert_eq(main.event_bus.messages, ["The way through is blocked."])
	assert_true(main.clear_transfer_calls.is_empty())
	assert_eq(main.player.world_layer, "surface")


func test_helper_parsers_handle_invalid_values_and_defaults() -> void:
	var entity := _entity({"world_layer": "", "portal": "bad"})

	assert_eq(VariantFields.array("bad"), [])
	assert_eq(VariantFields.portal_data(entity), {})
	assert_eq(VariantFields.entity_layer(entity), "surface")
	assert_eq(
		VariantFields.vector2i_from_pair([1.8, -2], Vector2i.ZERO),
		Vector2i(1, -2)
	)
	assert_eq(VariantFields.vector2i_from_pair(["bad", 1], Vector2i(9, 9)), Vector2i(9, 9))
	assert_eq(VariantFields.vector2_from_pair([1, 2.5], Vector2.ZERO), Vector2(1, 2.5))
	assert_eq(VariantFields.vector2_from_pair(["bad"], Vector2.ONE), Vector2.ONE)
	assert_eq(VariantFields.positive_int_field({"count": -4}, "count", 3), 1)
	assert_eq(VariantFields.positive_int_field({"count": "bad"}, "count", 3), 3)
	assert_true(VariantFields.is_number(1.0))
	assert_false(VariantFields.is_number("1"))


func _entity(data: Dictionary) -> WorldEntity:
	var entity := WorldEntity.new()
	add_child_autofree(entity)
	entity.setup(data)
	return entity
